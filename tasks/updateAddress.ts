import { task } from "hardhat/config";
import { updateRelatedAddress } from "./utils";
import { HardhatRuntimeEnvironment } from "hardhat/types";

task("addressAll", "update related address after deploy").setAction(updateAll);
task("addressRing", "update related address for ring after deploy").setAction(
  updateRingAddress
);
task(
  "addressPlayer",
  "update related address for player after deploy"
).setAction(updatePlayerAddress);

async function updateRingAddress(args: object, hre: HardhatRuntimeEnvironment) {
  await updateRelatedAddress(
    "RURingAdminFacet",
    hre.contracts.ring.CONTRACT_ADDRESS,
    {
      playerAddress: hre.contracts.player.CONTRACT_ADDRESS,
    },
    hre
  );
}
async function updatePlayerAddress(
  args: object,
  hre: HardhatRuntimeEnvironment
) {
  await updateRelatedAddress(
    "RUPlayerAdminFacet",
    hre.contracts.player.CONTRACT_ADDRESS,
    {
      feeAddress: hre.playerInitializers.FEE_ADDRESS,
      equipmentAddress: hre.contracts.equipment.CONTRACT_ADDRESS,
      coinAddress: hre.contracts.coin.CONTRACT_ADDRESS,
      ringAddress: hre.contracts.ring.CONTRACT_ADDRESS,
      townAddress: hre.contracts.town.CONTRACT_ADDRESS,
      bountyAddress: hre.contracts.bounty.CONTRACT_ADDRESS,
      vrfAddress: hre.playerInitializers.VRF_ADDRESS,
    },
    hre
  );
}

async function updateAll(args: object, hre: HardhatRuntimeEnvironment) {
  await hre.run("addressRing");
  await hre.run("addressPlayer");
  //   await updateRelatedAddress(
  //     "RUBountyAdminFacet",
  //     hre.contracts.bounty.CONTRACT_ADDRESS,
  //     {
  //       playerAddress: hre.contracts.player.CONTRACT_ADDRESS,
  //     },
  //     hre
  //   );

  //   await updateRelatedAddress(
  //     "RUEquipmentAdminFacet",
  //     hre.contracts.equipment.CONTRACT_ADDRESS,
  //     {
  //       playerAddress: hre.contracts.player.CONTRACT_ADDRESS,
  //     },
  //     hre
  //   );

  //   await updateRelatedAddress(
  //     "RURingAdminFacet",
  //     hre.contracts.ring.CONTRACT_ADDRESS,
  //     {
  //       playerAddress: hre.contracts.player.CONTRACT_ADDRESS,
  //     },
  //     hre
  //   );

  //   await updateRelatedAddress(
  //     "RUTownAdminFacet",
  //     hre.contracts.town.CONTRACT_ADDRESS,
  //     {
  //       playerAddress: hre.contracts.player.CONTRACT_ADDRESS,
  //     },
  //     hre
  //   );
}
