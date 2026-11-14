// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {GEOFRegistry} from "../contracts/GEOFRegistry.sol";
import {IGEOFRegistry} from "../contracts/interfaces/IGEOFRegistry.sol";

/// @notice Ties the Solidity id derivations to the vectors in assets/erc-9999/vectors/vectors.json
///         (built by tools/geof.js). The expected values are written out here so the test is self-contained.
contract VectorsTest is Test {
    GEOFRegistry internal reg;

    function setUp() public {
        reg = new GEOFRegistry();
    }

    function test_SubjectIdVectors() public pure {
        assertEq(
            keccak256("claim:example.com:warranty-correction-2026-10"),
            0x218830d41525a8cc55a22cc008a9af9b5b323861dcf5a9dba950d9e9290407be
        );
        assertEq(
            keccak256("content:example.com:/notices/warranty-correction"),
            0x141a89f70943b33aae98e8c533f418b73c6ee87e7a28eee2f49e13d2b37d4e35
        );
        assertEq(
            keccak256("caip19:eip155:11155111:erc721:0x8338000000000000000000000000000000000001/42"),
            0x61e9e8198037099f9e23259a635015d175ba0b0931bca3277f32e560f0b71339
        );
    }

    function test_DeclarationIdVector() public {
        // contentHash = keccak256('{"a":1}') ; kind = FRAME (1) ; declarant = 0x2222...2222
        bytes32 h = keccak256(bytes('{"a":1}'));
        assertEq(h, 0x25e7c2a96531eb50246780c1f25742e489bf55210e26981dc02992bb585feb97);
        address who = 0x2222222222222222222222222222222222222222;
        vm.prank(who);
        bytes32 id = reg.declare(IGEOFRegistry.DeclarationKind.FRAME, h, 0, "");
        assertEq(id, 0x63e896c7b07a742ec2b46a06cf40acd1396b1e62c8bbcd46b17110bba182a195);
    }

    function test_ProfileIdVector() public pure {
        bytes32 h = keccak256(bytes('{"b":2}'));
        assertEq(h, 0x39c6eef0731b991fda8c1165ce3ca386371f943806e05306e0394d74d165a623);
        bytes32 pid = 0x7000000000000000000000000000000000000000000000000000000000000a01;
        bytes32 id = keccak256(abi.encode(pid, uint32(1), 0x2222222222222222222222222222222222222222, h));
        assertEq(id, 0xfe992dd35a73050fed34911d62ff377cb2ecf07b19ec216a6e834df7673b1211);
    }
}
