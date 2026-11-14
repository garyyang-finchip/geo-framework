// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {GEOFRegistry} from "../contracts/GEOFRegistry.sol";
import {IGEOFRegistry} from "../contracts/interfaces/IGEOFRegistry.sol";

contract GEOFRegistryTest is Test {
    GEOFRegistry internal reg;

    address internal alice = makeAddr("alice"); // object holder / opener
    address internal bob = makeAddr("bob"); // third-party observer
    address internal carol = makeAddr("carol"); // engine operator / second publisher

    bytes32 internal constant H1 = keccak256("record-1");
    bytes32 internal constant H2 = keccak256("record-2");
    bytes32 internal constant H3 = keccak256("record-3");
    bytes32 internal constant SUBJECT = keccak256("claim:example.com:warranty-correction-2026-10");

    function setUp() public {
        reg = new GEOFRegistry();
        vm.warp(1_800_000_000);
    }

    // ------------------------------------------------------------------
    // helpers
    // ------------------------------------------------------------------

    function _id(IGEOFRegistry.DeclarationKind kind, address who, bytes32 h) internal pure returns (bytes32) {
        return keccak256(abi.encode(kind, who, h));
    }

    function _declareAll(address who)
        internal
        returns (bytes32 frameId, bytes32 objectId, bytes32 sourceId, bytes32 methodId, bytes32 intentId, bytes32 metricId)
    {
        vm.startPrank(who);
        frameId = reg.declare(IGEOFRegistry.DeclarationKind.FRAME, keccak256("frame"), 0, "ipfs://frame");
        objectId = reg.declareObject(SUBJECT, keccak256("object"), 0, "ipfs://object");
        sourceId = reg.declare(IGEOFRegistry.DeclarationKind.SOURCE, keccak256("source"), 0, "ipfs://source");
        methodId = reg.declare(IGEOFRegistry.DeclarationKind.METHOD, keccak256("method"), 0, "ipfs://method");
        intentId = reg.declare(IGEOFRegistry.DeclarationKind.INTENT, keccak256("intent"), 0, "ipfs://intent");
        metricId = reg.declare(IGEOFRegistry.DeclarationKind.METRIC, keccak256("metric"), 0, "ipfs://metric");
        vm.stopPrank();
    }

    function _one(bytes32 x) internal pure returns (bytes32[] memory a) {
        a = new bytes32[](1);
        a[0] = x;
    }

    function _none() internal pure returns (bytes32[] memory a) {
        a = new bytes32[](0);
    }

    function _openDefault(address opener) internal returns (bytes32 processId, bytes32 frameId, bytes32 intentId) {
        (bytes32 f, bytes32 o, bytes32 s, bytes32 m, bytes32 i,) = _declareAll(opener);
        vm.prank(opener);
        processId = reg.openProcess(f, _one(o), _one(i), _one(s), _one(m));
        return (processId, f, i);
    }

    // ------------------------------------------------------------------
    // ERC-165 / ERC-6372
    // ------------------------------------------------------------------

    function test_SupportsInterfaces() public view {
        assertTrue(reg.supportsInterface(0x01ffc9a7), "erc165");
        assertTrue(reg.supportsInterface(0xda287a1d), "erc6372");
        assertTrue(reg.supportsInterface(type(IGEOFRegistry).interfaceId), "geof");
        assertFalse(reg.supportsInterface(0xffffffff));
    }

    function test_ClockIsTimestamp() public {
        assertEq(reg.clock(), uint48(1_800_000_000));
        assertEq(reg.CLOCK_MODE(), "mode=timestamp");
        vm.warp(1_800_000_123);
        assertEq(reg.clock(), uint48(1_800_000_123));
    }

    // ------------------------------------------------------------------
    // declarations
    // ------------------------------------------------------------------

    function test_DeclareRecordsAttributionAndClock() public {
        vm.prank(bob);
        bytes32 id = reg.declare(IGEOFRegistry.DeclarationKind.FRAME, H1, 0, "ipfs://f");
        assertEq(id, _id(IGEOFRegistry.DeclarationKind.FRAME, bob, H1));
        (IGEOFRegistry.DeclarationKind kind, address declarant, bytes32 h, bytes32 sup, uint48 at, string memory uri) =
            reg.declarationOf(id);
        assertEq(uint8(kind), uint8(IGEOFRegistry.DeclarationKind.FRAME));
        assertEq(declarant, bob);
        assertEq(h, H1);
        assertEq(sup, bytes32(0));
        assertEq(at, uint48(1_800_000_000));
        assertEq(uri, "ipfs://f");
    }

    function test_DeclareEmitsEvent() public {
        vm.expectEmit(true, true, true, true);
        emit IGEOFRegistry.Declared(
            _id(IGEOFRegistry.DeclarationKind.SOURCE, bob, H1), IGEOFRegistry.DeclarationKind.SOURCE, bob, H1, 0, "u"
        );
        vm.prank(bob);
        reg.declare(IGEOFRegistry.DeclarationKind.SOURCE, H1, 0, "u");
    }

    function test_DeclareRejectsZeroHash() public {
        vm.expectRevert(IGEOFRegistry.GEOF_ZeroHash.selector);
        reg.declare(IGEOFRegistry.DeclarationKind.FRAME, 0, 0, "");
    }

    function test_DeclareRejectsObjectKind() public {
        vm.expectRevert(
            abi.encodeWithSelector(IGEOFRegistry.GEOF_WrongKind.selector, bytes32(0), IGEOFRegistry.DeclarationKind.OBJECT)
        );
        reg.declare(IGEOFRegistry.DeclarationKind.OBJECT, H1, 0, "");
    }

    function test_DuplicateBySameAccountReverts() public {
        vm.startPrank(bob);
        bytes32 id = reg.declare(IGEOFRegistry.DeclarationKind.METHOD, H1, 0, "a");
        vm.expectRevert(abi.encodeWithSelector(IGEOFRegistry.GEOF_DuplicateDeclaration.selector, id));
        reg.declare(IGEOFRegistry.DeclarationKind.METHOD, H1, 0, "b");
        vm.stopPrank();
    }

    function test_SameRecordByDifferentAccountsCoexists() public {
        vm.prank(bob);
        bytes32 a = reg.declare(IGEOFRegistry.DeclarationKind.METHOD, H1, 0, "a");
        vm.prank(carol);
        bytes32 b = reg.declare(IGEOFRegistry.DeclarationKind.METHOD, H1, 0, "b");
        assertTrue(a != b);
    }

    function test_SupersedesMustExist() public {
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(IGEOFRegistry.GEOF_UnknownDeclaration.selector, H3));
        reg.declare(IGEOFRegistry.DeclarationKind.METHOD, H1, H3, "");
    }

    function test_SupersedesMustBeSameKind() public {
        vm.startPrank(bob);
        bytes32 f = reg.declare(IGEOFRegistry.DeclarationKind.FRAME, H1, 0, "");
        vm.expectRevert(abi.encodeWithSelector(IGEOFRegistry.GEOF_SupersedesMismatch.selector, f));
        reg.declare(IGEOFRegistry.DeclarationKind.METHOD, H2, f, "");
        vm.stopPrank();
    }

    function test_SupersedesMustBeSameDeclarant() public {
        vm.prank(bob);
        bytes32 m = reg.declare(IGEOFRegistry.DeclarationKind.METHOD, H1, 0, "");
        vm.prank(carol);
        vm.expectRevert(abi.encodeWithSelector(IGEOFRegistry.GEOF_SupersedesMismatch.selector, m));
        reg.declare(IGEOFRegistry.DeclarationKind.METHOD, H2, m, "");
    }

    function test_SupersedesChainRecorded() public {
        vm.startPrank(bob);
        bytes32 m1 = reg.declare(IGEOFRegistry.DeclarationKind.METHOD, H1, 0, "v1");
        bytes32 m2 = reg.declare(IGEOFRegistry.DeclarationKind.METHOD, H2, m1, "v2");
        vm.stopPrank();
        (,,, bytes32 sup,,) = reg.declarationOf(m2);
        assertEq(sup, m1);
    }

    function test_DeclareObjectBindsSubjectAndEmits() public {
        bytes32 expected = _id(IGEOFRegistry.DeclarationKind.OBJECT, alice, H1);
        vm.expectEmit(true, true, false, false);
        emit IGEOFRegistry.SubjectBound(expected, SUBJECT);
        vm.prank(alice);
        bytes32 id = reg.declareObject(SUBJECT, H1, 0, "ipfs://o");
        assertEq(id, expected);
        assertEq(reg.subjectOf(id), SUBJECT);
    }

    function test_DeclareObjectRejectsZeroSubject() public {
        vm.expectRevert(IGEOFRegistry.GEOF_ZeroHash.selector);
        reg.declareObject(0, H1, 0, "");
    }

    /// Two accounts describe the same subject; neither declaration confers control.
    function test_ObjectDeclarationsForOneSubjectCoexist() public {
        vm.prank(alice);
        bytes32 a = reg.declareObject(SUBJECT, H1, 0, "alice-view");
        vm.prank(carol);
        bytes32 c = reg.declareObject(SUBJECT, H2, 0, "carol-view");
        assertEq(reg.subjectOf(a), SUBJECT);
        assertEq(reg.subjectOf(c), SUBJECT);
        assertTrue(a != c);
    }

    function test_SubjectOfNonObjectIsZero() public {
        vm.prank(bob);
        bytes32 f = reg.declare(IGEOFRegistry.DeclarationKind.FRAME, H1, 0, "");
        assertEq(reg.subjectOf(f), bytes32(0));
    }

    function test_UnknownDeclarationViewsRevert() public {
        vm.expectRevert(abi.encodeWithSelector(IGEOFRegistry.GEOF_UnknownDeclaration.selector, H3));
        reg.declarationOf(H3);
        vm.expectRevert(abi.encodeWithSelector(IGEOFRegistry.GEOF_UnknownDeclaration.selector, H3));
        reg.subjectOf(H3);
    }

    // ------------------------------------------------------------------
    // processes
    // ------------------------------------------------------------------

    function test_OpenProcessBindsAndStartsAtVersionOne() public {
        (bytes32 f, bytes32 o, bytes32 s, bytes32 m, bytes32 i,) = _declareAll(alice);
        vm.prank(alice);
        bytes32 pid = reg.openProcess(f, _one(o), _one(i), _one(s), _one(m));
        (address opener, bytes32 frameId, uint32 v, bool open) = reg.processOf(pid);
        assertEq(opener, alice);
        assertEq(frameId, f);
        assertEq(v, 1);
        assertTrue(open);
        (bytes32[] memory os, bytes32[] memory is_, bytes32[] memory ss, bytes32[] memory ms) = reg.processBindings(pid);
        assertEq(os[0], o);
        assertEq(is_[0], i);
        assertEq(ss[0], s);
        assertEq(ms[0], m);
        (bytes32 root, uint48 cutoff, uint64 n, bool frozen) = reg.versionOf(pid, 1);
        assertEq(root, bytes32(0));
        assertEq(cutoff, 0);
        assertEq(n, 0);
        assertFalse(frozen);
    }

    function test_OpenProcessWithoutIntentIsValid() public {
        (bytes32 f, bytes32 o, bytes32 s, bytes32 m,,) = _declareAll(alice);
        vm.prank(alice);
        bytes32 pid = reg.openProcess(f, _one(o), _none(), _one(s), _one(m));
        (, bytes32[] memory is_,,) = reg.processBindings(pid);
        assertEq(is_.length, 0);
    }

    function test_OpenProcessRequiresAtLeastOneObject() public {
        (bytes32 f,, bytes32 s, bytes32 m,,) = _declareAll(alice);
        vm.prank(alice);
        vm.expectRevert(IGEOFRegistry.GEOF_EmptyBinding.selector);
        reg.openProcess(f, _none(), _none(), _one(s), _one(m));
    }

    function test_OpenProcessChecksKinds() public {
        (bytes32 f, bytes32 o, bytes32 s, bytes32 m,,) = _declareAll(alice);
        vm.startPrank(alice);
        // object slot given a source id
        vm.expectRevert(
            abi.encodeWithSelector(IGEOFRegistry.GEOF_WrongKind.selector, s, IGEOFRegistry.DeclarationKind.OBJECT)
        );
        reg.openProcess(f, _one(s), _none(), _one(s), _one(m));
        // frame slot given an object id
        vm.expectRevert(
            abi.encodeWithSelector(IGEOFRegistry.GEOF_WrongKind.selector, o, IGEOFRegistry.DeclarationKind.FRAME)
        );
        reg.openProcess(o, _one(o), _none(), _one(s), _one(m));
        // unknown id
        vm.expectRevert(abi.encodeWithSelector(IGEOFRegistry.GEOF_UnknownDeclaration.selector, H3));
        reg.openProcess(f, _one(o), _none(), _one(H3), _one(m));
        vm.stopPrank();
    }

    function test_ProcessIdsDifferPerCall() public {
        (bytes32 f, bytes32 o, bytes32 s, bytes32 m,,) = _declareAll(alice);
        vm.startPrank(alice);
        bytes32 p1 = reg.openProcess(f, _one(o), _none(), _one(s), _one(m));
        bytes32 p2 = reg.openProcess(f, _one(o), _none(), _one(s), _one(m));
        vm.stopPrank();
        assertTrue(p1 != p2);
    }

    function test_OpenerMayUseAnotherAccountsDeclarations() public {
        (bytes32 f, bytes32 o, bytes32 s, bytes32 m,,) = _declareAll(alice);
        vm.prank(bob);
        bytes32 pid = reg.openProcess(f, _one(o), _none(), _one(s), _one(m));
        (address opener,,,) = reg.processOf(pid);
        assertEq(opener, bob);
    }

    // ------------------------------------------------------------------
    // commitments
    // ------------------------------------------------------------------

    function test_AnyAccountMayCommitAndIsAttributed() public {
        (bytes32 pid,,) = _openDefault(alice);
        vm.expectEmit(true, true, true, true);
        emit IGEOFRegistry.ObservationsCommitted(pid, 1, bob, H1, 1440, IGEOFRegistry.ObservationKind.EVENT);
        vm.prank(bob);
        reg.commitObservations(pid, H1, 1440, IGEOFRegistry.ObservationKind.EVENT);
        vm.prank(carol);
        reg.commitObservations(pid, H2, 1, IGEOFRegistry.ObservationKind.AGGREGATE);
        (,, uint64 n,) = reg.versionOf(pid, 1);
        assertEq(n, 2);
    }

    function test_CommitRejectsZeroRootAndZeroCount() public {
        (bytes32 pid,,) = _openDefault(alice);
        vm.expectRevert(IGEOFRegistry.GEOF_ZeroHash.selector);
        reg.commitObservations(pid, 0, 1, IGEOFRegistry.ObservationKind.EVENT);
        vm.expectRevert(IGEOFRegistry.GEOF_ZeroCount.selector);
        reg.commitObservations(pid, H1, 0, IGEOFRegistry.ObservationKind.EVENT);
    }

    function test_CommitToUnknownProcessReverts() public {
        vm.expectRevert(abi.encodeWithSelector(IGEOFRegistry.GEOF_UnknownProcess.selector, H3));
        reg.commitObservations(H3, H1, 1, IGEOFRegistry.ObservationKind.EVENT);
    }

    function test_CommitAfterFreezeReverts() public {
        (bytes32 pid,,) = _openDefault(alice);
        vm.prank(alice);
        reg.closeProcess(pid, H1, uint48(1_800_100_000));
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(IGEOFRegistry.GEOF_VersionFrozen.selector, pid, uint32(1)));
        reg.commitObservations(pid, H2, 1, IGEOFRegistry.ObservationKind.FOLLOWUP);
    }

    // ------------------------------------------------------------------
    // closure and addenda
    // ------------------------------------------------------------------

    function test_CloseFreezesVersionAndEmits() public {
        (bytes32 pid,,) = _openDefault(alice);
        vm.prank(bob);
        reg.commitObservations(pid, H1, 10, IGEOFRegistry.ObservationKind.EVENT);
        vm.expectEmit(true, true, false, true);
        emit IGEOFRegistry.ProcessClosed(pid, 1, H2, uint48(1_800_100_000));
        vm.prank(alice);
        reg.closeProcess(pid, H2, uint48(1_800_100_000));
        (bytes32 root, uint48 cutoff, uint64 n, bool frozen) = reg.versionOf(pid, 1);
        assertEq(root, H2);
        assertEq(cutoff, uint48(1_800_100_000));
        assertEq(n, 1);
        assertTrue(frozen);
        (,,, bool open) = reg.processOf(pid);
        assertFalse(open);
    }

    function test_CloseOnlyOpener() public {
        (bytes32 pid,,) = _openDefault(alice);
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(IGEOFRegistry.GEOF_NotOpener.selector, pid, bob));
        reg.closeProcess(pid, H1, 0);
    }

    function test_CloseTwiceReverts() public {
        (bytes32 pid,,) = _openDefault(alice);
        vm.startPrank(alice);
        reg.closeProcess(pid, H1, 0);
        vm.expectRevert(abi.encodeWithSelector(IGEOFRegistry.GEOF_VersionFrozen.selector, pid, uint32(1)));
        reg.closeProcess(pid, H2, 0);
        vm.stopPrank();
    }

    function test_AddendumRequiresFrozenAndOpener() public {
        (bytes32 pid,,) = _openDefault(alice);
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(IGEOFRegistry.GEOF_VersionOpen.selector, pid, uint32(1)));
        reg.openAddendum(pid);
        vm.prank(alice);
        reg.closeProcess(pid, H1, 0);
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(IGEOFRegistry.GEOF_NotOpener.selector, pid, bob));
        reg.openAddendum(pid);
    }

    function test_AddendumOpensNextVersionAndKeepsFrozenOne() public {
        (bytes32 pid,,) = _openDefault(alice);
        vm.prank(bob);
        reg.commitObservations(pid, H1, 5, IGEOFRegistry.ObservationKind.EVENT);
        vm.prank(alice);
        reg.closeProcess(pid, H2, uint48(1_800_100_000));
        vm.expectEmit(true, true, false, false);
        emit IGEOFRegistry.AddendumOpened(pid, 2);
        vm.prank(alice);
        uint32 v2 = reg.openAddendum(pid);
        assertEq(v2, 2);
        // late follow-up lands in v2
        vm.prank(bob);
        reg.commitObservations(pid, H3, 1, IGEOFRegistry.ObservationKind.FOLLOWUP);
        (bytes32 root1,, uint64 n1, bool frozen1) = reg.versionOf(pid, 1);
        (bytes32 root2,, uint64 n2, bool frozen2) = reg.versionOf(pid, 2);
        assertEq(root1, H2);
        assertEq(n1, 1);
        assertTrue(frozen1);
        assertEq(root2, bytes32(0));
        assertEq(n2, 1);
        assertFalse(frozen2);
        (,, uint32 cur, bool open) = reg.processOf(pid);
        assertEq(cur, 2);
        assertTrue(open);
    }

    function test_VersionOfRejectsZeroAndFuture() public {
        (bytes32 pid,,) = _openDefault(alice);
        vm.expectRevert(abi.encodeWithSelector(IGEOFRegistry.GEOF_UnknownVersion.selector, pid, uint32(0)));
        reg.versionOf(pid, 0);
        vm.expectRevert(abi.encodeWithSelector(IGEOFRegistry.GEOF_UnknownVersion.selector, pid, uint32(2)));
        reg.versionOf(pid, 2);
    }

    // ------------------------------------------------------------------
    // profiles
    // ------------------------------------------------------------------

    function test_PublishRequiresFrozenVersion() public {
        (bytes32 pid,,) = _openDefault(alice);
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(IGEOFRegistry.GEOF_VersionOpen.selector, pid, uint32(1)));
        reg.publishProfile(pid, 1, H1, 0, "");
    }

    function test_PublishRejectsUnknownVersionAndZeroHash() public {
        (bytes32 pid,,) = _openDefault(alice);
        vm.prank(alice);
        reg.closeProcess(pid, H1, 0);
        vm.expectRevert(abi.encodeWithSelector(IGEOFRegistry.GEOF_UnknownVersion.selector, pid, uint32(0)));
        reg.publishProfile(pid, 0, H1, 0, "");
        vm.expectRevert(abi.encodeWithSelector(IGEOFRegistry.GEOF_UnknownVersion.selector, pid, uint32(2)));
        reg.publishProfile(pid, 2, H1, 0, "");
        vm.expectRevert(IGEOFRegistry.GEOF_ZeroHash.selector);
        reg.publishProfile(pid, 1, 0, 0, "");
    }

    function test_AnyAccountMayPublishAndProfilesCoexist() public {
        (bytes32 pid,,) = _openDefault(alice);
        vm.prank(alice);
        reg.closeProcess(pid, H1, 0);
        bytes32 expectedBob = keccak256(abi.encode(pid, uint32(1), bob, H2));
        vm.expectEmit(true, true, true, true);
        emit IGEOFRegistry.ProfilePublished(expectedBob, pid, 1, bob, H2, 0, "ipfs://bob");
        vm.prank(bob);
        bytes32 pb = reg.publishProfile(pid, 1, H2, 0, "ipfs://bob");
        vm.prank(carol);
        bytes32 pc = reg.publishProfile(pid, 1, H3, 0, "ipfs://carol");
        assertEq(pb, expectedBob);
        assertTrue(pb != pc);
        (bytes32 p, uint32 v, address pub, bytes32 h, bytes32 sup, uint48 at, string memory uri) = reg.profileOf(pc);
        assertEq(p, pid);
        assertEq(v, 1);
        assertEq(pub, carol);
        assertEq(h, H3);
        assertEq(sup, bytes32(0));
        assertEq(at, uint48(1_800_000_000));
        assertEq(uri, "ipfs://carol");
    }

    function test_ObjectHolderCannotBlockThirdPartyProfile() public {
        // alice declared the object and opened the process; bob publishes without any approval step
        (bytes32 pid,,) = _openDefault(alice);
        vm.prank(alice);
        reg.closeProcess(pid, H1, 0);
        vm.prank(bob);
        bytes32 pb = reg.publishProfile(pid, 1, H2, 0, "");
        (,, address pub,,,,) = reg.profileOf(pb);
        assertEq(pub, bob);
    }

    function test_DuplicateProfileReverts() public {
        (bytes32 pid,,) = _openDefault(alice);
        vm.prank(alice);
        reg.closeProcess(pid, H1, 0);
        vm.startPrank(bob);
        bytes32 pb = reg.publishProfile(pid, 1, H2, 0, "");
        vm.expectRevert(abi.encodeWithSelector(IGEOFRegistry.GEOF_DuplicateProfile.selector, pb));
        reg.publishProfile(pid, 1, H2, 0, "again");
        vm.stopPrank();
    }

    function test_ProfileSupersedesSamePublisherSameProcess() public {
        (bytes32 pid,,) = _openDefault(alice);
        vm.prank(alice);
        reg.closeProcess(pid, H1, 0);
        vm.prank(bob);
        bytes32 p1 = reg.publishProfile(pid, 1, H2, 0, "v1");
        // another publisher may not supersede bob's profile
        vm.prank(carol);
        vm.expectRevert(abi.encodeWithSelector(IGEOFRegistry.GEOF_SupersedesMismatch.selector, p1));
        reg.publishProfile(pid, 1, H3, p1, "");
        // unknown supersedes
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(IGEOFRegistry.GEOF_UnknownProfile.selector, H3));
        reg.publishProfile(pid, 1, H3, H3, "");
        // bob supersedes his own
        vm.prank(bob);
        bytes32 p2 = reg.publishProfile(pid, 1, H3, p1, "v2");
        (,,,, bytes32 sup,,) = reg.profileOf(p2);
        assertEq(sup, p1);
    }

    function test_ProfileSupersedesMustBeSameProcess() public {
        (bytes32 pid1,,) = _openDefault(alice);
        (bytes32 pid2,,) = _openDefault(carol);
        vm.prank(alice);
        reg.closeProcess(pid1, H1, 0);
        vm.prank(carol);
        reg.closeProcess(pid2, H1, 0);
        vm.startPrank(bob);
        bytes32 p1 = reg.publishProfile(pid1, 1, H2, 0, "");
        vm.expectRevert(abi.encodeWithSelector(IGEOFRegistry.GEOF_SupersedesMismatch.selector, p1));
        reg.publishProfile(pid2, 1, H3, p1, "");
        vm.stopPrank();
    }

    function test_ProfilesBindToFrozenVersionsAcrossAddenda() public {
        (bytes32 pid,,) = _openDefault(alice);
        vm.startPrank(alice);
        reg.closeProcess(pid, H1, 0);
        reg.openAddendum(pid);
        vm.stopPrank();
        // v1 frozen: publishable; v2 open: not yet
        vm.prank(bob);
        reg.publishProfile(pid, 1, H2, 0, "");
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(IGEOFRegistry.GEOF_VersionOpen.selector, pid, uint32(2)));
        reg.publishProfile(pid, 2, H3, 0, "");
        vm.prank(alice);
        reg.closeProcess(pid, H2, 0);
        vm.prank(bob);
        bytes32 p2 = reg.publishProfile(pid, 2, H3, 0, "");
        (, uint32 v,,,,,) = reg.profileOf(p2);
        assertEq(v, 2);
    }

    function test_UnknownProfileViewReverts() public {
        vm.expectRevert(abi.encodeWithSelector(IGEOFRegistry.GEOF_UnknownProfile.selector, H3));
        reg.profileOf(H3);
    }

    // ------------------------------------------------------------------
    // fuzz
    // ------------------------------------------------------------------

    function testFuzz_DeclarationIdIsDeterministic(uint8 kindRaw, bytes32 h, address who) public {
        vm.assume(h != bytes32(0));
        vm.assume(who != address(0));
        kindRaw = uint8(bound(kindRaw, 1, 5)); // FRAME..METRIC
        IGEOFRegistry.DeclarationKind kind = IGEOFRegistry.DeclarationKind(kindRaw);
        vm.prank(who);
        bytes32 id = reg.declare(kind, h, 0, "");
        assertEq(id, keccak256(abi.encode(kind, who, h)));
    }

    function testFuzz_CommitCountsAccumulate(uint8 n) public {
        n = uint8(bound(n, 1, 40));
        (bytes32 pid,,) = _openDefault(alice);
        for (uint256 i = 0; i < n; i++) {
            vm.prank(bob);
            reg.commitObservations(pid, keccak256(abi.encode(i)), uint64(i + 1), IGEOFRegistry.ObservationKind.EVENT);
        }
        (,, uint64 count,) = reg.versionOf(pid, 1);
        assertEq(count, n);
    }
}
