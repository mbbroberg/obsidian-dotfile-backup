#!/bin/bash
# obsidian-sync.sh - Sync Obsidian config between machines

# Check for config file and load it, or use defaults
CONFIG_FILE="$HOME/obsidian-config/local-config"
if [ -f "$CONFIG_FILE" ]; then
  source "$CONFIG_FILE"
else
  # Default configuration
  REPO_DIR="$HOME/obsidian-config"
  VAULT_DIR="$HOME/path/to/your/vault/.obsidian"
  REMOTE_URL="git@github.com:yourusername/obsidian-config.git"
  SKIP_PLUGINS="api-key-plugin token-based-plugin update-time-on-edit"
  SKIP_FILES="manifest.json workspace.json"
  
  # Create config file for future runs
  mkdir -p "$(dirname "$CONFIG_FILE")"
  cat > "$CONFIG_FILE" << EOF
# Local configuration - not synced with git
REPO_DIR="$REPO_DIR"
VAULT_DIR="$VAULT_DIR"
REMOTE_URL="$REMOTE_URL"
SKIP_PLUGINS="$SKIP_PLUGINS"
SKIP_FILES="$SKIP_FILES"
EOF
  
  echo "Created local config at $CONFIG_FILE - edit this file to set your paths"
  exit 1
fi

# Convert space-separated strings to arrays
read -ra SKIP_PLUGINS_ARR <<< "$SKIP_PLUGINS"
read -ra SKIP_FILES_ARR <<< "$SKIP_FILES"

# Helper functions
log() { echo "[$(date '+%H:%M:%S')] $1"; }

# Setup repo
if [ ! -d "$REPO_DIR/.git" ]; then
  mkdir -p "$REPO_DIR"
  cd "$REPO_DIR" || exit 1
  git init
  
  if [ -n "$REMOTE_URL" ]; then
    git remote add origin "$REMOTE_URL"
    git pull origin main 2>/dev/null || git pull origin master 2>/dev/null || echo "# Obsidian Config" > README.md
    git add README.md
    git commit -m "Initial commit" 2>/dev/null
  fi
fi

# Create needed directories
mkdir -p "$REPO_DIR/plugins"

# Sync core configs
for config in "$VAULT_DIR"/*.json; do
  if [ -f "$config" ]; then
    filename=$(basename "$config")
    
    # Skip files in skip list
    if [[ " ${SKIP_FILES_ARR[*]} " == *" $filename "* ]]; then
      continue
    fi
    
    if [ ! -f "$REPO_DIR/$filename" ] || ! cmp -s "$config" "$REPO_DIR/$filename"; then
      log "Copying $filename to repo"
      cp "$config" "$REPO_DIR/$filename"
    fi
  fi
done

# Sync plugin configs
find "$VAULT_DIR/plugins" -name "data.json" | while read -r file; do
  plugin=$(basename "$(dirname "$file")")
  
  # Skip plugins in skip list
  if [[ " ${SKIP_PLUGINS_ARR[*]} " == *" $plugin "* ]]; then
    continue
  fi
  
  mkdir -p "$REPO_DIR/plugins/$plugin"
  
  if [ ! -f "$REPO_DIR/plugins/$plugin/data.json" ] || ! cmp -s "$file" "$REPO_DIR/plugins/$plugin/data.json"; then
    log "Copying config for plugin: $plugin"
    cp "$file" "$REPO_DIR/plugins/$plugin/data.json"
  fi
done

# Create symlinks
for config in "$REPO_DIR"/*.json; do
  if [ -f "$config" ]; then
    filename=$(basename "$config")
    
    # Skip files in skip list
    if [[ " ${SKIP_FILES_ARR[*]} " == *" $filename "* ]]; then
      continue
    fi
    
    # Backup existing file if needed
    if [ -f "$VAULT_DIR/$filename" ] && [ ! -L "$VAULT_DIR/$filename" ]; then
      log "Backing up $filename"
      mv "$VAULT_DIR/$filename" "$VAULT_DIR/$filename.bak"
    elif [ -L "$VAULT_DIR/$filename" ] && [ "$(readlink "$VAULT_DIR/$filename")" != "$config" ]; then
      rm "$VAULT_DIR/$filename"
    fi
    
    # Create symlink
    if [ ! -L "$VAULT_DIR/$filename" ]; then
      log "Creating symlink for $filename"
      ln -sf "$config" "$VAULT_DIR/$filename"
    fi
  fi
done

# Create plugin symlinks
find "$REPO_DIR/plugins" -name "data.json" | while read -r file; do
  plugin=$(basename "$(dirname "$file")")
  target_dir="$VAULT_DIR/plugins/$plugin"
  
  # Skip plugins in skip list
  if [[ " ${SKIP_PLUGINS_ARR[*]} " == *" $plugin "* ]]; then
    continue
  fi
  
  mkdir -p "$target_dir"
  
  # Backup existing file if needed
  if [ -f "$target_dir/data.json" ] && [ ! -L "$target_dir/data.json" ]; then
    log "Backing up plugin config for $plugin"
    mv "$target_dir/data.json" "$target_dir/data.json.bak"
  elif [ -L "$target_dir/data.json" ] && [ "$(readlink "$target_dir/data.json")" != "$file" ]; then
    rm "$target_dir/data.json"
  fi
  
  # Create symlink
  if [ ! -L "$target_dir/data.json" ]; then
    log "Creating symlink for plugin $plugin"
    ln -sf "$file" "$target_dir/data.json"
  fi
done

# Git sync
cd "$REPO_DIR" || exit 1

# Add gitignore for local config if it doesn't exist
if [ ! -f "$REPO_DIR/.gitignore" ] || ! grep -q "local-config" "$REPO_DIR/.gitignore"; then
  echo "local-config" >> "$REPO_DIR/.gitignore"
  git add .gitignore
  git commit -m "Add local-config to gitignore" 2>/dev/null
fi

# Pull changes
if git remote -v | grep -q origin; then
  git pull origin main 2>/dev/null || git pull origin master 2>/dev/null || true
fi

# Commit and push changes
if git status --porcelain | grep -q .; then
  git add .
  git commit -m "Config sync $(date '+%Y-%m-%d %H:%M:%S')"
  
  if git remote -v | grep -q origin; then
    git push -u origin "$(git rev-parse --abbrev-ref HEAD)" 2>/dev/null || true
  fi
fi

log "Config sync completed"