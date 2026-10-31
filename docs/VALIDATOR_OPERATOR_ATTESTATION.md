# Auvra validator operator attestation template

Complete one copy per proposed testnet validator. Keep signed identity/contact details in the project coordinator's restricted records; do not commit completed forms or private contact details to this public repository.

## Operator identity

- Public operator ID:
- Legal person or organization:
- Authorized representative:
- Private contact channel for coordination:
- Country/jurisdiction of operation:
- Related entities or common beneficial/control ownership with another proposed operator:

## Independence declaration

Confirm each statement and explain any exception:

- [ ] I control the validator host and its signing environment.
- [ ] No other proposed validator operator controls this host or its signing keys.
- [ ] My consensus and BLS private keys are generated and stored under my exclusive operational control.
- [ ] My validator does not share a single point of failure with another proposed operator (host, cloud account, credentials, network path or administrator).
- [ ] I will promptly disclose any ownership, control, infrastructure or key-custody change.
- [ ] I understand that a distinct operator ID or distinct public keys do not, by themselves, establish independence.

## Public validator parameters

- Consensus address:
- Fee recipient address:
- BSC fee recipient address:
- BLS public key (48-byte hex):
- Proposed genesis voting power:
- Validator host/provider and region (do not include IP addresses in this public repository):
- Monitoring and incident contact method:

## Key-ownership verification

The coordinator must define and publish a chain-specific challenge procedure before collecting signatures. Record the verification outcome, challenge identifier, verifier and timestamp in the restricted operator register.

- Consensus-key challenge: pending / passed / failed
- BLS-key proof-of-possession: pending / passed / failed
- Verification procedure/version:
- Challenge ID:
- Verifier:
- Verification timestamp (UTC):

Never submit a private key, seed phrase, keystore file or keystore password. A screenshot or self-assertion is not cryptographic proof of key possession.

## Operational commitment

- Expected availability and maintenance notice:
- Backup and disaster-recovery plan:
- Security contact and incident response commitment:
- Agreement to the published validator reward, penalty, upgrade and emergency procedures:

## Approval

- Operator representative:
- Date (UTC):
- Coordinator review:
- Independence review:
- Final status: pending / approved / rejected

Approval of an operator does not imply approval of the final genesis or launch. All operators must independently verify the final genesis hash and client release before starting a validator.
