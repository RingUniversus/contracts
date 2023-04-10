import { constants } from "ethers";
import { task } from "hardhat/config";
import { HardhatRuntimeEnvironment, Libraries } from "hardhat/types";
import * as settings from "../settings";
import { DiamondChanges } from "../utils/diamond";
import {
  deployDiamond,
  deployDiamondCutFacet,
  deployDiamondInit,
  deployDiamondLoupeFacet,
  deployOwnershipFacet,
  saveDeploy,
  updateRelatedAddress,
} from "./utils";

const { AddressZero } = constants;

task("deployPlayer", "deploy player's contracts").setAction(deploy);
task(
  "upgradePlayer",
  "upgrade player contracts and replace in the diamond"
).setAction(upgrade);
task("updateRelatedAddress", "update related address after deploy").setAction(
  afterDeploy
);

async function deploy(args: {}, hre: HardhatRuntimeEnvironment) {
  const isDev =
    hre.network.name === "localhost" || hre.network.name === "hardhat";

  // Ensure we have required keys in our initializers
  hre.playerInitializers.EQUIPMENT_ADDRESS =
    hre.contracts.equipment.CONTRACT_ADDRESS;
  hre.playerInitializers.COIN_ADDRESS = hre.contracts.coin.CONTRACT_ADDRESS;
  hre.playerInitializers.RING_ADDRESS = hre.contracts.ring.CONTRACT_ADDRESS;
  hre.playerInitializers.TOWN_ADDRESS = hre.contracts.town.CONTRACT_ADDRESS;
  hre.playerInitializers.BOUNTY_ADDRESS = hre.contracts.bounty.CONTRACT_ADDRESS;
  // TODO:
  hre.playerInitializers.VRF_ADDRESS = AddressZero;
  settings.required(hre.playerInitializers, ["FEE_ADDRESS"]);

  // need to force a compile for tasks
  await hre.run("compile");

  // Were only using one account, getSigners()[0], the deployer.
  // Is deployer of all contracts, but ownership is transferred to ADMIN_PUBLIC_ADDRESS if set
  const [deployer] = await hre.ethers.getSigners();

  const requires = hre.ethers.utils.parseEther("2.1");
  const balance = await deployer.getBalance();

  // Only when deploying to production, give the deployer wallet money,
  // in order for it to be able to deploy the contracts
  if (!isDev && balance.lt(requires)) {
    throw new Error(
      `${deployer.address} requires ~$${hre.ethers.utils.formatEther(
        requires
      )} but has ${hre.ethers.utils.formatEther(balance)} top up and rerun`
    );
  }

  const [diamond, diamondInit, initReceipt] = await deployAndCut(
    {
      ownerAddress: deployer.address,
      initializers: hre.playerInitializers,
    },
    hre
  );

  await saveDeploy(
    "player",
    {
      coreBlockNumber: initReceipt.blockNumber,
      diamondAddress: diamond.address,
      initAddress: diamondInit.address,
    },
    hre
  );

  // give all contract administration over to an admin adress if was provided
  if (hre.ADMIN_PUBLIC_ADDRESS) {
    const ownership = await hre.ethers.getContractAt(
      "RingUniversusPlayer",
      diamond.address
    );
    const tx = await ownership.transferOwnership(hre.ADMIN_PUBLIC_ADDRESS);
    await tx.wait();
    console.log(`transfered diamond ownership to ${hre.ADMIN_PUBLIC_ADDRESS}`);
  }

  console.log("Deployed successfully. Godspeed cadet.");
}

export async function deployAndCut(
  {
    ownerAddress,
    initializers,
  }: {
    ownerAddress: string;
    initializers: HardhatRuntimeEnvironment["playerInitializers"];
  },
  hre: HardhatRuntimeEnvironment
) {
  const isDev =
    hre.network.name === "localhost" || hre.network.name === "hardhat";

  // Deploy and cut
  const changes = new DiamondChanges();

  // Deploy libraries
  const libraries = await deployLibraries({}, hre);

  // Diamond Spec facets
  // Note: These won't be updated during an upgrade without manual intervention
  const diamondCutFacet = await deployDiamondCutFacet({}, libraries, hre);
  const diamondLoupeFacet = await deployDiamondLoupeFacet({}, libraries, hre);
  const ownershipFacet = await deployOwnershipFacet({}, libraries, hre);

  // The `cuts` to perform for Diamond Spec facets
  const diamondSpecFacetCuts = [
    // Note: The `diamondCut` is omitted because it is cut upon deployment
    ...changes.getFacetCuts("DiamondLoupeFacet", diamondLoupeFacet),
    ...changes.getFacetCuts("OwnershipFacet", ownershipFacet),
  ];

  const diamond = await deployDiamond(
    {
      ownerAddress: ownerAddress,
      // The `diamondCutFacet` is cut upon deployment
      diamondCutAddress: diamondCutFacet.address,
    },
    libraries,
    hre
  );

  const diamondInit = await deployDiamondInit(
    {
      targetContract: "contracts/player/InitDiamond.sol:InitDiamond",
    },
    {},
    hre
  );

  // Ring Universus facets
  const playerFacet = await deployPlayerFacet({}, libraries, hre);

  // The `cuts` to perform for Ring Universus facets
  const ringUniversusPlayerFacetCuts = [
    ...changes.getFacetCuts("RUPlayerFacet", playerFacet),
  ];

  if (isDev) {
    const debugFacet = await deployDebugFacet({}, libraries, hre);
    ringUniversusPlayerFacetCuts.push(
      ...changes.getFacetCuts("RUPlayerDebugFacet", debugFacet)
    );
  }

  const toCut = [...diamondSpecFacetCuts, ...ringUniversusPlayerFacetCuts];

  const diamondCut = await hre.ethers.getContractAt(
    "RingUniversusPlayer",
    diamond.address
  );

  const initAddress = diamondInit.address;
  const initFunctionCall = diamondInit.interface.encodeFunctionData("init", [
    initializers,
  ]);

  const initTx = await diamondCut.diamondCut(
    toCut,
    initAddress,
    initFunctionCall
  );
  const initReceipt = await initTx.wait();
  if (!initReceipt.status) {
    throw Error(`Player's Diamond cut failed: ${initTx.hash}`);
  }
  console.log("Completed player's diamond cut");
  return [diamond, diamondInit, initReceipt] as const;
}

async function upgrade({}, hre: HardhatRuntimeEnvironment) {
  await hre.run("utils:assertChainId", { component: "player" });

  const isDev =
    hre.network.name === "localhost" || hre.network.name === "hardhat";

  // need to force a compile for tasks
  await hre.run("compile");

  console.log("Player Diamond address:", hre.contracts.player.CONTRACT_ADDRESS);
  const diamond = await hre.ethers.getContractAt(
    "RingUniversusPlayer",
    hre.contracts.player.CONTRACT_ADDRESS
  );
  // console.log(diamond);
  // console.log(diamond.interface.fragments);

  const previousFacets = await diamond.facets();

  const changes = new DiamondChanges(previousFacets);

  // Deploy libraries
  const libraries = await deployLibraries({}, hre);

  // Ring Universus facets
  const playerFacet = await deployPlayerFacet({}, libraries, hre);

  // The `cuts` to perform for Ring Universus facets
  const ringUniversusPlayerFacetCuts = [
    ...changes.getFacetCuts("RUPlayerFacet", playerFacet),
  ];

  if (isDev) {
    const debugFacet = await deployDebugFacet({}, libraries, hre);
    ringUniversusPlayerFacetCuts.push(
      ...changes.getFacetCuts("RUPlayerDebugFacet", debugFacet)
    );
  }

  // The `cuts` to remove any old, unused functions
  const removeCuts = changes.getRemoveCuts(ringUniversusPlayerFacetCuts);

  const shouldUpgrade = await changes.verify();
  if (!shouldUpgrade) {
    console.log("Upgrade aborted");
    return;
  }

  const toCut = [...ringUniversusPlayerFacetCuts, ...removeCuts];

  // As mentioned in the `deploy` task, EIP-2535 specifies that the `diamondCut`
  // function takes two optional arguments: address _init and bytes calldata _calldata
  // However, in a standard upgrade, no state modifications are done, so the 0x0 address
  // and empty calldata are specified for those `diamondCut` parameters.
  // If the Diamond storage needs to be changed on an upgrade, a contract would need to be
  // deployed and these variables would need to be adjusted similar to the `deploy` task.
  const initAddress = hre.ethers.constants.AddressZero;
  const initFunctionCall = "0x";

  const upgradeTx = await diamond.diamondCut(
    toCut,
    initAddress,
    initFunctionCall
  );
  const upgradeReceipt = await upgradeTx.wait();
  if (!upgradeReceipt.status) {
    throw Error(`Diamond cut failed: ${upgradeTx.hash}`);
  }
  console.log("Completed diamond cut");
  console.log("Upgraded successfully. Godspeed cadet.");
}

export async function deployPlayerFacet(
  {},
  { LibPlayer, LibUtil }: Libraries,
  hre: HardhatRuntimeEnvironment
) {
  const factory = await hre.ethers.getContractFactory("RUPlayerFacet", {
    libraries: { LibPlayer, LibUtil },
  });
  const contract = await factory.deploy();
  await contract.deployTransaction.wait();
  console.log(`RUPlayerFacet deployed to: ${contract.address}`);
  return contract;
}

export async function deployLibraries({}, hre: HardhatRuntimeEnvironment) {
  // TODO: Deploy shared libraries first
  const LibUtilFactory = await hre.ethers.getContractFactory(
    "contracts/shared/libraries/LibUtil.sol:LibUtil"
  );
  const LibUtil = await LibUtilFactory.deploy();
  await LibUtil.deployTransaction.wait();

  const LibPlayerFactory = await hre.ethers.getContractFactory("LibPlayer", {
    libraries: {
      LibUtil: LibUtil.address,
    },
  });
  const LibPlayer = await LibPlayerFactory.deploy();
  await LibPlayer.deployTransaction.wait();

  return {
    LibUtil: LibUtil.address,
    LibPlayer: LibPlayer.address,
  };
}

export async function deployDebugFacet(
  {},
  {}: Libraries,
  hre: HardhatRuntimeEnvironment
) {
  const factory = await hre.ethers.getContractFactory("RUPlayerDebugFacet");
  const contract = await factory.deploy();
  await contract.deployTransaction.wait();
  console.log(`RUPlayerDebugFacet deployed to: ${contract.address}`);
  return contract;
}

async function afterDeploy(args: {}, hre: HardhatRuntimeEnvironment) {
  await updateRelatedAddress(
    "RUPlayerFacet",
    hre.contracts.player.CONTRACT_ADDRESS,
    {
      feeAddress: hre.playerInitializers.FEE_ADDRESS,
      equipmentAddress: hre.contracts.equipment.CONTRACT_ADDRESS,
      coinAddress: hre.contracts.coin.CONTRACT_ADDRESS,
      ringAddress: hre.contracts.ring.CONTRACT_ADDRESS,
      townAddress: hre.contracts.town.CONTRACT_ADDRESS,
      bountyAddress: hre.contracts.bounty.CONTRACT_ADDRESS,
      // TODO
      vrfAddress: "0x3097403B64fe672467345bf159F4C9C5464bD89e",
    },
    hre
  );

  await updateRelatedAddress(
    "RUBountyFacet",
    hre.contracts.bounty.CONTRACT_ADDRESS,
    {
      playerAddress: hre.contracts.player.CONTRACT_ADDRESS,
    },
    hre
  );

  await updateRelatedAddress(
    "RUEquipmentFacet",
    hre.contracts.bounty.CONTRACT_ADDRESS,
    {
      playerAddress: hre.contracts.player.CONTRACT_ADDRESS,
    },
    hre
  );

  await updateRelatedAddress(
    "RURingFacet",
    hre.contracts.bounty.CONTRACT_ADDRESS,
    {
      playerAddress: hre.contracts.player.CONTRACT_ADDRESS,
    },
    hre
  );

  await updateRelatedAddress(
    "RUTownFacet",
    hre.contracts.bounty.CONTRACT_ADDRESS,
    {
      playerAddress: hre.contracts.player.CONTRACT_ADDRESS,
    },
    hre
  );
}
