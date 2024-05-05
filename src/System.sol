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
     * Type declarations
     */
    enum RoleType {
        PATIENT,
        DOCTOR,
        SERVICE,
        DATA
    }

    /**
     * State Variables
     */
    mapping(address user => address) private s_userToContract;
    mapping(address user => RoleType) private s_userToRoleType;
    mapping(address user => uint256) private s_needFund;

    /**
     * Events
     */
    event System__NewUserContractAdded(address indexed user, address indexed contractAddress, uint8 indexed roleType);
    event System__NewUserAdded(address indexed user, uint8 indexed roleType);

    /**
     * Functions
     */
    constructor() {}

    /**
     * frontend ABI
     * @dev mapping new user and his contract to system
     * @param roleType type of user. main charactor :0 - patient, 1 - doctor
     */
    function addNewUserToSystem(RoleType roleType) public nonReentrant {
        s_userToRoleType[msg.sender] = roleType;
        emit System__NewUserAdded(msg.sender, uint8(roleType));
        if (roleType == RoleType.PATIENT) {
            _addNewUserContractToSystem(roleType);
        }
    }

    function getUserToContract(address user) public view returns (address) {
        return s_userToContract[user];
    }

    function _addNewUserContractToSystem(RoleType roleType) private {
        Role role = new Role(msg.sender, address(this), uint8(roleType));
        s_userToContract[msg.sender] = address(role);
        emit System__NewUserContractAdded(msg.sender, address(role), uint8(roleType));
    }

    function registerFundRequest(address user, address contractAddress, uint256 amountInUsd) public {
        if(s_userToContract[user] != contractAddress) {
            revert();
        }
        s_needFund[user] = amountInUsd;
    }
}
