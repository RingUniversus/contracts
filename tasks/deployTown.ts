import { task, types } from "hardhat/config";
import type { HardhatRuntimeEnvironment, Libraries } from "hardhat/types";
import * as settings from "../settings";
import { DiamondChanges } from "../utils/diamond";
import { deployDiamond, deployDiamondInit } from "./deploy";
import {
  deployDiamondCutFacet,
  deployDiamondLoupeFacet,
  deployOwnershipFacet,
} from "./deploy";

task("deployTown", "deploy town's contracts").setAction(deploy);

async function deploy(args: {}, hre: HardhatRuntimeEnvironment) {
  const isDev =
    hre.network.name === "localhost" || hre.network.name === "hardhat";

  // Ensure we have required keys in our initializers
  settings.required(hre.townInitializers, []);

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
      initializers: hre.townInitializers,
    },
    hre
  );

  // TODO: Transfer diamond ownership

  console.log("Deployed successfully. Godspeed cadet.");
}

export async function deployAndCut(
  {
    ownerAddress,
    initializers,
  }: {
    ownerAddress: string;
    initializers: HardhatRuntimeEnvironment["townInitializers"];
  },
  hre: HardhatRuntimeEnvironment
) {
  const isDev =
    hre.network.name === "localhost" || hre.network.name === "hardhat";

  // Deploy and cut
  const changes = new DiamondChanges();

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
      targetContract: "contracts/town/InitDiamond.sol:InitDiamond",
    },
    libraries,
    hre
  );

  // Ring Universus facets
  const townFacet = await deployTownFacet({}, libraries, hre);

  // The `cuts` to perform for Ring Universus facets
  const ringUniversusFacetCuts = [
    ...changes.getFacetCuts("RUTownFacet", townFacet),
  ];

  if (isDev) {
    // const debugFacet = await deployDebugFacet({}, libraries, hre);
    // ringUniversusFacetCuts.push(
    //   ...changes.getFacetCuts("RUTownDebugFacet", debugFacet)
    // );
  }

  const toCut = [...diamondSpecFacetCuts, ...ringUniversusFacetCuts];

  const diamondCut = await hre.ethers.getContractAt(
    "RingUniversusTown",
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
    throw Error(`Town's Diamond cut failed: ${initTx.hash}`);
  }
  console.log("Completed town's diamond cut");
  return [diamond, diamondInit, initReceipt] as const;
}

export async function deployTownFacet(
  {},
  {}: Libraries,
  hre: HardhatRuntimeEnvironment
) {
  const factory = await hre.ethers.getContractFactory("RUTownFacet", {
    libraries: {},
  });
  const contract = await factory.deploy();
  await contract.deployTransaction.wait();
  console.log(`RUTownFacet deployed to: ${contract.address}`);
  return contract;
}
