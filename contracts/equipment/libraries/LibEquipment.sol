// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// Storage imports
import {LibStorage, GameStorage, GameConstants} from "./LibStorage.sol";

// Type imports
import {ERarity} from "../../shared/Types.sol";

library LibEquipment {
    function gs() internal pure returns (GameStorage storage) {
        return LibStorage.gameStorage();
    }

    function gameConstants() internal pure returns (GameConstants storage) {
        return LibStorage.gameConstants();
    }

    function rarityMulti(ERarity _rarity) public pure returns (uint256) {
        uint256 _eMulit = 10000;
        if (_rarity == ERarity.Common) {
            _eMulit = 10000;
        } else if (_rarity == ERarity.Uncommon) {
            _eMulit = 11000;
        } else if (_rarity == ERarity.Rare) {
            _eMulit = 13000;
        } else if (_rarity == ERarity.Epic) {
            _eMulit = 16000;
        } else if (_rarity == ERarity.Masterwork) {
            _eMulit = 20000;
        } else if (_rarity == ERarity.Legendary) {
            _eMulit = 25000;
        }
        return _eMulit;
    }
}
