#!/bin/bash
# obsidian-sync.sh - Copy Obsidian configuration between machines

# Local configuration file
CONFIG_FILE="$HOME/obsidian-config/local-config"

# Check if config file exists and load it
if [ -f "$CONFIG_FILE" ]; then
  source "$CONFIG_FILE"
  echo "Loaded configuration from $CONFIG_FILE"
else
  # First run - create config file and prompt for values
  mkdir -p "$(dirname "$CONFIG_FILE")"
  
  # Get vault directory
  DEFAULT_VAULT_DIR="$HOME/Documents/ObsidianVault/.obsidian"
  echo -n "Enter your Obsidian vault's .obsidian directory [$DEFAULT_VAULT_DIR]: "
  read -r input_vault
  VAULT_DIR=${input_vault:-$DEFAULT_VAULT_DIR}
  
  # Get repo directory
  DEFAULT_REPO_DIR="$HOME/obsidian-config"
  echo -n "Enter directory to store synced config [$DEFAULT_REPO_DIR]: "
  read -r input_repo
  REPO_DIR=${input_repo:-$DEFAULT_REPO_DIR}
  
  # Get git URL if desired
  echo -n "Enter git repository URL (leave empty to skip git sync): "
  read -r REMOTE_URL
  
  # Default skip lists
  DEFAULT_SKIP_PLUGINS="api-key-plugin token-based-plugin update-time-on-edit workspaces-plus"
  DEFAULT_SKIP_FILES="manifest.json workspace.json workspaces.json"
  
  # Create config file
  cat > "$CONFIG_FILE" << EOF
# Local configuration for Obsidian config sync - created $(date)
VAULT_DIR="$VAULT_DIR"
REPO_DIR="$REPO_DIR"
REMOTE_URL="$REMOTE_URL"
SKIP_PLUGINS="$DEFAULT_SKIP_PLUGINS"
SKIP_FILES="$DEFAULT_SKIP_FILES"
EOF

  echo "Created configuration at $CONFIG_FILE"
  echo "Edit this file to customize which plugins and files to skip"
  echo "Run the script again to perform the initial sync"
  exit 0
fi

# Convert space-separated strings to arrays
read -ra SKIP_PLUGINS_ARR <<< "$SKIP_PLUGINS"
read -ra SKIP_FILES_ARR <<< "$SKIP_FILES"

# ======== Helper Functions ========
log() { 
  echo "[$(date '+%H:%M:%S')] $1"
}

error() { 
  echo "[ERROR] $1" >&2
  exit 1
}

# ======== Repository Setup ========
setup_repo() {
  # Create repo directory if it doesn't exist
  if [ ! -d "$REPO_DIR" ]; then
    log "Creating repository directory at $REPO_DIR"
    mkdir -p "$REPO_DIR"
  fi
  
  # Initialize git if URL was provided and repo isn't already a git repo
  if [ -n "$REMOTE_URL" ] && [ ! -d "$REPO_DIR/.git" ]; then
    log "Initializing git repository"
    cd "$REPO_DIR" || error "Failed to change to repo directory"
    git init
    git remote add origin "$REMOTE_URL"
    
    # Try to pull from remote
    if git ls-remote --exit-code origin &>/dev/null; then
      log "Pulling from remote repository"
      git pull origin main 2>/dev/null || git pull origin master 2>/dev/null || log "No existing branch found"
    else
      log "Remote not accessible or empty. Creating initial commit."
      echo "# Obsidian Configuration" > README.md
      git add README.md
      git commit -m "Initial commit"
    fi
    
    # Add local-config to gitignore
    if [ ! -f "$REPO_DIR/.gitignore" ] || ! grep -q "local-config" "$REPO_DIR/.gitignore"; then
      echo "local-config" >> "$REPO_DIR/.gitignore"
      git add .gitignore
      git commit -m "Add local-config to gitignore" 2>/dev/null
    fi
  fi
  
  # Create subdirectories
  mkdir -p "$REPO_DIR/plugins"
}

# ======== Sync Functions ========
copy_core_configs() {
  log "Copying core configuration files"
  
  # Copy core JSON files from vault to repo
  find "$VAULT_DIR" -maxdepth 1 -name "*.json" | while read -r file; do
    filename=$(basename "$file")
    
    # Skip files in skip list
    if [[ " ${SKIP_FILES_ARR[*]} " == *" $filename "* ]]; then
      log "Skipping file: $filename"
      continue
    fi
    
    # Only copy if different
    if [ ! -f "$REPO_DIR/$filename" ] || ! cmp -s "$file" "$REPO_DIR/$filename"; then
      log "Copying $filename to repo"
      cp "$file" "$REPO_DIR/$filename"
    fi
  done
}

copy_plugin_configs() {
  log "Copying plugin configurations"
  
  # Find all plugin data.json files in the vault
  find "$VAULT_DIR/plugins" -name "data.json" 2>/dev/null | while read -r file; do
    plugin_dir=$(dirname "$file")
    plugin_name=$(basename "$plugin_dir")
    
    # Skip plugins in skip list
    if [[ " ${SKIP_PLUGINS_ARR[*]} " == *" $plugin_name "* ]]; then
      log "Skipping plugin: $plugin_name"
      continue
    fi
    
    # Create plugin directory in repo
    mkdir -p "$REPO_DIR/plugins/$plugin_name"
    
    # Copy config file if it's different
    if [ ! -f "$REPO_DIR/plugins/$plugin_name/data.json" ] || ! cmp -s "$file" "$REPO_DIR/plugins/$plugin_name/data.json"; then
      log "Copying config for plugin: $plugin_name"
      cp "$file" "$REPO_DIR/plugins/$plugin_name/data.json"
    fi
  done
}

apply_configs_to_vault() {
  log "Applying configs from repo to vault"
  
  # Apply core configs
  for config in "$REPO_DIR"/*.json; do
    if [ -f "$config" ]; then
      filename=$(basename "$config")
      
      # Skip files in skip list
      if [[ " ${SKIP_FILES_ARR[*]} " == *" $filename "* ]]; then
        continue
      fi
      
      # Copy file to vault 
      if [ ! -f "$VAULT_DIR/$filename" ] || ! cmp -s "$config" "$VAULT_DIR/$filename"; then
        log "Applying $filename to vault"
        # Backup existing file if different
        if [ -f "$VAULT_DIR/$filename" ]; then
          cp "$VAULT_DIR/$filename" "$VAULT_DIR/$filename.bak.$(date +%Y%m%d%H%M%S)"
        fi
        cp "$config" "$VAULT_DIR/$filename"
      fi
    fi
  done
  
  # Apply plugin configs
  for plugin_dir in "$REPO_DIR/plugins"/*; do
    if [ -d "$plugin_dir" ] && [ -f "$plugin_dir/data.json" ]; then
      plugin_name=$(basename "$plugin_dir")
      
      # Skip plugins in skip list
      if [[ " ${SKIP_PLUGINS_ARR[*]} " == *" $plugin_name "* ]]; then
        continue
      fi
      
      # Ensure plugin directory exists in vault
      mkdir -p "$VAULT_DIR/plugins/$plugin_name"
      
      # Copy config file if different
      if [ ! -f "$VAULT_DIR/plugins/$plugin_name/data.json" ] || ! cmp -s "$plugin_dir/data.json" "$VAULT_DIR/plugins/$plugin_name/data.json"; then
        log "Applying config for plugin: $plugin_name"
        # Backup existing file if different
        if [ -f "$VAULT_DIR/plugins/$plugin_name/data.json" ]; then
          cp "$VAULT_DIR/plugins/$plugin_name/data.json" "$VAULT_DIR/plugins/$plugin_name/data.json.bak.$(date +%Y%m%d%H%M%S)"
        fi
        cp "$plugin_dir/data.json" "$VAULT_DIR/plugins/$plugin_name/data.json"
      fi
    fi
  done
}

git_sync() {
  if [ -z "$REMOTE_URL" ]; then
    log "No remote URL configured, skipping git sync"
    return
  fi
  
  log "Syncing with git repository"
  
  cd "$REPO_DIR" || error "Failed to change to repo directory"
  
  # Pull changes first
  if git remote -v | grep -q origin; then
    log "Pulling latest changes"
    git pull origin "$(git rev-parse --abbrev-ref HEAD)" 2>/dev/null || git pull origin main 2>/dev/null || git pull origin master 2>/dev/null || log "Pull failed, continuing anyway"
  fi
  
  # Commit and push changes
  if git status --porcelain | grep -q .; then
    log "Committing changes"
    git add .
    git commit -m "Config sync $(date '+%Y-%m-%d %H:%M:%S')"
    
    if git remote -v | grep -q origin; then
      log "Pushing changes"
      git push -u origin "$(git rev-parse --abbrev-ref HEAD)" 2>/dev/null || log "Push failed, check your remote settings"
    fi
  else
    log "No changes to commit"
  fi
}

# ======== Main Execution ========
main() {
  log "Starting Obsidian config sync"
  
  # Verify vault directory exists
  if [ ! -d "$VAULT_DIR" ]; then
    error "Vault directory not found at $VAULT_DIR. Check VAULT_DIR in $CONFIG_FILE"
  fi
  
  # Setup repository
  setup_repo
  
  # Copy configs FROM vault TO repo
  copy_core_configs
  copy_plugin_configs
  
  # Copy configs FROM repo TO vault
  apply_configs_to_vault
  
  # Git sync if configured
  git_sync
  
  log "Config sync completed successfully"
}

# Run the main function
main