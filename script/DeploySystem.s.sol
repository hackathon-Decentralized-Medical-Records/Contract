// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script} from "forge-std/Script.sol";
import {System} from "../src/System.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";

contract DeploySystem is Script {
    HelperConfig helperConfig;

    function run() external returns (System) {
        helperConfig = new HelperConfig();

        (uint64 subscriptionId, bytes32 gasLane, uint256 automationUpdateInterval, uint32 callbackGasLimit, address vrfCoordinatorV2, /* address link */, /* uint256 deployerKey */, address priceFeed) = helperConfig.activeNetworkConfig();
        vm.startBroadcast();
        System system = new System(priceFeed, subscriptionId, gasLane, automationUpdateInterval, callbackGasLimit, vrfCoordinatorV2);
        vm.stopBroadcast();
        return system;
    }
}
