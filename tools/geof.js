#!/usr/bin/env node
// GEOF off-chain tool: canonicalize (RFC 8785), hash (keccak256), derive ids, validate against schemas.
//
//   node tools/geof.js subject "<scheme>:<domain>:<identifier>"   -> subjectId
//   node tools/geof.js hash <file.json>                             -> contentHash of the canonical record
//   node tools/geof.js validate <file.json>                         -> schema validation by record type
//   node tools/geof.js case <examples/case-x/case.json>             -> validate every record in a case bundle
//   node tools/geof.js vectors                                      -> (re)build assets/erc-9999/vectors/vectors.json
//
// Declaration id  = keccak256(abi.encode(kind, declarant, contentHash))
// Profile id      = keccak256(abi.encode(processId, version, publisher, profileHash))

const fs = require("fs");
const path = require("path");
const canonicalize = require("canonicalize");
const { keccak256, toUtf8Bytes, AbiCoder } = require("ethers");
const Ajv = require("ajv/dist/2020");
const addFormats = require("ajv-formats");

const ROOT = path.resolve(__dirname, "..");
const SCHEMA_DIR = path.join(ROOT, "assets", "erc-9999", "schemas");
const VECTORS = path.join(ROOT, "assets", "erc-9999", "vectors", "vectors.json");
const KIND = { "geof:object": 0, "geof:frame": 1, "geof:source": 2, "geof:method": 3, "geof:intent": 4, "geof:metric-definition": 5 };
const abi = AbiCoder.defaultAbiCoder();

function subjectId(canonicalSubject) {
  return keccak256(toUtf8Bytes(canonicalSubject));
}
function contentHash(record) {
  return keccak256(toUtf8Bytes(canonicalize(record)));
}
function declarationId(kind, declarant, hash) {
  return keccak256(abi.encode(["uint8", "address", "bytes32"], [kind, declarant, hash]));
}
function profileId(processId, version, publisher, hash) {
  return keccak256(abi.encode(["bytes32", "uint32", "address", "bytes32"], [processId, version, publisher, hash]));
}

function schemaFor(type) {
  const map = {
    "geof:object": "geof-object.schema.json",
    "geof:frame": "geof-frame.schema.json",
    "geof:source": "geof-source.schema.json",
    "geof:method": "geof-method.schema.json",
    "geof:intent": "geof-intent.schema.json",
    "geof:metric-definition": "geof-metric-definition.schema.json",
    "geof:observation": "geof-observation.schema.json",
    "geof:profile": "geof-profile.schema.json",
  };
  return map[type];
}

function makeAjv() {
  const ajv = new Ajv({ strict: false, allErrors: true });
  addFormats(ajv);
  for (const f of fs.readdirSync(SCHEMA_DIR)) {
    if (!f.endsWith(".schema.json")) continue;
    ajv.addSchema(JSON.parse(fs.readFileSync(path.join(SCHEMA_DIR, f), "utf8")));
  }
  return ajv;
}

function validateRecord(ajv, record, label) {
  const s = schemaFor(record.type);
  if (!s) return { label, ok: false, errors: [`unknown record type ${record.type}`] };
  const v = ajv.getSchema(s);
  const ok = v(record);
  return { label, ok, errors: ok ? [] : v.errors.map((e) => `${e.instancePath || "/"} ${e.message}`) };
}

function caseRecords(bundle) {
  const out = [];
  (bundle.objects || []).forEach((r, i) => out.push([`objects[${i}]`, r]));
  if (bundle.intent) out.push(["intent", bundle.intent]);
  if (bundle.frame) out.push(["frame", bundle.frame]);
  (bundle.sources || []).forEach((r, i) => out.push([`sources[${i}]`, r]));
  (bundle.methods || []).forEach((r, i) => out.push([`methods[${i}]`, r]));
  (bundle.observations_sample || []).forEach((r, i) => out.push([`observations_sample[${i}]`, r]));
  if (bundle.profile) out.push(["profile", bundle.profile]);
  return out;
}

function buildVectors() {
  const subjects = [
    "claim:example.com:warranty-correction-2026-10",
    "content:example.com:/notices/warranty-correction",
    "caip19:eip155:11155111:erc721:0x8338000000000000000000000000000000000001/42",
  ];
  const cases = ["case-a-web-correction", "case-b-agentic-skill"].map((name) => {
    const file = path.join(ROOT, "assets", "erc-9999", "examples", name, "case.json");
    const bundle = JSON.parse(fs.readFileSync(file, "utf8"));
    const records = caseRecords(bundle)
      .filter(([, r]) => KIND[r.type] !== undefined || r.type === "geof:profile")
      .map(([label, r]) => {
        const h = contentHash(r);
        const declarant = r.provenance ? r.provenance.declarant : r.publisher;
        const entry = { label, type: r.type, contentHash: h, declarant };
        if (KIND[r.type] !== undefined) entry.declarationId = declarationId(KIND[r.type], declarant, h);
        if (r.type === "geof:object") entry.subjectId = r.subjectId;
        return entry;
      });
    return { case: name, records };
  });
  const vectors = {
    note: "Derived by tools/geof.js. canonicalization = RFC 8785 (JCS); hash = keccak256(utf8(canonical)). Declaration id = keccak256(abi.encode(uint8 kind, address declarant, bytes32 contentHash)). Kind codes: object 0, frame 1, source 2, method 3, intent 4, metric 5.",
    subjectIds: subjects.map((s) => ({ canonicalSubject: s, subjectId: subjectId(s) })),
    declarationIdExample: {
      kind: 1,
      declarant: "0x2222222222222222222222222222222222222222",
      contentHash: keccak256(toUtf8Bytes('{"a":1}')),
      declarationId: declarationId(1, "0x2222222222222222222222222222222222222222", keccak256(toUtf8Bytes('{"a":1}'))),
    },
    profileIdExample: {
      processId: "0x7000000000000000000000000000000000000000000000000000000000000a01",
      version: 1,
      publisher: "0x2222222222222222222222222222222222222222",
      profileHash: keccak256(toUtf8Bytes('{"b":2}')),
      profileId: profileId(
        "0x7000000000000000000000000000000000000000000000000000000000000a01",
        1,
        "0x2222222222222222222222222222222222222222",
        keccak256(toUtf8Bytes('{"b":2}'))
      ),
    },
    cases,
  };
  fs.mkdirSync(path.dirname(VECTORS), { recursive: true });
  fs.writeFileSync(VECTORS, JSON.stringify(vectors, null, 2) + "\n");
  return vectors;
}

function main() {
  const [cmd, arg] = process.argv.slice(2);
  if (cmd === "subject") {
    console.log(subjectId(arg));
  } else if (cmd === "hash") {
    console.log(contentHash(JSON.parse(fs.readFileSync(arg, "utf8"))));
  } else if (cmd === "validate") {
    const r = validateRecord(makeAjv(), JSON.parse(fs.readFileSync(arg, "utf8")), arg);
    console.log(r.ok ? `ok ${arg}` : `FAIL ${arg}\n  ${r.errors.join("\n  ")}`);
    process.exit(r.ok ? 0 : 1);
  } else if (cmd === "case") {
    const ajv = makeAjv();
    const bundle = JSON.parse(fs.readFileSync(arg, "utf8"));
    let bad = 0;
    for (const [label, r] of caseRecords(bundle)) {
      const res = validateRecord(ajv, r, label);
      if (!res.ok) bad++;
      console.log(res.ok ? `ok   ${label}` : `FAIL ${label}\n  ${res.errors.join("\n  ")}`);
    }
    process.exit(bad ? 1 : 0);
  } else if (cmd === "vectors") {
    const v = buildVectors();
    console.log(`wrote ${path.relative(ROOT, VECTORS)}: ${v.subjectIds.length} subjects, ${v.cases.reduce((n, c) => n + c.records.length, 0)} records`);
  } else {
    console.error("usage: geof.js subject <s> | hash <file> | validate <file> | case <case.json> | vectors");
    process.exit(2);
  }
}

module.exports = { subjectId, contentHash, declarationId, profileId, canonicalize };
if (require.main === module) main();
