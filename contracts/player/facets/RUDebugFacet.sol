// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// Library imports
import {LibDiamond} from "../../vendor/libraries/LibDiamond.sol";

// Storage imports
import {WithStorage} from "../libraries/LibStorage.sol";

// Type imports
import {Status} from "../Types.sol";

// Functions used in tests/development for easily modifying game state
contract RUDebugFacet is WithStorage {
    modifier onlyAdmin() {
        LibDiamond.enforceIsContractOwner();
        _;
    }

    function testFillRandomWords(
        address _player,
        uint256 _requestId
    ) public onlyAdmin {
        require(
            gs().info[_player].status == Status.Moving,
            "Player is not moving."
        );
        gs().vrfIdPlayer[_requestId] = _player;
        // stop moving
        gs().currentMoveInfo[_player].endTime = block.timestamp;
        gs().info[_player].lastMoveTime = block.timestamp;
    }
}
