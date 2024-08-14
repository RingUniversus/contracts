// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// Storage imports
import {LibStorage, GameStorage, GameConstants} from "./LibStorage.sol";

// Interface imports
import {IRUEquipmentFacet} from "../../equipment/interfaces/IRUEquipmentFacet.sol";
import {IRUCoinFacet} from "../../coin/interfaces/IRUCoinFacet.sol";
import {IRURingFacet} from "../../ring/interfaces/IRURingFacet.sol";
import {IRUTownFacet} from "../../town/interfaces/IRUTownFacet.sol";
import {IRUBountyFacet} from "../../bounty/interfaces/IRUBountyFacet.sol";

// Libraries imports
import {SafeCast} from "../../shared/libraries/LibSafeCast.sol";
import {LibUtil} from "../../shared/libraries/LibUtil.sol";

// Type imports
import {Point} from "../../shared/Types.sol";
import {Info, EquipmentSlot, Status, Moving} from "../Types.sol";

library LibPlayer {
    using SafeCast for uint256;
    using SafeCast for int256;

    function gs() internal pure returns (GameStorage storage) {
        return LibStorage.gameStorage();
    }

    function gameConstants() internal pure returns (GameConstants storage) {
        return LibStorage.gameConstants();
    }

    function equipmentContract() public view returns (IRUEquipmentFacet) {
        return IRUEquipmentFacet(gameConstants().EQUIPMENT_ADDRESS);
    }

    function coinContract() public view returns (IRUCoinFacet) {
        return IRUCoinFacet(gameConstants().COIN_ADDRESS);
    }

    function ringContract() public view returns (IRURingFacet) {
        return IRURingFacet(gameConstants().RING_ADDRESS);
    }

    function townContract() public view returns (IRUTownFacet) {
        return IRUTownFacet(gameConstants().TOWN_ADDRESS);
    }

    function bountyContract() public view returns (IRUBountyFacet) {
        return IRUBountyFacet(gameConstants().BOUNTY_ADDRESS);
    }

    function info(address _player) public view returns (Info memory) {
        return gs().info[_player];
    }

    function currentMoveInfo(
        address _player
    ) external view returns (Moving memory) {
        return gs().currentMoveInfo[_player];
    }

    function coordsAtRatio(
        Point memory _startCoords,
        Point memory _endCoords,
        uint256 _ratio
    ) public pure returns (Point memory) {
        // _ratio must within 10000
        // 9982 means 0.9982
        // if player moved over than 99.90%, set as completed
        if (_ratio >= 10000) {
            return _endCoords;
        }
        // Calculate the difference in x and y coordinates
        int256 deltaX = _endCoords.x - _startCoords.x;
        int256 deltaY = _endCoords.y - _startCoords.y;

        // Calculate the coordinates at the given ratio
        int256 newX = _startCoords.x + (deltaX * int256(_ratio)) / 10000;
        int256 newY = _startCoords.y + (deltaY * int256(_ratio)) / 10000;

        return Point(newX, newY);
    }

    function eMultied(
        uint256 _tokenId,
        uint256 _cSpeedMulti,
        uint256 _cAPMulti
    ) public view returns (uint256, uint256) {
        if (_tokenId == 0) {
            return (10000, 10000);
        }
        (uint256 eSpeedMulti, uint256 eAttackPowerMulti) = equipmentContract()
            .eMulti(_tokenId);
        return (
            (_cSpeedMulti * eSpeedMulti) / 10000,
            (_cAPMulti * eAttackPowerMulti) / 10000
        );
    }

    function slotMulti(address _player) public view returns (uint256, uint256) {
        uint256 _speedMulti = gameConstants().BASE_MOVE_SPEED;
        uint256 _attackPowerMulti = gameConstants().BASE_ATTACK_POWER;

        EquipmentSlot[20] memory slots = [
            EquipmentSlot.Neck,
            EquipmentSlot.Head,
            EquipmentSlot.Back,
            EquipmentSlot.RightHand,
            EquipmentSlot.LeftHand,
            EquipmentSlot.Body,
            EquipmentSlot.FingersLT,
            EquipmentSlot.FingersLI,
            EquipmentSlot.FingersLM,
            EquipmentSlot.FingersLR,
            EquipmentSlot.FingersLL,
            EquipmentSlot.FingersRT,
            EquipmentSlot.FingersRI,
            EquipmentSlot.FingersRM,
            EquipmentSlot.FingersRR,
            EquipmentSlot.FingersRL,
            EquipmentSlot.Legs,
            EquipmentSlot.Hands,
            EquipmentSlot.Feet,
            EquipmentSlot.Pet
        ];

        for (uint256 i = 0; i < slots.length; i++) {
            (_speedMulti, _attackPowerMulti) = eMultied(
                gs().equipmentSlots[_player][slots[i]],
                _speedMulti,
                _attackPowerMulti
            );
        }

        return (_speedMulti, _attackPowerMulti);
    }

    /**
     * Returns the time spent on the player's current move, in seconds.
     * @param _player The address of the player.
     */
    function movingTime(address _player) public view returns (uint256) {
        Info memory _playerInfo = gs().info[_player];

        // Return 0 if the player is not moving
        if (_playerInfo.status != Status.Moving) {
            return 0;
        }

        Moving memory _moveInfo = gs().currentMoveInfo[_player];
        uint256 elapsedTime;

        // If the player has completed the movement
        if (_moveInfo.endTime != 0) {
            elapsedTime = _moveInfo.endTime - _moveInfo.startTime;
        } else {
            elapsedTime = block.timestamp - _moveInfo.startTime;
        }

        // Cap elapsed time to the predefined maximum spend time
        if (elapsedTime > _moveInfo.spendTime) {
            elapsedTime = _moveInfo.spendTime;
        }

        return elapsedTime;
    }

    function currentLocation(
        address _player
    ) public view returns (Point memory, uint256, uint256) {
        // Retrieve player's current movement details
        Moving memory playerMoveInfo = gs().currentMoveInfo[_player];

        // Calculate the ratio of distance moved by the player
        uint256 distanceMovedRatio = (movingTime(_player) *
            playerMoveInfo.speed *
            10000) / playerMoveInfo.distance;

        // Cap movedRatio to 100% if it's close to completion
        if (distanceMovedRatio >= 9990) {
            distanceMovedRatio = 10000;
        }

        // Calculate the current location based on the moved ratio
        Point memory playerCurrentLocation = coordsAtRatio(
            gs().info[_player].location,
            playerMoveInfo.target,
            distanceMovedRatio
        );
        return (playerCurrentLocation, distanceMovedRatio, movingTime(_player));
    }

    function moveInfo(
        address _player,
        Point calldata start,
        Point calldata end
    ) public view returns (uint256, uint256, uint256) {
        uint256 speed = gs().info[_player].moveSpeed;
        int256 distance = LibUtil.caculateDistance(
            end.x - start.x,
            end.y - start.y
        );
        uint256 uintDistance = distance.toUint256();
        uint256 spendTime = LibUtil.distanceSpendTime(uintDistance, speed);
        return (uintDistance, spendTime, speed);
    }

    // Calculate base chance
    function calculateChance(
        uint256 _totalDistance,
        uint256 _maxTownToMint,
        uint256 _segmentationDistance
    ) public pure returns (uint256[] memory) {
        uint256[] memory _mintRatioArray = new uint256[](_maxTownToMint);
        uint256 _actualTownToMint = _maxTownToMint;
        if (_totalDistance / _segmentationDistance < _maxTownToMint) {
            _actualTownToMint = _maxTownToMint / _segmentationDistance;
        }
        for (uint256 i = 0; i < _actualTownToMint; i++) {
            _mintRatioArray[i] = 10000;
        }
        // If actual mint town count less than max
        // increase mint ratio based on distance
        if (_actualTownToMint < _maxTownToMint) {
            _mintRatioArray[_actualTownToMint] =
                ((_totalDistance - _actualTownToMint * _segmentationDistance) *
                    10000) /
                _segmentationDistance;
        }
        return _mintRatioArray;
    }

    function formatRandomWordsWithPrecision(
        uint256[] memory randomWords,
        uint256 precision
    ) internal pure returns (uint256[] memory) {
        uint256[] memory formatedNumber = new uint256[](randomWords.length);
        for (uint256 i; i < randomWords.length; i++) {
            formatedNumber[i] = randomWords[i] % precision;
        }
        return formatedNumber;
    }

    function formatRandomWords(
        uint256[] memory randomWords,
        uint256 startIndex,
        uint256 groupSize,
        uint256 precision
    ) public pure returns (uint256[] memory) {
        uint256[] memory temp = new uint256[](groupSize);
        for (uint256 i = 0; i < groupSize; i++) {
            temp[i] = randomWords[i + startIndex];
        }
        uint256[] memory formatedWords = formatRandomWordsWithPrecision(
            temp,
            precision
        );
        return formatedWords;
    }
}
