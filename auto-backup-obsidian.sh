#!/bin/bash
# backup-obsidian.sh

# Configure git if not already done
OBSIDIAN_DIR="~/obsidian"
LOG_FILE="${OBSIDIAN_DIR}/backup.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

cd "${OBSIDIAN_DIR}" || exit 1

# Ensure we're in a git repository
if [ ! -d ".git" ]; then
    /usr/bin/osascript -e 'display notification "Git repository not found in Obsidian directory" with title "Obsidian Backup Error"'
    exit 1
fi

# Perform git operations
git add . >> "${LOG_FILE}" 2>&1
CHANGES=$(git status --porcelain)

if [ -n "$CHANGES" ]; then
    git commit -m "Auto-backup: ${TIMESTAMP}" >> "${LOG_FILE}" 2>&1
    git push >> "${LOG_FILE}" 2>&1
    
    if [ $? -eq 0 ]; then
        /usr/bin/osascript -e 'display notification "Successfully backed up Obsidian vault" with title "Obsidian Backup"'
    else
        /usr/bin/osascript -e 'display notification "Failed to push changes to remote" with title "Obsidian Backup Error"'
    fi
else
    echo "${TIMESTAMP}: No changes to backup" >> "${LOG_FILE}"
fi
