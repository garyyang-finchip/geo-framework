# Sepolia evidence run

`script/EvidenceRun.s.sol` deploys `GEOFRegistry` and walks case A and case B on chain, using the record hashes from `assets/erc-9999/vectors/vectors.json`. It writes `deployments/<network>.json`. The anvil rehearsal (`deployments/anvil.json`) completed with 43 transactions.

## Accounts

| Role | Account | Funding |
| --- | --- | --- |
| A — deployer; panel observer (case A); skill provider (case B) | `DEPLOYER_PK` | 0.05 Sepolia ETH from a faucet |
| B — company (case A); independent indexer (case B) | derived from A inside the script | 0.004 ETH sent by A in the first block |
| C — auditor, second publisher (case A) | derived from A inside the script | 0.001 ETH sent by A |

B and C are deterministic per deployer key (`keccak256(abi.encode(pkA, "geof-evidence-B"))`, same for C), so a re-run with the same deployer reuses them. They are evidence accounts only.

## Run

Preferred: the session that holds the deployer key runs it and reports back. Fallback: any machine with Foundry and an RPC:

```bash
# ~/geof.env
export SEPOLIA_RPC_URL=https://...
export DEPLOYER_PK=0x...
```

```bash
source ~/geof.env
scripts/evidence-run.sh sepolia
```

The driver checks the deployer balance, then runs the script with `--broadcast --skip-simulation`. Skipping simulation matters: Sepolia's current gas schedule costs several times what a local estimate predicts, and the first runs of earlier proposals ran out of gas with simulated limits. Take limits from the live chain.

## What comes back

`deployments/sepolia.json` — registry address, the three accounts, both process ids, declaration ids and profile ids. `broadcast/EvidenceRun.s.sol/11155111/run-latest.json` — every transaction hash. Paste `deployments/sepolia.json` back (and, if convenient, the `transactions[].hash` list from the broadcast file); the README address table, `docs/sepolia-evidence.md` and the Magicians evidence reply are written from those.

## Verification (optional)

```bash
forge verify-contract --chain sepolia --verifier sourcify <registry-address> contracts/GEOFRegistry.sol:GEOFRegistry
```

Sourcify needs no API key. Etherscan verification needs one and can follow later.
