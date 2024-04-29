// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Role} from "./Role.sol";

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

contract System is ReentrancyGuard {
    /**
     * State Variables
     */
    mapping(address user => address) private s_userToContract;

    /**
     * Events
     */
    event System__UserContractAdded(address indexed user, address indexed contractAddress, uint8 indexed roleType);

    /**
     * Functions
     */
    constructor() {}

    /**
     * frontend ABI
     * @dev mapping new user and his contract to system
     * @param roleType type of user. main charactor :0 - patient, 1 - doctor
     */
    function newUserContract(uint8 roleType) public payable nonReentrant {
        Role role = new Role{value: msg.value}(msg.sender, address(this), roleType);

        s_userToContract[msg.sender] = address(role);
        emit System__UserContractAdded(msg.sender, address(role), roleType);
    }

    function getUserToContract(address user) public view returns (address) {
        return s_userToContract[user];
    }
}
