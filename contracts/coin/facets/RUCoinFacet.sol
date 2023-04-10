// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// Contract imports
import {SolidStateERC20} from "@solidstate/contracts/token/ERC20/SolidStateERC20.sol";

// Storage imports
import {Modifiers, WithStorage} from "../libraries/LibStorage.sol";

contract RUCoinFacet is Modifiers, SolidStateERC20 {
    function mint(uint256 _amount) external {
        _mint(msg.sender, _amount);
    }
}
