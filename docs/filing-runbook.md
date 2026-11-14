# Filing runbook — ethereum/ERCs

Order of operations, in the sequence that has worked for the earlier proposals in this line.

## 1. Repository

1. Create the public repository `geo-framework` (CC0-1.0 via GitHub's license picker).
2. Upload the package contents through the web UI, keeping the directory layout. Nested dotfiles (`.gitmodules`, `.gitignore`) must be added one by one with "Create new file" — the folder uploader drops them.
3. Do not upload `lib/`, `out/`, `cache/`, `broadcast/` or `tools/node_modules/`. A fresh clone rebuilds them:

```bash
git clone https://github.com/garyyang-finchip/geo-framework
cd geo-framework
forge install foundry-rs/forge-std
forge test
cd tools && npm ci && cd ..
node tools/geof.js case assets/erc-9999/examples/case-a-web-correction/case.json
```

## 2. Ethereum Magicians

1. Post `docs/magicians-post.md` in the ERCs category with the title it carries.
2. Copy the topic URL. It becomes `discussions-to`.

## 3. Filing package

```bash
python3 -I scripts/make-filing-package.py --discussions-to https://ethereum-magicians.org/t/<slug>/<id>
```

This writes `ercs-pr-package/ERCS/erc-9999.md` and `ercs-pr-package/assets/erc-9999/**` (17 files) and lints them: no CJK, description ≤ 140 characters, no inline code span containing `eip-9999`, no directory-style asset links, every linked asset present, external links only to the allow-list. Also apply the same `discussions-to` line to `ERCS/erc-9999.md` in the repository.

## 4. Branch

The branch must be cut from `ethereum/ERCs` master, never from the fork's master (which carries the ERC-8338 history).

1. On `github.com/ethereum/ERCs`, open `ERCS/`, choose "Add file → Create new file", name it `ERCS/erc-9999.md`, paste the package's ERC text, and choose "Propose changes". GitHub creates the branch in the fork from upstream master — rename `patch-N` to `add-erc-geo-framework` before continuing.
2. Verify the base with the compare URL: the branch must differ from `ethereum/ERCs:master` by exactly the package files.
3. Upload `assets/erc-9999/**` on that branch (folder uploads, keeping paths). Confirm the ERC file sits at `ERCS/erc-9999.md`, not at the repository root.

## 5. Pull request

- Title: `Add ERC: Generative Engine Optimization Framework`
- Body: one paragraph from the Magicians summary, the Magicians link, the repository link. No attribution trailers.
- Expected CI: EIP Walidator (eipw), Markdown Linter, HTMLProofer. The three red "Markdown Linter" annotations that appear on every ERC PR are the workflow's own grep bug, not findings.
- After CI is green, put the PR link into the Magicians first post ("ERC pull request: …").

## 6. Number assignment

When an editor assigns a number N in a review conversation on the ERC file:

```bash
python3 -I scripts/make-filing-package.py --number N --discussions-to <topic URL>
```

Replace the branch's `ERCS/erc-9999.md` and `assets/erc-9999/` with the renumbered files (`ERCS/erc-N.md`, `assets/erc-N/`), delete the 9999 files, re-run CI, then reply inside the editor's conversation and resolve it. Rename the Magicians topic to `ERC-N: Generative Engine Optimization Framework`. Mirror the renumbering into the repository.

## 7. Evidence

Run `docs/sepolia-runbook.md` in parallel; once `deployments/sepolia.json` exists, add the registry address to the README table and post the evidence reply on the Magicians thread.
