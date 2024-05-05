// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {System} from "./System.sol";
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

contract Role is ERC721, ERC721URIStorage, Ownable, ReentrancyGuard {
    /**
     * Error
     */
    error Role__improperRole(address user, uint8 roleType);
    error Role__mintNotApproved(address user);
    error Role__TransferFail();
    error Role__tokenNotApproved(address provider, uint256 tokenId);

    /**
     * Type declarations
     */
    enum RoleType {
        PATIENT,
        DOCTOR,
        SERVICE,
        DATA
    }

    struct Medicalcord {
        mapping(uint256 index => address) indexToProvider;
        uint256 createTimeSinceEpoch;
    }

    /**
     * State Variables
     */
    RoleType private immutable i_roleType;
    address private s_systemAddress;
    uint256 private s_tokenCounter;
    bool private s_needFund;
    mapping(address => bool) private s_approvedMintState;
    mapping(uint256 tokenId => string) private s_tokenIdToMedicalInfo;
    mapping(address provider => bool) private s_reservationState;
    mapping(uint256 tokenId => mapping(address provider => bool)) private s_tokenToProviderApprovalState;

    /**
     * Events
     */
    event Role__MaterialAddedAndCancelAddRight(address indexed sender, uint256 indexed tokenId);
    event Role__ApproveMintAddress(address indexed user);
    event Role__ReservationAppointed(
        address indexed user, address indexed provider, uint256 indexed appointTimeSinceEpoch
    );
    event Role__AppointedFinished(address indexed user, address indexed provider);
    event Role__TokenAccessApproved(uint256 indexed tokenId, address indexed provider);
    event Role__FundRequested(string indexed statement, uint256 indexed amountInUsd);

    /**
     * Modifier
     */
    modifier mintApproved(address user) {
        if (s_approvedMintState[user] == false && msg.sender != owner()) {
            revert Role__mintNotApproved(user);
        }
        _;
    }

    modifier tokenApproved(address provider, uint256 tokenId) {
        if (s_tokenToProviderApprovalState[tokenId][provider] == false && s_needFund == false) {
            revert Role__tokenNotApproved(provider, tokenId);
        }
        _;
    }

    modifier onlyPatient() {
        if (i_roleType != RoleType.PATIENT) {
            revert Role__improperRole(msg.sender, uint8(i_roleType));
        }
        _;
    }

    modifier onlyDoctor() {
        if (i_roleType != RoleType.DOCTOR) {
            revert Role__improperRole(msg.sender, uint8(i_roleType));
        }
        _;
    }

    modifier onlyService() {
        if (i_roleType != RoleType.SERVICE) {
            revert Role__improperRole(msg.sender, uint8(i_roleType));
        }
        _;
    }

    modifier onlyData() {
        if (i_roleType != RoleType.DATA) {
            revert Role__improperRole(msg.sender, uint8(i_roleType));
        }
        _;
    }

    /**
     * Functions
     */
    constructor(address user, address systemAddress, uint8 roleType)
        payable
        ERC721("Medical Materials", "MM")
        Ownable(user)
    {
        require(type(RoleType).min <= RoleType(roleType) && RoleType(roleType) <= type(RoleType).max, "Invalid role type");
        i_roleType = RoleType(roleType);
        s_systemAddress = systemAddress;
    }

    fallback() external payable {}

    receive() external payable {}

    function setApprovalForAddingMaterial(address provider) public onlyOwner {
        s_approvedMintState[provider] = true;
        emit Role__ApproveMintAddress(provider);
    }

    function setApprovalForTokenId(uint256 tokenId, address provider) public onlyOwner {
        s_tokenToProviderApprovalState[tokenId][provider] = true;
        emit Role__TokenAccessApproved(tokenId, provider);
    }

    function addMaterial(string memory uri) public mintApproved(msg.sender) {
        uint256 tokenId = s_tokenCounter++;
        _safeMint(owner(), tokenId);
        _setTokenURI(tokenId, uri);
        s_approvedMintState[msg.sender] = false;
        emit Role__MaterialAddedAndCancelAddRight(msg.sender, tokenId);
    }

    function updateURI(uint256 tokenId, string memory uri) public mintApproved(msg.sender) {
        _setTokenURI(tokenId, uri);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) tokenApproved(msg.sender, tokenId) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function appointReservation(address provider, uint256 appointTimeSinceEpoch, uint256 reservationFee)
        public
        payable
        onlyOwner
        onlyPatient
    {
        s_reservationState[provider] = true;
        (bool success,) = provider.call{value: reservationFee}("");
        if (!success) {
            revert Role__TransferFail();
        }

        emit Role__ReservationAppointed(msg.sender, provider, appointTimeSinceEpoch);
    }

    //TODO: disapprove provider access to token
    function finishAppointment(address provider, uint256 AppointmentFee) public payable onlyOwner onlyPatient {
        s_reservationState[provider] = false;
        (bool success,) = provider.call{value: AppointmentFee}("");
        if (!success) {
            revert Role__TransferFail();
        }

        emit Role__AppointedFinished(msg.sender, provider);
    }

    function getReservationStatus(address provider) public view returns (bool) {
        return s_reservationState[provider];
    }

    function requestFund(string memory statement, uint256 amountUsd) public onlyOwner onlyPatient {
        s_needFund = true;
        System(s_systemAddress).registerFundRequest(msg.sender, address(this), amountUsd);
        emit Role__FundRequested(statement, amountUsd);
    }

}
