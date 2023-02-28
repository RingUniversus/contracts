// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// Type imports
import {Point, BTYOwnType} from "../../shared/Types.sol";

interface IRUBountyFacet {
    function newBounty(
        address _player,
        uint256 _circleId,
        Point memory _location,
        BTYOwnType _ownType
    ) external returns (uint256);
}
