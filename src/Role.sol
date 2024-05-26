// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./ModuleMain.sol";
import "../src/utils/LibTypeDef.sol";

contract Role is ERC1155URIStorage, Ownable, ReentrancyGuard {
    error Role__improperRole(address user, uint8 roleType);
    error Role__mintNotApproved(address user);
    error Role__tokenNotApproved(address provider, uint256 id);

    LibTypeDef.RoleType private immutable i_roleType;
    address private s_systemAddress;
    bool private s_needFund;
    mapping(address => bool) private s_approvedMintState;
    mapping(uint256 => mapping(address => bool)) private s_idToProviderApprovalState;

    event Role__ApproveMintAddress(address indexed user);
    event Role__MaterialAddedAndCancelAddRight(address indexed sender, uint256 indexed id);
    event Role__TokenAccessApproved(uint256 indexed id, address indexed provider);
    event Role__FundRequested(string indexed statement, uint256 indexed amountInUsd);

    modifier mintApproved(address user) {
        if (!s_approvedMintState[user] && _msgSender() != owner()) {
            revert Role__mintNotApproved(user);
        }
        _;
    }

    modifier tokenApproved(address provider, uint256 id) {
        if (!s_idToProviderApprovalState[id][provider] && !s_needFund) {
            revert Role__tokenNotApproved(provider, id);
        }
        _;
    }

    modifier onlyPatient() {
        if (i_roleType != LibTypeDef.RoleType.PATIENT) {
            revert Role__improperRole(_msgSender(), uint8(i_roleType));
        }
        _;
    }

    constructor(address user, address systemAddress, LibTypeDef.RoleType roleType)
        ERC1155("")
        Ownable(user)
    {
        require(
            type(LibTypeDef.RoleType).min <= roleType && roleType <= type(LibTypeDef.RoleType).max, "Invalid role type"
        );
        i_roleType = roleType;
        s_systemAddress = systemAddress;
    }
    fallback() external payable {}

    receive() external payable {}

    function setApprovalForAddingMaterial(address provider) public onlyOwner {
        s_approvedMintState[provider] = true;
        emit Role__ApproveMintAddress(provider);
    }

    function setApprovalForTokenId(uint256 id, address provider) public onlyOwner {
        s_idToProviderApprovalState[id][provider] = true;
        emit Role__TokenAccessApproved(id, provider);
    }

    function addMaterial(uint256 id, uint256 amount, bytes memory data) public mintApproved(_msgSender()) {
        _mint(owner(), id, amount, data);
        s_approvedMintState[_msgSender()] = false;
        emit Role__MaterialAddedAndCancelAddRight(_msgSender(), id);
    }

    function requestFund(string memory statement, uint256 amountUsd) public onlyOwner onlyPatient {
        s_needFund = true;
        ModuleMain(s_systemAddress).registerFundRequest(_msgSender(), address(this), amountUsd);
        emit Role__FundRequested(statement, amountUsd);
    }
}