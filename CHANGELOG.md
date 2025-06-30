# Changelog

All notable changes to the Windows Driver Cleanup Tool will be documented in this file.

**Author**: Thomas Canter ([LinkedIn](https://linkedin.com/in/thomas-canter) | [GitHub](https://github.com/tcanter))

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Session-based logging system with unique session IDs
- Comprehensive GitHub repository structure with CI/CD
- Unit tests using Pester framework with cross-version compatibility
- GitHub Actions CI/CD pipeline with PowerShell validation
- Multiple Safe Mode detection methods
- Automatic state recovery across reboots
- Detailed command output logging with tee-like functionality
- Manual file system cleanup as fallback method
- Support for multiple boot configuration methods
- PSScriptAnalyzer integration for code quality checks
- VS Code workspace configuration with tasks and debugging
- Professional attribution and documentation for GitHub publication
- WhatIf parameter support for safe preview of all destructive actions
- Comment-based help documentation for Get-Help compatibility

### Changed
- Restructured logging to use session folders under `logs/`
- Improved error handling and recovery mechanisms
- Enhanced Safe Mode detection with multiple validation methods
- Better user experience with clear status messages
- CI/CD workflow made more robust with optional Pester tests
- Updated .gitignore to include VS Code settings for development
- All destructive operations now support WhatIf parameter
- PSScriptAnalyzer configuration updated to focus on critical errors only
- CI/CD pipeline now separates errors from warnings for better feedback
- PSScriptAnalyzer rules tuned for interactive scripts (excluded overly strict formatting rules)
- Fixed Pester test configuration compatibility across different Pester versions

### Fixed
- Safe Mode detection reliability issues
- Boot configuration setting for Safe Mode transitions
- Log file organization and session tracking
- GitHub Actions workflow compatibility issues with different Pester versions
- PowerShell syntax validation in CI/CD pipeline
- Cross-platform compatibility for GitHub Actions runners
- PSScriptAnalyzer rule conflicts causing CI/CD failures
- Code quality checks now properly exclude interactive script patterns
- Pester test runner configuration for cross-version compatibility
- CI/CD pipeline test execution order and error handling
- Test result XML generation and publishing in CI/CD pipeline

## [1.0.0] - 2025-06-30

### Added
- Initial release of Windows Driver Cleanup Tool
- Basic driver enumeration and removal functionality
- Safe Mode support for stubborn drivers
- Simple logging system
- PowerShell script for Windows driver cleanup

### Features
- Remove drivers that can't be uninstalled normally
- Automatic Safe Mode transition when needed
- Device instance removal before driver deletion
- Manual cleanup of driver files and registry entries
- Comprehensive error logging

### Security
- Requires Administrator privileges
- Safe Mode isolation for system protection
- Validation of driver existence before removal
- Backup recommendations in documentation
