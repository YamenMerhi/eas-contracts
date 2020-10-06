// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

/// @title EAS - Ethereum Attestation Service
contract EAS {
    string constant public VERSION = "0.1";

    bytes32 constant private EMPTY_UUID = bytes32(0x0);
    string constant private HASH_SEPARATOR = "@";

    // A data struct representing a single attestation.
    struct Attestation {
        bytes32 uuid;
        uint32 aio;
        address from;
        uint256 time;
        uint256 expirationTime;
        uint256 revocationTime;
        string data;
    }

    // A data struct representing attestations to a specific AIO (by their UIIDs).
    struct AttestationIdentityObject {
        // A list of attestations IDs, belonging to this AIO.
        bytes32[] attestationUIIDs;
    }

    // A mapping between an account, its AIOs and their respective attestations.
    mapping (address => mapping (uint32 => AttestationIdentityObject)) private attestations;

    // A global mapping between attestations and their UUIDs.
    mapping (bytes32 => Attestation) private db;

    // A global counter for the total number of attestations.
    uint256 public attestationsCount;

    /// @dev Triggered when an attestation has been made.
    ///
    /// @param _attester The attesting account.
    /// @param _aio The ID of the AIO.
    /// @param _uuid The UUID the revoked attestation.
    event Attested(address indexed _attester, uint32 indexed _aio, bytes32 indexed _uuid);

    /// @dev Triggered when an attestation has been revoked.
    ///
    /// @param _attester The attesting account.
    /// @param _aio The ID of the AIO.
    /// @param _uuid The UUID the revoked attestation.
    event Revoked(address indexed _attester, uint32 indexed _aio, bytes32 indexed _uuid);

    /// @dev Attests to a specific AIO.
    ///
    /// @param _recipient The recipient the attestation.
    /// @param _aio The ID of the AIO.
    /// @param _expirationTime The expiration time of the attestation.
    /// @param _data The additional attestation data.
    function attest(address _recipient, uint32 _aio, uint256 _expirationTime, string calldata _data) public {
        AttestationIdentityObject storage aio = attestations[_recipient][_aio];

        require(_recipient != msg.sender, "ERR_INVALID_ATTESTER");
        require(_expirationTime > block.timestamp, "ERR_INVALID_EXPIRATION_TIME");

        Attestation memory attestation = Attestation({
            uuid: EMPTY_UUID,
            aio: _aio,
            from: msg.sender,
            time: block.timestamp,
            expirationTime: _expirationTime,
            revocationTime: 0,
            data: _data
        });

        bytes32 uuid = getUUID(attestation);
        attestation.uuid = uuid;

        aio.attestationUIIDs.push(uuid);

        db[uuid] = attestation;
        attestationsCount++;

        emit Attested(msg.sender, _aio, uuid);
    }

    /// @dev Revokes an existing attestation to a specific AIO.
    ///
    /// @param _uuid The UUID of the attestation to revoke.
    function revoke(bytes32 _uuid) public {
        Attestation storage attestation = db[_uuid];
        require(attestation.uuid != EMPTY_UUID, "ERR_NO_ATTESTATION");

        attestation.revocationTime = block.timestamp;

        emit Revoked(msg.sender, attestation.aio, EMPTY_UUID);
    }

    /// @dev Returns an existing attestation by UUID.
    ///
    /// @param _uuid The UUID of the attestation to retrieve.
    ///
    /// @return The attestation data members.
    function getAttestation(bytes32 _uuid) public view returns (uint32, address, uint256, uint256, uint256, string memory) {
        Attestation memory attestation = db[_uuid];

        return (
            attestation.aio,
            attestation.from,
            attestation.time,
            attestation.expirationTime,
            attestation.revocationTime,
            attestation.data
        );
    }

    /// @dev Calculates a UUID for a given attestation.
    ///
    /// @param _attestation The input attestation.
    function getUUID(Attestation memory _attestation) private view returns (bytes32) {
        return keccak256(abi.encodePacked(
            _attestation.aio, HASH_SEPARATOR,
            _attestation.from, HASH_SEPARATOR,
            _attestation.time, HASH_SEPARATOR,
            _attestation.expirationTime, HASH_SEPARATOR,
            _attestation.data, HASH_SEPARATOR,
            attestationsCount, HASH_SEPARATOR
        ));
    }
}