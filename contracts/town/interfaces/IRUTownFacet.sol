// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// Type imports
import {Point, Town} from "../../shared/Types.sol";

interface IRUTownFacet {
    function metadata(uint256 _tokenId) external view returns (Town memory);

    function create(
        address _owner,
        Point memory _location
    ) external returns (uint256);
}
