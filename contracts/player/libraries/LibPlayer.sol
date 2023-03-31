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

    function targetPoint(
        Point memory _p1,
        Point memory _p2,
        uint256 _ratio
    ) public pure returns (Point memory) {
        // _ratio must within 10000
        // 9982 means 0.9982
        require(10000 >= _ratio && _ratio >= 0, "Ratio error.");
        int256 x;
        int256 y;
        if (_p1.x == _p2.x) {
            x = _p1.x * 10000;
            y = (_p2.y - _p1.y) * _ratio.toInt256() * 10000 + _p1.y * 100000000;
        } else {
            int256 a = ((_p2.y - _p1.y) * 10000) / (_p2.x - _p1.x);
            x = (_p2.x - _p1.x) * _ratio.toInt256() + _p1.x * 10000;
            y = a * (x - _p1.x * 10000) + _p1.y * 100000000;
        }
        return Point(x / 10000, y / 100000000);
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

    function movingTime(address _player) public view returns (uint256) {
        // If player is not moving, return 0
        if (gs().info[_player].status != Status.Moving) {
            return 0;
        }

        uint256 _realtimeSpend;
        // if player stop moving already
        if (gs().currentMoveInfo[_player].endTime != 0) {
            _realtimeSpend =
                gs().currentMoveInfo[_player].endTime -
                gs().currentMoveInfo[_player].startTime;
        } else {
            _realtimeSpend =
                block.timestamp -
                gs().currentMoveInfo[_player].startTime;
        }
        if (_realtimeSpend > gs().currentMoveInfo[_player].spendTime) {
            _realtimeSpend = gs().currentMoveInfo[_player].spendTime;
        }
        return _realtimeSpend;
    }

    function currentLocation(
        address _player
    ) public view returns (Point memory, uint256, uint256) {
        // calcuate current distance ratio based on player speed
        uint256 speed = gs().currentMoveInfo[_player].speed;
        uint256 realtimeSpend = movingTime(_player);
        // scale to save percentage detail
        realtimeSpend = realtimeSpend * 10000;
        uint256 distRatio = ((realtimeSpend * speed)) /
            gs().currentMoveInfo[_player].distance;
        if (distRatio > 10000) {
            distRatio = 10000;
        }

        Point memory _location = targetPoint(
            gs().info[_player].location,
            gs().currentMoveInfo[_player].target,
            distRatio
        );
        return (_location, distRatio, realtimeSpend / 10000);
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
