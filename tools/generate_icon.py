#!/usr/bin/env python3
"""Generate app icon assets for Status Saver.

Outputs:
  assets/icon/icon.png             1024x1024 full icon (rounded square + glyph)
  assets/icon/icon_foreground.png  1024x1024 transparent foreground (Android adaptive)
  android/app/src/main/res/mipmap-*/ic_launcher.png
  android/app/src/main/res/mipmap-*/ic_launcher_foreground.png
  android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml
  android/app/src/main/res/values/colors.xml  (adaptive bg)
  ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-*.png

Run from repo root:  python3 tools/generate_icon.py

The same output can be regenerated via flutter_launcher_icons (configured in
pubspec.yaml) when a Flutter SDK is available — both paths stay in sync.
"""
from __future__ import annotations

from pathlib import Path
from PIL import Image, ImageDraw

GREEN = (18, 140, 126)        # #128C7E - WhatsApp brand
GREEN_LIGHT = (37, 211, 102)  # #25D366 - status ring accent
WHITE = (255, 255, 255)

SIZE = 1024
CORNER = 224          # rounded-square radius (Android & iOS friendly)
RING_INSET = 56       # padding from edge to status ring
RING_WIDTH = 28
RING_GAP = 36         # gap between ring segments
GLYPH_SCALE = 0.45    # glyph occupies ~45% of canvas


def rounded_square(size: int, radius: int, fill) -> Image.Image:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((0, 0, size, size), radius=radius, fill=fill)
    return img


def draw_status_ring(img: Image.Image, color) -> None:
    d = ImageDraw.Draw(img)
    box = (RING_INSET, RING_INSET, SIZE - RING_INSET, SIZE - RING_INSET)
    segments = 8
    span = 360 / segments
    for i in range(segments):
        start = i * span + RING_GAP / 2
        end = (i + 1) * span - RING_GAP / 2
        d.arc(box, start=start, end=end, fill=color, width=RING_WIDTH)


def draw_save_glyph(img: Image.Image, color, scale: float = GLYPH_SCALE) -> None:
    d = ImageDraw.Draw(img)
    cx, cy = img.width // 2, img.height // 2
    g = int(min(img.width, img.height) * scale)
    half = g // 2

    stem_w = int(g * 0.18)
    stem_top = cy - half + int(g * 0.05)
    stem_bot = cy + int(g * 0.10)
    d.rounded_rectangle(
        (cx - stem_w // 2, stem_top, cx + stem_w // 2, stem_bot),
        radius=stem_w // 2,
        fill=color,
    )

    head_w = int(g * 0.62)
    head_h = int(g * 0.34)
    head_top_y = stem_bot - int(g * 0.04)
    d.polygon(
        [
            (cx - head_w // 2, head_top_y),
            (cx + head_w // 2, head_top_y),
            (cx, head_top_y + head_h),
        ],
        fill=color,
    )

    tray_w = int(g * 0.86)
    tray_h = int(g * 0.18)
    tray_thickness = int(g * 0.10)
    tray_top = cy + half - tray_h
    tray_left = cx - tray_w // 2
    tray_right = cx + tray_w // 2
    tray_bot = cy + half
    d.rounded_rectangle(
        (tray_left, tray_top, tray_left + tray_thickness, tray_bot),
        radius=tray_thickness // 2,
        fill=color,
    )
    d.rounded_rectangle(
        (tray_right - tray_thickness, tray_top, tray_right, tray_bot),
        radius=tray_thickness // 2,
        fill=color,
    )
    d.rounded_rectangle(
        (tray_left, tray_bot - tray_thickness, tray_right, tray_bot),
        radius=tray_thickness // 2,
        fill=color,
    )


def make_full_icon(size: int = SIZE) -> Image.Image:
    # Render at native SIZE for crispness, then resize.
    img = rounded_square(SIZE, CORNER, GREEN)
    draw_status_ring(img, GREEN_LIGHT)
    draw_save_glyph(img, WHITE)
    if size != SIZE:
        img = img.resize((size, size), Image.LANCZOS)
    return img


def make_foreground(size: int = SIZE) -> Image.Image:
    """Transparent foreground for Android adaptive icon.

    Android crops the foreground to a system-defined safe zone (~66% of canvas),
    so the glyph is rendered smaller and centered.
    """
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw_save_glyph(img, WHITE, scale=0.32)
    if size != SIZE:
        img = img.resize((size, size), Image.LANCZOS)
    return img


def make_ios_icon(size: int) -> Image.Image:
    """iOS icons must be opaque RGB (no alpha)."""
    img = make_full_icon(size).convert("RGB")
    return img


# Android density buckets (mdpi=48, hdpi=72, xhdpi=96, xxhdpi=144, xxxhdpi=192)
ANDROID_LAUNCHER_SIZES = {
    "mdpi": 48,
    "hdpi": 72,
    "xhdpi": 96,
    "xxhdpi": 144,
    "xxxhdpi": 192,
}
# Adaptive foreground/background must be 108dp; the foreground source is rendered
# 1.5x larger so the system can crop to the safe zone.
ANDROID_ADAPTIVE_SIZES = {
    "mdpi": 108,
    "hdpi": 162,
    "xhdpi": 216,
    "xxhdpi": 324,
    "xxxhdpi": 432,
}

IOS_ICONS = [
    ("Icon-App-20x20@1x.png", 20),
    ("Icon-App-20x20@2x.png", 40),
    ("Icon-App-20x20@3x.png", 60),
    ("Icon-App-29x29@1x.png", 29),
    ("Icon-App-29x29@2x.png", 58),
    ("Icon-App-29x29@3x.png", 87),
    ("Icon-App-40x40@1x.png", 40),
    ("Icon-App-40x40@2x.png", 80),
    ("Icon-App-40x40@3x.png", 120),
    ("Icon-App-60x60@2x.png", 120),
    ("Icon-App-60x60@3x.png", 180),
    ("Icon-App-76x76@1x.png", 76),
    ("Icon-App-76x76@2x.png", 152),
    ("Icon-App-83.5x83.5@2x.png", 167),
    ("Icon-App-1024x1024@1x.png", 1024),
]

ADAPTIVE_XML = """<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
</adaptive-icon>
"""

COLORS_XML = """<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">#128C7E</color>
</resources>
"""


def main() -> None:
    repo_root = Path(__file__).resolve().parent.parent

    # 1. Source assets (consumed by flutter_launcher_icons too).
    out_dir = repo_root / "assets" / "icon"
    out_dir.mkdir(parents=True, exist_ok=True)
    make_full_icon().save(out_dir / "icon.png", format="PNG")
    make_foreground().save(out_dir / "icon_foreground.png", format="PNG")
    print(f"wrote {(out_dir / 'icon.png').relative_to(repo_root)}")
    print(f"wrote {(out_dir / 'icon_foreground.png').relative_to(repo_root)}")

    # 2. Android: legacy launcher + adaptive foreground per density bucket.
    res = repo_root / "android" / "app" / "src" / "main" / "res"
    for bucket, size in ANDROID_LAUNCHER_SIZES.items():
        d = res / f"mipmap-{bucket}"
        d.mkdir(parents=True, exist_ok=True)
        make_full_icon(size).save(d / "ic_launcher.png", format="PNG")
    for bucket, size in ANDROID_ADAPTIVE_SIZES.items():
        d = res / f"mipmap-{bucket}"
        d.mkdir(parents=True, exist_ok=True)
        make_foreground(size).save(d / "ic_launcher_foreground.png", format="PNG")

    # 3. Adaptive icon XML + background color.
    anydpi = res / "mipmap-anydpi-v26"
    anydpi.mkdir(parents=True, exist_ok=True)
    (anydpi / "ic_launcher.xml").write_text(ADAPTIVE_XML)
    values = res / "values"
    values.mkdir(parents=True, exist_ok=True)
    colors = values / "colors.xml"
    if colors.exists():
        existing = colors.read_text()
        if "ic_launcher_background" not in existing:
            new = existing.replace(
                "</resources>",
                '    <color name="ic_launcher_background">#128C7E</color>\n</resources>',
            )
            colors.write_text(new)
    else:
        colors.write_text(COLORS_XML)
    print("wrote android adaptive + legacy mipmaps")

    # 4. iOS: opaque RGB at every required size.
    ios_dir = (
        repo_root / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
    )
    ios_dir.mkdir(parents=True, exist_ok=True)
    for name, size in IOS_ICONS:
        make_ios_icon(size).save(ios_dir / name, format="PNG")
    print("wrote ios AppIcon set")


if __name__ == "__main__":
    main()
