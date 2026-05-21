"""
Generate the Overload app launcher icon as a 1024x1024 PNG.
Draws a powerlifter in squat with barbell using PIL.
"""
from PIL import Image, ImageDraw
import math, os

SIZE = 1024
CX = SIZE // 2  # 512

img = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
draw = ImageDraw.Draw(img, 'RGBA')


# ── Helper: rounded rectangle ─────────────────────────────────────────────────
def rounded_rect(draw, xy, r, fill):
    x1, y1, x2, y2 = [int(v) for v in xy]
    w, h = x2 - x1, y2 - y1
    r = min(r, w // 2, h // 2)   # clamp radius so it never exceeds half-dim
    if w > 2 * r:
        draw.rectangle([x1 + r, y1, x2 - r, y2], fill=fill)
    if h > 2 * r:
        draw.rectangle([x1, y1 + r, x2, y2 - r], fill=fill)
    draw.ellipse([x1, y1, x1 + 2*r, y1 + 2*r], fill=fill)
    draw.ellipse([x2 - 2*r, y1, x2, y1 + 2*r], fill=fill)
    draw.ellipse([x1, y2 - 2*r, x1 + 2*r, y2], fill=fill)
    draw.ellipse([x2 - 2*r, y2 - 2*r, x2, y2], fill=fill)


# ── Background ────────────────────────────────────────────────────────────────
BG = (13, 13, 31, 255)
rounded_rect(draw, [0, 0, SIZE - 1, SIZE - 1], 176, BG)

# Subtle warm glow strip (where bar will be)
for i in range(60):
    alpha = int(18 * (1 - i / 60))
    y = 390 + i
    draw.line([(120, y), (SIZE - 120, y)], fill=(255, 60, 0, alpha))


# ── Barbell ───────────────────────────────────────────────────────────────────
BAR_Y      = 388           # top of bar shaft
BAR_H      = 28            # height of shaft
SHAFT_COL  = (180, 180, 180, 255)
DARK_SHAFT = (120, 120, 120, 255)

PLATE_RED   = (220, 38, 38, 255)
PLATE_RED2  = (170, 20, 10, 255)
PLATE_ORG   = (220, 100, 0, 255)
PLATE_ORG2  = (160, 70, 0, 255)
COLLAR_COL  = (90, 90, 90, 255)

# Left outer sleeve
draw.rectangle([110, BAR_Y + 4, 215, BAR_Y + BAR_H - 4], fill=DARK_SHAFT)
# Right outer sleeve
draw.rectangle([SIZE - 215, BAR_Y + 4, SIZE - 110, BAR_Y + BAR_H - 4], fill=DARK_SHAFT)
# Center shaft
draw.rectangle([215, BAR_Y + 6, SIZE - 215, BAR_Y + BAR_H - 6], fill=SHAFT_COL)

# LEFT plates ─────
# Large outer plate (red)
rounded_rect(draw, [108, 320, 174, 470], 14, PLATE_RED)
draw.rectangle([108, 320, 174, 342], fill=PLATE_RED2)   # dark top rim
# Inner plate (orange)
rounded_rect(draw, [174, 334, 218, 456], 10, PLATE_ORG)
draw.rectangle([174, 334, 218, 352], fill=PLATE_ORG2)
# Collar
rounded_rect(draw, [218, 378, 240, 426], 6, COLLAR_COL)

# RIGHT plates ────
rounded_rect(draw, [SIZE - 174, 320, SIZE - 108, 470], 14, PLATE_RED)
draw.rectangle([SIZE - 174, 320, SIZE - 108, 342], fill=PLATE_RED2)
rounded_rect(draw, [SIZE - 218, 334, SIZE - 174, 456], 10, PLATE_ORG)
draw.rectangle([SIZE - 218, 334, SIZE - 174, 352], fill=PLATE_ORG2)
rounded_rect(draw, [SIZE - 240, 378, SIZE - 218, 426], 6, COLLAR_COL)


# ── Athlete (white) ───────────────────────────────────────────────────────────
W = (255, 255, 255, 255)

def line(pts, width, color=W):
    draw.line(pts, fill=color, width=width)

def circle(cx, cy, r, color=W):
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=color)

def ellipse_xy(cx, cy, rx, ry, color=W):
    draw.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=color)

def rect_r(xy, r, color=W):
    rounded_rect(draw, xy, r, color)


# Head
circle(CX, 196, 60)

# Neck
rect_r([CX - 22, 252, CX + 22, 298], 10)

# Shoulders / traps block (where bar rests)
rect_r([CX - 124, 290, CX + 124, 330], 22)

# Left arm from shoulder to bar grip
line([(CX - 108, 310), (CX - 165, 345), (CX - 320, 402)], 36)
circle(CX - 320, 402, 20)   # grip knuckle

# Right arm
line([(CX + 108, 310), (CX + 165, 345), (CX + 320, 402)], 36)
circle(CX + 320, 402, 20)

# Torso — tapered trapezoid (wider shoulders, narrower hips)
torso_pts = [
    CX - 104, 332,   # top-left shoulder width
    CX - 72,  630,   # bottom-left hip width
    CX + 72,  630,   # bottom-right hip
    CX + 104, 332,   # top-right
]
draw.polygon(torso_pts, fill=W)

# Lifting belt (red accent across torso)
BELT = (220, 38, 38, 220)
rect_r([CX - 74, 560, CX + 74, 600], 10, BELT)
draw.rectangle([CX - 74, 565, CX + 74, 575], fill=(255, 80, 80, 100))

# Hips
ellipse_xy(CX, 635, 86, 30)

# LEFT leg ─────
# Thigh (hip to knee)
line([(CX - 50, 655), (CX - 230, 760)], 48)
# Knee cap
circle(CX - 230, 760, 28)
# Shin (knee to ankle)
line([(CX - 230, 760), (CX - 268, 900)], 40)
# Foot
ellipse_xy(CX - 282, 918, 66, 26)

# RIGHT leg ─────
line([(CX + 50, 655), (CX + 230, 760)], 48)
circle(CX + 230, 760, 28)
line([(CX + 230, 760), (CX + 268, 900)], 40)
ellipse_xy(CX + 282, 918, 66, 26)

# Ground shadow
for i in range(30):
    alpha = int(120 * (1 - i / 30))
    ry = 8 + i // 3
    draw.ellipse(
        [CX - 280, 940 - ry, CX + 280, 940 + ry],
        fill=(0, 0, 0, alpha)
    )


# ── Save ──────────────────────────────────────────────────────────────────────
out_dir = os.path.join(os.path.dirname(__file__), '..', 'assets', 'images')
os.makedirs(out_dir, exist_ok=True)
out_path = os.path.join(out_dir, 'logo_icon.png')
img.save(out_path, 'PNG')
print(f"Saved: {out_path}  ({SIZE}x{SIZE})")
