# =============================================================================
# GLOBAL VARIABLES
# =============================================================================
# Define the bare git command once
git_cmd := "/usr/bin/git --git-dir=" + env_var('HOME') + "/dusky/ --work-tree=" + env_var('HOME')

# Default: List all available recipes
default:
    @just --list

# GIT PASSTHROUGH
git +args='':
    {{git_cmd}} {{args}}


# =============================================================================
# [DOTFILES]
# Usage: just dotfiles <command> [args]
# =============================================================================

# The Dispatcher
dotfiles action +args='':
    @just --justfile {{justfile()}} dotfiles-{{action}} {{args}}

# --- Sub-commands (prefixed with dotfiles-) ---

# Internal: Add files to git and the tracking list
[private]
dotfiles-add +files:
    @# 1. Git Add
    {{git_cmd}} add {{files}}
    
    @# 2. Update Tracking List
    @for file in {{files}}; do \
        target=$(realpath --relative-to=$HOME "$file"); \
        echo "Tracking: $target"; \
        echo "$target" >> $HOME/.git_dusky_list; \
    done
    
    @# 3. Sort and Clean List
    @sort -u $HOME/.git_dusky_list -o $HOME/.git_dusky_list
    @echo "[OK] Dotfiles tracked."

# Internal: Commit and Push
[private]
dotfiles-save +message:
    @just --justfile {{justfile()}} backup-packages
    {{git_cmd}} commit -m "{{message}}"
    {{git_cmd}} push
    @echo "[SUCCESS] Configuration saved and pushed."

[private]
dotfiles-restore +args:
    {{git_cmd}} restore {{args}}

# Internal: Pull updates safely
[private]
dotfiles-upgrade:
    @echo ">> Fetching upstream..."
    {{git_cmd}} fetch origin main
    @echo ">> Merging updates..."
    {{git_cmd}} merge origin/main
    @echo "[OK] Upgrade complete."

# Internal: Git Status
[private]
dotfiles-status:
    {{git_cmd}} status -s

# =============================================================================
# [SYSTEM]
# Usage: just system <command>
# =============================================================================

system action +args='':
    @just --justfile {{justfile()}} system-{{action}} {{args}}

[private]
system-update:
    paru -Syu
    @echo "[OK] System updated."

[private]
system-clean:
    ~/user_scripts/arch_setup_scripts/scripts/065_cache_purge.sh

# ================================
# Backup root configs
# ================================

backup target:
    @just --justfile {{justfile()}} backup-{{target}}

[private]
backup-sddm:
    @echo ">> Backing up SDDM configs to ~/system_backups..."
    @mkdir -p $HOME/system_backups/etc
    @mkdir -p $HOME/system_backups/themes
    
    # Copy main config
    @sudo cp /etc/sddm.conf $HOME/system_backups/etc/sddm.conf
    
    # Copy your current theme (Change 'dusky' to your actual theme folder name if different)
    @if [ -d "/usr/share/sddm/themes/dusky" ]; then \
        sudo cp -r /usr/share/sddm/themes/dusky $HOME/system_backups/themes/; \
    fi
    
    @# Fix permissions so you own the backup files
    @sudo chown -R $USER:$USER $HOME/system_backups
    
    @# Add to git
    @just --justfile {{justfile()}} dotfiles-add $HOME/system_backups
    @echo "[OK] SDDM backed up and tracked."

[private]
backup-packages:
    @echo ">> Generating package lists..."
    @# Save explicit native packages (things you installed on purpose)
    @pacman -Qqe > $HOME/pkglist_native.txt
    
    @# Save AUR packages (explicit only)
    @pacman -Qqem > $HOME/pkglist_aur.txt
    
    @# Track them
    @just --justfile {{justfile()}} dotfiles-add $HOME/pkglist_native.txt
    @just --justfile {{justfile()}} dotfiles-add $HOME/pkglist_aur.txt
    @echo "[OK] Package lists updated."

    