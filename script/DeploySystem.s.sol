// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script} from "forge-std/Script.sol";
import {System} from "../src/System.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";

contract DeploySystem is Script {
    HelperConfig helperConfig;

    function run() external returns (System) {
        helperConfig = new HelperConfig();

        (, , , , , , , address priceFeed) = helperConfig.activeNetworkConfig();
        vm.startBroadcast();
        System system = new System(priceFeed);
        vm.stopBroadcast();
        return system;
    }
}