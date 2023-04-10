// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// Type imports
import {Status} from "./Types.sol";

// Error when player status not required
// player, required status, current status
error PlayerStatusError(address player, Status required, Status current);

// Error when player uninitialized
error UnInitializedPlayer(address sender);
