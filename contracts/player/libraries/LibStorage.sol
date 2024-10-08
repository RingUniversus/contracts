// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// Library imports
import {LibDiamond} from "../../vendor/libraries/LibDiamond.sol";

// Type imports
import {Info, EquipmentSlot, Moving, Status} from "../Types.sol";

// Error imports
import {UnauthorizedOwner} from "../../shared/Errors.sol";
import {PlayerStatusError, UnInitializedPlayer} from "../Errors.sol";

struct GameStorage {
    // Contract housekeeping
    address diamondAddress;
    // Store player's current info
    mapping(address => Info) info;
    // Store player's equipments
    // player's address => item slot => E Token ID
    mapping(address => mapping(EquipmentSlot => uint256)) equipmentSlots;
    // Player's current(is moving) / last(not moving) moving info
    mapping(address => Moving) currentMoveInfo;
    // store players' random words request id
    mapping(uint256 => address) vrfIdPlayer;
}

// Game config
struct GameConstants {
    // Addresses
    address FEE_ADDRESS;
    // Contract Address
    address EQUIPMENT_ADDRESS;
    address COIN_ADDRESS;
    address RING_ADDRESS;
    address TOWN_ADDRESS;
    address OBLIVION_ADDRESS;
    address VRF_ADDRESS;
    // Args
    uint256 BASE_MOVE_SPEED;
    uint256 BASE_ATTACK_POWER;
    uint256 MIN_TRIP_TIME;
    uint256 TOWN_MINT_FEE;
    uint256 MAX_MINT_TOW_PER_MOVE;
    uint256 TOWN_MINT_RATIO_PER_MOVE;
    uint256 OBLIVION_MINT_RATIO_PER_MOVE;
    uint256 SEGMENTATION_DISTANCE_PER_MOVE;
}

/**
 * All of Ring Universus's game storage is stored in a single GameStorage struct.
 *
 * The Diamond Storage pattern (https://dev.to/mudgen/how-diamond-storage-works-90e)
 * is used to set the struct at a specific place in contract storage. The pattern
 * recommends that the hash of a specific namespace (e.g. "ringuniversus.game.storage")
 * be used as the slot to store the struct.
 *
 * Additionally, the Diamond Storage pattern can be used to access and change state inside
 * of Library contract code (https://dev.to/mudgen/solidity-libraries-can-t-have-state-variables-oh-yes-they-can-3ke9).
 * Instead of using `LibStorage.gameStorage()` directly, a Library will probably
 * define a convenience function to accessing state, similar to the `gs()` function provided
 * in the `WithStorage` base contract below.
 *
 * This pattern was chosen over the AppStorage pattern (https://dev.to/mudgen/appstorage-pattern-for-state-variables-in-solidity-3lki)
 * because AppStorage seems to indicate it doesn't support additional state in contracts.
 * This becomes a problem when using base contracts that manage their own state internally.
 *
 * There are a few caveats to this approach:
 * 1. State must always be loaded through a function (`LibStorage.gameStorage()`)
 *    instead of accessing it as a variable directly. The `WithStorage` base contract
 *    below provides convenience functions, such as `gs()`, for accessing storage.
 * 2. Although inherited contracts can have their own state, top level contracts must
 *    ONLY use the Diamond Storage. This seems to be due to how contract inheritance
 *    calculates contract storage layout.
 * 3. The same namespace can't be used for multiple structs. However, new namespaces can
 *    be added to the contract to add additional storage structs.
 * 4. If a contract is deployed using the Diamond Storage, you must ONLY ADD fields to the
 *    very end of the struct during upgrades. During an upgrade, if any fields get added,
 *    removed, or changed at the beginning or middle of the existing struct, the
 *    entire layout of the storage will be broken.
 * 5. Avoid structs within the Diamond Storage struct, as these nested structs cannot be
 *    changed during upgrades without breaking the layout of storage. Structs inside of
 *    mappings are fine because their storage layout is different. Consider creating a new
 *    Diamond storage for each struct.
 *
 * More information on Solidity contract storage layout is available at:
 * https://docs.soliditylang.org/en/latest/internals/layout_in_storage.html
 *
 * Nick Mudge, the author of the Diamond Pattern and creator of Diamond Storage pattern,
 * wrote about the benefits of the Diamond Storage pattern over other storage patterns at
 * https://medium.com/1milliondevs/new-storage-layout-for-proxy-contracts-and-diamonds-98d01d0eadb#bfc1
 */
library LibStorage {
    // Storage are structs where the data gets updated throughout the lifespan of the game
    bytes32 private constant GAME_STORAGE_POSITION =
        keccak256("ringuniversus.player.storage.game");
    // Constants are structs where the data gets configured on game initialization
    // and configured by Admin or Owner
    bytes32 private constant GAME_CONSTANTS_POSITION =
        keccak256("ringuniversus.player.constants.game");

    function gameStorage() internal pure returns (GameStorage storage gs) {
        bytes32 position = GAME_STORAGE_POSITION;
        assembly {
            gs.slot := position
        }
    }

    function gameConstants() internal pure returns (GameConstants storage gc) {
        bytes32 position = GAME_CONSTANTS_POSITION;
        assembly {
            gc.slot := position
        }
    }
}

/**
 * The `WithStorage` contract provides a base contract for Facet contracts to inherit.
 *
 * It mainly provides internal helpers to access the storage structs, which reduces
 * calls like `LibStorage.gameStorage()` to just `gs()`.
 *
 * To understand why the storage stucts must be accessed using a function instead of a
 * state variable, please refer to the documentation above `LibStorage` in this file.
 */

contract WithStorage {
    function gs() internal pure returns (GameStorage storage) {
        return LibStorage.gameStorage();
    }

    function gameConstants() internal pure returns (GameConstants storage) {
        return LibStorage.gameConstants();
    }
}

/**
 * Add shared modifiers.
 */
contract Modifiers is WithStorage {
    modifier onlyOwner() {
        if (msg.sender != LibDiamond.contractOwner())
            revert UnauthorizedOwner({sender: msg.sender});
        _;
    }

    modifier onlyInitializedPlayer(address _player) {
        if (gs().info[_player].createdAt == 0)
            revert UnInitializedPlayer({sender: msg.sender});
        _;
    }

    modifier requiredStatus(Status _status) {
        if (gs().info[msg.sender].status != _status)
            revert PlayerStatusError({
                player: msg.sender,
                // required status
                required: _status,
                // current status
                current: gs().info[msg.sender].status
            });
        _;
    }
}
