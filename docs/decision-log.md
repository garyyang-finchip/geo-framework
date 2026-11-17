# Decision log

Design rulings that shaped the skeleton, in the order they were settled. Each entry is the ruling as adopted; discussion lives outside the repository.

## Round 1–2 (2026-11-14)

| # | Decision |
| --- | --- |
| 1 | Title **Generative Engine Optimization Framework (GEOF)**; repository `geo-framework`. |
| 2 | Atomic unit = one run or delivery instance. "Query × engine" is a sampling cell of the Frame; repetition is a Frame dimension. One run may touch several Objects. Sources that only reach aggregates register `aggregate` observations; instance events are never fabricated from them. |
| 3 | Object = the subject itself, engine-independent; representation belongs to the Event. `content` and `entity` are distinct kinds related by `carrierOf`. |
| 4 | The kernel is open: any account declares, commits and publishes. Trust is a consumer decision. Object holders need not approve third-party profiles. |
| 5 | Fidelity statements must declare reference set, comparator and proposition. Fidelity splits into occurrence, relay fidelity and claim support. Consensus is its own metric and must state its independence basis. |
| 6 | Trigger (initiator, prior authorization, immediate query) and delivery channel are separate fields; unsolicited delivery is measured as sent / delivered / displayed. An information-flow paradigm registry is referenced by optional semantic mapping, not dependency. |
| 7 | Agentic GEO is in v1 as a parallel application of the same model; `INVOKED` carries `actor` (engine vs recipient). |
| 8 | General rules for metric definitions are normative; classic search metrics are an informative vocabulary in their source platform's units; page conditions (Core Web Vitals, index state) are `condition`-basis metrics. |
| 9 | `economics` is in v1 as ledger facts only: actual spend, actual revenue, allocated amount (by a declared rule), estimated incremental value (by an attribution method). No pricing or settlement rules. |
| 10 | No global minimum aggregation. `observationGranularity` and `disclosureGranularity` are declared separately; a single authorized recipient is a valid audience; the public layer carries aggregates or commitments. |
| 11 | Independent from the information-flow framework; semantic mapping only; `requires` lists only ERC-165 and ERC-6372. |
| 12 | The kernel has `declareObject`; kinds `skill` / `task` / `agent` / `registry` reference existing value-registry records through `externalRecords`. The declaring account is a `declarant`, never a `controller`; control claims carry a `basis` and are verified by consumers. |
| 13 | Metric grammar `geof:<family>/<metric>/vN`, extensions `geof:x/<publisher>/<metric>/vN`. A definition is immutable; any change to unit, numerator, denominator, eligibility, de-duplication or aggregation is a new version. Identifiers name definitions, never readings. |
| 14 | `TRANSACTED` is not a representation kind; it is a follow-up observation with a `linkBasis`. Representation ends at `INVOKED`. |
| 15 | Intent is an optional record bound to a Process, ex-ante or ex-post with provenance. Normative rule: statements in `attainment` and `attribution` must reference an Intent; base observation stands without one. |
| 16 | `coverage` is mandatory on every statement; ratios carry numerator and denominator counts. `attribution` is its own family, always separate from `attainment`. |
| 17 | Round-2 deliverable: concept diagram, two worked cases (wide-but-unfaithful, narrow-but-attained), design memo, English skeleton. |

## Adopted from advisory review

- Three kinds of intent named apart: query intent, intervention, dissemination intent.
- Four fidelity questions kept apart: did it happen; was it relayed faithfully; are the source's claims supported; was the purpose achieved.
- Denominator, evidence coverage and incremental contribution are three statements, not one (invocation intensity ≠ invocation incidence).
- Source and Method carry a role dimension: engine-input, observation, evaluation.
- Three clock points per Frame; engine stance as a presentation fact; subscription-style pushes as prior authorization without an immediate query.
- Value states `ABSENT`, `UNOBSERVED`, `NOT_APPLICABLE` plus `UNDETERMINABLE`; "unrestricted" scope distinguished from observed coverage.
- Versioned closure with addenda; disputes point at a `statementId`.
- Composite scores allowed only with components, weights and method.
- Conclusions must not exceed the evidence (inherited from the dispute-resolution framework).

## Number assignment (2026-11-14)

The editors assigned **ERC-8501** in a review on ethereum/ERCs PR #2176. Files renamed to `ERCS/erc-8501.md` and `assets/erc-8501/`; JSON-LD namespace IRI moved to `https://eips.ethereum.org/EIPS/eip-8501#`; Ethereum Magicians topic 30396 retitled "ERC-8501: Generative Engine Optimization Framework". No example record or vector changed, so every content hash committed on Sepolia still matches.

## Pending

| # | Question | Skeleton's choice |
| --- | --- | --- |
| N1 | Metric prefix `geo:` vs `geof:` | `geof:` — `geo:` collides with the W3C WGS84 vocabulary prefix and the RFC 5870 URI scheme |
| N2 | Nine families or ten | ten — `attribution` separate from `attainment` |
| N3 | Who may commit to another account's Process | anyone, attributable to the sender; only the opener closes or reopens |
| N4 | Fifth value state | `UNDETERMINABLE` added |
| N5 | License | CC0 for text and assets |
| N6 | Process id derivation | `keccak256(abi.encode(opener, frameId, nonce))` — independent of block time so ids are predictable off-chain and scripts that reference a process in later transactions do not break between simulation and broadcast |
