// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// Type imports
import {Point} from "../../shared/Types.sol";

interface IRUTownFacet {
    function create(address _owner, Point memory _location)
        external
        returns (uint256);
}
