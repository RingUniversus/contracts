// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// Contract imports
import {SolidStateERC721} from "@solidstate/contracts/token/ERC721/SolidStateERC721.sol";

// Library Imports
import {UintUtils} from "@solidstate/contracts/utils/UintUtils.sol";
import {LibEquipment} from "../libraries/LibEquipment.sol";

// Storage imports
import {Modifiers, WithStorage} from "../libraries/LibStorage.sol";

// Type imports
import {Point} from "../../shared/Types.sol";
import {EMetadata, ETypes, ERarity} from "../../shared/Types.sol";

contract RUEquipmentFacet is Modifiers, SolidStateERC721 {
    using UintUtils for uint256;

    function metadata(
        uint256 _tokenId
    ) external view returns (EMetadata memory) {
        return gs().equipments[_tokenId];
    }

    function metadataAtIndex(
        uint256 _idx
    ) public view returns (EMetadata memory) {
        return gs().equipments[tokenByIndex(_idx)];
    }

    // Mint new E with give random words
    // 3 random words needed
    function mint(
        address _player,
        uint256[] calldata _randomWords
    ) external onlyOwnerOrPlayer returns (uint256) {
        require(_randomWords.length == 3, "Random words length error.");
        uint256 _tokenId = gs().tokenId++;
        _safeMint(_player, _tokenId);

        // set Equipment metadata
        bool[] memory _effection = new bool[](2);
        EMetadata memory _metadata = EMetadata({
            eType: ETypes.Necklace,
            effection: _effection,
            rarity: ERarity.Common,
            mintedBy: _player,
            equipedAt: 0
        });
        // Type
        uint256 eType256 = _randomWords[0] % 1001;
        if (eType256 < 100) {
            _metadata.eType = ETypes.Necklace;
        } else if (eType256 < 200) {
            _metadata.eType = ETypes.Helmet;
        } else if (eType256 < 300) {
            _metadata.eType = ETypes.Wings;
        } else if (eType256 < 400) {
            _metadata.eType = ETypes.Shield;
        } else if (eType256 < 500) {
            _metadata.eType = ETypes.Chest;
        } else if (eType256 < 600) {
            _metadata.eType = ETypes.Weapon;
        } else if (eType256 < 700) {
            _metadata.eType = ETypes.Ring;
        } else if (eType256 < 800) {
            _metadata.eType = ETypes.Pants;
        } else if (eType256 < 900) {
            _metadata.eType = ETypes.Gloves;
        } else if (eType256 < 1000) {
            _metadata.eType = ETypes.Boots;
        } else {
            _metadata.eType = ETypes.Pet;
        }

        // Rarity
        uint256 rarity256 = _randomWords[1] % 1001;
        if (rarity256 < 500) {
            // about 50%
            _metadata.rarity = ERarity.Common;
        } else if (rarity256 < 800) {
            // about 30%
            _metadata.rarity = ERarity.Uncommon;
        } else if (rarity256 < 940) {
            // about 14%
            _metadata.rarity = ERarity.Rare;
        } else if (rarity256 < 990) {
            // about 5%
            _metadata.rarity = ERarity.Epic;
        } else if (rarity256 < 1000) {
            // about 1%
            _metadata.rarity = ERarity.Masterwork;
        } else {
            // about .1%
            _metadata.rarity = ERarity.Legendary;
        }

        // Effection
        // Index 0 for speed, index 1 for attack power
        uint256 _effection256 = _randomWords[2] % 1001;
        if (_effection256 < 500) {
            // index 0 for speed active
            _metadata.effection[0] = true;
        } else if (_effection256 < 1000) {
            // index 1 for attack power active
            _metadata.effection[1] = true;
        } else {
            _metadata.effection[0] = true;
            _metadata.effection[1] = true;
        }

        gs().equipments[_tokenId] = _metadata;
        return _tokenId;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(SolidStateERC721) {
        // prevent transfer equiped E
        require(
            gs().equipments[tokenId].equipedAt == 0,
            "Cannot transfer equiped E"
        );
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /// @notice Return E's multi
    /// @dev Return base multi avoid calc error
    /// @param _tokenId E's Token ID
    /// @return speedMulit Speed multi
    /// @return attackPowerMulit AttackPower multi
    function eMulti(uint256 _tokenId) external view returns (uint256, uint256) {
        uint256 baseSpeedMulit = 10000;
        uint256 baseAttackPowerMulit = 10000;
        if (_tokenId > 0) {
            // index 0 for speed
            if (gs().equipments[_tokenId].effection[0] == true) {
                baseSpeedMulit = LibEquipment.rarityMulti(
                    gs().equipments[_tokenId].rarity
                );
            }
            // index 1 for attack power
            if (gs().equipments[_tokenId].effection[1] == true) {
                baseAttackPowerMulit = LibEquipment.rarityMulti(
                    gs().equipments[_tokenId].rarity
                );
            }
        }
        return (baseSpeedMulit, baseAttackPowerMulit);
    }

    function equip(uint256 _tokenId) external onlyOwnerOrPlayer {
        require(
            gs().equipments[_tokenId].mintedBy != address(0),
            "Not Minted."
        );
        require(gs().equipments[_tokenId].equipedAt == 0, "Already Euqiped.");
        require(this.ownerOf(_tokenId) == msg.sender, "E not owned.");
        gs().equipments[_tokenId].equipedAt = block.timestamp;
    }

    function unequip(uint256 _tokenId) external onlyOwnerOrPlayer {
        require(
            gs().equipments[_tokenId].mintedBy != address(0),
            "Not Minted."
        );
        require(gs().equipments[_tokenId].equipedAt != 0, "Not Euqiped.");
        require(this.ownerOf(_tokenId) == msg.sender, "E not owned.");
        gs().equipments[_tokenId].equipedAt = 0;
    }
}
