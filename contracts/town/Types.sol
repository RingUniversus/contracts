// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// Type imports
import {Point} from "../shared/Types.sol";

struct Town {
    string nickname;
    string flagPath;
    Point location;
    uint256 level;
    uint256 explorerFeeRatio;
    uint256 explorerSlot;
    uint256 createdAt;
}

struct Attribute {
    uint256 explorerCounter;
}
