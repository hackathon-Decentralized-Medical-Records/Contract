// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {ModuleJudge} from "../modules/ModuleJudge.sol";

contract ModuleReservation is ModuleJudge, ReentrancyGuard {
    error ModuleReservation__NoReservation();
    error ModuleReservation__TransferFail();

    mapping(address provider => address) private s_userToReservationAddress;

    event ModuleReservation__ReservationAppointed(
        address indexed user, address indexed provider, uint256 appointTimeSinceEpoch
    );
    event ModuleReservation__AppointedFinished(address indexed user, address indexed provider, uint256 amountInWei);

    constructor() ModuleJudge() {}

    function appointReservation(address provider, uint256 appointTimeSinceEpoch, uint256 reservationFee)
        public
        payable
    {
        s_userToReservationAddress[msg.sender] = provider;
        (bool success,) = payable(provider).call{value: reservationFee}("");
        if (!success) {
            revert ModuleReservation__TransferFail();
        }

        emit ModuleReservation__ReservationAppointed(msg.sender, provider, appointTimeSinceEpoch);
    }

    //TODO: disapprove provider access to token
    function finishAppointment(address provider, uint256 AppointmentFee) public payable {
        if (s_userToReservationAddress[msg.sender] == address(0)) {
            revert ModuleReservation__NoReservation();
        }
        s_userToReservationAddress[msg.sender] = address(0);
        (bool success,) = provider.call{value: AppointmentFee}("");
        if (!success) {
            revert ModuleReservation__TransferFail();
        }

        emit ModuleReservation__AppointedFinished(msg.sender, provider, AppointmentFee);
    }

    function getReservationInfo() public view returns (address) {
        return s_userToReservationAddress[msg.sender];
    }
}
