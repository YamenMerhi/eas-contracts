// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "../EAS.sol";

contract TestEAS is EAS {
    bytes32 private _lastUUID;

    constructor(IAORegistry aoRegistry, IEIP712Verifier eip712Verifier) EAS(aoRegistry, eip712Verifier) {}

    function getLastUUID() external view returns (bytes32) {
        return _lastUUID;
    }

    function attest(
        address recipient,
        uint256 ao,
        uint256 expirationTime,
        bytes32 refUUID,
        bytes calldata data
    ) public payable override returns (bytes32) {
        _lastUUID = super.attest(recipient, ao, expirationTime, refUUID, data);

        return _lastUUID;
    }

    function attestByDelegation(
        address recipient,
        uint256 ao,
        uint256 expirationTime,
        bytes32 refUUID,
        bytes calldata data,
        address attester,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable override returns (bytes32) {
        _lastUUID = super.attestByDelegation(recipient, ao, expirationTime, refUUID, data, attester, v, r, s);

        return _lastUUID;
    }
}
