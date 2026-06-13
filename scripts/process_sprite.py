import sys
from PIL import Image

def process_sprite(input_path: str, output_path: str):
	# Load image and convert to RGBA
	img = Image.open(input_path).convert("RGBA")
	width, height = img.size
	
	# Determine background colors from top-left corner
	# The background is a grid of 16x16 or 32x32 pixels checkerboard squares
	color_1 = img.getpixel((0, 0))
	color_2 = img.getpixel((16, 0)) # offset by half square to find second color
	
	# Fallback if colors are similar
	if abs(color_1[0] - color_2[0]) < 10:
		color_2 = img.getpixel((0, 16))
		
	print(f"Detected background colors: {color_1} and {color_2}")
	
	# Create a mask for flood fill
	# We will flood fill starting from all border pixels
	pixels = img.load()
	visited = set()
	queue = []
	
	# Helper to check if pixel is background color
	def is_bg(color):
		# Allow a small tolerance for JPEG artifacts
		tol = 25
		match_1 = all(abs(color[i] - color_1[i]) <= tol for i in range(3))
		match_2 = all(abs(color[i] - color_2[i]) <= tol for i in range(3))
		return match_1 or match_2

	# Initialize queue with all border coordinates
	for x in range(width):
		queue.append((x, 0))
		queue.append((x, height - 1))
	for y in range(1, height - 1):
		queue.append((0, y))
		queue.append((width - 1, y))
		
	# Flood fill
	while queue:
		x, y = queue.pop(0)
		if (x, y) in visited:
			continue
		visited.add((x, y))
		
		# If it's a background pixel, make it transparent and enqueue neighbors
		current_color = pixels[x, y]
		if is_bg(current_color):
			pixels[x, y] = (0, 0, 0, 0) # Make transparent
			
			# Enqueue 4-way neighbors
			for dx, dy in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
				nx, ny = x + dx, y + dy
				if 0 <= nx < width and 0 <= ny < height and (nx, ny) not in visited:
					queue.append((nx, ny))
					
	# Save as PNG
	img.save(output_path, "PNG")
	print(f"Processed sprite saved to: {output_path}")

if __name__ == "__main__":
	if len(sys.argv) < 3:
		print("Usage: python process_sprite.py <input_path> <output_path>")
		sys.exit(1)
	process_sprite(sys.argv[1], sys.argv[2])
