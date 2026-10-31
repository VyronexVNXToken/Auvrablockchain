# Auvra operations and security

## Node roles
- Validator: participates in Parlia consensus; private signing keys remain isolated.
- Sentry/P2P gateway: protects validator nodes from direct public peer exposure where supported.
- RPC node: serves wallet and dApp requests, separated from validators.
- Bootnode: peer discovery only; it is not a validator or consensus authority.

## RPC
Expose only required namespaces (normally eth, net, web3). Keep admin, debug, personal and account-unlock APIs private/disabled. Use TLS, method/IP rate limits, request-size limits, CORS/WS origin allowlists, connection caps and abuse monitoring.

## Key custody
Generate validator keys on trusted hosts. Use encrypted offline backups, least-privilege access, MFA and tested recovery. Never commit keys, keystores, JWT secrets or cloud credentials to Git, CI, images or logs.

## Operations
Use separate Linux hosts/VMs and operators for testnet validators. Monitor block height, missed proposals, peer count, disk, CPU, memory, RPC errors, latency and clock drift. Pin client source and record binary checksums. Test every upgrade on local network and public testnet before coordinating a production upgrade.
