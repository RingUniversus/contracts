// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// Storage imports
import {LibStorage, Modifiers} from "../libraries/LibStorage.sol";

// Type imports
import {Point, EMetadata, ETypes, Ring, BTYOwnType} from "../../shared/Types.sol";
import {Status, Moving, Info, RandomWordsInfo} from "../Types.sol";

// Functions used in tests/development for easily modifying game state
contract RUPlayerDebugFacet is Modifiers {
    event TestEvent(uint256 timestamp);

    function testFillRandomWords(
        address _player,
        uint256 _requestId,
        uint256[] calldata _randomWords
    ) public onlyOwner {
        // Update current move random words info
        gs().currentMoveInfo[_player].randomWords = RandomWordsInfo(
            _randomWords,
            block.timestamp,
            _requestId
        );
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

    function testUpdateGameConstants(
        address cAddr,
        address rAddr,
        address tAddr
    ) public onlyOwner {
        LibStorage.gameConstants().COIN_ADDRESS = cAddr;
        LibStorage.gameConstants().RING_ADDRESS = rAddr;
        LibStorage.gameConstants().TOWN_ADDRESS = tAddr;
    }
}
