# Auvra Testnet genesis generation

This is a deliberate, explicit genesis workflow. It uses the official BNB Chain genesis-contract tooling at immutable commit `84641812a013eda1593e058aeed4dc116c7746eb` and BSC client source commit `947ba1cb1ef05d4a5f71b738113a3d8b4c16f6b7`. Review both commits before production use.

## Required operator inputs

1. A collision-checked testnet chain ID in the range 1..65535. The current upstream genesis generator writes a `uint16` BSC system chain ID, so the wrapper enforces that bound.
2. At least four independent public validator records in `config/validators.testnet.conf`, format:
   `consensusAddress,feeAddress,bscFeeAddress,votingPower,bLSPublicKeyHex`
3. At least one approved faucet/treasury balance in `config/initial-holders.testnet.csv`, format `address,balance_wei`.
4. A reviewed system-contract protector address.

The files must contain public addresses and BLS public keys only, never private keys. See [validator onboarding](VALIDATOR_ONBOARDING.md).

## Generate

Copy the example input files:
```sh
cp config/validators.testnet.example.conf config/validators.testnet.conf
cp config/initial-holders.testnet.example.csv config/initial-holders.testnet.csv
```

Set approved parameters:
```sh
export AUVRA_TESTNET_CHAIN_ID=<approved-unique-id>
export AUVRA_SYSTEM_ADMIN_ADDRESS=0x<20-byte-address>
./scripts/prepare-testnet-genesis.sh
```

The script validates inputs, checks out the pinned genesis-contract commit, installs the upstream toolchain, generates Auvra-specific validator/system-contract state, runs the upstream recovery command, verifies the chain ID and core predeploys, and writes the genesis plus checksums under `artifacts/auvra-testnet/`.

The generator's `dev` profile is used as a customizable base because the upstream `testnet` profile hardcodes BSC Chapel's chain ID, validator set and protector addresses. The resulting artifact is Auvra-specific, but its economic/governance parameters still require review before public testnet launch.

## Initialize a node

After operators approve the genesis hash and receive the exact release artifact:
```sh
export AUVRA_DATA_DIR=/var/lib/auvra
./scripts/init-node.sh
```

This verifies the genesis SHA-256 before initializing the data directory. Starting the node and configuring validator signing are separate, operator-specific tasks.

## Important

Genesis generation is not a live network. Do not initialize nodes until the genesis hash is independently reproduced and the matching pinned BSC client binary is built. Validator keys, peer addresses, server inventory, RPC hostnames, firewall rules and operator agreements are separate deployment requirements.
