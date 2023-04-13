// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// Library imports

// Storage imports
import {Modifiers} from "../libraries/LibStorage.sol";

// Type imports
import {UpdateRelatedAddressArgs} from "../Types.sol";

contract RUEquipmentAdminFacet is Modifiers {
    function updateRelatedAddress(
        UpdateRelatedAddressArgs calldata _addresses
    ) external onlyOwner {
        gameConstants().PLAYER_ADDRESS = _addresses.playerAddress;
    }
}
