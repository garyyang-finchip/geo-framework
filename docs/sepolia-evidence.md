# Sepolia evidence — GEOFRegistry reference deployment

Both worked cases of the specification were executed end to end on Sepolia on 2026-11-14 (UTC) against a fresh `GEOFRegistry`. 43 transactions, blocks 12134766–12134808, all `status = 1`. Machine-readable record: `deployments/sepolia.json`.

## Deployment

| Item | Value |
| --- | --- |
| Network | Sepolia (chain id 11155111) |
| GEOFRegistry | [`0xe725180476760B4012D8Eb9aD1De3337B5e40478`](https://sepolia.etherscan.io/address/0xe725180476760B4012D8Eb9aD1De3337B5e40478) |
| Deployment tx | [`0xe51a9684655ef52ccd82ed2c7bf8eadf0eb0d31f70c64a714892f3d06423d0b0`](https://sepolia.etherscan.io/tx/0xe51a9684655ef52ccd82ed2c7bf8eadf0eb0d31f70c64a714892f3d06423d0b0) (block 12134766) |
| Source | `contracts/GEOFRegistry.sol`, Solidity 0.8.28, optimizer 200 runs, EVM cancun |
| Runtime code | 7,826 bytes |
| Clock | ERC-6372, `mode=timestamp` |

## Accounts

| Account | Address | Roles |
| --- | --- | --- |
| A | `0x87fd31695C1cef8e247967c174E4c6275Eb55FD5` | deployer; panel observer and opener in case A; skill provider and opener in case B |
| B | `0xa036DA636C23b9f7e25d3Fc9E0D24F0467CdE854` | company in case A (objects, intent, publisher-side source, aggregate, late follow-up); independent indexer in case B |
| C | `0x1A7f5E50E81e14BD4254eA33aA58BF1aBaD283C9` | auditor in case A (second publisher on the same frozen version) |

B and C are derived from A's key inside the script and funded by A in the first block. All three are evidence accounts only.

## Case A — web correction notice (wide spread, low fidelity, attainment unknown)

| Record | Id |
| --- | --- |
| Process | `0xc648a9d15bfab71c7ce298a5e4f345f8142d07f5a1098f5ab5a36672a1835ae1` |
| Frame | `0xd9aa6b064154635f95b55a1ecc5ec72f5afe06d40371121d2994441bfc50a5e0` |
| Object (claim) | `0x1d5d2d87334da4dd84527513e8f7d05939622572db9a15f933d3a2e16f0eebd8` |
| Object (page) | `0x7004bfe019b90a23125f8729d1e12f902a7cc0bfb85a15da1598d144a9014e3f` |
| Intent | `0x5c1f35eaedcac0a49d8c8b8305cfb6edc5eb9f446b367b63d9c736ccd9a64fe8` |
| Profile, panel, v1 | `0x600fd9178e1b6b5934ed784bbdf1de070f98728808a80f357f416eb4cf458bb4` |
| Profile, auditor, v1 | `0x752557c4580835338923a1884df5a5ed13ce2ceb2b699a2ec4ac815f3a9d897a` |
| Profile, panel, v2 (supersedes panel v1) | `0xf4aba376199a68135ec00cee2c3b1aff2335019a8d9d3307495e0fca18d27583` |

Walk: B declares two Objects, the Intent and its log Source; A declares the Frame, two Sources and four Methods and opens the Process; A commits four weekly `EVENT` batches (360 each), B commits one `AGGREGATE`; A freezes version 1; A and C each publish a Profile against v1; A opens an addendum, B commits a late `FOLLOWUP` batch (40), A freezes version 2 and publishes a second Profile that supersedes its first. The auditor's v1 Profile is untouched.

State read back at block 12134808: version 1 — 5 commitments, frozen, evidence root `0x8bf6713ecc4b0d17e5cfe7347eae32f60059eab433bb2b73163eec295804eb24`; version 2 — 1 commitment, frozen, evidence root `0xcb770e1beb32184e042fdc467f2d79e0a02ce67b985ed2c35c72ebbdc419fc39`; current version 2, closed; `profileOf(panel v2).supersedes == panel v1`.

## Case B — agentic skill (narrow reach, full fidelity, full attainment)

| Record | Id |
| --- | --- |
| Process | `0x80277a1a8b0a74daa3d0682fd2f4744993aaddcca2435a187c387491fe330af4` |
| Frame | `0xc67e01be6f2b827ecf721fef43ca46ef2cb43bed9118959113fd06433adc6122` |
| Object (skill) | `0xf0208dd5fab77bc4a2e546eef8ec42af98ba2c2021b9b6af41ee1e743dbdef2a` |
| Intent | `0x4616b8a570f9dd57ac719854bffe07891a3bf48ea26c8c0d3799489876ef9c4b` |
| Profile, provider, v1 | `0xdc7a29a11b62e81d99b39d6796384a9ecc0ecdfca022a17ba2cfe465faa63bfe` |
| Profile, indexer, v1 | `0x4d8bd78666a33a6fc87f7a1796790135ed8cd548f26ef48291a9b382d356131f` |

Walk: A declares the skill Object, Intent, Frame, three Sources and three Methods, opens the Process and commits the discovery `EVENT` batch (11) and the gateway `AGGREGATE`; B commits the three settlements as a `FOLLOWUP` batch; A freezes version 1 and publishes; B publishes its own Profile against the same frozen version.

State read back at block 12134808: version 1 — 3 commitments, frozen, evidence root `0x808c3c30479256e561dc28b3176f5253c327aeb818952a29674e19eb390a8d9a`; current version 1, closed.

## Transactions

Total gas 35,774,901; total paid 0.000894373630384415 ETH.

| # | Phase | Sender | Function | Tx | Block | Gas used |
| --- | --- | --- | --- | --- | --- | --- |
| 0 | deploy-and-fund | A | `deploy` | [0xe51a9684…23d0b0](https://sepolia.etherscan.io/tx/0xe51a9684655ef52ccd82ed2c7bf8eadf0eb0d31f70c64a714892f3d06423d0b0) | 12134766 | 12,310,042 |
| 1 | deploy-and-fund | A | `transfer` | [0xe8784723…96a629](https://sepolia.etherscan.io/tx/0xe8784723795293c66321ba868cb0721a86acfe0d267c95bd13e72c754696a629) | 12134767 | 204,600 |
| 2 | deploy-and-fund | A | `transfer` | [0xae17ab90…7838de](https://sepolia.etherscan.io/tx/0xae17ab9005307eeb42e3e5a95b04279c74da63cf39196e7f6663f8a0f87838de) | 12134768 | 204,600 |
| 3 | case-a | B | `declareObject` | [0xefd5a962…e7457d](https://sepolia.etherscan.io/tx/0xefd5a962834d0e844999a86c97925cd676a1b6b6c2187f40ae452bef50e7457d) | 12134769 | 798,025 |
| 4 | case-a | B | `declareObject` | [0xc5a02f9b…a7e9b6](https://sepolia.etherscan.io/tx/0xc5a02f9b9d187d254c19b6c8a17aa9983ac4dee5f472074ca5c8193083a7e9b6) | 12134770 | 798,025 |
| 5 | case-a | B | `declare` | [0x848f42e4…1ed2cd](https://sepolia.etherscan.io/tx/0x848f42e411235fa27628dd41ff66d19583e91f771ee8639f382806c0f61ed2cd) | 12134771 | 685,961 |
| 6 | case-a | B | `declare` | [0x7ad707fe…675f50](https://sepolia.etherscan.io/tx/0x7ad707fef5af263afe8accf9a182e94d9111ee7047e5110dff46de7a37675f50) | 12134772 | 686,009 |
| 7 | case-a | A | `declare` | [0xcf24e203…da0702](https://sepolia.etherscan.io/tx/0xcf24e2030da3534baaa55c36535e456fa195cf9a8a3177ab07fe4d01ddda0702) | 12134773 | 685,961 |
| 8 | case-a | A | `declare` | [0x97e6f24d…348d42](https://sepolia.etherscan.io/tx/0x97e6f24dbbbee1405729d7f3e39840cc983262cf77f3a7c0147dacbe84348d42) | 12134774 | 686,009 |
| 9 | case-a | A | `declare` | [0x49aa6ee8…d578b1](https://sepolia.etherscan.io/tx/0x49aa6ee80407a00fe0057d8a49149ddfa77cea79bb85bab3b2fdb1eeb8d578b1) | 12134775 | 686,009 |
| 10 | case-a | A | `declare` | [0x32412cb1…86b3a1](https://sepolia.etherscan.io/tx/0x32412cb1995e904126cfb5d1e3f852290ac197c8b633ba2a62af87a5b386b3a1) | 12134776 | 685,997 |
| 11 | case-a | A | `declare` | [0x773afb9d…f0d670](https://sepolia.etherscan.io/tx/0x773afb9d7435aea0f9955a9ff34f9356d7c7a0065864b8dcc4f4e43d25f0d670) | 12134777 | 686,009 |
| 12 | case-a | A | `declare` | [0x1305dd0f…d240d7](https://sepolia.etherscan.io/tx/0x1305dd0f4869882b99c8986078efc4dc484f5c72d5c795286e0f82b6dcd240d7) | 12134778 | 686,009 |
| 13 | case-a | A | `declare` | [0x6ca4f2c2…879e19](https://sepolia.etherscan.io/tx/0x6ca4f2c2230760683cb8474e7c0724d2b26d4405a7da8bfce8ecd4ff11879e19) | 12134779 | 686,009 |
| 14 | case-a | A | `openProcess` | [0x6c8c853d…8f95c0](https://sepolia.etherscan.io/tx/0x6c8c853d1aa23ba8ecaf0e82d0dcbfe754e04f926c67ba265ba1ea6b208f95c0) | 12134780 | 2,064,011 |
| 15 | case-a | A | `commitObservations` | [0x33a188c9…94bdd0](https://sepolia.etherscan.io/tx/0x33a188c95eecf67706183eea75cd47743808fa5672fbce39d32926dea094bdd0) | 12134781 | 132,818 |
| 16 | case-a | A | `commitObservations` | [0xf59c996a…389df8](https://sepolia.etherscan.io/tx/0xf59c996a0c7c71992d5d5e11c22ccefb7d33d3257605d86139701b6b13389df8) | 12134782 | 34,886 |
| 17 | case-a | A | `commitObservations` | [0xa92a809f…5e9237](https://sepolia.etherscan.io/tx/0xa92a809f1475e49e8f88ebbc660fe83daa75815a471a5a588f16b30d865e9237) | 12134783 | 34,898 |
| 18 | case-a | A | `commitObservations` | [0xdfda9f24…96c481](https://sepolia.etherscan.io/tx/0xdfda9f24892386727b45a5d9062ae5c755a23326b715356af8fc94634d96c481) | 12134784 | 34,898 |
| 19 | case-a | B | `commitObservations` | [0xefaca057…9a190c](https://sepolia.etherscan.io/tx/0xefaca057cdcdcc31fdb8617ab014ec7167700763ebe5d706e18740aae59a190c) | 12134785 | 34,898 |
| 20 | case-a | A | `closeProcess` | [0x7d14ca12…ffb812](https://sepolia.etherscan.io/tx/0x7d14ca125dbe796bcc01b089b14d4f36c40e46d5f7cefbd3b5b122b791ffb812) | 12134786 | 145,717 |
| 21 | case-a | A | `publishProfile` | [0x3bde5ee1…35d754](https://sepolia.etherscan.io/tx/0x3bde5ee14b643f82026dba8be32adb104d05bc2794cc3f346a0ec7fd8d35d754) | 12134787 | 801,175 |
| 22 | case-a | C | `publishProfile` | [0x1004fa3d…ab2cf0](https://sepolia.etherscan.io/tx/0x1004fa3d6b23fcd8db0bd81f29ac710ca68e4d964d72c5f7105ad3fee3ab2cf0) | 12134788 | 801,271 |
| 23 | case-a | A | `openAddendum` | [0x9c9fa6c8…936da0](https://sepolia.etherscan.io/tx/0x9c9fa6c87b21fd05ce746a22cf0a542ad7d7a202adf11b3afe7e36ec55936da0) | 12134789 | 34,545 |
| 24 | case-a | B | `commitObservations` | [0x534804e2…5899ad](https://sepolia.etherscan.io/tx/0x534804e20b6c52b8fdce3ab5995369438a35330b785be54fefa8e7c2c35899ad) | 12134790 | 132,818 |
| 25 | case-a | A | `closeProcess` | [0x0194185d…6b91d4](https://sepolia.etherscan.io/tx/0x0194185d72a0c1a652a0b6c8d6ac5df708eca1353381e2a6573681a5ce6b91d4) | 12134791 | 145,729 |
| 26 | case-a | A | `publishProfile` | [0xace04be1…b04856](https://sepolia.etherscan.io/tx/0xace04be1b5c4e019a6d88e0f874890e57e19b1a114e7cdcdbf97e249c2b04856) | 12134792 | 916,025 |
| 27 | case-b | A | `declareObject` | [0x6d1c72eb…c57abf](https://sepolia.etherscan.io/tx/0x6d1c72eb755b3a33db215ce69bbf1bcbe66fb61643ac70610c4bf6a439c57abf) | 12134793 | 798,013 |
| 28 | case-b | A | `declare` | [0x1bb98073…e942bb](https://sepolia.etherscan.io/tx/0x1bb980732a5767023c7fa3d98a5253bf802bb6756f644da7f70482126ee942bb) | 12134794 | 685,961 |
| 29 | case-b | A | `declare` | [0x230c9c23…7c5b6d](https://sepolia.etherscan.io/tx/0x230c9c239757e19e436f513bc0d6aa63d378dacc7196a54f00782a26a17c5b6d) | 12134795 | 685,949 |
| 30 | case-b | A | `declare` | [0xdc988013…d3a5ac](https://sepolia.etherscan.io/tx/0xdc98801370284ca6e9086b416b9b23f7cac75ae95a28cd23251b076e80d3a5ac) | 12134796 | 685,985 |
| 31 | case-b | A | `declare` | [0xcc2e40ba…c533e6](https://sepolia.etherscan.io/tx/0xcc2e40ba6f01348a2987773ec66abd8ea175f9ab2b3682accfd2f6d033c533e6) | 12134797 | 685,997 |
| 32 | case-b | A | `declare` | [0x11344da0…413b78](https://sepolia.etherscan.io/tx/0x11344da0f5609d3b1bcd9a6e1c887368cfbbc8432720797db133071982413b78) | 12134798 | 685,997 |
| 33 | case-b | A | `declare` | [0x5a7dbf0b…c85026](https://sepolia.etherscan.io/tx/0x5a7dbf0bb23baad28d9e94ee9eae4b53e977d50c77a0a4b3b97fb717a1c85026) | 12134799 | 685,997 |
| 34 | case-b | A | `declare` | [0xc56f0764…36383c](https://sepolia.etherscan.io/tx/0xc56f076483f20631461ce42e894259e3c60f15ce06cf7200dd485f89d036383c) | 12134800 | 685,997 |
| 35 | case-b | A | `declare` | [0xaf2cf0a3…eb79a4](https://sepolia.etherscan.io/tx/0xaf2cf0a3652cf61b925cee566aa8508b5f73b9a021949893365c74bbcdeb79a4) | 12134801 | 685,997 |
| 36 | case-b | A | `openProcess` | [0x685b3b45…905acb](https://sepolia.etherscan.io/tx/0x685b3b454c054d24d59da5a60197b196140dd7b68f4b5fe8af0c12a32b905acb) | 12134802 | 1,735,325 |
| 37 | case-b | A | `commitObservations` | [0x4b71aca4…2ee244](https://sepolia.etherscan.io/tx/0x4b71aca456d8807e509200f079d278e6ca5d4d0a38e71fa4ed5fed08b62ee244) | 12134803 | 132,806 |
| 38 | case-b | A | `commitObservations` | [0xe39054ab…8f8bfb](https://sepolia.etherscan.io/tx/0xe39054ab525036113a49ba2a81c318b72b17d00690c61b9acc171bf2ce8f8bfb) | 12134804 | 34,898 |
| 39 | case-b | B | `commitObservations` | [0xd1ac9cfd…4db91e](https://sepolia.etherscan.io/tx/0xd1ac9cfd081787aa5b01d9c3dddd8f02906bd8efc7aaa1e0f16a27ce764db91e) | 12134805 | 34,874 |
| 40 | case-b | A | `closeProcess` | [0x97cf2091…d42360](https://sepolia.etherscan.io/tx/0x97cf2091a44e91eed0581afef15b90e3c60e7d5c707a6e6cb04af52d25d42360) | 12134806 | 145,729 |
| 41 | case-b | A | `publishProfile` | [0xb252700b…f9fa54](https://sepolia.etherscan.io/tx/0xb252700bfac3d2d17dcbdb177428a8c4a7b9e1909332cf2b3688819a7cf9fa54) | 12134807 | 801,163 |
| 42 | case-b | B | `publishProfile` | [0x83de84dd…b6d5cc](https://sepolia.etherscan.io/tx/0x83de84ddb340f40da61b17afe8988923bd4bd54af972fdb72d4fc1175bb6d5cc) | 12134808 | 801,259 |

## Observations from the run

- Sepolia charged between 1.0x and 9.7x the gas the same transactions used on a local anvil (deployment 12,310,042 vs 1,745,392; a `declare` about 686,000 vs 164,000). Gas limits must come from live estimation; `scripts/evidence-run.sh sepolia` runs with `--skip-simulation` for that reason.
- Every id on Sepolia equals the id produced by the local replay with the same deployer key, because declaration ids, process ids and profile ids depend only on kind, account, content hash, frame and per-account nonce — never on block time (decision N6 in `docs/decision-log.md`).

## Reproduce the reads

```bash
R=0xe725180476760B4012D8Eb9aD1De3337B5e40478
PA=0xc648a9d15bfab71c7ce298a5e4f345f8142d07f5a1098f5ab5a36672a1835ae1
PB=0x80277a1a8b0a74daa3d0682fd2f4744993aaddcca2435a187c387491fe330af4
cast call $R "processOf(bytes32)(address,bytes32,uint32,bool)" $PA --rpc-url $SEPOLIA_RPC_URL
cast call $R "versionOf(bytes32,uint32)(bytes32,uint48,uint64,bool)" $PA 1 --rpc-url $SEPOLIA_RPC_URL
cast call $R "versionOf(bytes32,uint32)(bytes32,uint48,uint64,bool)" $PA 2 --rpc-url $SEPOLIA_RPC_URL
cast call $R "versionOf(bytes32,uint32)(bytes32,uint48,uint64,bool)" $PB 1 --rpc-url $SEPOLIA_RPC_URL
cast call $R "profileOf(bytes32)(bytes32,uint32,address,bytes32,bytes32,uint48,string)" 0xf4aba376199a68135ec00cee2c3b1aff2335019a8d9d3307495e0fca18d27583 --rpc-url $SEPOLIA_RPC_URL
cast call $R "supportsInterface(bytes4)(bool)" 0xda287a1d --rpc-url $SEPOLIA_RPC_URL
```

Source verification (Sourcify, no API key):

```bash
forge verify-contract --chain sepolia --verifier sourcify $R contracts/GEOFRegistry.sol:GEOFRegistry
```
