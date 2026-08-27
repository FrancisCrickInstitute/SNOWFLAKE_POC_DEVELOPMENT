#!/bin/bash
# =============================================================================
# dcm-sqlfluff-lint.sh — Pre-commit hook for linting DCM definition files
# =============================================================================
# Strips DCM-specific syntax (DEFINE TABLE/VIEW/DYNAMIC TABLE) so sqlfluff
# can parse and lint the SQL body.
#
# For DEFINE VIEW / DEFINE DYNAMIC TABLE: extracts the body after "as"
# For DEFINE TABLE: skips (pure DDL, nothing to lint)
# For plain SQL (ALTER, GRANT, etc.): passes through unchanged
# =============================================================================

set -euo pipefail

LINT_DIR=$(mktemp -d)
trap 'rm -rf "$LINT_DIR"' EXIT

EXIT_CODE=0
FILES="${@}"

if [[ -z "$FILES" ]]; then
  echo "Usage: $0 <file1.sql> [file2.sql ...]"
  exit 0
fi

for FILE in $FILES; do
  [[ -f "$FILE" ]] || continue

  FIRST_LINE=$(head -1 "$FILE" | tr '[:lower:]' '[:upper:]')
  BASENAME=$(basename "$FILE")
  TEMP_FILE="${LINT_DIR}/${BASENAME}"

  if [[ "$FIRST_LINE" == DEFINE\ TABLE* ]]; then
    # Pure DDL — nothing to lint
    continue

  elif [[ "$FIRST_LINE" == DEFINE\ VIEW* ]] || [[ "$FIRST_LINE" == DEFINE\ DYNAMIC\ TABLE* ]]; then
    # Extract everything after the first line ending in "as" (case-insensitive)
    awk '
      BEGIN { found = 0 }
      found { print; next }
      tolower($0) ~ /[[:space:]]as[[:space:]]*$/ || tolower($0) ~ /^as$/ { found = 1; next }
    ' "$FILE" > "$TEMP_FILE"

    if [[ ! -s "$TEMP_FILE" ]]; then
      continue
    fi

  elif [[ "$FIRST_LINE" == ALTER* ]] || [[ "$FIRST_LINE" == GRANT* ]] || [[ "$FIRST_LINE" == --* ]]; then
    # Plain SQL or comments — pass through
    cp "$FILE" "$TEMP_FILE"

  else
    # Unknown format — skip
    continue
  fi

  # Replace Jinja template variables with dummy identifiers
  sed -i '' \
    -e 's/{{db}}/LINT_DB/g' \
    -e 's/{{transform_wh}}/LINT_WH/g' \
    -e 's/{{reporting_wh}}/LINT_WH/g' \
    -e 's/{{ingest_wh}}/LINT_WH/g' \
    -e 's/{{dev_wh}}/LINT_WH/g' \
    -e 's/{{env}}/DEV/g' \
    -e 's/{{[^}]*}}/LINT_PLACEHOLDER/g' \
    "$TEMP_FILE"

  # Run sqlfluff lint — only check keyword capitalisation (CP01)
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  if ! sqlfluff lint "$TEMP_FILE" --config "${SCRIPT_DIR}/.sqlfluff" --rules CP01 --nocolor 2>/dev/null; then
    echo ""
    echo "  Linting errors in: $FILE"
    echo ""
    EXIT_CODE=1
  fi
done

exit $EXIT_CODE
