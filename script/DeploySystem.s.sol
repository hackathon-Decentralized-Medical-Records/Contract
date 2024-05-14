// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script} from "forge-std/Script.sol";
import {ModuleMain} from "../src/ModuleMain.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";

contract DeployModuleMain is Script {
    HelperConfig helperConfig;

    function run() external returns (ModuleMain) {
        helperConfig = new HelperConfig();

        (
            uint64 subscriptionId,
            bytes32 gasLane,
            uint256 automationUpdateInterval,
            uint32 callbackGasLimit,
            address vrfCoordinatorV2, /* address link */
            , /* uint256 deployerKey */
            ,
            address priceFeed
        ) = helperConfig.activeNetworkConfig();
        vm.startBroadcast();
        ModuleMain system =
            new ModuleMain(priceFeed, subscriptionId, gasLane, automationUpdateInterval, callbackGasLimit, vrfCoordinatorV2);
        vm.stopBroadcast();
        return system;
    }
}
