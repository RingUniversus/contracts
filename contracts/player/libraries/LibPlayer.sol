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
import {Info, EquipmentSlot, Status} from "../Types.sol";

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
        return IRUEquipmentFacet(gs().equipmentAddress);
    }

    function coinContract() public view returns (IRUCoinFacet) {
        return IRUCoinFacet(gs().coinAddress);
    }

    function ringContract() public view returns (IRURingFacet) {
        return IRURingFacet(gs().ringAddress);
    }

    function townContract() public view returns (IRUTownFacet) {
        return IRUTownFacet(gs().townAddress);
    }

    function bountyContract() public view returns (IRUBountyFacet) {
        return IRUBountyFacet(gs().bountyAddress);
    }

    function info(address _player) public view returns (Info memory) {
        return gs().info[_player];
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
        // Neck
        (_speedMulti, _attackPowerMulti) = eMultied(
            gs().equipmentSlots[_player][EquipmentSlot.Neck],
            _speedMulti,
            _attackPowerMulti
        );
        // Head
        (_speedMulti, _attackPowerMulti) = eMultied(
            gs().equipmentSlots[_player][EquipmentSlot.Head],
            _speedMulti,
            _attackPowerMulti
        );
        // Back
        (_speedMulti, _attackPowerMulti) = eMultied(
            gs().equipmentSlots[_player][EquipmentSlot.Back],
            _speedMulti,
            _attackPowerMulti
        );
        // Back
        (_speedMulti, _attackPowerMulti) = eMultied(
            gs().equipmentSlots[_player][EquipmentSlot.Back],
            _speedMulti,
            _attackPowerMulti
        );
        // RightHand
        (_speedMulti, _attackPowerMulti) = eMultied(
            gs().equipmentSlots[_player][EquipmentSlot.RightHand],
            _speedMulti,
            _attackPowerMulti
        );
        // LeftHand
        (_speedMulti, _attackPowerMulti) = eMultied(
            gs().equipmentSlots[_player][EquipmentSlot.LeftHand],
            _speedMulti,
            _attackPowerMulti
        );
        // LeftHand
        (_speedMulti, _attackPowerMulti) = eMultied(
            gs().equipmentSlots[_player][EquipmentSlot.LeftHand],
            _speedMulti,
            _attackPowerMulti
        );
        // Body
        (_speedMulti, _attackPowerMulti) = eMultied(
            gs().equipmentSlots[_player][EquipmentSlot.Body],
            _speedMulti,
            _attackPowerMulti
        );
        // FingersLT
        (_speedMulti, _attackPowerMulti) = eMultied(
            gs().equipmentSlots[_player][EquipmentSlot.FingersLT],
            _speedMulti,
            _attackPowerMulti
        );
        // FingersLI
        (_speedMulti, _attackPowerMulti) = eMultied(
            gs().equipmentSlots[_player][EquipmentSlot.FingersLI],
            _speedMulti,
            _attackPowerMulti
        );
        // FingersLM
        (_speedMulti, _attackPowerMulti) = eMultied(
            gs().equipmentSlots[_player][EquipmentSlot.FingersLM],
            _speedMulti,
            _attackPowerMulti
        );
        // FingersLR
        (_speedMulti, _attackPowerMulti) = eMultied(
            gs().equipmentSlots[_player][EquipmentSlot.FingersLR],
            _speedMulti,
            _attackPowerMulti
        );
        // FingersLL
        (_speedMulti, _attackPowerMulti) = eMultied(
            gs().equipmentSlots[_player][EquipmentSlot.FingersLL],
            _speedMulti,
            _attackPowerMulti
        );
        // FingersRT
        (_speedMulti, _attackPowerMulti) = eMultied(
            gs().equipmentSlots[_player][EquipmentSlot.FingersRT],
            _speedMulti,
            _attackPowerMulti
        );
        // FingersRI
        (_speedMulti, _attackPowerMulti) = eMultied(
            gs().equipmentSlots[_player][EquipmentSlot.FingersRI],
            _speedMulti,
            _attackPowerMulti
        );
        // FingersRM
        (_speedMulti, _attackPowerMulti) = eMultied(
            gs().equipmentSlots[_player][EquipmentSlot.FingersRM],
            _speedMulti,
            _attackPowerMulti
        );
        // FingersRR
        (_speedMulti, _attackPowerMulti) = eMultied(
            gs().equipmentSlots[_player][EquipmentSlot.FingersRR],
            _speedMulti,
            _attackPowerMulti
        );
        // FingersRL
        (_speedMulti, _attackPowerMulti) = eMultied(
            gs().equipmentSlots[_player][EquipmentSlot.FingersRL],
            _speedMulti,
            _attackPowerMulti
        );
        // Legs
        (_speedMulti, _attackPowerMulti) = eMultied(
            gs().equipmentSlots[_player][EquipmentSlot.Legs],
            _speedMulti,
            _attackPowerMulti
        );
        // Hands
        (_speedMulti, _attackPowerMulti) = eMultied(
            gs().equipmentSlots[_player][EquipmentSlot.Hands],
            _speedMulti,
            _attackPowerMulti
        );
        // Feet
        (_speedMulti, _attackPowerMulti) = eMultied(
            gs().equipmentSlots[_player][EquipmentSlot.Feet],
            _speedMulti,
            _attackPowerMulti
        );
        // Pet
        (_speedMulti, _attackPowerMulti) = eMultied(
            gs().equipmentSlots[_player][EquipmentSlot.Pet],
            _speedMulti,
            _attackPowerMulti
        );
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
        Point memory start,
        Point memory end
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
        uint256[] memory mintBaseChance = new uint256[](_maxTownToMint);
        uint256 totalChange = _maxTownToMint;
        if (_totalDistance / _segmentationDistance < _maxTownToMint) {
            totalChange = _maxTownToMint / _segmentationDistance;
        }
        for (uint256 i = 0; i < totalChange; i++) {
            mintBaseChance[i] = 10000;
        }
        if (totalChange < _maxTownToMint) {
            mintBaseChance[totalChange] =
                ((_totalDistance - totalChange * _segmentationDistance) *
                    10000) /
                _segmentationDistance;
        }
        return mintBaseChance;
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
