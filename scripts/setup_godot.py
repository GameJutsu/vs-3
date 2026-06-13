import os
import urllib.request
import zipfile

def main():
    # Define paths
    home = os.path.expanduser("~")
    templates_dir = os.path.join(home, ".local/share/godot/export_templates/4.6.3.stable")
    os.makedirs(templates_dir, exist_ok=True)
    print(f"Target templates directory: {templates_dir}")

    # 1. Download and Extract Godot Editor
    editor_zip = "godot.zip"
    editor_bin = "Godot_v4.6.3-stable_linux.x86_64"
    if not os.path.exists(editor_bin):
        if not os.path.exists(editor_zip):
            print("Downloading Godot Editor...")
            url = "https://github.com/godotengine/godot/releases/download/4.6.3-stable/Godot_v4.6.3-stable_linux.x86_64.zip"
            urllib.request.urlretrieve(url, editor_zip)
            print("Godot Editor downloaded.")
        
        print("Extracting Godot Editor...")
        with zipfile.ZipFile(editor_zip, 'r') as zip_ref:
            zip_ref.extractall(".")
        print("Godot Editor extracted.")
    
    if os.path.exists(editor_bin):
        os.chmod(editor_bin, 0o755)
        print("Executable permission set on editor binary.")

    # 2. Download and Extract Export Templates
    templates_zip = "templates.tpz"
    if not os.path.exists(templates_zip):
        print("Downloading Export Templates...")
        url = "https://github.com/godotengine/godot/releases/download/4.6.3-stable/Godot_v4.6.3-stable_export_templates.tpz"
        urllib.request.urlretrieve(url, templates_zip)
        print("Export Templates downloaded.")

    print("Extracting Export Templates...")
    extracted_count = 0
    with zipfile.ZipFile(templates_zip, 'r') as zip_ref:
        for member in zip_ref.namelist():
            # Check if it starts with templates/
            if member.startswith("templates/"):
                filename = os.path.basename(member)
                if filename:  # Ignore directory entries
                    source = zip_ref.open(member)
                    target_path = os.path.join(templates_dir, filename)
                    with open(target_path, "wb") as target:
                        target.write(source.read())
                    extracted_count += 1

    print(f"Successfully extracted {extracted_count} templates to {templates_dir}.")
    print("Contents of templates directory:")
    for f in sorted(os.listdir(templates_dir)):
        print(f"  - {f}")

if __name__ == "__main__":
    main()
