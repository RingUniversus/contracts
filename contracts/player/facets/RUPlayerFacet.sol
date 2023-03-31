// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// Library Imports
import {LibPlayer} from "../libraries/LibPlayer.sol";
import {LibUtil} from "../../shared/libraries/LibUtil.sol";
import {SafeCast} from "../../shared/libraries/LibSafeCast.sol";

// Storage imports
import {Modifiers, WithStorage} from "../libraries/LibStorage.sol";

// Type imports
import {Point, EMetadata, ETypes, Ring, BTYOwnType} from "../../shared/Types.sol";
import {Info, EquipmentSlot, Status, Moving, RandomWordsInfo, NewTownArgs, NewBountyArgs, UpdateRelatedAddressArgs} from "../Types.sol";

contract RUPlayerFacet is Modifiers {
    using SafeCast for int256;

    modifier onlyMoving() {
        require(
            gs().info[msg.sender].status == Status.Moving,
            "Player is not moving."
        );
        _;
    }

    function updateRelatedAddress(
        UpdateRelatedAddressArgs calldata _addresses
    ) external onlyOwner {
        gameConstants().FEE_ADDRESS = _addresses.feeAddress;
        gameConstants().EQUIPMENT_ADDRESS = _addresses.equipmentAddress;
        gameConstants().COIN_ADDRESS = _addresses.coinAddress;
        gameConstants().RING_ADDRESS = _addresses.ringAddress;
        gameConstants().TOWN_ADDRESS = _addresses.townAddress;
        gameConstants().BOUNTY_ADDRESS = _addresses.bountyAddress;
        gameConstants().VRF_ADDRESS = _addresses.vrfAddress;
    }

    function _updatePlayerAttributes(address _player, uint256 _eId) internal {
        // calc player new attributes
        (uint256 speed, uint256 attackPower) = LibPlayer.slotMulti(_player);
        gs().info[_player].moveSpeed = speed;
        gs().info[_player].attackPower = attackPower;
        // update E's status
        LibPlayer.equipmentContract().unequip(_eId);
    }

    function equip(EquipmentSlot _slot, uint256 _equipmentId) external {
        address _player = msg.sender;
        require(
            LibPlayer.equipmentContract().ownerOf(_equipmentId) == _player,
            "Permission error."
        );

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

    function unequip(EquipmentSlot _slot) external {
        address _player = msg.sender;
        uint256 _eId = gs().equipmentSlots[_player][_slot];
        delete gs().equipmentSlots[_player][_slot];

        _updatePlayerAttributes(_player, _eId);
    }

    function initPlayer(
        string calldata _nickname
    ) external returns (Info memory) {
        address _player = msg.sender;
        require(gs().info[_player].createdAt == 0, "Already inited.");

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
        delete gs().currentMoveInfo[_player];
    }

    function move(
        Point calldata _target
    ) external returns (uint256, uint256, uint256) {
        address player = msg.sender;
        require(
            gs().info[player].status == Status.Idle ||
                gs().info[player].status == Status.Moving,
            "Player is busy."
        );

        Point memory start;
        if (gs().info[player].status == Status.Moving) {
            // if player is moving, start new
            (start, , ) = LibPlayer.currentLocation(player);
        } else {
            // if not, start from last location
            start = gs().info[player].location;
        }
        // reset moving info before move
        _resetPlayerMoveInfo(player, start, block.timestamp);

        (uint256 distance, uint256 spendTime, uint256 speed) = LibPlayer
            .moveInfo(player, start, _target);

        // check move time
        require(spendTime >= gameConstants().MIN_TRIP_TIME, "Target too near.");
        gs().currentMoveInfo[player] = Moving({
            target: _target,
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
            randomWords: RandomWordsInfo(new uint256[](0), 0, 0)
        });
        // change player status to moving status
        gs().info[player].status = Status.Moving;
        return (distance, spendTime, speed);
    }

    function stopAndRequestRandomWords(address _player) external onlyMoving {
        require(_player == msg.sender, "Permission denied");
        // if move to near, pass rewards calculate process
        if (
            gs().currentMoveInfo[_player].endTime -
                gs().currentMoveInfo[_player].startTime <
            gameConstants().MIN_TRIP_TIME
        ) {
            (Point memory end, , ) = LibPlayer.currentLocation(_player);
            _resetPlayerMoveInfo(_player, end, block.timestamp);

            return;
        }
        // stop moving
        gs().info[_player].lastMoveTime = block.timestamp;
        gs().currentMoveInfo[_player].endTime = block.timestamp;

        // TODO
        // uint256 requestId = _vrfContract().requestRandomWords();
        // gs().vrfIdPlayer[requestId] = _player;
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) external {
        // Role check
        require(
            msg.sender == gameConstants().VRF_ADDRESS,
            "VRF contracts only."
        );
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
        Point memory _location,
        address _player
    ) internal returns (Ring memory, uint256) {
        uint256 _ringId = LibPlayer.ringContract().number(
            _location.x,
            _location.y
        );

        // Mint new ring or get exists ring info
        (Ring memory _ring, ) = LibPlayer.ringContract().safeMint(
            _ringId,
            _player
        );
        return (_ring, _ringId);
    }

    function _mintTown(
        address _player,
        Point memory p
    ) internal returns (uint256) {
        uint256 townId = LibPlayer.townContract().create(
            _player,
            Point(p.x, p.y)
        );
        return townId;
    }

    function _discoveryNewTown(
        NewTownArgs memory _calldata
    ) internal returns (uint256[] memory) {
        uint256[] memory mintBaseChance = LibPlayer.calculateChance(
            _calldata.totalDistance,
            _calldata.maxTownToMint,
            _calldata.segmentationDistance
        );

        uint256[] memory towns = new uint256[](_calldata.maxTownToMint);
        for (uint256 i = 0; i < _calldata.maxTownToMint; i++) {
            Point memory _townLocation = LibPlayer.targetPoint(
                _calldata.start,
                _calldata.end,
                _calldata.location[i]
            );
            (Ring memory _ring, uint256 _ringId) = _mintRing(
                _townLocation,
                _calldata.player
            );
            uint256 _currentChance = (_calldata.chance[i] *
                mintBaseChance[i] *
                _ring.townMintingRatio) / 100000000;
            // Skip 0 chance
            if (_currentChance == 0) {
                continue;
            }

            if (_currentChance >= _calldata.townMintRatio) {
                towns[i] = _mintTown(_calldata.player, _townLocation);
                // Update circle info
                LibPlayer.ringContract().increaseTownCount(_ringId, 1);
            }
        }

        return towns;
    }

    function _discoveryNewBounty(
        NewBountyArgs memory _calldata
    ) internal returns (bool, uint256) {
        Point memory _bountyLocation = LibPlayer.targetPoint(
            _calldata.start,
            _calldata.end,
            _calldata.location
        );
        (Ring memory _ring, uint256 _ringId) = _mintRing(
            _bountyLocation,
            _calldata.player
        );
        uint256 _bountyMintingRatio = _ring.bountyMintingRatio;

        uint256 _currentChance = (_calldata.chance * _bountyMintingRatio) /
            1000000;

        // TODO
        if (_currentChance >= _calldata.bountyMintRatio) {
            uint256 bId = LibPlayer.bountyContract().newBounty(
                _calldata.player,
                _ringId,
                _bountyLocation,
                BTYOwnType.MINT
            );
            return (true, bId);
        }
        return (false, 0);
    }

    /// @notice Claim rewards after get random words form RF
    /// @dev Change moving state after call function which require moving state
    function claim(
        address _player
    ) external returns (uint256[] memory, uint256) {
        require(
            gs().info[_player].status == Status.Moving,
            "Player is not moving."
        );

        Moving memory _moveInfo = gs().currentMoveInfo[_player];
        // Only claim rewards after random words filled by VRF
        require(
            _moveInfo.randomWords.requestId != 0,
            "Request random words first."
        );
        // check account coin balance
        // need sender to pay
        require(
            LibPlayer.coinContract().balanceOf(msg.sender) >=
                _moveInfo.maxTownToMint * gameConstants().TOWN_MINT_FEE,
            "Insufficient number of tokens."
        );

        Point memory start = Point(
            gs().info[_player].location.x,
            gs().info[_player].location.y
        );
        (Point memory end, , ) = LibPlayer.currentLocation(_player);

        uint256[] memory randomWords = _moveInfo.randomWords.randomWords;

        // calculate and mint new Town
        int256 _distance = LibUtil.caculateDistance(
            start.x - end.x,
            start.y - end.y
        );
        uint256[] memory towns = _discoveryNewTown(
            NewTownArgs({
                player: _player,
                totalDistance: _distance.toUint256(),
                maxTownToMint: _moveInfo.maxTownToMint,
                townMintRatio: _moveInfo.townMintRatio,
                segmentationDistance: _moveInfo.segmentationDistance,
                chance: LibPlayer.formatRandomWords(randomWords, 0, 3, 10000),
                location: LibPlayer.formatRandomWords(randomWords, 3, 3, 10000),
                start: start,
                end: end
            })
        );
        LibPlayer.coinContract().transferFrom(
            msg.sender,
            gameConstants().FEE_ADDRESS,
            towns.length * gameConstants().TOWN_MINT_FEE
        );

        // Chance to discovery new bounty
        uint256[] memory bountyInfo = LibPlayer.formatRandomWords(
            randomWords,
            6,
            2,
            1000000
        );
        (, uint256 bId) = _discoveryNewBounty(
            NewBountyArgs({
                player: _player,
                chance: bountyInfo[0],
                location: bountyInfo[1],
                bountyMintRatio: _moveInfo.bountyMintRatio,
                start: start,
                end: end
            })
        );

        // Change state
        _resetPlayerMoveInfo(_player, end, _moveInfo.endTime);

        return (towns, bId);
    }
}
