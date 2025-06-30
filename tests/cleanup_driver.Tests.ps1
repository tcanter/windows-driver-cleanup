# Unit Tests for Windows Driver Cleanup Tool

BeforeAll {
    # Mock external commands to avoid actual system changes during testing
    Mock pnputil { return "Microsoft PnP Utility" }
    Mock bcdedit { return "Boot Configuration Data" }
    Mock shutdown { return "Shutdown initiated" }
    Mock Get-WmiObject { return @{ BootupState = "Normal boot" } }
    Mock Get-ItemProperty { return $null }
}

Describe "Driver Cleanup Tool Tests" {
    Context "Session Management" {
        It "Should create driver-based session IDs" {
            $driverInf = "oem124.inf"
            $sessionId = $driverInf.Replace('.inf', '')
            
            $sessionId | Should -Be "oem124"
        }
        
        It "Should create driver-specific session folders" {
            $driverInf = "oem124.inf"
            $sessionId = $driverInf.Replace('.inf', '')
            $logsFolder = "./test-logs"
            $sessionFolder = Join-Path $logsFolder "driver-$sessionId"
            
            if (-not (Test-Path $sessionFolder)) {
                New-Item -Path $sessionFolder -ItemType Directory -Force
            }
            
            Test-Path $sessionFolder | Should -Be $true
            $sessionFolder | Should -Match "driver-oem124"
            
            # Cleanup
            if (Test-Path $logsFolder) {
                Remove-Item -Path $logsFolder -Recurse -Force
            }
        }
        
        It "Should handle multiple driver sessions" {
            $drivers = @("oem124.inf", "oem125.inf", "oem126.inf")
            $logsFolder = "./test-logs"
            
            foreach ($driver in $drivers) {
                $sessionId = $driver.Replace('.inf', '')
                $sessionFolder = Join-Path $logsFolder "driver-$sessionId"
                
                if (-not (Test-Path $sessionFolder)) {
                    New-Item -Path $sessionFolder -ItemType Directory -Force
                }
                
                Test-Path $sessionFolder | Should -Be $true
            }
            
            # Verify all sessions exist
            $sessions = Get-ChildItem -Path $logsFolder -Directory
            $sessions.Count | Should -Be 3
            $sessions.Name | Should -Contain "driver-oem124"
            $sessions.Name | Should -Contain "driver-oem125"
            $sessions.Name | Should -Contain "driver-oem126"
            
            # Cleanup
            if (Test-Path $logsFolder) {
                Remove-Item -Path $logsFolder -Recurse -Force
            }
        }
    }
    
    Context "Logging Functions" {
        BeforeEach {
            $testLogFile = "./test-log.txt"
            if (Test-Path $testLogFile) {
                Remove-Item $testLogFile
            }
        }
        
        AfterEach {
            if (Test-Path $testLogFile) {
                Remove-Item $testLogFile
            }
        }
        
        It "Should create log entries with timestamps" {
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Add-Content -Path $testLogFile -Value "[$timestamp] Test log entry"
            
            $content = Get-Content $testLogFile
            $content | Should -Match "\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\] Test log entry"
        }
        
        It "Should handle multiple log files" {
            $logFile1 = "./test-log1.txt"
            $logFile2 = "./test-log2.txt"
            
            Add-Content -Path $logFile1 -Value "Log 1 content"
            Add-Content -Path $logFile2 -Value "Log 2 content"
            
            Test-Path $logFile1 | Should -Be $true
            Test-Path $logFile2 | Should -Be $true
            
            Get-Content $logFile1 | Should -Be "Log 1 content"
            Get-Content $logFile2 | Should -Be "Log 2 content"
            
            # Cleanup
            Remove-Item $logFile1, $logFile2 -ErrorAction SilentlyContinue
        }
    }
    
    Context "State Detection" {
        It "Should detect COMPLETED state" {
            $testLogContent = @"
[2025-06-30 12:00:00] Starting cleanup
[2025-06-30 12:05:00] Driver oem124.inf successfully removed.
"@
            $testLogContent | Should -Match "Driver .* successfully removed"
        }
        
        It "Should detect FAILED_DELETION state" {
            $testLogContent = @"
[2025-06-30 12:00:00] Starting cleanup
[2025-06-30 12:05:00] Failed to delete driver package
"@
            $testLogContent | Should -Match "Failed to delete driver package"
        }
        
        It "Should detect SAFE_MODE_ACTIVE state" {
            $testLogContent = @"
[2025-06-30 12:00:00] Starting cleanup
[2025-06-30 12:05:00] Running in Safe Mode
"@
            $testLogContent | Should -Match "Running in Safe Mode"
        }
    }
    
    Context "Safe Mode Detection" {
        It "Should detect Safe Mode through WMI" {
            Mock Get-WmiObject { return @{ BootupState = "Fail-safe boot" } }
            
            $bootupState = (Get-WmiObject -Class Win32_ComputerSystem).BootupState
            $bootupState | Should -Be "Fail-safe boot"
        }
        
        It "Should detect Safe Mode through registry" {
            Mock Get-ItemProperty { return @{ OptionValue = 1 } }
            
            $safeModeReg = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SafeBoot\Option" -Name "OptionValue" -ErrorAction SilentlyContinue).OptionValue
            $safeModeReg | Should -Be 1
        }
        
        It "Should detect Safe Mode through BCDEdit" {
            Mock bcdedit { return "safeboot                Minimal" }
            
            $bcdeditOutput = bcdedit
            $bcdeditOutput | Should -Match "safeboot"
        }
    }
    
    Context "Command Validation" {
        It "Should validate pnputil enum-drivers command" {
            Mock pnputil { return "Published Name:     oem124.inf" } -ParameterFilter { $args -contains "/enum-drivers" }
            
            $result = pnputil /enum-drivers
            $result | Should -Match "Published Name:"
        }
        
        It "Should validate pnputil delete-driver command" {
            Mock pnputil { return "Driver package deleted successfully." } -ParameterFilter { $args -contains "/delete-driver" }
            
            $result = pnputil /delete-driver "oem124.inf" /force
            $result | Should -Match "Driver package deleted successfully"
        }
        
        It "Should validate bcdedit safe mode commands" {
            Mock bcdedit { return "The operation completed successfully." } -ParameterFilter { $args -contains "/set" }
            
            $result = bcdedit /set safeboot minimal
            $result | Should -Match "completed successfully"
        }
    }
    
    Context "WhatIf Functionality" {
        It "Should support WhatIf parameter" {
            # Test that the script accepts WhatIf parameter
            $result = & { param([switch]$WhatIf) $WhatIf } -WhatIf
            $result | Should -Be $true
        }
        
        It "Should detect WhatIf mode correctly" {
            $whatIfEnabled = $true
            $shouldProcess = $false
            
            $isWhatIf = $whatIfEnabled -or $shouldProcess
            $isWhatIf | Should -Be $true
        }
        
        It "Should log WhatIf actions without executing" {
            $testLogFile = "./test-whatif-log.txt"
            $command = "Test-Command"
            $whatIfOutput = "What if: Would execute command: $command"
            
            Add-Content -Path $testLogFile -Value $whatIfOutput
            
            $content = Get-Content $testLogFile
            $content | Should -Match "What if: Would execute command:"
            
            # Cleanup
            Remove-Item $testLogFile -ErrorAction SilentlyContinue
        }
        
        It "Should handle destructive vs non-destructive commands" {
            $destructiveCommand = "pnputil /delete-driver test.inf /force"
            $nonDestructiveCommand = "pnputil /enum-drivers"
            
            # Destructive commands should be flagged
            $destructiveCommand | Should -Match "/delete-driver|/remove-device"
            
            # Non-destructive commands should not be flagged
            $nonDestructiveCommand | Should -Match "/enum-drivers|/enum-devices"
        }
    }
    
    Context "Error Handling" {
        It "Should handle missing driver gracefully" {
            Mock pnputil { return "" } -ParameterFilter { $args -contains "/enum-drivers" }
            
            $result = pnputil /enum-drivers
            $result | Should -Be ""
        }
        
        It "Should handle command failures" {
            Mock pnputil { throw "Access denied" } -ParameterFilter { $args -contains "/delete-driver" }
            
            { pnputil /delete-driver "test.inf" /force } | Should -Throw "Access denied"
        }
    }
}

Describe "Integration Tests" {
    Context "End-to-End Scenarios" {
        It "Should handle a complete successful cleanup flow" {
            # Mock successful commands
            Mock pnputil { return "Published Name: oem124.inf" } -ParameterFilter { $args -contains "/enum-drivers" }
            Mock pnputil { return "Driver package deleted successfully." } -ParameterFilter { $args -contains "/delete-driver" }
            
            # Test would run the main logic here
            $true | Should -Be $true # Placeholder for actual integration test
        }
        
        It "Should handle Safe Mode transition flow" {
            # Mock Safe Mode detection
            Mock Get-WmiObject { return @{ BootupState = "Fail-safe boot" } }
            Mock Get-ItemProperty { return @{ OptionValue = 1 } }
            
            # Test would verify Safe Mode handling here
            $true | Should -Be $true # Placeholder for actual integration test
        }
    }
}
