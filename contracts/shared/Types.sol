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
    // Bounty Info, 950000 means 95.00%
    uint256 bountyMintingRatio;
    address explorer;
    uint256 exploredAt;
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

// For diffrent type with diffrent rewards
enum BTYType {
    // Biggest type
    Uni,
    // Monster rewards token
    Monster,
    //
    Wanted
}

enum BTYOwnType {
    // own by mint
    MINT,
    // own by beat
    BEAT
}

struct BTYMetadata {
    address owner;
    BTYOwnType otype;
    uint256 tokenId;
    uint256 ringId;
}

struct BTYInfo {
    Point location;
    uint256 btype;
    uint256 discovererRewards;
    uint256 validAt;
    uint256 createdAt;
    address discoverer;
    uint256 claimedAt;
    uint256 beatedAt;
    address beatedBy;
}
