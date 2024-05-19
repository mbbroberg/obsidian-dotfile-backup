import os
import argparse
import shutil
import datetime

# ignoring plugins that store API key as plaintext :facepalm:
ignore_list = ("update-time-on-edit", "obsidian-omnivore", "digitalgarden", "node_modules")

# When you should pause and start fresh
# Not willing to be fully destructive and delete
def archive_destination(destination_dir):
    date_str = datetime.datetime.now().strftime('%Y-%m-%d')
    archive_dir = "_archive-" + date_str
    archive_path = os.path.join(destination_dir, archive_dir)
    shutil.make_archive(archive_path, 'zip', destination_dir)

def compare_directories(source_dir, home_dir, ignore_list):
    source_dirs = sorted([d for d in os.listdir(source_dir) if os.path.isdir(os.path.join(source_dir, d)) and d not in ignore_list])
    home_dirs = sorted([d for d in os.listdir(home_dir) if os.path.isdir(os.path.join(home_dir, d)) and d not in ignore_list])

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

def check_hard_link(src_path, dest_path):
    try:
        src_inode = os.stat(src_path).st_ino
        dest_inode = os.stat(dest_path).st_ino
        return src_inode == dest_inode
    except OSError as e:
        print(f"Error checking hard link: {e}")
        return False

def create_hard_links(source_dir, destination_dir, ignore_list):
    for dirpath, dirs, files in os.walk(source_dir):
        # Skip directories in ignore_list
        dirs[:] = [d for d in dirs if d not in ignore_list]
        for file in files:
            if file == "data.json":
                src_path = os.path.join(dirpath, file)  # Use dirpath instead of destination_dir
                relative_path = os.path.relpath(dirpath, source_dir)
                dest_dir = os.path.join(destination_dir, relative_path)  # Use destination_dir instead of source_dir
                try:
                    os.makedirs(dest_dir, exist_ok=True)
                    dest_path = os.path.join(dest_dir, file)
                    if not os.path.exists(dest_path):
                        os.link(src_path, dest_path)
                        if check_hard_link(src_path, dest_path):
                            print(f"Hard link created successfully: {dest_path}")
                        else:
                            print(f"Failed to create hard link: {dest_path}")
                    else:
                        print(f"File already exists, skipping: {dest_path}")
                except OSError as e:
                    print(f"Error creating hard link: {e}")

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
