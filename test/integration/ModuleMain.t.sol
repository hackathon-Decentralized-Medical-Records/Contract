//SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {ModuleMain} from "src/ModuleMain.sol";
import {Role} from "src/Role.sol";
import {Test, console} from "forge-std/Test.sol";
import {DeployModuleMain} from "script/DeploySystem.s.sol";
import {LibTypeDef} from "src/utils/LibTypeDef.sol";
import {ModuleReservation} from "src/modules/ModuleReservation.sol";
import {ModuleFund} from "src/modules/ModuleFund.sol";

contract ModuleMainTest is Test {
    ModuleMain system;
    address public PATIENT = makeAddr("patient");
    address public DOCTORA = makeAddr("doctorA");
    address public DOCTORB = makeAddr("doctorB");
    address public PATIENT_CONTRACT;

    function setUp() public {
        DeployModuleMain deployModuleMain = new DeployModuleMain();
        system = deployModuleMain.run();
        vm.startPrank(PATIENT);
        system.addNewUserToSystem(LibTypeDef.RoleType.PATIENT);
        vm.stopPrank();
        vm.deal(PATIENT, 1e20);
        PATIENT_CONTRACT = system.getUserToContract(PATIENT);

        vm.startPrank(DOCTORA);
        system.addNewUserToSystem(LibTypeDef.RoleType.DOCTOR);
        vm.deal(DOCTORA, 1e20);
        vm.stopPrank();

        vm.startPrank(DOCTORB);
        system.addNewUserToSystem(LibTypeDef.RoleType.DOCTOR);
        vm.stopPrank();
    }

    function testRequestReservation() public {
        vm.startPrank(PATIENT);
        vm.expectEmit(true, true, false, false);
        emit ModuleReservation.ModuleReservation__ReservationRequested(PATIENT, DOCTORA, block.timestamp + 1 days);
        system.requestReservation{value: 1e9}(DOCTORA, block.timestamp + 1 days);
        vm.stopPrank();
    }

    function testCancelReservation() public {
        vm.startPrank(PATIENT);
        vm.expectEmit(false, false, true, false);
        emit ModuleReservation.ModuleReservation__ReservationCanceled(PATIENT, DOCTORA, 1e9);
        system.cancelReservation(DOCTORA);
        vm.stopPrank();
    }

    function testStartAppointment() public {
        vm.startPrank(PATIENT);
        system.requestReservation{value: 1e9}(DOCTORA, block.timestamp + 1 days);
        vm.expectEmit(true, true, true, false);
        emit ModuleReservation.ModuleReservation__AppointmentStarted(PATIENT, DOCTORA, 1e9);
        system.startAppointment(DOCTORA);
        vm.stopPrank();
    }

    function testAddMaterial() public {
        vm.startPrank(PATIENT);
        Role(payable(PATIENT_CONTRACT)).setApprovalForAddingMaterial(DOCTORA);
        vm.stopPrank();

        vm.expectEmit(true, true, false, false);
        emit Role.Role__MaterialAddedAndCancelAddRight(DOCTORA, 0);
        vm.startPrank(DOCTORA);
        Role(payable(PATIENT_CONTRACT)).addMaterial("TestMaterial");
        vm.stopPrank();
    }

    function testMaterialURI() public {
        vm.startPrank(PATIENT);
        Role(payable(PATIENT_CONTRACT)).setApprovalForAddingMaterial(DOCTORA);
        vm.stopPrank();

        vm.startPrank(DOCTORA);
        Role(payable(PATIENT_CONTRACT)).addMaterial("TestMaterial");
        string memory uri = Role(payable(PATIENT_CONTRACT)).uri(0);
        assertEq(uri, "TestMaterial");
        vm.stopPrank();
    }

    function testAddFund() public {
        //vm.expectEmit(true, true, false, false);
        //emit Role.Role__FundRequested("TestFund", 1e18);
        vm.startPrank(PATIENT);
        Role(payable(PATIENT_CONTRACT)).requestFund("TestFund",3e4); //3e4=1e19*3
        vm.stopPrank();
        LibTypeDef.FundInfo memory fundInfo = system.getFundInfo(0);
        //console.log(fundInfo.requiredAmountInWei);
        //3e4 * 1e18 * 1e8 / 3e11 = 1e19
        assertEq(fundInfo.requiredAmountInWei, 1e19);
        assertEq(fundInfo.userAddress, PATIENT);
    }

    function testDonation() public {
        vm.startPrank(PATIENT);
        Role(payable(PATIENT_CONTRACT)).requestFund("TestFund",3e4);
        vm.stopPrank();

        vm.expectEmit(true, true, false, false);
		emit ModuleFund.System__NewDonation(0, PATIENT, DOCTORA, 1e18);
        vm.startPrank(DOCTORA);
        system.donation{value: 1e18}(0, PATIENT);
        vm.stopPrank();

        LibTypeDef.FundInfo memory fundInfo = system.getFundInfo(0);

        assertEq(fundInfo.userAddress, PATIENT);
        assertEq(fundInfo.actualAmountInWei, 1e18);
        assertEq(fundInfo.tempAmountInWei, 1e18);
    }

}