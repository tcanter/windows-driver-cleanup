# Windows Driver Cleanup Tool - VS Code Development Guide

This document provides VS Code-specific information for developing and using the Windows Driver Cleanup Tool.

**Author**: Thomas Canter | [LinkedIn](https://linkedin.com/in/thomascanter) | [GitHub](https://github.com/tcanter)

## 🚀 Quick Start in VS Code

### Prerequisites
1. **Install VS Code Extensions** (recommended extensions will be suggested when you open the workspace):
   - PowerShell Extension (`ms-vscode.powershell`)
   - GitHub Actions (`github.vscode-github-actions`)
   - JSON support (`ms-vscode.vscode-json`)

2. **Set PowerShell Execution Policy** (if needed):
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

### Opening the Project
1. Open VS Code
2. Use `File > Open Folder` and select this directory
3. VS Code will suggest installing recommended extensions

## 🔧 VS Code Tasks

Press `Ctrl+Shift+P` and type "Tasks: Run Task" to access these pre-configured tasks:

### Development Tasks
- **Run Driver Cleanup Script** - Execute the script with a specified driver INF
- **Run Driver Cleanup Script (WhatIf)** - Preview what the script would do
- **Check PowerShell Syntax** - Validate script syntax
- **Show Script Help** - Display comprehensive help documentation

### Testing Tasks  
- **Run Tests** - Execute the full Pester test suite
- **Run Tests (Simple)** - Run tests with basic Pester syntax
- **Install Pester (if needed)** - Install Pester testing framework

### Utility Tasks
- **List All Drivers (pnputil)** - View all installed drivers in a grid
- **Open Log Folder** - Open the logs directory in File Explorer  
- **Clean Up Logs** - Remove all log files

## 🎯 Launch Configurations

Press `F5` or use the Run and Debug panel (`Ctrl+Shift+D`) to access these launch configurations:

### Debug Configurations
- **PowerShell: Launch Current File** - Debug the currently open PowerShell file
- **PowerShell: Launch Driver Cleanup Script** - Debug the main script in WhatIf mode
- **PowerShell: Launch Driver Cleanup Script (Live)** - Debug the main script with actual execution
- **PowerShell: Run Tests** - Debug the test suite
- **PowerShell: Show Script Help** - Debug help system

## 📁 Workspace Organization

### File Nesting
The workspace is configured with file nesting to keep related files organized:
- `cleanup_driver.ps1` groups with `cleanup_driver.Tests.ps1`
- `README.md` groups with `CONTRIBUTING.md`, `LICENSE`, `CHANGELOG.md`, `.gitignore`
- Test files are nested under their corresponding source files

### Folder Structure
```
├── .github/                    # GitHub workflows and templates
│   ├── workflows/
│   └── ISSUE_TEMPLATE/
├── .vscode/                    # VS Code configuration
│   ├── tasks.json             # Task definitions
│   ├── launch.json            # Debug configurations
│   ├── settings.json          # Workspace settings
│   └── extensions.json        # Recommended extensions
├── tests/                      # Test files
│   ├── cleanup_driver.Tests.ps1
│   └── Run-Tests.ps1
├── logs/                       # Generated log files (ignored by git)
├── cleanup_driver.ps1          # Main script
├── PSScriptAnalyzerSettings.psd1  # PowerShell linting rules
└── README.md                   # Main documentation
```

## 🔍 Code Analysis

### PowerShell Script Analyzer
The workspace includes custom PSScriptAnalyzer settings (`PSScriptAnalyzerSettings.psd1`) that:
- Focus on errors and warnings (excludes informational messages)
- Enforces consistent code formatting
- Checks for PowerShell best practices
- Excludes some rules that don't apply to this script's use case

### Linting Rules
- **Consistent indentation**: 4 spaces
- **Brace placement**: Opening braces on same line
- **Consistent whitespace**: Around operators and separators
- **Correct casing**: PowerShell cmdlet casing
- **Aligned assignments**: Hash tables and assignment statements

## 🧪 Testing in VS Code

### Running Tests
1. **Via Task**: `Ctrl+Shift+P` → "Tasks: Run Task" → "Run Tests"
2. **Via Debug**: `F5` → "PowerShell: Run Tests"
3. **Via Terminal**: Open integrated terminal and run `.\tests\Run-Tests.ps1`

### Test Structure
- Unit tests for individual functions
- Integration tests for end-to-end scenarios  
- Mock implementations to avoid system changes during testing
- WhatIf functionality testing
- State management and session testing

## 🔧 Development Workflow

### 1. Code Development
- Use IntelliSense and syntax highlighting for PowerShell
- Leverage integrated debugging with breakpoints
- Use the Problems panel to see linting issues

### 2. Testing
- Run tests frequently during development
- Use WhatIf mode to safely test functionality
- Check logs in the `logs/` folder for debugging

### 3. Documentation
- Update help comments in the script when adding features
- Use `Get-Help` task to verify documentation
- Update README.md as needed

### 4. Validation
- Use "Check PowerShell Syntax" task before committing
- Run full test suite to ensure no regressions
- Test both WhatIf and live execution modes

## 🎨 Code Formatting

### Automatic Formatting
The PowerShell extension provides automatic formatting. To format:
- **Current file**: `Shift+Alt+F`
- **Selection**: `Ctrl+K, Ctrl+F`

### Style Guidelines
- Use 4-space indentation
- Place opening braces on the same line
- Use consistent spacing around operators
- Follow PowerShell approved verb naming
- Include comment-based help for all functions

## 🚀 Deployment

### Pre-deployment Checklist
1. Run all tests: `Tasks: Run Task` → "Run Tests"
2. Check syntax: `Tasks: Run Task` → "Check PowerShell Syntax"  
3. Verify help: `Tasks: Run Task` → "Show Script Help"
4. Test WhatIf mode: `Tasks: Run Task` → "Run Driver Cleanup Script (WhatIf)"
5. Clean up logs: `Tasks: Run Task` → "Clean Up Logs"

### GitHub Integration
- GitHub Actions workflow runs automatically on push/PR
- Issue templates are provided for bug reports and feature requests
- Contribution guidelines are in `CONTRIBUTING.md`

## 📊 Monitoring and Debugging

### Log Analysis
- Use "Open Log Folder" task to access logs quickly
- Each driver session gets its own folder
- Three log types: Main, Safe Mode, and Command Output

### Debug Features
- Set breakpoints in PowerShell files
- Use the Debug Console for interactive debugging
- Inspect variables and call stack during execution
- Use conditional breakpoints for specific scenarios

### Troubleshooting
- Check the PowerShell extension output for errors
- Verify execution policy allows script execution
- Ensure running as Administrator for system operations
- Use WhatIf mode to safely test problematic scenarios

## 🔗 Useful VS Code Commands

| Command | Shortcut | Description |
|---------|----------|-------------|
| Command Palette | `Ctrl+Shift+P` | Access all commands |
| Run Task | `Ctrl+Shift+P` → Tasks | Execute predefined tasks |
| Start Debugging | `F5` | Launch with debugger |
| Toggle Terminal | `Ctrl+`` | Show/hide integrated terminal |
| Problems Panel | `Ctrl+Shift+M` | View linting issues |
| Search Files | `Ctrl+P` | Quick file navigation |
| Format Document | `Shift+Alt+F` | Auto-format current file |

## 📝 Tips for VS Code Development

1. **Use the integrated terminal** for running PowerShell commands
2. **Leverage IntelliSense** for PowerShell cmdlets and parameters
3. **Set breakpoints** in the script for debugging complex scenarios
4. **Use the Problems panel** to see PSScriptAnalyzer warnings
5. **Utilize file nesting** to keep the workspace organized
6. **Take advantage of tasks** for common operations
7. **Use WhatIf mode extensively** during development

This VS Code setup provides a comprehensive development environment for maintaining and extending the Windows Driver Cleanup Tool.
