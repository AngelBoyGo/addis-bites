# Addis Bites Worker — D1 provision + deploy.
# Requires a logged-in wrangler (`npx wrangler login`).
# Run from the worker/ directory:
#   pwsh ./deploy.ps1
#
# Steps (idempotent where possible):
#   1. Ensures the D1 database exists.
#   2. Applies schema.sql.
#   3. Sets database_id in wrangler.toml.
#   4. Installs production secrets (AUTH_SECRET, CHAPA_WEBHOOK_SECRET, and
#      optionally TELEBIRR_API_KEY / DEMO_WEBHOOK).
#   5. Deploys the Worker.
#
# Secrets are read from environment variables / prompted; do NOT commit them.

$ErrorActionPreference = "Stop"
$dbName = "addis-bites-db"
$to = "wrangler.toml"
$ok = $true

Write-Host "==> Checking prerequisites" -ForegroundColor Cyan
if (-not (Get-Command npx -ErrorAction SilentlyContinue)) { Write-Host "npx not found" -ForegroundColor Red; $ok = $false }
if (-not (Test-Path "schema.sql")) { Write-Host "Run from the worker/ directory (schema.sql missing)" -ForegroundColor Red; $ok = $false }
if (-not $ok) { exit 1 }

Write-Host "==> Ensuring D1 database '$dbName' exists" -ForegroundColor Cyan
$list = npx wrangler d1 list 2>$null
if (-not ($list -match [regex]::Escape($dbName))) {
  npx wrangler d1 create $dbName
} else {
  Write-Host "database '$dbName' already exists"
}

Write-Host "==> Applying schema.sql" -ForegroundColor Cyan
npx wrangler d1 execute $dbName --file=./schema.sql

Write-Host "==> Resolving database_id into wrangler.toml" -ForegroundColor Cyan
$id = (npx wrangler d1 info $dbName 2>$null | Select-String "database_id\s*[:=]\s*(\S+)").Matches.Groups[1].Value
if (-not $id) {
  Write-Host "Could not auto-read database_id; open wrangler.toml and replace the placeholder manually." -ForegroundColor Yellow
} else {
  $t = Get-Content $to -Raw
  $t = $t -replace 'database_id = "[^"]*"', "database_id = `"$id`""
  Set-Content $to $t
  Write-Host "database_id set to $id"
}

Write-Host "==> Installing secrets" -ForegroundColor Cyan
foreach ($name in @("AUTH_SECRET", "CHAPA_WEBHOOK_SECRET")) {
  $val = [Environment]::GetEnvironmentVariable($name)
  if (-not $val) { $val = Read-Host "Provide A value for $name (leave blank to skip)" }
  if ($val) {
    $val | npx wrangler secret put $name
  } else {
    Write-Host "skipping $name (not provided)" -ForegroundColor Yellow
  }
}

$useDemoWebhook = Read-Host "Set DEMO_WEBHOOK=1 for dev webhook testing? (y/N)"
if ($useDemoWebhook -match "^[Yy]") { "1" | npx wrangler secret put DEMO_WEBHOOK }

Write-Host "==> Deploying" -ForegroundColor Cyan
npx wrangler deploy

Write-Host "Done." -ForegroundColor Green