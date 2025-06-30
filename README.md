# Windows Driver Cleanup Tool

A robust PowerShell script for safely removing stubborn Windows drivers that cannot be uninstalled through normal means. This tool provides comprehensive logging, Safe Mode support, and automatic recovery capabilities.

**Author**: Thomas Canter  
**LinkedIn**: [thomascanter](https://linkedin.com/in/thomascanter)  
**GitHub**: [@tcanter](https://github.com/tcanter)  
**Company**: OJMOT  

## 🚀 Features

- **Smart State Management**: Automatically resumes from where it left off after reboots
- **Session-Based Logging**: Each cleanup attempt gets its own timestamped session folder
- **Safe Mode Support**: Automatically boots into Safe Mode when needed for stubborn drivers
- **Comprehensive Logging**: Detailed command output logging for troubleshooting
- **Multiple Removal Methods**: Progressive escalation from standard removal to manual file cleanup
- **Automatic Recovery**: Intelligently detects current state and continues cleanup process

## 📋 Prerequisites

- Windows 10/11
- PowerShell 5.1 or later
- Administrator privileges
- The driver INF name you want to remove (e.g., `oem124.inf`)

## 🔧 Installation

1. Clone this repository:
```powershell
git clone https://github.com/tcanter/windows-driver-cleanup.git
cd windows-driver-cleanup
```

2. Run as Administrator:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### 💻 VS Code Development

For development in Visual Studio Code:

1. **Open in VS Code**: Open this folder in VS Code
2. **Install Extensions**: Accept the recommended extension suggestions
3. **Use Tasks**: Press `Ctrl+Shift+P` → "Tasks: Run Task" for quick operations
4. **Debug**: Press `F5` to debug the script with integrated PowerShell debugger
5. **Help**: See `.vscode/README.md` for detailed VS Code development guide

**Quick VS Code Tasks:**
- Run script with WhatIf preview
- Execute tests with Pester
- Check PowerShell syntax
- View comprehensive help
- Open log folders
- Clean up test artifacts

## 📖 Usage

### Getting Help

The script includes comprehensive PowerShell help documentation:

```powershell
# Get basic help
Get-Help .\cleanup_driver.ps1

# Get detailed help with examples
Get-Help .\cleanup_driver.ps1 -Detailed

# Get full help with all technical details
Get-Help .\cleanup_driver.ps1 -Full

# Get just the examples
Get-Help .\cleanup_driver.ps1 -Examples

# Get help for a specific parameter
Get-Help .\cleanup_driver.ps1 -Parameter DriverInf
```

### Basic Usage

1. **Identify the driver** you want to remove:
```powershell
pnputil /enum-drivers
```

2. **Run the script** as Administrator:
```powershell
# Preview what the script would do (WhatIf mode)
.\cleanup_driver.ps1 -DriverInf "oem124.inf" -WhatIf

# Actually perform the cleanup
.\cleanup_driver.ps1 -DriverInf "oem124.inf"
```

### Parameters

- **`-DriverInf`**: The driver INF file to remove (e.g., "oem124.inf")
- **`-WhatIf`**: Preview mode - shows what would be done without making changes

### WhatIf Mode

The script supports PowerShell's `-WhatIf` parameter for safe preview:

```powershell
# See what the script would do without making any changes
.\cleanup_driver.ps1 -DriverInf "oem124.inf" -WhatIf
```

**WhatIf mode will:**
- Show all commands that would be executed
- Display files that would be removed
- Preview reboot and Safe Mode operations
- Log all preview actions for review
- **Not make any actual system changes**

### What the Script Does

1. **Initial Cleanup**: Attempts standard driver removal
2. **Safe Mode Escalation**: If standard removal fails, boots into Safe Mode
3. **Device Removal**: Removes devices using the driver
4. **Manual Cleanup**: If all else fails, manually removes driver files
5. **Normal Mode Return**: Automatically returns to normal mode when complete

## 📁 Log Structure

The script creates driver-specific session logs in the `logs` folder:

```
logs/
├── driver-oem124/
│   ├── DriverCleanupLog.txt      # Main operation log
│   ├── SafeModeDetailedLog.txt   # Safe Mode operations
│   └── CommandOutputLog.txt      # All command outputs
├── driver-oem125/
│   ├── DriverCleanupLog.txt      # Different driver session
│   └── CommandOutputLog.txt
└── driver-oem126/
    └── DriverCleanupLog.txt      # Another driver session
```

Each driver gets its own session folder, allowing you to:
- Track cleanup progress for multiple problematic drivers
- Resume cleanup for a specific driver after reboots
- Keep logs organized by driver name
- Maintain session state across Safe Mode transitions

## 🔍 Troubleshooting

### Common Issues

**Script reports "Not in Safe Mode" when you think you're in Safe Mode:**
- The script uses multiple detection methods
- Check the `SafeModeDetailedLog.txt` for detection details
- Manually verify Safe Mode using `msconfig`

**Driver still present after cleanup:**
- Check the session logs for error details
- Verify you're running as Administrator
- Some drivers may require multiple cleanup attempts

**Script won't reboot to Safe Mode:**
- Use `msconfig` to manually set Safe Mode
- Reboot and run the script again

### Log Analysis

Each session folder contains:
- **DriverCleanupLog.txt**: High-level operations and status
- **SafeModeDetailedLog.txt**: Detailed Safe Mode command outputs
- **CommandOutputLog.txt**: All command executions with timestamps

## 🧪 Testing

Run the test suite:
```powershell
.\tests\Run-Tests.ps1
```

## 🤝 Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

For VS Code development, see [.vscode/README.md](.vscode/README.md) for the complete development guide including tasks, debugging, and workspace configuration.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## ⚠️ Disclaimer

This tool modifies system drivers and can potentially cause system instability if used incorrectly. Always:
- Create a system backup before use
- Test on non-production systems first
- Ensure you have recovery media available

## 🆘 Support

- **Issues**: [GitHub Issues](https://github.com/tcanter/windows-driver-cleanup/issues)
- **Discussions**: [GitHub Discussions](https://github.com/tcanter/windows-driver-cleanup/discussions)
- **LinkedIn**: [Connect with Thomas Canter](https://linkedin.com/in/thomascanter)
- **Email**: tcanter@ojmot.com

## 📊 Example Output

### Normal Mode
```
Created new driver cleanup session: oem124
Logs will be saved to: .\logs\driver-oem124

[2025-06-30 14:30:25] Starting driver cleanup for oem124.inf - Current State: INITIAL
Session ID: oem124

[2025-06-30 14:30:25] Checking if driver oem124.inf is present in driver store
Command: pnputil /enum-drivers | Select-String -Pattern oem124.inf
Published Name:     oem124.inf

Driver removal failed. Would you like to reboot into Safe Mode now? (Y/N): Y
System will reboot in 10 seconds. Run this script again after reboot.
```

### WhatIf Mode
```
=== WHATIF MODE ENABLED ===
No actual changes will be made to the system
This will show what the script would do
===============================

Created new driver cleanup session: oem124
Logs will be saved to: .\logs\driver-oem124

[2025-06-30 14:30:25] Checking if driver oem124.inf is present in driver store
Command: pnputil /enum-drivers | Select-String -Pattern oem124.inf
Published Name:     oem124.inf

[2025-06-30 14:30:26] Attempting to uninstall and delete driver oem124.inf
Command: pnputil /delete-driver oem124.inf /uninstall /force
What if: Would execute command: pnputil /delete-driver oem124.inf /uninstall /force

What if: Would prompt user for Safe Mode reboot
```

### After Safe Mode Reboot

```
Continuing existing driver cleanup session: oem124
Previous session for oem124.inf was in Safe Mode. Continuing device removal process...

[2025-06-30 14:45:12] Starting driver cleanup for oem124.inf - Current State: SAFE_MODE_ACTIVE
Session ID: oem124
```

## 🏗️ Architecture

The script follows a state-machine pattern:
- **INITIAL**: First run
- **FAILED_DELETION**: Standard removal failed
- **SAFE_MODE_ACTIVE**: Running in Safe Mode
- **RETRY_ATTEMPTED**: Attempted device removal and retry
- **MANUAL_CLEANUP**: Performing manual file cleanup
- **MANUAL_COMPLETED**: Manual cleanup finished
- **COMPLETED**: Driver successfully removed

This ensures robust recovery and continuation across reboots and interruptions.
