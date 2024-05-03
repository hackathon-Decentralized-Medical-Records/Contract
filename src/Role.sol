// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
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

    /**
     * Type declarations
     */
    enum RoleType {
        PATIENT,
        DOCTOR,
        SERVICE,
        DATA
    }

    struct MedicalInfo {
        string metaData;
        uint256 createTimeSinceEpoch;
        address creatorAddress;
    }

    /**
     * State Variables
     */
    RoleType private immutable i_roleType;
    address private s_systemAddress;
    mapping(uint256 tokenId => MedicalInfo) private s_tokenIdToMedicalInfo;
    uint256 private s_tokenCounter;

    /**
     * Events
     */
    event Role__MaterialsMinted(address sender, uint256 tokenId);

    /**
     * Modifier
     */
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
        require(uint8(type(RoleType).min) <= roleType && roleType <= uint8(type(RoleType).max), "Invalid role type");
        i_roleType = RoleType(roleType);
        s_systemAddress = systemAddress;
    }

    fallback() external payable {}

    receive() external payable {}

    function safeMint(string memory uri) public onlyOwner onlyPatient {
        uint256 tokenId = s_tokenCounter++;
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, uri);
        emit Role__MaterialsMinted(msg.sender, tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
