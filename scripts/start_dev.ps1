# =============================================================================
# start_dev.ps1 — Begin a new development task
# =============================================================================
# Prompts for domain and description, then:
#   1. Creates a GitHub issue
#   2. Creates and pushes a feature branch
#   3. Waits for WIP clone to be auto-created by CI/CD
#   4. Prints summary with issue number and clone name
# =============================================================================

$ErrorActionPreference = "Stop"

$repoRoot = git rev-parse --show-toplevel

# --- Validate domain ---
$validDomains = Get-ChildItem -Directory "$repoRoot/domains" | ForEach-Object { $_.Name.ToUpper() }

if ($validDomains.Count -eq 0) {
    Write-Host "Error: No domains found in domains/ folder." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Start Development Task" -ForegroundColor White
Write-Host ""
Write-Host "Available domains: $($validDomains -join ', ')" -ForegroundColor Yellow
Write-Host ""
$domainInput = Read-Host "Domain"
$domain = $domainInput.ToUpper()

if ($domain -notin $validDomains) {
    Write-Host "Error: '$domainInput' is not a valid domain." -ForegroundColor Red
    Write-Host "  Valid domains: $($validDomains -join ', ')"
    exit 1
}

$domainLower = $domain.ToLower()

# --- Get description ---
Write-Host ""
$description = Read-Host "Description of the change"

if ([string]::IsNullOrWhiteSpace($description)) {
    Write-Host "Error: Description cannot be empty." -ForegroundColor Red
    exit 1
}

# Slugify description for branch name
$slug = $description.ToLower() -replace '[^a-z0-9]', '-' -replace '-+', '-' -replace '^-|-$', ''
if ($slug.Length -gt 40) { $slug = $slug.Substring(0, 40) }

# --- Ensure we're on main and up to date ---
Write-Host ""
Write-Host "Switching to main and pulling latest..." -ForegroundColor Cyan
git checkout main
git pull

# --- Create issue ---
Write-Host ""
Write-Host "Creating GitHub issue..." -ForegroundColor Cyan
$issueUrl = gh issue create --title "Deploy ${domain}: ${description}" `
    --body "Domain: ${domain}`nDescription: ${description}" `
    --assignee "@me"
$issueId = ($issueUrl -split '/')[-1]
Write-Host "  Issue #$issueId created" -ForegroundColor Green

# --- Create and push feature branch ---
$branch = "feature/${issueId}-${domainLower}-${slug}"
Write-Host ""
Write-Host "Creating branch: $branch" -ForegroundColor Cyan
git checkout -b $branch
git push -u origin $branch

# --- Wait for WIP clone workflow ---
Write-Host ""
Write-Host "Waiting for WIP clone to be created by CI/CD..." -ForegroundColor Cyan
Start-Sleep -Seconds 5
$wipRun = gh run list --workflow=create-wip-clone.yml --limit 1 --json databaseId --jq '.[0].databaseId'
Write-Host "  Workflow run ID: $wipRun"

$maxWait = 120
$elapsed = 0
while ($elapsed -lt $maxWait) {
    $status = gh run view $wipRun --json status --jq '.status'
    if ($status -eq "completed") {
        $conclusion = gh run view $wipRun --json conclusion --jq '.conclusion'
        if ($conclusion -eq "success") {
            Write-Host "  WIP clone created successfully." -ForegroundColor Green
        } else {
            Write-Host "  WIP clone workflow failed ($conclusion)." -ForegroundColor Red
            Write-Host "  Check: gh run view $wipRun --log-failed"
        }
        break
    }
    Start-Sleep -Seconds 5
    $elapsed += 5
    Write-Host "  ... $status (${elapsed}s)"
}

if ($elapsed -ge $maxWait) {
    Write-Host "  Workflow still running after ${maxWait}s. Check manually." -ForegroundColor Yellow
}

# --- Summary ---
$wipDb = "WIP_${issueId}_${domain}_CORE_DB"
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host "  Ready to develop!" -ForegroundColor Green
Write-Host ""
Write-Host "  Issue:      #$issueId"
Write-Host "  Branch:     $branch"
Write-Host "  WIP Clone:  $wipDb"
Write-Host ""
Write-Host "  When done, run: .\scripts\complete_dev.ps1 $issueId" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host ""
