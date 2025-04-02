# Obsidian Config Sync

Simple script to sync Obsidian settings across machines with git.

## Setup

1. Clone repo and run script:
   ```bash
   git clone git@github.com:yourusername/obsidian-config.git ~/obsidian-config
   cd ~/obsidian-config
   chmod +x obsidian-sync.sh
   ./obsidian-sync.sh
   ```

2. Edit the generated config file with your actual paths:
   ```bash
   # ~/obsidian-config/local-config
   REPO_DIR="$HOME/obsidian-config"
   VAULT_DIR="$HOME/actual/path/to/vault/.obsidian"  # CHANGE THIS
   REMOTE_URL="git@github.com:yourusername/obsidian-config.git"
   SKIP_PLUGINS="api-key-plugin token-based-plugin update-time-on-edit"
   SKIP_FILES="manifest.json workspace.json"
   ```

3. Run the script again to sync:
   ```bash
   ./obsidian-sync.sh
   ```

## Auto-running with Obsidian

1. Install "Shell commands" plugin
2. Add command: `~/obsidian-config/obsidian-sync.sh`
3. Set to run at Obsidian startup

## Troubleshooting

### Symlink Issues
```bash
# Check symlinks
ls -la ~/.obsidian/
readlink ~/.obsidian/appearance.json
```

### Git Problems
```bash
cd ~/obsidian-config
git status
git remote -v
```

### Path Issues
If vault path changes, just edit `~/obsidian-config/local-config`.

### Permission Errors
```bash
chmod +x ~/obsidian-config/obsidian-sync.sh
chmod 600 ~/obsidian-config/local-config
```

### Undo Symlinks
```bash
# Remove symlink and restore backup
rm ~/.obsidian/appearance.json
mv ~/.obsidian/appearance.json.bak ~/.obsidian/appearance.json
```