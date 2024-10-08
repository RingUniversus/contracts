import { task } from "hardhat/config";
import { HardhatRuntimeEnvironment, Libraries } from "hardhat/types";

import {
  deployAdminFacet,
  deployDiamond,
  deployDiamondCutFacet,
  deployDiamondInit,
  deployDiamondLoupeFacet,
  deployOwnershipFacet,
  saveDeploy,
} from "./utils";
import * as settings from "../settings";
import { DiamondChanges } from "../utils/diamond";
import { ZeroAddress } from "ethers";

task("deployPlayer", "deploy player's contracts").setAction(deploy);
task(
  "upgradePlayer",
  "upgrade player contracts and replace in the diamond"
).setAction(upgrade);

async function deploy(args: object, hre: HardhatRuntimeEnvironment) {
  const isDev =
    hre.network.name === "localhost" || hre.network.name === "hardhat";

  // Ensure we have required keys in our initializers
  hre.playerInitializers.EQUIPMENT_ADDRESS =
    hre.contracts.equipment.CONTRACT_ADDRESS;
  hre.playerInitializers.COIN_ADDRESS = hre.contracts.coin.CONTRACT_ADDRESS;
  hre.playerInitializers.RING_ADDRESS = hre.contracts.ring.CONTRACT_ADDRESS;
  hre.playerInitializers.TOWN_ADDRESS = hre.contracts.town.CONTRACT_ADDRESS;
  hre.playerInitializers.OBLIVION_ADDRESS =
    hre.contracts.oblivion.CONTRACT_ADDRESS;
  hre.playerInitializers.VRF_ADDRESS = hre.playerInitializers.VRF_ADDRESS;

  settings.required(hre.playerInitializers, ["FEE_ADDRESS", "VRF_ADDRESS"]);

  // need to force a compile for tasks
  await hre.run("compile");

  // Were only using one account, getSigners()[0], the deployer.
  // Is deployer of all contracts, but ownership is transferred to ADMIN_PUBLIC_ADDRESS if set
  const [deployer] = await hre.ethers.getSigners();

  const requires = hre.ethers.parseEther("0.1");
  const balance = await deployer.provider.getBalance(deployer.address);

  // Only when deploying to production, give the deployer wallet money,
  // in order for it to be able to deploy the contracts
  if (!isDev && balance < requires) {
    throw new Error(
      `${deployer.address} requires ~$${hre.ethers.formatEther(
        requires
      )} but has ${hre.ethers.formatEther(balance)} top up and rerun`
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
      diamondAddress: await diamond.getAddress(),
      initAddress: await diamondInit.getAddress(),
    },
    hre
  );

  // give all contract administration over to an admin adress if was provided
  if (hre.ADMIN_PUBLIC_ADDRESS) {
    const ownership = await hre.ethers.getContractAt(
      "RingUniversusPlayer",
      await diamond.getAddress()
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
    ...(await changes.getFacetCuts("DiamondLoupeFacet", diamondLoupeFacet)),
    ...(await changes.getFacetCuts("OwnershipFacet", ownershipFacet)),
  ];

  const diamond = await deployDiamond(
    {
      ownerAddress: ownerAddress,
      // The `diamondCutFacet` is cut upon deployment
      diamondCutAddress: await diamondCutFacet.getAddress(),
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
  const adminFacet = await deployAdminFacet("RUPlayerAdminFacet", {}, hre);

  // The `cuts` to perform for Ring Universus facets
  const ringUniversusPlayerFacetCuts = [
    ...(await changes.getFacetCuts("RUPlayerFacet", playerFacet)),
    ...(await changes.getFacetCuts("RUPlayerAdminFacet", adminFacet)),
  ];

  if (isDev) {
    const debugFacet = await deployDebugFacet({}, libraries, hre);
    ringUniversusPlayerFacetCuts.push(
      ...(await changes.getFacetCuts("RUPlayerDebugFacet", debugFacet))
    );
  }

  const toCut = [...diamondSpecFacetCuts, ...ringUniversusPlayerFacetCuts];

  const diamondCut = await hre.ethers.getContractAt(
    "RingUniversusPlayer",
    await diamond.getAddress()
  );

  const initAddress = await diamondInit.getAddress();
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

// export async function deployAdminFacet(
//   {},
//   {}: Libraries,
//   hre: HardhatRuntimeEnvironment
// ) {
//   const factory = await hre.ethers.getContractFactory("RUPlayerAdminFacet", {
//     libraries: {},
//   });
//   const contract = await factory.deploy();
//   await contract.deployTransaction.wait();
//   console.log(`RUPlayerAdminFacet deployed to: ${await contract.getAddress()}`);
//   return contract;
// }

async function upgrade(args: object, hre: HardhatRuntimeEnvironment) {
  await hre.run("utils:assertChainId", { component: "player" });

  // const isDev =
  //   hre.network.name === "localhost" || hre.network.name === "hardhat";
  const isDev = true;

  // need to force a compile for tasks
  await hre.run("compile");

  console.log("Player Diamond address:", hre.contracts.player.CONTRACT_ADDRESS);
  const diamond = await hre.ethers.getContractAt(
    "RingUniversusPlayer",
    hre.contracts.player.CONTRACT_ADDRESS
  );

  const previousFacets = await diamond.facets();

  const changes = new DiamondChanges(previousFacets);

  // Deploy libraries
  const libraries = await deployLibraries({}, hre);

  // Ring Universus facets
  const playerFacet = await deployPlayerFacet({}, libraries, hre);
  const adminFacet = await deployAdminFacet("RUPlayerAdminFacet", {}, hre);

  // The `cuts` to perform for Ring Universus facets
  const ringUniversusPlayerFacetCuts = [
    ...(await changes.getFacetCuts("RUPlayerFacet", playerFacet)),
    ...(await changes.getFacetCuts("RUPlayerAdminFacet", adminFacet)),
  ];

  if (isDev) {
    const debugFacet = await deployDebugFacet({}, libraries, hre);
    ringUniversusPlayerFacetCuts.push(
      ...(await changes.getFacetCuts("RUPlayerDebugFacet", debugFacet))
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
  const initAddress = hre.ethers.ZeroAddress;
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
  args: object,
  { LibPlayer, LibUtil }: Libraries,
  hre: HardhatRuntimeEnvironment
) {
  const factory = await hre.ethers.getContractFactory("RUPlayerFacet", {
    libraries: { LibPlayer, LibUtil },
  });
  const contract = await factory.deploy();
  await contract.deploymentTransaction()!.wait();
  console.log(`RUPlayerFacet deployed to: ${await contract.getAddress()}`);
  return contract;
}

export async function deployLibraries(
  args: object,
  hre: HardhatRuntimeEnvironment
) {
  // TODO: Deploy shared libraries first
  const LibUtilFactory = await hre.ethers.getContractFactory(
    "contracts/shared/libraries/LibUtil.sol:LibUtil"
  );
  const LibUtil = await LibUtilFactory.deploy();
  await LibUtil.deploymentTransaction()!.wait();

  const LibPlayerFactory = await hre.ethers.getContractFactory("LibPlayer", {
    libraries: { LibUtil: await LibUtil.getAddress() },
  });
  const LibPlayer = await LibPlayerFactory.deploy();
  await LibPlayer.deploymentTransaction()!.wait();

  return {
    LibUtil: await LibUtil.getAddress(),
    LibPlayer: await LibPlayer.getAddress(),
  };
}

export async function deployDebugFacet(
  args: object,
  libraries: Libraries,
  hre: HardhatRuntimeEnvironment
) {
  const factory = await hre.ethers.getContractFactory("RUPlayerDebugFacet");
  const contract = await factory.deploy();
  await contract.deploymentTransaction()!.wait();
  console.log(`RUPlayerDebugFacet deployed to: ${await contract.getAddress()}`);
  return contract;
}
