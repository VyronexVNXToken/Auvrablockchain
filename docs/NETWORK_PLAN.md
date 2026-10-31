# Auvra network plan

## Approved identity
- Network: Auvra
- Native coin: Auvra (AUR), 18 decimals
- EVM execution; Parlia PoSA consensus
- Testnet before Mainnet

## Genesis is not a generic Geth genesis
Parlia depends on BSC client logic and network-specific system contract state. Do not substitute Clique, a generic single-validator dev chain, or BSC's existing genesis. Genesis must be generated for Auvra using the system-contract tooling compatible with the exact pinned client release.

## Upstream genesis procedure
The official BNB Chain genesis-contract repository documents the process: install Node dependencies, Foundry and Poetry; configure initial holders in init_holders.js, initial validators in validators.js, adjust system contract settings, and run the genesis generator. It provides separate testnet/dev generation commands. Auvra must maintain its own reviewed configuration and generated artifact.

Repository: https://github.com/bnb-chain/bsc-genesis-contract

## Testnet decisions required
1. Use the proposed Auvra Testnet chain ID `52101` (`0xcb85`) and Mainnet chain ID `52100` (`0xcb84`); complete a final registry/collision review before public launch.
2. Select separate validator operators and gather public validator addresses.
3. Decide initial AUR test allocations and faucet policy.
4. Approve block interval, gas limit, epoch/validator rotation and fork schedule.
5. Configure Parlia system contracts, bootnodes, peer network identity and ports.
6. Generate genesis with pinned tooling, validate using the exact client, and independently reproduce its hash.
7. Start multiple independently operated validator nodes; a single-node private dev chain is only a smoke test.
8. Run separate RPC/sentry nodes and verify peer sync, block production, transactions, contract deployment, restart and recovery.
9. Publish RPC only after firewall, TLS, rate limits, monitoring and API allowlists are active.

## Mainnet launch gates
Mainnet uses the selected chain ID `52100` (`0xcb84`) and needs its own genesis and independent validator keys, disclosed AUR allocation and vesting rules, validator reward/fee/governance policy, upgrade and emergency process, independent audits and a sustained public testnet soak period. Never carry testnet balances or signing keys into mainnet.
