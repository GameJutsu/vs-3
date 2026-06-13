import os
from PIL import Image

def flood_fill_transparent(image_path, output_path):
    img = Image.open(image_path).convert("RGBA")
    width, height = img.size
    
    # Target color is white (or very close to white)
    # We will do a flood fill from the corners
    data = img.load()
    visited = set()
    queue = []
    
    # Add corners to queue
    corners = [(0, 0), (width - 1, 0), (0, height - 1), (width - 1, height - 1)]
    for x, y in corners:
        queue.append((x, y))
        visited.add((x, y))
        
    while queue:
        cx, cy = queue.pop(0)
        r, g, b, a = data[cx, cy]
        
        # If the pixel is white-ish, make it transparent
        if r > 240 and g > 240 and b > 240:
            data[cx, cy] = (0, 0, 0, 0)
            
            # Add neighbors
            for dx, dy in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                nx, ny = cx + dx, cy + dy
                if 0 <= nx < width and 0 <= ny < height and (nx, ny) not in visited:
                    visited.add((nx, ny))
                    queue.append((nx, ny))

    # Crop to content bounding box
    bbox = img.getbbox()
    if bbox:
        img = img.crop(bbox)
        
    # Create target directory
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    img.save(output_path)
    print(f"Processed and saved: {output_path}")

def main():
    brain_dir = "/home/deck/.gemini/antigravity-cli/brain/f1ff4091-2d4e-4246-8559-446c8238ad3f"
    assets_dir = "/home/deck/Game Dev/vs3/vs-3/assets/sprites"
    
    sprite_map = {
        "rattata_sprite_white_1781377711406.png": "rattata.png",
        "raticate_sprite_1781377697460.png": "raticate.png",
        "zubat_sprite_1781377782523.png": "zubat.png",
        "golbat_sprite_1781377798405.png": "golbat.png",
        "pikachu_sprite_1781377812786.png": "pikachu.png",
        "raichu_sprite_1781377826207.png": "raichu.png",
        "staryu_sprite_1781377841001.png": "staryu.png",
        "starmie_sprite_1781377856364.png": "starmie.png",
        "geodude_sprite_1781377872014.png": "geodude.png",
        "graveler_sprite_1781377887182.png": "graveler.png"
    }
    
    for src_name, dest_name in sprite_map.items():
        src_path = os.path.join(brain_dir, src_name)
        dest_path = os.path.join(assets_dir, dest_name)
        if os.path.exists(src_path):
            flood_fill_transparent(src_path, dest_path)
        else:
            print(f"Warning: Source file not found {src_path}")

if __name__ == "__main__":
    main()
