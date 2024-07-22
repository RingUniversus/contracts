// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// Storage imports
import {Modifiers} from "../libraries/LibStorage.sol";

// Type imports
import {Status} from "../Types.sol";

// Functions used in tests/development for easily modifying game state
contract RUPlayerDebugFacet is Modifiers {
    function testFillRandomWords(
        address _player,
        uint256 _requestId
    ) public requiredStatus(Status.Moving) onlyOwner {
        gs().vrfIdPlayer[_requestId] = _player;
        // stop moving
        gs().currentMoveInfo[_player].endTime = block.timestamp;
        gs().info[_player].lastMoveTime = block.timestamp;
    }
}
