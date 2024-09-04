// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// Contract imports
import {SolidStateERC721} from "@solidstate/contracts/token/ERC721/SolidStateERC721.sol";

// Library Imports
import {UintUtils} from "@solidstate/contracts/utils/UintUtils.sol";

// Storage imports
import {Modifiers, WithStorage} from "../libraries/LibStorage.sol";

// Type imports
import {Point, OblivionMetadata, OblivionType} from "../../shared/Types.sol";

contract RUOblivionFacet is Modifiers, SolidStateERC721 {
    event OblivionBeated(uint256 tokenId, address indexed player);

    function mint(
        address _player,
        Point calldata _coords,
        uint256 _oblivionType
    ) external onlyOwnerOrPlayer returns (uint256) {
        uint256 _tokenId = gs().tokenId;
        gs().tokenId = gs().tokenId + 1;
        // Set oblivion metadata
        gs().metadata[_tokenId] = OblivionMetadata({
            owner: _player,
            coords: _coords,
            oblivionType: OblivionType(_oblivionType),
            tokenId: _tokenId,
            // TODO: add to config, rewards to discoverer
            discovererRewards: 2000,
            validAt: block.timestamp + gameConstants().VALID_DELAY,
            createdAt: block.timestamp,
            beatedAt: 0,
            beatedBy: address(0)
        });

        gs().unbeatedIds.push(_tokenId);
        gs().unbeatedIndex[_tokenId] = gs().unbeatedIds.length - 1;

        _safeMint(_player, _tokenId);

        return _tokenId;
    }

    function beat(uint256 _tokenId) external onlyOwnerOrPlayer {
        OblivionMetadata storage oblivion = gs().metadata[_tokenId];

        require(oblivion.createdAt != 0, "Oblivion not discovered yet.");
        require(oblivion.beatedAt == 0, "Oblivion already beated!");

        // TODO: calculate rewards
        // oblivion.beatedAt = block.timestamp;

        _removeUnbeated(_tokenId);

        emit OblivionBeated(_tokenId, msg.sender);
    }

    function _removeUnbeated(uint256 _tokenId) internal {
        uint256 index = gs().unbeatedIndex[_tokenId];
        uint256 lastTokenId = gs().unbeatedIds[gs().unbeatedIds.length - 1];
        gs().unbeatedIds[index] = lastTokenId;
        gs().unbeatedIndex[lastTokenId] = index;

        gs().unbeatedIds.pop();
        delete gs().unbeatedIndex[_tokenId];
    }
}
