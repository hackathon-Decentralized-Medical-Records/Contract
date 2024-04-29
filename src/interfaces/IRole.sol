// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

interface IRole {
    function appointDiagnosisCheck(uint256 appointedTime)
        external
        returns (bool success, uint256 validTimeSinceEpoch);
}
