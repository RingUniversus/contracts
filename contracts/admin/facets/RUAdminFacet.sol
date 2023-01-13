// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// Other Facets imports
import {IRUTownFacet} from "../../town/interfaces/IRUTownFacet.sol";

// Storage imports
import {Modifiers} from "../libraries/LibStorage.sol";

// Type imports
import {Point} from "../../shared/Types.sol";

contract RUCoreFacet is Modifiers {
    function createTown(Point memory _point)
        public
        onlyOwner
        returns (uint256)
    {
        return
            IRUTownFacet(gameConstants().UNIVERSUS_DIAMOND_ADDRESS).create(
                msg.sender,
                _point
            );
    }
}
