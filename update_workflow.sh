#!/bin/bash
set -euo pipefail

WORKFLOW_FILE=".github/workflows/e2e-test.yml"
TOTAL_SCENARIOS=28

[[ -f "$WORKFLOW_FILE" ]] || { echo "❌ Workflow not found: $WORKFLOW_FILE"; exit 1; }

# --- Utility functions ---
sed_edit() {
    local pattern="$1"
    if [[ "$OSTYPE" == "darwin"* ]]; then sed -i '' "$pattern" "$WORKFLOW_FILE"
    else sed -i "$pattern" "$WORKFLOW_FILE"; fi
}

msg() { echo -e "\033[1;32m$1\033[0m"; }
err() { echo -e "\033[1;31m$1\033[0m" >&2; }

set_config() {
    local key="$1" value="$2"
    sed_edit "s|#${key}:.*|${key}: '${value}'|"
    sed_edit "s|^[[:space:]]*${key}:|          ${key}:|"
}

clear_config() {
    for key in bridgecli_base_url bridgecli_download_url bridgecli_download_version; do
        sed_edit "s|^[[:space:]]*${key}:|          #${key}:|"
    done
}

auto_commit() {
    local msg="$1"
    git rev-parse --git-dir >/dev/null 2>&1 || { echo "⚠️ Not a git repo"; return; }
    git add "$WORKFLOW_FILE"
    git commit -m "$msg" >/dev/null 2>&1 && git push --force >/dev/null 2>&1 && msg "✅ $msg" || echo "⚠️ Nothing to commit"
}

# --- Core configuration ---
set_base_url() {
    set_config "bridgecli_base_url" "https://repo.blackduck.com/bds-integrations-release/com/blackduck/integration/bridge/binaries/"
}

set_download_url() {
    local url
    if grep -q "enable_bridgecli_thin_client: true" "$WORKFLOW_FILE"; then
        url="https://repo.blackduck.com/bds-integrations-release/com/blackduck/integration/bridge/binaries/bridge-cli-thin-client/3.0.18/bridge-cli-macos_arm.zip"
    else
        url="https://repo.blackduck.com/bds-integrations-release/com/blackduck/integration/bridge/binaries/bridge-cli-bundle/3.3.0/bridge-cli-bundle-3.3.0-macos_arm.zip"
    fi
    set_config "bridgecli_download_url" "$url"
}

set_version() {
    local version
    if grep -q "enable_bridgecli_thin_client: true" "$WORKFLOW_FILE"; then version="3.0.43"; else version="3.8.1"; fi
    set_config "bridgecli_download_version" "$version"
}

toggle_env() {
    local key="$1" value="$2"
    sed_edit "s|${key}: .*|${key}: ${value}|"
}

# --- Scenario logic ---
apply_scenario() {
    local n="$1"
    [[ $n -ge 1 && $n -le $TOTAL_SCENARIOS ]] || { err "Invalid scenario"; return; }

    local env type base download ver
    (( n <= 14 )) && type="Thin" || type="Bundle"
    (( n % 14 <= 6 && n % 14 != 0 )) || (( n <= 6 )) || (( n >= 15 && n <= 20 )) && env="Airgap" || env="Non-Airgap"
    case $(( (n - 1) % 6 + 1 )) in
        1) base=0; download=0; ver=1;;
        2) base=0; download=0; ver=0;;
        3) base=1; download=0; ver=1;;
        4) base=1; download=0; ver=0;;
        5) base=0; download=1; ver=1;;
        6) base=0; download=1; ver=0;;
    esac

    toggle_env "network_airgap" $([[ $env == "Airgap" ]] && echo true || echo false)
    toggle_env "enable_bridgecli_thin_client" $([[ $type == "Thin" ]] && echo true || echo false)

    clear_config
    (( base )) && set_base_url
    (( download )) && set_download_url
    (( ver )) && set_version

    msg "✅ Scenario #$n applied ($env $type)"
}

# --- Interactive mode ---
interactive_setup() {
    read -rp "Enable base URL? (y/n): " b
    read -rp "Enable download URL? (y/n): " d
    read -rp "Enable version? (y/n): " v
    read -rp "Use Thin Client? (y/n): " t
    read -rp "Use Airgap? (y/n): " a

    toggle_env "enable_blackduck_airgap" $([[ $a == y ]] && echo true || echo false)
    toggle_env "enable_bridgecli_thin_client" $([[ $t == y ]] && echo true || echo false)
    [[ $b == y ]] && set_base_url
    [[ $d == y ]] && set_download_url
    [[ $v == y ]] && set_version
}

# --- Batch mode ---
batch_run() {
    echo "1) All 28 | 2) Range | 3) Thin | 4) Bundle"
    read -rp "Choice: " c
    case $c in
        1) seq 1 28 ;;
        2) read -rp "Start: " s; read -rp "End: " e; seq "$s" "$e" ;;
        3) seq 1 14 ;;
        4) seq 15 28 ;;
    esac | while read -r i; do
        apply_scenario "$i"
        auto_commit "Scenario $i"
        sleep 1
    done
}

# --- Menu ---
echo "=== E2E Workflow Updater ==="
echo "1) Base URL | 2) Download URL | 3) Version | 4) Clear | 5) Interactive | 6) Scenario | 7) Batch"
read -rp "Choice: " c
case $c in
    1) set_base_url ;;
    2) set_download_url ;;
    3) set_version ;;
    4) clear_config ;;
    5) interactive_setup ;;
    6) read -rp "Scenario # (1–$TOTAL_SCENARIOS): " n; apply_scenario "$n" ;;
    7) batch_run ;;
    *) err "Invalid choice" ;;
esac

auto_commit "Workflow update"
msg "🎉 Done!"
