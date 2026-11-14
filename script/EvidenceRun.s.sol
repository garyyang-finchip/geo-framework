// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {GEOFRegistry} from "../contracts/GEOFRegistry.sol";
import {IGEOFRegistry} from "../contracts/interfaces/IGEOFRegistry.sol";

/// @notice Evidence run: deploys GEOFRegistry and walks case A and case B on chain with the record
///         hashes from assets/erc-9999/vectors/vectors.json. Three accounts:
///         A (DEPLOYER_PK)   — panel observer in case A, skill provider in case B
///         B (derived)       — company in case A, independent indexer in case B
///         C (derived)       — auditor (second publisher) in case A
///         B and C are funded from A inside the run. Writes deployments/<network>.json.
///
///   NETWORK=anvil   forge script script/EvidenceRun.s.sol --rpc-url $RPC --broadcast
///   NETWORK=sepolia forge script script/EvidenceRun.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --skip-simulation
contract EvidenceRun is Script {
    string internal vectors;
    GEOFRegistry internal reg;

    uint256 internal pkA;
    uint256 internal pkB;
    uint256 internal pkC;
    address internal A;
    address internal B;
    address internal C;

    string internal out;

    function run() external {
        pkA = vm.envUint("DEPLOYER_PK");
        A = vm.addr(pkA);
        // deterministic sub-accounts for this run; keys are derived from the deployer key and never reused
        pkB = uint256(keccak256(abi.encode(pkA, "geof-evidence-B")));
        pkC = uint256(keccak256(abi.encode(pkA, "geof-evidence-C")));
        B = vm.addr(pkB);
        C = vm.addr(pkC);
        vectors = vm.readFile("assets/erc-9999/vectors/vectors.json");
        string memory network = vm.envOr("NETWORK", string("anvil"));
        uint256 fund = vm.envOr("FUND_WEI", uint256(0.004 ether));

        console2.log("A (deployer / panel / provider):", A);
        console2.log("B (company / indexer):          ", B);
        console2.log("C (auditor):                    ", C);

        // ---- deploy + fund -------------------------------------------------
        vm.startBroadcast(pkA);
        reg = new GEOFRegistry();
        payable(B).transfer(fund);
        payable(C).transfer(fund / 4);
        vm.stopBroadcast();
        console2.log("GEOFRegistry:", address(reg));

        out = "geof";
        vm.serializeString(out, "network", network);
        vm.serializeAddress(out, "registry", address(reg));
        vm.serializeAddress(out, "accountA", A);
        vm.serializeAddress(out, "accountB", B);
        vm.serializeAddress(out, "accountC", C);
        vm.serializeUint(out, "chainId", block.chainid);

        _caseA();
        _caseB();

        string memory json = vm.serializeUint(out, "finishedAt", block.timestamp);
        string memory file = string.concat("deployments/", network, ".json");
        vm.writeJson(json, file);
        console2.log("wrote", file);
    }

    // ---------------------------------------------------------------------
    // helpers
    // ---------------------------------------------------------------------

    function _h(uint256 caseIdx, uint256 recIdx) internal view returns (bytes32) {
        return vm.parseJsonBytes32(
            vectors, string.concat(".cases[", vm.toString(caseIdx), "].records[", vm.toString(recIdx), "].contentHash")
        );
    }

    function _s(uint256 i) internal view returns (bytes32) {
        return vm.parseJsonBytes32(vectors, string.concat(".subjectIds[", vm.toString(i), "].subjectId"));
    }

    function _arr(bytes32 a) internal pure returns (bytes32[] memory r) {
        r = new bytes32[](1);
        r[0] = a;
    }

    function _arr(bytes32 a, bytes32 b) internal pure returns (bytes32[] memory r) {
        r = new bytes32[](2);
        r[0] = a;
        r[1] = b;
    }

    function _arr(bytes32 a, bytes32 b, bytes32 c) internal pure returns (bytes32[] memory r) {
        r = new bytes32[](3);
        r[0] = a;
        r[1] = b;
        r[2] = c;
    }

    function _arr(bytes32 a, bytes32 b, bytes32 c, bytes32 d) internal pure returns (bytes32[] memory r) {
        r = new bytes32[](4);
        r[0] = a;
        r[1] = b;
        r[2] = c;
        r[3] = d;
    }

    // ---------------------------------------------------------------------
    // Case A — vectors.cases[0]: objects[0..1], intent 2, frame 3, sources 4..6, methods 7..10, profile 11
    // ---------------------------------------------------------------------

    struct AIds {
        bytes32 objClaim;
        bytes32 objPage;
        bytes32 intent;
        bytes32 srcLogs;
        bytes32 frame;
        bytes32 srcPanel;
        bytes32 srcNotice;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 m4;
        bytes32 pid;
        bytes32 profPanel;
        bytes32 profAuditor;
        bytes32 profPanel2;
    }

    AIds internal a;

    function _caseA() internal {
        string memory base = "geof.examples/case-a-web-correction/";

        // company (B): objects, intent, publisher-side source
        vm.startBroadcast(pkB);
        a.objClaim = reg.declareObject(_s(0), _h(0, 0), 0, string.concat(base, "objects/0"));
        a.objPage = reg.declareObject(_s(1), _h(0, 1), 0, string.concat(base, "objects/1"));
        a.intent = reg.declare(IGEOFRegistry.DeclarationKind.INTENT, _h(0, 2), 0, string.concat(base, "intent"));
        a.srcLogs = reg.declare(IGEOFRegistry.DeclarationKind.SOURCE, _h(0, 6), 0, string.concat(base, "sources/2"));
        vm.stopBroadcast();

        // panel (A): frame, sources, methods, process
        vm.startBroadcast(pkA);
        a.frame = reg.declare(IGEOFRegistry.DeclarationKind.FRAME, _h(0, 3), 0, string.concat(base, "frame"));
        a.srcPanel = reg.declare(IGEOFRegistry.DeclarationKind.SOURCE, _h(0, 4), 0, string.concat(base, "sources/0"));
        a.srcNotice = reg.declare(IGEOFRegistry.DeclarationKind.SOURCE, _h(0, 5), 0, string.concat(base, "sources/1"));
        a.m1 = reg.declare(IGEOFRegistry.DeclarationKind.METHOD, _h(0, 7), 0, string.concat(base, "methods/0"));
        a.m2 = reg.declare(IGEOFRegistry.DeclarationKind.METHOD, _h(0, 8), 0, string.concat(base, "methods/1"));
        a.m3 = reg.declare(IGEOFRegistry.DeclarationKind.METHOD, _h(0, 9), 0, string.concat(base, "methods/2"));
        a.m4 = reg.declare(IGEOFRegistry.DeclarationKind.METHOD, _h(0, 10), 0, string.concat(base, "methods/3"));
        a.pid = reg.openProcess(
            a.frame, _arr(a.objClaim, a.objPage), _arr(a.intent), _arr(a.srcPanel, a.srcNotice, a.srcLogs), _arr(a.m1, a.m2, a.m3, a.m4)
        );
        // four weekly batches of answer instances (360 each = 1440)
        for (uint256 w = 1; w <= 4; w++) {
            reg.commitObservations(a.pid, keccak256(abi.encode("A:events:week", w)), 360, IGEOFRegistry.ObservationKind.EVENT);
        }
        vm.stopBroadcast();

        // company (B): monthly aggregate from its logs
        vm.startBroadcast(pkB);
        reg.commitObservations(a.pid, keccak256("A:aggregate:oct-logs"), 1, IGEOFRegistry.ObservationKind.AGGREGATE);
        vm.stopBroadcast();

        // panel (A): freeze v1, publish profile
        vm.startBroadcast(pkA);
        reg.closeProcess(a.pid, keccak256("A:evidence-root:v1"), uint48(block.timestamp + 14 days));
        a.profPanel = reg.publishProfile(a.pid, 1, _h(0, 11), 0, string.concat(base, "profile"));
        vm.stopBroadcast();

        // auditor (C): second profile on the same frozen version
        vm.startBroadcast(pkC);
        a.profAuditor = reg.publishProfile(a.pid, 1, keccak256("A:profile:auditor:v1"), 0, string.concat(base, "profile-auditor"));
        vm.stopBroadcast();

        // panel (A): addendum for late recipient signal; company (B) commits it; panel freezes v2 and supersedes
        vm.startBroadcast(pkA);
        reg.openAddendum(a.pid);
        vm.stopBroadcast();
        vm.startBroadcast(pkB);
        reg.commitObservations(a.pid, keccak256("A:followup:survey"), 40, IGEOFRegistry.ObservationKind.FOLLOWUP);
        vm.stopBroadcast();
        vm.startBroadcast(pkA);
        reg.closeProcess(a.pid, keccak256("A:evidence-root:v2"), uint48(block.timestamp + 14 days));
        a.profPanel2 = reg.publishProfile(a.pid, 2, keccak256("A:profile:panel:v2"), a.profPanel, string.concat(base, "profile-v2"));
        vm.stopBroadcast();

        string memory o = "caseA";
        vm.serializeBytes32(o, "processId", a.pid);
        vm.serializeBytes32(o, "frameId", a.frame);
        vm.serializeBytes32(o, "objectClaimId", a.objClaim);
        vm.serializeBytes32(o, "objectPageId", a.objPage);
        vm.serializeBytes32(o, "intentId", a.intent);
        vm.serializeBytes32(o, "profilePanelV1", a.profPanel);
        vm.serializeBytes32(o, "profileAuditorV1", a.profAuditor);
        string memory j = vm.serializeBytes32(o, "profilePanelV2", a.profPanel2);
        vm.serializeString(out, "caseA", j);
        console2.log("case A process:");
        console2.logBytes32(a.pid);
    }

    // ---------------------------------------------------------------------
    // Case B — vectors.cases[1]: objects[0] 0, intent 1, frame 2, sources 3..5, methods 6..8, profile 9
    // ---------------------------------------------------------------------

    struct BIds {
        bytes32 objSkill;
        bytes32 intent;
        bytes32 frame;
        bytes32 srcGateway;
        bytes32 srcChain;
        bytes32 srcDescriptor;
        bytes32 m1;
        bytes32 m2;
        bytes32 m3;
        bytes32 pid;
        bytes32 profProvider;
        bytes32 profIndexer;
    }

    BIds internal b;

    function _caseB() internal {
        string memory base = "geof.examples/case-b-agentic-skill/";

        // provider (A): everything up to the first commitments
        vm.startBroadcast(pkA);
        b.objSkill = reg.declareObject(_s(2), _h(1, 0), 0, string.concat(base, "objects/0"));
        b.intent = reg.declare(IGEOFRegistry.DeclarationKind.INTENT, _h(1, 1), 0, string.concat(base, "intent"));
        b.frame = reg.declare(IGEOFRegistry.DeclarationKind.FRAME, _h(1, 2), 0, string.concat(base, "frame"));
        b.srcGateway = reg.declare(IGEOFRegistry.DeclarationKind.SOURCE, _h(1, 3), 0, string.concat(base, "sources/0"));
        b.srcChain = reg.declare(IGEOFRegistry.DeclarationKind.SOURCE, _h(1, 4), 0, string.concat(base, "sources/1"));
        b.srcDescriptor = reg.declare(IGEOFRegistry.DeclarationKind.SOURCE, _h(1, 5), 0, string.concat(base, "sources/2"));
        b.m1 = reg.declare(IGEOFRegistry.DeclarationKind.METHOD, _h(1, 6), 0, string.concat(base, "methods/0"));
        b.m2 = reg.declare(IGEOFRegistry.DeclarationKind.METHOD, _h(1, 7), 0, string.concat(base, "methods/1"));
        b.m3 = reg.declare(IGEOFRegistry.DeclarationKind.METHOD, _h(1, 8), 0, string.concat(base, "methods/2"));
        b.pid = reg.openProcess(
            b.frame, _arr(b.objSkill), _arr(b.intent), _arr(b.srcGateway, b.srcChain, b.srcDescriptor), _arr(b.m1, b.m2, b.m3)
        );
        reg.commitObservations(b.pid, keccak256("B:events:discovery"), 11, IGEOFRegistry.ObservationKind.EVENT);
        reg.commitObservations(b.pid, keccak256("B:aggregate:gateway"), 1, IGEOFRegistry.ObservationKind.AGGREGATE);
        vm.stopBroadcast();

        // indexer (B): the three settlements as follow-ups
        vm.startBroadcast(pkB);
        reg.commitObservations(b.pid, keccak256("B:followups:settlements"), 3, IGEOFRegistry.ObservationKind.FOLLOWUP);
        vm.stopBroadcast();

        // provider (A): freeze and publish; indexer (B): second profile
        vm.startBroadcast(pkA);
        reg.closeProcess(b.pid, keccak256("B:evidence-root:v1"), uint48(block.timestamp + 7 days));
        b.profProvider = reg.publishProfile(b.pid, 1, _h(1, 9), 0, string.concat(base, "profile"));
        vm.stopBroadcast();
        vm.startBroadcast(pkB);
        b.profIndexer = reg.publishProfile(b.pid, 1, keccak256("B:profile:indexer:v1"), 0, string.concat(base, "profile-indexer"));
        vm.stopBroadcast();

        string memory o = "caseB";
        vm.serializeBytes32(o, "processId", b.pid);
        vm.serializeBytes32(o, "frameId", b.frame);
        vm.serializeBytes32(o, "objectSkillId", b.objSkill);
        vm.serializeBytes32(o, "intentId", b.intent);
        vm.serializeBytes32(o, "profileProviderV1", b.profProvider);
        string memory j = vm.serializeBytes32(o, "profileIndexerV1", b.profIndexer);
        vm.serializeString(out, "caseB", j);
        console2.log("case B process:");
        console2.logBytes32(b.pid);
    }
}
