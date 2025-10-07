#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Tests the authentication flow end-to-end
.DESCRIPTION
    This script tests:
    - User registration
    - User login
    - Token-based authentication
    - Profile retrieval
    - Token refresh
    - Password reset request
.EXAMPLE
    .\Test-AuthFlow.ps1
.EXAMPLE
    .\Test-AuthFlow.ps1 -BaseUrl "http://localhost:8000"
#>

param(
    [string]$BaseUrl = "http://localhost:8000",
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"

# Colors for output
function Write-Success { param($Message) Write-Host "✓ $Message" -ForegroundColor Green }
function Write-Failure { param($Message) Write-Host "✗ $Message" -ForegroundColor Red }
function Write-Info { param($Message) Write-Host "ℹ $Message" -ForegroundColor Cyan }
function Write-Step { param($Message) Write-Host "`n=== $Message ===" -ForegroundColor Yellow }

# Test counter
$script:TestsPassed = 0
$script:TestsFailed = 0

function Test-Endpoint {
    param(
        [string]$Name,
        [scriptblock]$Test
    )

    try {
        Write-Info "Testing: $Name"
        & $Test
        $script:TestsPassed++
        Write-Success "PASSED: $Name"
        return $true
    }
    catch {
        $script:TestsFailed++
        Write-Failure "FAILED: $Name"
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
        if ($Verbose) {
            Write-Host "  Details: $($_.Exception)" -ForegroundColor DarkRed
        }
        return $false
    }
}

# Generate unique test data
$timestamp = Get-Date -Format "yyyyMMddHHmmss"
$username = "testuser_$timestamp"
$email = "test_${timestamp}@example.com"
$password = "TestPass123"
$script:accessToken = $null
$script:refreshToken = $null
$script:userId = $null

Write-Step "Starting Authentication Flow Tests"
Write-Info "Base URL: $BaseUrl"
Write-Info "Test User: $username"
Write-Info "Test Email: $email"

# Test 1: Backend Health Check
Test-Endpoint "Backend Health Check" {
    $response = Invoke-RestMethod -Uri "$BaseUrl/health" -Method GET -TimeoutSec 5
    if ($response.status -ne "healthy") {
        throw "Backend is not healthy: $($response.status)"
    }
}

# Test 2: Register New User
Test-Endpoint "User Registration" {
    $body = @{
        username = $username
        email = $email
        password = $password
    } | ConvertTo-Json

    $response = Invoke-RestMethod `
        -Uri "$BaseUrl/api/v1/auth/register" `
        -Method POST `
        -ContentType "application/json" `
        -Body $body

    if (-not $response.id) {
        throw "No user ID returned"
    }
    if ($response.username -ne $username) {
        throw "Username mismatch: expected $username, got $($response.username)"
    }
    if ($response.email -ne $email) {
        throw "Email mismatch: expected $email, got $($response.email)"
    }
    if ($response.is_active -ne $true) {
        throw "User is not active"
    }

    $script:userId = $response.id
    Write-Info "  User ID: $($response.id)"
}

# Test 3: Login
Test-Endpoint "User Login" {
    $body = @{
        username_or_email = $username
        password = $password
    } | ConvertTo-Json

    $response = Invoke-RestMethod `
        -Uri "$BaseUrl/api/v1/auth/login" `
        -Method POST `
        -ContentType "application/json" `
        -Body $body

    if (-not $response.access_token) {
        throw "No access token returned"
    }
    if (-not $response.refresh_token) {
        throw "No refresh token returned"
    }
    if ($response.token_type -ne "bearer") {
        throw "Invalid token type: $($response.token_type)"
    }

    $script:accessToken = $response.access_token
    $script:refreshToken = $response.refresh_token
    Write-Info "  Access token: $($response.access_token.Substring(0, 20))..."
    Write-Info "  Refresh token: $($response.refresh_token.Substring(0, 20))..."
}

# Test 4: Login with Email
Test-Endpoint "Login with Email" {
    $body = @{
        username_or_email = $email
        password = $password
    } | ConvertTo-Json

    $response = Invoke-RestMethod `
        -Uri "$BaseUrl/api/v1/auth/login" `
        -Method POST `
        -ContentType "application/json" `
        -Body $body

    if (-not $response.access_token) {
        throw "No access token returned"
    }
}

# Test 5: Get User Profile (Authenticated)
Test-Endpoint "Get User Profile" {
    $headers = @{
        "Authorization" = "Bearer $($script:accessToken)"
    }

    $response = Invoke-RestMethod `
        -Uri "$BaseUrl/api/v1/users/me" `
        -Method GET `
        -Headers $headers

    if ($response.id -ne $script:userId) {
        throw "User ID mismatch: expected $($script:userId), got $($response.id)"
    }
    if ($response.username -ne $username) {
        throw "Username mismatch"
    }
    if ($response.email -ne $email) {
        throw "Email mismatch"
    }

    Write-Info "  Profile retrieved for: $($response.username)"
}

# Test 6: Get User Profile without Token (Should Fail)
Test-Endpoint "Unauthorized Access Blocked" {
    try {
        $response = Invoke-RestMethod `
            -Uri "$BaseUrl/api/v1/users/me" `
            -Method GET `
            -ErrorAction Stop

        throw "Expected 401 Unauthorized but request succeeded"
    }
    catch {
        if ($_.Exception.Response.StatusCode.value__ -ne 401) {
            throw "Expected 401 Unauthorized, got: $($_.Exception.Response.StatusCode.value__)"
        }
        # This is expected - unauthorized access was blocked
    }
}

# Test 7: Refresh Token
Test-Endpoint "Token Refresh" {
    $body = @{
        refresh_token = $script:refreshToken
    } | ConvertTo-Json

    $response = Invoke-RestMethod `
        -Uri "$BaseUrl/api/v1/auth/refresh" `
        -Method POST `
        -ContentType "application/json" `
        -Body $body

    if (-not $response.access_token) {
        throw "No new access token returned"
    }
    if (-not $response.refresh_token) {
        throw "No new refresh token returned"
    }

    # Update tokens
    $oldAccessToken = $script:accessToken
    $script:accessToken = $response.access_token
    $script:refreshToken = $response.refresh_token

    # Verify old and new tokens are different
    if ($oldAccessToken -eq $script:accessToken) {
        throw "New access token is the same as old token"
    }

    Write-Info "  New access token: $($response.access_token.Substring(0, 20))..."
}

# Test 8: Get User Preferences
Test-Endpoint "Get User Preferences" {
    $headers = @{
        "Authorization" = "Bearer $($script:accessToken)"
    }

    $response = Invoke-RestMethod `
        -Uri "$BaseUrl/api/v1/users/me/preferences" `
        -Method GET `
        -Headers $headers

    if ($null -eq $response) {
        throw "No preferences returned"
    }

    Write-Info "  Preferences retrieved successfully"
}

# Test 9: Update User Preferences
Test-Endpoint "Update User Preferences" {
    $headers = @{
        "Authorization" = "Bearer $($script:accessToken)"
    }

    $body = @{
        theme = "dark"
        daily_xp_goal = 100
    } | ConvertTo-Json

    $response = Invoke-RestMethod `
        -Uri "$BaseUrl/api/v1/users/me/preferences" `
        -Method PATCH `
        -Headers $headers `
        -ContentType "application/json" `
        -Body $body

    if ($response.theme -ne "dark") {
        throw "Theme not updated"
    }
    if ($response.daily_xp_goal -ne 100) {
        throw "Daily XP goal not updated"
    }

    Write-Info "  Preferences updated: theme=dark, daily_xp_goal=100"
}

# Test 10: Request Password Reset
Test-Endpoint "Password Reset Request" {
    $body = @{
        email = $email
    } | ConvertTo-Json

    $response = Invoke-RestMethod `
        -Uri "$BaseUrl/api/v1/auth/password-reset/request" `
        -Method POST `
        -ContentType "application/json" `
        -Body $body

    if (-not $response.message) {
        throw "No message returned"
    }

    Write-Info "  Reset requested for: $email"
    Write-Info "  Response: $($response.message)"
}

# Test 11: Invalid Login (Wrong Password)
Test-Endpoint "Invalid Login Blocked" {
    $body = @{
        username_or_email = $username
        password = "WrongPassword123"
    } | ConvertTo-Json

    try {
        $response = Invoke-RestMethod `
            -Uri "$BaseUrl/api/v1/auth/login" `
            -Method POST `
            -ContentType "application/json" `
            -Body $body `
            -ErrorAction Stop

        throw "Expected 401 Unauthorized but login succeeded with wrong password"
    }
    catch {
        if ($_.Exception.Response.StatusCode.value__ -ne 401) {
            throw "Expected 401 Unauthorized, got: $($_.Exception.Response.StatusCode.value__)"
        }
        # This is expected - wrong password was rejected
    }
}

# Test 12: Duplicate Username (Should Fail)
Test-Endpoint "Duplicate Username Rejected" {
    $body = @{
        username = $username  # Same username
        email = "different_$email"
        password = $password
    } | ConvertTo-Json

    try {
        $response = Invoke-RestMethod `
            -Uri "$BaseUrl/api/v1/auth/register" `
            -Method POST `
            -ContentType "application/json" `
            -Body $body `
            -ErrorAction Stop

        throw "Expected 400 Bad Request but duplicate username was accepted"
    }
    catch {
        if ($_.Exception.Response.StatusCode.value__ -ne 400) {
            throw "Expected 400 Bad Request, got: $($_.Exception.Response.StatusCode.value__)"
        }
        # This is expected - duplicate username was rejected
    }
}

# Test 13: Logout
Test-Endpoint "User Logout" {
    $headers = @{
        "Authorization" = "Bearer $($script:accessToken)"
    }

    $response = Invoke-RestMethod `
        -Uri "$BaseUrl/api/v1/auth/logout" `
        -Method POST `
        -Headers $headers

    if (-not $response.message) {
        throw "No logout message returned"
    }

    Write-Info "  Logged out successfully"
}

# Summary
Write-Step "Test Results"
$total = $script:TestsPassed + $script:TestsFailed
Write-Host "`nTotal Tests: $total" -ForegroundColor White
Write-Host "Passed: $($script:TestsPassed)" -ForegroundColor Green
Write-Host "Failed: $($script:TestsFailed)" -ForegroundColor $(if ($script:TestsFailed -gt 0) { "Red" } else { "Green" })

if ($script:TestsFailed -eq 0) {
    Write-Host "`n🎉 All tests passed!" -ForegroundColor Green
    Write-Host "`nAuthentication system is working correctly." -ForegroundColor Green
    Write-Host "You can now test the Flutter app with confidence." -ForegroundColor Cyan
    exit 0
}
else {
    Write-Host "`n❌ Some tests failed." -ForegroundColor Red
    Write-Host "Please review the errors above and fix the issues." -ForegroundColor Yellow
    exit 1
}
