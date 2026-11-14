#!/usr/bin/env bash
# Evidence run driver: anvil rehearsal or Sepolia.
#   scripts/evidence-run.sh anvil
#   scripts/evidence-run.sh sepolia      (needs SEPOLIA_RPC_URL and DEPLOYER_PK in the environment, e.g. from ~/geof.env)
set -euo pipefail
cd "$(dirname "$0")/.."
NET="${1:-anvil}"
if [ "$NET" = "anvil" ]; then
  anvil --silent --port 8545 &
  ANVIL=$!
  trap 'kill $ANVIL 2>/dev/null || true' EXIT
  sleep 1
  export DEPLOYER_PK=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
  NETWORK=anvil forge script script/EvidenceRun.s.sol --rpc-url http://127.0.0.1:8545 --broadcast -vv
elif [ "$NET" = "sepolia" ]; then
  : "${SEPOLIA_RPC_URL:?set SEPOLIA_RPC_URL}"
  : "${DEPLOYER_PK:?set DEPLOYER_PK}"
  BAL=$(cast balance --rpc-url "$SEPOLIA_RPC_URL" "$(cast wallet address --private-key "$DEPLOYER_PK")")
  echo "deployer balance: $BAL wei"
  if [ "$BAL" = "0" ]; then echo "deployer is unfunded"; exit 1; fi
  # --skip-simulation: Sepolia's gas schedule differs from the local estimate (see docs/sepolia-runbook.md)
  NETWORK=sepolia forge script script/EvidenceRun.s.sol --rpc-url "$SEPOLIA_RPC_URL" --broadcast --skip-simulation -vv
else
  echo "usage: $0 anvil|sepolia"; exit 2
fi
