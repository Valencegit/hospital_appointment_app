$ErrorActionPreference = "Continue"

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host " CAREPULSE HOSPITAL APP - 10-ITERATION STRESS & VALIDATION TEST " -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

$iterations = 10
$results = @()
$globalStart = [System.Diagnostics.Stopwatch]::StartNew()

for ($i = 1; $i -le $iterations; $i++) {
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Write-Host "`n[$timestamp] [Iteration $i/$iterations] Running full Flutter test suite..." -ForegroundColor Yellow
    $sw = [System.Diagnostics.Stopwatch]::StartNew()

    $rawOutput = & flutter test 2>&1 | Out-String
    $exitCode = $LASTEXITCODE
    $sw.Stop()
    $duration = [math]::Round($sw.Elapsed.TotalSeconds, 2)

    $allPassed = ($exitCode -eq 0) -and ($rawOutput -match "All tests passed!")
    
    $passedCount = 0
    if ($rawOutput -match "\+(\d+):\s*All tests passed!") {
        $passedCount = [int]$matches[1]
    } elseif ($rawOutput -match "\+(\d+)") {
        $passedCount = [int]$matches[1]
    }

    $statusString = if ($allPassed) { "PASSED (100%)" } else { "FAILED" }
    $color = if ($allPassed) { "Green" } else { "Red" }
    
    Write-Host "Iteration $i Result: $statusString | Tests Passed: $passedCount/52 | Duration: ${duration}s" -ForegroundColor $color

    $results += [PSCustomObject]@{
        Iteration = $i
        Status = if ($allPassed) { "PASS" } else { "FAIL" }
        PassPercentage = if ($allPassed) { 100.0 } else { 0.0 }
        TestsPassed = $passedCount
        DurationSeconds = $duration
        ExitCode = $exitCode
        Timestamp = $timestamp
    }
}

$globalStart.Stop()
$totalTime = [math]::Round($globalStart.Elapsed.TotalSeconds, 2)
$successfulRuns = ($results | Where-Object { $_.Status -eq "PASS" }).Count
$overallPassRate = [math]::Round(($successfulRuns / $iterations) * 100, 1)

Write-Host "`n=================================================================" -ForegroundColor Cyan
Write-Host " 10-ITERATION RELIABILITY TEST RESULTS SUMMARY " -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "Total Iterations Executed : $iterations"
Write-Host "Successful Iterations     : $successfulRuns / $iterations"
Write-Host "Reliability / Pass Rate   : $overallPassRate%" -ForegroundColor $(if ($overallPassRate -ge 90) { "Green" } else { "Red" })
Write-Host "Total Execution Time      : ${totalTime}s"
Write-Host "Target Threshold (>90%)   : $(if ($overallPassRate -ge 90) {'ACHIEVED (EXCEEDED)'} else {'NOT MET'})"

$results | Format-Table -AutoSize

# Export JSON report
$jsonReport = [PSCustomObject]@{
    TargetReliability = 90.0
    AchievedReliability = $overallPassRate
    MeetsRequirement = ($overallPassRate -ge 90.0)
    TotalIterations = $iterations
    SuccessfulIterations = $successfulRuns
    TotalExecutionDurationSeconds = $totalTime
    Runs = $results
}

$jsonPath = Join-Path $PSScriptRoot "test_results_10x.json"
$jsonReport | ConvertTo-Json -Depth 4 | Set-Content -Path $jsonPath -Encoding UTF8
Write-Host "`nDetailed JSON report exported to: $jsonPath" -ForegroundColor Cyan
