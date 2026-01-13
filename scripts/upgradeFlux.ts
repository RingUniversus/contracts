import { network } from "hardhat";
import { upgradeDiamond } from "./libraries/diamond.js";

const main = async () => {
  const { viem, networkName } = await network.connect();

  const diamondName = "FluxDiamond";
  const facets = [
    "DiamondUpgradeFacet",
    "DiamondInspectFacet",
    "OwnerFacet",
    "ERC165Facet",
    "ERC20TransferFacet",
    "ERC20DataFacet",
    "ERC20MetadataFacet",
    "ERC20ApproveFacet",
  ];
  await upgradeDiamond(viem, networkName, diamondName, facets);
};

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
