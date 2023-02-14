// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// Storage imports
import {LibStorage, GameStorage, GameConstants} from "./LibStorage.sol";
// Library imports
import {LibUtil} from "../../shared/libraries/LibUtil.sol";
import {SafeCast} from "../../shared/libraries/LibSafeCast.sol";
// Type imports
import {Ring} from "../Types.sol";

library LibRing {
    using SafeCast for int256;

    function gs() internal pure returns (GameStorage storage) {
        return LibStorage.gameStorage();
    }

    function gameConstants() internal pure returns (GameConstants storage) {
        return LibStorage.gameConstants();
    }

    /**
     * Calculate ring number by distance.
     */
    function number(
        int256 _distanceX,
        int256 _distanceY
    ) public view returns (uint256) {
        uint256 dist = LibUtil.caculateDistance(
            _distanceX.toUint256(),
            _distanceY.toUint256()
        );
        return dist / gameConstants().DISTANCE;
    }

    function isMinted(uint256 _ringId) public view returns (bool) {
        if (gs().rings[_ringId].exploredAt == 0) {
            return false;
        }
        return true;
    }

    /**
     * Query or calc ring info with given id.
     */
    function metadata(uint256 _ringId) public view returns (Ring memory, bool) {
        // return exist info if minted
        if (isMinted(_ringId)) {
            return (gs().rings[_ringId], true);
        } else {
            uint256 mintingRatio = _ringId * _ringId + 2 * _ringId;
            return (
                Ring({
                    // TODO: townLimit Based on area
                    townLimit: gs().rings[1].townLimit * mintingRatio,
                    townCount: 0,
                    townMintingRatio: gameConstants().TOWN_MINTING_RATIO,
                    bountyMintingRatio: gameConstants().BOUNTY_MINTING_RATIO,
                    explorer: address(0),
                    exploredAt: 0
                }),
                false
            );
        }
    }

    /**
     * Mint new ring or update exists.
     */
    function _mintOrUpdate(
        uint256 _ringId,
        Ring memory _ring
    ) internal returns (uint256) {
        // init new ring or update info by given id
        gs().rings[_ringId] = Ring({
            townLimit: _ring.townLimit,
            townCount: 0,
            townMintingRatio: _ring.townMintingRatio,
            bountyMintingRatio: _ring.bountyMintingRatio,
            explorer: _ring.explorer,
            exploredAt: _ring.exploredAt
        });
        // Sync ring token ID
        if (!isMinted(_ringId)) {
            gs().tokenId += 1;
        }
        return _ringId;
    }

    /**
     * Mint new ring.
     */
    function mint(Ring memory _ring) public returns (uint256) {
        return _mintOrUpdate(gs().tokenId + 1, _ring);
    }

    /**
     * Mint new ring with default args by explorer.
     */
    function mintByExplorer(
        uint256 _ringId,
        address _explorer
    ) public returns (uint256) {
        (Ring memory _ring, bool exists) = metadata(_ringId);
        // Use assert because it's system logic error and should not happen
        assert(exists == false);
        // update explorer info
        _ring.explorer = _explorer;
        _ring.exploredAt = block.timestamp;
        return mint(_ring);
    }

    /**
     * Update ring with given id and info.
     */
    function update(
        uint256 _ringId,
        Ring memory _ring
    ) public returns (uint256) {
        return _mintOrUpdate(_ringId, _ring);
    }
}
