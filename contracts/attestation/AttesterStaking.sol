// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title AttesterStaking
/// @notice Simple staking/slashing for attesters. Protocol governance controls slashing.
contract AttesterStaking is AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant SLASHER_ROLE = keccak256("SLASHER_ROLE");

    IERC20 public immutable stakeToken;
    uint256 public immutable minStake;

    mapping(address => uint256) public stakeOf;

    event Staked(address indexed attester, uint256 amount);
    event Unstaked(address indexed attester, uint256 amount);
    event Slashed(address indexed attester, uint256 amount, address indexed recipient);

    constructor(address admin, IERC20 stakeToken_, uint256 minStake_) {
        stakeToken = stakeToken_;
        minStake = minStake_;
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ADMIN_ROLE, admin);
        _grantRole(SLASHER_ROLE, admin);
    }

    function stake(uint256 amount) external {
        require(amount > 0, "amount=0");
        require(stakeToken.transferFrom(msg.sender, address(this), amount), "xfer fail");
        stakeOf[msg.sender] += amount;
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) external {
        require(amount > 0, "amount=0");
        uint256 current = stakeOf[msg.sender];
        require(current >= amount, "insufficient");
        uint256 newStake = current - amount;
        require(newStake == 0 || newStake >= minStake, "below min");
        stakeOf[msg.sender] = newStake;
        require(stakeToken.transfer(msg.sender, amount), "xfer fail");
        emit Unstaked(msg.sender, amount);
    }

    function isStaked(address attester) external view returns (bool) {
        return stakeOf[attester] >= minStake;
    }

    function slash(address attester, uint256 amount, address recipient) external onlyRole(SLASHER_ROLE) {
        require(recipient != address(0), "recipient=0");
        uint256 current = stakeOf[attester];
        require(current >= amount, "exceeds");
        stakeOf[attester] = current - amount;
        require(stakeToken.transfer(recipient, amount), "xfer fail");
        emit Slashed(attester, amount, recipient);
    }
}


