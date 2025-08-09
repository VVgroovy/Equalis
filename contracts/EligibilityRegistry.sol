// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/// @title EligibilityRegistry
/// @notice Maintains identity bindings and eligibility to receive redistribution.
///         Stores only pseudonymous identifiers (identityId) to avoid PII on-chain.
contract EligibilityRegistry is AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant ATTESTER_ROLE = keccak256("ATTESTER_ROLE");
    address public verifier; // optional zk verifier contract

    // address -> identityId (e.g., keccak256 hash of a verifiable credential DID subject)
    mapping(address => bytes32) private _addressToIdentityId;

    // Track addresses currently eligible to receive redistribution
    EnumerableSet.AddressSet private _eligible;

    event IdentityRegistered(address indexed subject, bytes32 indexed identityId);
    event EligibilityGranted(address indexed subject, bytes32 indexed identityId);
    event EligibilityRevoked(address indexed subject, bytes32 indexed identityId);
    event VerifierSet(address indexed verifier);

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ADMIN_ROLE, admin);
    }

    /// @notice Registers or updates the identityId associated with an address.
    /// @dev Only trusted attesters can bind identityIds to addresses.
    function registerIdentity(address subject, bytes32 identityId) external onlyRole(ATTESTER_ROLE) {
        require(subject != address(0), "subject=0");
        require(identityId != bytes32(0), "identityId=0");
        _addressToIdentityId[subject] = identityId;
        emit IdentityRegistered(subject, identityId);
    }

    function getIdentityId(address subject) external view returns (bytes32) {
        return _addressToIdentityId[subject];
    }
    /// @notice Optionally set a ZK verifier contract that validates age/uniqueness proofs.
    function setVerifier(address newVerifier) external onlyRole(ADMIN_ROLE) {
        verifier = newVerifier;
        emit VerifierSet(newVerifier);
    }

    /// @notice Registers identity using an off-chain ZK proof verified by `verifier`.
    /// @dev If a verifier is set, it must return true for the provided `data` (opaque bytes).
    function registerIdentityWithProof(address subject, bytes32 identityId, bytes calldata data) external {
        require(verifier != address(0), "verifier unset");
        (bool ok, bytes memory res) = verifier.staticcall(abi.encodeWithSignature("verify(bytes)", data));
        require(ok && res.length == 32 && abi.decode(res, (bool)), "invalid proof");
        _addressToIdentityId[subject] = identityId;
        emit IdentityRegistered(subject, identityId);
    }


    function isEligible(address subject) external view returns (bool) {
        return _eligible.contains(subject);
    }

    function eligibleCount() external view returns (uint256) {
        return _eligible.length();
    }

    function eligibleAtIndex(uint256 index) external view returns (address) {
        return _eligible.at(index);
    }

    /// @notice Grants eligibility to a single address after ensuring it has an identityId.
    function grantEligibility(address subject) public onlyRole(ATTESTER_ROLE) {
        bytes32 identityId = _addressToIdentityId[subject];
        require(identityId != bytes32(0), "identity not set");
        bool added = _eligible.add(subject);
        require(added, "already eligible");
        emit EligibilityGranted(subject, identityId);
    }

    function grantEligibilityBatch(address[] calldata subjects) external onlyRole(ATTESTER_ROLE) {
        for (uint256 i = 0; i < subjects.length; i++) {
            // Will revert if invalid; keeps state consistent
            grantEligibility(subjects[i]);
        }
    }

    function revokeEligibility(address subject) external onlyRole(ATTESTER_ROLE) {
        bytes32 identityId = _addressToIdentityId[subject];
        require(identityId != bytes32(0), "identity not set");
        bool removed = _eligible.remove(subject);
        require(removed, "not eligible");
        emit EligibilityRevoked(subject, identityId);
    }

    /// @notice Admin can add or remove attesters.
    function setAttester(address attester, bool isAttester) external onlyRole(ADMIN_ROLE) {
        if (isAttester) {
            _grantRole(ATTESTER_ROLE, attester);
        } else {
            _revokeRole(ATTESTER_ROLE, attester);
        }
    }
}


