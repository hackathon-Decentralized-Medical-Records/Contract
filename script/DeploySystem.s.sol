// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script} from "forge-std/Script.sol";
import {System} from "../src/System.sol";
contract DeploySystem is Script {

    function run() external returns (System) {
        vm.startBroadcast();
        System system = new System();
        vm.stopBroadcast();
        return system;
    }
}