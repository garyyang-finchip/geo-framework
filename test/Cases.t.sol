// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {GEOFRegistry} from "../contracts/GEOFRegistry.sol";
import {IGEOFRegistry} from "../contracts/interfaces/IGEOFRegistry.sol";

/// @notice The two worked cases of the specification, walked on chain end to end.
///         Case A: a web correction notice — wide spread, low fidelity, attainment unknown.
///         Case B: an agentic skill — narrow reach, full fidelity, full attainment.
///         Record contents live in assets/erc-9999/examples/; here only their hashes matter.
contract CasesTest is Test {
    GEOFRegistry internal reg;

    // Case A participants
    address internal company = makeAddr("company"); // object holder, declares intent and logs
    address internal panel = makeAddr("panel"); // third-party observer, opens the process
    address internal auditor = makeAddr("auditor"); // second publisher, disagrees on one statement

    // Case B participants
    address internal provider = makeAddr("provider"); // skill provider, first-party observer and opener
    address internal indexer = makeAddr("indexer"); // independent chain indexer, commits follow-ups

    bytes32 internal constant SUBJECT_CLAIM = keccak256("claim:example.com:warranty-correction-2026-10");
    bytes32 internal constant SUBJECT_PAGE = keccak256("content:example.com:/notices/warranty-correction");
    bytes32 internal constant SUBJECT_SKILL =
        keccak256("caip19:eip155:11155111:erc721:0x8338000000000000000000000000000000000001/42");

    function setUp() public {
        reg = new GEOFRegistry();
        vm.warp(1_800_000_000);
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

    function _empty() internal pure returns (bytes32[] memory r) {
        r = new bytes32[](0);
    }

    // ------------------------------------------------------------------
    // Case A — wide spread, low fidelity, attainment unknown
    // ------------------------------------------------------------------

    struct CaseAIds {
        bytes32 objClaim;
        bytes32 objPage;
        bytes32 intent;
        bytes32 srcLogs;
        bytes32 frame;
        bytes32 srcPanel;
        bytes32 srcNotice;
        bytes32 mSampling;
        bytes32 mDetect;
        bytes32 mJudge;
        bytes32 mRates;
        bytes32 pid;
    }

    CaseAIds internal ca;

    function _caseADeclareCompany() internal {
        vm.startPrank(company);
        ca.objClaim = reg.declareObject(SUBJECT_CLAIM, keccak256("A:object:claim"), 0, "ipfs://A/object-claim");
        ca.objPage = reg.declareObject(SUBJECT_PAGE, keccak256("A:object:page"), 0, "ipfs://A/object-page");
        ca.intent = reg.declare(IGEOFRegistry.DeclarationKind.INTENT, keccak256("A:intent"), 0, "ipfs://A/intent");
        ca.srcLogs =
            reg.declare(IGEOFRegistry.DeclarationKind.SOURCE, keccak256("A:source:publisher-logs"), 0, "ipfs://A/src-logs");
        vm.stopPrank();
    }

    function _caseADeclarePanelAndOpen() internal {
        vm.startPrank(panel);
        ca.frame = reg.declare(IGEOFRegistry.DeclarationKind.FRAME, keccak256("A:frame"), 0, "ipfs://A/frame");
        ca.srcPanel = reg.declare(IGEOFRegistry.DeclarationKind.SOURCE, keccak256("A:source:panel"), 0, "ipfs://A/src-panel");
        ca.srcNotice =
            reg.declare(IGEOFRegistry.DeclarationKind.SOURCE, keccak256("A:source:notice-page"), 0, "ipfs://A/src-notice");
        ca.mSampling =
            reg.declare(IGEOFRegistry.DeclarationKind.METHOD, keccak256("A:method:panel-design-v1"), 0, "ipfs://A/m1");
        ca.mDetect = reg.declare(IGEOFRegistry.DeclarationKind.METHOD, keccak256("A:method:detect-v2"), 0, "ipfs://A/m2");
        ca.mJudge =
            reg.declare(IGEOFRegistry.DeclarationKind.METHOD, keccak256("A:method:claim-coverage-judge-v1"), 0, "ipfs://A/m3");
        ca.mRates = reg.declare(IGEOFRegistry.DeclarationKind.METHOD, keccak256("A:method:rates-wilson-v1"), 0, "ipfs://A/m4");
        ca.pid = reg.openProcess(
            ca.frame,
            _arr(ca.objClaim, ca.objPage),
            _arr(ca.intent),
            _arr(ca.srcPanel, ca.srcNotice, ca.srcLogs),
            _arr(ca.mSampling, ca.mDetect, ca.mJudge, ca.mRates)
        );
        vm.stopPrank();
    }

    function test_CaseA_WebCorrection() public {
        // 1. The company describes its objects and declares its ex-ante intent.
        _caseADeclareCompany();
        // 2. The third-party panel declares its frame, sources and methods, and opens the process.
        _caseADeclarePanelAndOpen();
        bytes32 pid = ca.pid;

        (address opener,, uint32 v, bool open) = reg.processOf(pid);
        assertEq(opener, panel);
        assertEq(v, 1);
        assertTrue(open);

        // 3. Observations over the 30-day window: panel commits 1440 answer instances in weekly batches;
        //    the company commits one monthly aggregate from its logs.
        for (uint256 week = 1; week <= 4; week++) {
            vm.warp(1_800_000_000 + week * 7 days);
            vm.prank(panel);
            reg.commitObservations(pid, keccak256(abi.encode("A:events:week", week)), 360, IGEOFRegistry.ObservationKind.EVENT);
        }
        vm.prank(company);
        reg.commitObservations(pid, keccak256("A:aggregate:oct-logs"), 1, IGEOFRegistry.ObservationKind.AGGREGATE);
        (,, uint64 commits,) = reg.versionOf(pid, 1);
        assertEq(commits, 5);

        // 4. The panel freezes version 1 with an observation cutoff two weeks later.
        uint48 cutoff = uint48(1_800_000_000 + 45 days);
        vm.warp(1_800_000_000 + 32 days);
        vm.prank(panel);
        reg.closeProcess(pid, keccak256("A:evidence-root:v1"), cutoff);
        (,,, open) = reg.processOf(pid);
        assertFalse(open);

        // 5. Two profiles against v1: the panel's (nine statements, attainment UNOBSERVED) and an auditor's
        //    that re-reads the same evidence with a different claim-coverage method. Both coexist.
        vm.prank(panel);
        bytes32 profPanel = reg.publishProfile(pid, 1, keccak256("A:profile:panel:v1"), 0, "ipfs://A/profile-panel");
        vm.prank(auditor);
        bytes32 profAuditor = reg.publishProfile(pid, 1, keccak256("A:profile:auditor:v1"), 0, "ipfs://A/profile-auditor");
        assertTrue(profPanel != profAuditor);

        // 6. A late recipient signal arrives: the company cannot open an addendum (not the opener);
        //    the panel does, and the company's follow-up lands in v2 without touching v1.
        vm.prank(company);
        vm.expectRevert(abi.encodeWithSelector(IGEOFRegistry.GEOF_NotOpener.selector, pid, company));
        reg.openAddendum(pid);
        vm.prank(panel);
        assertEq(reg.openAddendum(pid), 2);
        vm.prank(company);
        reg.commitObservations(pid, keccak256("A:followup:survey"), 40, IGEOFRegistry.ObservationKind.FOLLOWUP);
        _assertFrozenV1(pid);

        // 7. The panel freezes v2 and supersedes its own profile with one that now states attainment
        //    (30/40 understood among those surveyed, coverage 40/100). The auditor's v1 profile stands.
        vm.startPrank(panel);
        reg.closeProcess(pid, keccak256("A:evidence-root:v2"), cutoff);
        bytes32 profPanel2 = reg.publishProfile(pid, 2, keccak256("A:profile:panel:v2"), profPanel, "ipfs://A/profile-panel-2");
        vm.stopPrank();
        (, uint32 pv,,, bytes32 sup,,) = reg.profileOf(profPanel2);
        assertEq(pv, 2);
        assertEq(sup, profPanel);
        (,, address pubA,,,,) = reg.profileOf(profAuditor);
        assertEq(pubA, auditor);
    }

    function _assertFrozenV1(bytes32 pid) internal view {
        (bytes32 root1,, uint64 n1, bool frozen1) = reg.versionOf(pid, 1);
        assertEq(root1, keccak256("A:evidence-root:v1"));
        assertEq(n1, 5);
        assertTrue(frozen1);
    }

    // ------------------------------------------------------------------
    // Case B — narrow reach, full fidelity, full attainment
    // ------------------------------------------------------------------

    function test_CaseB_AgenticSkill() public {
        // 1. Provider declares the skill object (referencing its value-registry record off-chain),
        //    its intent toward three named agents, frame, sources and methods, and opens the process.
        vm.startPrank(provider);
        bytes32 objSkill = reg.declareObject(SUBJECT_SKILL, keccak256("B:object:skill"), 0, "ipfs://B/object-skill");
        bytes32 intent = reg.declare(IGEOFRegistry.DeclarationKind.INTENT, keccak256("B:intent"), 0, "ipfs://B/intent");
        bytes32 frame = reg.declare(IGEOFRegistry.DeclarationKind.FRAME, keccak256("B:frame"), 0, "ipfs://B/frame");
        bytes32 srcGateway =
            reg.declare(IGEOFRegistry.DeclarationKind.SOURCE, keccak256("B:source:gateway-logs"), 0, "ipfs://B/src-gw");
        bytes32 srcChain = reg.declare(IGEOFRegistry.DeclarationKind.SOURCE, keccak256("B:source:chain"), 0, "ipfs://B/src-chain");
        bytes32 srcDescriptor =
            reg.declare(IGEOFRegistry.DeclarationKind.SOURCE, keccak256("B:source:canonical-descriptor"), 0, "ipfs://B/src-desc");
        bytes32 mHash =
            reg.declare(IGEOFRegistry.DeclarationKind.METHOD, keccak256("B:method:descriptor-hash-match-v1"), 0, "ipfs://B/m1");
        bytes32 mLink = reg.declare(IGEOFRegistry.DeclarationKind.METHOD, keccak256("B:method:chain-link-v1"), 0, "ipfs://B/m2");
        bytes32 mCounts = reg.declare(IGEOFRegistry.DeclarationKind.METHOD, keccak256("B:method:counts-v1"), 0, "ipfs://B/m3");
        bytes32 pid = reg.openProcess(
            frame, _arr(objSkill), _arr(intent), _arr(srcGateway, srcChain, srcDescriptor), _arr(mHash, mLink, mCounts)
        );

        // 2. Discovery events for the three agents (INVOKED, actor = recipient) and the gateway aggregate.
        reg.commitObservations(pid, keccak256("B:events:discovery"), 11, IGEOFRegistry.ObservationKind.EVENT);
        reg.commitObservations(pid, keccak256("B:aggregate:gateway"), 1, IGEOFRegistry.ObservationKind.AGGREGATE);
        vm.stopPrank();

        // 3. An independent indexer commits the three settlements as follow-ups with deterministic links.
        vm.warp(1_800_000_000 + 10 days);
        vm.prank(indexer);
        reg.commitObservations(pid, keccak256("B:followups:settlements"), 3, IGEOFRegistry.ObservationKind.FOLLOWUP);
        (,, uint64 commits,) = reg.versionOf(pid, 1);
        assertEq(commits, 3);

        // 4. Provider freezes v1 and publishes its profile (attainment 3/3, attribution UNDETERMINABLE).
        vm.warp(1_800_000_000 + 15 days);
        vm.startPrank(provider);
        reg.closeProcess(pid, keccak256("B:evidence-root:v1"), uint48(1_800_000_000 + 21 days));
        bytes32 profProvider = reg.publishProfile(pid, 1, keccak256("B:profile:provider:v1"), 0, "ipfs://B/profile-provider");
        vm.stopPrank();

        // 5. The indexer publishes its own profile against the same frozen version (it can only speak to
        //    the on-chain statements; exposure and fidelity are UNOBSERVED in its profile).
        vm.prank(indexer);
        bytes32 profIndexer = reg.publishProfile(pid, 1, keccak256("B:profile:indexer:v1"), 0, "ipfs://B/profile-indexer");
        assertTrue(profProvider != profIndexer);

        // 6. Nothing further arrives; the process stays at one frozen version.
        (, bytes32 f, uint32 cur, bool open) = reg.processOf(pid);
        assertEq(f, frame);
        assertEq(cur, 1);
        assertFalse(open);
        (bytes32 root, uint48 cutoff, uint64 n, bool frozen) = reg.versionOf(pid, 1);
        assertEq(root, keccak256("B:evidence-root:v1"));
        assertEq(cutoff, uint48(1_800_000_000 + 21 days));
        assertEq(n, 3);
        assertTrue(frozen);
    }

    /// The same frame can back two independent processes: an observer who wants its own closure
    /// discipline opens its own process rather than committing into the provider's.
    function test_TwoProcessesOneFrame() public {
        vm.startPrank(provider);
        bytes32 objSkill = reg.declareObject(SUBJECT_SKILL, keccak256("B:object:skill"), 0, "");
        bytes32 frame = reg.declare(IGEOFRegistry.DeclarationKind.FRAME, keccak256("B:frame"), 0, "");
        bytes32 src = reg.declare(IGEOFRegistry.DeclarationKind.SOURCE, keccak256("B:source:chain"), 0, "");
        bytes32 m = reg.declare(IGEOFRegistry.DeclarationKind.METHOD, keccak256("B:method:counts-v1"), 0, "");
        bytes32 p1 = reg.openProcess(frame, _arr(objSkill), _empty(), _arr(src), _arr(m));
        vm.stopPrank();
        vm.prank(indexer);
        bytes32 p2 = reg.openProcess(frame, _arr(objSkill), _empty(), _arr(src), _arr(m));
        assertTrue(p1 != p2);
        (address o1, bytes32 f1,,) = reg.processOf(p1);
        (address o2, bytes32 f2,,) = reg.processOf(p2);
        assertEq(o1, provider);
        assertEq(o2, indexer);
        assertEq(f1, f2);
        // each opener closes only its own
        vm.prank(indexer);
        vm.expectRevert(abi.encodeWithSelector(IGEOFRegistry.GEOF_NotOpener.selector, p1, indexer));
        reg.closeProcess(p1, keccak256("x"), 0);
        vm.prank(indexer);
        reg.closeProcess(p2, keccak256("y"), 0);
    }
}
