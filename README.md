# geo-framework — Generative Engine Optimization Framework (GEOF)

**Status: skeleton v0.1 (2026-11-14). Architecture frozen; ERC text, interface, schemas and worked cases drafted. Reference contract, tests, validator and test-network evidence follow.**

GEOF is a descriptive framework for how generative engines — answer engines, AI search surfaces, agent runtimes with discovery layers — represent an object, how that representation is measured, and how independent parties exchange and verify the measurements. It lets independent parties declare, for the same object or dissemination process, what they observed; and, when a dissemination intent has been declared, how much of it was attained and how much can be attributed to the dissemination.

GEOF assigns no desirability to any value. It defines no thresholds, weights, ranking algorithms, engine policies, anti-abuse rules or licensing mechanics, and it does not say what "good GEO" is.

## What it defines

- **Eight record types**, content-addressed (JCS + keccak256): Object, Frame, Source, Method, Intent, Metric Definition, Observation, Profile.
- **Process**: a bounded observation container with versioned closure — the opener freezes a version, anyone commits observations and publishes profiles, late material goes into addenda.
- **Five value states**: `ABSENT`, `UNOBSERVED`, `NOT_APPLICABLE`, `UNDETERMINABLE`, or a value. `UNOBSERVED` is never zero.
- **Metric grammar** `geof:<family>/<metric>/vN` over ten families: exposure, presentation, reception, fidelity, seo, access, dynamics, economics, attainment, attribution.
- **A minimal on-chain registry** (`IGEOFRegistry`, ERC-165 + ERC-6372) that records declarations, observation commitments, closures and profile publications — hashes, URIs, attribution and ordering only.

Two applications share the model: **Web GEO** (being cited in AI answers) and **Agentic GEO** (being discovered, invoked and settled by agents).

## Layout

```text
ERCS/erc-9999.md                         ERC draft (placeholder number)
assets/erc-9999/
  contracts/interfaces/IGEOFRegistry.sol  registry interface with NatSpec
  schemas/                                JSON Schemas: defs, object, frame, source, method,
                                          intent, metric-definition, observation, profile
  schemas/geof-metric-vocabulary.json     informative starter vocabulary (no directions)
  contexts/geof.jsonld                    JSON-LD context
  examples/case-a-web-correction/         wide spread, low fidelity, attainment unknown
  examples/case-b-agentic-skill/          narrow reach, full fidelity, full attainment
docs/concept-model.md                     one-picture summary + the two cases side by side
docs/decision-log.md                      rulings behind the design
```

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

## Roadmap

1. Reference `GEOFRegistry.sol` + Foundry tests walking both cases on chain.
2. Off-chain validator (schemas, canonicalization, the four consistency rules) + test vectors.
3. Test-network deployment with recorded evidence.
4. Ethereum Magicians thread, then the ERC pull request.

## License

Text and assets: CC0-1.0.
