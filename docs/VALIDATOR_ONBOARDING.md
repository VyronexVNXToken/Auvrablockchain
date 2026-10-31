# Auvra Testnet validator onboarding

This guide is for each independent validator operator. Never send private keys to the Auvra project owner, GitHub, a chat, CI, or another validator operator.

## 1. Prepare a dedicated validator host

Use a hardened Linux host with persistent SSD storage, synchronized time, firewalling and monitoring. Each validator should be operated by a distinct legal person or organization, with separate infrastructure, credentials and operational control. Do not count multiple nodes controlled by one operator as independent validators. Do not colocate public RPC services with the validator process.

Build the exact Auvra-pinned client from this repository and verify the release checksum before use.

## 2. Create consensus and BLS keys locally

On the validator host, using the Auvra-built `geth` binary:

```sh
export AUVRA_DATA_DIR=/var/lib/auvra
install -d -m 700 "$AUVRA_DATA_DIR"
geth account new --datadir "$AUVRA_DATA_DIR"
geth bls account new --datadir "$AUVRA_DATA_DIR"
geth bls account list --datadir "$AUVRA_DATA_DIR"
```

- The ECDSA account address is the consensus signing address.
- The BLS account list output provides the BLS public key needed for the validator record.
- Keep both keystore/private-key materials on the operator's host, encrypted and backed up securely.
- The validator configuration requires public data only: operator ID, consensus address, fee recipient, BSC fee recipient, voting power and BLS public key.
- Do not publish or share private keys, keystore JSON files or passwords.

The official BNB Chain validator documentation describes the separate consensus account and BLS account workflow. Auvra uses its own chain ID for any Auvra-specific proof or signature operation; do not use BSC mainnet/testnet chain IDs.

## 3. Submit public validator details

Copy `config/validators.testnet.example.conf` to `config/validators.testnet.conf`. Submit one line per operator using exactly this format:

```text
operatorId,consensusAddress,feeAddress,bscFeeAddress,votingPower,blsPublicKeyHex
```

- `operatorId`: stable public label, 2-64 letters/digits/dot/underscore/hyphen characters; it is not proof of independence.
- `consensusAddress`, `feeAddress`, `bscFeeAddress`: distinct 20-byte EVM addresses.
- `votingPower`: positive integer agreed by all operators before genesis.
- `blsPublicKeyHex`: unique 48-byte public key in hex (optional `0x` prefix).

At least four distinct operators are required for the initial public testnet. The input validator rejects repeated operator IDs, any reused address across the three address roles, and duplicate BLS public keys. These mechanical checks cannot prove that operators are genuinely independent.

The network coordinator must separately verify each operator's identity, infrastructure/control separation, consent and proof of possession of the consensus and BLS keys using a reviewed, chain-specific challenge procedure. Do not treat a submitted address or public key alone as proof of key ownership. Record operator approval and agreed voting power outside the public config file.

## 4. Validator-set review

Before genesis generation, circulate the complete proposed validator set to every operator and obtain explicit approval of:
- operator roster and independence declarations
- consensus, fee-recipient and BSC-fee-recipient addresses
- BLS public keys and proof-of-possession verification results
- voting-power weights and validator reward/penalty policy
- validator uptime, maintenance, replacement and emergency procedures

Use equal voting power only if that is the explicit, documented agreement. Do not silently derive voting power from stake or reputation.

## 5. Genesis agreement

All operators independently verify:
- Auvra testnet chain ID
- genesis JSON SHA-256 and genesis block hash
- exact client source commit and binary checksum
- validator set and initial allocations
- peer/bootnode addresses and upgrade procedure

Never initialize nodes from a genesis artifact whose checksum differs from the approved release.

## 6. Run and monitor

Initialize the node using the repository's `scripts/init-node.sh`. Configure peer connectivity and validator signing through the reviewed upstream client procedure. Keep RPC admin/debug APIs private. Monitor missed blocks, peer count, disk, process health and clock drift.

## References

- [BNB Chain validator creation guide](https://docs.bnbchain.org/bc-fusion/validators/creation/)
- [BNB Chain validator key management](https://docs.bnbchain.org/bc-fusion/validators/key-management/)
- [Parlia consensus overview](https://github.com/bnb-chain/bsc#proof-of-staked-authority)
