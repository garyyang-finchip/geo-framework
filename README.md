# geo-framework — ERC-8501 Generative Engine Optimization Framework (GEOF)

**Status: v0.3.1 (2026-11-17). ERC-8501 merged into ethereum/ERCs as a Draft on 2026-11-17 (PR #2176, commit 7214b22); reference registry with 50 Foundry tests, JSON Schemas, validator, vectors, two worked cases; Sepolia evidence run complete (43 transactions, both cases).**

GEOF is a descriptive framework for how generative engines — answer engines, AI search surfaces, agent runtimes with discovery layers — represent an object, how that representation is measured, and how independent parties exchange and verify the measurements. It lets independent parties declare, for the same object or dissemination process, what they observed; and, when a dissemination intent has been declared, how much of it was attained and how much can be attributed to the dissemination.

GEOF assigns no desirability to any value. It defines no thresholds, weights, ranking algorithms, engine policies, anti-abuse rules or licensing mechanics, and it does not say what "good GEO" is.

## Links

- Discussion: https://ethereum-magicians.org/t/erc-8501-generative-engine-optimization-framework/30396
- ERC page: https://eips.ethereum.org/EIPS/eip-8501 (Draft)
- ERC pull request: https://github.com/ethereum/ERCs/pull/2176 (merged 2026-11-17)

## What it defines

- **Eight record types**, content-addressed (JCS + keccak256): Object, Frame, Source, Method, Intent, Metric Definition, Observation, Profile.
- **Process**: a bounded observation container with versioned closure — the opener freezes a version, anyone commits observations and publishes profiles, late material goes into addenda.
- **Five value states**: `ABSENT`, `UNOBSERVED`, `NOT_APPLICABLE`, `UNDETERMINABLE`, or a value. `UNOBSERVED` is never zero.
- **Metric grammar** `geof:<family>/<metric>/vN` over ten families: exposure, presentation, reception, fidelity, seo, access, dynamics, economics, attainment, attribution.
- **A minimal on-chain registry** (`IGEOFRegistry`, ERC-165 + ERC-6372) that records declarations, observation commitments, closures and profile publications — hashes, URIs, attribution and ordering only.

Two applications share the model: **Web GEO** (being cited in AI answers) and **Agentic GEO** (being discovered, invoked and settled by agents).

## Layout

```text
ERCS/erc-8501.md                          ERC draft (ERC-8501)
contracts/GEOFRegistry.sol                reference registry (~7.9 KB runtime)
contracts/interfaces/IGEOFRegistry.sol    interface with NatSpec
test/                                     50 Foundry tests: registry rules, both cases end to end, vectors
script/EvidenceRun.s.sol                  deploys and walks both cases; writes deployments/<network>.json
scripts/evidence-run.sh                   anvil rehearsal / Sepolia driver
scripts/make-filing-package.py            builds + lints ercs-pr-package/ (renumbering, discussions-to)
tools/geof.js                             canonicalize, hash, derive ids, validate records, build vectors
assets/erc-8501/
  contracts/                              byte-identical copies of the two Solidity files (ERC assets)
  schemas/                                JSON Schemas (defs, object, frame, source, method, intent,
                                          metric-definition, observation, profile) + metric vocabulary
  contexts/geof.jsonld                    JSON-LD context
  examples/case-a-web-correction/         wide spread, low fidelity, attainment unknown
  examples/case-b-agentic-skill/          narrow reach, full fidelity, full attainment
  vectors/vectors.json                    subject ids, record hashes, declaration ids, id-derivation examples
ercs-pr-package/                          what goes on the ethereum/ERCs branch (17 files)
deployments/anvil.json                    rehearsal record
docs/                                     concept model, decision log, Magicians post, filing + Sepolia runbooks
```

## Build and test

```bash
forge install foundry-rs/forge-std      # once, after cloning
forge build
forge test                              # 50 tests
scripts/evidence-run.sh anvil           # rehearsal: 43 transactions on a local chain

cd tools && npm ci && cd ..
node tools/geof.js case assets/erc-8501/examples/case-a-web-correction/case.json
node tools/geof.js case assets/erc-8501/examples/case-b-agentic-skill/case.json
node tools/geof.js vectors
python3 -I scripts/make-filing-package.py
```

Solidity 0.8.28, EVM `cancun`, optimizer 200 runs, no via-IR.

## Deployments

| Network | GEOFRegistry | Record |
| --- | --- | --- |
| Sepolia | [`0xe725180476760B4012D8Eb9aD1De3337B5e40478`](https://sepolia.etherscan.io/address/0xe725180476760B4012D8Eb9aD1De3337B5e40478) — 43 txs, blocks 12134766–12134808, both cases | `deployments/sepolia.json`, `docs/sepolia-evidence.md` |

## Relation to adjacent proposals

The ERC text references other frameworks descriptively and requires only ERC-165 and ERC-6372. In this repository the links are named:

| Proposal | Relation |
| --- | --- |
| ERC-8489 Agent Information Flow Paradigm | independent; optional semantic mapping (`aifpModeRef` on an Event's origin). Subject encoding and `UNDETERMINABLE` vocabulary reused. |
| ERC-8444 ARD Onchain | Objects of kind skill / task / agent / registry reference 8444 records through `externalRecords`. |
| ERC-8338 / ERC-8414 | on-chain sources: skill calls are `INVOKED` by a recipient; tender settlements are `TRANSACTED` follow-ups with a deterministic link. |
| ERC-8434 AID / ERC-8419 KYA | observer and publisher credit, applied by consumers; a Profile may be published as an AID facet. |
| ERC-8468 ASF | observers may adopt safety specifications for panel construction. |
| ERC-8471 ADRF / ERC-8436 ACDF | disputes over a `statementId`; collective rulings on contested reference sets. |
| ERC-8490 AMM | an agent's self-maintenance may refresh its own GEO profile. |

## Filing

See `docs/filing-runbook.md`: Magicians post → `discussions-to` → branch `add-erc-geo-framework` cut from `ethereum/ERCs` master → PR "Add ERC: Generative Engine Optimization Framework". Evidence run: `docs/sepolia-runbook.md`.

## Authors and contributors

- **Gary Yang** ([@garyyang-finchip](https://github.com/garyyang-finchip)) - author of the ERC text, the
  framework model and the reference implementation.
- **SG_XiaoMing** ([@SGXiaoMing](https://github.com/SGXiaoMing)) - contributor.

The full list is kept in [`CONTRIBUTORS.md`](CONTRIBUTORS.md).

## License

Text, schemas, examples and contracts: CC0-1.0.
