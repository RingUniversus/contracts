// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Base import
import {LibDiamond} from "../vendor/libraries/LibDiamond.sol";
import {IDiamondLoupe} from "../vendor/interfaces/IDiamondLoupe.sol";
import {IDiamondCut} from "../vendor/interfaces/IDiamondCut.sol";
import {IERC173} from "../vendor/interfaces/IERC173.sol";
import {IERC165} from "../vendor/interfaces/IERC165.sol";
// Custom import blow
import {IRUCoinFacet} from "./interfaces/IRUCoinFacet.sol";
import {WithStorage} from "./libraries/LibStorage.sol";
import {IERC20} from "@solidstate/contracts/interfaces/IERC20.sol";
import {IERC20Metadata} from "@solidstate/contracts/token/ERC20/metadata/IERC20Metadata.sol";
import {ERC20MetadataStorage} from "@solidstate/contracts/token/ERC20/metadata/ERC20MetadataStorage.sol";

// It is expected that this contract is customized if you want to deploy your diamond
// with data from a deployment script. Use the init function to initialize state variables
// of your diamond. Add parameters to the init funciton if you need to.

struct InitArgs {
    string NAME;
    string SYMBOL;
    uint8 DECIMALS;
    uint256 TOTAL_SUPPLY;
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

        ds.supportedInterfaces[type(IERC20).interfaceId] = true;
        ds.supportedInterfaces[type(IERC20Metadata).interfaceId] = true;

        gs().diamondAddress = address(this);

        // Coin config
        ERC20MetadataStorage.Layout storage layout = ERC20MetadataStorage
            .layout();
        layout.name = initArgs.NAME;
        layout.symbol = initArgs.SYMBOL;
        layout.decimals = initArgs.DECIMALS;

        IRUCoinFacet uniC = IRUCoinFacet(address(this));
        uniC.mint(initArgs.TOTAL_SUPPLY * 1e18);
    }
}
