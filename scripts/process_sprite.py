import sys
from collections import deque
from PIL import Image

def process_sprite(input_path: str, output_path: str):
	# Load image and convert to RGBA
	img = Image.open(input_path).convert("RGBA")
	width, height = img.size
	pixels = img.load()
	
	# 1. Collect all border pixels
	border_pixels = []
	for x in range(width):
		border_pixels.append(pixels[x, 0])
		border_pixels.append(pixels[x, height - 1])
	for y in range(1, height - 1):
		border_pixels.append(pixels[0, y])
		border_pixels.append(pixels[width - 1, y])
		
	# 2. Convert border colors to 3D color-space bins for O(1) matching with tolerance.
	# We round color components to nearest 12 to handle JPEG compression/gradients.
	bin_size = 12
	border_bins = set()
	for color in border_pixels:
		r, g, b = color[0], color[1], color[2]
		r_bin, g_bin, b_bin = r // bin_size, g // bin_size, b // bin_size
		# Add the main bin
		border_bins.add((r_bin, g_bin, b_bin))
		# Also add adjacent bins for small tolerance safety
		for dr in [-1, 0, 1]:
			for dg in [-1, 0, 1]:
				for db in [-1, 0, 1]:
					border_bins.add((r_bin + dr, g_bin + dg, b_bin + db))
					
	# Helper to check if a pixel color falls into any border bin
	def is_bg(color):
		r_bin = color[0] // bin_size
		g_bin = color[1] // bin_size
		b_bin = color[2] // bin_size
		return (r_bin, g_bin, b_bin) in border_bins
	
	# 3. Flood fill starting from all border coordinates
	visited = set()
	queue = deque()
	
	# Initialize queue with all border coordinates
	for x in range(width):
		queue.append((x, 0))
		queue.append((x, height - 1))
	for y in range(1, height - 1):
		queue.append((0, y))
		queue.append((width - 1, y))
		
	# Flood fill
	while queue:
		x, y = queue.popleft()
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
