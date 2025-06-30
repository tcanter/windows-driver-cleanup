<#
.SYNOPSIS
    A robust PowerShell script for safely removing stubborn Windows drivers that cannot be uninstalled through normal means.

.DESCRIPTION
    This script provides comprehensive driver removal capabilities with advanced logging, Safe Mode support, 
    and automatic recovery mechanisms. It uses session-based state management to resume cleanup operations
    across reboots and escalates through multiple removal methods when standard approaches fail.

    Key Features:
    - Smart state management with automatic resumption after reboots
    - Session-based logging (each driver gets its own log folder)
    - Safe Mode escalation for stubborn drivers
    - WhatIf support for safe preview of all operations
    - Progressive removal methods from standard to aggressive manual cleanup
    - Comprehensive command and output logging
    - Multiple Safe Mode detection methods
    - Automatic return to normal mode after completion

    The script operates in phases:
    1. Initial standard driver removal attempt
    2. Safe Mode escalation if standard removal fails
    3. Device removal using the problematic driver
    4. Manual file and registry cleanup if needed
    5. Automatic return to normal boot mode

.PARAMETER DriverInf
    Specifies the driver INF file to remove (e.g., "oem124.inf").
    This should be the OEM driver name found using 'pnputil /enum-drivers'.
    Default value is "oem124.inf" if not specified.

.PARAMETER WhatIf
    Shows what the script would do without making any actual changes to the system.
    This is a standard PowerShell parameter provided by [CmdletBinding(SupportsShouldProcess)].
    When used, provides a safe way to preview all operations including file removals,
    device removals, reboot operations, and Safe Mode transitions.
    All WhatIf actions are logged for review.

.INPUTS
    None. You cannot pipe objects to this script.

.OUTPUTS
    The script outputs status information to the console and creates detailed logs
    in a session-specific folder under .\logs\driver-<drivername>\
    
    Log files created:
    - DriverCleanupLog.txt: Main operation log with timestamps
    - SafeModeDetailedLog.txt: Detailed Safe Mode operations
    - CommandOutputLog.txt: All command outputs with separators

.EXAMPLE
    .\cleanup_driver.ps1 -DriverInf "oem124.inf"
    
    Removes the specified driver using all available methods, escalating to Safe Mode if needed.

.EXAMPLE
    .\cleanup_driver.ps1 -DriverInf "oem125.inf" -WhatIf
    
    Shows what the script would do to remove oem125.inf without making any changes.
    Useful for previewing operations before actual execution.

.EXAMPLE
    .\cleanup_driver.ps1
    
    Uses the default driver "oem124.inf" for removal.

.EXAMPLE
    # First, identify problematic drivers
    pnputil /enum-drivers
    
    # Preview the cleanup process
    .\cleanup_driver.ps1 -DriverInf "oem126.inf" -WhatIf
    
    # Perform actual cleanup
    .\cleanup_driver.ps1 -DriverInf "oem126.inf"

.NOTES
    File Name      : cleanup_driver.ps1
    Author         : Thomas Canter
    LinkedIn       : https://linkedin.com/in/thomascanter
    GitHub         : https://github.com/tcanter
    Email          : tcanter@ojmot.com
    Company        : OJMOT
    Created        : June 30, 2025
    Version        : 1.0.0
    Prerequisite   : PowerShell 5.1 or later, Administrator privileges
    Copyright      : MIT License
    
    IMPORTANT SAFETY NOTES:
    - Always run as Administrator
    - Use -WhatIf first to preview operations
    - The script will reboot your system when escalating to Safe Mode
    - Save your work before running without -WhatIf
    - Each driver cleanup gets its own session folder for tracking
    
    SYSTEM REQUIREMENTS:
    - Windows 10/11
    - PowerShell 5.1 or later
    - Administrator privileges
    - Network access for potential driver downloads (if needed)
    
    TROUBLESHOOTING:
    - Check logs in .\logs\driver-<drivername>\ for detailed operation history
    - The script automatically resumes from the last known state after reboots
    - If stuck in Safe Mode, run the script again to return to normal mode
    - Use Get-Help for additional parameter information

.LINK
    https://github.com/tcanter/windows-driver-cleanup

.LINK
    https://linkedin.com/in/thomascanter

.LINK
    https://docs.microsoft.com/en-us/windows-hardware/drivers/install/pnputil

.COMPONENT
    Windows Driver Management

.ROLE
    Administrator

.FUNCTIONALITY
    Driver Removal, System Maintenance, Safe Mode Operations
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $false)]
    [string]$DriverInf = "oem124.inf"
)

$DriverInf = $DriverInf
$SessionId = $DriverInf.Replace('.inf', '')  # Use driver name as session key
$LogsFolder = ".\logs"
$SessionFolder = Join-Path $LogsFolder "driver-$SessionId"
$LogFile = Join-Path $SessionFolder "DriverCleanupLog.txt"
$SafeModeLogFile = Join-Path $SessionFolder "SafeModeDetailedLog.txt"
$CommandLogFile = Join-Path $SessionFolder "CommandOutputLog.txt"
$TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# WhatIf mode indicator
$IsWhatIf = $WhatIfPreference -eq 'Continue' -or $PSBoundParameters.ContainsKey('WhatIf')

if ($IsWhatIf) {
    Write-Host "=== WHATIF MODE ENABLED ===" -ForegroundColor Yellow
    Write-Host "No actual changes will be made to the system" -ForegroundColor Yellow
    Write-Host "This will show what the script would do" -ForegroundColor Yellow
    Write-Host "===============================" -ForegroundColor Yellow
}

# Create or continue existing session folder for this driver
if (-not (Test-Path $SessionFolder)) {
    New-Item -Path $SessionFolder -ItemType Directory -Force | Out-Null
    Write-Host "Created new driver cleanup session: $SessionId" -ForegroundColor Green
    Write-Host "Logs will be saved to: $SessionFolder" -ForegroundColor Yellow
} else {
    Write-Host "Continuing existing driver cleanup session: $SessionId" -ForegroundColor Yellow
    Write-Host "Session logs: $SessionFolder" -ForegroundColor Yellow
}

<#
.SYNOPSIS
    Logs command execution to both console and log files with WhatIf support.

.DESCRIPTION
    This internal function provides centralized logging for all script operations.
    It writes command information and output to multiple log files while also
    displaying the information on the console. Supports WhatIf mode to preview
    destructive operations without executing them.

.PARAMETER Command
    The command string to execute or preview.

.PARAMETER Description
    A human-readable description of what the command does.

.PARAMETER IsSafeModeCommand
    Indicates this command is being executed in Safe Mode context.
    When set, also logs to the Safe Mode detailed log file.

.PARAMETER IsDestructive
    Indicates this command makes destructive changes to the system.
    When combined with WhatIf mode, the command is previewed but not executed.

.EXAMPLE
    Write-CommandLog -Command "pnputil /delete-driver oem124.inf" -Description "Removing driver" -IsDestructive

.NOTES
    This is an internal function used by the main script for consistent logging.
#>
function Write-CommandLog {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$Command,
        [string]$Description,
        [switch]$IsSafeModeCommand,
        [switch]$IsDestructive
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $separator = "=" * 80
    
    # Log to main log
    Add-Content -Path $LogFile -Value "`n[$timestamp] $Description"
    Add-Content -Path $LogFile -Value "Command: $Command"
    
    # Log to command output file
    Add-Content -Path $CommandLogFile -Value "`n$separator"
    Add-Content -Path $CommandLogFile -Value "[$timestamp] $Description"
    Add-Content -Path $CommandLogFile -Value "Command: $Command"
    Add-Content -Path $CommandLogFile -Value $separator
    
    # Also log to Safe Mode file if in Safe Mode context
    if ($IsSafeModeCommand) {
        Add-Content -Path $SafeModeLogFile -Value "`n$separator"
        Add-Content -Path $SafeModeLogFile -Value "[$timestamp] $Description"
        Add-Content -Path $SafeModeLogFile -Value "Command: $Command"
        Add-Content -Path $SafeModeLogFile -Value $separator
    }
    
    Write-Host "`n[$timestamp] $Description" -ForegroundColor Cyan
    Write-Host "Command: $Command" -ForegroundColor Gray
    
    # Handle WhatIf mode
    if ($IsWhatIf -and $IsDestructive) {
        $whatIfOutput = "What if: Would execute command: $Command"
        Write-Host $whatIfOutput -ForegroundColor Yellow
        
        # Log WhatIf action
        Add-Content -Path $LogFile -Value $whatIfOutput
        Add-Content -Path $CommandLogFile -Value $whatIfOutput
        
        if ($IsSafeModeCommand) {
            Add-Content -Path $SafeModeLogFile -Value $whatIfOutput
        }
        
        Add-Content -Path $CommandLogFile -Value $separator
        if ($IsSafeModeCommand) {
            Add-Content -Path $SafeModeLogFile -Value $separator
        }
        
        return $whatIfOutput
    }
    
    # Execute command and capture output
    try {
        $output = Invoke-Expression $Command 2>&1
        
        # Display on console
        $output | ForEach-Object {
            Write-Host $_ -ForegroundColor White
        }
        
        # Log to files
        Add-Content -Path $LogFile -Value $output
        Add-Content -Path $CommandLogFile -Value $output
        
        if ($IsSafeModeCommand) {
            Add-Content -Path $SafeModeLogFile -Value $output
        }
        
        Add-Content -Path $CommandLogFile -Value $separator
        if ($IsSafeModeCommand) {
            Add-Content -Path $SafeModeLogFile -Value $separator
        }
        
        return $output
    }
    catch {
        $errorMsg = "Command failed: $($_.Exception.Message)"
        Write-Host $errorMsg -ForegroundColor Red
        
        Add-Content -Path $LogFile -Value $errorMsg
        Add-Content -Path $CommandLogFile -Value $errorMsg
        
        if ($IsSafeModeCommand) {
            Add-Content -Path $SafeModeLogFile -Value $errorMsg
        }
        
        return $errorMsg
    }
}

# Check current state from previous log entries for this specific driver
$currentState = "INITIAL"

# Check if this driver already has a session folder with logs
if (Test-Path $LogFile) {
    $logContent = Get-Content $LogFile -Raw
    
    # Determine current state based on log content
    if ($logContent -match "Driver .* successfully removed") {
        $currentState = "COMPLETED"
        Write-Host "Driver $DriverInf already successfully removed according to session logs." -ForegroundColor Green
        Write-Host "Session logs: $SessionFolder" -ForegroundColor Green
        exit
    }
    elseif ($logContent -match "Manual cleanup completed") {
        $currentState = "MANUAL_COMPLETED"
        Write-Host "Manual cleanup already completed for $DriverInf. Checking if reboot to normal mode is needed..." -ForegroundColor Yellow
    }
    elseif ($logContent -match "Standard removal still failed. Attempting manual cleanup") {
        $currentState = "MANUAL_CLEANUP"
        Write-Host "Resuming manual cleanup phase for $DriverInf..." -ForegroundColor Yellow
    }
    elseif ($logContent -match "Second deletion attempt:") {
        $currentState = "RETRY_ATTEMPTED"
        Write-Host "Retry already attempted for $DriverInf. Proceeding to manual cleanup if needed..." -ForegroundColor Yellow
    }
    elseif ($logContent -match "Running in Safe Mode") {
        $currentState = "SAFE_MODE_ACTIVE"
        Write-Host "Previous session for $DriverInf was in Safe Mode. Continuing device removal process..." -ForegroundColor Yellow
    }
    elseif ($logContent -match "Failed to delete driver package") {
        $currentState = "FAILED_DELETION"
        Write-Host "Previous deletion failed for $DriverInf. Checking Safe Mode status..." -ForegroundColor Yellow
    }
    else {
        $currentState = "IN_PROGRESS"
        Write-Host "Continuing driver cleanup process for $DriverInf..." -ForegroundColor Yellow
    }
    
    # Add continuation marker to existing log
    Add-Content -Path $LogFile -Value "`n=== CONTINUING SESSION ==="
    Add-Content -Path $LogFile -Value "Resumed at: $TimeStamp"
    Add-Content -Path $LogFile -Value "Current state: $currentState"
    Add-Content -Path $LogFile -Value "=========================="
}

# Check if we have a Safe Mode log from this driver's session
if (Test-Path $SafeModeLogFile) {
    $safeModeContent = Get-Content $SafeModeLogFile -Raw
    Write-Host "Safe Mode log found for $DriverInf. Check $SafeModeLogFile for detailed Safe Mode operation history." -ForegroundColor Yellow
    Add-Content -Path $LogFile -Value "Safe Mode log file detected with $(($safeModeContent -split "`n").Count) lines of output"
}

Add-Content -Path $LogFile -Value "`n[$TimeStamp] Starting driver cleanup for $DriverInf - Current State: $currentState"
Add-Content -Path $LogFile -Value "Session ID: $SessionId"

# Step 1: Check if the driver is present (skip if already in advanced cleanup phases)
if ($currentState -notin @("MANUAL_CLEANUP", "MANUAL_COMPLETED")) {
    $driver = Write-CommandLog -Command "pnputil /enum-drivers | Select-String -Pattern $DriverInf" -Description "Checking if driver $DriverInf is present in driver store" -IsDestructive:$false
    if (-not $driver) {
        Add-Content -Path $LogFile -Value "Driver $DriverInf not found in driver store."
        Write-Output "Driver not found. Exiting."
        exit
    }
}

# Step 2: Check for devices using the driver (skip if already in advanced cleanup phases)
if ($currentState -notin @("MANUAL_CLEANUP", "MANUAL_COMPLETED")) {
    $devices = Write-CommandLog -Command "pnputil /enum-devices /drivers | Select-String -Context 0,10 -Pattern $DriverInf" -Description "Enumerating devices using driver $DriverInf" -IsDestructive:$false
    if ($devices) {
        Add-Content -Path $LogFile -Value "Devices found using ${DriverInf}:"
        $devices | ForEach-Object { Add-Content -Path $LogFile -Value $_.Line }
    } else {
        Add-Content -Path $LogFile -Value "No active devices found using ${DriverInf}."
    }
}

# Step 3: Attempt to uninstall and delete the driver (skip if already failed or in manual cleanup)
if ($currentState -notin @("FAILED_DELETION", "SAFE_MODE_ACTIVE", "RETRY_ATTEMPTED", "MANUAL_CLEANUP", "MANUAL_COMPLETED")) {
    $deleteResult = Write-CommandLog -Command "pnputil /delete-driver $DriverInf /uninstall /force" -Description "Attempting to uninstall and delete driver $DriverInf" -IsDestructive:$true
} else {
    # Simulate failed deletion to continue with advanced cleanup
    $deleteResult = "Failed to delete driver package"
    Add-Content -Path $LogFile -Value "Skipping initial deletion attempt - proceeding with advanced cleanup based on previous state"
}

# Check if we're resuming from manual cleanup completion
if ($currentState -eq "MANUAL_COMPLETED") {
    # Multiple methods to detect Safe Mode
    $bootupState = (Get-WmiObject -Class Win32_ComputerSystem).BootupState
    $safeModeReg = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SafeBoot\Option" -Name "OptionValue" -ErrorAction SilentlyContinue).OptionValue
    $bcdeditSafe = bcdedit | Select-String "safeboot"
    
    # Consider Safe Mode if any detection method indicates it
    $safeMode = ($bootupState -eq "Fail-safe boot") -or 
                ($safeModeReg -eq 1) -or 
                ($null -ne $bcdeditSafe) -or
                ($null -ne $env:SAFEBOOT_OPTION)
    
    if ($safeMode) {
        $rebootChoice = Read-Host "Manual cleanup was already completed. Reboot to normal mode now? (Y/N)"
        if ($rebootChoice -eq "Y") {
            Add-Content -Path $LogFile -Value "User chose to reboot to normal mode from manual completion state."
            try {
                $clearResult1 = bcdedit /deletevalue "{current}" safeboot 2>&1
                $clearResult2 = bcdedit /deletevalue safeboot 2>&1
                Add-Content -Path $LogFile -Value "Clear Safe Mode result 1: $clearResult1"
                Add-Content -Path $LogFile -Value "Clear Safe Mode result 2: $clearResult2"
                
                shutdown /r /t 10 /c "Rebooting to normal mode"
                Write-Host "System will reboot to normal mode in 10 seconds." -ForegroundColor Green
            } catch {
                Add-Content -Path $LogFile -Value "Auto-reboot failed: $($_.Exception.Message)"
                Write-Host "Please manually clear Safe Mode using msconfig and restart." -ForegroundColor Yellow
            }
        } else {
            Add-Content -Path $LogFile -Value "User chose to remain in Safe Mode after manual cleanup completion."
        }
    } else {
        Write-Host "Manual cleanup completed and system is in normal mode. Driver cleanup process finished." -ForegroundColor Green
    }
    exit
}

# Step 4: Check if deletion succeeded
if ($deleteResult -match "Failed to delete driver package") {
    Add-Content -Path $LogFile -Value "Driver removal failed. Attempting advanced Safe Mode cleanup..."
    
    # Step 4a: Check if we're in Safe Mode
    # Multiple methods to detect Safe Mode
    $bootupState = Write-CommandLog -Command "(Get-WmiObject -Class Win32_ComputerSystem).BootupState" -Description "Checking system bootup state" -IsSafeModeCommand -IsDestructive:$false
    $safeModeReg = Write-CommandLog -Command "(Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SafeBoot\Option' -Name 'OptionValue' -ErrorAction SilentlyContinue).OptionValue" -Description "Checking Safe Mode registry setting" -IsSafeModeCommand -IsDestructive:$false
    $bcdeditSafe = Write-CommandLog -Command "bcdedit | Select-String 'safeboot'" -Description "Checking BCDEdit for Safe Mode configuration" -IsSafeModeCommand -IsDestructive:$false
    
    Add-Content -Path $LogFile -Value "Safe Mode Detection Results:"
    Add-Content -Path $LogFile -Value "  BootupState: $bootupState"
    Add-Content -Path $LogFile -Value "  Registry SafeBoot: $safeModeReg"
    Add-Content -Path $LogFile -Value "  BCDEdit SafeBoot: $bcdeditSafe"
    
    # Consider Safe Mode if any detection method indicates it
    $safeMode = ($bootupState -eq "Fail-safe boot") -or 
                ($safeModeReg -eq 1) -or 
                ($null -ne $bcdeditSafe) -or
                ($null -ne $env:SAFEBOOT_OPTION)
    
    Add-Content -Path $LogFile -Value "Final Safe Mode determination: $safeMode"
    
    if ($safeMode) {
        Add-Content -Path $LogFile -Value "Running in Safe Mode. Attempting aggressive device removal..."
        
        # Step 4b: Find and forcibly remove devices using this driver
        Add-Content -Path $LogFile -Value "Identifying devices using $DriverInf..."
        $deviceInstances = Write-CommandLog -Command "pnputil /enum-devices /drivers | Select-String -Pattern $DriverInf -Context 3,3" -Description "Finding device instances using driver $DriverInf" -IsSafeModeCommand -IsDestructive:$false
        
        if ($deviceInstances) {
            foreach ($instance in $deviceInstances) {
                $contextLines = $instance.Context.PreContext + $instance.Line + $instance.Context.PostContext
                $instanceId = ($contextLines | Select-String -Pattern "Instance ID:").ToString().Split(':')[1].Trim()
                
                if ($instanceId) {
                    Add-Content -Path $LogFile -Value "Found device instance: $instanceId"
                    Add-Content -Path $SafeModeLogFile -Value "Found device instance: $instanceId"
                    
                    # Try to remove the device instance
                    Write-CommandLog -Command "pnputil /remove-device `"$instanceId`" /force" -Description "Removing device instance $instanceId" -IsSafeModeCommand -IsDestructive:$true
                }
            }
            
            # Step 4c: Try to delete the driver again after device removal
            Add-Content -Path $LogFile -Value "Retrying driver deletion after device removal..."
            Start-Sleep -Seconds 2
            $deleteResult2 = Write-CommandLog -Command "pnputil /delete-driver $DriverInf /force" -Description "Second attempt to delete driver $DriverInf after device removal" -IsSafeModeCommand -IsDestructive:$true
            
            if ($deleteResult2 -match "Failed to delete driver package") {
                # Step 4d: Manual file system cleanup as last resort
                Add-Content -Path $LogFile -Value "Standard removal still failed. Attempting manual cleanup..."
                
                # Try to find the driver files in the driver store
                $driverStorePath = "$env:SystemRoot\System32\DriverStore\FileRepository"
                $driverFolders = Get-ChildItem -Path $driverStorePath -Directory | Where-Object { $_.Name -like "*$($DriverInf.Replace('.inf',''))*" }
                
                foreach ($folder in $driverFolders) {
                    Add-Content -Path $LogFile -Value "Found driver folder: $($folder.FullName)"
                    if ($PSCmdlet.ShouldProcess("$($folder.FullName)", "Remove driver folder")) {
                        try {
                            # Take ownership and remove the folder
                            takeown /f $folder.FullName /r /d y | Out-Null
                            icacls $folder.FullName /grant administrators:F /t | Out-Null
                            Remove-Item -Path $folder.FullName -Recurse -Force
                            Add-Content -Path $LogFile -Value "Successfully removed driver folder: $($folder.FullName)"
                        } catch {
                            Add-Content -Path $LogFile -Value "Failed to remove driver folder: $($_.Exception.Message)"
                        }
                    } else {
                        Add-Content -Path $LogFile -Value "What if: Would remove driver folder: $($folder.FullName)"
                    }
                }
                
                # Clean up INF files from INF directory
                $infPath = "$env:SystemRoot\INF\$DriverInf"
                if (Test-Path $infPath) {
                    if ($PSCmdlet.ShouldProcess("$infPath", "Remove INF file")) {
                        try {
                            takeown /f $infPath | Out-Null
                            icacls $infPath /grant administrators:F | Out-Null
                            Remove-Item -Path $infPath -Force
                            Add-Content -Path $LogFile -Value "Removed INF file: $infPath"
                        } catch {
                            Add-Content -Path $LogFile -Value "Failed to remove INF file: $($_.Exception.Message)"
                        }
                    } else {
                        Add-Content -Path $LogFile -Value "What if: Would remove INF file: $infPath"
                    }
                }
                
                # Clean up PNF file
                $pnfPath = "$env:SystemRoot\INF\$($DriverInf.Replace('.inf','.pnf'))"
                if (Test-Path $pnfPath) {
                    if ($PSCmdlet.ShouldProcess("$pnfPath", "Remove PNF file")) {
                        try {
                            takeown /f $pnfPath | Out-Null
                            icacls $pnfPath /grant administrators:F | Out-Null
                            Remove-Item -Path $pnfPath -Force
                            Add-Content -Path $LogFile -Value "Removed PNF file: $pnfPath"
                        } catch {
                            Add-Content -Path $LogFile -Value "Failed to remove PNF file: $($_.Exception.Message)"
                        }
                    } else {
                        Add-Content -Path $LogFile -Value "What if: Would remove PNF file: $pnfPath"
                    }
                }
                
                Add-Content -Path $LogFile -Value "Manual cleanup completed. Reboot recommended to complete cleanup."
                if (-not $IsWhatIf) {
                    $rebootChoice = Read-Host "Manual cleanup completed. Reboot to normal mode now? (Y/N)"
                    if ($rebootChoice -eq "Y") {
                        Add-Content -Path $LogFile -Value "User chose to reboot to normal mode."
                        if ($PSCmdlet.ShouldProcess("System", "Reboot to normal mode")) {
                            try {
                                # Multiple methods to clear Safe Mode
                                $clearResult1 = bcdedit /deletevalue "{current}" safeboot 2>&1
                                $clearResult2 = bcdedit /deletevalue safeboot 2>&1
                                Add-Content -Path $LogFile -Value "Clear Safe Mode result 1: $clearResult1"
                                Add-Content -Path $LogFile -Value "Clear Safe Mode result 2: $clearResult2"
                                
                                shutdown /r /t 10 /c "Rebooting to normal mode after driver cleanup"
                                Write-Host "System will reboot to normal mode in 10 seconds." -ForegroundColor Green
                            } catch {
                                Add-Content -Path $LogFile -Value "Auto-reboot failed: $($_.Exception.Message)"
                                Write-Host "Please manually clear Safe Mode using msconfig and restart." -ForegroundColor Yellow
                            }
                        } else {
                            Add-Content -Path $LogFile -Value "What if: Would clear Safe Mode and reboot to normal mode"
                            Write-Host "What if: Would clear Safe Mode and reboot to normal mode" -ForegroundColor Yellow
                        }
                    } else {
                        Add-Content -Path $LogFile -Value "User chose to remain in Safe Mode after manual cleanup."
                    }
                } else {
                    Add-Content -Path $LogFile -Value "What if: Would prompt user for reboot to normal mode"
                    Write-Host "What if: Would prompt user for reboot to normal mode" -ForegroundColor Yellow
                }
            } else {
                Add-Content -Path $LogFile -Value "Driver $DriverInf successfully removed on second attempt."
                $rebootChoice = Read-Host "Driver successfully removed. Reboot to normal mode now? (Y/N)"
                if ($rebootChoice -eq "Y") {
                    Add-Content -Path $LogFile -Value "User chose to reboot to normal mode after successful removal."
                    try {
                        $clearResult1 = bcdedit /deletevalue "{current}" safeboot 2>&1
                        $clearResult2 = bcdedit /deletevalue safeboot 2>&1
                        Add-Content -Path $LogFile -Value "Clear Safe Mode result 1: $clearResult1"
                        Add-Content -Path $LogFile -Value "Clear Safe Mode result 2: $clearResult2"
                        
                        shutdown /r /t 10 /c "Rebooting to normal mode after successful driver removal"
                        Write-Host "Driver successfully removed! System will reboot to normal mode in 10 seconds." -ForegroundColor Green
                    } catch {
                        Add-Content -Path $LogFile -Value "Auto-reboot failed: $($_.Exception.Message)"
                        Write-Host "Driver removed! Please manually clear Safe Mode using msconfig and restart." -ForegroundColor Yellow
                    }
                } else {
                    Add-Content -Path $LogFile -Value "User chose to remain in Safe Mode after successful removal."
                }
            }
        }
    } else {
        Add-Content -Path $LogFile -Value "Not in Safe Mode. Prompting for Safe Mode reboot."
        if (-not $IsWhatIf) {
            $choice = Read-Host "Driver removal failed. Would you like to reboot into Safe Mode now? (Y/N)"
            if ($choice -eq "Y") {
                Add-Content -Path $LogFile -Value "User chose to reboot into Safe Mode. Setting Safe Mode boot option..."
                
                if ($PSCmdlet.ShouldProcess("System", "Configure Safe Mode boot and reboot")) {
                    # Try multiple methods to set Safe Mode
                    try {
                        # Method 1: Use bcdedit with proper syntax
                        $bcdResult1 = bcdedit /set "{current}" safeboot minimal 2>&1
                        Add-Content -Path $LogFile -Value "BCDEdit method 1 result: $bcdResult1"
                        
                        # Method 2: Alternative bcdedit syntax
                        $bcdResult2 = bcdedit /set safeboot minimal 2>&1
                        Add-Content -Path $LogFile -Value "BCDEdit method 2 result: $bcdResult2"
                        
                        Write-Host "Safe Mode boot option has been set using BCDEdit." -ForegroundColor Yellow
                        Write-Host "If automatic reboot fails, please manually:" -ForegroundColor Yellow
                        Write-Host "1. Open msconfig" -ForegroundColor Yellow
                        Write-Host "2. Go to Boot tab" -ForegroundColor Yellow
                        Write-Host "3. Check 'Safe boot' and select 'Minimal'" -ForegroundColor Yellow
                        Write-Host "4. Click OK and restart" -ForegroundColor Yellow
                        
                        $rebootNow = Read-Host "Reboot now? (Y/N) - Choose N if you prefer to use msconfig manually"
                        if ($rebootNow -eq "Y") {
                            Add-Content -Path $LogFile -Value "Initiating automatic reboot to Safe Mode..."
                            shutdown /r /t 10 /c "Rebooting to Safe Mode for driver cleanup"
                            Write-Host "System will reboot in 10 seconds. Run this script again after reboot." -ForegroundColor Green
                        } else {
                            Add-Content -Path $LogFile -Value "User chose to manually configure Safe Mode reboot."
                            Write-Host "Please use msconfig to set Safe Mode and reboot, then run this script again." -ForegroundColor Yellow
                        }
                    } catch {
                        Add-Content -Path $LogFile -Value "BCDEdit failed: $($_.Exception.Message)"
                        Write-Host "BCDEdit failed. Please use msconfig to set Safe Mode:" -ForegroundColor Red
                        Write-Host "1. Run 'msconfig'" -ForegroundColor Yellow
                        Write-Host "2. Go to Boot tab" -ForegroundColor Yellow
                        Write-Host "3. Check 'Safe boot' and select 'Minimal'" -ForegroundColor Yellow
                        Write-Host "4. Click OK and restart" -ForegroundColor Yellow
                        Write-Host "5. Run this script again after reboot" -ForegroundColor Yellow
                    }
                } else {
                    Add-Content -Path $LogFile -Value "What if: Would configure Safe Mode boot and reboot system"
                    Write-Host "What if: Would configure Safe Mode boot and reboot system" -ForegroundColor Yellow
                }
            } else {
                Add-Content -Path $LogFile -Value "User declined Safe Mode reboot."
            }
        } else {
            Add-Content -Path $LogFile -Value "What if: Would prompt user for Safe Mode reboot"
            Write-Host "What if: Would prompt user for Safe Mode reboot" -ForegroundColor Yellow
        }
    }
} else {
    Add-Content -Path $LogFile -Value "Driver $DriverInf successfully removed."
}
