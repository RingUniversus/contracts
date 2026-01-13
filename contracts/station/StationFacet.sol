// SPDX-License-Identifier: MIT
pragma solidity >=0.8.30;
import "lib/token/ERC721/Mint/ERC721MintMod.sol" as ERC721MintMod;

contract StationFacet {
    bytes32 constant STORAGE_POSITION = keccak256("ru.station.storage");
    struct StationStorage {
        uint256 totalSupply;
    }

    function getStorage() internal pure returns (StationStorage storage s) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }

    function _totalSupply() internal view returns (uint256) {
        return getStorage().totalSupply;
    }

    function mint(address player) external {
        uint256 _tokenId = _totalSupply();
        ERC721MintMod.mintERC721(player, _tokenId);
        getStorage().totalSupply += 1;
    }
}
