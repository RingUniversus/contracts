// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// Storage imports
import {LibStorage, GameStorage, GameConstants} from "./LibStorage.sol";

// Type imports
import {Rarity} from "../Types.sol";

library LibEquipment {
    function gs() internal pure returns (GameStorage storage) {
        return LibStorage.gameStorage();
    }

    function gameConstants() internal pure returns (GameConstants storage) {
        return LibStorage.gameConstants();
    }

    function rarityMulti(Rarity _rarity) public pure returns (uint256) {
        uint256 _eMulit = 10000;
        if (_rarity == Rarity.Common) {
            _eMulit = 10000;
        } else if (_rarity == Rarity.Uncommon) {
            _eMulit = 11000;
        } else if (_rarity == Rarity.Rare) {
            _eMulit = 13000;
        } else if (_rarity == Rarity.Epic) {
            _eMulit = 16000;
        } else if (_rarity == Rarity.Masterwork) {
            _eMulit = 20000;
        } else if (_rarity == Rarity.Legendary) {
            _eMulit = 25000;
        }
        return _eMulit;
    }
}
