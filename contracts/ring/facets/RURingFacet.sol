// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// Library Imports
import {LibRing} from "../libraries/LibRing.sol";

// Storage imports
import {Modifiers} from "../libraries/LibStorage.sol";

// Type imports
import {UpdateRelatedAddressArgs} from "../Types.sol";
import {Ring} from "../../shared/Types.sol";

contract RURingFacet is Modifiers {
    function updateRelatedAddress(
        UpdateRelatedAddressArgs calldata _addresses
    ) external onlyOwner {
        gameConstants().PLAYER_ADDRESS = _addresses.playerAddress;
    }

    function metadata(uint256 _ringId) public view returns (Ring memory) {
        (Ring memory _ring, ) = LibRing.metadata(_ringId);
        return _ring;
    }

    function metadataAtIndex(uint256 _idx) public view returns (Ring memory) {
        (Ring memory _ring, ) = LibRing.metadata(_idx + 1);
        return _ring;
    }

    function number(
        int256 _distanceX,
        int256 _distanceY
    ) external view returns (uint256) {
        return LibRing.number(_distanceX, _distanceY);
    }

    /**
     * Mint new Ring
     */
    function mint(
        uint256 _ringId,
        address _explorer
    ) public onlyOwner returns (uint256) {
        LibRing.mintByExplorer(_ringId, _explorer);
        return _ringId;
    }

    function safeMint(
        uint256 _tokenId,
        address _explorer
    ) external onlyOwner returns (Ring memory, bool) {
        // if minted
        if (LibRing.isMinted(_tokenId) == true) {
            return (gs().rings[_tokenId], false);
        }

        return (gs().rings[LibRing.mintByExplorer(_tokenId, _explorer)], true);
    }

    /// @notice increase Ring's Town Count for given ring ID
    /// @dev Update Minting ratio after town increase
    /// @param _ringId ring token ID
    /// @param _step town count
    function increaseTownCount(
        uint256 _ringId,
        uint256 _step
    ) external onlyOwner {
        require(_step > 0, "Step must greater than 1.");
        gs().rings[_ringId].townCount += _step;
        if (gs().rings[_ringId].townCount >= gs().rings[_ringId].townLimit) {
            gs().rings[_ringId].townMintingRatio = gameConstants()
                .TOWN_OVER_MINTING_RATIO;
        }
    }
}
