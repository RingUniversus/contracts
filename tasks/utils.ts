import * as fs from "fs";
import path from "path";

import { subtask } from "hardhat/config";
import { HardhatRuntimeEnvironment, Libraries } from "hardhat/types";
import { dedent as dedentString } from "ts-dedent";

import { tscompile } from "../utils/tscompile";

subtask("utils:assertChainId", "Assert proper network is selectaed").setAction(
  assertChainId,
);

type Components = "bounty" | "coin" | "equipment" | "player" | "ring" | "town";

async function assertChainId(
  { component }: { component: Components },
  hre: HardhatRuntimeEnvironment,
) {
  const { NETWORK_ID } = hre.contracts[component];

  if (hre.network.config.chainId !== NETWORK_ID) {
    throw new Error(
      `Hardhat defined network chain id ${hre.network.config.chainId} is NOT same as ${component} contracts network id: ${NETWORK_ID}.`,
    );
  }
}

export async function deployDiamondCutFacet(
  args: object,
  libraries: Libraries,
  hre: HardhatRuntimeEnvironment,
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
  libraries: Libraries,
  hre: HardhatRuntimeEnvironment,
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
  hre: HardhatRuntimeEnvironment,
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
  args: object,
  libraries: Libraries,
  hre: HardhatRuntimeEnvironment,
) {
  const factory = await hre.ethers.getContractFactory("DiamondLoupeFacet");
  const contract = await factory.deploy();
  await contract.deployTransaction.wait();
  console.log(`DiamondLoupeFacet deployed to: ${contract.address}`);
  return contract;
}

export async function deployOwnershipFacet(
  args: object,
  libraries: Libraries,
  hre: HardhatRuntimeEnvironment,
) {
  const factory = await hre.ethers.getContractFactory("OwnershipFacet");
  const contract = await factory.deploy();
  await contract.deployTransaction.wait();
  console.log(`OwnershipFacet deployed to: ${contract.address}`);
  return contract;
}

function capitalizeFirstLetter(str: string): string {
  return str.charAt(0).toUpperCase() + str.slice(1);
}

export async function saveDeploy(
  component: Components,
  args: {
    coreBlockNumber: number;
    diamondAddress: string;
    initAddress: string;
  },
  hre: HardhatRuntimeEnvironment,
) {
  const isDev =
    hre.network.name === "localhost" || hre.network.name === "hardhat";

  // Save the addresses of the deployed contracts to the `@ringuniversus/contracts` package
  const tsContents = dedentString`
  /**
   * This package contains deployed contract addresses, ABIs, and Typechain types
   * for the Ring Universus ${capitalizeFirstLetter(component)}.
   */

  /**
   * The name of the network where these contracts are deployed.
   */
  export const NETWORK = '${hre.network.name}';
  /**
   * The id of the network where these contracts are deployed.
   */
  export const NETWORK_ID = ${hre.network.config.chainId};
  /**
   * The block in which the RingUniversus contract was initialized.
   */
  export const START_BLOCK = ${isDev ? 0 : args.coreBlockNumber};
  /**
   * The address for the RingUniversus${capitalizeFirstLetter(
     component,
   )} contract.
   */
  export const CONTRACT_ADDRESS = '${args.diamondAddress}';
  /**
   * The address for the initalizer contract. Useful for lobbies.
   */
  export const INIT_ADDRESS = '${args.initAddress}';
  `;

  const { jsContents, jsmapContents, dtsContents, dtsmapContents } = tscompile(
    tsContents,
    component,
  );

  const contractsFileTS = path.join(
    hre.packageDirs["@ringuniversus/contracts"],
    `${component}.ts`,
  );
  const contractsFileJS = path.join(
    hre.packageDirs["@ringuniversus/contracts"],
    `${component}.js`,
  );
  const contractsFileJSMap = path.join(
    hre.packageDirs["@ringuniversus/contracts"],
    `${component}.js.map`,
  );
  const contractsFileDTS = path.join(
    hre.packageDirs["@ringuniversus/contracts"],
    `${component}.d.ts`,
  );
  const contractsFileDTSMap = path.join(
    hre.packageDirs["@ringuniversus/contracts"],
    `${component}.d.ts.map`,
  );

  fs.writeFileSync(contractsFileTS, tsContents);
  fs.writeFileSync(contractsFileJS, jsContents);
  fs.writeFileSync(contractsFileJSMap, jsmapContents);
  fs.writeFileSync(contractsFileDTS, dtsContents);
  fs.writeFileSync(contractsFileDTSMap, dtsmapContents);
}

interface AddressMapping {
  [key: string]: string;
}

export async function updateRelatedAddress(
  targetContract: string,
  contractAddress: string,
  addressMapping: AddressMapping,
  hre: HardhatRuntimeEnvironment,
) {
  const contract = await hre.ethers.getContractAt(
    targetContract,
    contractAddress,
  );
  const updateRelatedAddressReceipt =
    await contract.updateRelatedAddress(addressMapping);
  await updateRelatedAddressReceipt.wait();
  console.log(
    `Completed update ${targetContract}'s related contracts' address.`,
  );
}

export async function deployAdminFacet(
  targetContract: string,
  libraries: Libraries,
  hre: HardhatRuntimeEnvironment,
) {
  const factory = await hre.ethers.getContractFactory(targetContract, {
    libraries: libraries,
  });
  const contract = await factory.deploy();
  await contract.deployTransaction.wait();
  console.log(`${targetContract} deployed to: ${contract.address}`);
  return contract;
}
