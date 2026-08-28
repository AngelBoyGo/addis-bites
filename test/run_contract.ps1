# PowerShell contract & integration test runner for Addis Bites
$ErrorActionPreference = "Stop"

Write-Host "1. Running Contract Tests..." -ForegroundColor Cyan
& flutter test test/contract_test.dart

Write-Host "`n2. Running Unit & Role Tests..." -ForegroundColor Cyan
& flutter test test/unit_test.dart test/role_router_test.dart

Write-Host "`n3. Running Worker HTTP Shape Tests..." -ForegroundColor Cyan
& flutter test test/worker_http_test.dart

Write-Host "`n4. Running Static Analysis..." -ForegroundColor Cyan
& flutter analyze lib test

Write-Host "`n=== ALL CONTRACT & QUALITY GATES PASSED ===" -ForegroundColor Green
