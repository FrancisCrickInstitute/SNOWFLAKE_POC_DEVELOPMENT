# =============================================================================
# complete_dev.ps1 — Submit development work for TEST
# =============================================================================
# Takes an issue number, then:
#   1. Ensures working tree is clean
#   2. Pushes latest changes
#   3. Creates PR to test/main
#   4. Merges (or shows PR link if insufficient permissions)
#   5. Waits for TEST workflow to complete
# =============================================================================

$ErrorActionPreference = "Stop"

$repoRoot = git rev-parse --show-toplevel

# --- Get issue number ---
$issueId = if ($args.Count -gt 0) { $args[0] } else { Read-Host "Issue number" }

if ($issueId -notmatch '^\d+$') {
    Write-Host "Error: Issue number must be numeric." -ForegroundColor Red
    exit 1
}

# --- Find the feature branch ---
$branch = git branch --list "feature/${issueId}-*" | ForEach-Object { $_.Trim('* ').Trim() } | Select-Object -First 1

if ([string]::IsNullOrEmpty($branch)) {
    Write-Host "Error: No local branch matching feature/${issueId}-*" -ForegroundColor Red
    Write-Host "  Are you in the right repo? Do you have the branch checked out?"
    exit 1
}

Write-Host ""
Write-Host "Complete Development - Issue #$issueId" -ForegroundColor White
Write-Host "  Branch: $branch"
Write-Host ""

# --- Ensure on the correct branch ---
$current = git branch --show-current
if ($current -ne $branch) {
    Write-Host "Switching to $branch..." -ForegroundColor Cyan
    git checkout $branch
}

# --- Check working tree is clean ---
$dirty = git status --porcelain
if ($dirty) {
    Write-Host "Uncommitted changes detected:" -ForegroundColor Yellow
    Write-Host ""
    git status --short
    Write-Host ""
    $choice = Read-Host "  Commit all changes now? [Y/n]"
    if ($choice -eq "n" -or $choice -eq "N") {
        Write-Host "  Aborting. Please commit manually and re-run."
        exit 1
    }
    git add -A
    $branchShort = $branch -replace '.+/', ''
    git commit -m "feat: $branchShort (#$issueId)"
    Write-Host ""
}

# --- Push latest ---
Write-Host "Pushing latest changes..." -ForegroundColor Cyan
git push

# --- Create PR to test/main ---
Write-Host ""
Write-Host "Creating PR to test/main..." -ForegroundColor Cyan
$prOutput = gh pr create --base test/main --head $branch `
    --title "Deploy to TEST (#$issueId)" `
    --body "Issue #${issueId}: Ready for TEST deployment" 2>&1

if ($prOutput -match "already exists") {
    Write-Host "  PR already exists." -ForegroundColor Yellow
    $prUrl = gh pr list --base test/main --head $branch --json url --jq '.[0].url'
} else {
    $prUrl = $prOutput
}
Write-Host "  PR: $prUrl" -ForegroundColor Green

# --- Merge PR ---
Write-Host ""
Write-Host "Merging PR..." -ForegroundColor Cyan
$prNum = gh pr list --base test/main --head $branch --json number --jq '.[0].number'
try {
    gh pr merge --merge --admin --delete-branch=false $prNum 2>$null
    Write-Host "  PR merged successfully." -ForegroundColor Green
} catch {
    Write-Host "  Could not auto-merge (insufficient permissions?)." -ForegroundColor Yellow
    Write-Host "  PR is ready for review: $prUrl"
    Write-Host "  Ask a repo admin to merge, then re-run this script."
    exit 0
}

# --- Wait for TEST workflow ---
Write-Host ""
Write-Host "Waiting for TEST deployment workflow..." -ForegroundColor Cyan
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
            Write-Host "  TEST deployment completed successfully." -ForegroundColor Green
        } else {
            Write-Host "  TEST deployment failed ($conclusion)." -ForegroundColor Red
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
$domainLower = ($branch -replace 'feature/\d+-([a-z]+)-.*', '$1')
$domain = $domainLower.ToUpper()
$testDb = "TEST_${issueId}_${domain}_CORE_DB"

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host "  Development complete!" -ForegroundColor Green
Write-Host ""
Write-Host "  TEST Clone: $testDb"
Write-Host ""
Write-Host "  To promote to UAT: .\scripts\promote.ps1 $issueId uat" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host ""
