// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {EligibilityRegistry} from "./EligibilityRegistry.sol";

/// @title RedistributionPool
/// @notice Holds overflow funds and periodically redistributes them to eligible addresses.
/// @dev Pagination via distributionCursor + maxRecipients to avoid OOG.
contract RedistributionPool is AccessControl, ReentrancyGuard, Pausable {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant DEPOSITOR_ROLE = keccak256("DEPOSITOR_ROLE");

    IERC20 public immutable token; // e.g., a stablecoin token
    EligibilityRegistry public immutable registry;

    uint64 public lastDistributionTime;
    uint64 public immutable minDistributionInterval; // e.g., 7 days or 30 days
    uint256 public distributionCursor; // index into registry eligible set

    event Deposited(address indexed from, uint256 amount);
    event Distributed(uint256 recipientsProcessed, uint256 amountPerRecipient, uint64 timestamp, uint256 newCursor);

    constructor(address admin, IERC20 token_, EligibilityRegistry registry_, uint64 minIntervalSeconds) {
        require(address(token_) != address(0), "token=0");
        require(address(registry_) != address(0), "registry=0");
        token = token_;
        registry = registry_;
        minDistributionInterval = minIntervalSeconds;
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ADMIN_ROLE, admin);
    }

    /// @notice Deposit overflow funds. Typically called by payroll contracts.
    function deposit(uint256 amount) external nonReentrant whenNotPaused {
        require(amount > 0, "amount=0");
        bool ok = token.transferFrom(msg.sender, address(this), amount);
        require(ok, "transfer failed");
        emit Deposited(msg.sender, amount);
    }

    /// @notice Distributes the current balance equally to up to maxRecipients, starting at distributionCursor.
    /// @dev Can be called by anyone (permissionless), throttled by minDistributionInterval once a full cycle finishes.
    function distribute(uint256 maxRecipients) external nonReentrant whenNotPaused {
        uint256 totalEligible = registry.eligibleCount();
        require(totalEligible > 0, "no eligible");

        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "no balance");

        uint256 remainingRecipients = totalEligible - (distributionCursor % totalEligible);
        uint256 num = maxRecipients < remainingRecipients ? maxRecipients : remainingRecipients;
        require(num > 0, "num=0");

        uint256 amountPerRecipient = balance / num; // split only among batch to avoid dust; remainder stays for next call
        require(amountPerRecipient > 0, "too small");

        for (uint256 i = 0; i < num; i++) {
            address recipient = registry.eligibleAtIndex((distributionCursor + i) % totalEligible);
            bool ok = token.transfer(recipient, amountPerRecipient);
            require(ok, "xfer fail");
        }

        distributionCursor = (distributionCursor + num) % totalEligible;

        // If we completed a full cycle, enforce min interval
        if (distributionCursor == 0) {
            require(
                lastDistributionTime == 0 || block.timestamp >= lastDistributionTime + minDistributionInterval,
                "interval not reached"
            );
            lastDistributionTime = uint64(block.timestamp);
        }

        emit Distributed(num, amountPerRecipient, uint64(block.timestamp), distributionCursor);
    }

    function pause() external onlyRole(ADMIN_ROLE) { _pause(); }
    function unpause() external onlyRole(ADMIN_ROLE) { _unpause(); }
}


