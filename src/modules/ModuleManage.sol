// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {LibTypeDef} from "../../src/utils/LibTypeDef.sol";
import {Role} from "./../Role.sol";

abstract contract ModuleManage {
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
        bytes memory bytecode = type(Role).creationCode;
        bytecode = abi.encodePacked(bytecode, abi.encode(msg.sender, address(this), roleType));

        address roleAddress;
        // Compute the address for the new contract, this step is optional if you don't need to know the address beforehand.
        bytes32 salt = keccak256(abi.encodePacked(msg.sender, address(this), roleType));

        // Using create2 to deploy a new Role contract
        assembly {
            roleAddress := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }

        require(roleAddress != address(0), "Failed to create the Role contract");

        s_userToContract[msg.sender] = roleAddress;
        emit System__NewUserContractAdded(msg.sender, roleAddress, uint8(roleType));
    }
}
