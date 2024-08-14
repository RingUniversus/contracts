// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// Library Imports
import {LibRing} from "../libraries/LibRing.sol";

// Storage imports
import {Modifiers, GameConstants} from "../libraries/LibStorage.sol";

// Type imports
import {Ring} from "../../shared/Types.sol";

// Errors imports
import {IncreaseStepError} from "../Errors.sol";

contract RURingFacet is Modifiers {
    function metadata(uint256 _ringId) public view returns (Ring memory) {
        (Ring memory _ring, ) = LibRing.metadata(_ringId);
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
    function mint(address _explorer) public onlyOwner returns (uint256) {
        LibRing.mintByExplorer(_explorer);
        return gs().nextRingId;
    }

    function safeMint(
        address _explorer
    ) external onlyOwnerOrPlayer returns (Ring memory, bool) {
        // if minted
        if (LibRing.isMinted(gs().nextRingId) == true) {
            return (gs().rings[gs().nextRingId], false);
        }

        return (gs().rings[LibRing.mintByExplorer(_explorer)], true);
    }

    /// @notice increase Ring's Town Count for given ring ID
    /// @dev Update Minting ratio after town increase
    /// @param _ringId ring token ID
    /// @param _step town count
    function increaseTownCount(
        uint256 _ringId,
        uint256 _step
    ) external onlyOwnerOrPlayer {
        if (_step == 0) revert IncreaseStepError({step: _step});
        gs().rings[_ringId].townCount += _step;
        if (gs().rings[_ringId].townCount >= gs().rings[_ringId].townLimit) {
            gs().rings[_ringId].townMintingRatio = gameConstants()
                .TOWN_OVER_MINTING_RATIO;
        }
    }

    /**
     * Game Getter
     */
    function getGameConstants() public pure returns (GameConstants memory) {
        return gameConstants();
    }

    function getNextRingId() public view returns (uint256) {
        return gs().nextRingId;
    }

    function isMinted(uint256 _tokenId) public view returns (bool) {
        return LibRing.isMinted(_tokenId);
    }
}
