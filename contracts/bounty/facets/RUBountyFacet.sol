// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// Contract imports
import {SolidStateERC721} from "@solidstate/contracts/token/ERC721/SolidStateERC721.sol";

// Library Imports
import {UintUtils} from "@solidstate/contracts/utils/UintUtils.sol";

// Storage imports
import {Modifiers, WithStorage} from "../libraries/LibStorage.sol";

// Type imports
import {Point, BTYOwnType, BTYInfo, BTYMetadata} from "../../shared/Types.sol";

contract RUBountyFacet is Modifiers, SolidStateERC721 {
    function newBounty(
        address _player,
        uint256 _circleId,
        Point memory _location,
        BTYOwnType _ownType
    ) external onlyOwnerOrPlayer returns (uint256) {
        uint256 existBountyLength = gs().ringBountyInfo[_circleId].length;
        BTYInfo memory bountyInfo = BTYInfo({
            location: _location,
            btype: 0,
            // default 25% rewards to discoverer
            discovererRewards: 2500,
            validAt: block.timestamp + gameConstants().VALID_DELAY,
            createdAt: block.timestamp,
            discoverer: _player,
            claimedAt: 0,
            beatedAt: 0,
            beatedBy: address(0)
        });
        // new bounty
        gs().ringBountyInfo[_circleId].push(bountyInfo);
        uint256 bountyId = existBountyLength;
        mint(_player, bountyId, _circleId, _ownType);
        return bountyId;
    }

    function mint(
        address _player,
        uint256 _bountyId,
        uint256 _circleId,
        BTYOwnType _ownType
    ) internal returns (uint256) {
        uint256 _tokenId = gs().tokenId++;
        _safeMint(_player, _tokenId);

        // set bounty metadata
        gs().metadata[_tokenId] = BTYMetadata(
            _player,
            _ownType,
            _bountyId,
            _circleId
        );
        return _tokenId;
    }
}
