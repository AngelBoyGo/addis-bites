#!/usr/bin/env bash
set -e

echo "1. Running Contract Tests..."
flutter test test/contract_test.dart

echo "\n2. Running Unit & Role Tests..."
flutter test test/unit_test.dart test/role_router_test.dart

echo "\n3. Running Worker HTTP Shape Tests..."
flutter test test/worker_http_test.dart

echo "\n4. Running Static Analysis..."
flutter analyze lib test

echo "\n=== ALL CONTRACT & QUALITY GATES PASSED ==="
