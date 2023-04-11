// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// Contract imports
import {SolidStateERC20} from "@solidstate/contracts/token/ERC20/SolidStateERC20.sol";

// Storage imports
import {Modifiers, WithStorage} from "../libraries/LibStorage.sol";

error AlreadyMinted();

contract RUCoinFacet is Modifiers, SolidStateERC20 {
    function mint(uint256 _amount) external onlyOwner {
        if (gameConstants().MINT_AT != 0) revert AlreadyMinted();

        gameConstants().MINT_AT = block.timestamp;
        _mint(msg.sender, _amount);
    }
}
