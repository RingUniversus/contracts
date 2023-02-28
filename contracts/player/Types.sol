// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// Type imports
import {Point} from "../shared/Types.sol";

enum Status {
    Idle,
    Moving,
    Exploring,
    Attacking
}

struct Info {
    string nickname;
    Point location;
    uint256 lastMoveTime; // last moving finished timestamp
    Status status;
    uint256 moveSpeed; // 10000 means move 1 distance per second
    uint256 attackPower; // 10000 means decrease 1 hp per second
    uint256 createdAt;
}

enum EquipmentSlot {
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

struct RandomWordsInfo {
    // use VRF's random word as seed
    // uint256 seed;
    uint256[] randomWords;
    uint256 recivedAt;
    uint256 requestId;
}

struct Moving {
    Point target; // target point
    uint256 spendTime; // time will spend in this moving
    uint256 speed; // speed coefficient in this moving
    uint256 distance; // Whole move distance
    uint256 startTime; // start timestamp
    uint256 endTime; // moving actual end time
    // move configure
    uint256 maxTownToMint;
    uint256 townMintChance;
    uint256 bountyMintChance;
    uint256 segmentationDistance;
    // random words section
    RandomWordsInfo randomWords;
}

// Function arguements
struct NewTownArgs {
    address player;
    uint256 totalDistance;
    uint256 maxTownToMint;
    uint256 townMintRatio;
    uint256 segmentationDistance;
    uint256[] chance;
    uint256[] location;
    Point start;
    Point end;
}

struct NewBountyArgs {
    address player;
    uint256 chance;
    uint256 location;
    uint256 bountyMintRatio;
    Point start;
    Point end;
}
