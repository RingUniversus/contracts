import * as fs from "fs";
import { task, types } from "hardhat/config";
import type { HardhatRuntimeEnvironment, Libraries } from "hardhat/types";
import * as path from "path";
import { dedent } from "ts-dedent";
import * as settings from "../settings";
import { DiamondChanges } from "../utils/diamond";
import { tscompile } from "../utils/tscompile";

task("deploy", "deploy all contracts")
  .addOptionalParam(
    "subgraph",
    "bring up subgraph with name (requires docker)",
    undefined,
    types.string
  )
  .setAction(deploy);

async function deploy(
  args: { subgraph?: string },
  hre: HardhatRuntimeEnvironment
) {}

export async function deployDiamondCutFacet(
  {},
  libraries: Libraries,
  hre: HardhatRuntimeEnvironment
) {
  const factory = await hre.ethers.getContractFactory("DiamondCutFacet");
  const contract = await factory.deploy();
  await contract.deployTransaction.wait();
  console.log(`DiamondCutFacet deployed to: ${contract.address}`);
  return contract;
}

export async function deployDiamond(
  {
    ownerAddress,
    diamondCutAddress,
  }: {
    ownerAddress: string;
    diamondCutAddress: string;
  },
  {}: Libraries,
  hre: HardhatRuntimeEnvironment
) {
  const factory = await hre.ethers.getContractFactory("Diamond");
  const contract = await factory.deploy(ownerAddress, diamondCutAddress);
  await contract.deployTransaction.wait();
  console.log(`Diamond deployed to: ${contract.address}`);
  return contract;
}

export async function deployDiamondInit(
  {
    targetContract,
  }: {
    targetContract: string;
  },
  libraries: Libraries,
  hre: HardhatRuntimeEnvironment
) {
  // Initialize contract provides a function that is called when the diamond is upgraded to initialize state variables
  // Read about how the diamondCut function works here: https://eips.ethereum.org/EIPS/eip-2535#addingreplacingremoving-functions
  const factory = await hre.ethers.getContractFactory(targetContract, {
    libraries: libraries,
  });
  const contract = await factory.deploy();
  await contract.deployTransaction.wait();
  console.log(`${targetContract} deployed to: ${contract.address}`);
  return contract;
}

export async function deployDiamondLoupeFacet(
  {},
  {}: Libraries,
  hre: HardhatRuntimeEnvironment
) {
  const factory = await hre.ethers.getContractFactory("DiamondLoupeFacet");
  const contract = await factory.deploy();
  await contract.deployTransaction.wait();
  console.log(`DiamondLoupeFacet deployed to: ${contract.address}`);
  return contract;
}

export async function deployOwnershipFacet(
  {},
  {}: Libraries,
  hre: HardhatRuntimeEnvironment
) {
  const factory = await hre.ethers.getContractFactory("OwnershipFacet");
  const contract = await factory.deploy();
  await contract.deployTransaction.wait();
  console.log(`OwnershipFacet deployed to: ${contract.address}`);
  return contract;
}

export async function deployLobbyFacet(
  {},
  {}: Libraries,
  hre: HardhatRuntimeEnvironment
) {
  const factory = await hre.ethers.getContractFactory("DFLobbyFacet");
  const contract = await factory.deploy();
  await contract.deployTransaction.wait();
  console.log(`DFLobbyFacet deployed to: ${contract.address}`);
  return contract;
}
