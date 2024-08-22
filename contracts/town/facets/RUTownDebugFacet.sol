// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// Storage imports
import {Modifiers} from "../libraries/LibStorage.sol";

// Functions used in tests/development for easily modifying game state
contract RUTownDebugFacet is Modifiers {
    function testUpdateGameConstants(address pAddr) public onlyOwner {
        gameConstants().PLAYER_ADDRESS = pAddr;
    }
}
