import fs from "fs";
import path from "path";

import { task } from "hardhat/config";
import { HardhatRuntimeEnvironment } from "hardhat/types/runtime";
import { dedent as dedentString } from "ts-dedent";

import { tscompile } from "../utils/tscompile";

task("settingIndex", "create setting index").setAction(settingIndex);

async function settingIndex(args: object, hre: HardhatRuntimeEnvironment) {
  const isDev =
    hre.network.name === "localhost" || hre.network.name === "hardhat";

  // create index file for deployed contracts to the `@ringuniversus/contracts` package
  const tsContents = dedentString`
  /**
   * This package contains deployed contract addresses, ABIs, and Typechain types
   * for the Ring Universus game.
   *
   * ## Installation
   *
   * You can install this package using [\`npm\`](https://www.npmjs.com) or
   * [\`yarn\`](https://classic.yarnpkg.com/lang/en/) by running:
   *
   * \`\`\`bash
   * npm install --save @ringuniversus/contracts
   * \`\`\`
   * \`\`\`bash
   * yarn add @ringuniversus/contracts
   * \`\`\`
   *
   * When using this in a plugin, you might want to load it with [skypack](https://www.skypack.dev)
   *
   * \`\`\`js
   * import * as contracts from 'http://cdn.skypack.dev/@ringuniversus/contracts'
   * \`\`\`
   *
   * ## Typechain
   *
   * The Typechain types can be found in the \`typechain\` directory.
   *
   * ## ABIs
   *
   * The contract ABIs can be found in the \`abis\` directory.
   *
   * @packageDocumentation
   */

  export * as town from "./src/town";
  export * as ring from "./src/ring";
  export * as coin from "./src/coin";
  export * as oblivion from "./src/oblivion";
  export * as equipment from "./src/equipment";
  export * as player from "./src/player";

  `;

  const { jsContents, jsmapContents, dtsContents, dtsmapContents } = tscompile(
    tsContents,
    "index"
  );

  const contractsFileTS = path.join(
    hre.packageDirs["@ringuniversus/contracts"],
    "index.ts"
  );
  const contractsFileJS = path.join(
    hre.packageDirs["@ringuniversus/contracts"],
    "index.js"
  );
  const contractsFileJSMap = path.join(
    hre.packageDirs["@ringuniversus/contracts"],
    "index.js.map"
  );
  const contractsFileDTS = path.join(
    hre.packageDirs["@ringuniversus/contracts"],
    "index.d.ts"
  );
  const contractsFileDTSMap = path.join(
    hre.packageDirs["@ringuniversus/contracts"],
    "index.d.ts.map"
  );

  fs.writeFileSync(contractsFileTS, tsContents);
  fs.writeFileSync(contractsFileJS, jsContents);
  fs.writeFileSync(contractsFileJSMap, jsmapContents);
  fs.writeFileSync(contractsFileDTS, dtsContents);
  fs.writeFileSync(contractsFileDTSMap, dtsmapContents);
}
