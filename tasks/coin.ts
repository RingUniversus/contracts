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
} from "./utils";

task("deployCoin", "deploy coin's contracts").setAction(deploy);
task(
  "upgradeCoin",
  "upgrade coin contracts and replace in the diamond"
).setAction(upgrade);

async function deploy(args: {}, hre: HardhatRuntimeEnvironment) {
  const isDev =
    hre.network.name === "localhost" || hre.network.name === "hardhat";

  // Ensure we have required keys in our initializers
  settings.required(hre.coinInitializers, [
    "NAME",
    "SYMBOL",
    "DECIMALS",
    "TOTAL_SUPPLY",
  ]);

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
      initializers: hre.coinInitializers,
    },
    hre
  );

  await saveDeploy(
    "coin",
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
      "RingUniversusCoin",
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
    initializers: HardhatRuntimeEnvironment["coinInitializers"];
  },
  hre: HardhatRuntimeEnvironment
) {
  const isDev =
    hre.network.name === "localhost" || hre.network.name === "hardhat";

  // Deploy and cut
  const changes = new DiamondChanges();

  // TODO: Deploy libraries
  // const libraries = await deployLibraries({}, hre);
  const libraries = {};

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
      targetContract: "contracts/coin/InitDiamond.sol:InitDiamond",
    },
    libraries,
    hre
  );

  // Ring Universus facets
  const coinFacet = await deployCoinFacet({}, libraries, hre);

  // The `cuts` to perform for Ring Universus facets
  const ringUniversusCoinFacetCuts = [
    ...changes.getFacetCuts("RUCoinFacet", coinFacet),
  ];

  // if (isDev) {
  //   const debugFacet = await deployDebugFacet({}, libraries, hre);
  //   ringUniversusCoinFacetCuts.push(
  //     ...changes.getFacetCuts("RUCoinDebugFacet", debugFacet)
  //   );
  // }

  const toCut = [...diamondSpecFacetCuts, ...ringUniversusCoinFacetCuts];

  const diamondCut = await hre.ethers.getContractAt(
    "RingUniversusCoin",
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
    throw Error(`Coin's Diamond cut failed: ${initTx.hash}`);
  }
  console.log("Completed coin's diamond cut");
  return [diamond, diamondInit, initReceipt] as const;
}

async function upgrade({}, hre: HardhatRuntimeEnvironment) {
  await hre.run("utils:assertChainId", { component: "coin" });

  const isDev =
    hre.network.name === "localhost" || hre.network.name === "hardhat";

  // need to force a compile for tasks
  await hre.run("compile");

  console.log("Coin Diamond address:", hre.contracts.coin.CONTRACT_ADDRESS);
  const diamond = await hre.ethers.getContractAt(
    "RingUniversusCoin",
    hre.contracts.coin.CONTRACT_ADDRESS
  );

  const previousFacets = await diamond.facets();

  const changes = new DiamondChanges(previousFacets);

  const libraries = {};

  // Ring Universus facets
  const coinFacet = await deployCoinFacet({}, libraries, hre);

  // The `cuts` to perform for Ring Universus facets
  const ringUniversusCoinFacetCuts = [
    ...changes.getFacetCuts("RUCoinFacet", coinFacet),
  ];

  // The `cuts` to remove any old, unused functions
  const removeCuts = changes.getRemoveCuts(ringUniversusCoinFacetCuts);

  const shouldUpgrade = await changes.verify();
  if (!shouldUpgrade) {
    console.log("Upgrade aborted");
    return;
  }

  const toCut = [...ringUniversusCoinFacetCuts, ...removeCuts];

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

export async function deployCoinFacet(
  {},
  {}: Libraries,
  hre: HardhatRuntimeEnvironment
) {
  const factory = await hre.ethers.getContractFactory("RUCoinFacet", {
    libraries: {},
  });
  const contract = await factory.deploy();
  await contract.deployTransaction.wait();
  console.log(`RUCoinFacet deployed to: ${contract.address}`);
  return contract;
}

export async function deployDebugFacet(
  {},
  {}: Libraries,
  hre: HardhatRuntimeEnvironment
) {
  const factory = await hre.ethers.getContractFactory("RUCoinDebugFacet");
  const contract = await factory.deploy();
  await contract.deployTransaction.wait();
  console.log(`RUCoinDebugFacet deployed to: ${contract.address}`);
  return contract;
}
