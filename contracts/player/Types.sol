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

enum TeleportType {
    Town,
    Oblivion
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
    Point target; // target coords
    Point start; // start coords
    Point end; // end coords
    uint256 spendTime; // time will spend in this moving
    uint256 speed; // speed coefficient in this moving
    uint256 distance; // Whole move distance
    uint256 startTime; // start timestamp
    uint256 endTime; // moving actual end time
    // move configure
    uint256 maxTownToMint;
    uint256 townMintRatio;
    uint256 oblivionMintRatio;
    uint256 segmentationDistance;
    // random words section
    RandomWordsInfo randomWords;
    bool isClaimed;
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

struct NewOblivionArgs {
    address player;
    uint256 chance;
    uint256 location;
    uint256 oblivionMintRatio;
    Point start;
    Point end;
}

// Function arguements
struct UpdateRelatedAddressArgs {
    address feeAddress;
    address equipmentAddress;
    address coinAddress;
    address ringAddress;
    address townAddress;
    address oblivionAddress;
    address vrfAddress;
}
