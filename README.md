# Auvra Blockchain

**Auvra (AUR)** is being engineered as an independent EVM-compatible Layer 1 using the BNB Chain BSC client and Parlia Proof-of-Staked-Authority consensus.

**Launch sequence: public Testnet first, then Mainnet.**

> **Current status: engineering scaffold.** This repository is not yet a live blockchain network. No Auvra genesis has been generated or approved, no validator cluster is running, and no public RPC endpoint is deployed. Do not advertise Auvra as a live network until the launch gates in `docs/NETWORK_PLAN.md` are met.

## Approved parameters

| Parameter | Value |
|---|---|
| Network | Auvra |
| Native coin | Auvra |
| Symbol | AUR |
| Decimals | 18 |
| Execution | EVM |
| Consensus | Parlia PoSA |
| Rollout | Testnet, then Mainnet |
| Client foundation | BNB Chain BSC |

Chain IDs, validator set, allocations, block parameters and bootnodes remain to be approved. These are consensus-critical settings; this project will not silently guess them.

## Repository contents

- `config/auvra-network.json` — approved identity and pending network parameters.
- `scripts/validate-network.py` — validates network configuration and launch prerequisites.
- `scripts/bootstrap-upstream.sh` — obtains and builds a pinned BSC client release.
- `scripts/prepare-genesis-tooling.sh` — checks out the official BSC genesis-contract tooling.
- `Dockerfile` — reproducible BSC client source build.
- `docs/NETWORK_PLAN.md` — genesis, testnet and mainnet procedures.
- `docs/OPERATIONS.md` — validator and RPC security baseline.
- `docs/VALIDATOR_ONBOARDING.md` — safe consensus/BLS key onboarding for each operator.
- `docs/TESTNET_GENESIS.md` — explicit Auvra testnet genesis generation and node initialization.

## Build the client

Requires Linux, Git, Go 1.25+, GCC and Make.

```bash
export BSC_VERSION=v1.8.1
./scripts/bootstrap-upstream.sh
```

Or build a container:

```bash
docker build --build-arg BSC_VERSION=v1.8.1 -t auvra/bsc-client:v1.8.1 .
```

The upstream client source documents `make geth` and the Go/C compiler requirements. The binary is a BSC-derived client; it is not by itself an initialized Auvra chain.

## Prepare genesis tooling

```bash
./scripts/prepare-genesis-tooling.sh
```

The official BNB Chain genesis-contract project provides the Parlia-related system contracts and scripts for generating genesis. Its documented process configures initial holders, validators and system contract settings before running genesis generation. Auvra must customize and review those settings; never reuse BSC mainnet/testnet genesis, allocations, validators or keys.

## Validate configuration

```bash
make validate
```

The validator intentionally fails the launch-readiness check while chain IDs, validators or an approved generated genesis are missing.

## Security

Never commit validator private keys, keystores, JWT secrets or production environment files. Keep validator nodes separate from public RPC nodes. Restrict RPC namespaces and admin APIs. Use TLS, firewalling, rate limits, monitoring, independent validator operators and tested recovery procedures.

## Upstream references

- [BSC client](https://github.com/bnb-chain/bsc)
- [BSC genesis contracts](https://github.com/bnb-chain/bsc-genesis-contract)
- [BSC node deployment tooling](https://github.com/bnb-chain/node-deploy)
- [BSC documentation](https://docs.bnbchain.org/)
