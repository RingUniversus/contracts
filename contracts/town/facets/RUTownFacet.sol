// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// Contract imports
import {SolidStateERC721} from "@solidstate/contracts/token/ERC721/SolidStateERC721.sol";

// Library Imports
import {UintUtils} from "@solidstate/contracts/utils/UintUtils.sol";

// Storage imports
import {Modifiers, WithStorage, GameConstants} from "../libraries/LibStorage.sol";

// Type imports
import {Point} from "../../shared/Types.sol";
import {Town, Attribute} from "../Types.sol";

// Errors imports
import {InsufficientExplorerSlot} from "../Errors.sol";

contract RUTownFacet is Modifiers, SolidStateERC721 {
    using UintUtils for uint256;

    function metadata(uint256 _tokenId) public view returns (Town memory) {
        return gs().towns[_tokenId];
    }

    function attribute(
        uint256 _tokenId
    ) public view returns (Attribute memory) {
        return gs().townAttributes[_tokenId];
    }

    function metadataAtIndex(uint256 _idx) public view returns (Town memory) {
        return gs().towns[tokenByIndex(_idx)];
    }

    function explorerList(
        uint256 _tokenId
    ) public view returns (address[] memory) {
        uint256 _townExplorerSlot = metadata(_tokenId).explorerSlot;
        address[] memory _explorerList = new address[](_townExplorerSlot);
        for (uint256 index = 0; index < _townExplorerSlot; index++) {
            _explorerList[index] = gs().townExplorers[_tokenId][index];
        }
        return _explorerList;
    }

    // function changeAttributes(uint256 _tokenId, int256 _step) public {
    //     gs().townAttributes[_tokenId].explorerCounter =
    //         gs().townAttributes[_tokenId].explorerCounter +
    //         uint256(_step);
    // }

    /**
     * Create new Town
     */
    function create(
        address _owner,
        Point memory _location
    ) public onlyOwnerOrPlayer returns (uint256) {
        uint256 tokenId = gs().townTokenId++;

        _mint(_owner, tokenId);

        // Init town's metadata
        Town memory newTown = Town({
            // Radix 10 with zero padding 5
            nickname: string.concat("UNiT #", tokenId.toString(10, 5)),
            flagPath: "",
            location: _location,
            level: 1,
            explorerFeeRatio: gameConstants().EXPLORER_FEE_RATIO,
            explorerSlot: gameConstants().EXPLORER_SLOT,
            createdAt: block.timestamp
        });
        gs().towns[tokenId] = newTown;

        // Init town's attr
        // Attribute memory attr = Attribute({explorerCounter: 0});
        // gs().townAttributes[tokenId] = attr;

        return tokenId;
    }

    /**
     * Calculate rewards amounts
     */
    function exploreRewards(
        uint256 _tokenId,
        uint256 _spendTime,
        uint256 _attackPower
    ) public view returns (uint256, uint256, uint256) {
        if (_spendTime <= gameConstants().MIN_EXPLORE_TIME) {
            return (
                0,
                gs().towns[_tokenId].explorerFeeRatio,
                gameConstants().SYSTEM_EXPLORE_FEE_RATIO
            );
        }
        // max rewards time limit
        if (_spendTime > gameConstants().MAX_EXPLORE_TIME) {
            _spendTime = gameConstants().MAX_EXPLORE_TIME;
        }
        // Attack power: 100 means 1.00 so we need to multi 1e16
        // Base rewards for 1 week with 1 attack power should around 1k
        uint256 reward = (_spendTime * _attackPower * 1e16) / 600;
        if (reward > gameConstants().MAX_EXPLORE_REWARDS) {
            reward = gameConstants().MAX_EXPLORE_REWARDS;
        }
        // players actual rewards, town owner's fee, system's fee
        return (
            reward,
            gs().towns[_tokenId].explorerFeeRatio,
            gameConstants().SYSTEM_EXPLORE_FEE_RATIO
        );
    }

    /**
     * Add a player as town's explorer
     */
    function addExplorer(
        uint256 _tokenId,
        address _player
    ) public onlyOwnerOrPlayer {
        uint256 townExplorerCount = attribute(_tokenId).explorerCounter;
        uint256 townExplorerSlot = metadata(_tokenId).explorerSlot;
        if (townExplorerSlot <= townExplorerCount)
            revert InsufficientExplorerSlot();

        for (uint256 index = 0; index < townExplorerSlot; index++) {
            if (gs().townExplorers[_tokenId][index] == address(0)) {
                // allign player
                gs().townExplorers[_tokenId][index] = _player;
                // increase counter
                gs().townAttributes[_tokenId].explorerCounter =
                    townExplorerCount +
                    1;
                break;
            }
        }
    }

    /**
     * Remove a explorer from town
     */
    function removeExplorer(
        uint256 _tokenId,
        address _player
    ) public onlyOwnerOrPlayer {
        uint256 townExplorerCount = attribute(_tokenId).explorerCounter;
        uint256 townExplorerSlot = metadata(_tokenId).explorerSlot;
        if (townExplorerCount == 0) {
            return;
        }

        for (uint256 index = 0; index < townExplorerSlot; index++) {
            if (gs().townExplorers[_tokenId][index] == _player) {
                // remove explorer
                gs().townExplorers[_tokenId][index] = address(0);
                // decrease counter
                gs().townAttributes[_tokenId].explorerCounter =
                    townExplorerCount -
                    1;
                break;
            }
        }
    }

    /**
     * Terminate timeout explorer and share rewards to caller & town owner
     */
    // function terminateExplore(uint256 _townId, address _player) public {
    //     address _townOwner = msg.sender;
    //     require(_ownerOf(_townId) == _townOwner, "Not owned.");
    //     (uint256 _timeSpent, uint256 _targetTownId) = _playerContract()
    //         .exploreInfo(_player);
    //     require(
    //         _timeSpent > _systemSettingsContract().minTerminateTime() &&
    //             _targetTownId > 0,
    //         "Player explore status error."
    //     );

    //     // Remove explorer and owner claim all rewards
    //     // calclate rewards amount
    //     (, uint256 _attackPower) = _playerContract().getPlayerInfo(_player);
    //     (uint256 reward, , uint256 systemFeeRatio) = _rewards(
    //         _townId,
    //         _timeSpent,
    //         _attackPower
    //     );

    //     // remove explorer from town
    //     _removeExplorer(_townId, _player);
    //     if (reward > 0) {
    //         // transfer rewards
    //         uint256 systemFee = (reward * systemFeeRatio) / 100;
    //         _uniCoinContract().transferFrom(
    //             _systemSettingsContract().feeAddress(),
    //             this.ownerOf(_townId),
    //             reward - systemFee
    //         );
    //     }
    //     _playerContract().resetExploreInfo(_player);
    // }

    // function burn(uint256 _tokenId) public {
    //     require(_ownerOf(_tokenId) == msg.sender, "Not owned.");
    //     _burn(_tokenId);
    // }

    /**
     * Game Getter
     */
    function getGameConstants() public pure returns (GameConstants memory) {
        return gameConstants();
    }
}
