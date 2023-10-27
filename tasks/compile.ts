import * as fs from "fs/promises";
import * as path from "path";

import { utils } from "ethers";
import { TASK_COMPILE } from "hardhat/builtin-tasks/task-names";
import { task } from "hardhat/config";
import type {
  HardhatArguments,
  HardhatRuntimeEnvironment,
  RunSuperFunction,
  TaskArguments,
} from "hardhat/types";
import * as prettier from "prettier";

import * as diamondUtils from "../utils/diamond";

const { Fragment, FormatTypes } = utils;

task(TASK_COMPILE, "hook the compile step to copy our abis after").setAction(
  copyAbi,
);

async function copyAbi(
  args: HardhatArguments,
  hre: HardhatRuntimeEnvironment,
  runSuper: RunSuperFunction<TaskArguments>,
) {
  const out = await runSuper(args);

  const contracts = await hre.artifacts.getAllFullyQualifiedNames();

  const abisDir = path.join(
    hre.packageDirs["@ringuniversus/contracts"],
    "abis",
  );

  await fs.mkdir(abisDir, { recursive: true });

  const mergedAbisByApps: Record<string, any[]> = {
    vendor: [],
    // shared: [],
    town: [],
    ring: [],
    coin: [],
    bounty: [],
    player: [],
    equipment: [],
    admin: [],
  };

  for (const contractName of contracts) {
    if (!["Facet"].some((m) => contractName.match(m))) {
      // console.log(
      //   `Skipping ${contractName} because it didn't match any \`include\` patterns.`
      // );
      continue;
    }
    if (["interface", "Interface"].some((m) => contractName.match(m))) {
      // console.log(
      //   `Skipping ${contractName} because it didn't match any \`include\` patterns.`
      // );
      continue;
    }
    const appName = contractName.split("/")[1];

    console.log(`Including ${contractName} in your RingUniversus ABI.`);

    const { abi } = await hre.artifacts.readArtifact(contractName);

    const validAbi = abi.filter((abiElement, index, abi) => {
      if (abiElement.type === "constructor") {
        return false;
      }
      if (abiElement.type === "fallback") {
        return false;
      }
      if (abiElement.type === "receive") {
        return false;
      }
      const signature = diamondUtils.toSignature(abiElement);
      return diamondUtils.isIncluded(contractName, signature);
    });
    // Skip empty contract
    if (validAbi.length == 0 || !(appName in mergedAbisByApps)) {
      continue;
    }
    mergedAbisByApps[appName].push(...validAbi);
  }

  // console.log("mergedAbisByApps:", mergedAbisByApps);
  // console.log("mergedAbisByApps.vendor:", mergedAbisByApps.vendor);
  for (const app in mergedAbisByApps) {
    // Skip vender
    if (app === "vendor") {
      continue;
    }
    const abi = mergedAbisByApps[app];
    // Add Diamond abi
    abi.push(...mergedAbisByApps.vendor);

    // Validate same function
    const diamondAbiSet = new Set();
    abi.forEach((abi) => {
      const sighash = Fragment.fromObject(abi).format(FormatTypes.sighash);
      if (diamondAbiSet.has(sighash)) {
        // throw new Error(
        //   `Failed to create ${nameForAbi(app)} - \`${sighash}\` appears twice.`
        // );
      }
      diamondAbiSet.add(sighash);
    });

    // Generate ABI
    const artifact = createArtifact(nameForAbi(app), abi);
    await hre.artifacts.saveArtifactAndDebugFile(artifact);

    // Original ABI
    await fs.writeFile(
      path.join(abisDir, `${nameForAbi(app)}.json`),
      `${JSON.stringify(abi, null, 2)}\n`,
      {
        flag: "w",
      },
    );

    const filteredDiamondAbi = abi.filter(abiFilter);
    console.log(path.join(abisDir, `${nameForAbi(app)}_stripped.json`));
    await fs.writeFile(
      path.join(abisDir, `${nameForAbi(app)}_stripped.json`),
      await prettier.format(JSON.stringify(filteredDiamondAbi), {
        semi: false,
        parser: "json",
      }),
    );
  }

  return out;
}

function createArtifact(artifactName: string, abi: unknown[]) {
  return {
    _format: "hh-sol-artifact-1",
    contractName: artifactName,
    sourceName: artifactName,
    abi: abi,
    deployedBytecode: "",
    bytecode: "",
    linkReferences: {},
    deployedLinkReferences: {},
  } as const;
}

function nameForAbi(appName: string) {
  return `RingUniversus${appName.charAt(0).toUpperCase() + appName.slice(1)}`;
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
function abiFilter(item: any) {
  if (item.type === "function") {
    // filter out all non view fns
    if (
      item.stateMutability === "nonpayable" ||
      item.stateMutability === "payable"
    ) {
      return false;
    }

    for (const input of item.inputs) {
      if (input.type.includes("][") || input.internalType.includes("][")) {
        return false;
      }

      for (const component of input.components ?? []) {
        if (component.internalType.includes("][")) {
          return false;
        }
      }
    }

    for (const output of item.outputs) {
      if (output.type.includes("][") || output.internalType.includes("][")) {
        return false;
      }

      for (const component of output.components ?? []) {
        if (component.internalType.includes("][")) {
          return false;
        }
      }
    }
  }
  return true;
}
