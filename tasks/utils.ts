import { subtask } from "hardhat/config";
import { HardhatRuntimeEnvironment, Libraries } from "hardhat/types";

subtask("utils:assertChainId", "Assert proper network is selectaed").setAction(
  assertChainId
);

async function assertChainId(
  {
    appName,
  }: {
    appName: string;
  },
  hre: HardhatRuntimeEnvironment
) {
  const { NETWORK_ID } = hre.contracts[appName];

  if (hre.network.config.chainId !== NETWORK_ID) {
    throw new Error(
      `Hardhat defined network chain id ${hre.network.config.chainId} is NOT same as ${appName} contracts network id: ${NETWORK_ID}.`
    );
  }
}

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
