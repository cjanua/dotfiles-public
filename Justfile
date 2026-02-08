# =============================================================================
# [GLOBAL CONFIGURATION]
# =============================================================================
# The core git command for the bare repo
git_cmd := "/usr/bin/git --git-dir=" + env_var('HOME') + "/dusky/ --work-tree=" + env_var('HOME')
# Your specific repo (Origin)
my_repo := "git@github.com:cjanua/dotfiles-public.git"
# Official Dusky repo (Upstream)
dusky_repo := "https://github.com/dusklinux/dusky.git"

set shell := ["bash", "-c"]

# Default: List all available recipes
default:
    @just --choose

# =============================================================================
# [CORE WORKFLOW] - Daily Drivers
# =============================================================================

# Save configuration to Your GitHub (Auto-backs up packages)
# Usage: sys save "Added new hyprland keybinds"
save +message="Auto-save snapshot":
    @echo "📦 Generating package lists..."
    @just --justfile {{justfile()}} backup-packages

    @echo "📥 Staging tracked files..."
    @{{git_cmd}} status -s | grep " M " || true
    {{git_cmd}} add -u
    
    @echo "💾 Committing..."
    {{git_cmd}} commit -m "{{message}}" || echo "Nothing to commit."
    
    @echo "☁️  Pushing to Origin..."
    {{git_cmd}} push origin main
    @echo "✅ State saved successfully."

# Pull changes from Your GitHub (Syncing between multiple machines)
sync:
    @echo "⬇️  Fetching from Origin..."
    {{git_cmd}} pull origin main
    @echo "✅ System synced with cloud."

# Update from official Dusky repo (automatically applies changes)
upgrade:
    @echo "🌐 Cloning latest Dusky to /tmp/dusky-latest..."
    @rm -rf /tmp/dusky-latest
    git clone --depth 1 https://github.com/dusklinux/dusky.git /tmp/dusky-latest
    
    @echo "📊 Generating pre-upgrade diff..."
    @diff -ur --exclude='edit_here' --exclude='scripts' \
        /tmp/dusky-latest/.config/hypr/source/ \
        ~/.config/hypr/source/ \
        > /tmp/dusky_upgrade_diff.txt || true
    
    @echo "🔄 Applying Dusky updates to source/ folder..."
    cp -rf /tmp/dusky-latest/.config/hypr/source/* ~/.config/hypr/source/
    
    @echo "✅ Dusky configs updated!"
    @echo "📄 Changes saved to: /tmp/dusky_upgrade_diff.txt"
    @echo ""
    @echo "⚠️  Your customizations in edit_here/ are safe and unchanged."
    @echo "🔄 Run: just save \"Updated Dusky configs\" to commit changes"

# Abort an upgrade if it breaks things (Hard Reset)
abort-upgrade:
    {{git_cmd}} merge --abort 2>/dev/null || true
    {{git_cmd}} reset --hard HEAD
    @echo "⏪ Upgrade aborted. Back to previous state."

# =============================================================================
# [FILE MANAGEMENT]
# =============================================================================

# Track a new file or folder
add path:
    {{git_cmd}} add {{path}}
    @# Update the readable tracking list
    @target=$(realpath --relative-to=$HOME "{{path}}"); \
    echo "Tracking: $target"; \
    echo "$target" >> $HOME/.git_dusky_list; \
    sort -u $HOME/.git_dusky_list -o $HOME/.git_dusky_list

# Stop tracking a file (Keeps file on disk)
forget path:
    {{git_cmd}} rm --cached -r {{path}}
    @# Remove from tracking list
    @target=$(realpath --relative-to=$HOME "{{path}}"); \
    sed -i "\|${target}|d" $HOME/.git_dusky_list
    @echo "🚫 No longer tracking: {{path}}"

# Restore a file to its last saved state (Undo changes)
restore path:
    {{git_cmd}} restore {{path}}

# Passthrough for raw git commands
git +args='':
    {{git_cmd}} {{args}}

# Show current status
status:
    {{git_cmd}} status -s

# =============================================================================
# [SYSTEM & MAINTENANCE]
# =============================================================================

# Full System Update (Paru + Arch)
system-update:
    paru -Syu
    @echo "✅ System updated."

# Clean cache and garbage collect Git DB
clean:
    ~/user_scripts/arch_setup_scripts/scripts/065_cache_purge.sh
    {{git_cmd}} gc --prune=now
    @echo "🧹 Cleanup complete."

# Install/Bootstrap (Run this after a fresh git clone)
install:
    @echo "🚀 Starting Post-Clone Bootstrap..."
    @just --justfile {{justfile()}} system-update
    @# Ensure scripts are executable
    @chmod +x ~/user_scripts/**/*.sh
    @echo "✅ Permissions fixed."
    @echo "ℹ️  Run 'sys restore .' to force all config files to match the repo."
    @just --justfile {{justfile()}} _install_packages
    @echo "🎉 Bootstrap complete."

# Install Packages from backup lists (Run after Fresh Install)
_install_packages:
    @echo "📦 Installing Native Packages..."
    @if [ -f $HOME/pkglist_native.txt ]; then sudo pacman -S --needed - < $HOME/pkglist_native.txt; else echo "No native list found."; fi
    
    @echo "📦 Installing AUR Packages..."
    @if [ -f $HOME/pkglist_aur.txt ]; then paru -S --needed - < $HOME/pkglist_aur.txt; else echo "No AUR list found."; fi
    
    @echo "✅ All software restored."

# =============================================================================
# [BACKUPS] - Internal Helpers
# =============================================================================

[private]
backup-sddm:
    @echo ">> Backing up SDDM configs to ~/system_backups..."
    @mkdir -p $HOME/system_backups/etc
    @mkdir -p $HOME/system_backups/themes
    @if [ -f "/etc/sddm.conf" ]; then sudo cp /etc/sddm.conf $HOME/system_backups/etc/sddm.conf; fi
    @if [ -d "/usr/share/sddm/themes/dusky" ]; then sudo cp -r /usr/share/sddm/themes/dusky $HOME/system_backups/themes/; fi
    @sudo chown -R $USER:$USER $HOME/system_backups
    @just --justfile {{justfile()}} add $HOME/system_backups
    @echo "✅ SDDM backed up."

[private]
backup-packages:
    @echo ">> Generating package lists..."
    @pacman -Qqen > $HOME/pkglist_native.txt
    @pacman -Qqem > $HOME/pkglist_aur.txt
    @just --justfile {{justfile()}} add $HOME/pkglist_native.txt
    @just --justfile {{justfile()}} add $HOME/pkglist_aur.txt