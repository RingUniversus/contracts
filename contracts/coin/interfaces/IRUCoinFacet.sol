// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// Interfaces imports
import {ISolidStateERC20} from "@solidstate/contracts/token/ERC20/ISolidStateERC20.sol";

interface IRUCoinFacet is ISolidStateERC20 {
    function mint(uint256 _amount) external;
}
