#!/usr/bin/env bats

setup_file() {
    PROJECT_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
    export PROJECT_ROOT

    ORIGINAL_HOME="${HOME:-}"
    export ORIGINAL_HOME

    HOME="$(mktemp -d "${BATS_TEST_DIRNAME}/tmp-scripts-home.XXXXXX")"
    export HOME

    mkdir -p "$HOME"
}

teardown_file() {
    if [[ "$HOME" == "${BATS_TEST_DIRNAME}/tmp-"* ]]; then
        rm -rf "$HOME"
    fi
    if [[ -n "${ORIGINAL_HOME:-}" ]]; then
        export HOME="$ORIGINAL_HOME"
    fi
}

setup() {
    # Safety: refuse to operate on a real home directory.
    if [[ "$HOME" != "${BATS_TEST_DIRNAME}/tmp-"* ]]; then
        printf 'FATAL: HOME is not a test temp dir: %s\n' "$HOME" >&2
        return 1
    fi
    export TERM="dumb"
    rm -rf "${HOME:?}"/*
    mkdir -p "$HOME"
}

@test "check.sh --help shows usage information" {
    run "$PROJECT_ROOT/scripts/check.sh" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage"* ]] || return 1
    [[ "$output" == *"--format"* ]] || return 1
    [[ "$output" == *"--no-format"* ]]
}

@test "check.sh script exists and is valid" {
    [ -f "$PROJECT_ROOT/scripts/check.sh" ]
    [ -x "$PROJECT_ROOT/scripts/check.sh" ]

    run /bin/bash -c "grep -q 'Diggory Check' '$PROJECT_ROOT/scripts/check.sh'"
	[ "$status" -eq 0 ]
}

@test "diagnostic guidance check rejects equivalent pipe-to-shell spellings across lines" {
	run env HOME="$HOME" PROJECT_ROOT="$PROJECT_ROOT" /bin/bash --noprofile --norc <<'EOF'
set -euo pipefail
eval "$(sed -n '/^check_diagnostic_guidance()/,/^}/p' "$PROJECT_ROOT/scripts/check.sh")"

safe="$HOME/safe-guidance.md"
cat > "$safe" <<'SAFE'
Download `Diggory-Diagnose.command` with `curl -o`, inspect it, then open it manually.
SAFE
check_diagnostic_guidance "$safe"

assert_unsafe() {
	local name="$1"
	local guidance="$2"
	local unsafe="$HOME/unsafe-${name}.md"
	printf '%s\n' "$guidance" > "$unsafe"
	if check_diagnostic_guidance "$unsafe"; then
		echo "UNEXPECTED_UNSAFE_PASS:$name"
		exit 1
	fi
}

assert_unsafe path '`curl https://example.test/Diggory-Diagnose.command | /bin/bash`'
assert_unsafe command '`curl https://example.test/Diggory-Diagnose.command | command bash`'
assert_unsafe sudo '`curl https://example.test/Diggory-Diagnose.command | sudo -u root bash`'
assert_unsafe env $'`curl https://example.test/Diggory-Diagnose.command \\\n  | env MODE=1 zsh`'
assert_unsafe tee $'`curl https://example.test/Diggory-Diagnose.command |\n  tee /tmp/diagnose | dash`'
assert_unsafe quoted "\`curl https://example.test/Diggory-Diagnose.command | 'bash'\`"
assert_unsafe ansi_c "\`curl https://example.test/Diggory-Diagnose.command | \$'bash'\`"
assert_unsafe ksh '`curl https://example.test/Diggory-Diagnose.command | ksh`'
assert_unsafe escaped '`curl https://example.test/Diggory-Diagnose.command | ba\sh`'
EOF

	[ "$status" -eq 0 ] || { echo "$output"; return 1; }
	[[ "$output" != *"UNEXPECTED_UNSAFE_PASS:"* ]]
}

@test "test.sh script exists and is valid" {
    [ -f "$PROJECT_ROOT/scripts/test.sh" ]
    [ -x "$PROJECT_ROOT/scripts/test.sh" ]

    run /bin/bash -c "grep -q 'Diggory Test Runner' '$PROJECT_ROOT/scripts/test.sh'"
    [ "$status" -eq 0 ]
}

@test "test.sh includes test lint step" {
    run /bin/bash -c "grep -q 'Test script lint' '$PROJECT_ROOT/scripts/test.sh'"
    [ "$status" -eq 0 ]
}

@test "Makefile has build target for Go binaries" {
    run /bin/bash -c "grep -Eq '(^|[[:space:]])(go|\\$\\(GO\\))[[:space:]]+build' '$PROJECT_ROOT/Makefile'"
    [ "$status" -eq 0 ]
}

@test "release builds disable cgo and check minimum macOS version" {
    run /bin/bash -c "grep -q '^RELEASE_GO_ENV := CGO_ENABLED=0$' '$PROJECT_ROOT/Makefile'"
    [ "$status" -eq 0 ]
    run /bin/bash -c "grep -q 'scripts/check_release_minos.sh' '$PROJECT_ROOT/.github/workflows/release.yml'"
    [ "$status" -eq 0 ]
    [ -x "$PROJECT_ROOT/scripts/check_release_minos.sh" ]
}

@test "release workflow does not bump a third-party Homebrew Core fork" {
    local workflow="$PROJECT_ROOT/.github/workflows/release.yml"

    run grep -E 'update-homebrew-core:|tw93/homebrew-core|head=tw93:' "$workflow"
    [ "$status" -ne 0 ]
}

@test "setup-quick-launchers.sh has detect_digg function" {
    run /bin/bash -c "grep -q 'detect_digg()' '$PROJECT_ROOT/scripts/setup-quick-launchers.sh'"
    [ "$status" -eq 0 ]
}

@test "setup-quick-launchers.sh has Raycast script generation" {
    run /bin/bash -c "grep -q 'create_raycast_commands' '$PROJECT_ROOT/scripts/setup-quick-launchers.sh'"
    [ "$status" -eq 0 ]
    run /bin/bash -c "grep -q 'write_raycast_script' '$PROJECT_ROOT/scripts/setup-quick-launchers.sh'"
    [ "$status" -eq 0 ]
}

@test "setup-quick-launchers.sh generates Raycast scripts with discoverable metadata" {
    local fake_bin="$HOME/fake-bin"
    mkdir -p "$fake_bin"
    cat > "$fake_bin/digg" <<'EOF'
#!/bin/bash
exit 0
EOF
    chmod +x "$fake_bin/digg"

    run env HOME="$HOME" TERM="dumb" PATH="$fake_bin:/usr/bin:/bin:/usr/sbin:/sbin" \
        "$PROJECT_ROOT/scripts/setup-quick-launchers.sh"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Raycast: Diggory Clean | Alfred keyword: clean"* ]] || return 1
    [[ "$output" == *"Raycast: Diggory Status | Alfred keyword: status"* ]] || return 1

    local raycast_dir="$HOME/Library/Application Support/Raycast/script-commands"
    [ -d "$raycast_dir" ]

    local clean_script="$raycast_dir/diggory-clean.sh"
    local uninstall_script="$raycast_dir/diggory-uninstall.sh"
    local optimize_script="$raycast_dir/diggory-optimize.sh"
    local analyze_script="$raycast_dir/diggory-analyze.sh"
    local status_script="$raycast_dir/diggory-status.sh"

    [ -x "$clean_script" ]
    [ -x "$uninstall_script" ]
    [ -x "$optimize_script" ]
    [ -x "$analyze_script" ]
    [ -x "$status_script" ]

    run grep -q '^# @raycast.title Diggory Clean$' "$clean_script"
    [ "$status" -eq 0 ]
    run grep -q '^# @raycast.title Diggory Uninstall$' "$uninstall_script"
    [ "$status" -eq 0 ]
    run grep -q '^# @raycast.title Diggory Optimize$' "$optimize_script"
    [ "$status" -eq 0 ]
    run grep -q '^# @raycast.title Diggory Analyze$' "$analyze_script"
    [ "$status" -eq 0 ]
    run grep -q '^# @raycast.title Diggory Status$' "$status_script"
    [ "$status" -eq 0 ]

    run grep -q '^# @raycast.description Deep system cleanup with Diggory$' "$clean_script"
    [ "$status" -eq 0 ]
    run grep -q '^# @raycast.description Uninstall applications with Diggory$' "$uninstall_script"
    [ "$status" -eq 0 ]
    run grep -q '^# @raycast.description System health checks and optimization$' "$optimize_script"
    [ "$status" -eq 0 ]
    run grep -q '^# @raycast.description Disk space analysis with Diggory$' "$analyze_script"
    [ "$status" -eq 0 ]
    run grep -q '^# @raycast.description Live system status dashboard$' "$status_script"
    [ "$status" -eq 0 ]
}

@test "install.sh supports dev branch installs" {
    run env PROJECT_ROOT="$PROJECT_ROOT" /bin/bash --noprofile --norc <<'EOF'
set -euo pipefail
eval "$(sed -n '/^source_archive_url()/,/^}/p' "$PROJECT_ROOT/install.sh")"
[[ "$(source_archive_url dev "")" == "https://github.com/superstack-oss/Diggory-CLI/archive/refs/heads/dev.tar.gz" ]]
EOF
    [ "$status" -eq 0 ] || { echo "$output"; return 1; }
    run /bin/bash -c "grep -q 'DIGGORY_VERSION=\"dev\"' '$PROJECT_ROOT/install.sh'"
    [ "$status" -eq 0 ]
}

@test "release workflow does not publish Homebrew from this repo yet" {
    run grep -Eq 'update-homebrew-core:|update-personal-tap:|tw93/homebrew-tap|PAT_TOKEN' "$PROJECT_ROOT/.github/workflows/release.yml"
    [ "$status" -ne 0 ]

    [ ! -e "$PROJECT_ROOT/scripts/update_homebrew_tap_formula.sh" ]
}

@test "no shell function shares another's body under a different name" {
    # This gate also lives in check.sh, but CI runs scripts/test.sh and never
    # check.sh, so without this case it could not block a pull request. The
    # class it catches is invisible to grep: the copies that matter have
    # already had their variables renamed, which is why review reads them as
    # separate helpers. Run the script with --list to inspect every group.
    run python3 "$PROJECT_ROOT/scripts/audit_function_duplication.py"
    [ "$status" -eq 0 ] || {
        echo "$output"
        return 1
    }
}
