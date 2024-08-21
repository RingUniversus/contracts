// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// Type imports
import {Ring} from "../../shared/Types.sol";

interface IRURingFacet {
    function metadata(uint256 _ringId) external view returns (Ring memory);
    function isMinted(uint256 _tokenId) external view returns (bool);

    function safeMint(
        address _explorer,
        uint256 _ringId
    ) external returns (uint256);

    function number(
        int256 _distanceX,
        int256 _distanceY
    ) external view returns (uint256);

    function increaseTownCount(uint256 _ringId, uint256 _step) external;
}
