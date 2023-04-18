// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// Permission error
error UnauthorizedOwner(address sender);
error UnauthorizedOwnerOrPlayer(address sender);
error EquipmentNotOwned(uint256 tokenId);
