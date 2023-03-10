import { task } from "hardhat/config";
import { HardhatRuntimeEnvironment } from "hardhat/types";

task("deploy", "deploy contracts").setAction(deploy);
task("upgrade", "upgrade contracts").setAction(upgrade);

async function deploy(args: {}, hre: HardhatRuntimeEnvironment) {
  await hre.run("settingIndex");
  await hre.run("utils:assertChainId", { appName: "player" });

  await hre.run("deployBounty");
  await hre.run("deployCoin");
  await hre.run("deployE");
  await hre.run("deployRing");
  await hre.run("deployTown");
  await hre.run("deployPlayer");
}

async function upgrade(args: {}, hre: HardhatRuntimeEnvironment) {}
