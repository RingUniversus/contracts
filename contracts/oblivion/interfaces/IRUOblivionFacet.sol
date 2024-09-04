// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// Type imports
import {Point} from "../../shared/Types.sol";

interface IRUOblivionFacet {
    function mint(
        address _player,
        Point memory _coords,
        uint256 _oblivionType
    ) external returns (uint256);
}
