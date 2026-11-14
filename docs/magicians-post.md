# Ethereum Magicians — first post (draft)

**Category:** ERCs
**Title:** Draft ERC: Generative Engine Optimization Framework (GEOF) — attributable declarations, observation commitments and profiles for how generative engines represent objects

---

## Summary

GEOF is a descriptive framework for recording how generative engines — answer engines, AI search surfaces, and agent runtimes with discovery layers — represent an object, how that representation is measured, and how independent parties exchange and verify the measurements.

It lets independent parties declare, for the same object or dissemination process, what they observed; and, when a dissemination intent has been declared, how much of it was attained and how much can be attributed to the dissemination.

It assigns no desirability to any value. No thresholds, weights, ranking algorithms, engine policies, anti-abuse rules or licensing mechanics, and no definition of "good GEO".

Repository: `https://github.com/garyyang-finchip/geo-framework`
ERC pull request: to be added after filing.

## Why

- Generative engines retrieve, select, synthesize and attribute. Classic search metrics (impressions, clicks, position) describe part of that; the metrics that grew up around generative engines (mention rate, citation rate, share of voice, position-adjusted word count) are published under incompatible units and denominators. Two parties holding the same number cannot tell whether they measured the same thing.
- When the recipient is an agent and the engine is an agent runtime, "being cited" becomes "being invoked" and "being settled". These outcomes already leave on-chain traces (skill-token calls, task-tender settlements) but no shared vocabulary links them to the discovery event that caused them.
- The engine operator, the object holder and third-party panels each observe different parts of the same process. None can be the canonical source; their statements must coexist, each attributable and each bound to the frame, sources and methods it used.
- The same dissemination is a success under one intent and a failure under another. Statements about attainment or contribution are only meaningful relative to a declared intent, and must stay separate from statements about what was observed.

## What it defines

**Eight content-addressed record types** (JCS canonicalization + keccak256): Object, Frame, Source, Method, Intent, Metric Definition, Observation, Profile.

**Process**: an observation container bound to one Frame, one or more Objects, zero or more Intents, and the Sources and Methods the opener announces. Any account commits observation batches (Merkle root + count, attributable to the sender) and publishes Profiles; only the opener freezes a version or opens an addendum. Profiles bind to a frozen version. Nothing designates an official profile.

**Five value states**: `ABSENT` (checked, none), `UNOBSERVED` (no material), `NOT_APPLICABLE`, `UNDETERMINABLE` (material, but the declared method reached no determination), or a value. `UNOBSERVED` is never zero.

**Metric grammar** `geof:<family>/<metric>/vN` (extensions `geof:x/<publisher>/<metric>/vN`) over ten families: exposure, presentation, reception, fidelity, seo, access, dynamics, economics, attainment, attribution. A metric definition fixes statistical unit, numerator, denominator, eligibility, de-duplication and aggregation, and carries no preferred direction. Every statement carries its frame, sources, method, counts, coverage, uncertainty and a human-readable rationale.

**Three rules that keep the statements honest**

1. Fidelity statements must name a reference set, a comparator and the proposition checked. "Did it happen", "was it relayed faithfully", "are the source's claims supported" and "was the purpose achieved" are four questions with four answers.
2. Attainment and attribution statements must reference an Intent. Base observation stands without one; claims of effectiveness do not.
3. Representation ends at `INVOKED` (with the actor named: engine or recipient). A purchase, a settled task or a payment is a follow-up observation with a stated link basis, never something the engine "did".

**A minimal registry** (`IGEOFRegistry`, ERC-165 + ERC-6372): `declare`, `declareObject`, `openProcess`, `commitObservations`, `closeProcess`, `openAddendum`, `publishProfile`, plus views. Hashes, URIs, attribution and ordering only.

## Two worked cases, one framework

| | Case A — web correction notice | Case B — agentic skill |
| --- | --- | --- |
| Intent | public searchers should understand condition Z | three named agents should invoke and settle |
| Exposure | answer-inclusion 0.74 (1066/1440) | public retrieval 0.042 (9/212); targeted reach 3/3 |
| Fidelity | key proposition present in 0.23 of mentioning answers | descriptor hash match 11/11 |
| Attainment | `UNOBSERVED` — no recipient evidence | 1.0 for `invoked`, 1.0 for `acted` |
| Attribution | not stated | `UNDETERMINABLE`, basis `declared` |
| Reading | wide, unfaithful, effect unknown | narrow, faithful, attained, contribution unproven |

Neither case gets a score. Both are walked on chain in the reference tests, and the record bundles and derived vectors are in the repository.

## Relation to adjacent work

Independent of, and mappable to, an information-flow paradigm registry (ERC-8489): a GEO process may span several information flows, and a monthly platform report supports a profile without any single flow being visible. Objects of kind skill / task / agent / registry reference records in an on-chain value registry (ERC-8444). Skill calls (ERC-8338) and task-tender settlements (ERC-8414) are on-chain sources for invocation and follow-up statements. Identity and credit (ERC-8434, ERC-8419), safety adoption (ERC-8468) and dispute resolution (ERC-8471) consume profiles through their own interfaces. The ERC text requires only ERC-165 and ERC-6372.

## Status and asks

- Reference registry with 50 Foundry tests (both cases end to end), JSON Schemas, validator, vectors. Test-network evidence run next.
- Looking for review on: (1) the five-state value vocabulary; (2) opener-only closure with open commitment — is a per-observer closure needed in the kernel, or is "open your own process on the same frame" enough; (3) whether `UNDETERMINABLE` should be allowed as a statement value outside the fidelity, attainment and attribution families; (4) the metric identifier grammar's publisher namespace.
