#!/usr/bin/env bash
set -euo pipefail

# Oracle-integrity guard for the autonomous agent.
# It permits additions to tests but rejects common forms of weakening.
diff="$(git diff --unified=0 HEAD --   '.github/workflows/*.yml'   '.github/actions/**/*.yml'   'tests/**'   'scripts/compare*'   'scripts/validate*'   'scripts/run_mame*' || true)"

if grep -E '^[+-]' <<<"$diff" | grep -E '^\+.*(continue-on-error:[[:space:]]*true|\|\|[[:space:]]*true|exit[[:space:]]+0[[:space:]]*#.*pass|pytest[[:space:]]+-k[[:space:]]+not|skip.*test)' >/dev/null; then
  echo "TEST_ORACLE_WEAKENED"
  exit 20
fi

# Existing hard failure thresholds may not be increased silently.
if git diff --unified=0 HEAD -- scripts/validate_visual_anchors.py scripts/compare_visual_frames.py |
   grep -E '^-' | grep -E 'MAX_|THRESHOLD|threshold|ratio|mae' >/dev/null; then
  echo "VISUAL_ORACLE_THRESHOLD_CHANGED"
  exit 21
fi

echo "TEST_ORACLE_INTEGRITY_OK"
