# Contributing to Complete Linux Internet Repair Tool

First off, thank you for considering contributing to the Complete Linux Internet Repair Tool! It's people like you that make this tool better for everyone.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
  - [Reporting Bugs](#reporting-bugs)
  - [Suggesting Enhancements](#suggesting-enhancements)
  - [Pull Requests](#pull-requests)
- [Development Setup](#development-setup)
- [Coding Guidelines](#coding-guidelines)
- [Testing](#testing)
- [Documentation](#documentation)

## Code of Conduct

This project and everyone participating in it is governed by a Code of Conduct. By participating, you are expected to uphold this code. Please be respectful and constructive in all interactions.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates.

When you create a bug report, please include as many details as possible:

- **Use a clear and descriptive title**
- **Describe the exact steps to reproduce the problem**
- **Provide specific examples**
- **Describe the behavior you observed and what you expected**
- **Include system information**:
  - Linux distribution and version
  - Kernel version (`uname -r`)
  - Network manager type (NetworkManager, systemd-networkd, etc.)
  - Bash version

**Bug Report Template:**

```markdown
## Description
A clear description of the bug.

## Steps to Reproduce
1. Run command '...'
2. See error '...'

## Expected Behavior
What you expected to happen.

## Actual Behavior
What actually happened.

## System Information
- Distribution: Ubuntu 22.04
- Kernel: 5.15.0-91
- Network Manager: NetworkManager 1.36.6
- Bash: 5.1.16

## Additional Context
Any other relevant information.
```

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, please include:

- **Use a clear and descriptive title**
- **Provide a detailed description of the suggested enhancement**
- **Explain why this enhancement would be useful**
- **List some examples of where this would be beneficial**

### Pull Requests

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Run the test suite (`./tests/run-tests.sh`)
5. Commit your changes (`git commit -m 'Add some amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

**Pull Request Guidelines:**

- Follow the coding guidelines below
- Update documentation for any changed functionality
- Add tests for new features
- Ensure all tests pass
- Keep pull requests focused on a single feature or fix
- Write clear commit messages

## Development Setup

### Prerequisites

- Bash 4.0+
- Git
- A Linux system for testing
- (Optional) Virtual machines for multi-distribution testing

### Getting Started

```bash
# Clone your fork
git clone https://github.com/YOUR-USERNAME/complete-linux-internet-repair.git
cd complete-linux-internet-repair

# Make scripts executable
chmod +x network-repair src/main.sh tests/*.sh

# Run tests
./tests/run-tests.sh

# Test the tool (without installation)
./network-repair --help
./network-repair diagnose
```

### Project Structure

```
src/
├── main.sh              # Main entry point
├── diagnostics/         # Diagnostic modules
│   └── *.sh            # Each diagnostic in its own file
├── repairs/            # Repair modules
│   └── *.sh            # Each repair in its own file
└── utils/              # Utility functions
    └── *.sh            # Shared utilities

tests/
├── run-tests.sh        # Main test runner
└── test-*.sh           # Individual test files

config/                 # Configuration files
docs/                   # Documentation
examples/               # Usage examples
```

## Coding Guidelines

### Shell Script Standards

Follow the [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html) with these specifics:

#### File Header

```bash
#!/usr/bin/env bash
# Brief description of the script

set -euo pipefail  # For non-sourced scripts
```

#### Naming Conventions

- **Functions**: Use lowercase with underscores
  ```bash
  check_dns_configuration() {
      # ...
  }
  ```

- **Variables**: Use lowercase for local, UPPERCASE for global
  ```bash
  local interface_name="eth0"
  GLOBAL_CONFIG_PATH="/etc/network"
  ```

- **Constants**: Use UPPERCASE
  ```bash
  readonly MAX_RETRIES=3
  readonly DEFAULT_TIMEOUT=30
  ```

#### Function Structure

```bash
# Brief description of what the function does
#
# Arguments:
#   $1 - description of first argument
#   $2 - description of second argument
#
# Returns:
#   0 on success, 1 on failure
function_name() {
    local arg1="$1"
    local arg2="${2:-default_value}"

    # Function body

    return 0
}
```

#### Error Handling

- Always check command exit codes
- Use appropriate error messages
- Return non-zero on errors

```bash
if ! some_command; then
    log_error "Command failed: some_command"
    return 1
fi
```

#### Logging

Use the logging utility functions:

```bash
log_debug "Detailed diagnostic information"
log_info "General information"
log_success "Operation completed successfully"
log_warn "Warning message"
log_error "Error message"
log_fatal "Fatal error - will exit"
```

#### Safety Checks

- Validate inputs
- Check for required privileges
- Backup before modifying files
- Test destructive operations in dry-run mode

```bash
# Check root privileges
require_root "This operation requires root privileges"

# Backup before modification
backup_file "/etc/resolv.conf" "resolv.conf"

# Validate interface name
interface=$(sanitize_input "${interface}")
```

### Adding New Features

#### Adding a Diagnostic Module

1. Create `src/diagnostics/your-module.sh`
2. Source utilities at the top
3. Implement check functions that return 0 (success) or 1 (failure)
4. Create a main diagnostic function named `diagnose_yourmodule`
5. Add to `src/main.sh`
6. Add tests
7. Update documentation

Example:

```bash
#!/usr/bin/env bash
# Your module diagnostics

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/logging.sh"
source "${SCRIPT_DIR}/../utils/system.sh"

check_something() {
    log_section "Checking Something"

    # Perform checks
    if some_condition; then
        log_success "Check passed"
        return 0
    else
        log_error "Check failed"
        return 1
    fi
}

diagnose_yourmodule() {
    log_section "Your Module Diagnostics"

    local total_issues=0

    check_something
    total_issues=$((total_issues + $?))

    return ${total_issues}
}
```

#### Adding a Repair Module

1. Create `src/repairs/your-module.sh`
2. Implement repair functions
3. Always backup before changes
4. Verify repairs worked
5. Provide rollback on failure
6. Create main repair function named `repair_yourmodule`
7. Add to `src/main.sh`
8. Add tests
9. Update documentation

## Testing

### Running Tests

```bash
# Run all tests
./tests/run-tests.sh

# Run specific test
./tests/test-utils.sh
```

### Writing Tests

Create test files in `tests/` directory:

```bash
#!/usr/bin/env bash
# Test description

test_something() {
    # Arrange
    local input="test"

    # Act
    local result=$(some_function "${input}")

    # Assert
    if [[ "${result}" == "expected" ]]; then
        echo "✓ Test passed"
        return 0
    else
        echo "✗ Test failed"
        return 1
    fi
}
```

### Testing Checklist

- [ ] Syntax validation passes (`bash -n script.sh`)
- [ ] ShellCheck passes (if available)
- [ ] All unit tests pass
- [ ] Manual testing on target distributions
- [ ] Documentation updated
- [ ] Examples added/updated

## Documentation

### Code Documentation

- Add comments for complex logic
- Document function parameters and return values
- Include usage examples for public functions

### User Documentation

When adding features, update:

- `README.md` - for user-facing features
- `CLAUDE.md` - for AI development guidance
- `docs/` - for detailed documentation
- `examples/` - for usage examples

### Commit Messages

Write clear, descriptive commit messages:

```
Add DNS fallback server configuration

- Implement automatic fallback to secondary DNS servers
- Add configuration option for custom DNS server list
- Update tests to cover fallback scenarios
- Document new DNS_FALLBACK_SERVERS config option

Fixes #123
```

Format:
- First line: Brief summary (50 chars or less)
- Blank line
- Detailed description
- Reference issues/PRs

## Questions?

Feel free to open an issue with the `question` label if you have any questions about contributing!

Thank you for contributing! 🎉
