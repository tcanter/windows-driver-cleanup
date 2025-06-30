# Contributing to Windows Driver Cleanup Tool

Thank you for your interest in contributing to the Windows Driver Cleanup Tool! This document provides guidelines and information for contributors.

**Project Maintainer**: Thomas Canter ([LinkedIn](https://linkedin.com/in/thomas-canter) | [GitHub](https://github.com/tcanter))  
**Email**: tcanter@ojmot.com

## 🤝 Code of Conduct

By participating in this project, you agree to abide by our Code of Conduct:

- **Be respectful**: Treat all community members with respect and kindness
- **Be inclusive**: Welcome newcomers and people from all backgrounds
- **Be collaborative**: Work together constructively and share knowledge
- **Be constructive**: Provide helpful feedback and suggestions

## 🚀 Getting Started

### Prerequisites

- Windows 10/11
- PowerShell 5.1 or later
- Git for Windows
- A code editor (VS Code recommended)

### Development Setup

1. **Fork the repository** on GitHub
2. **Clone your fork** locally:
```bash
git clone https://github.com/yourusername/windows-driver-cleanup.git
cd windows-driver-cleanup
```

3. **Create a feature branch**:
```bash
git checkout -b feature/your-feature-name
```

## 📝 Making Changes

### Code Style Guidelines

- **Use PowerShell best practices**:
  - Use approved verbs for function names
  - Follow Pascal Case for function names
  - Use camelCase for variable names
  - Include comment-based help for functions

- **Code formatting**:
  - Use 4 spaces for indentation
  - Keep lines under 120 characters
  - Use meaningful variable names
  - Add comments for complex logic

### Example Function Structure

```powershell
<#
.SYNOPSIS
    Brief description of what the function does

.DESCRIPTION
    Detailed description of the function's purpose and behavior

.PARAMETER ParameterName
    Description of the parameter

.EXAMPLE
    Example of how to use the function

.NOTES
    Additional notes or requirements
#>
function Verb-Noun {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RequiredParameter,
        
        [Parameter(Mandatory = $false)]
        [switch]$OptionalSwitch
    )
    
    # Function implementation
}
```

### Testing Guidelines

1. **Write tests** for new functionality
2. **Update existing tests** when modifying behavior
3. **Test in multiple environments**:
   - Normal mode and Safe Mode
   - Different Windows versions
   - Various driver types

4. **Run the test suite**:
```powershell
.\tests\Run-Tests.ps1
```

### Logging Standards

- **Use the `Write-CommandLog` function** for all command executions
- **Include descriptive messages** for log entries
- **Use appropriate log levels**:
  - Information: General operation status
  - Warning: Potentially problematic conditions
  - Error: Failure conditions

## 🐛 Reporting Issues

### Bug Reports

When reporting bugs, please include:

1. **System Information**:
   - Windows version
   - PowerShell version
   - Driver type being removed

2. **Steps to Reproduce**:
   - Exact commands used
   - Configuration settings
   - Any custom modifications

3. **Expected vs Actual Behavior**:
   - What you expected to happen
   - What actually happened

4. **Log Files**:
   - Attach relevant session logs
   - Include error messages

### Feature Requests

For feature requests, please provide:

1. **Use Case**: Describe the scenario where this feature would be useful
2. **Proposed Solution**: How you envision the feature working
3. **Alternatives**: Other approaches you've considered
4. **Priority**: How important this feature is to you

## 🔄 Pull Request Process

### Before Submitting

1. **Update documentation** for any new features
2. **Add or update tests** for changed functionality
3. **Verify all tests pass**
4. **Check code style** compliance
5. **Update the changelog** if applicable

### Pull Request Template

```markdown
## Description
Brief description of changes made

## Type of Change
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update

## Testing
- [ ] Tests added/updated for the changes
- [ ] All tests pass
- [ ] Tested in Safe Mode
- [ ] Tested with multiple driver types

## Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] No conflicts with main branch
```

### Review Process

1. **Automated checks** will run on your PR
2. **Maintainer review** - at least one maintainer will review your changes
3. **Community feedback** - other contributors may provide input
4. **Address feedback** - make requested changes if needed
5. **Merge** - once approved, your PR will be merged

## 📚 Documentation

### Documentation Standards

- **Keep README.md updated** with new features
- **Add inline comments** for complex logic
- **Include examples** for new functions
- **Update help text** for changed behavior

### Documentation Types

- **User Documentation**: README.md, usage examples
- **Developer Documentation**: Code comments, architecture notes
- **API Documentation**: Function help, parameter descriptions

## 🏗️ Architecture Overview

### Core Components

1. **State Management**: Tracks cleanup progress across reboots
2. **Logging System**: Session-based logging with multiple output files
3. **Safe Mode Handler**: Manages Safe Mode transitions
4. **Driver Operations**: Core driver removal functionality
5. **Error Recovery**: Handles failures and retry logic

### Adding New Features

When adding new features:

1. **Consider state management**: How does this affect the cleanup state?
2. **Add appropriate logging**: Ensure operations are properly logged
3. **Handle errors gracefully**: Provide meaningful error messages
4. **Test edge cases**: Consider unusual scenarios
5. **Update documentation**: Keep docs current with changes

## 🔧 Development Tools

### Recommended VS Code Extensions

- **PowerShell**: Official PowerShell extension
- **GitLens**: Git integration and history
- **Bracket Pair Colorizer**: Visual bracket matching
- **TODO Highlight**: Highlight TODO comments

### Useful PowerShell Modules

```powershell
# Development and testing
Install-Module -Name Pester -Force
Install-Module -Name PSScriptAnalyzer -Force
```

## 📊 Project Structure

```
windows-driver-cleanup/
├── cleanup_driver.ps1          # Main script
├── tests/                      # Test files
│   ├── Run-Tests.ps1          # Test runner
│   └── *.Tests.ps1            # Individual test files
├── docs/                       # Additional documentation
├── .github/                    # GitHub workflows and templates
│   ├── workflows/             # CI/CD workflows
│   └── ISSUE_TEMPLATE/        # Issue templates
├── README.md                  # Main documentation
├── LICENSE                    # License file
├── CONTRIBUTING.md           # This file
└── CHANGELOG.md              # Version history
```

## 🎯 Contribution Ideas

### Easy (Good First Issues)

- Improve error messages
- Add more test cases
- Fix typos in documentation
- Add code comments

### Medium

- Add support for different driver types
- Improve Safe Mode detection
- Add configuration file support
- Create PowerShell module structure

### Advanced

- Add GUI interface
- Implement parallel processing
- Add remote driver cleanup
- Create installer package

## 💬 Communication

- **GitHub Issues**: For bug reports and feature requests
- **GitHub Discussions**: For questions and general discussion
- **Pull Request Comments**: For code review discussions

## 🏆 Recognition

Contributors will be recognized in:
- The README.md contributors section
- The CHANGELOG.md for their contributions
- GitHub's contributors graph

Thank you for helping make this tool better for everyone!
