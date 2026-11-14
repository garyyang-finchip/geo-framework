#!/usr/bin/env python3
"""Build the ethereum/ERCs filing package for GEOF.

    python3 scripts/make-filing-package.py                 # placeholder 9999 -> ercs-pr-package/
    python3 scripts/make-filing-package.py --number 8512   # renumbered package (after the editor assigns a number)
    python3 scripts/make-filing-package.py --discussions-to https://ethereum-magicians.org/t/...  (patch the preamble)

Steps:
  1. sync assets/erc-9999/contracts/ from contracts/ (interface + reference registry are byte-identical)
  2. copy ERCS/erc-9999.md and assets/erc-9999/** into ercs-pr-package/ under the target number
  3. rewrite number-bearing paths and the preamble `eip:` line
  4. lint: no CJK characters, description <= 140 chars, no backticks around eip-N IRIs,
     no directory-style asset links, asset links only as ../assets/eip-N/<file>, every linked asset exists

Run from the repository root with -I to ignore any planted modules.
"""
import argparse
import os
import re
import shutil
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC_NUM = "9999"
SKIP_DIRS = {"node_modules", "__pycache__"}


def sync_contracts():
    pairs = [
        ("contracts/interfaces/IGEOFRegistry.sol", "assets/erc-9999/contracts/interfaces/IGEOFRegistry.sol"),
        ("contracts/GEOFRegistry.sol", "assets/erc-9999/contracts/GEOFRegistry.sol"),
    ]
    for src, dst in pairs:
        s, d = os.path.join(ROOT, src), os.path.join(ROOT, dst)
        os.makedirs(os.path.dirname(d), exist_ok=True)
        shutil.copyfile(s, d)
    return [p[1] for p in pairs]


def copy_tree(src, dst):
    for dirpath, dirnames, filenames in os.walk(src):
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS]
        rel = os.path.relpath(dirpath, src)
        out_dir = os.path.join(dst, rel) if rel != "." else dst
        os.makedirs(out_dir, exist_ok=True)
        for f in filenames:
            shutil.copyfile(os.path.join(dirpath, f), os.path.join(out_dir, f))


def rewrite_number(text, number):
    text = text.replace(f"eip: {SRC_NUM}", f"eip: {number}")
    text = text.replace(f"../assets/eip-{SRC_NUM}/", f"../assets/eip-{number}/")
    text = text.replace(f"EIPS/eip-{SRC_NUM}#", f"EIPS/eip-{number}#")
    return text


def lint(erc_path, assets_root, number):
    problems = []
    text = open(erc_path, encoding="utf-8").read()
    if re.search("[\\u4e00-\\u9fff]", text):
        problems.append("CJK characters in ERC text")
    m = re.search(r"^description: (.*)$", text, re.M)
    if not m:
        problems.append("missing description")
    elif len(m.group(1)) > 140:
        problems.append(f"description is {len(m.group(1))} chars (> 140)")
    if re.search(rf"`[^`\n]*eip-{number}[^`\n]*`", text):
        problems.append(f"inline code span containing eip-{number} (eipw markdown-no-backticks)")
    for link in re.findall(r"\]\(([^)]+)\)", text):
        if link.startswith("../assets/"):
            if link.endswith("/"):
                problems.append(f"directory-style asset link: {link}")
                continue
            if not link.startswith(f"../assets/eip-{number}/"):
                problems.append(f"asset link with wrong number: {link}")
                continue
            rel = link[len(f"../assets/eip-{number}/"):]
            if not os.path.exists(os.path.join(assets_root, rel)):
                problems.append(f"linked asset missing: {link}")
        elif link.startswith("./eip-"):
            pass
        elif link.startswith("http"):
            if not re.match(r"https://(www\.rfc-editor\.org|ethereum-magicians\.org|eips\.ethereum\.org)/", link):
                problems.append(f"external link outside the allow-list: {link}")
        elif link.startswith("../LICENSE.md"):
            pass
        else:
            problems.append(f"unexpected link: {link}")
    for dirpath, _, filenames in os.walk(assets_root):
        for f in filenames:
            p = os.path.join(dirpath, f)
            if os.path.getsize(p) == 0:
                problems.append(f"empty asset file: {os.path.relpath(p, ROOT)}")
            try:
                if re.search("[\\u4e00-\\u9fff]", open(p, encoding="utf-8").read()):
                    problems.append(f"CJK characters in asset {os.path.relpath(p, ROOT)}")
            except UnicodeDecodeError:
                pass
    return problems


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--number", default=SRC_NUM)
    ap.add_argument("--discussions-to", default=None)
    ap.add_argument("--out", default="ercs-pr-package")
    args = ap.parse_args()
    number = args.number

    synced = sync_contracts()
    out = os.path.join(ROOT, args.out)
    if os.path.isdir(out):
        shutil.rmtree(out)
    os.makedirs(os.path.join(out, "ERCS"))
    erc_src = os.path.join(ROOT, "ERCS", f"erc-{SRC_NUM}.md")
    erc_dst = os.path.join(out, "ERCS", f"erc-{number}.md")
    text = rewrite_number(open(erc_src, encoding="utf-8").read(), number)
    if args.discussions_to:
        text = re.sub(r"^discussions-to: .*$", f"discussions-to: {args.discussions_to}", text, flags=re.M)
    open(erc_dst, "w", encoding="utf-8").write(text)

    assets_dst = os.path.join(out, "assets", f"erc-{number}")
    copy_tree(os.path.join(ROOT, "assets", f"erc-{SRC_NUM}"), assets_dst)
    ctx = os.path.join(assets_dst, "contexts", "geof.jsonld")
    if os.path.exists(ctx):
        ctx_text = open(ctx, encoding="utf-8").read()  # read fully before opening for write
        with open(ctx, "w", encoding="utf-8") as fh:
            fh.write(rewrite_number(ctx_text, number))

    problems = lint(erc_dst, assets_dst, number)
    count = sum(len(f) for _, _, f in os.walk(out))
    print(f"synced {len(synced)} contract files into assets")
    print(f"filing package: {os.path.relpath(out, ROOT)} ({count} files, number {number})")
    if problems:
        print("LINT FAILED:")
        for p in problems:
            print("  -", p)
        sys.exit(1)
    print("lint: ok")


if __name__ == "__main__":
    main()
