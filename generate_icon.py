from PIL import Image, ImageDraw

size = 1024
img = Image.new("RGBA", (size, size), (0, 0, 0, 255))
draw = ImageDraw.Draw(img)

# Purple-to-blue diagonal gradient background
for y in range(size):
    t = y / size
    # top: deep purple (120, 30, 210) -> bottom: vivid blue (50, 110, 250)
    r = int(120 * (1 - t) + 50 * t)
    g = int(30 * (1 - t) + 110 * t)
    b = int(210 * (1 - t) + 250 * t)
    draw.line([(0, y), (size, y)], fill=(r, g, b, 255))

# Overlay a left-to-right tint
img2 = Image.new("RGBA", (size, size), (0, 0, 0, 0))
d2 = ImageDraw.Draw(img2)
for x in range(size):
    t = x / size
    r = int(80 * (1 - t) + 20 * t)
    g = int(0 * (1 - t) + 60 * t)
    b = int(10 * (1 - t) + 40 * t)
    alpha = int(80 * t)
    d2.line([(x, 0), (x, size)], fill=(r, g, b, alpha))

img = Image.alpha_composite(img.convert("RGBA"), img2)
draw = ImageDraw.Draw(img)

# Paper plane vertices (pointing right, centred in canvas)
cx, cy = size // 2, size // 2
sc = 360

nose      = (cx + int(sc * 0.78), cy)
upper_tip = (cx - int(sc * 0.78), cy - int(sc * 0.50))
lower_tip = (cx - int(sc * 0.78), cy + int(sc * 0.50))
fold_top  = (cx - int(sc * 0.06), cy - int(sc * 0.04))
fold_tail = (cx - int(sc * 0.06), cy + int(sc * 0.26))

# Draw three panels of the plane
# Upper wing
draw.polygon([nose, upper_tip, fold_top], fill=(255, 255, 255, 245))
# Lower body
draw.polygon([nose, fold_top, fold_tail], fill=(225, 225, 250, 230))
# Tail fin
draw.polygon([fold_top, lower_tip, fold_tail], fill=(200, 200, 240, 215))

# Subtle fold crease lines
draw.line([nose, fold_top], fill=(160, 150, 210, 150), width=4)
draw.line([fold_top, fold_tail], fill=(160, 150, 210, 150), width=4)

# Convert to RGB for PNG (no transparency so iOS icon mask works)
final = img.convert("RGB")
out = "/Users/sara/work/flyaway/FlyAway/FlyAway/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png"
final.save(out, "PNG")
print("Saved:", out)
