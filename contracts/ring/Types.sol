// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// Type imports
import {Point} from "../shared/Types.sol";

struct Ring {
    // Town Info
    uint256 townLimit;
    uint256 townCount;
    // Minting Town chance, 9500 means 95.00%
    uint256 townMintingRatio;
    // Bounty Info, 950000 means 95.00%
    uint256 bountyMintingRatio;
    address explorer;
    uint256 exploredAt;
}
