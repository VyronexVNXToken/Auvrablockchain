# Auvra local testnet node setup

This procedure prepares node software and RPC/full-node processes for the Auvra testnet. It does **not** create validator identities, invent genesis allocations, or turn one machine into independent operators.

## Current network parameters

- Network: Auvra Testnet
- Chain ID and network ID: `52101` (`0xcb85`)
- Native currency: AUR, 18 decimals
- Consensus: Parlia PoSA
- Target block interval: 3 seconds (genesis tooling parameter)
- P2P: TCP/UDP 30303
- HTTP RPC: 8545 (loopback by default)
- WebSocket RPC: 8546 (loopback by default)

## 1. Build the pinned client

From the repository root:

```bash
export AUVRA_BSC_COMMIT=947ba1cb1ef05d4a5f71b738113a3d8b4c16f6b7
./scripts/bootstrap-upstream.sh
```

The script builds the BSC-derived `geth` binary under `.build/bsc/build/bin/geth`.

## 2. Generate test-only validator identities

For an experimental single-host testnet, create four separate node data directories and generate three distinct ECDSA accounts (consensus signer, fee recipient and BSC fee recipient) plus one BLS account for each node. Use the pinned Auvra BSC-derived client:

```bash
for n in 1 2 3 4; do
  mkdir -p ".local-testnet/node$n"
  for role in consensus fee bscfee; do
    .build/bsc/build/bin/geth account new --datadir ".local-testnet/node$n"
  done
  .build/bsc/build/bin/geth bls account new --datadir ".local-testnet/node$n"
  .build/bsc/build/bin/geth bls account list --datadir ".local-testnet/node$n"
done
```

These commands are interactive. Use unique strong passwords and store them outside the repository. Do not enable `--show-private-key`, paste secrets into chat, or commit keystores/password files. Record only the public EVM addresses and 48-byte BLS public keys in the six-column validator input file. The four local identities are suitable only for isolated development; they do not count as independent production operators.

## 3. Prepare the genesis inputs

Create `config/validators.testnet.conf` from the example using the required six-column format:

```text
operatorId,consensusAddress,feeAddress,bscFeeAddress,votingPower,blsPublicKeyHex
```

Use unique public addresses and BLS public keys. Prepare `config/initial-holders.testnet.csv` with test-only faucet allocations in wei. Set `AUVRA_SYSTEM_ADMIN_ADDRESS` to a dedicated testnet protector address that you control and have reviewed.

Then generate and verify the genesis:

```bash
AUVRA_SYSTEM_ADMIN_ADDRESS=0xYOUR_TESTNET_ADMIN_ADDRESS \
  ./scripts/prepare-testnet-genesis.sh
```

The script refuses to proceed without validator inputs, an admin address and initial holder allocations. Review the generated genesis and checksum before initializing any node. The same genesis file and SHA-256 must be used by every node.

## 4. Initialize each node

```bash
for n in 1 2 3 4; do
  AUVRA_DATA_DIR="$PWD/.local-testnet/node$n" ./scripts/init-node.sh
done
```

Each node gets its own persistent data directory. Back up the generated keystores securely.

## 5. Start a validator node

Once the genesis validator set includes the address, a discovery bootnode is reachable, and the node has been initialized, start a validator using its own consensus account password file:

```bash
AUVRA_DATA_DIR="$PWD/.local-testnet/node1" \\
AUVRA_VALIDATOR_ADDRESS=0xYOUR_NODE1_CONSENSUS_ADDRESS \\
AUVRA_PASSWORD_FILE=/secure/path/node1-account-password.txt \\
AUVRA_BOOTNODES='enode://BOOTNODE_PUBLIC_KEY@BOOTNODE_HOST:30303' \\
  ./scripts/start-validator-node.sh
```

Repeat with each validator's own data directory, consensus address, password file and P2P port. Keep password files outside the repository with restrictive permissions. The launcher enables Parlia sealing with `--mine`, `--unlock` and `--miner.etherbase`; it does not expose HTTP or WebSocket RPC. An optional `AUVRA_BLS_PASSWORD_FILE` is passed to the client for BLS voting / fast-finality wallet access. The discovery bootnode must be provisioned separately and its actual enode URL supplied; do not use a placeholder URL.

## 6. Start a separate full node with private RPC

Create and initialize a separate RPC data directory using the same approved genesis:

```bash
mkdir -p .local-testnet/rpc1
AUVRA_DATA_DIR="$PWD/.local-testnet/rpc1" ./scripts/init-node.sh
AUVRA_DATA_DIR="$PWD/.local-testnet/rpc1" ./scripts/start-rpc-node.sh
```

The helper exposes HTTP and WebSocket RPC on loopback only, with only `eth`, `net` and `web3` namespaces. To access it remotely, use a firewall and TLS reverse proxy; do not expose administrative, personal, debug or account-unlock APIs.

Set `AUVRA_RPC_BIND=0.0.0.0` only when you have separately configured network firewalling and a protected TLS ingress. The helper warns when binding to all interfaces.

## Important limitations

- The RPC helper starts a full node; it does not enable validator signing or produce blocks by itself.
- The validator launcher uses the pinned client's documented `--mine`, `--unlock`, `--miner.etherbase`, `--password` and `--bootnodes` options. It has not yet been exercised against a generated Auvra genesis in this environment.
- Parlia validator startup requires the node's consensus account, correct validator-set registration, BLS wallet configuration for the client version, and secure key unlocking. The validator startup command must be validated against the exact pinned client before using it.
- Four nodes on one server are a local integration test, not four independent operators.
- The genesis generator still requires real public validator parameters, an admin/protector address and initial allocations. No production or testnet private keys are stored in this repository.
- Do not publish a public RPC endpoint until genesis consistency, peer connectivity, block production, chain ID, rate limits, TLS and monitoring have been verified.
