// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// Interface imports
import {ISolidStateERC721} from "@solidstate/contracts/token/ERC721/ISolidStateERC721.sol";

// Type imports
import {Point, EMetadata} from "../../shared/Types.sol";

interface IRUEquipmentFacet is ISolidStateERC721 {
    function metadata(
        uint256 _tokenId
    ) external view returns (EMetadata memory);

    function eMulti(uint256 _tokenId) external view returns (uint256, uint256);

    function equip(uint256 _tokenId) external;

    function unequip(uint256 _tokenId) external;
}
