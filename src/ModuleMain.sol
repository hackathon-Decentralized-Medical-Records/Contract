// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {ModuleReservation} from "./modules/ModuleReservation.sol";
import {ModuleContribution} from "./modules/ModuleContribution.sol";
import {ModuleFund} from "./modules/ModuleFund.sol";
import {ModuleVRF} from "./modules/ModuleVRF.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import {AutomationCompatibleInterface} from
    "@chainlink/contracts/src/v0.8/automation/interfaces/AutomationCompatibleInterface.sol";
import {LibTypeDef} from "./utils/LibTypeDef.sol";

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

contract ModuleMain is VRFConsumerBaseV2, ModuleReservation, ModuleContribution, ModuleFund {
    constructor(
        address PriceFeed,
        uint64 subscriptionId,
        bytes32 gasLane, // keyHash
        uint256 interval,
        uint32 callbackGasLimit,
        address vrfCoordinatorV2
    ) VRFConsumerBaseV2(vrfCoordinatorV2) ModuleReservation() ModuleContribution(interval) ModuleFund(PriceFeed) {
        setVRFConfig(subscriptionId, gasLane, callbackGasLimit, vrfCoordinatorV2);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        // 获取提供者地址
        address provider = getRequestIdToProvider(requestId); // 根据requestId来确定哪个提供者
        if (provider == address(0)) {
            contributionLottery(randomWords);
        } else {
            judgeLottery(provider, randomWords);
        }
    }
}
