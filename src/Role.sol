// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {System} from "./System.sol";
import {IRole} from "./interfaces/IRole.sol";

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

contract Role is Ownable, ReentrancyGuard, IRole {
    /**
     * Error
     */
    error Role__improperRole(address user, uint8 roleType);
    error Role__invalidAppointedTime(uint256 roleType);
    error Role__InvalidAppointeeContractAddress();

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
    RoleType private immutable i_roleType;
    address private s_systemAddress;

    /**
     * Modifier
     */
    modifier patientOnly() {
        if (i_roleType != RoleType.PATIENT) {
            revert Role__improperRole(msg.sender, uint8(i_roleType));
        }
        _;
    }

    modifier doctorOnly() {
        if (i_roleType != RoleType.DOCTOR) {
            revert Role__improperRole(msg.sender, uint8(i_roleType));
        }
        _;
    }

    modifier serviceOnly() {
        if (i_roleType != RoleType.SERVICE) {
            revert Role__improperRole(msg.sender, uint8(i_roleType));
        }
        _;
    }

    modifier dataOnly() {
        if (i_roleType != RoleType.DATA) {
            revert Role__improperRole(msg.sender, uint8(i_roleType));
        }
        _;
    }

    /**
     * Functions
     */
    constructor(address user, address systemAddress, uint8 roleType) payable Ownable(user) {
        require(uint8(type(RoleType).min) <= roleType && roleType <= uint8(type(RoleType).max), "Invalid role type");
        i_roleType = RoleType(roleType);
        s_systemAddress = systemAddress;
    }

    fallback() external payable {}

    receive() external payable {}

    /**
     * @dev Patient can only appoint diagnosis
     */
    function appointDiagnosisRequest(address appointee, uint256 appointedTime)
        public
        patientOnly
        nonReentrant
        returns (uint256)
    {
        address appointeeContractAddress = System(s_systemAddress).getUserToContract(appointee);
        if (appointeeContractAddress == address(0)) {
            revert Role__InvalidAppointeeContractAddress();
        }
        (bool success, uint256 validTimeSinceEpoch) =
            IRole(appointeeContractAddress).appointDiagnosisCheck(appointedTime);
        //FIXME
        if (!success) {
            return validTimeSinceEpoch;
        } else {
            return 0;
        }
    }

    //TODO: Appointment data storage ?
    function appointDiagnosisCheck(uint256 appointedTime) public doctorOnly nonReentrant returns (bool, uint256) {
        if (block.timestamp >= appointedTime) {
            revert Role__invalidAppointedTime(appointedTime);
        }
        // FIXME
        return (true, block.timestamp);
    }
}
