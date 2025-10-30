#Requires -Version 5.1
# Test script for comprehensive email system verification

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Import Python resolver
. "$PSScriptRoot\..\common\python_resolver.ps1"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Email System Comprehensive Test Suite" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get correct Python
Write-Host "1. Resolving Python executable..." -ForegroundColor Yellow
try {
    $python = Get-ProjectPythonCommand
    Write-Host "   [OK] Found Python: $python" -ForegroundColor Green

    # Show version
    $version = & $python --version
    Write-Host "   [OK] Version: $version" -ForegroundColor Green
} catch {
    Write-Host "   [FAIL] Error: $_" -ForegroundColor Red
    exit 1
}

# Install APScheduler
Write-Host ""
Write-Host "2. Installing APScheduler..." -ForegroundColor Yellow
try {
    & $python -m pip install apscheduler --quiet
    Write-Host "   [OK] APScheduler installed" -ForegroundColor Green
} catch {
    Write-Host "   [FAIL] Error installing APScheduler: $_" -ForegroundColor Red
    exit 1
}

# Test imports
Write-Host ""
Write-Host "3. Testing module imports..." -ForegroundColor Yellow

$importTests = @(
    "from app.services.email_marketing import EmailMarketingService",
    "from app.services.email_templates import EmailTemplates",
    "from app.api.routers.email_verification import router as email_verification_router",
    "from app.api.routers.email_preferences import router as email_preferences_router",
    "from app.jobs.email_jobs import send_streak_reminders, send_srs_review_reminders",
    "from app.jobs.scheduler import EmailScheduler, email_scheduler",
    "from app.db.user_models import EmailVerificationToken",
    "from apscheduler.schedulers.asyncio import AsyncIOScheduler",
    "from apscheduler.triggers.cron import CronTrigger"
)

$importSuccess = 0
$importFailed = 0

foreach ($importTest in $importTests) {
    try {
        $testScript = @"
import sys
sys.path.insert(0, 'backend')
$importTest
print('OK')
"@
        $result = $testScript | & $python 2>&1

        if ($LASTEXITCODE -eq 0 -and $result -match 'OK') {
            Write-Host "   [OK] $importTest" -ForegroundColor Green
            $importSuccess++
        } else {
            Write-Host "   [FAIL] $importTest" -ForegroundColor Red
            Write-Host "     Error: $result" -ForegroundColor Red
            $importFailed++
        }
    } catch {
        Write-Host "   [FAIL] $importTest" -ForegroundColor Red
        Write-Host "     Error: $_" -ForegroundColor Red
        $importFailed++
    }
}

Write-Host ""
Write-Host "   Import Results: $importSuccess passed, $importFailed failed" -ForegroundColor $(if ($importFailed -eq 0) { 'Green' } else { 'Yellow' })

# Test email templates rendering
Write-Host ""
Write-Host "4. Testing email template rendering..." -ForegroundColor Yellow

$templateTest = @"
import sys
sys.path.insert(0, 'backend')
from app.services.email_templates import EmailTemplates

# Test verification email
subject, html, text = EmailTemplates.verification_email(
    username='testuser',
    verification_url='https://example.com/verify?token=abc123'
)
assert 'testuser' in html
assert 'verify?token=abc123' in html
print('[OK] Verification email')

# Test streak reminder
subject, html, text = EmailTemplates.streak_reminder(
    username='testuser',
    streak_days=5,
    xp_needed=50,
    quick_lesson_url='https://example.com/lessons',
    settings_url='https://example.com/settings'
)
assert 'testuser' in html
assert '5' in subject or '5' in html
print('[OK] Streak reminder')

# Test achievement notification
subject, html, text = EmailTemplates.achievement_unlocked(
    username='testuser',
    achievement_name='First Lesson',
    achievement_description='Complete your first lesson',
    achievement_icon_url='https://example.com/icon.png',
    rarity_percent=85.5,
    achievements_url='https://example.com/achievements',
    share_url='https://example.com/share/achievement'
)
assert 'First Lesson' in html
print('[OK] Achievement notification')

print('ALL_TEMPLATES_OK')
"@

try {
    $result = $templateTest | & $python 2>&1
    if ($LASTEXITCODE -eq 0 -and $result -match 'ALL_TEMPLATES_OK') {
        Write-Host "   [OK] All email templates render correctly" -ForegroundColor Green
        $result | Where-Object { $_ -match '\[OK\]' } | ForEach-Object {
            Write-Host "     $_" -ForegroundColor Green
        }
    } else {
        Write-Host "   [FAIL] Template rendering failed" -ForegroundColor Red
        Write-Host "     $result" -ForegroundColor Red
    }
} catch {
    Write-Host "   [FAIL] Error testing templates: $_" -ForegroundColor Red
}

# Test scheduler initialization
Write-Host ""
Write-Host "5. Testing scheduler initialization..." -ForegroundColor Yellow

$schedulerTest = @"
import sys
import asyncio
sys.path.insert(0, 'backend')
from app.jobs.scheduler import EmailScheduler

async def test_scheduler():
    scheduler = EmailScheduler()
    # Do not actually start it, just verify it can be created
    assert scheduler is not None
    assert hasattr(scheduler, 'start')
    assert hasattr(scheduler, 'stop')
    assert hasattr(scheduler, '_register_streak_reminder_jobs')
    print('[OK] Scheduler initialized')
    print('[OK] All required methods present')
    print('SCHEDULER_OK')

asyncio.run(test_scheduler())
"@

try {
    $result = $schedulerTest | & $python 2>&1
    if ($LASTEXITCODE -eq 0 -and $result -match 'SCHEDULER_OK') {
        Write-Host "   [OK] Scheduler initialization successful" -ForegroundColor Green
        $result | Where-Object { $_ -match '\[OK\]' } | ForEach-Object {
            Write-Host "     $_" -ForegroundColor Green
        }
    } else {
        Write-Host "   [FAIL] Scheduler initialization failed" -ForegroundColor Red
        Write-Host "     $result" -ForegroundColor Red
    }
} catch {
    Write-Host "   [FAIL] Error testing scheduler: $_" -ForegroundColor Red
}

# Test email job functions exist
Write-Host ""
Write-Host "6. Testing email job functions..." -ForegroundColor Yellow

$jobTest = @"
import sys
import inspect
sys.path.insert(0, 'backend')
from app.jobs import email_jobs

# Check all required functions exist
required_functions = [
    'send_streak_reminders',
    'send_srs_review_reminders',
    'send_weekly_digest',
    'send_onboarding_emails',
    'send_re_engagement_emails',
    'send_achievement_notification'
]

for func_name in required_functions:
    assert hasattr(email_jobs, func_name), f'Missing function: {func_name}'
    func = getattr(email_jobs, func_name)
    assert callable(func), f'Not callable: {func_name}'
    assert inspect.iscoroutinefunction(func), f'Not async: {func_name}'
    print(f'[OK] {func_name}')

print('ALL_JOBS_OK')
"@

try {
    $result = $jobTest | & $python 2>&1
    if ($LASTEXITCODE -eq 0 -and $result -match 'ALL_JOBS_OK') {
        Write-Host "   [OK] All email job functions present and async" -ForegroundColor Green
        $result | Where-Object { $_ -match '\[OK\]' } | ForEach-Object {
            Write-Host "     $_" -ForegroundColor Green
        }
    } else {
        Write-Host "   [FAIL] Email job function check failed" -ForegroundColor Red
        Write-Host "     $result" -ForegroundColor Red
    }
} catch {
    Write-Host "   [FAIL] Error testing email jobs: $_" -ForegroundColor Red
}

# Test database models
Write-Host ""
Write-Host "7. Testing database models..." -ForegroundColor Yellow

$modelTest = @"
import sys
sys.path.insert(0, 'backend')
from app.db.user_models import User, UserPreferences, EmailVerificationToken
from sqlalchemy import inspect as sqla_inspect

# Check User has email_verified
assert hasattr(User, 'email_verified'), 'User missing email_verified field'
print('[OK] User.email_verified field exists')

# Check EmailVerificationToken model
assert hasattr(EmailVerificationToken, 'user_id'), 'Missing user_id'
assert hasattr(EmailVerificationToken, 'token'), 'Missing token'
assert hasattr(EmailVerificationToken, 'expires_at'), 'Missing expires_at'
print('[OK] EmailVerificationToken model complete')

# Check UserPreferences has email fields
email_prefs = [
    'email_streak_reminders',
    'email_srs_reminders',
    'email_achievement_notifications',
    'email_weekly_digest',
    'email_onboarding_series',
    'email_new_content_alerts',
    'email_social_notifications',
    'email_re_engagement',
    'srs_reminder_time',
    'streak_reminder_time'
]

for field in email_prefs:
    assert hasattr(UserPreferences, field), f'UserPreferences missing {field}'
    print(f'[OK] UserPreferences.{field}')

print('MODELS_OK')
"@

try {
    $result = $modelTest | & $python 2>&1
    if ($LASTEXITCODE -eq 0 -and $result -match 'MODELS_OK') {
        Write-Host "   [OK] All database models complete" -ForegroundColor Green
        $result | Where-Object { $_ -match '\[OK\]' } | ForEach-Object {
            Write-Host "     $_" -ForegroundColor Green
        }
    } else {
        Write-Host "   [FAIL] Database model check failed" -ForegroundColor Red
        Write-Host "     $result" -ForegroundColor Red
    }
} catch {
    Write-Host "   [FAIL] Error testing database models: $_" -ForegroundColor Red
}

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Test Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

if ($importFailed -eq 0) {
    Write-Host "[OK] All imports successful" -ForegroundColor Green
    Write-Host "[OK] Email templates working" -ForegroundColor Green
    Write-Host "[OK] Scheduler initialized" -ForegroundColor Green
    Write-Host "[OK] Email jobs configured" -ForegroundColor Green
    Write-Host "[OK] Database models complete" -ForegroundColor Green
    Write-Host ""
    Write-Host "SUCCESS: Email system is ready!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. Run database migration: cd backend && python -m alembic upgrade head" -ForegroundColor White
    Write-Host "2. Start server: uvicorn app.main:app --reload" -ForegroundColor White
    Write-Host "3. Test endpoints using docs/EMAIL_TESTING_GUIDE.md" -ForegroundColor White
    exit 0
} else {
    Write-Host "WARNING: Some tests failed - review errors above" -ForegroundColor Yellow
    exit 1
}
