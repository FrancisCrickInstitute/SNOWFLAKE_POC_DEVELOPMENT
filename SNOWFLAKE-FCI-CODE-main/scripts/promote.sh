#!/bin/bash
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"

# =============================================================================
# promote.sh — Promote code to the next environment
# =============================================================================
# Usage: ./scripts/promote.sh <issue_number> <target>
#
# Valid targets:
#   uat       (promotes from test/main → uat/main)
#   preprod   (promotes from uat/main → preprod/main)
#   prod      (promotes from preprod/main → prod/main)
# =============================================================================

BOLD='\033[1m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
RESET='\033[0m'

# --- Validate arguments ---
ISSUE_ID="${1:-}"
TARGET="${2:-}"

if [[ -z "$ISSUE_ID" || -z "$TARGET" ]]; then
  echo ""
  echo -e "${BOLD}Usage:${RESET} ./scripts/promote.sh <issue_number> <target>"
  echo ""
  echo "  Valid targets:"
  echo "    uat       (from TEST)"
  echo "    preprod   (from UAT)"
  echo "    prod      (from PREPROD)"
  echo ""
  echo "  Example: ./scripts/promote.sh 55 uat"
  echo ""
  exit 1
fi

if [[ ! "$ISSUE_ID" =~ ^[0-9]+$ ]]; then
  echo -e "${RED}Error: Issue number must be numeric.${RESET}"
  exit 1
fi

TARGET_LOWER=$(echo "$TARGET" | tr '[:upper:]' '[:lower:]')
TARGET_UPPER=$(echo "$TARGET" | tr '[:lower:]' '[:upper:]')

# Derive source from target
case "$TARGET_LOWER" in
  uat)     SOURCE_LOWER="test";    SOURCE_UPPER="TEST" ;;
  preprod) SOURCE_LOWER="uat";     SOURCE_UPPER="UAT" ;;
  prod)    SOURCE_LOWER="preprod"; SOURCE_UPPER="PREPROD" ;;
  *)
    echo -e "${RED}Error: Invalid target '${TARGET}'.${RESET}"
    echo "  Valid targets: uat, preprod, prod"
    exit 1
    ;;
esac

echo ""
echo -e "${BOLD}Promote: ${SOURCE_UPPER} → ${TARGET_UPPER} (issue #${ISSUE_ID})${RESET}"
echo ""

# --- Create PR ---
echo -e "${CYAN}Creating PR: ${SOURCE_LOWER}/main → ${TARGET_LOWER}/main...${RESET}"
PR_URL=$(gh pr create --base "${TARGET_LOWER}/main" --head "${SOURCE_LOWER}/main" \
  --title "Promote to ${TARGET_UPPER} (#${ISSUE_ID})" \
  --body "Issue #${ISSUE_ID}: Promoting approved code from ${SOURCE_UPPER} to ${TARGET_UPPER}" 2>&1) || true

if echo "$PR_URL" | grep -q "No commits between"; then
  echo -e "${RED}Error: Nothing to promote — ${SOURCE_LOWER}/main has no new commits vs ${TARGET_LOWER}/main.${RESET}"
  echo "  Did you skip a step? The pipeline is: test → uat → preprod → prod"
  exit 1
fi

if echo "$PR_URL" | grep -q "already exists"; then
  echo -e "${YELLOW}  PR already exists.${RESET}"
  PR_URL=$(gh pr list --base "${TARGET_LOWER}/main" --head "${SOURCE_LOWER}/main" --json url --jq '.[0].url')
fi
echo -e "  ${GREEN}PR: ${PR_URL}${RESET}"

# --- Merge PR ---
echo ""
echo -e "${CYAN}Merging PR...${RESET}"
PR_NUM=$(gh pr list --base "${TARGET_LOWER}/main" --head "${SOURCE_LOWER}/main" --json number --jq '.[0].number')

if gh pr merge --merge --admin --delete-branch=false "$PR_NUM" 2>/dev/null; then
  echo -e "  ${GREEN}PR merged successfully.${RESET}"
else
  echo -e "${YELLOW}  Could not auto-merge (insufficient permissions?).${RESET}"
  echo "  PR is ready for review: ${PR_URL}"
  echo "  Ask a repo admin to approve and merge."
  exit 0
fi

# --- Wait for workflow ---
echo ""
echo -e "${CYAN}Waiting for ${TARGET_UPPER} deployment workflow...${RESET}"
sleep 5
RUN_ID=$(gh run list --limit 1 --json databaseId --jq '.[0].databaseId')
echo "  Workflow run ID: ${RUN_ID}"

MAX_WAIT=300
ELAPSED=0
while [[ $ELAPSED -lt $MAX_WAIT ]]; do
  STATUS=$(gh run view "$RUN_ID" --json status --jq '.status')
  if [[ "$STATUS" == "completed" ]]; then
    CONCLUSION=$(gh run view "$RUN_ID" --json conclusion --jq '.conclusion')
    if [[ "$CONCLUSION" == "success" ]]; then
      echo -e "  ${GREEN}${TARGET_UPPER} deployment completed successfully.${RESET}"
    else
      echo -e "  ${RED}${TARGET_UPPER} deployment failed (${CONCLUSION}).${RESET}"
      echo "  Check: gh run view ${RUN_ID} --log-failed"
    fi
    break
  fi
  sleep 10
  ELAPSED=$((ELAPSED + 10))
  echo "  ... ${STATUS} (${ELAPSED}s)"
done

if [[ $ELAPSED -ge $MAX_WAIT ]]; then
  echo -e "${YELLOW}  Workflow still running after ${MAX_WAIT}s. Check manually.${RESET}"
fi

# --- Summary ---
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${GREEN}  Promotion complete: ${SOURCE_UPPER} → ${TARGET_UPPER}${RESET}"
echo ""

case "$TARGET_LOWER" in
  uat)
    echo -e "  Next: ${CYAN}./scripts/promote.sh ${ISSUE_ID} preprod${RESET}"
    ;;
  preprod)
    echo -e "  Next: ${CYAN}./scripts/promote.sh ${ISSUE_ID} prod${RESET}"
    ;;
  prod)
    echo -e "  ${GREEN}Code is now in production. Clones will be cleaned up automatically.${RESET}"
    echo ""
    # Merge prod/main back into main so it stays current
    echo -e "${CYAN}Syncing main with prod/main...${RESET}"
    git checkout main && git pull
    git merge origin/prod/main --no-edit && git push
    echo -e "  ${GREEN}main is now up to date.${RESET}"
    # Clean up the feature branch
    FEATURE_BRANCH=$(git branch --list "feature/${ISSUE_ID}-*" | sed 's/^[* ]*//')
    if [[ -n "$FEATURE_BRANCH" ]]; then
      echo ""
      echo -e "${CYAN}Deleting feature branch: ${FEATURE_BRANCH}${RESET}"
      git branch -D "$FEATURE_BRANCH"
      git push origin --delete "$FEATURE_BRANCH" 2>/dev/null || true
    fi
    ;;
esac
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
