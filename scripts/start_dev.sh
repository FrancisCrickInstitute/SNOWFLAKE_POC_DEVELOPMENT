#!/bin/bash
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"

# =============================================================================
# start_dev.sh — Begin a new development task
# =============================================================================
# Prompts for domain and description, then:
#   1. Creates a GitHub issue
#   2. Creates and pushes a feature branch
#   3. Waits for WIP clone to be auto-created by CI/CD
#   4. Prints summary with issue number and clone name
# =============================================================================

BOLD='\033[1m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
RESET='\033[0m'

# --- Validate domain ---
VALID_DOMAINS=()
for d in "${REPO_ROOT}"/domains/*/; do
  [[ -d "$d" ]] && VALID_DOMAINS+=("$(basename "$d" | tr '[:lower:]' '[:upper:]')")
done

if [[ ${#VALID_DOMAINS[@]} -eq 0 ]]; then
  echo -e "${RED}Error: No domains found in domains/ folder.${RESET}"
  exit 1
fi

echo ""
echo -e "${BOLD}Start Development Task${RESET}"
echo ""
echo -e "${YELLOW}Available domains:${RESET} ${VALID_DOMAINS[*]}"
echo ""
read -rp "Domain: " DOMAIN_INPUT
DOMAIN=$(echo "$DOMAIN_INPUT" | tr '[:lower:]' '[:upper:]')

DOMAIN_VALID=false
for d in "${VALID_DOMAINS[@]}"; do
  if [[ "$d" == "$DOMAIN" ]]; then
    DOMAIN_VALID=true
    break
  fi
done

if [[ "$DOMAIN_VALID" != "true" ]]; then
  echo -e "${RED}Error: '${DOMAIN_INPUT}' is not a valid domain.${RESET}"
  echo "  Valid domains: ${VALID_DOMAINS[*]}"
  exit 1
fi

DOMAIN_LOWER=$(echo "$DOMAIN" | tr '[:upper:]' '[:lower:]')

# --- Get description ---
echo ""
read -rp "Description of the change: " DESCRIPTION

if [[ -z "$DESCRIPTION" ]]; then
  echo -e "${RED}Error: Description cannot be empty.${RESET}"
  exit 1
fi

# Slugify description for branch name
SLUG=$(echo "$DESCRIPTION" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//' | cut -c1-40)

# --- Ensure we're on main and up to date ---
echo ""
echo -e "${CYAN}Switching to main and pulling latest...${RESET}"
git checkout main && git pull

# --- Create issue ---
echo ""
echo -e "${CYAN}Creating GitHub issue...${RESET}"
ISSUE_URL=$(gh issue create --title "Deploy ${DOMAIN}: ${DESCRIPTION}" \
  --body "Domain: ${DOMAIN}\nDescription: ${DESCRIPTION}" \
  --assignee @me)
ISSUE_ID=$(echo "$ISSUE_URL" | grep -oE '[0-9]+$')
echo -e "${GREEN}  Issue #${ISSUE_ID} created${RESET}"

# --- Create and push feature branch ---
BRANCH="feature/${ISSUE_ID}-${DOMAIN_LOWER}-${SLUG}"
echo ""
echo -e "${CYAN}Creating branch: ${BRANCH}${RESET}"
git checkout -b "$BRANCH"
git push -u origin "$BRANCH"

# --- Wait for WIP clone workflow ---
echo ""
echo -e "${CYAN}Waiting for WIP clone to be created by CI/CD...${RESET}"
sleep 5
WIP_RUN=$(gh run list --workflow=create-wip-clone.yml --limit 1 --json databaseId --jq '.[0].databaseId')
echo "  Workflow run ID: ${WIP_RUN}"

MAX_WAIT=120
ELAPSED=0
while [[ $ELAPSED -lt $MAX_WAIT ]]; do
  STATUS=$(gh run view "$WIP_RUN" --json status --jq '.status')
  if [[ "$STATUS" == "completed" ]]; then
    CONCLUSION=$(gh run view "$WIP_RUN" --json conclusion --jq '.conclusion')
    if [[ "$CONCLUSION" == "success" ]]; then
      echo -e "  ${GREEN}WIP clone created successfully.${RESET}"
    else
      echo -e "  ${RED}WIP clone workflow failed (${CONCLUSION}).${RESET}"
      echo "  Check: gh run view ${WIP_RUN} --log-failed"
    fi
    break
  fi
  sleep 5
  ELAPSED=$((ELAPSED + 5))
  echo "  ... ${STATUS} (${ELAPSED}s)"
done

if [[ $ELAPSED -ge $MAX_WAIT ]]; then
  echo -e "${YELLOW}  Workflow still running after ${MAX_WAIT}s. Check manually.${RESET}"
fi

# --- Summary ---
WIP_DB="WIP_${ISSUE_ID}_${DOMAIN}_CORE_DB"
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${GREEN}  Ready to develop!${RESET}"
echo ""
echo -e "  Issue:      ${BOLD}#${ISSUE_ID}${RESET}"
echo -e "  Branch:     ${BOLD}${BRANCH}${RESET}"
echo -e "  WIP Clone:  ${BOLD}${WIP_DB}${RESET}"
echo ""
echo -e "  When done, run: ${CYAN}./scripts/complete_dev.sh ${ISSUE_ID}${RESET}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
