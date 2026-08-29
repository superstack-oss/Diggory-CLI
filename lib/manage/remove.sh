#!/bin/bash
# Diggory self-removal: Homebrew formula, manual binaries, config/cache/logs.
# Extracted from the `diggory` dispatcher, which now only routes.

set -euo pipefail

if [[ -n "${DIGGORY_MANAGE_REMOVE_LOADED:-}" ]]; then
    return 0
fi
readonly DIGGORY_MANAGE_REMOVE_LOADED=1

# Remove flow (Homebrew + manual + config/cache).
remove_diggory() {
    local dry_run_mode="${1:-false}"
    local test_mode=false
    if [[ "${DIGGORY_TEST_MODE:-0}" == "1" ]]; then
        test_mode=true
    fi

    if [[ -t 1 ]]; then
        start_inline_spinner "Detecting Diggory installations..."
    else
        echo "Detecting installations..."
    fi

    local is_homebrew=false
    local brew_cmd=""
    local brew_has_diggory="false"
    local -a manual_installs=()
    local -a alias_installs=()

    if [[ "$test_mode" != "true" ]]; then
        if command -v brew > /dev/null 2>&1; then
            brew_cmd="brew"
        elif [[ -x "/opt/homebrew/bin/brew" ]]; then
            brew_cmd="/opt/homebrew/bin/brew"
        elif [[ -x "/usr/local/bin/brew" ]]; then
            brew_cmd="/usr/local/bin/brew"
        fi

        if [[ -n "$brew_cmd" ]]; then
            if brew_diggory_formula_installed "$brew_cmd"; then
                brew_has_diggory="true"
            fi
        fi

        if [[ "$brew_has_diggory" == "true" ]] || is_homebrew_install; then
            is_homebrew=true
        fi
    fi

    local found_diggory
    found_diggory=""
    if [[ "$test_mode" != "true" ]]; then
        found_diggory=$(command -v diggory 2> /dev/null || true)
        if [[ -n "$found_diggory" && -f "$found_diggory" ]]; then
            if [[ ! -L "$found_diggory" ]] || ! readlink "$found_diggory" | grep -q "Cellar/diggory"; then
                manual_installs+=("$found_diggory")
            fi
        fi
    fi

    local -a fallback_paths=()
    if [[ "$test_mode" == "true" ]]; then
        fallback_paths=("$HOME/.local/bin/diggory")
    else
        fallback_paths=(
            "/usr/local/bin/diggory"
            "$HOME/.local/bin/diggory"
            "/opt/local/bin/diggory"
        )
    fi

    for path in "${fallback_paths[@]}"; do
        if [[ -f "$path" && "$path" != "$found_diggory" ]]; then
            if [[ ! -L "$path" ]] || ! readlink "$path" | grep -q "Cellar/diggory"; then
                manual_installs+=("$path")
            fi
        fi
    done

    local found_digg
    found_digg=""
    if [[ "$test_mode" != "true" ]]; then
        found_digg=$(command -v digg 2> /dev/null || true)
        if [[ -n "$found_digg" && -f "$found_digg" ]]; then
            if [[ ! -L "$found_digg" ]] || ! readlink "$found_digg" | grep -q "Cellar/diggory"; then
                alias_installs+=("$found_digg")
            fi
        fi
    fi

    local -a alias_fallback=()
    if [[ "$test_mode" == "true" ]]; then
        alias_fallback=("$HOME/.local/bin/digg")
    else
        alias_fallback=(
            "/usr/local/bin/digg"
            "$HOME/.local/bin/digg"
            "/opt/local/bin/digg"
        )
    fi

    for alias in "${alias_fallback[@]}"; do
        if [[ -f "$alias" && "$alias" != "$found_digg" ]]; then
            if [[ ! -L "$alias" ]] || ! readlink "$alias" | grep -q "Cellar/diggory"; then
                alias_installs+=("$alias")
            fi
        fi
    done

    if [[ -t 1 ]]; then
        stop_inline_spinner
    fi

    printf '\n'

    local manual_count=${#manual_installs[@]}
    local alias_count=${#alias_installs[@]}
    if [[ "$is_homebrew" == "false" && ${manual_count:-0} -eq 0 && ${alias_count:-0} -eq 0 ]]; then
        printf '%s\n\n' "${YELLOW}No Diggory installation detected${NC}"
        exit 0
    fi

    # Dry-run mode: show preview and exit without confirmation
    if [[ "$dry_run_mode" == "true" ]]; then
        echo -e "${YELLOW}${ICON_DRY_RUN} DRY RUN MODE${NC}, no files will be removed"
        echo ""
        echo -e "${YELLOW}Remove Diggory${NC}, would delete the following:"
        if [[ "$is_homebrew" == "true" ]]; then
            echo -e "  ${GRAY}${ICON_LIST} Would run: brew uninstall --force diggory${NC}"
        fi
        if [[ ${manual_count:-0} -gt 0 ]]; then
            for install in "${manual_installs[@]}"; do
                [[ -f "$install" ]] && echo -e "  ${GRAY}${ICON_LIST} Would remove: ${install}${NC}"
            done
        fi
        if [[ ${alias_count:-0} -gt 0 ]]; then
            for alias in "${alias_installs[@]}"; do
                [[ -f "$alias" ]] && echo -e "  ${GRAY}${ICON_LIST} Would remove: ${alias}${NC}"
            done
        fi
        [[ -d "$HOME/.cache/diggory" ]] && echo -e "  ${GRAY}${ICON_LIST} Would remove: $HOME/.cache/diggory${NC}"
        [[ -d "$HOME/.config/diggory" ]] && echo -e "  ${GRAY}${ICON_LIST} Would move to Trash: $HOME/.config/diggory${NC}"
        [[ -d "$HOME/Library/Logs/diggory" ]] && echo -e "  ${GRAY}${ICON_LIST} Would remove: $HOME/Library/Logs/diggory${NC}"

        printf '\n%s\n\n' "${GREEN}${ICON_SUCCESS}${NC} Dry run complete, no changes made"
        exit 0
    fi

    echo -e "${YELLOW}Remove Diggory${NC}, will delete the following:"
    if [[ "$is_homebrew" == "true" ]]; then
        echo "  ${ICON_LIST} Diggory via Homebrew"
    fi
    for install in ${manual_installs[@]+"${manual_installs[@]}"} ${alias_installs[@]+"${alias_installs[@]}"}; do
        echo "  ${ICON_LIST} $install"
    done
    echo "  ${ICON_LIST} ~/.config/diggory (to Trash)"
    echo "  ${ICON_LIST} ~/.cache/diggory"
    echo "  ${ICON_LIST} ~/Library/Logs/diggory"
    echo -ne "${PURPLE}${ICON_ARROW}${NC} Press ${GREEN}Enter${NC} to confirm, ${GRAY}ESC${NC} to cancel: "

    IFS= read -r -s -n1 key || key=""
    drain_pending_input # Clean up any escape sequence remnants
    case "$key" in
        $'\e')
            exit 0
            ;;
        "" | $'\n' | $'\r')
            printf "\r\033[K" # Clear the prompt line
            ;;
        *)
            exit 0
            ;;
    esac

    local has_error=false
    if [[ "$is_homebrew" == "true" ]]; then
        if [[ -z "$brew_cmd" ]]; then
            log_error "Homebrew command not found. Please ensure Homebrew is installed and in your PATH."
            log_warning "Manual step: brew uninstall --force diggory"
            exit 1
        fi

        log_info "Attempting to uninstall Diggory via Homebrew..."
        local brew_uninstall_output
        if ! brew_uninstall_output=$("$brew_cmd" uninstall --force diggory 2>&1); then
            has_error=true
            log_error "Homebrew uninstallation failed:"
            printf "%s\n" "$brew_uninstall_output" | sed "s/^/${RED}  | ${NC}/" >&2
            log_warning "Manual step: ${YELLOW}brew uninstall --force diggory${NC}"
            echo "" # Add a blank line for readability
        else
            log_success "Diggory uninstalled via Homebrew."
        fi
    fi
    if [[ ${manual_count:-0} -gt 0 ]]; then
        for install in "${manual_installs[@]}"; do
            if [[ -f "$install" ]]; then
                if [[ ! -w "$(dirname "$install")" ]]; then
                    if [[ "${DIGGORY_TEST_MODE:-0}" == "1" || "${DIGGORY_TEST_NO_AUTH:-0}" == "1" ]] || ! sudo rm -f "$install" 2> /dev/null; then
                        has_error=true
                    fi
                else
                    if ! rm -f "$install" 2> /dev/null; then
                        has_error=true
                    fi
                fi
            fi
        done
    fi
    if [[ ${alias_count:-0} -gt 0 ]]; then
        for alias in "${alias_installs[@]}"; do
            if [[ -f "$alias" ]]; then
                if [[ ! -w "$(dirname "$alias")" ]]; then
                    if [[ "${DIGGORY_TEST_MODE:-0}" == "1" || "${DIGGORY_TEST_NO_AUTH:-0}" == "1" ]] || ! sudo rm -f "$alias" 2> /dev/null; then
                        has_error=true
                    fi
                else
                    if ! rm -f "$alias" 2> /dev/null; then
                        has_error=true
                    fi
                fi
            fi
        done
    fi
    if [[ -d "$HOME/.cache/diggory" ]]; then
        rm -rf "$HOME/.cache/diggory" 2> /dev/null || true # SAFE: hardcoded Diggory-owned dir, -d guarded
    fi
    if [[ -d "$HOME/.config/diggory" ]]; then
        # The config dir holds user-authored state (whitelist, purge config),
        # which is the one thing here a reinstall cannot rebuild. Move it to
        # Trash so it stays recoverable (#1346); cache and logs around it are
        # rebuildable and stay permanent removals. On failure leave it in
        # place rather than falling back to deletion.
        local config_trash="$HOME/.Trash/diggory-config"
        local config_trash_n=1
        while [[ -e "$config_trash" || -L "$config_trash" ]]; do
            config_trash="$HOME/.Trash/diggory-config-$config_trash_n"
            config_trash_n=$((config_trash_n + 1))
        done
        if ! mkdir -p "$HOME/.Trash" 2> /dev/null ||
            ! mv -f "$HOME/.config/diggory" "$config_trash" 2> /dev/null; then
            has_error=true
            log_warning "Could not move ~/.config/diggory to Trash; left in place"
        fi
    fi
    if [[ -d "$HOME/Library/Logs/diggory" ]]; then
        rm -rf "$HOME/Library/Logs/diggory" 2> /dev/null || true # SAFE: hardcoded Diggory-owned dir, -d guarded
    fi

    local final_message
    if [[ "$has_error" == "true" ]]; then
        final_message="${YELLOW}${ICON_ERROR} Diggory uninstalled with some errors, thank you for using Diggory!${NC}"
    else
        final_message="${GREEN}${ICON_SUCCESS} Diggory uninstalled successfully, thank you for using Diggory!${NC}"
    fi
    printf '\n%s\n\n' "$final_message"

    exit 0
}
