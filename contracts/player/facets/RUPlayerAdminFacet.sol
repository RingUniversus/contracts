// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// Library imports

// Storage imports
import {Modifiers} from "../libraries/LibStorage.sol";

// Type imports
import {UpdateRelatedAddressArgs} from "../Types.sol";

contract RUPlayerAdminFacet is Modifiers {
    function updateRelatedAddress(
        UpdateRelatedAddressArgs calldata _addresses
    ) external onlyOwner {
        gameConstants().FEE_ADDRESS = _addresses.feeAddress;
        gameConstants().EQUIPMENT_ADDRESS = _addresses.equipmentAddress;
        gameConstants().COIN_ADDRESS = _addresses.coinAddress;
        gameConstants().RING_ADDRESS = _addresses.ringAddress;
        gameConstants().TOWN_ADDRESS = _addresses.townAddress;
        gameConstants().OBLIVION_ADDRESS = _addresses.oblivionAddress;
        gameConstants().VRF_ADDRESS = _addresses.vrfAddress;
    }
}
