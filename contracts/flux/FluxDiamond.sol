// SPDX-License-Identifier: MIT
pragma solidity >=0.8.30;

import "lib/diamond/DiamondMod.sol" as DiamondMod;
import "lib/access/Owner/OwnerMod.sol" as OwnerMod;
import "lib/token/ERC20/Metadata/ERC20MetadataMod.sol" as ERC20MetadataMod;
import "lib/token/ERC20/Mint/ERC20MintMod.sol" as ERC20MintMod;
import "lib/interfaceDetection/ERC165/ERC165Mod.sol" as ERC165Mod;
import {IERC20} from "lib/interfaces/IERC20.sol";

contract FluxDiamond {
    /**
     * @notice Struct to hold facet address and its function selectors.
     * struct FacetFunctions {
     *     address facet;
     *     bytes4[] selectors;
     * }
     */
    /**
     * @notice Initializes the diamond contract with facets, owner and other data.
     * @dev Adds all provided facets to the diamond's function selector mapping and sets the contract owner.
     *      Each facet in the array will have its function selectors registered to enable delegatecall routing.
     * @param _facets Array of facet addresses and their corresponding function selectors to add to the diamond.
     * @param _diamondOwner Address that will be set as the owner of the diamond contract.
     */
    constructor(
        DiamondMod.FacetFunctions[] memory _facets,
        address _diamondOwner
    ) {
        DiamondMod.addFacets(_facets);

        /*************************************
         * Initialize storage variables
         ************************************/

        /**
         * Setting the contract owner
         */
        OwnerMod.setContractOwner(_diamondOwner);
        /**
         * Setting ERC20 token details
         */
        ERC20MetadataMod.setMetadata({
            _name: "Flux",
            _symbol: "FLUX",
            _decimals: 8
        });
        ERC20MintMod.mintERC20(_diamondOwner, 100000000 * 1e8);
        /**
         * Registering ERC165 interfaces
         */
        ERC165Mod.registerInterface(type(IERC20).interfaceId);
    }

    fallback() external payable {
        DiamondMod.diamondFallback();
    }

    receive() external payable {}
}
