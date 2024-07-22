// This file uses a `organize-imports-ignore` comment because we
// need to control the ordering that Hardhat tasks are registered

import "@typechain/hardhat";
import "@nomicfoundation/hardhat-ethers";
import "@nomicfoundation/hardhat-chai-matchers";
// import "@nomicfoundation/hardhat-waffle";

import * as path from "path";

import {
  decodeBountyInitializers,
  decodeCoinInitializers,
  decodeContracts,
  decodeEquipmentInitializers,
  decodeInitializers,
  decodePlayerInitializers,
  decodeRingInitializers,
  decodeTownInitializers,
} from "@ringuniversus/settings";
import { config as dotEnvConfig } from "dotenv";
import "hardhat-contract-sizer";
import { HardhatUserConfig, extendEnvironment } from "hardhat/config.js";
import { lazyObject } from "hardhat/plugins.js";
import { HardhatRuntimeEnvironment } from "hardhat/types";

import * as settings from "./settings";
import "./tasks/compile";
import "./tasks/settingIndex";
import "./tasks/town";
import "./tasks/ring";
import "./tasks/coin";
import "./tasks/bounty";
import "./tasks/equipment";
import "./tasks/player";
import "./tasks/deploy";
import "./tasks/utils";
// import "@solidstate/hardhat-4byte-uploader";

dotEnvConfig();

const { DEPLOYER_MNEMONIC, ADMIN_PUBLIC_ADDRESS } = process.env;

// Ensure we can lookup the needed workspace packages
const packageDirs = {
  "@ringuniversus/contracts": settings.resolvePackageDir(
    "@ringuniversus/contracts"
  ),
};

extendEnvironment((env: HardhatRuntimeEnvironment) => {
  env.DEPLOYER_MNEMONIC = DEPLOYER_MNEMONIC;
  // cant easily lookup deployer.address here so well have to be ok with undefined and check it later
  env.ADMIN_PUBLIC_ADDRESS = ADMIN_PUBLIC_ADDRESS;

  env.packageDirs = packageDirs;

  env.contracts = lazyObject(() => {
    // eslint-disable-next-line @typescript-eslint/no-var-requires
    const contracts = require("@ringuniversus/contracts");
    return settings.parse(decodeContracts, contracts);
  });

  env.initializers = lazyObject(() => {
    const { initializers = {} } = settings.load(env.network.name);
    return settings.parse(decodeInitializers, initializers);
  });

  env.townInitializers = lazyObject(() => {
    const { town_initializers = {} } = settings.load(env.network.name);
    return settings.parse(decodeTownInitializers, town_initializers);
  });

  env.ringInitializers = lazyObject(() => {
    const { ring_initializers = {} } = settings.load(env.network.name);
    return settings.parse(decodeRingInitializers, ring_initializers);
  });

  env.coinInitializers = lazyObject(() => {
    const { coin_initializers = {} } = settings.load(env.network.name);
    return settings.parse(decodeCoinInitializers, coin_initializers);
  });

  env.bountyInitializers = lazyObject(() => {
    const { bounty_initializers = {} } = settings.load(env.network.name);
    return settings.parse(decodeBountyInitializers, bounty_initializers);
  });

  env.equipmentInitializers = lazyObject(() => {
    const { equipment_initializers = {} } = settings.load(env.network.name);
    return settings.parse(decodeEquipmentInitializers, equipment_initializers);
  });

  env.playerInitializers = lazyObject(() => {
    const { player_initializers = {} } = settings.load(env.network.name);
    return settings.parse(decodePlayerInitializers, player_initializers);
  });
});

// The custom rpc config, but it isn't added to networks unless we have a DEPLOYER_MNEMONIC
const customNetwork = {
  url: process.env.CUSTOM_RPC_URL ?? "https://rpc-df.xdaichain.com/",
  accounts: {
    mnemonic: DEPLOYER_MNEMONIC,
  },
  chainId: Number(process.env.CUSTOM_CHAIN_ID),
  gasMultiplier: 10,
  // gas: 1,
  // gasPrice: 10,
};

// The mainnet config, but it isn't added to networks unless we have a DEPLOYER_MNEMONIC
const mainnet = {
  // Brian's Infura endpoint (free tier)
  url: "https://mainnet.infura.io/v3/5459b6d562eb47f689c809fe0b78408e",
  accounts: {
    mnemonic: DEPLOYER_MNEMONIC,
  },
  chainId: 1,
};

const config: HardhatUserConfig = {
  defaultNetwork: "hardhat",
  networks: {
    // Check for a DEPLOYER_MNEMONIC before we add custom/mainnet network to the list of networks
    // Ex: If you try to deploy to custom without DEPLOYER_MNEMONIC, you'll see this error:
    // > Error HH100: Network custom doesn't exist
    ...(DEPLOYER_MNEMONIC ? { customNetwork } : undefined),
    ...(DEPLOYER_MNEMONIC ? { mainnet } : undefined),
    localhost: {
      url: "http://127.0.0.1:8545/",
      accounts: {
        // Same mnemonic used in the .env.example
        mnemonic:
          "change typical hire slam amateur loan grid fix drama electric seed label",
      },
      chainId: 31337,
    },
    // Used when you dont specify a network on command line, like in tests
    hardhat: {
      accounts: [
        // from/deployer is default the first address in accounts
        {
          privateKey:
            "0x044C7963E9A89D4F8B64AB23E02E97B2E00DD57FCB60F316AC69B77135003AEF",
          balance: "100000000000000000000",
        },
        // user1 in tests
        {
          privateKey:
            "0x523170AAE57904F24FFE1F61B7E4FF9E9A0CE7557987C2FC034EACB1C267B4AE",
          balance: "100000000000000000000",
        },
        // user2 in tests
        // admin account
        {
          privateKey:
            "0x67195c963ff445314e667112ab22f4a7404bad7f9746564eb409b9bb8c6aed32",
          balance: "100000000000000000000",
        },
      ],
      blockGasLimit: 16777215,
      mining: {
        auto: false,
        interval: 1000,
      },
    },
  },
  solidity: {
    version: "0.8.24",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000,
      },
    },
  },
  contractSizer: {
    alphaSort: true,
    runOnCompile: false,
    disambiguatePaths: false,
  },
  typechain: {
    outDir: path.join(packageDirs["@ringuniversus/contracts"], "typechain"),
    target: "ethers-v6",
    alwaysGenerateOverloads: false,
  },
};

export default config;
