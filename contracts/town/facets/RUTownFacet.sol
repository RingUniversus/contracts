// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// Contract imports
import {SolidStateERC721} from "@solidstate/contracts/token/ERC721/SolidStateERC721.sol";

// Library Imports
import {UintUtils} from "@solidstate/contracts/utils/UintUtils.sol";

// Storage imports
import {Modifiers} from "../libraries/LibStorage.sol";

// Type imports
import {Point} from "../../shared/Types.sol";
import {Town} from "../Types.sol";

contract RUTownFacet is Modifiers, SolidStateERC721 {
    using UintUtils for uint256;

    function create(address _owner, Point memory _location)
        public
        onlyOwner
        returns (uint256)
    {
        uint256 tokenId = gs().townTokenId++;

        _mint(_owner, tokenId);

        Town memory newTown = Town({
            nickname: string.concat("UNiT ", tokenId.toString()),
            flagPath: "",
            location: _location,
            level: 1,
            explorerFeeRatio: gameConstants().EXPLORER_FEE_RATIO,
            explorerSlot: gameConstants().EXPLORER_SLOT,
            createdAt: block.timestamp
        });

        gs().towns[tokenId] = newTown;

        return tokenId;
    }
}
