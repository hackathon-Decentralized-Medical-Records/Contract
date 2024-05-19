// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {ModuleJudge} from "../modules/ModuleJudge.sol";

contract ModuleReservation is ModuleJudge {
    error ModuleReservation__NoReservation();
    error ModuleReservation__TransferFail();

    mapping(address provider => address) private s_userToReservationAddress;
    mapping(address user => mapping(address provider => uint256)) s_userToProviderFee;

    event ModuleReservation__ReservationRequested(
        address indexed user, address indexed provider, uint256 appointTimeSinceEpoch
    );
    event ModuleReservation__AppointmentFinished(address indexed user, address indexed provider, uint256 amountInWei);
    event ModuleReservation__ReservationCanceled(address indexed user, address indexed provider, uint256 amountInWei);
    event ModuleReservation__AppointmentStarted(address indexed user, address indexed provider, uint256 amountInWei);

    function requestReservation(address provider, uint256 appointTimeSinceEpoch) public payable {
        s_userToReservationAddress[msg.sender] = provider;
        s_userToProviderFee[msg.sender][provider] = msg.value;
        emit ModuleReservation__ReservationRequested(msg.sender, provider, appointTimeSinceEpoch);
    }

    function cancelReservation(address provider) public {
        s_userToReservationAddress[msg.sender] = address(0);
        uint256 amount = s_userToProviderFee[msg.sender][provider];
        s_userToProviderFee[msg.sender][provider] = 0;
        (bool success,) = payable(msg.sender).call{value: amount}("");
        if (!success) {
            revert ModuleReservation__TransferFail();
        }
        emit ModuleReservation__ReservationCanceled(msg.sender, provider, amount);
    }

    function startAppointment(address provider) public payable {
        if (s_userToReservationAddress[msg.sender] == address(0)) {
            revert ModuleReservation__NoReservation();
        }
        uint256 amount = s_userToProviderFee[msg.sender][provider];
        (bool success,) = provider.call{value: amount}("");
        s_userToProviderFee[msg.sender][provider] = 0;
        if (!success) {
            revert ModuleReservation__TransferFail();
        }
        emit ModuleReservation__AppointmentStarted(msg.sender, provider, amount);
    }

    //TODO: disapprove provider access to token
    function finishAppointment(address provider) public payable {
        s_userToReservationAddress[msg.sender] = address(0);
        (bool success,) = provider.call{value: msg.value}("");
        if (!success) {
            revert ModuleReservation__TransferFail();
        }

        emit ModuleReservation__AppointmentFinished(msg.sender, provider, msg.value);
    }

    function getReservationInfo() public view returns (address) {
        return s_userToReservationAddress[msg.sender];
    }
}
