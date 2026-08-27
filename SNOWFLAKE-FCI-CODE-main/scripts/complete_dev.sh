#!/bin/bash
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"

# =============================================================================
# complete_dev.sh — Submit development work for TEST
# =============================================================================
# Takes an issue number, then:
#   1. Ensures working tree is clean
#   2. Pushes latest changes
#   3. Creates PR to test/main
#   4. Merges (or shows PR link if insufficient permissions)
#   5. Waits for TEST workflow to complete
# =============================================================================

BOLD='\033[1m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
RESET='\033[0m'

# --- Get issue number ---
ISSUE_ID="${1:-}"
if [[ -z "$ISSUE_ID" ]]; then
  read -rp "Issue number: " ISSUE_ID
fi

if [[ ! "$ISSUE_ID" =~ ^[0-9]+$ ]]; then
  echo -e "${RED}Error: Issue number must be numeric.${RESET}"
  exit 1
fi

# --- Find the feature branch ---
BRANCH=$(git branch --list "feature/${ISSUE_ID}-*" | sed 's/^[* ]*//' | head -1)

if [[ -z "$BRANCH" ]]; then
  echo -e "${RED}Error: No local branch matching feature/${ISSUE_ID}-*${RESET}"
  echo "  Are you in the right repo? Do you have the branch checked out?"
  exit 1
fi

echo ""
echo -e "${BOLD}Complete Development — Issue #${ISSUE_ID}${RESET}"
echo -e "  Branch: ${BRANCH}"
echo ""

# --- Ensure on the correct branch ---
CURRENT=$(git branch --show-current)
if [[ "$CURRENT" != "$BRANCH" ]]; then
  echo -e "${CYAN}Switching to ${BRANCH}...${RESET}"
  git checkout "$BRANCH"
fi

# --- Check working tree is clean ---
if [[ -n "$(git status --porcelain)" ]]; then
  echo -e "${YELLOW}Uncommitted changes detected:${RESET}"
  echo ""
  git status --short
  echo ""
  read -rp "  Commit all changes now? [Y/n] " choice
  if [[ "$choice" == "n" || "$choice" == "N" ]]; then
    echo "  Aborting. Please commit manually and re-run."
    exit 1
  fi
  git add -A
  git commit -m "feat: ${BRANCH##*/} (#${ISSUE_ID})"
  echo ""
fi

# --- Push latest ---
echo -e "${CYAN}Pushing latest changes...${RESET}"
git push

# --- Create PR to test/main ---
echo ""
echo -e "${CYAN}Creating PR to test/main...${RESET}"
PR_URL=$(gh pr create --base test/main --head "$BRANCH" \
  --title "Deploy to TEST (#${ISSUE_ID})" \
  --body "Issue #${ISSUE_ID}: Ready for TEST deployment" 2>&1) || true

if echo "$PR_URL" | grep -q "already exists"; then
  echo -e "${YELLOW}  PR already exists.${RESET}"
  PR_URL=$(gh pr list --base test/main --head "$BRANCH" --json url --jq '.[0].url')
fi
echo -e "  ${GREEN}PR: ${PR_URL}${RESET}"

# --- Merge PR ---
echo ""
echo -e "${CYAN}Merging PR...${RESET}"
PR_NUM=$(gh pr list --base test/main --head "$BRANCH" --json number --jq '.[0].number')
if gh pr merge --merge --admin --delete-branch=false "$PR_NUM" 2>/dev/null; then
  echo -e "  ${GREEN}PR merged successfully.${RESET}"
else
  echo -e "${YELLOW}  Could not auto-merge (insufficient permissions?).${RESET}"
  echo "  PR is ready for review: ${PR_URL}"
  echo "  Ask a repo admin to merge, then re-run this script."
  exit 0
fi

# --- Wait for TEST workflow ---
echo ""
echo -e "${CYAN}Waiting for TEST deployment workflow...${RESET}"
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
      echo -e "  ${GREEN}TEST deployment completed successfully.${RESET}"
    else
      echo -e "  ${RED}TEST deployment failed (${CONCLUSION}).${RESET}"
      echo "  Check: gh run view ${RUN_ID} --log-failed"
      exit 1
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
# Extract domain from branch name
DOMAIN_LOWER=$(echo "$BRANCH" | sed -E "s|feature/[0-9]+-([a-z]+)-.*|\1|")
DOMAIN=$(echo "$DOMAIN_LOWER" | tr '[:lower:]' '[:upper:]')
TEST_DB="TEST_${ISSUE_ID}_${DOMAIN}_CORE_DB"

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${GREEN}  Development complete!${RESET}"
echo ""
echo -e "  TEST Clone: ${BOLD}${TEST_DB}${RESET}"
echo ""
echo -e "  To promote to UAT: ${CYAN}./scripts/promote.sh ${ISSUE_ID} uat${RESET}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
