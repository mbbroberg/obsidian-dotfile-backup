# Obsidian Plugin Backup 

An incredibly imperfect implementation of a backup tool for my Obsidian [dotfiles](https://opensource.com/article/19/3/move-your-dotfiles-version-control). It helps me: 

- Hardlink plugin customizations (data.json) in any easy-to-backup way
- See where I've drifted between environments by comparing directories

### But isn't there a better way? 

Oh, absolutely. I looked at the [git plugin](https://github.com/denolehov/obsidian-git) but I didn't want to figure out how to make it work across separate Obsidian environments. I can also think of at least two better implementations: 

1. An Obsidian plugin that handles this all
2. Building this into a compiled utility with a less clumsy argument structure

### Acknowledgement 

I only had the patience and time to put this together because I used [GitHub Copilot](https://github.com/features/copilot). I want to thank everyone who's contributed code helped me navigate this problem. 