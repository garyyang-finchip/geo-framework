# Magicians reply — Sepolia evidence (paste-ready)

Post this as a reply on topic 30396 once the repository delta with `deployments/sepolia.json` and `docs/sepolia-evidence.md` is uploaded.

---

**Sepolia evidence run — both worked cases on chain**

The reference `GEOFRegistry` is deployed on Sepolia at `0xe725180476760B4012D8Eb9aD1De3337B5e40478` ([deployment tx](https://sepolia.etherscan.io/tx/0xe51a9684655ef52ccd82ed2c7bf8eadf0eb0d31f70c64a714892f3d06423d0b0), block 12134766). Both worked cases from the draft were walked end to end: 43 transactions across three accounts, blocks 12134766–12134808, all successful.

- **Case A (web correction notice):** two Objects, an Intent and a publisher-side Source declared by the company; Frame, two Sources and four Methods declared by a third-party panel that opens the Process; four `EVENT` batches and one `AGGREGATE` committed by two different accounts; version 1 frozen; two Profiles published against it by the panel and an auditor; an addendum for a late `FOLLOWUP` batch; version 2 frozen; the panel supersedes its own Profile while the auditor's stands. Process `0xc648a9d15bfab71c7ce298a5e4f345f8142d07f5a1098f5ab5a36672a1835ae1`.
- **Case B (agentic skill):** skill Object with a value-registry reference, Intent toward three named agents, Frame with `queries = not-applicable`; discovery `EVENT` and gateway `AGGREGATE` from the provider, settlements as a `FOLLOWUP` batch from an independent indexer; version 1 frozen; two Profiles. Process `0x80277a1a8b0a74daa3d0682fd2f4744993aaddcca2435a187c387491fe330af4`.

Reads at block 12134808 confirm the model's guarantees: a frozen version's commitment count and evidence root do not change when an addendum is opened; a Profile binds to a frozen version only; `supersedes` resolves to the same publisher's earlier Profile; ERC-6372 `mode=timestamp`.

Full record (every tx hash, gas, ids, state snapshot, `cast` commands to reproduce the reads): `deployments/sepolia.json` and `docs/sepolia-evidence.md` in the repository. One operational note for implementers: Sepolia charged 1x–10x the gas of the same transactions on a local chain, so the evidence driver skips simulation and takes limits from live estimation.
