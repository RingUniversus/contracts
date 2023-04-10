// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// Contract imports
// import {SolidStateERC20} from "@solidstate/contracts/token/ERC20/SolidStateERC20.sol";

// Library imports
import {LibDiamond} from "../../vendor/libraries/LibDiamond.sol";

// Storage imports
import {WithStorage, Modifiers} from "../libraries/LibStorage.sol";

// Functions used in tests/development for easily modifying game state
contract RUCoinDebugFacet is WithStorage, Modifiers {
    // function mint(uint256 _amount) external onlyOwner {
    //     _mint(msg.sender, _amount);
    // }
}
