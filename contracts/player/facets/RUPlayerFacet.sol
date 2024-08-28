// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// Library Imports
import {LibPlayer} from "../libraries/LibPlayer.sol";
import {LibUtil} from "../../shared/libraries/LibUtil.sol";
import {SafeCast} from "../../shared/libraries/LibSafeCast.sol";

// Storage imports
import {Modifiers, GameConstants} from "../libraries/LibStorage.sol";

// Type imports
import {Point, EMetadata, ETypes, Ring, BTYOwnType, Town} from "../../shared/Types.sol";
import {Info, EquipmentSlot, Status, Moving, RandomWordsInfo, NewTownArgs, NewBountyArgs, TeleportType} from "../Types.sol";

// Error imports
import {NotVRFContract, InitializedPlayer} from "../Errors.sol";
import {EquipmentNotOwned} from "../../shared/Errors.sol";

contract RUPlayerFacet is Modifiers {
    using SafeCast for int256;

    // Event to log player movement details
    event PlayerMoved(
        address indexed player,
        Point target,
        uint256 distance,
        uint256 spendTime,
        uint256 speed,
        uint256 timestamp
    );

    // Event to log when a move is stopped
    event MoveStopped(
        address indexed player,
        Point startCoords,
        Point endCoords,
        uint256 timestamp,
        bool rewardsCalculated
    );

    function _updatePlayerAttributes(address _player, uint256 _eId) internal {
        // calc player new attributes
        (uint256 speed, uint256 attackPower) = LibPlayer.slotMulti(_player);
        gs().info[_player].moveSpeed = speed;
        gs().info[_player].attackPower = attackPower;
        // update E's status
        LibPlayer.equipmentContract().unequip(_eId);
    }

    function equip(
        EquipmentSlot _slot,
        uint256 _equipmentId
    ) external onlyInitializedPlayer(msg.sender) {
        address _player = msg.sender;
        if (LibPlayer.equipmentContract().ownerOf(_equipmentId) != _player)
            revert EquipmentNotOwned({tokenId: _equipmentId});

        EMetadata memory eMetadata = LibPlayer.equipmentContract().metadata(
            _equipmentId
        );
        // equip slot check
        if (
            (_slot == EquipmentSlot.Neck &&
                eMetadata.eType == ETypes.Necklace) ||
            (_slot == EquipmentSlot.Head && eMetadata.eType == ETypes.Helmet) ||
            (_slot == EquipmentSlot.Back && eMetadata.eType == ETypes.Wings) ||
            ((_slot == EquipmentSlot.RightHand ||
                _slot == EquipmentSlot.LeftHand) &&
                (eMetadata.eType == ETypes.Shield ||
                    eMetadata.eType == ETypes.Weapon)) ||
            (_slot == EquipmentSlot.Body && eMetadata.eType == ETypes.Chest) ||
            ((_slot >= EquipmentSlot.FingersLT &&
                _slot <= EquipmentSlot.FingersRL) &&
                eMetadata.eType == ETypes.Ring) ||
            (_slot == EquipmentSlot.Legs && eMetadata.eType == ETypes.Pants) ||
            (_slot == EquipmentSlot.Hands &&
                eMetadata.eType == ETypes.Gloves) ||
            (_slot == EquipmentSlot.Feet && eMetadata.eType == ETypes.Boots) ||
            (_slot == EquipmentSlot.Pet && eMetadata.eType == ETypes.Pet)
        ) {
            gs().equipmentSlots[_player][_slot] = _equipmentId;
        } else {
            revert("Type error.");
        }

        _updatePlayerAttributes(_player, _equipmentId);
    }

    function unequip(
        EquipmentSlot _slot
    ) external onlyInitializedPlayer(msg.sender) {
        address _player = msg.sender;
        uint256 _eId = gs().equipmentSlots[_player][_slot];
        delete gs().equipmentSlots[_player][_slot];

        _updatePlayerAttributes(_player, _eId);
    }

    function initPlayer(
        string calldata _nickname
    ) external returns (Info memory) {
        address _player = msg.sender;
        if (gs().info[_player].createdAt != 0)
            revert InitializedPlayer({sender: _player});

        gs().info[_player] = Info({
            nickname: _nickname,
            location: Point(0, 0),
            lastMoveTime: 0,
            status: Status.Idle,
            moveSpeed: gameConstants().BASE_MOVE_SPEED,
            attackPower: gameConstants().BASE_ATTACK_POWER,
            createdAt: block.timestamp
        });
        return gs().info[_player];
    }

    function playerInfo(address _player) external view returns (Info memory) {
        return LibPlayer.info(_player);
    }

    function currentLocation(
        address _player
    ) external view returns (Point memory, uint256, uint256) {
        return LibPlayer.currentLocation(_player);
    }

    function movingTime(address _player) external view returns (uint256) {
        return LibPlayer.movingTime(_player);
    }

    function currentMoveInfo(
        address _player
    ) external view returns (Moving memory) {
        return LibPlayer.currentMoveInfo(_player);
    }

    function slotMulti(
        address _player
    ) external view returns (uint256, uint256) {
        return LibPlayer.slotMulti(_player);
    }

    function moveInfo(
        address _player,
        Point calldata start,
        Point calldata end
    ) external view returns (uint256, uint256, uint256) {
        return LibPlayer.moveInfo(_player, start, end);
    }

    function _resetPlayerMoveInfo(
        address _player,
        Point memory _end,
        uint256 _endTime
    ) internal {
        gs().info[_player].status = Status.Idle;
        gs().info[_player].location = _end;
        gs().info[_player].lastMoveTime = _endTime;
    }

    function move(
        Point calldata _target
    )
        external
        onlyInitializedPlayer(msg.sender)
        returns (uint256 distance, uint256 spendTime, uint256 speed)
    {
        address _player = msg.sender;
        Info storage _playerInfo = gs().info[_player];
        require(
            _playerInfo.status == Status.Idle ||
                _playerInfo.status == Status.Moving,
            "Player is busy."
        );

        // Determine the start location based on the player's status
        Point memory startLocation;
        if (_playerInfo.status == Status.Moving) {
            (startLocation, , ) = LibPlayer.currentLocation(_player);
        } else {
            startLocation = _playerInfo.location;
        }

        // Reset player's move info and update status to Moving
        _resetPlayerMoveInfo(_player, startLocation, block.timestamp);
        _playerInfo.status = Status.Moving;

        // Calculate movement details
        (distance, spendTime, speed) = LibPlayer.moveInfo(
            _player,
            startLocation,
            _target
        );

        // Ensure the movement time is above the minimum required
        require(spendTime >= gameConstants().MIN_TRIP_TIME, "Target too near.");

        // Update the player's current movement information
        gs().currentMoveInfo[_player] = Moving({
            target: _target,
            start: startLocation,
            end: Point(0, 0),
            spendTime: spendTime,
            speed: speed,
            distance: distance,
            startTime: block.timestamp,
            endTime: 0,
            maxTownToMint: gameConstants().MAX_MINT_TOW_PER_MOVE,
            townMintRatio: gameConstants().TOWN_MINT_RATIO_PER_MOVE,
            bountyMintRatio: gameConstants().BOUNTY_MINT_RATIO_PER_MOVE,
            segmentationDistance: gameConstants()
                .SEGMENTATION_DISTANCE_PER_MOVE,
            randomWords: RandomWordsInfo(new uint256[](0), 0, 0),
            isClaimed: false
        });

        // Emit the PlayerMoved event
        emit PlayerMoved(
            _player,
            _target,
            distance,
            spendTime,
            speed,
            block.timestamp
        );

        return (distance, spendTime, speed);
    }

    function _rewardClaimable(
        uint256 moveDuration,
        uint256 distance
    ) internal view returns (bool) {
        // TODO: add distance check?
        if (moveDuration < gameConstants().MIN_TRIP_TIME) {
            return false;
        }
        return true;
    }

    function stopAndRequestRandomWords()
        external
        onlyInitializedPlayer(msg.sender)
        requiredStatus(Status.Moving)
        returns (bool)
    {
        address _player = msg.sender;
        Moving storage _moveInfo = gs().currentMoveInfo[_player];
        require(_moveInfo.endTime == 0, "Current move already stopped.");

        uint256 moveDuration = block.timestamp - _moveInfo.startTime;
        _moveInfo.endTime = block.timestamp;
        (Point memory endCoords, , ) = LibPlayer.currentLocation(_player);

        bool claimable = _rewardClaimable(moveDuration, 0);
        // Stop the move and record the info
        _resetPlayerMoveInfo(_player, endCoords, block.timestamp);
        gs().currentMoveInfo[_player].end = endCoords;

        emit MoveStopped(
            _player,
            _moveInfo.start,
            endCoords,
            block.timestamp,
            claimable
        );

        // TODO
        // uint256 requestId = _vrfContract().requestRandomWords();
        // gs().vrfIdPlayer[requestId] = _player;
        return claimable;
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) external {
        // Role check
        if (msg.sender != gameConstants().VRF_ADDRESS) revert NotVRFContract();
        address player = gs().vrfIdPlayer[requestId];
        // Update current move random words info
        gs().currentMoveInfo[player].randomWords = RandomWordsInfo(
            randomWords,
            block.timestamp,
            requestId
        );
        // Remove useless random words
        gs().vrfIdPlayer[requestId] = address(0);
    }

    function _mintRing(
        uint256[] memory _ringsToMint,
        address _player
    ) internal {
        // Mint ring
        for (uint256 i = 0; i <= _ringsToMint.length; i++) {
            if (_ringsToMint[i] == 0) {
                continue;
            }
            if (!LibPlayer.ringContract().isMinted(_ringsToMint[i])) {
                LibPlayer.ringContract().safeMint(_player, _ringsToMint[i]);
            }
        }
    }

    function _ringMetadata(
        Point memory p
    ) internal view returns (Ring memory, uint256, bool) {
        uint256 _ringId = LibPlayer.ringContract().number(p.x, p.y);
        return (
            LibPlayer.ringContract().metadata(_ringId),
            _ringId,
            LibPlayer.ringContract().isMinted(_ringId)
        );
    }

    function _mintTown(
        address _player,
        Point memory p
    ) internal returns (uint256) {
        uint256 townId = LibPlayer.townContract().create(_player, p);
        return townId;
    }

    function _discoveryNewTown(
        NewTownArgs memory _calldata
    ) internal returns (uint256, uint256[] memory) {
        uint256 _actualTownToMint = _calldata.totalDistance /
            _calldata.segmentationDistance;
        if (_actualTownToMint > _calldata.maxTownToMint) {
            _actualTownToMint = _calldata.maxTownToMint;
        }

        // TODO add this to constants, 10000 means 100%
        uint256 baseRatio = 10000;
        uint256 mintedTown = 0;
        uint256[] memory ringsToMint = new uint256[](_actualTownToMint);
        for (uint256 i = 0; i < _actualTownToMint; i++) {
            Point memory _townLocation = LibPlayer.coordsAtRatio(
                _calldata.start,
                _calldata.end,
                _calldata.location[i]
            );
            (Ring memory _ring, uint256 _ringId, bool isMinted) = _ringMetadata(
                _townLocation
            );
            if (!isMinted) {
                ringsToMint[i] = _ringId;
            }
            // userRatio * baseRadio * ringRatio
            // 10000(100%) * 10000(100%) * 10000(100%)
            uint256 _currentChance = (_calldata.townMintRatio *
                baseRatio *
                _ring.townMintingRatio) / 100000000;
            // Skip 0 chance
            if (_currentChance == 0) {
                continue;
            }

            // RNG chance chance (0.01% - 100%)
            if (_currentChance > _calldata.chance[i] + 1) {
                _mintTown(_calldata.player, _townLocation);
                // Update circle info
                LibPlayer.ringContract().increaseTownCount(_ringId, 1);
                mintedTown = mintedTown + 1;
            }
        }

        return (mintedTown, ringsToMint);
    }

    function teleport(
        TeleportType _ttype,
        uint256 _tid
    ) external returns (Point memory, Point memory, uint256) {
        address _player = msg.sender;
        Info memory _playerInfo = gs().info[_player];
        require(
            _playerInfo.status == Status.Idle,
            "Teleport need play stop moving first."
        );
        require(
            gs().currentMoveInfo[_player].isClaimed,
            "Claim your rewards first."
        );

        Point memory _playerCurrentCoords = _playerInfo.location;
        uint256 _playerRingId = LibPlayer.ringContract().number(
            _playerCurrentCoords.x,
            _playerCurrentCoords.y
        );

        // TODO: Add to game constants
        uint256 baseFee = 0;
        uint256 passingRingFee = 0;
        Point memory targetCoords;

        // Teleport rto minted town
        // if (_ttype == TeleportType.Town) {
        Town memory town = LibPlayer.townContract().metadata(_tid);
        require(town.createdAt != 0, "Target not exists!");
        targetCoords = town.location;

        baseFee += 10;
        passingRingFee = 50;
        // }

        uint256 targetRingId = LibPlayer.ringContract().number(
            targetCoords.x,
            targetCoords.y
        );

        uint256 passingRingNo = 0;
        if (_playerRingId > targetRingId) {
            passingRingNo = _playerRingId - targetRingId;
        } else {
            passingRingNo = targetRingId - _playerRingId;
        }

        uint256 totalFee = (baseFee + passingRingFee * passingRingNo) * 1e18;
        _resetPlayerMoveInfo(_player, targetCoords, block.timestamp);
        if (totalFee > 0) {
            LibPlayer.coinContract().transferFrom(
                _player,
                gameConstants().FEE_ADDRESS,
                totalFee
            );
        }
        return (_playerCurrentCoords, targetCoords, totalFee);
    }

    // function _discoveryNewBounty(
    //     NewBountyArgs memory _calldata
    // ) internal returns (bool, uint256) {
    //     Point memory _bountyLocation = LibPlayer.coordsAtRatio(
    //         _calldata.start,
    //         _calldata.end,
    //         _calldata.location % 10000
    //     );
    //     (Ring memory _ring, uint256 _ringId) = _mintRing(
    //         _bountyLocation,
    //         _calldata.player
    //     );
    //     uint256 _bountyMintingRatio = _ring.bountyMintingRatio;

    //     uint256 _currentChance = (_calldata.chance * _bountyMintingRatio) /
    //         1000000;

    //     // TODO
    //     if (_currentChance >= _calldata.bountyMintRatio) {
    //         uint256 bId = LibPlayer.bountyContract().newBounty(
    //             _calldata.player,
    //             _ringId,
    //             _bountyLocation,
    //             BTYOwnType.MINT
    //         );
    //         return (true, bId);
    //     }
    //     return (false, 0);
    // }

    /// @notice Claim rewards after get random words form RF
    /// @dev Change moving state after call function which require moving state
    function claim()
        external
        onlyInitializedPlayer(msg.sender)
        requiredStatus(Status.Idle)
        returns (uint256, uint256)
    {
        address _player = msg.sender;

        Moving memory _moveInfo = gs().currentMoveInfo[_player];
        // Only claim rewards after random words filled by VRF
        require(
            _moveInfo.randomWords.requestId != 0,
            "Request random words first."
        );
        require(!_moveInfo.isClaimed, "Rewards already clamied.");

        // check account coin balance
        // need sender to pay
        uint256 mintingCost = _moveInfo.maxTownToMint *
            gameConstants().TOWN_MINT_FEE;
        require(
            LibPlayer.coinContract().balanceOf(_player) >= mintingCost,
            "Insufficient number of tokens."
        );

        Point memory startLocation = _moveInfo.start;
        Point memory endLocation = _moveInfo.end;

        // TODO: Change state
        gs().currentMoveInfo[_player].isClaimed = true;

        uint256[] memory randomWords = _moveInfo.randomWords.randomWords;

        // Calculate distance and mint new towns
        uint256 travelDistance = LibUtil
            .caculateDistance(
                startLocation.x - endLocation.x,
                startLocation.y - endLocation.y
            )
            .toUint256();

        (
            uint256 mintedTownCount,
            uint256[] memory ringsToMint1
        ) = _discoveryNewTown(
                NewTownArgs({
                    player: _player,
                    totalDistance: travelDistance,
                    maxTownToMint: _moveInfo.maxTownToMint,
                    townMintRatio: _moveInfo.townMintRatio,
                    segmentationDistance: _moveInfo.segmentationDistance,
                    chance: LibPlayer.formatRandomWords(
                        randomWords,
                        0,
                        3,
                        10000
                    ),
                    location: LibPlayer.formatRandomWords(
                        randomWords,
                        3,
                        3,
                        10000
                    ),
                    start: startLocation,
                    end: endLocation
                })
            );
        if (mintedTownCount > 0) {
            LibPlayer.coinContract().transferFrom(
                _player,
                gameConstants().FEE_ADDRESS,
                mintedTownCount * gameConstants().TOWN_MINT_FEE
            );
        }

        // if (ringsToMint1.length > 0) {
        //     uint256[] memory ringsToMint = new uint256[](ringsToMint1.length);
        //     for (uint256 index = 0; index < ringsToMint1.length; index++) {
        //         ringsToMint[index] = ringsToMint1[index];
        //     }

        //     // Mint ring
        //     _mintRing(ringsToMint, _player);
        // }

        // Chance to discovery new bounty
        // uint256[] memory bountyData = LibPlayer.formatRandomWords(
        //     randomWords,
        //     6,
        //     2,
        //     1000000
        // );
        // (, uint256 bountyId) = _discoveryNewBounty(
        //     NewBountyArgs({
        //         player: _player,
        //         chance: bountyData[0],
        //         location: bountyData[1],
        //         bountyMintRatio: _moveInfo.bountyMintRatio,
        //         start: startLocation,
        //         end: endLocation
        //     })
        // );

        return (mintedTownCount, 0);
    }

    function testDataCheck(
        address _player
    ) public view returns (Point memory, uint256) {
        Moving memory _moveInfo = gs().currentMoveInfo[_player];
        // Only claim rewards after random words filled by VRF
        require(
            _moveInfo.randomWords.requestId != 0,
            "Request random words first."
        );
        require(!_moveInfo.isClaimed, "Rewards already clamied.");

        // check account coin balance
        // need sender to pay
        uint256 mintingCost = _moveInfo.maxTownToMint *
            gameConstants().TOWN_MINT_FEE;

        Point memory startLocation = _moveInfo.start;
        Point memory endLocation = _moveInfo.end;

        // TODO: Change state
        // gs().currentMoveInfo[_player].isClaimed = true;

        uint256[] memory randomWords = _moveInfo.randomWords.randomWords;

        uint256[] memory location = LibPlayer.formatRandomWords(
            randomWords,
            3,
            3,
            10000
        );

        Point memory _townLocation = LibPlayer.coordsAtRatio(
            startLocation,
            endLocation,
            location[2]
        );

        (Ring memory _ring, uint256 _ringId, bool isMinted) = _ringMetadata(
            _townLocation
        );

        // TODO add this to constants, 10000 means 100%
        uint256 baseRatio = 10000;
        uint256 _currentChance = (_moveInfo.townMintRatio *
            baseRatio *
            _ring.townMintingRatio) / 100000000;

        return (_townLocation, _ringId);
    }

    function test(uint256 _ringId) external {
        LibPlayer.ringContract().increaseTownCount(_ringId, 1);
    }

    /**
     * Game Getter
     */
    function getGameConstants() public pure returns (GameConstants memory) {
        return gameConstants();
    }
}
