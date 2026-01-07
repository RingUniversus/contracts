import hre, { artifacts, network } from "hardhat";
import { DiamondChanges } from "./libraries/diamond.js";
import { zeroAddress, zeroHash } from "viem";
import path from "node:path";

// const { viem, networkName } = await network.connect();

// const publicClient = await viem.getPublicClient();

// const diamond = await viem.getContractAt(
//   "FluxDiamond",
//   "0x4c4a2f8c81640e47606d3fd77b353e87ba015584"
// );

// console.log(diamond);
// process.exit(1);

// // for (const fragment of diamond.abi) {
// //   console.log(fragment);
// // }

// const diamondLoupe = await viem.getContractAt(
//   "DiamondInspectFacet",
//   "0x4c4a2f8c81640e47606d3fd77b353e87ba015584"
// );

// const previousFacets = await diamondLoupe.read.functionFacetPairs();
// const changes = await DiamondChanges.create(
//   ["CFacets", "AFacets"],
//   previousFacets
// );

// const diamondUpgrade = await viem.getContractAt(
//   "DiamondUpgradeFacet",
//   "0x4c4a2f8c81640e47606d3fd77b353e87ba015584"
// );

// const shouldUpgrade = await changes.verify();
// if (!shouldUpgrade) {
//   console.log("Upgrade aborted");
//   process.exit(1);
// }

// console.log("addFunctions", changes.getAddFunctions());
// console.log("replaceFunctions", changes.getReplaceFunctions());

// await changes.deploy(viem);

// const functionCall = "0x";
// const tx = await diamondUpgrade.write.upgradeDiamond([
//   changes.getAddFunctions(),
//   changes.getReplaceFunctions(),
//   // changes.getRemoveFunctions(),
//   [],
//   zeroAddress,
//   functionCall,
//   zeroHash,
//   "0x",
// ]);
// console.log("tx:", tx);
// await publicClient.waitForTransactionReceipt({ hash: tx });
// console.log("Upgrade done");

// const diamond = await viem.getContractAt(
//   "IDiamondCut",
//   "0x5f83ce28ea95c39eba5a6ce6ee0540ba8c64592a"
// );

const main = async () => {
  const { viem, networkName } = await network.connect();
  const publicClient = await viem.getPublicClient();

  // const diamondName = "CustomNFTDiamond";
  // const deployed = await import(
  //   path.join(
  //     hre.config.paths.root,
  //     "deployment",
  //     networkName,
  //     `${diamondName}.json`
  //   )
  // );
  // console.log(deployed.diamond);

  const bytecode = await publicClient.getCode({
    address: "0x0165878a594ca255338adfa4d48449f69242eb8f",
  });

  console.log(bytecode);
  const existingArtifact = await artifacts.readArtifact("CustomNFTFacet");
  console.log(existingArtifact.deployedBytecode);
  console.log(existingArtifact.deployedBytecode === bytecode);
};

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
