// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// Storage imports
import {Modifiers} from "../libraries/LibStorage.sol";

// Type imports
import {Status, Info} from "../Types.sol";

// Functions used in tests/development for easily modifying game state
contract RUPlayerDebugFacet is Modifiers {
    event TestEvent(uint256 timestamp);

    function testFillRandomWords(
        address _player,
        uint256 _requestId
    ) public requiredStatus(Status.Moving) onlyOwner {
        gs().vrfIdPlayer[_requestId] = _player;
        // stop moving
        gs().currentMoveInfo[_player].endTime = block.timestamp;
        gs().info[_player].lastMoveTime = block.timestamp;
    }

    function testUpdatePlayerInfo(
        address _player,
        uint256 _speed,
        uint256 _atkPow
    ) public onlyOwner {
        Info memory _oldInfo = gs().info[_player];
        gs().info[_player] = Info({
            nickname: _oldInfo.nickname,
            location: _oldInfo.location,
            lastMoveTime: _oldInfo.lastMoveTime,
            status: _oldInfo.status,
            moveSpeed: _speed,
            attackPower: _atkPow,
            createdAt: _oldInfo.lastMoveTime
        });
    }

    function testEventEmit() public onlyOwner {
        emit TestEvent(block.timestamp);
    }
}
