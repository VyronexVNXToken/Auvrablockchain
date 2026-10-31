# Auvra Testnet validator onboarding

This guide is for each independent validator operator. Never send private keys to the Auvra project owner, GitHub, a chat, CI, or another validator operator.

## 1. Prepare a dedicated validator host

Use a hardened Linux host with persistent SSD storage, synchronized time, firewalling and monitoring. Each validator should be operated by a distinct trusted party where possible. Do not colocate public RPC services with the validator process.

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
- The BLS account list output provides the BLS vote/public address needed for the validator record.
- Keep both keystore/private-key materials on the operator's host, encrypted and backed up securely.
- The validator configuration requires public data only: consensus address, fee recipient, BSC fee recipient, voting power and BLS public key.
- Do not publish or share private keys, keystore JSON files or passwords.

The official BNB Chain validator documentation describes the separate consensus account and BLS account workflow. Auvra uses its own chain ID for any Auvra-specific proof or signature operation; do not use BSC mainnet/testnet chain IDs.

## 3. Submit public validator details

Each operator submits only:
- consensus address (20-byte EVM address)
- fee recipient address (20-byte EVM address)
- BSC fee recipient address (20-byte EVM address)
- agreed genesis voting power (positive integer)
- BLS public key (48-byte hex value)

The network coordinator checks duplicates, confirms key ownership out-of-band, and obtains operator consent before including the record in the genesis. Genesis voting power and validator rewards must be agreed transparently.

## 4. Genesis agreement

All operators independently verify:
- Auvra testnet chain ID
- genesis JSON SHA-256 and genesis block hash
- exact client source commit and binary checksum
- validator set and initial allocations
- peer/bootnode addresses and upgrade procedure

Never initialize nodes from a genesis artifact whose checksum differs from the approved release.

## 5. Run and monitor

Initialize the node using the repository's `scripts/init-node.sh`. Configure P2P peer connectivity and validator signing through the reviewed upstream client procedure. Keep RPC admin/debug APIs private. Monitor missed blocks, peer count, disk, process health and clock drift.

## References

- [BNB Chain validator creation guide](https://docs.bnbchain.org/bc-fusion/validators/creation/)
- [BNB Chain validator key management](https://docs.bnbchain.org/bc-fusion/validators/key-management/)
- [Parlia consensus overview](https://github.com/bnb-chain/bsc#proof-of-staked-authority)
