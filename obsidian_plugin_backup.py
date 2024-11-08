import os
import argparse
import shutil
import datetime
import glob

# ignoring plugins that store API key as plaintext :facepalm:
ignore_list = ("update-time-on-edit", "obsidian-omnivore", "digitalgarden", "node_modules")
# additional files without .json extension
file_list = ("config")

def find_files_to_link(source_dir, patterns):
    """Find all files matching the given patterns"""
    matched_files = []
    for pattern in patterns:
        pattern_path = os.path.join(source_dir, f"**/{pattern}")
        matched_files.extend(glob.glob(pattern_path, recursive=True))
    return matched_files

def create_single_hard_link(src_path, dest_path):
    """Create a single hard link and verify its creation"""
    try:
        os.makedirs(os.path.dirname(dest_path), exist_ok=True)
        if not os.path.exists(dest_path):
            os.link(src_path, dest_path)
            if check_hard_link(src_path, dest_path):
                print(f"Hard link created successfully: {dest_path}")
                return True
        else:
            print(f"File already exists, skipping: {dest_path}")
    except OSError as e:
        print(f"Error creating hard link: {e}")
    return False

def link_plugin_data(source_dir, destination_dir, ignore_list):
    """Handle plugin data.json files"""
    for dirpath, dirs, files in os.walk(source_dir):
        dirs[:] = [d for d in dirs if d not in ignore_list]
        for file in files:
            if file == "data.json":
                src_path = os.path.join(dirpath, file)
                relative_path = os.path.relpath(dirpath, source_dir)
                dest_path = os.path.join(destination_dir, relative_path, file)
                create_single_hard_link(src_path, dest_path)

def link_config_files(source_dir, destination_dir, file_list):
    """Handle config and other specified files"""
    # Link all JSON files
    json_files = find_files_to_link(source_dir, ["*.json"])
    for src_path in json_files:
        if not any(ignore in src_path for ignore in ignore_list):
            relative_path = os.path.relpath(src_path, source_dir)
            dest_path = os.path.join(destination_dir, relative_path)
            create_single_hard_link(src_path, dest_path)

    # Link specified config files
    config_files = find_files_to_link(source_dir, file_list)
    for src_path in config_files:
        relative_path = os.path.relpath(src_path, source_dir)
        dest_path = os.path.join(destination_dir, relative_path)
        create_single_hard_link(src_path, dest_path)

def create_hard_links(source_dir, destination_dir, ignore_list):
    """Main function to create all hard links"""
    link_plugin_data(source_dir, destination_dir, ignore_list)
    link_config_files(source_dir, destination_dir, file_list)

# Keep existing functions
def check_hard_link(src_path, dest_path):
    try:
        src_inode = os.stat(src_path).st_ino
        dest_inode = os.stat(dest_path).st_ino
        return src_inode == dest_inode
    except OSError as e:
        print(f"Error checking hard link: {e}")
        return False

def archive_destination(destination_dir):
    date_str = datetime.datetime.now().strftime('%Y-%m-%d')
    archive_dir = "_archive-" + date_str
    archive_path = os.path.join(destination_dir, archive_dir)
    shutil.make_archive(archive_path, 'zip', destination_dir)

def compare_directories(source_dir, home_dir, ignore_list):
    source_dirs = sorted([d for d in os.listdir(source_dir) if os.path.isdir(os.path.join(source_dir, d)) and d not in ignore_list and os.path.isfile(os.path.join(source_dir, d, 'data.json'))])
    home_dirs = sorted([d for d in os.listdir(home_dir) if os.path.isdir(os.path.join(home_dir, d)) and d not in ignore_list and os.path.isfile(os.path.join(home_dir, d, 'data.json'))])

    all_dirs = sorted(set(source_dirs + home_dirs))

    print(f"{'Source':<30} | {'Home':<30}")
    print('-' * 62)

    for dir in all_dirs:
        source_dir = dir if dir in source_dirs else ' '
        home_dir = dir if dir in home_dirs else ' '

        if source_dir != home_dir:
            source_dir = '*' + source_dir + '*' if source_dir.strip() else ' '
            home_dir = '*' + home_dir + '*' if home_dir.strip() else ' '

        print(f"{source_dir:<30} | {home_dir:<30}")

    if source_dirs == home_dirs:
        print("\nCongratulations! All relevant folders with data.json in them are in both locations.")

def main():
    parser = argparse.ArgumentParser(description='Manage your Obsidian dotfiles by hardlinking them to root, then backing them up however you prefer.')
    parser.add_argument('-c', '--compare', action='store_true', help='Compare directories')
    parser.add_argument('-l', '--link', action='store_true', help='Create hardlinks')
    parser.add_argument('-a', '--archive', action='store_true', help='Archive destination directory')
    parser.add_argument('-s', '--source', type=str, required=True, help='Source directory')
    parser.add_argument('-d', '--destination', type=str, required=True, help='Destination directory')
    args = parser.parse_args()

    if args.compare:
        compare_directories(args.source, args.destination, ignore_list)
    elif args.link:
        create_hard_links(args.source, args.destination, ignore_list)
    elif args.archive:
        archive_destination(args.destination)

if __name__ == "__main__":
    main()
