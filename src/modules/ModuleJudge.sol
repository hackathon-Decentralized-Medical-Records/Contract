// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {ModuleVRF} from "./ModuleVRF.sol";

contract ModuleJudge is ModuleVRF{
    constructor(uint64 subscriptionId,
        bytes32 gasLane, // keyHash
        uint32 callbackGasLimit,
        address vrfCoordinatorV2,
        uint256 interval) ModuleVRF(subscriptionId, gasLane, callbackGasLimit, vrfCoordinatorV2){}
}