# Changelog

All notable changes to the Windows Driver Cleanup Tool will be documented in this file.

**Author**: Thomas Canter ([LinkedIn](https://linkedin.com/in/thomas-canter) | [GitHub](https://github.com/tcanter))

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Session-based logging system with unique session IDs
- Comprehensive GitHub repository structure with CI/CD
- Unit tests using Pester framework
- Multiple Safe Mode detection methods
- Automatic state recovery across reboots
- Detailed command output logging with tee-like functionality
- Manual file system cleanup as fallback method
- Support for multiple boot configuration methods

### Changed
- Restructured logging to use session folders under `logs/`
- Improved error handling and recovery mechanisms
- Enhanced Safe Mode detection with multiple validation methods
- Better user experience with clear status messages

### Fixed
- Safe Mode detection reliability issues
- Boot configuration setting for Safe Mode transitions
- Log file organization and session tracking

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
