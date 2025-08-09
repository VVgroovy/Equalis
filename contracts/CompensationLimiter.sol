// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/// @title CompensationLimiter
/// @notice Tracks per-identity compensation and enforces an annual cap.
/// @dev Units are in smallest units of the salary token configured by the caller.
contract CompensationLimiter is AccessControl {
    bytes32 public constant CALLER_ROLE = keccak256("CALLER_ROLE");

    struct PeriodData {
        uint64 periodStart;
        uint256 paidInPeriod;
    }

    // identityId => period data
    mapping(bytes32 => PeriodData) private _periods;

    uint256 public immutable annualCap;
    uint256 public immutable periodLength;

    event Consumed(bytes32 indexed identityId, uint256 allowed, uint256 overflow, uint64 newPeriodStart, uint256 paidInPeriod);

    constructor(address admin, uint256 annualCap_, uint256 periodLength_) {
        require(admin != address(0), "admin=0");
        require(annualCap_ > 0, "cap=0");
        require(periodLength_ >= 30 days && periodLength_ <= 400 days, "period invalid");
        annualCap = annualCap_;
        periodLength = periodLength_;
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    function remainingAllowance(bytes32 identityId) public view returns (uint256 remaining, uint64 periodStart, uint256 paid) {
        PeriodData memory p = _periods[identityId];
        if (p.periodStart == 0) {
            return (annualCap, uint64(block.timestamp), 0);
        }
        if (block.timestamp >= p.periodStart + periodLength) {
            return (annualCap, uint64(block.timestamp), 0);
        }
        if (p.paidInPeriod >= annualCap) {
            return (0, p.periodStart, p.paidInPeriod);
        }
        return (annualCap - p.paidInPeriod, p.periodStart, p.paidInPeriod);
    }

    /// @notice Consumes up to the remaining allowance for an identity; returns (allowed, overflow)
    function consume(bytes32 identityId, uint256 requested) external onlyRole(CALLER_ROLE) returns (uint256 allowed, uint256 overflow) {
        PeriodData memory p = _periods[identityId];
        if (p.periodStart == 0 || block.timestamp >= p.periodStart + periodLength) {
            p.periodStart = uint64(block.timestamp);
            p.paidInPeriod = 0;
        }
        uint256 remaining = annualCap > p.paidInPeriod ? (annualCap - p.paidInPeriod) : 0;
        if (requested <= remaining) {
            allowed = requested;
            overflow = 0;
        } else {
            allowed = remaining;
            overflow = requested - remaining;
        }
        p.paidInPeriod += allowed;
        _periods[identityId] = p;
        emit Consumed(identityId, allowed, overflow, p.periodStart, p.paidInPeriod);
    }
}


