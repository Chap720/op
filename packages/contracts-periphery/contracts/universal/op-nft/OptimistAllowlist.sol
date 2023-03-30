// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { Semver } from "@eth-optimism/contracts-bedrock/contracts/universal/Semver.sol";
import { AttestationStation } from "./AttestationStation.sol";
import { OptimistInviter } from "./OptimistInviter.sol";

/**
 * @title  OptimistAllowlist
 * @notice Source of truth for whether an address is able to mint an Optimist NFT.
           isAllowedToMint function checks various signals to return boolean value for whether an
           address is eligible or not.
 */
contract OptimistAllowlist is Semver {
    /**
     * @notice Attestation key used by the AllowlistAttestor to manually add addresses to the
     *         allowlist.
     */
    bytes32 public constant OPTIMIST_CAN_MINT_ATTESTATION_KEY = bytes32("optimist.can-mint");

    /**
     * @notice Attestation key used by Coinbase to issue attestations for Quest participants.
     */
    bytes32 public constant COINBASE_QUEST_ELIGIBLE_ATTESTATION_KEY =
        bytes32("coinbase.quest-eligible");

    /**
     * @notice Attestation key the OptimistInviter needs to issue to allow an address to mint.
     */
    bytes32 public constant OPTIMIST_CAN_MINT_FROM_INVITE_ATTESTATION_KEY =
        bytes32("optimist.can-mint-from-invite");

    /**
     * @notice Address of the AttestationStation contract.
     */
    AttestationStation public immutable ATTESTATION_STATION;

    /**
     * @notice Attestor that issues 'optimist.can-mint' attestations.
     */
    address public immutable ALLOWLIST_ATTESTOR;

    /**
     * @notice Attestor that issues 'coinbase.quest-eligible' attestations.
     */
    address public immutable COINBASE_QUEST_ATTESTOR;

    /**
     * @notice Address of OptimistInviter contract that issues 'optimist.can-mint-from-invite'
     *         attestations.
     */
    address public immutable OPTIMIST_INVITER;

    /**
     * @custom:semver 1.0.0
     * @param _attestationStation    Address of the AttestationStation contract.
     * @param _allowlistAttestor     Address of the allowlist attestor.
     * @param _coinbaseQuestAttestor Address of the Coinbase Quest attestor.
     * @param _optimistInviter       Address of the OptimistInviter contract.
     */
    constructor(
        AttestationStation _attestationStation,
        address _allowlistAttestor,
        address _coinbaseQuestAttestor,
        address _optimistInviter
    ) Semver(1, 0, 0) {
        ATTESTATION_STATION = _attestationStation;
        ALLOWLIST_ATTESTOR = _allowlistAttestor;
        COINBASE_QUEST_ATTESTOR = _coinbaseQuestAttestor;
        OPTIMIST_INVITER = _optimistInviter;
    }

    /**
     * @notice Checks whether an address has an optimist.can-mint attestation from the allowlist attestor.
     *
     * @return Whether or not the address has a optimist.can-mint attestation from the allowlist .
     */
    function _hasAttestationFromAllowlistAttestor(address _recipient) internal view returns (bool) {
        // Expected attestation value is bytes32("true"), but we consider any non-zero value
        // to be truthy.
        return
            ATTESTATION_STATION
                .attestations(ALLOWLIST_ATTESTOR, _recipient, OPTIMIST_CAN_MINT_ATTESTATION_KEY)
                .length > 0;
    }

    /**
     * @notice Checks whether an address has the correct attestation from the Coinbase.
     *
     * @return Whether or not the address has a optimist.can-mint attestation from the allowlist.
     */
    function _hasAttestationFromCoinbaseQuestAttestor(address _recipient)
        internal
        view
        returns (bool)
    {
        // Expected attestation value is bytes32("true"), but we consider any non-zero value
        // to be truthy.
        return
            ATTESTATION_STATION
                .attestations(
                    COINBASE_QUEST_ATTESTOR,
                    _recipient,
                    COINBASE_QUEST_ELIGIBLE_ATTESTATION_KEY
                )
                .length > 0;
    }

    function _hasAttestationFromOptimistInviter(address _recipient) internal view returns (bool) {
        // Expected attestation value is the inviter's address, but we just check that it's set.
        return
            ATTESTATION_STATION
                .attestations(
                    OPTIMIST_INVITER,
                    _recipient,
                    OPTIMIST_CAN_MINT_FROM_INVITE_ATTESTATION_KEY
                )
                .length > 0;
    }

    /**
     * @notice Checks whether a given address is allowed to mint the Optimist NFT yet. Since the
     *         Optimist NFT will also be used as part of the Citizens House, mints are currently
     *         restricted. Eventually anyone will be able to mint.
     *
     * @return Whether or not the address is allowed to mint yet.
     */
    function isAllowedToMint(address _recipient) public view returns (bool) {
        return
            _hasAttestationFromAllowlistAttestor(_recipient) ||
            _hasAttestationFromCoinbaseQuestAttestor(_recipient) ||
            _hasAttestationFromOptimistInviter(_recipient);
    }
}