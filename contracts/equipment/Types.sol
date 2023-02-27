// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// Type imports
import {Point} from "../shared/Types.sol";

// 11 types of Equipment
enum Types {
    Necklace,
    Helmet,
    Wings,
    Shield,
    Chest,
    Weapon,
    Ring,
    Pants,
    Gloves,
    Boots,
    // Most Rare
    Pet
}

enum Rarity {
    // White 1x
    Common,
    // Yellow 1.1x
    Uncommon,
    // Purple 1.3x
    Rare,
    // Cyan 1.6x
    Epic,
    // Orange 2.0x
    Masterwork,
    // Gold 2.5x
    Legendary
}

struct Metadata {
    Types eType;
    // fixed length 2
    // index 0 for speed, 1 for Attack Power
    bool[] effection;
    Rarity rarity;
    address mintedBy;
    uint256 equipedAt;
}
