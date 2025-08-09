// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/// @title MerkleEpochDistributor
/// @notice Claim-based distribution at epoch granularity for massive scale.
contract MerkleEpochDistributor is AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    IERC20 public immutable token;

    struct Epoch {
        bytes32 merkleRoot; // leaf: keccak256(abi.encode(account, amount))
        mapping(uint256 => uint256) claimedBitMap; // index / 256 => bitmap
        uint256 totalAllocated;
    }

    mapping(uint256 => Epoch) private _epochs;

    event EpochRootSet(uint256 indexed epochId, bytes32 root, uint256 totalAllocated);
    event Claimed(uint256 indexed epochId, uint256 indexed index, address indexed account, uint256 amount);

    constructor(address admin, IERC20 token_) {
        token = token_;
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ADMIN_ROLE, admin);
    }

    function setEpochRoot(uint256 epochId, bytes32 root, uint256 totalAllocated) external onlyRole(ADMIN_ROLE) {
        require(root != bytes32(0), "root=0");
        Epoch storage e = _epochs[epochId];
        e.merkleRoot = root;
        e.totalAllocated = totalAllocated;
        emit EpochRootSet(epochId, root, totalAllocated);
    }

    function isClaimed(uint256 epochId, uint256 index) public view returns (bool) {
        uint256 wordIndex = index / 256;
        uint256 bitIndex = index % 256;
        uint256 word = _epochs[epochId].claimedBitMap[wordIndex];
        uint256 mask = (1 << bitIndex);
        return (word & mask) != 0;
    }

    function _setClaimed(uint256 epochId, uint256 index) private {
        uint256 wordIndex = index / 256;
        uint256 bitIndex = index % 256;
        _epochs[epochId].claimedBitMap[wordIndex] |= (1 << bitIndex);
    }

    function claim(uint256 epochId, uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof) external {
        require(!isClaimed(epochId, index), "claimed");
        bytes32 node = keccak256(abi.encode(account, amount));
        require(MerkleProof.verify(merkleProof, _epochs[epochId].merkleRoot, node), "bad proof");
        _setClaimed(epochId, index);
        require(token.transfer(account, amount), "xfer fail");
        emit Claimed(epochId, index, account, amount);
    }
}


