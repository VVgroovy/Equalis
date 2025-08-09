// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {RedistributionPool} from "../RedistributionPool.sol";

/// @title AutomationDistributor
/// @notice Minimal Chainlink Automation-compatible adapter wrapper for `RedistributionPool.distribute`.
contract AutomationDistributor is AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    RedistributionPool public immutable pool;
    uint64 public immutable minInterval;
    uint256 public batchSize;
    uint64 public lastRun;

    event Performed(uint64 when, uint256 batchSize);

    constructor(address admin, RedistributionPool pool_, uint64 minInterval_, uint256 batchSize_) {
        pool = pool_;
        minInterval = minInterval_;
        batchSize = batchSize_;
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ADMIN_ROLE, admin);
    }

    function setBatchSize(uint256 newSize) external onlyRole(ADMIN_ROLE) {
        require(newSize > 0, "size=0");
        batchSize = newSize;
    }

    function checkUpkeep(bytes calldata)
        external
        view
        returns (bool upkeepNeeded, bytes memory performData)
    {
        upkeepNeeded = (block.timestamp >= lastRun + minInterval);
        performData = abi.encode(batchSize);
    }

    function performUpkeep(bytes calldata performData) external {
        (uint256 size) = abi.decode(performData, (uint256));
        if (size == 0) size = batchSize;
        pool.distribute(size);
        lastRun = uint64(block.timestamp);
        emit Performed(lastRun, size);
    }
}


