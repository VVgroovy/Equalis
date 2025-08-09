// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {EligibilityRegistry} from "./EligibilityRegistry.sol";
import {CompensationLimiter} from "./CompensationLimiter.sol";
import {RedistributionPool} from "./RedistributionPool.sol";

/// @title RedistributivePayroll
/// @notice Employers fund and pay employees; amounts above the annual cap are redirected to the redistribution pool.
contract RedistributivePayroll is AccessControl, ReentrancyGuard, Pausable {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant EMPLOYER_ROLE = keccak256("EMPLOYER_ROLE");

    IERC20 public immutable token; // salary token (e.g., a stablecoin)
    EligibilityRegistry public immutable registry;
    CompensationLimiter public immutable limiter;
    RedistributionPool public immutable pool;

    event Paid(address indexed employer, address indexed employee, bytes32 indexed identityId, uint256 paid, uint256 overflow);

    constructor(
        address admin,
        IERC20 token_,
        EligibilityRegistry registry_,
        CompensationLimiter limiter_,
        RedistributionPool pool_
    ) {
        require(address(token_) != address(0), "token=0");
        require(address(registry_) != address(0), "registry=0");
        require(address(limiter_) != address(0), "limiter=0");
        require(address(pool_) != address(0), "pool=0");
        token = token_;
        registry = registry_;
        limiter = limiter_;
        pool = pool_;
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ADMIN_ROLE, admin);
    }

    function setEmployer(address employer, bool isEmployer) external onlyRole(ADMIN_ROLE) {
        if (isEmployer) {
            _grantRole(EMPLOYER_ROLE, employer);
        } else {
            _revokeRole(EMPLOYER_ROLE, employer);
        }
    }

    /// @notice Transfers `amount` from employer to this contract, pays employee up to cap remainder, and deposits overflow to pool.
    function fundAndPay(address employee, uint256 amount) external nonReentrant onlyRole(EMPLOYER_ROLE) whenNotPaused {
        require(employee != address(0), "employee=0");
        require(amount > 0, "amount=0");
        bool pulled = token.transferFrom(msg.sender, address(this), amount);
        require(pulled, "pull fail");

        bytes32 identityId = EligibilityRegistry(registry).getIdentityId(employee);
        require(identityId != bytes32(0), "identity missing");

        (bool okConsume, bytes memory data) = address(limiter).call(
            abi.encodeWithSelector(CompensationLimiter.consume.selector, identityId, amount)
        );
        require(okConsume, "limiter fail");
        (uint256 allowed, uint256 overflow) = abi.decode(data, (uint256, uint256));

        if (allowed > 0) {
            bool okPay = token.transfer(employee, allowed);
            require(okPay, "pay fail");
        }

        if (overflow > 0) {
            // Approve and deposit overflow to the pool in a single step
            bool okApprove = token.approve(address(pool), overflow);
            require(okApprove, "approve fail");
            pool.deposit(overflow);
        }

        emit Paid(msg.sender, employee, identityId, allowed, overflow);
    }

    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }
}


