// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {LibTypeDef} from "../../src/utils/LibTypeDef.sol";
import {Role} from "./../Role.sol";

contract ModuleManage {
    mapping(address user => address) internal s_userToContract;
    mapping(address user => LibTypeDef.RoleType) internal s_userToRoleType;

    event System__NewUserContractAdded(address indexed user, address indexed contractAddress, uint8 indexed roleType);
    event System__NewUserAdded(address indexed user, uint8 indexed roleType);

    function addNewUserToSystem(LibTypeDef.RoleType roleType) public {
        s_userToRoleType[msg.sender] = roleType;
        emit System__NewUserAdded(msg.sender, uint8(roleType));
        if (roleType == LibTypeDef.RoleType.PATIENT) {
            _addNewUserContractToSystem(roleType);
        }
    }

    function getUserToContract(address user) public view returns (address) {
        return s_userToContract[user];
    }

    function _addNewUserContractToSystem(LibTypeDef.RoleType roleType) private {
        Role role = new Role(msg.sender, address(this), roleType);
        s_userToContract[msg.sender] = address(role);
        emit System__NewUserContractAdded(msg.sender, address(role), uint8(roleType));
    }
}
