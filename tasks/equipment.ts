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

task("deployE", "deploy E's contracts").setAction(deploy);
task("upgradeE", "upgrade E's contracts and replace in the diamond").setAction(
  upgrade
);

async function deploy(args: object, hre: HardhatRuntimeEnvironment) {
  const isDev =
    hre.network.name === "localhost" || hre.network.name === "hardhat";

  // Ensure we have required keys in our initializers
  settings.required(hre.equipmentInitializers, []);

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
      initializers: hre.equipmentInitializers,
    },
    hre
  );

  await saveDeploy(
    "equipment",
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
      "RingUniversusEquipment",
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
    initializers: HardhatRuntimeEnvironment["equipmentInitializers"];
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
      targetContract: "contracts/equipment/InitDiamond.sol:InitDiamond",
    },
    {},
    hre
  );

  // Ring Universus facets
  const equipmentFacet = await deployEquipmentFacet({}, libraries, hre);
  const adminFacet = await deployAdminFacet("RUEquipmentAdminFacet", {}, hre);

  // The `cuts` to perform for Ring Universus facets
  const ringUniversusEquipmentFacetCuts = [
    ...(await changes.getFacetCuts("RUEquipmentFacet", equipmentFacet)),
    ...(await changes.getFacetCuts("RUEquipmentAdminFacet", adminFacet)),
  ];

  if (isDev) {
    // const debugFacet = await deployDebugFacet({}, libraries, hre);
    // ringUniversusFacetCuts.push(
    //   ...changes.getFacetCuts("RUEquipmentDebugFacet", debugFacet)
    // );
  }

  const toCut = [...diamondSpecFacetCuts, ...ringUniversusEquipmentFacetCuts];

  const diamondCut = await hre.ethers.getContractAt(
    "RingUniversusEquipment",
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
    throw Error(`E's Diamond cut failed: ${initTx.hash}`);
  }
  console.log("Completed E's diamond cut");
  return [diamond, diamondInit, initReceipt] as const;
}

async function upgrade(args: object, hre: HardhatRuntimeEnvironment) {
  await hre.run("utils:assertChainId", { component: "equipment" });

  const isDev =
    hre.network.name === "localhost" || hre.network.name === "hardhat";

  // need to force a compile for tasks
  await hre.run("compile");

  console.log("E Diamond address:", hre.contracts.equipment.CONTRACT_ADDRESS);
  const diamond = await hre.ethers.getContractAt(
    "RingUniversusEquipment",
    hre.contracts.equipment.CONTRACT_ADDRESS
  );

  const previousFacets = await diamond.facets();

  const changes = new DiamondChanges(previousFacets);

  // Deploy libraries
  const libraries = await deployLibraries({}, hre);

  // Ring Universus facets
  const equipmentFacet = await deployEquipmentFacet({}, libraries, hre);
  const adminFacet = await deployAdminFacet("RUEquipmentAdminFacet", {}, hre);

  // The `cuts` to perform for Ring Universus facets
  const ringUniversusEquipmentFacetCuts = [
    ...(await changes.getFacetCuts("RUEquipmentFacet", equipmentFacet)),
    ...(await changes.getFacetCuts("RUEquipmentAdminFacet", adminFacet)),
  ];

  // The `cuts` to remove any old, unused functions
  const removeCuts = changes.getRemoveCuts(ringUniversusEquipmentFacetCuts);

  const shouldUpgrade = await changes.verify();
  if (!shouldUpgrade) {
    console.log("Upgrade aborted");
    return;
  }

  const toCut = [...ringUniversusEquipmentFacetCuts, ...removeCuts];

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

export async function deployEquipmentFacet(
  args: object,
  { LibEquipment }: Libraries,
  hre: HardhatRuntimeEnvironment
) {
  const factory = await hre.ethers.getContractFactory("RUEquipmentFacet", {
    libraries: { LibEquipment },
  });
  const contract = await factory.deploy();
  await contract.deploymentTransaction()!.wait();
  console.log(`RUEquipmentFacet deployed to: ${await contract.getAddress()}`);
  return contract;
}

export async function deployLibraries(
  args: object,
  hre: HardhatRuntimeEnvironment
) {
  const LibEquipmentFactory = await hre.ethers.getContractFactory(
    "LibEquipment",
    {
      libraries: {},
    }
  );
  const LibEquipment = await LibEquipmentFactory.deploy();
  await LibEquipment.deploymentTransaction()!.wait();

  return {
    LibEquipment: await LibEquipment.getAddress(),
  };
}
