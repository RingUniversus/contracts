// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

struct Point {
    int256 x;
    int256 y;
}

enum PlayerStatus {
    Idle,
    Moving,
    Exploring,
    Attacking
}

// Town metadata
struct Town {
    string nickname;
    string flagPath;
    Point location;
    uint256 level;
    uint256 explorerFeeRatio;
    uint256 explorerSlot;
    uint256 createdAt;
}

// 11 types of Equipment
enum ETypes {
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

enum ERarity {
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

struct EMetadata {
    ETypes eType;
    // fixed length 2
    // index 0 for speed, 1 for Attack Power
    bool[] effection;
    ERarity rarity;
    address mintedBy;
    uint256 equipedAt;
}

enum PlayerItemSlot {
    Neck,
    Head,
    Back,
    RightHand,
    Body,
    LeftHand,
    FingersLT,
    FingersLI,
    FingersLM,
    FingersLR,
    FingersLL,
    FingersRT,
    FingersRI,
    FingersRM,
    FingersRR,
    FingersRL,
    Legs,
    Hands,
    Feet,
    Pet
}
