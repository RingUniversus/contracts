// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "hardhat/console.sol";

import {LibDiamond} from "../../vendor/libraries/LibDiamond.sol";

// Game config
struct GameConstants {
    address UNIVERSUS_DIAMOND_ADDRESS;
}

library LibStorage {
    bytes32 private constant GAME_CONSTANTS_POSITION =
        keccak256("ringuniversus.constants.game");

    function gameConstants() internal pure returns (GameConstants storage gc) {
        bytes32 position = GAME_CONSTANTS_POSITION;
        assembly {
            gc.slot := position
        }
    }
}

/**
 * The `WithStorage` contract provides a base contract for Facet contracts to inherit.
 */
contract WithStorage {
    function gameConstants() internal pure returns (GameConstants storage) {
        return LibStorage.gameConstants();
    }
}

/**
 * Shared modifiers.
 */
contract Modifiers is WithStorage {
    modifier onlyOwner() {
        console.log("*****************");
        console.log(msg.sender);
        console.log(LibDiamond.contractOwner());
        console.log("*****************");
        LibDiamond.enforceIsContractOwner();
        _;
    }
}
