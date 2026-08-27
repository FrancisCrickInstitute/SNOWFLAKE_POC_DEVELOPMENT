# =============================================================================
# promote.ps1 — Promote code to the next environment
# =============================================================================
# Usage: .\scripts\promote.ps1 <issue_number> <target>
#
# Valid targets:
#   uat       (promotes from test/main -> uat/main)
#   preprod   (promotes from uat/main -> preprod/main)
#   prod      (promotes from preprod/main -> prod/main)
# =============================================================================

$ErrorActionPreference = "Stop"

$repoRoot = git rev-parse --show-toplevel

# --- Validate arguments ---
$issueId = if ($args.Count -gt 0) { $args[0] } else { "" }
$target = if ($args.Count -gt 1) { $args[1] } else { "" }

if ([string]::IsNullOrEmpty($issueId) -or [string]::IsNullOrEmpty($target)) {
    Write-Host ""
    Write-Host "Usage: .\scripts\promote.ps1 <issue_number> <target>" -ForegroundColor White
    Write-Host ""
    Write-Host "  Valid targets:"
    Write-Host "    uat       (from TEST)"
    Write-Host "    preprod   (from UAT)"
    Write-Host "    prod      (from PREPROD)"
    Write-Host ""
    Write-Host "  Example: .\scripts\promote.ps1 55 uat"
    Write-Host ""
    exit 1
}

if ($issueId -notmatch '^\d+$') {
    Write-Host "Error: Issue number must be numeric." -ForegroundColor Red
    exit 1
}

$targetLower = $target.ToLower()
$targetUpper = $target.ToUpper()

# Derive source from target
switch ($targetLower) {
    "uat"     { $sourceLower = "test";    $sourceUpper = "TEST" }
    "preprod" { $sourceLower = "uat";     $sourceUpper = "UAT" }
    "prod"    { $sourceLower = "preprod"; $sourceUpper = "PREPROD" }
    default {
        Write-Host "Error: Invalid target '$target'." -ForegroundColor Red
        Write-Host "  Valid targets: uat, preprod, prod"
        exit 1
    }
}

Write-Host ""
Write-Host "Promote: $sourceUpper -> $targetUpper (issue #$issueId)" -ForegroundColor White
Write-Host ""

# --- Create PR ---
Write-Host "Creating PR: ${sourceLower}/main -> ${targetLower}/main..." -ForegroundColor Cyan
$prOutput = gh pr create --base "${targetLower}/main" --head "${sourceLower}/main" `
    --title "Promote to $targetUpper (#$issueId)" `
    --body "Issue #${issueId}: Promoting approved code from $sourceUpper to $targetUpper" 2>&1

if ($prOutput -match "No commits between") {
    Write-Host "Error: Nothing to promote - ${sourceLower}/main has no new commits vs ${targetLower}/main." -ForegroundColor Red
    Write-Host "  Did you skip a step? The pipeline is: test -> uat -> preprod -> prod"
    exit 1
}

if ($prOutput -match "already exists") {
    Write-Host "  PR already exists." -ForegroundColor Yellow
    $prUrl = gh pr list --base "${targetLower}/main" --head "${sourceLower}/main" --json url --jq '.[0].url'
} else {
    $prUrl = $prOutput
}
Write-Host "  PR: $prUrl" -ForegroundColor Green

# --- Merge PR ---
Write-Host ""
Write-Host "Merging PR..." -ForegroundColor Cyan
$prNum = gh pr list --base "${targetLower}/main" --head "${sourceLower}/main" --json number --jq '.[0].number'

try {
    gh pr merge --merge --admin --delete-branch=false $prNum 2>$null
    Write-Host "  PR merged successfully." -ForegroundColor Green
} catch {
    Write-Host "  Could not auto-merge (insufficient permissions?)." -ForegroundColor Yellow
    Write-Host "  PR is ready for review: $prUrl"
    Write-Host "  Ask a repo admin to approve and merge."
    exit 0
}

# --- Wait for workflow ---
Write-Host ""
Write-Host "Waiting for $targetUpper deployment workflow..." -ForegroundColor Cyan
Start-Sleep -Seconds 5
$runId = gh run list --limit 1 --json databaseId --jq '.[0].databaseId'
Write-Host "  Workflow run ID: $runId"

$maxWait = 300
$elapsed = 0
while ($elapsed -lt $maxWait) {
    $status = gh run view $runId --json status --jq '.status'
    if ($status -eq "completed") {
        $conclusion = gh run view $runId --json conclusion --jq '.conclusion'
        if ($conclusion -eq "success") {
            Write-Host "  $targetUpper deployment completed successfully." -ForegroundColor Green
        } else {
            Write-Host "  $targetUpper deployment failed ($conclusion)." -ForegroundColor Red
            Write-Host "  Check: gh run view $runId --log-failed"
        }
        break
    }
    Start-Sleep -Seconds 10
    $elapsed += 10
    Write-Host "  ... $status (${elapsed}s)"
}

if ($elapsed -ge $maxWait) {
    Write-Host "  Workflow still running after ${maxWait}s. Check manually." -ForegroundColor Yellow
}

# --- Summary ---
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host "  Promotion complete: $sourceUpper -> $targetUpper" -ForegroundColor Green
Write-Host ""

switch ($targetLower) {
    "uat"     { Write-Host "  Next: .\scripts\promote.ps1 $issueId preprod" -ForegroundColor Cyan }
    "preprod" { Write-Host "  Next: .\scripts\promote.ps1 $issueId prod" -ForegroundColor Cyan }
    "prod"    {
        Write-Host "  Code is now in production. Clones will be cleaned up automatically." -ForegroundColor Green
        Write-Host ""
        # Merge prod/main back into main so it stays current
        Write-Host "Syncing main with prod/main..." -ForegroundColor Cyan
        git checkout main
        git pull
        git merge origin/prod/main --no-edit
        git push
        Write-Host "  main is now up to date." -ForegroundColor Green
        # Clean up the feature branch
        $featureBranch = git branch --list "feature/${issueId}-*" | ForEach-Object { $_.Trim('* ').Trim() } | Select-Object -First 1
        if ($featureBranch) {
            Write-Host ""
            Write-Host "Deleting feature branch: $featureBranch" -ForegroundColor Cyan
            git branch -D $featureBranch
            git push origin --delete $featureBranch 2>$null
        }
    }
}
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host ""
