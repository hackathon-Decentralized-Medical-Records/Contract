// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract ModuleReservation is ReentrancyGuard {
    error ModuleReservationNoReservation();
    error ModuleReservationTransferFail();

    mapping(address provider => address) private s_userToReservationAddress;

    event ModuleReservationReservationAppointed(address indexed user, address indexed provider, uint256 appointTimeSinceEpoch);
    event ModuleReservationAppointedFinished(address indexed user, address indexed provider, uint256 amountInWei);

    constructor() {}

    function appointReservation(address provider, uint256 appointTimeSinceEpoch, uint256 reservationFee)
        public
        payable
    {
        s_userToReservationAddress[msg.sender] = provider;
        (bool success,) = payable(provider).call{value: reservationFee}("");
        if (!success) {
            revert ModuleReservationTransferFail();
        }

        emit ModuleReservationReservationAppointed(msg.sender, provider, appointTimeSinceEpoch);
    }

    //TODO: disapprove provider access to token
    function finishAppointment(address provider, uint256 AppointmentFee) public payable {
        if(s_userToReservationAddress[msg.sender] == address(0)) {
            revert ModuleReservationNoReservation();
        }
        s_userToReservationAddress[msg.sender] = address(0);
        (bool success,) = provider.call{value: AppointmentFee}("");
        if (!success) {
            revert ModuleReservationTransferFail();
        }

        emit ModuleReservationAppointedFinished(msg.sender, provider, AppointmentFee);
    }

    function getReservationInfo() public view returns (address) {
        return s_userToReservationAddress[msg.sender];
    }
}