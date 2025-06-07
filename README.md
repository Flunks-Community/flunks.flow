# Flunks Contracts

This repository contains Cadence smart contracts and scripts for the Flunks NFT collection.

## Deploying

1. Install the [Flow CLI](https://docs.onflow.org/flow-cli/install/).
2. Provide private keys for each account listed in `flow.json` via environment variables (e.g. `FLOW_EMULATOR-ACCOUNT_PRIVATE_KEY`).
3. Deploy the contracts:

```bash
flow deploy --network testnet
```

See `flow.json` for the list of contracts deployed per network.

