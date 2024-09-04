// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

struct Point {
    int256 x;
    int256 y;
}

struct Ring {
    // Town Info
    uint256 townLimit;
    uint256 townCount;
    // Minting Town chance, 9500 means 95.00%
    uint256 townMintingRatio;
    // Oblivion Info, 9500 means 95.00%
    uint256 oblivionMintingRatio;
    address explorer;
    uint256 exploredAt;
}

struct Town {
    string nickname;
    string flagPath;
    Point location;
    // uint256 ringId;
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

// Oblivion type start
// Diffrent type with diffrent rewards and Attacker
enum OblivionType {
    PlayerToken,
    PlayerEquip,
    PlayerBuff,
    UniToken,
    UniEquip,
    UniBuff
}

struct OblivionMetadata {
    address owner;
    Point coords;
    OblivionType oblivionType;
    uint256 tokenId;
    uint256 discovererRewards;
    uint256 validAt;
    uint256 createdAt;
    uint256 beatedAt;
    address beatedBy;
}
// Oblivion End
