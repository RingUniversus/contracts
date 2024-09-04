// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Base import
import {LibDiamond} from "../vendor/libraries/LibDiamond.sol";
import {IDiamondLoupe} from "../vendor/interfaces/IDiamondLoupe.sol";
import {IDiamondCut} from "../vendor/interfaces/IDiamondCut.sol";
import {IERC173} from "../vendor/interfaces/IERC173.sol";
import {IERC165} from "../vendor/interfaces/IERC165.sol";
// Custom import blow
import {WithStorage} from "./libraries/LibStorage.sol";
import {IERC721} from "@solidstate/contracts/interfaces/IERC721.sol";
import {IERC721Metadata} from "@solidstate/contracts/token/ERC721/metadata/IERC721Metadata.sol";
import {IERC721Enumerable} from "@solidstate/contracts/token/ERC721/enumerable/IERC721Enumerable.sol";
import {ERC721MetadataStorage} from "@solidstate/contracts/token/ERC721/metadata/ERC721MetadataStorage.sol";

// It is expected that this contract is customized if you want to deploy your diamond
// with data from a deployment script. Use the init function to initialize state variables
// of your diamond. Add parameters to the init funciton if you need to.

struct InitArgs {
    // Addresses
    address FEE_ADDRESS;
    // Contract Address
    address EQUIPMENT_ADDRESS;
    address COIN_ADDRESS;
    address RING_ADDRESS;
    address TOWN_ADDRESS;
    address OBLIVION_ADDRESS;
    address VRF_ADDRESS;
    // Base config
    uint256 BASE_MOVE_SPEED;
    uint256 BASE_ATTACK_POWER;
    uint256 MIN_TRIP_TIME;
    uint256 TOWN_MINT_FEE;
    uint256 MAX_MINT_TOW_PER_MOVE;
    uint256 TOWN_MINT_RATIO_PER_MOVE;
    uint256 OBLIVION_MINT_RATIO_PER_MOVE;
    uint256 SEGMENTATION_DISTANCE_PER_MOVE;
}

contract InitDiamond is WithStorage {
    // You can add parameters to this function in order to pass in
    // data to set your own state variables
    function init(InitArgs memory initArgs) external {
        // adding ERC165 data
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IERC173).interfaceId] = true;

        // add your own state variables
        // EIP-2535 specifies that the `diamondCut` function takes two optional
        // arguments: address _init and bytes calldata _calldata
        // These arguments are used to execute an arbitrary function using delegatecall
        // in order to set state variables in the diamond during deployment or an upgrade
        // More info here: https://eips.ethereum.org/EIPS/eip-2535#diamond-interface

        ds.supportedInterfaces[type(IERC721).interfaceId] = true;
        ds.supportedInterfaces[type(IERC721Metadata).interfaceId] = true;
        ds.supportedInterfaces[type(IERC721Enumerable).interfaceId] = true;

        gs().diamondAddress = address(this);

        // Player config
        gameConstants().FEE_ADDRESS = initArgs.FEE_ADDRESS;
        gameConstants().EQUIPMENT_ADDRESS = initArgs.EQUIPMENT_ADDRESS;
        gameConstants().COIN_ADDRESS = initArgs.COIN_ADDRESS;
        gameConstants().RING_ADDRESS = initArgs.RING_ADDRESS;
        gameConstants().TOWN_ADDRESS = initArgs.TOWN_ADDRESS;
        gameConstants().OBLIVION_ADDRESS = initArgs.OBLIVION_ADDRESS;
        gameConstants().VRF_ADDRESS = initArgs.VRF_ADDRESS;

        gameConstants().BASE_MOVE_SPEED = initArgs.BASE_MOVE_SPEED;
        gameConstants().BASE_ATTACK_POWER = initArgs.BASE_ATTACK_POWER;
        gameConstants().MIN_TRIP_TIME = initArgs.MIN_TRIP_TIME;
        gameConstants().TOWN_MINT_FEE = initArgs.TOWN_MINT_FEE * 1e18;
        gameConstants().MAX_MINT_TOW_PER_MOVE = initArgs.MAX_MINT_TOW_PER_MOVE;
        gameConstants().TOWN_MINT_RATIO_PER_MOVE = initArgs
            .TOWN_MINT_RATIO_PER_MOVE;
        gameConstants().OBLIVION_MINT_RATIO_PER_MOVE = initArgs
            .OBLIVION_MINT_RATIO_PER_MOVE;
        gameConstants().SEGMENTATION_DISTANCE_PER_MOVE = initArgs
            .SEGMENTATION_DISTANCE_PER_MOVE;
    }
}
