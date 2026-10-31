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

## 5. Start a full node with private RPC

```bash
AUVRA_DATA_DIR="$PWD/.local-testnet/node1" ./scripts/start-rpc-node.sh
```

The helper exposes HTTP and WebSocket RPC on loopback only, with only `eth`, `net` and `web3` namespaces. To access it remotely, use a firewall and TLS reverse proxy; do not expose administrative, personal, debug or account-unlock APIs.

Set `AUVRA_RPC_BIND=0.0.0.0` only when you have separately configured network firewalling and a protected TLS ingress. The helper warns when binding to all interfaces.

## Important limitations

- This RPC helper starts a full node; it does not enable validator signing or produce blocks by itself.
- Parlia validator startup requires the node's consensus account, correct validator-set registration, BLS wallet configuration for the client version, and secure key unlocking. The validator startup command must be validated against the exact pinned client before using it.
- Four nodes on one server are a local integration test, not four independent operators.
- The genesis generator still requires real public validator parameters, an admin/protector address and initial allocations. No production or testnet private keys are stored in this repository.
- Do not publish a public RPC endpoint until genesis consistency, peer connectivity, block production, chain ID, rate limits, TLS and monitoring have been verified.
