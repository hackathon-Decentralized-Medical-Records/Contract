// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {ModuleReservation} from "./modules/ModuleReservation.sol";
import {ModuleContribution} from "./modules/ModuleContribution.sol";
import {ModuleFund} from "./modules/ModuleFund.sol";
import {ModuleVRF} from "./modules/ModuleVRF.sol";

// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

contract ModuleMain is ModuleReservation, ModuleContribution, ModuleFund {
    constructor(
        address PriceFeed,
        uint64 subscriptionId,
        bytes32 gasLane, // keyHash
        uint256 interval,
        uint32 callbackGasLimit,
        address vrfCoordinatorV2
    ) ModuleReservation(vrfCoordinatorV2) ModuleContribution(vrfCoordinatorV2, interval) ModuleFund(PriceFeed) {
        setVRFConfig(subscriptionId, gasLane, callbackGasLimit, vrfCoordinatorV2);
    }
}
