// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// Type imports
import {Ring} from "../../shared/Types.sol";

interface IRURingFacet {
    function safeMint(
        uint256 _tokenId,
        address _explorer
    ) external returns (Ring memory, bool);

    function number(
        int256 _distanceX,
        int256 _distanceY
    ) external view returns (uint256);

    function increaseTownCount(uint256 _ringId, uint256 _step) external;
}
