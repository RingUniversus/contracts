// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// Type imports
import {Info} from "../Types.sol";

interface IRUPlayerFacet {
    function playerInfo(address _player) external view returns (Info memory);
}
