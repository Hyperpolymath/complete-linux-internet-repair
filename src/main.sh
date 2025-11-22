#!/usr/bin/env bash
# Complete Linux Internet Repair Tool
# Main entry point

set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Version
VERSION="1.0.0"

# Source utilities
source "${SCRIPT_DIR}/utils/colors.sh"
source "${SCRIPT_DIR}/utils/logging.sh"
source "${SCRIPT_DIR}/utils/privileges.sh"
source "${SCRIPT_DIR}/utils/system.sh"
source "${SCRIPT_DIR}/utils/backup.sh"

# Source diagnostics
source "${SCRIPT_DIR}/diagnostics/dns.sh"
source "${SCRIPT_DIR}/diagnostics/interfaces.sh"
source "${SCRIPT_DIR}/diagnostics/routing.sh"
source "${SCRIPT_DIR}/diagnostics/connectivity.sh"
source "${SCRIPT_DIR}/diagnostics/firewall.sh"
source "${SCRIPT_DIR}/diagnostics/networkmanager.sh"

# Source repairs
source "${SCRIPT_DIR}/repairs/dns.sh"
source "${SCRIPT_DIR}/repairs/interfaces.sh"
source "${SCRIPT_DIR}/repairs/routing.sh"
source "${SCRIPT_DIR}/repairs/networkmanager.sh"

# Configuration
DRY_RUN="${DRY_RUN:-false}"
INTERACTIVE="${INTERACTIVE:-false}"
AUTO_REPAIR="${AUTO_REPAIR:-false}"

# Show usage
show_usage() {
    cat << EOF
Complete Linux Internet Repair Tool v${VERSION}

Usage: $(basename "$0") [OPTIONS] [COMMAND]

Commands:
    diagnose          Run all diagnostics (default)
    repair            Run all repairs (requires root)
    interactive       Run in interactive guided mode

    diagnose-dns      Diagnose DNS issues only
    diagnose-network  Diagnose network interfaces only
    diagnose-routing  Diagnose routing issues only
    diagnose-all      Run all diagnostics

    repair-dns        Repair DNS issues only
    repair-network    Repair network interfaces only
    repair-routing    Repair routing issues only
    repair-all        Run all repairs

Options:
    -h, --help        Show this help message
    -v, --version     Show version information
    -V, --verbose     Enable verbose output
    -q, --quiet       Quiet mode (errors only)
    -i, --interactive Run in interactive mode
    -a, --auto-repair Automatically repair found issues
    -d, --dry-run     Show what would be done without doing it
    --no-color        Disable colored output
    --log-file FILE   Write logs to FILE

Examples:
    # Run diagnostics
    $(basename "$0") diagnose

    # Run all repairs
    sudo $(basename "$0") repair

    # Interactive guided mode
    sudo $(basename "$0") interactive

    # Diagnose and auto-repair
    sudo $(basename "$0") --auto-repair diagnose

    # Repair DNS only
    sudo $(basename "$0") repair-dns

    # Dry run (show what would be done)
    $(basename "$0") --dry-run repair-all

EOF
}

# Show version
show_version() {
    echo "Complete Linux Internet Repair Tool v${VERSION}"
    echo "Bash version: ${BASH_VERSION}"
    echo "Platform: $(uname -s) $(uname -r)"
}

# Run all diagnostics
run_all_diagnostics() {
    log_section "Complete Network Diagnostics"

    local total_issues=0

    # Show system info
    log_info "Distribution: $(detect_distro)"
    log_info "Network Manager: $(detect_network_manager)"
    echo ""

    # Run diagnostics
    diagnose_interfaces
    total_issues=$((total_issues + $?))
    echo ""

    diagnose_routing
    total_issues=$((total_issues + $?))
    echo ""

    diagnose_dns
    total_issues=$((total_issues + $?))
    echo ""

    diagnose_connectivity
    total_issues=$((total_issues + $?))
    echo ""

    diagnose_firewall
    total_issues=$((total_issues + $?))
    echo ""

    diagnose_networkmanager
    total_issues=$((total_issues + $?))
    echo ""

    # Summary
    log_section "Diagnostic Summary"

    if [[ ${total_issues} -eq 0 ]]; then
        log_success "All diagnostics passed! No issues found."
        return 0
    else
        log_warn "Diagnostics found ${total_issues} issue(s)"

        if [[ "${AUTO_REPAIR}" == "true" ]]; then
            echo ""
            log_info "Auto-repair is enabled, proceeding with repairs..."
            run_all_repairs
        elif [[ "${INTERACTIVE}" == "true" ]]; then
            echo ""
            read -p "Would you like to attempt repairs? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                run_all_repairs
            fi
        else
            log_info "Run with --auto-repair or --interactive to fix issues"
        fi

        return 1
    fi
}

# Run all repairs
run_all_repairs() {
    log_section "Complete Network Repair"

    if [[ "${DRY_RUN}" == "true" ]]; then
        log_warn "DRY RUN MODE - No changes will be made"
        echo ""
    fi

    # Check privileges
    if ! check_privileges; then
        log_fatal "Repairs require root privileges. Please run with sudo."
    fi

    local total_issues=0

    # Run repairs in order
    repair_interfaces
    total_issues=$((total_issues + $?))
    echo ""

    repair_routing
    total_issues=$((total_issues + $?))
    echo ""

    repair_dns
    total_issues=$((total_issues + $?))
    echo ""

    repair_networkmanager
    total_issues=$((total_issues + $?))
    echo ""

    # Final connectivity test
    log_section "Final Connectivity Test"

    if check_internet "8.8.8.8" 3; then
        log_success "Internet connectivity is working!"

        if check_dns "google.com"; then
            log_success "DNS resolution is working!"
        else
            log_warn "DNS resolution is still not working"
        fi
    else
        log_error "Internet connectivity is still not working"
        total_issues=$((total_issues + 1))
    fi

    echo ""
    log_section "Repair Summary"

    if [[ ${total_issues} -eq 0 ]]; then
        log_success "All repairs completed successfully!"
        return 0
    else
        log_warn "Some issues may remain. You might need manual intervention."
        log_info "Check logs for details or run 'diagnose' again"
        return 1
    fi
}

# Interactive guided mode
run_interactive_mode() {
    INTERACTIVE="true"

    clear
    cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║   Complete Linux Internet Repair Tool                    ║
║   Interactive Guided Mode                                ║
╚═══════════════════════════════════════════════════════════╝

EOF

    log_info "This tool will help diagnose and repair your internet connection."
    echo ""

    # Check privileges
    if ! check_privileges; then
        log_warn "Some repairs will require root privileges"
        read -p "Would you like to request sudo access now? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            require_root "Interactive repairs require root privileges"
        fi
    else
        log_success "Running with appropriate privileges"
    fi

    echo ""

    # Main menu
    while true; do
        echo ""
        log_section "What would you like to do?"
        echo ""
        echo "  1) Run complete diagnostics"
        echo "  2) Run specific diagnostic"
        echo "  3) Attempt automatic repairs"
        echo "  4) Run specific repair"
        echo "  5) View backup files"
        echo "  6) Exit"
        echo ""
        read -p "Enter choice [1-6]: " choice

        case ${choice} in
            1)
                echo ""
                run_all_diagnostics
                ;;
            2)
                echo ""
                log_info "Select diagnostic:"
                echo "  1) DNS"
                echo "  2) Network Interfaces"
                echo "  3) Routing"
                echo "  4) Connectivity"
                echo "  5) Firewall"
                echo "  6) NetworkManager"
                read -p "Enter choice [1-6]: " diag_choice

                echo ""
                case ${diag_choice} in
                    1) diagnose_dns ;;
                    2) diagnose_interfaces ;;
                    3) diagnose_routing ;;
                    4) diagnose_connectivity ;;
                    5) diagnose_firewall ;;
                    6) diagnose_networkmanager ;;
                    *) log_error "Invalid choice" ;;
                esac
                ;;
            3)
                echo ""
                read -p "This will attempt to automatically repair issues. Continue? (y/N): " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    run_all_repairs
                fi
                ;;
            4)
                echo ""
                log_info "Select repair:"
                echo "  1) DNS"
                echo "  2) Network Interfaces"
                echo "  3) Routing"
                echo "  4) NetworkManager"
                read -p "Enter choice [1-4]: " repair_choice

                echo ""
                case ${repair_choice} in
                    1) repair_dns ;;
                    2) repair_interfaces ;;
                    3) repair_routing ;;
                    4) repair_networkmanager ;;
                    *) log_error "Invalid choice" ;;
                esac
                ;;
            5)
                echo ""
                list_backups
                ;;
            6)
                echo ""
                log_info "Thank you for using Complete Linux Internet Repair Tool"
                exit 0
                ;;
            *)
                log_error "Invalid choice"
                ;;
        esac

        echo ""
        read -p "Press Enter to continue..." -r
    done
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -v|--version)
                show_version
                exit 0
                ;;
            -V|--verbose)
                VERBOSE="true"
                export VERBOSE
                shift
                ;;
            -q|--quiet)
                CURRENT_LOG_LEVEL="ERROR"
                export CURRENT_LOG_LEVEL
                shift
                ;;
            -i|--interactive)
                INTERACTIVE="true"
                export INTERACTIVE
                shift
                ;;
            -a|--auto-repair)
                AUTO_REPAIR="true"
                export AUTO_REPAIR
                shift
                ;;
            -d|--dry-run)
                DRY_RUN="true"
                export DRY_RUN
                shift
                ;;
            --no-color)
                USE_COLORS="never"
                export USE_COLORS
                shift
                ;;
            --log-file)
                LOG_FILE="$2"
                LOG_TO_FILE="true"
                export LOG_FILE LOG_TO_FILE
                shift 2
                ;;
            diagnose|diagnose-all)
                run_all_diagnostics
                exit $?
                ;;
            diagnose-dns)
                diagnose_dns
                exit $?
                ;;
            diagnose-network)
                diagnose_interfaces
                exit $?
                ;;
            diagnose-routing)
                diagnose_routing
                exit $?
                ;;
            repair|repair-all)
                run_all_repairs
                exit $?
                ;;
            repair-dns)
                repair_dns
                exit $?
                ;;
            repair-network)
                repair_interfaces
                exit $?
                ;;
            repair-routing)
                repair_routing
                exit $?
                ;;
            interactive)
                run_interactive_mode
                exit $?
                ;;
            *)
                log_error "Unknown option: $1"
                echo ""
                show_usage
                exit 1
                ;;
        esac
    done
}

# Main function
main() {
    # Show header
    echo ""
    log_info "Complete Linux Internet Repair Tool v${VERSION}"
    echo ""

    # Parse arguments
    if [[ $# -eq 0 ]]; then
        # No arguments, run diagnostics
        run_all_diagnostics
    else
        parse_args "$@"
    fi
}

# Run main function
main "$@"
