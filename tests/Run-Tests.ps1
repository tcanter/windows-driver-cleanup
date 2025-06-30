# Test Runner for Windows Driver Cleanup Tool
# This script runs all tests for the driver cleanup tool

[CmdletBinding()]
param(
    [Parameter()]
    [string]$TestPath = "./tests",
    
    [Parameter()]
    [string]$OutputPath = "./TestResults.xml",
    
    [Parameter()]
    [switch]$Coverage
)

# Ensure Pester is available
if (-not (Get-Module -ListAvailable -Name Pester)) {
    Write-Host "Installing Pester module..." -ForegroundColor Yellow
    Install-Module -Name Pester -Force -Scope CurrentUser
}

# Import Pester
Import-Module Pester -Force

# Configure Pester
$config = New-PesterConfiguration
$config.Run.Path = $TestPath
$config.TestResult.Enabled = $true
$config.TestResult.OutputPath = $OutputPath
$config.TestResult.OutputFormat = "NUnitXml"
$config.Output.Verbosity = "Detailed"

if ($Coverage) {
    $config.CodeCoverage.Enabled = $true
    $config.CodeCoverage.Path = "./cleanup_driver.ps1"
    $config.CodeCoverage.OutputFormat = "JaCoCo"
    $config.CodeCoverage.OutputPath = "./coverage.xml"
}

# Run tests
Write-Host "Running tests..." -ForegroundColor Green
$result = Invoke-Pester -Configuration $config

# Report results
if ($result.FailedCount -eq 0) {
    Write-Host "All tests passed!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "$($result.FailedCount) test(s) failed" -ForegroundColor Red
    exit 1
}
