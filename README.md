# Obsidian Plugin Backup 

An incredibly imperfect implementation of a backup tool for my Obsidian [dotfiles](https://opensource.com/article/19/3/move-your-dotfiles-version-control). It helps me: 

- Hardlink plugin customizations (data.json) in any easy-to-backup way
- See where I've drifted between environments by comparing directories

## But isn't there a better way? 

Oh, absolutely. I looked at the [git plugin](https://github.com/denolehov/obsidian-git) but I didn't want to figure out how to make it work across separate Obsidian environments. I can also think of at least two better implementations: 

1. An Obsidian plugin that handles this all
2. Building this into a compiled utility with a less clumsy argument structure

## Setup

### Usage

```bash
usage: obsidian_plugin_backup.py [-h] [-c] [-l] [-a] -s SOURCE -d DESTINATION

optional arguments:
  -h, --help                                    show this help message and exit
  -c, --compare                                 Compare directories
  -l, --link                                    Create hardlinks
  -a, --archive                                 Archive destination directory
  -s SOURCE, --source SOURCE                    Source directory
  -d DESTINATION, --destination DESTINATION     Destination directory
```

### Step 1: Hard-link Obsidian dotfiles

- Clone https://github.com/mbbroberg/obsidian-dotfile-backup
- Run it once to hard-link the dotfile folder to your home folder

```bash
$ python ./obsidian_plugin_backup.py -l -s "TODO_YOURVAULT/.obsidian/" -d "~/obsidian" 
```

## Step 2: Configure backup runner 

- Clone https://github.com/mbbroberg/obsidian 
- Either manually run `~/obsidian/auto-backup-obsidian.sh` or setup a service to run it periodically

### Using Launchd

Replace `TODO_YOURUSERNAME` with your username in the plist file then run: 

```bash
$ cp com.user.obsidian.backup.plist ~/Library/LaunchAgents/
$ launchctl load -w ~/Library/LaunchAgents/com.user.obsidian.backup.plist
```

Verify it's enabled in `System Preferences > Users & Groups > Login Items`

## Troubleshooting 

1: Double check the existance of log files, hard links, and permissions. You may have to `touch` the log files to create them or `chmod +x` the script.

2: Increase the frequency of the backup by replacing `1800` with `60` in `~/obsidian/auto-backup-obsidian.sh`

Reload:

```bash
launchctl unload -w ~/Library/LaunchAgents/com.user.obsidian.backup.plist
launchctl load -w ~/Library/LaunchAgents/com.user.obsidian.backup.plist
```

Then watch the logs: 

```bash
tail -f ~/obsidian/backup-error.log ~/obsidian/backup-output.log
```

## Acknowledgement 

I only had the patience and time to put this together because I used [GitHub Copilot](https://github.com/features/copilot) at first and [Cody with Claude](https://marketplace.visualstudio.com/items?itemName=sourcegraph.cody-ai) at other times. I want to thank everyone whose contributed code helped me navigate this problem. 