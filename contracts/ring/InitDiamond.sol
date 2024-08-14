// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Base import
import {LibDiamond} from "../vendor/libraries/LibDiamond.sol";
import {IDiamondLoupe} from "../vendor/interfaces/IDiamondLoupe.sol";
import {IDiamondCut} from "../vendor/interfaces/IDiamondCut.sol";
import {IERC173} from "../vendor/interfaces/IERC173.sol";
import {IERC165} from "../vendor/interfaces/IERC165.sol";
// Custom import blow
import {WithStorage} from "./libraries/LibStorage.sol";
import {IERC721} from "@solidstate/contracts/interfaces/IERC721.sol";
import {IERC721Metadata} from "@solidstate/contracts/token/ERC721/metadata/IERC721Metadata.sol";
import {IERC721Enumerable} from "@solidstate/contracts/token/ERC721/enumerable/IERC721Enumerable.sol";
import {ERC721MetadataStorage} from "@solidstate/contracts/token/ERC721/metadata/ERC721MetadataStorage.sol";

import {Ring} from "./../shared/Types.sol";
import {LibRing} from "./libraries/LibRing.sol";

// It is expected that this contract is customized if you want to deploy your diamond
// with data from a deployment script. Use the init function to initialize state variables
// of your diamond. Add parameters to the init funciton if you need to.

struct InitArgs {
    uint256 DISTANCE;
    uint256 TOWN_MINTING_RATIO;
    uint256 TOWN_OVER_MINTING_RATIO;
    uint256 TOWN_RATIO_BONUS;
    uint256 BOUNTY_MINTING_RATIO;
    uint256 BOUNTY_RATIO_BONUS;
}

contract InitDiamond is WithStorage {
    // You can add parameters to this function in order to pass in
    // data to set your own state variables
    function init(InitArgs memory initArgs) external {
        // adding ERC165 data
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IERC173).interfaceId] = true;

        // add your own state variables
        // EIP-2535 specifies that the `diamondCut` function takes two optional
        // arguments: address _init and bytes calldata _calldata
        // These arguments are used to execute an arbitrary function using delegatecall
        // in order to set state variables in the diamond during deployment or an upgrade
        // More info here: https://eips.ethereum.org/EIPS/eip-2535#diamond-interface

        ds.supportedInterfaces[type(IERC721).interfaceId] = true;
        ds.supportedInterfaces[type(IERC721Metadata).interfaceId] = true;
        ds.supportedInterfaces[type(IERC721Enumerable).interfaceId] = true;

        gs().diamondAddress = address(this);

        gameConstants().DISTANCE = initArgs.DISTANCE;
        // Town
        gameConstants().TOWN_MINTING_RATIO = initArgs.TOWN_MINTING_RATIO;
        gameConstants().TOWN_OVER_MINTING_RATIO = initArgs
            .TOWN_OVER_MINTING_RATIO;
        gameConstants().TOWN_RATIO_BONUS = initArgs.TOWN_RATIO_BONUS;
        // Bounty
        gameConstants().BOUNTY_MINTING_RATIO = initArgs.BOUNTY_MINTING_RATIO;
        gameConstants().BOUNTY_RATIO_BONUS = initArgs.BOUNTY_RATIO_BONUS;

        initDefaults();
    }

    function initDefaults() internal {
        // First ring mint by defaults by deployer
        gs().rings[0] = Ring({
            townLimit: 10,
            townCount: 0,
            townMintingRatio: gameConstants().TOWN_MINTING_RATIO,
            bountyMintingRatio: gameConstants().BOUNTY_MINTING_RATIO,
            explorer: msg.sender,
            exploredAt: block.timestamp
        });
        gs().nextRingId = 1;

        // Todo: test
        for (uint i = 0; i < 9; i++) {
            LibRing.mintByExplorer(msg.sender);
        }
    }
}
