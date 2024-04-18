import { task } from "hardhat/config";
import { HardhatRuntimeEnvironment } from "hardhat/types";

task("deploy", "deploy contracts").setAction(deploy);
// task("upgrade", "upgrade contracts").setAction(upgrade);

async function deploy(args: object, hre: HardhatRuntimeEnvironment) {
  await hre.run("settingIndex");
  await hre.run("utils:assertChainId", { component: "player" });

  await hre.run("deployBounty");
  await hre.run("deployCoin");
  await hre.run("deployE");
  await hre.run("deployRing");
  await hre.run("deployTown");
  await hre.run("deployPlayer");

  await hre.run("updateRelatedAddress");
  console.log("Deploy finished.");
}

// async function upgrade(args: object, hre: HardhatRuntimeEnvironment) {}
