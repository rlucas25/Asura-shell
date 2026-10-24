#!/usr/bin/env python3
# Based on iNiR by snowarch (https://github.com/snowarch/inir) and illogical-impulse by end-4
# Licensed under GNU General Public License v3.0 (GPL-3.0)
# Adapted for Asura Shell
import argparse
import colorsys
import getpass
import math
import json
import os
import re
import sys

import numpy as np

try:
    import tomllib
except ModuleNotFoundError:
    tomllib = None
from PIL import Image
from materialyoucolor.quantize import QuantizeCelebi
from materialyoucolor.score.score import Score
from materialyoucolor.hct import Hct
from materialyoucolor.dynamiccolor.material_dynamic_colors import MaterialDynamicColors
from materialyoucolor.utils.color_utils import (
    rgba_from_argb,
    argb_from_rgb,
    argb_from_rgba,
)
from materialyoucolor.utils.math_utils import (
    sanitize_degrees_double,
    difference_degrees,
    rotation_direction,
)

parser = argparse.ArgumentParser(description="Color generation script")
parser.add_argument(
    "--path", type=str, default=None, help="generate colorscheme from image"
)
parser.add_argument("--size", type=int, default=128, help="bitmap image size")
parser.add_argument(
    "--color", type=str, default=None, help="generate colorscheme from color"
)
parser.add_argument(
    "--palette", type=str, default=None, help="apply static base16 palette"
)
parser.add_argument(
    "--mode",
    type=str,
    choices=["dark", "light"],
    default="dark",
    help="dark or light mode",
)
parser.add_argument(
    "--primary-slot",
    type=str,
    default=None,
    help="slot key to use for primary accent color (e.g. base0D, base08, etc.)",
)
parser.add_argument(
    "--scheme", type=str, default="vibrant", help="material scheme to use"
)
parser.add_argument(
    "--smart",
    action="store_true",
    default=False,
    help="decide scheme type based on image color",
)
parser.add_argument(
    "--transparency",
    type=str,
    choices=["opaque", "transparent"],
    default="opaque",
    help="enable transparency",
)
parser.add_argument(
    "--termscheme",
    type=str,
    default=None,
    help="JSON file containg the terminal scheme for generating term colors",
)
parser.add_argument(
    "--harmony", type=float, default=0.4, help="(0-1) Color hue shift towards accent"
)
parser.add_argument(
    "--harmonize_threshold",
    type=float,
    default=100,
    help="(0-180) Max threshold angle to limit color hue shift",
)
parser.add_argument(
    "--term_fg_boost",
    type=float,
    default=0.35,
    help="Make terminal foreground more different from the background",
)
parser.add_argument(
    "--term_saturation",
    type=float,
    default=0.65,
    help="Terminal color saturation (0.0-1.0)",
)
parser.add_argument(
    "--term_brightness",
    type=float,
    default=0.60,
    help="Terminal color brightness/lightness (0.0-1.0)",
)
parser.add_argument(
    "--term_bg_brightness",
    type=float,
    default=0.50,
    help="Terminal background brightness (0.0-1.0, 0=darkest, 1=lightest)",
)
parser.add_argument(
    "--blend_bg_fg",
    action="store_true",
    default=False,
    help="Shift terminal background or foreground towards accent",
)
parser.add_argument(
    "--cache", type=str, default=None, help="file path to store the generated color"
)
parser.add_argument(
    "--soften", action="store_true", default=False, help="soften generated colors"
)
parser.add_argument(
    "--debug", action="store_true", default=False, help="enable debug output"
)
parser.add_argument(
    "--json-output", type=str, default=None, help="file path to write colors.json"
)
parser.add_argument(
    "--palette-output", type=str, default=None, help="file path to write palette.json"
)
parser.add_argument(
    "--app-palette-output",
    type=str,
    default=None,
    help="file path to write app-palette.json",
)
parser.add_argument(
    "--terminal-output", type=str, default=None, help="file path to write terminal.json"
)
parser.add_argument(
    "--meta-output", type=str, default=None, help="file path to write theme-meta.json"
)
parser.add_argument(
    "--asura-output", type=str, default=None, help="file path to write Asura colors.json"
)
parser.add_argument(
    "--scss-output",
    type=str,
    default=None,
    help="file path to write material_colors.scss",
)
parser.add_argument(
    "--surface-seed",
    type=str,
    default=None,
    help="hex colour the neutral surfaces are anchored to (the shell's own material); accents stay from the source",
)
parser.add_argument(
    "--render-templates",
    type=str,
    default=None,
    help="directory containing templates/ and templates.json (renders GTK/fuzzel/etc.)",
)
parser.add_argument(
    "--color-strength",
    type=float,
    default=1.0,
    help="multiplier for wallpaper-derived accent chroma (1.0 = default)",
)
parser.add_argument(
    "--invert-hue",
    action="store_true",
    default=False,
    help="Rotate seed color hue 180° before scheme generation (complementary palette)",
)
parser.add_argument(
    "--disabled-templates",
    type=str,
    nargs="*",
    default=[],
    help="List of template names to skip rendering",
)
parser.add_argument(
    "--disable-all-templates",
    action="store_true",
    default=False,
    help="Disable all template rendering",
)
args = parser.parse_args()

rgba_to_hex = lambda rgba: "#{:02X}{:02X}{:02X}".format(rgba[0], rgba[1], rgba[2])
argb_to_hex = lambda argb: "#{:02X}{:02X}{:02X}".format(
    *map(round, rgba_from_argb(argb))
)
hex_to_argb = lambda hex_code: argb_from_rgb(
    int(hex_code[1:3], 16), int(hex_code[3:5], 16), int(hex_code[5:], 16)
)
display_color = lambda rgba: "\x1b[38;2;{};{};{}m{}\x1b[0m".format(
    rgba[0], rgba[1], rgba[2], "\x1b[7m   \x1b[7m"
)


def _auto_detect_scheme(pil_image):
    """Detect optimal material scheme from image statistics.
    Uses the same decision tree as scheme_for_image.py but operates on an
    already-loaded PIL image, avoiding a separate Python process + cv2 import."""
    arr = np.array(pil_image, dtype=np.float64)
    if arr.ndim != 3 or arr.shape[2] < 3:
        return "scheme-tonal-spot"

    R, G, B = arr[:, :, 0], arr[:, :, 1], arr[:, :, 2]

    # Colorfulness (Hasler-Süsstrunk metric)
    rg = np.absolute(R - G)
    yb = np.absolute(0.5 * (R + G) - B)
    colorfulness = float(
        np.sqrt(np.std(rg) ** 2 + np.std(yb) ** 2)
        + 0.3 * np.sqrt(np.mean(rg) ** 2 + np.mean(yb) ** 2)
    )

    # HSV via numpy (H scaled to 0-180 to match cv2 convention)
    r, g, b = R / 255.0, G / 255.0, B / 255.0
    maxc = np.maximum(np.maximum(r, g), b)
    minc = np.minimum(np.minimum(r, g), b)
    s = np.where(maxc > 0, (maxc - minc) / maxc, 0.0) * 255
    delta = maxc - minc
    h = np.zeros_like(r)
    with np.errstate(invalid="ignore", divide="ignore"):
        mask = delta > 0
        idx = (maxc == r) & mask
        h[idx] = 30.0 * (((g[idx] - b[idx]) / delta[idx]) % 6)
        idx = (maxc == g) & mask
        h[idx] = 30.0 * ((b[idx] - r[idx]) / delta[idx] + 2)
        idx = (maxc == b) & mask
        h[idx] = 30.0 * ((r[idx] - g[idx]) / delta[idx] + 4)

    saturation = float(np.mean(s))
    hue_spread = float(np.std(h))

    if saturation < 20:
        return "scheme-monochrome"
    if colorfulness < 30:
        if saturation < 55:
            return "scheme-neutral"
        if hue_spread < 22:
            return "scheme-content"
        return "scheme-tonal-spot"
    if colorfulness < 55:
        if hue_spread < 22 and saturation < 100:
            return "scheme-content"
        return "scheme-tonal-spot"
    if colorfulness < 90:
        if saturation > 140 and hue_spread < 35:
            return "scheme-fidelity"
        if hue_spread < 30:
            return "scheme-content"
        return "scheme-tonal-spot"
    if hue_spread > 55 and saturation > 150:
        return "scheme-rainbow"
    if saturation > 160:
        return "scheme-fidelity"
    if hue_spread > 45:
        return "scheme-expressive"
    return "scheme-tonal-spot"


def calculate_optimal_size(width: int, height: int, bitmap_size: int) -> (int, int):
    image_area = width * height
    bitmap_area = bitmap_size**2
    scale = math.sqrt(bitmap_area / image_area) if image_area > bitmap_area else 1
    new_width = round(width * scale)
    new_height = round(height * scale)
    if new_width == 0:
        new_width = 1
    if new_height == 0:
        new_height = 1
    return new_width, new_height


def harmonize(
    design_color: int, source_color: int, threshold: float = 35, harmony: float = 0.5
) -> int:
    from_hct = Hct.from_int(design_color)
    to_hct = Hct.from_int(source_color)
    difference_degrees_ = difference_degrees(from_hct.hue, to_hct.hue)
    rotation_degrees = min(difference_degrees_ * harmony, threshold)
    output_hue = sanitize_degrees_double(
        from_hct.hue + rotation_degrees * rotation_direction(from_hct.hue, to_hct.hue)
    )
    return Hct.from_hct(output_hue, from_hct.chroma, from_hct.tone).to_int()


def boost_chroma_tone(
    argb: int, chroma: float = 1, tone: float = 1, tone_cap: float = 95.0
) -> int:
    """Scale chroma and tone of a color.

    Args:
        argb: Input color in ARGB format
        chroma: Chroma multiplier (1 = no change)
        tone: Tone multiplier (1 = no change)
        tone_cap: Maximum tone value to prevent white-washing bright colors

    Returns:
        Adjusted color in ARGB format
    """
    hct = Hct.from_int(argb)
    new_tone = min(tone_cap, hct.tone * tone)
    return Hct.from_hct(hct.hue, hct.chroma * chroma, new_tone).to_int()


def ensure_min_chroma(argb: int, min_chroma: float = 40) -> int:
    """Ensure a color has minimum chroma for visual distinctiveness."""
    hct = Hct.from_int(argb)
    if hct.chroma < min_chroma:
        return Hct.from_hct(hct.hue, min_chroma, hct.tone).to_int()
    return argb


def scale_chroma(argb: int, factor: float, maximum: float | None = None) -> int:
    """Scale chroma while preserving hue/tone for stronger or calmer accent colors."""
    if abs(factor - 1.0) < 1e-6:
        return argb
    hct = Hct.from_int(argb)
    new_chroma = max(0.0, hct.chroma * factor)
    if maximum is not None:
        new_chroma = min(maximum, new_chroma)
    return Hct.from_hct(hct.hue, new_chroma, hct.tone).to_int()


def relative_luminance(argb: int) -> float:
    """Calculate relative luminance per WCAG 2.1 spec."""
    r = ((argb >> 16) & 0xFF) / 255.0
    g = ((argb >> 8) & 0xFF) / 255.0
    b = (argb & 0xFF) / 255.0

    def linearize(c):
        return c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4

    return 0.2126 * linearize(r) + 0.7152 * linearize(g) + 0.0722 * linearize(b)


def contrast_ratio(fg_argb: int, bg_argb: int) -> float:
    """Calculate WCAG contrast ratio between two colors."""
    l1 = relative_luminance(fg_argb)
    l2 = relative_luminance(bg_argb)
    lighter = max(l1, l2)
    darker = min(l1, l2)
    return (lighter + 0.05) / (darker + 0.05)


def find_tone_for_contrast(
    hue: float,
    chroma: float,
    start_tone: float,
    limit_tone: float,
    bg_argb: int,
    min_ratio: float,
    is_dark: bool,
    step: float = 0.25,
) -> tuple[int, float, bool, float]:
    """Search tone values for contrast.

    Returns:
        (color_argb, tone, met_min_ratio, achieved_ratio)
    """
    direction = 1.0 if is_dark else -1.0
    tone = start_tone
    max_steps = max(1, int(math.ceil(abs(limit_tone - start_tone) / step)) + 2)

    initial = Hct.from_hct(hue, chroma, max(0.0, min(100.0, start_tone))).to_int()
    best_color = initial
    best_tone = start_tone
    best_ratio = contrast_ratio(initial, bg_argb)

    for _ in range(max_steps):
        clamped_tone = max(0.0, min(100.0, tone))
        candidate = Hct.from_hct(hue, chroma, clamped_tone).to_int()
        ratio = contrast_ratio(candidate, bg_argb)

        if ratio > best_ratio:
            best_color = candidate
            best_tone = clamped_tone
            best_ratio = ratio

        if ratio >= min_ratio:
            return candidate, clamped_tone, True, ratio

        if is_dark and clamped_tone >= limit_tone:
            break
        if not is_dark and clamped_tone <= limit_tone:
            break

        tone += direction * step
        if is_dark and tone > limit_tone:
            tone = limit_tone
        if not is_dark and tone < limit_tone:
            tone = limit_tone

    return best_color, best_tone, False, best_ratio


def ensure_contrast(
    fg_argb: int,
    bg_argb: int,
    min_ratio: float = 4.5,
    is_dark: bool = True,
    tone_limit: float | None = None,
) -> int:
    """Adjust foreground tone to ensure minimum contrast ratio against background.

    For dark mode, increases tone (lighter). For light mode, decreases tone (darker).
    Preserves hue and boosts chroma when tone approaches extremes to prevent washed-out colors.
    """
    current_ratio = contrast_ratio(fg_argb, bg_argb)
    if current_ratio >= min_ratio:
        return fg_argb

    hct = Hct.from_int(fg_argb)
    original_tone = hct.tone
    original_chroma = hct.chroma

    # Tone limits to prevent colors from washing out to pure white/black.
    # If min ratio is unreachable inside limits, return highest-contrast option.
    if tone_limit is None:
        tone_limit = 88.0 if is_dark else 20.0

    best, best_tone, met_min, best_ratio = find_tone_for_contrast(
        hct.hue,
        hct.chroma,
        original_tone,
        tone_limit,
        bg_argb,
        min_ratio,
        is_dark,
    )

    # Compensate for tone shift by boosting chroma
    # When tone moves far from original, colors lose perceptual saturation
    # Boost chroma proportionally to maintain color identity
    tone_shift = abs(best_tone - original_tone)
    if tone_shift > 10:
        # Boost chroma by up to 40% for large tone shifts
        # The further we shift, the more we compensate
        boost_factor = 1.0 + min(0.4, (tone_shift - 10) / 50)
        boosted_chroma = min(original_chroma * boost_factor, 80.0)
        boosted_same_tone = Hct.from_hct(hct.hue, boosted_chroma, best_tone).to_int()
        boosted_ratio = contrast_ratio(boosted_same_tone, bg_argb)

        if met_min and boosted_ratio >= min_ratio:
            return boosted_same_tone

        boosted_best, _, boosted_met, boosted_best_ratio = find_tone_for_contrast(
            hct.hue,
            boosted_chroma,
            best_tone,
            tone_limit,
            bg_argb,
            min_ratio,
            is_dark,
        )

        if met_min:
            # Keep strict contrast if we already had a valid candidate.
            if boosted_met:
                return boosted_best
            return best

        # If target contrast is unreachable, keep the best achievable ratio.
        if boosted_best_ratio > best_ratio:
            return boosted_best

    return best


def mix_hex(color_a: str, color_b: str, keep_a: float = 0.5) -> str:
    a = color_a.lstrip("#")
    b = color_b.lstrip("#")
    ar, ag, ab = int(a[0:2], 16), int(a[2:4], 16), int(a[4:6], 16)
    br, bg, bb = int(b[0:2], 16), int(b[2:4], 16), int(b[4:6], 16)
    return "#{:02X}{:02X}{:02X}".format(
        round(ar * keep_a + br * (1 - keep_a)),
        round(ag * keep_a + bg * (1 - keep_a)),
        round(ab * keep_a + bb * (1 - keep_a)),
    )


def readable_hex(fg_hex: str, bg_hex: str, min_ratio: float = 4.5) -> str:
    bg_argb = hex_to_argb(bg_hex)
    is_bg_dark = Hct.from_int(bg_argb).tone < 50
    return argb_to_hex(ensure_contrast(hex_to_argb(fg_hex), bg_argb, min_ratio, is_bg_dark))


def build_app_palette(base_palette: dict[str, str]) -> dict[str, str]:
    layer0 = base_palette.get("background") or base_palette.get("surface") or "#000000"
    layer1 = base_palette.get("surface_container_low") or base_palette.get("surface") or layer0
    layer2 = base_palette.get("surface_container") or layer1
    layer3 = base_palette.get("surface_container_high") or layer2
    layer4 = base_palette.get("surface_container_highest") or layer3
    on_surface = base_palette.get("on_surface") or base_palette.get("on_background") or "#FFFFFF"
    on_surface_variant = base_palette.get("on_surface_variant") or on_surface
    primary = base_palette.get("primary") or "#6750A4"
    primary_container = base_palette.get("primary_container") or primary
    on_primary = base_palette.get("on_primary") or readable_hex(on_surface, primary, 4.5)
    outline = base_palette.get("outline") or on_surface_variant
    outline_variant = base_palette.get("outline_variant") or mix_hex(layer1, outline, 0.72)

    on_layer0 = readable_hex(on_surface, layer0, 4.5)
    on_layer1 = readable_hex(on_surface_variant, layer1, 4.5)
    on_layer2 = readable_hex(on_surface, layer2, 4.5)
    on_layer3 = readable_hex(on_surface, layer3, 4.5)
    on_layer4 = readable_hex(on_surface, layer4, 4.5)
    layer1_hover = mix_hex(layer1, on_layer1, 0.92)
    layer1_active = mix_hex(layer1, on_layer1, 0.85)
    # Muted text on a light theme drops under 3:1 on hover and press fills, so
    # it is solved against the pressed fill; dark themes keep the 3:1 floor.
    if Hct.from_int(hex_to_argb(layer0)).tone >= 50:
        subtext = readable_hex(mix_hex(on_layer1, layer1, 0.75), layer1_active, 4.5)
    else:
        subtext = readable_hex(mix_hex(on_layer1, layer1, 0.75), layer1, 3.0)
    layer2_hover = mix_hex(layer2, on_layer2, 0.90)
    layer2_active = mix_hex(layer2, on_layer2, 0.80)
    layer3_hover = mix_hex(layer3, on_layer3, 0.90)
    layer3_active = mix_hex(layer3, on_layer3, 0.80)
    selection = mix_hex(layer3, primary, 0.82)
    selection_hover = mix_hex(layer3, primary, 0.74)
    on_selection = readable_hex(on_layer3, selection, 4.5)

    app = dict(base_palette)
    app.update(
        {
            "background": layer0,
            "on_background": on_layer0,
            "surface": layer0,
            "on_surface": on_layer1,
            "surface_dim": layer0,
            "surface_bright": layer3,
            "surface_container_lowest": layer0,
            "surface_container_low": layer1,
            "surface_container": layer2,
            "surface_container_high": layer3,
            "surface_container_highest": layer4,
            "outline": outline,
            "outline_variant": outline_variant,
            "app_background": layer0,
            "app_foreground": on_layer0,
            "app_subtext": subtext,
            "app_surface": layer1,
            "app_surface_hover": layer1_hover,
            "app_surface_active": layer1_active,
            "app_surface_elevated": layer2,
            "app_surface_elevated_hover": layer2_hover,
            "app_surface_elevated_active": layer2_active,
            "app_surface_popup": layer3,
            "app_surface_popup_hover": layer3_hover,
            "app_surface_popup_active": layer3_active,
            "app_on_surface": on_layer1,
            "app_on_surface_elevated": on_layer2,
            "app_on_surface_popup": on_layer3,
            "app_on_surface_highest": on_layer4,
            "app_border": outline,
            "app_border_subtle": outline_variant,
            "app_accent": primary,
            "app_on_accent": on_primary,
            "app_accent_container": primary_container,
            "app_selection": selection,
            "app_selection_hover": selection_hover,
            "app_on_selection": on_selection,
            "app_window_bg": layer0,
            "app_view_bg": layer0,
            "app_headerbar_bg": layer0,
            "app_sidebar_bg": layer0,
            "app_card_bg": layer1,
            "app_popover_bg": layer2,
            "app_dialog_bg": layer3,
            "app_thumbnail_bg": layer4,
        }
    )
    return app


darkmode = args.mode == "dark"
transparent = args.transparency == "transparent"

if args.path is not None:
    image = Image.open(args.path)

    if image.format == "GIF":
        image.seek(1)

    if image.mode in ["L", "P"]:
        image = image.convert("RGB")
    wsize, hsize = image.size
    wsize_new, hsize_new = calculate_optimal_size(wsize, hsize, args.size)
    if wsize_new < wsize or hsize_new < hsize:
        image = image.resize((wsize_new, hsize_new), Image.Resampling.BICUBIC)
    # Auto-detect scheme from the already-resized image (avoids separate Python process)
    if args.scheme == "auto":
        args.scheme = _auto_detect_scheme(image)
    try:
        pixel_data = list(image.get_flattened_data())
    except Exception:
        pixel_data = list(image.getdata())
    colors = QuantizeCelebi(pixel_data, 128)
    argb = Score.score(colors)[0]

    if args.cache is not None:
        with open(args.cache, "w") as file:
            file.write(argb_to_hex(argb))
    hct = Hct.from_int(argb)
    if args.smart:
        if hct.chroma < 20:
            args.scheme = "neutral"
elif args.color is not None:
    argb = hex_to_argb(args.color)
    hct = Hct.from_int(argb)

palette_dict = None
if args.palette:
    pal_input = args.palette.strip()
    if pal_input.startswith("{"):
        try:
            palette_dict = json.loads(pal_input)
        except Exception:
            pass
    elif os.path.isfile(pal_input):
        try:
            with open(pal_input, "r") as f:
                palette_dict = json.load(f)
        except Exception:
            pass
    else:
        possible_palettes_files = [
            os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "Asura", "palettes", "palettes.json")),
            os.path.expanduser("~/.config/quickshell/Asura/palettes/palettes.json"),
            os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "Asura", "palettes", f"{pal_input}.json")),
            os.path.expanduser(f"~/.config/quickshell/Asura/palettes/{pal_input}.json"),
        ]
        for pfile in possible_palettes_files:
            if os.path.isfile(pfile):
                try:
                    with open(pfile, "r") as f:
                        data = json.load(f)
                    if isinstance(data, dict):
                        if "palettes" in data and pal_input in data["palettes"]:
                            palette_dict = data["palettes"][pal_input]
                            break
                        elif pal_input in data:
                            palette_dict = data[pal_input]
                            break
                        elif "base00" in data:
                            palette_dict = data
                            break
                except Exception:
                    pass
    if palette_dict and isinstance(palette_dict, dict) and "palette" in palette_dict and isinstance(palette_dict["palette"], dict):
        palette_dict = palette_dict["palette"]

def get_configured_primary_slot() -> str:
    if args.primary_slot:
        return args.primary_slot.strip()
    for cfg_c in [
        os.path.expanduser("~/.config/asura/config.json"),
        os.path.expanduser("~/.config/quickshell/Asura/config/config.json"),
        os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "Asura", "config", "config.json")),
    ]:
        if os.path.isfile(cfg_c):
            try:
                with open(cfg_c, "r", encoding="utf-8") as f:
                    cdata = json.load(f)
                if cdata.get("primarySlot"):
                    return str(cdata["primarySlot"]).strip()
            except Exception:
                pass
    return "base0D"


def _contrast_hex(h):
    h_clean = h.lstrip("#")
    if len(h_clean) == 6:
        r, g, b = int(h_clean[0:2], 16), int(h_clean[2:4], 16), int(h_clean[4:6], 16)
        lum = 0.2126 * r + 0.7152 * g + 0.0722 * b
        return "#11111b" if lum > 135 else "#ffffff"
    return "#ffffff"


def _is_dark_hex(h):
    h_clean = h.lstrip("#")
    if len(h_clean) == 6:
        r, g, b = int(h_clean[0:2], 16), int(h_clean[2:4], 16), int(h_clean[4:6], 16)
        lum = 0.2126 * r + 0.7152 * g + 0.0722 * b
        return lum < 128
    return True


if palette_dict is not None:
    pal_type = palette_dict.get("type")
    if pal_type in ("dark", "light"):
        darkmode = (pal_type == "dark")
    elif "base00" in palette_dict:
        darkmode = _is_dark_hex(palette_dict["base00"])
    else:
        darkmode = (args.mode == "dark")

    active_slot = args.primary_slot or palette_dict.get("primarySlot") or get_configured_primary_slot()

    b00 = palette_dict.get("base00", "#1e1e2e")
    b01 = palette_dict.get("base01", "#181825")
    b02 = palette_dict.get("base02", "#313244")
    b03 = palette_dict.get("base03", "#45475a")
    b04 = palette_dict.get("base04", "#a6adc8")
    b05 = palette_dict.get("base05", "#cdd6f4")
    b06 = palette_dict.get("base06", "#f5e0dc")
    b07 = palette_dict.get("base07", "#ffffff")
    b08 = palette_dict.get("base08", "#f38ba8")
    b09 = palette_dict.get("base09", "#fab387")
    b0A = palette_dict.get("base0A", "#f9e2af")
    b0B = palette_dict.get("base0B", "#a6e3a1")
    b0C = palette_dict.get("base0C", "#94e2d5")
    b0D = palette_dict.get("base0D", "#89b4fa")
    b0E = palette_dict.get("base0E", "#cba6f7")
    b0F = palette_dict.get("base0F", "#f2cdcd")

    if active_slot in palette_dict:
        primary_val = palette_dict[active_slot]
    else:
        primary_val = palette_dict.get("primary", b0D)

    b_primary = primary_val
    argb = hex_to_argb(b_primary)
    hct = Hct.from_int(argb)

    on_primary_val = _contrast_hex(primary_val)
    secondary_val = palette_dict.get("secondary", b0A)
    tertiary_val = palette_dict.get("tertiary", b0B)
    error_val = palette_dict.get("error", b08)
    warning_val = palette_dict.get("warning", b0A)
    success_val = palette_dict.get("success", b0B)

    material_colors = {
        "primary": primary_val,
        "onPrimary": on_primary_val,
        "primaryContainer": b02,
        "onPrimaryContainer": primary_val,
        "inversePrimary": primary_val,
        "primaryFixed": primary_val,
        "primaryFixedDim": primary_val,
        "onPrimaryFixed": _contrast_hex(primary_val),
        "onPrimaryFixedVariant": b03,
        "secondary": secondary_val,
        "onSecondary": _contrast_hex(secondary_val),
        "secondaryContainer": b02,
        "onSecondaryContainer": secondary_val,
        "secondaryFixed": secondary_val,
        "secondaryFixedDim": secondary_val,
        "onSecondaryFixed": _contrast_hex(secondary_val),
        "onSecondaryFixedVariant": b03,
        "tertiary": tertiary_val,
        "onTertiary": _contrast_hex(tertiary_val),
        "tertiaryContainer": b02,
        "onTertiaryContainer": tertiary_val,
        "tertiaryFixed": tertiary_val,
        "tertiaryFixedDim": tertiary_val,
        "onTertiaryFixed": _contrast_hex(tertiary_val),
        "onTertiaryFixedVariant": b03,
        "error": error_val,
        "onError": _contrast_hex(error_val),
        "errorContainer": b02,
        "onErrorContainer": error_val,
        "success": success_val,
        "onSuccess": _contrast_hex(success_val),
        "successContainer": b02,
        "onSuccessContainer": success_val,
        "background": b00,
        "onBackground": b05,
        "surface": b00,
        "onSurface": b05,
        "surfaceDim": b00,
        "surfaceBright": b02,
        "surfaceContainerLowest": b00,
        "surfaceContainerLow": b01,
        "surfaceContainer": b02,
        "surfaceContainerHigh": b03,
        "surfaceContainerHighest": b03,
        "surfaceVariant": b02,
        "onSurfaceVariant": b04,
        "outline": b03,
        "outlineVariant": b02,
        "inverseSurface": b06 if darkmode else b01,
        "inverseOnSurface": b00 if darkmode else b07,
        "surfaceTint": primary_val,
        "shadow": "#000000",
        "scrim": "#000000",
        "primaryPaletteKeyColor": primary_val,
        "secondaryPaletteKeyColor": secondary_val,
        "tertiaryPaletteKeyColor": tertiary_val,
        "neutralPaletteKeyColor": b03,
        "neutralVariantPaletteKeyColor": b04,
        "errorPaletteKeyColor": error_val,
    }

    term_colors = {
        "term0": b00,
        "term1": b08,
        "term2": b0B,
        "term3": b0A,
        "term4": b0D,
        "term5": b0E,
        "term6": b0C,
        "term7": b05,
        "term8": b03,
        "term9": b08,
        "term10": b0B,
        "term11": b0A,
        "term12": b0D,
        "term13": b0E,
        "term14": b0C,
        "term15": b07 if darkmode else b06,
    }
else:
    if args.invert_hue and hct is not None:
        hct = Hct.from_hct((hct.hue + 180.0) % 360.0, hct.chroma, hct.tone)

    if args.scheme and not args.scheme.startswith("scheme-") and args.scheme != "auto":
        args.scheme = f"scheme-{args.scheme}"

    if args.scheme == "scheme-fruit-salad":
        from materialyoucolor.scheme.scheme_fruit_salad import SchemeFruitSalad as Scheme
    elif args.scheme == "scheme-expressive":
        from materialyoucolor.scheme.scheme_expressive import SchemeExpressive as Scheme
    elif args.scheme == "scheme-monochrome":
        from materialyoucolor.scheme.scheme_monochrome import SchemeMonochrome as Scheme
    elif args.scheme == "scheme-rainbow":
        from materialyoucolor.scheme.scheme_rainbow import SchemeRainbow as Scheme
    elif args.scheme == "scheme-tonal-spot":
        from materialyoucolor.scheme.scheme_tonal_spot import SchemeTonalSpot as Scheme
    elif args.scheme == "scheme-neutral":
        from materialyoucolor.scheme.scheme_neutral import SchemeNeutral as Scheme
    elif args.scheme == "scheme-fidelity":
        from materialyoucolor.scheme.scheme_fidelity import SchemeFidelity as Scheme
    elif args.scheme == "scheme-content":
        from materialyoucolor.scheme.scheme_content import SchemeContent as Scheme
    elif args.scheme == "scheme-vibrant":
        from materialyoucolor.scheme.scheme_vibrant import SchemeVibrant as Scheme
    else:
        from materialyoucolor.scheme.scheme_tonal_spot import SchemeTonalSpot as Scheme

    scheme = Scheme(hct, darkmode, 0.0)

    material_colors = {}
    term_colors = {}

    for color in vars(MaterialDynamicColors).keys():
        color_name = getattr(MaterialDynamicColors, color)
        if hasattr(color_name, "get_hct"):
            generated_hct = color_name.get_hct(scheme)
    
            # Apply softening if requested and scheme allows it
            if args.soften and args.scheme not in [
                "scheme-tonal-spot",
                "scheme-neutral",
                "scheme-monochrome",
            ]:
                generated_hct = Hct.from_hct(
                    generated_hct.hue, generated_hct.chroma * 0.60, generated_hct.tone
                )
    
            # Scale output chroma for color strength — skip near-achromatic tokens
            # (chroma < 2 means effectively gray/black/white, leave untouched)
            if abs(args.color_strength - 1.0) > 1e-6 and generated_hct.chroma > 2.0:
                generated_hct = Hct.from_hct(
                    generated_hct.hue,
                    generated_hct.chroma * args.color_strength,
                    generated_hct.tone,
                )
    
            rgba = generated_hct.to_rgba()
            material_colors[color] = rgba_to_hex(rgba)
    
    # Extended material
    if darkmode == True:
        material_colors["success"] = "#B5CCBA"
        material_colors["onSuccess"] = "#213528"
        material_colors["successContainer"] = "#374B3E"
        material_colors["onSuccessContainer"] = "#D1E9D6"
    else:
        material_colors["success"] = "#4F6354"
        material_colors["onSuccess"] = "#FFFFFF"
        material_colors["successContainer"] = "#D1E8D5"
        material_colors["onSuccessContainer"] = "#0C1F13"
    
    # The shell's own material as the surface base: the ramp between surfaces keeps
    # its steps, the hue and chroma come from the seed, so apps read as the shell.
    SURFACE_RAMP = [
        "background", "surface", "surfaceDim", "surfaceBright", "surfaceVariant",
        "surfaceContainerLowest", "surfaceContainerLow", "surfaceContainer",
        "surfaceContainerHigh", "surfaceContainerHighest",
    ]
    if args.surface_seed and re.fullmatch(r"#?[0-9A-Fa-f]{6}", args.surface_seed.strip()):
        seed_hct = Hct.from_int(hex_to_argb("#" + args.surface_seed.strip().lstrip("#")))
        # A seed of the other polarity is a scheme change still on its way: ignore it.
        if (seed_hct.tone < 50) == bool(darkmode) and "background" in material_colors:
            base_tone = Hct.from_int(hex_to_argb(material_colors["background"])).tone
            # A paper stays a paper and a night a night: past these tones no role can be solved against the ramp.
            seed_tone = max(64.0, seed_hct.tone) if not darkmode else min(30.0, seed_hct.tone)
            for key in SURFACE_RAMP:
                if key not in material_colors:
                    continue
                tone = Hct.from_int(hex_to_argb(material_colors[key])).tone
                shifted = max(0.0, min(100.0, seed_tone + (tone - base_tone)))
                material_colors[key] = argb_to_hex(
                    Hct.from_hct(seed_hct.hue, seed_hct.chroma, shifted).to_int()
                )
            # The ramp moved, and the text and accent roles were solved for the stock paper (or night). Solve them again against
            # the surface they now sit farthest from (the darkest in light, the lightest in dark), keeping hue and chroma, so a
            # seed that follows the shell's frost never costs legibility.
            ramp = [hex_to_argb(material_colors[key]) for key in SURFACE_RAMP if key in material_colors]
            worst = (min if not darkmode else max)(ramp, key=lambda argb: Hct.from_int(argb).tone)
            for key, ratio in (
                ("onSurface", 7.0), ("onBackground", 7.0), ("onSurfaceVariant", 4.5),
                ("primary", 4.5), ("secondary", 4.5), ("tertiary", 4.5), ("error", 4.5), ("outline", 3.0),
            ):
                if key in material_colors:
                    material_colors[key] = argb_to_hex(
                        ensure_contrast(
                            hex_to_argb(material_colors[key]), worst, ratio, bool(darkmode), 94.0 if darkmode else 8.0
                        )
                    )
    
    # Terminal Colors
    if args.termscheme is not None:
        with open(args.termscheme, "r") as f:
            json_termscheme = f.read()
        term_source_colors = json.loads(json_termscheme)["dark" if darkmode else "light"]
    
        # Handle both snake_case and camelCase key naming across library versions
        primary_key = material_colors.get(
            "primary_paletteKeyColor",
            material_colors.get(
                "primaryPaletteKeyColor", material_colors.get("primary", "#6750A4")
            ),
        )
        primary_color_argb = hex_to_argb(primary_key)
    
        # User-configurable parameters
        user_saturation = args.term_saturation  # 0.0-1.0
        user_brightness = args.term_brightness  # 0.0-1.0
        user_harmony = args.harmony  # 0.0-1.0
        user_bg_brightness = args.term_bg_brightness  # 0.0-1.0
    
        # Define surface colors for interpolation based on bg_brightness
        # 0.0 = background (darkest), 0.5 = surfaceContainerLow (matches shell), 1.0 = surfaceContainerHighest (lightest)
        surface_levels = [
            ("background", 0.0),
            ("surfaceContainerLowest", 0.2),
            ("surfaceContainerLow", 0.4),
            ("surfaceContainer", 0.6),
            ("surfaceContainerHigh", 0.8),
            ("surfaceContainerHighest", 1.0),
        ]
    
        def get_interpolated_surface(brightness):
            """Get a surface color based on brightness (0-1)"""
            # Find the two surface levels to interpolate between
            for i, (name, level) in enumerate(surface_levels):
                if brightness <= level or i == len(surface_levels) - 1:
                    if i == 0:
                        return material_colors.get(name, "#1a1a1a")
                    # Interpolate between previous and current
                    prev_name, prev_level = surface_levels[i - 1]
                    t = (
                        (brightness - prev_level) / (level - prev_level)
                        if level != prev_level
                        else 0
                    )
                    c1 = hex_to_argb(material_colors.get(prev_name, "#1a1a1a"))
                    c2 = hex_to_argb(material_colors.get(name, "#2a2a2a"))
                    # Simple RGB interpolation
                    r1, g1, b1 = (c1 >> 16) & 0xFF, (c1 >> 8) & 0xFF, c1 & 0xFF
                    r2, g2, b2 = (c2 >> 16) & 0xFF, (c2 >> 8) & 0xFF, c2 & 0xFF
                    r = int(r1 + (r2 - r1) * t)
                    g = int(g1 + (g2 - g1) * t)
                    b = int(b1 + (b2 - b1) * t)
                    return f"#{r:02X}{g:02X}{b:02X}"
            return material_colors.get("surfaceContainerLow", "#1a1a1a")
    
        for color, val in term_source_colors.items():
            if args.scheme == "monochrome":
                term_colors[color] = val
                continue
    
            # Terminal background: Interpolate based on user_bg_brightness
            # 0.5 = surfaceContainerLow (matches shell surfaces perfectly)
            if color == "term0":
                term_colors[color] = get_interpolated_surface(user_bg_brightness)
                continue
    
            # Terminal foreground: Use EXACT Material onSurface color
            if color == "term15":
                term_colors[color] = material_colors.get("onSurface", "#e0e0e0")
                continue
    
            # term8: autosuggestion color — needs contrast against term0
            if color == "term8":
                if darkmode:
                    term_colors[color] = material_colors.get(
                        "outline",
                        get_interpolated_surface(min(1.0, user_bg_brightness + 0.45)),
                    )
                else:
                    term_colors[color] = material_colors.get(
                        "outline",
                        get_interpolated_surface(max(0.0, user_bg_brightness - 0.45)),
                    )
                continue
    
            if color == "term7":
                # Neutral colors (gray tones) - minimal harmonization
                harmonized = harmonize(
                    hex_to_argb(val),
                    primary_color_argb,
                    args.harmonize_threshold * 0.3,
                    user_harmony * 0.4,
                )
                # Apply user saturation (reduced for grays)
                harmonized = boost_chroma_tone(harmonized, user_saturation * 1.2, 1)
            else:
                # Regular semantic colors — gentle harmonization preserves hue identity
                harmonized = harmonize(
                    hex_to_argb(val),
                    primary_color_argb,
                    args.harmonize_threshold * 0.12,
                    user_harmony,
                )
                # Apply user saturation and brightness
                # Brightness affects tone: higher = lighter in dark mode, darker in light mode
                tone_mult = 1 + ((user_brightness - 0.5) * 0.8 * (1 if darkmode else -1))
                # Foreground boost gently pushes ANSI colors away from background tone.
                # Keep this bounded so high values don't collapse colors to white/black.
                fg_boost_delta = args.term_fg_boost * 0.25 * (1 if darkmode else -1)
                tone_mult = max(0.60, min(1.45, tone_mult + fg_boost_delta))
                harmonized = boost_chroma_tone(harmonized, user_saturation * 2.0, tone_mult)
                # Ensure minimum chroma for visual distinctiveness
                harmonized = ensure_min_chroma(harmonized, 40)
    
            # Apply additional softening if requested
            if args.soften and args.scheme not in [
                "scheme-tonal-spot",
                "scheme-neutral",
                "scheme-monochrome",
            ]:
                harmonized = boost_chroma_tone(harmonized, 0.55, 1)
    
            term_colors[color] = argb_to_hex(harmonized)
    
        # Second pass: ensure all foreground colors have sufficient contrast against background
        # WCAG AA requires 4.5:1 for normal text, 3:1 for large text
        # Normal colors (term1-6) use 4.5:1, bright colors (term9-14) use 3.5:1 since they're
        # already intended to be lighter and we don't want to wash them out to white
        if "term0" in term_colors:
            bg_argb = hex_to_argb(term_colors["term0"])
    
            # Normal semantic colors: stricter contrast (4.5:1)
            normal_colors = ["term1", "term2", "term3", "term4", "term5", "term6"]
            for color in normal_colors:
                if color in term_colors:
                    fg_argb = hex_to_argb(term_colors[color])
                    adjusted = ensure_contrast(fg_argb, bg_argb, 4.5, darkmode)
                    term_colors[color] = argb_to_hex(adjusted)
    
            # Bright semantic colors: lighter contrast requirement (3.5:1) to preserve vibrancy
            bright_colors = ["term9", "term10", "term11", "term12", "term13", "term14"]
            for color in bright_colors:
                if color in term_colors:
                    fg_argb = hex_to_argb(term_colors[color])
                    adjusted = ensure_contrast(fg_argb, bg_argb, 3.5, darkmode)
                    term_colors[color] = argb_to_hex(adjusted)
    
    # Fallback: derive term colors from material colors when no termscheme provided
    if not term_colors and material_colors:
        term_colors = {
            "term0": material_colors.get("surfaceVariant", "#282828"),
            "term1": material_colors.get("error", "#CC241D"),
            "term2": material_colors.get("secondary", "#98971A"),
            "term3": material_colors.get("tertiary", "#D79921"),
            "term4": material_colors.get("primary", "#458588"),
            "term5": material_colors.get("tertiary", "#B16286"),
            "term6": material_colors.get("secondary", "#689D6A"),
            "term7": material_colors.get("onSurfaceVariant", "#A89984"),
            "term8": material_colors.get("outline", "#928374"),
            "term9": material_colors.get("error", "#FB4934"),
            "term10": material_colors.get("secondary", "#B8BB26"),
            "term11": material_colors.get("tertiary", "#FABD2F"),
            "term12": material_colors.get("primary", "#83A598"),
            "term13": material_colors.get("tertiary", "#D3869B"),
            "term14": material_colors.get("secondary", "#8EC07C"),
            "term15": material_colors.get("onSurface", "#EBDBB2"),
        }

def build_scss_output() -> str:
    lines = [f"$darkmode: {darkmode};", f"$transparent: {transparent};"]
    for color, code in material_colors.items():
        lines.append(f"${color}: {code};")
    for color, code in term_colors.items():
        lines.append(f"${color}: {code};")
    return "\n".join(lines) + "\n"


scss_output = build_scss_output()

if args.scss_output:
    with open(args.scss_output, "w") as f:
        f.write(scss_output)

if args.debug == False:
    print(scss_output, end="")
else:
    if args.path is not None:
        print("\n--------------Image properties-----------------")
        print(f"Image size: {wsize} x {hsize}")
        print(f"Resized image: {wsize_new} x {hsize_new}")
    print("\n---------------Selected color------------------")
    print(f"Dark mode: {darkmode}")
    print(f"Scheme: {args.scheme}")
    print(f"Accent color: {display_color(rgba_from_argb(argb))} {argb_to_hex(argb)}")
    print(f"HCT: {hct.hue:.2f}  {hct.chroma:.2f}  {hct.tone:.2f}")
    print("\n---------------Material colors-----------------")
    for color, code in material_colors.items():
        rgba = rgba_from_argb(hex_to_argb(code))
        print(f"{color.ljust(32)} : {display_color(rgba)}  {code}")
    print("\n----------Harmonize terminal colors------------")
    for color, code in term_colors.items():
        rgba = rgba_from_argb(hex_to_argb(code))
        code_source = term_source_colors[color]
        rgba_source = rgba_from_argb(hex_to_argb(code_source))
        print(
            f"{color.ljust(6)} : {display_color(rgba_source)} {code_source} --> {display_color(rgba)} {code}"
        )
    print("-----------------------------------------------")


def build_palette_json():
    palette = {
        "primary": material_colors.get("primary", ""),
        "on_primary": material_colors.get("onPrimary", ""),
        "primary_container": material_colors.get("primaryContainer", ""),
        "on_primary_container": material_colors.get("onPrimaryContainer", ""),
        "primary_fixed": material_colors.get("primaryFixed", ""),
        "primary_fixed_dim": material_colors.get("primaryFixedDim", ""),
        "on_primary_fixed": material_colors.get("onPrimaryFixed", ""),
        "on_primary_fixed_variant": material_colors.get("onPrimaryFixedVariant", ""),
        "secondary": material_colors.get("secondary", ""),
        "on_secondary": material_colors.get("onSecondary", ""),
        "secondary_container": material_colors.get("secondaryContainer", ""),
        "on_secondary_container": material_colors.get("onSecondaryContainer", ""),
        "secondary_fixed": material_colors.get("secondaryFixed", ""),
        "secondary_fixed_dim": material_colors.get("secondaryFixedDim", ""),
        "on_secondary_fixed": material_colors.get("onSecondaryFixed", ""),
        "on_secondary_fixed_variant": material_colors.get(
            "onSecondaryFixedVariant", ""
        ),
        "tertiary": material_colors.get("tertiary", ""),
        "on_tertiary": material_colors.get("onTertiary", ""),
        "tertiary_container": material_colors.get("tertiaryContainer", ""),
        "on_tertiary_container": material_colors.get("onTertiaryContainer", ""),
        "tertiary_fixed": material_colors.get("tertiaryFixed", ""),
        "tertiary_fixed_dim": material_colors.get("tertiaryFixedDim", ""),
        "on_tertiary_fixed": material_colors.get("onTertiaryFixed", ""),
        "on_tertiary_fixed_variant": material_colors.get("onTertiaryFixedVariant", ""),
        "error": material_colors.get("error", ""),
        "on_error": material_colors.get("onError", ""),
        "error_container": material_colors.get("errorContainer", ""),
        "on_error_container": material_colors.get("onErrorContainer", ""),
        "background": material_colors.get("background", ""),
        "on_background": material_colors.get("onBackground", ""),
        "surface": material_colors.get("surface", ""),
        "on_surface": material_colors.get("onSurface", ""),
        "surface_dim": material_colors.get("surfaceDim", ""),
        "surface_bright": material_colors.get("surfaceBright", ""),
        "surface_variant": material_colors.get("surfaceVariant", ""),
        "on_surface_variant": material_colors.get("onSurfaceVariant", ""),
        "surface_container_lowest": material_colors.get("surfaceContainerLowest", ""),
        "surface_container_low": material_colors.get("surfaceContainerLow", ""),
        "surface_container": material_colors.get("surfaceContainer", ""),
        "surface_container_high": material_colors.get("surfaceContainerHigh", ""),
        "surface_container_highest": material_colors.get("surfaceContainerHighest", ""),
        "outline": material_colors.get("outline", ""),
        "outline_variant": material_colors.get("outlineVariant", ""),
        "inverse_surface": material_colors.get("inverseSurface", ""),
        "inverse_on_surface": material_colors.get("inverseOnSurface", ""),
        "inverse_primary": material_colors.get("inversePrimary", ""),
        "shadow": material_colors.get("shadow", ""),
        "scrim": material_colors.get("scrim", ""),
        "surface_tint": material_colors.get("surfaceTint", ""),
        "success": material_colors.get("success", ""),
        "on_success": material_colors.get("onSuccess", ""),
        "success_container": material_colors.get("successContainer", ""),
        "on_success_container": material_colors.get("onSuccessContainer", ""),
    }
    return palette


palette_json = build_palette_json()
app_palette_json = build_app_palette(palette_json)
colors_json = dict(palette_json)
for tkey, tval in term_colors.items():
    colors_json[tkey] = tval

theme_meta = {
    "source": "image"
    if args.path is not None
    else "color"
    if args.color is not None
    else "unknown",
    "source_path": args.path,
    "seed_color": argb_to_hex(argb),
    "mode": "dark" if darkmode else "light",
    "scheme": args.scheme,
    "transparent": transparent,
    "soften": args.soften,
    "term_harmony": args.harmony,
    "term_saturation": args.term_saturation,
    "term_brightness": args.term_brightness,
    "term_bg_brightness": args.term_bg_brightness,
    "term_fg_boost": args.term_fg_boost,
    "harmonize_threshold": args.harmonize_threshold,
    "color_strength": args.color_strength,
    "blend_bg_fg": args.blend_bg_fg,
    # The surface iRiS asked for: the shell holds the apps until a generation carries the one it wants.
    "surface_seed": ("#" + args.surface_seed.strip().lstrip("#").lower())
    if args.surface_seed and re.fullmatch(r"#?[0-9A-Fa-f]{6}", args.surface_seed.strip())
    else "",
    "generated_by": "generate_colors_material.py",
}


if palette_dict is not None:
    theme_meta["source"] = "palette"
    theme_meta["palette"] = args.palette
    colors_json = {
        "background": b00,
        "surface": b01,
        "surfaceContainer": b02,
        "surfaceVariant": b03,
        "border": b03,
        "text": b05,
        "textSecondary": b04,
        "textBright": b06,
        "primary": primary_val,
        "on_primary": on_primary_val,
        "secondary": secondary_val,
        "tertiary": tertiary_val,
        "warning": warning_val,
        "error": error_val,
        "success": success_val,
        "shadow": "#000000",
        "primarySlot": active_slot,
        "base00": b00,
        "base01": b01,
        "base02": b02,
        "base03": b03,
        "base04": b04,
        "base05": b05,
        "base06": b06,
        "base07": b07,
        "base08": b08,
        "base09": b09,
        "base0A": b0A,
        "base0B": b0B,
        "base0C": b0C,
        "base0D": b0D,
        "base0E": b0E,
        "base0F": b0F,
    }
    for tkey, tval in term_colors.items():
        colors_json[tkey] = tval
else:
    colors_json["background"] = material_colors.get("surface", material_colors.get("background", "#130C0C"))
    colors_json["surface"] = material_colors.get("surfaceContainerLow", colors_json["background"])
    colors_json["surfaceContainer"] = material_colors.get("surfaceContainer", colors_json["surface"])
    colors_json["surfaceVariant"] = material_colors.get("surfaceContainerHigh", colors_json["surfaceContainer"])
    colors_json["border"] = material_colors.get("outline", "#847171")
    colors_json["text"] = material_colors.get("onSurfaceVariant", "#BCA6A5")
    colors_json["textBright"] = material_colors.get("onSurface", "#F8E0DF")
    colors_json["textSecondary"] = material_colors.get("outline", "#847171")
    colors_json["primary"] = material_colors.get("primary", "#F8B6B6")
    colors_json["on_primary"] = material_colors.get("onPrimary", "#613334")
    colors_json["secondary"] = material_colors.get("secondary", "#E6BDBC")
    colors_json["tertiary"] = material_colors.get("tertiary", "#FFDFF4")
    colors_json["warning"] = material_colors.get("secondary", "#E6BDBC")
    colors_json["error"] = material_colors.get("error", "#F97758")
    colors_json["success"] = material_colors.get("success", colors_json["primary"])
    colors_json["shadow"] = "#000000"

    active_slot = args.primary_slot or get_configured_primary_slot()
    colors_json["primarySlot"] = active_slot

    colors_json["base00"] = colors_json["background"]
    colors_json["base01"] = colors_json["surface"]
    colors_json["base02"] = colors_json["surfaceContainer"]
    colors_json["base03"] = colors_json["border"]
    colors_json["base04"] = colors_json["text"]
    colors_json["base05"] = colors_json["textBright"]
    colors_json["base06"] = colors_json["textBright"]
    colors_json["base07"] = colors_json["textBright"]
    colors_json["base08"] = term_colors.get("term1", colors_json["error"])
    colors_json["base09"] = term_colors.get("term9", colors_json["tertiary"])
    colors_json["base0A"] = term_colors.get("term3", colors_json["secondary"])
    colors_json["base0B"] = term_colors.get("term2", colors_json.get("success", colors_json["primary"]))
    colors_json["base0C"] = term_colors.get("term6", colors_json["tertiary"])
    colors_json["base0D"] = colors_json["primary"]
    colors_json["base0E"] = term_colors.get("term5", colors_json["secondary"])
    colors_json["base0F"] = term_colors.get("term13", colors_json["error"])

    if active_slot in colors_json:
        if active_slot == "base0D":
            primary_val = colors_json["base0D"]
            on_primary_val = material_colors.get("onPrimary", _contrast_hex(primary_val))
        else:
            primary_val = colors_json[active_slot]
            on_primary_val = _contrast_hex(primary_val)
        colors_json["primary"] = primary_val
        colors_json["on_primary"] = on_primary_val
        material_colors["primary"] = primary_val
        material_colors["onPrimary"] = on_primary_val
        palette_json = build_palette_json()
        app_palette_json = build_app_palette(palette_json)

    if args.scss_output:
        with open(args.scss_output, "w") as f:
            f.write(build_scss_output())

if args.asura_output:
    os.makedirs(os.path.dirname(os.path.abspath(os.path.expanduser(args.asura_output))), exist_ok=True)
    with open(args.asura_output, "w") as f:
        json.dump(colors_json, f, indent=4)

if args.json_output:
    with open(args.json_output, "w") as f:
        json.dump(colors_json, f, indent=2)

if args.palette_output:
    with open(args.palette_output, "w") as f:
        json.dump(palette_json, f, indent=2)

if args.app_palette_output:
    with open(args.app_palette_output, "w") as f:
        json.dump(app_palette_json, f, indent=2)

if args.terminal_output:
    with open(args.terminal_output, "w") as f:
        json.dump(term_colors, f, indent=2)

if args.meta_output:
    with open(args.meta_output, "w") as f:
        json.dump(theme_meta, f, indent=2)

# ---------------------------------------------------------------------------
# Template rendering for iNiR's unified theming pipeline
# ---------------------------------------------------------------------------
template_dirs = []
if args.render_templates:
    if isinstance(args.render_templates, list):
        template_dirs.extend(args.render_templates)
    else:
        template_dirs.append(args.render_templates)

# Auto-discover repository templates if present
repo_templates = os.path.abspath(
    os.path.join(os.path.dirname(__file__), "..", "..", "templates")
)
if os.path.isdir(repo_templates) and repo_templates not in template_dirs:
    template_dirs.append(repo_templates)

if template_dirs:
    template_entries = []
    managed_outputs = set()
    for managed_path in [
        args.json_output,
        args.asura_output,
        args.palette_output,
        args.app_palette_output,
        args.terminal_output,
        args.meta_output,
        args.scss_output,
    ]:
        if not managed_path:
            continue
        resolved = os.path.abspath(os.path.expanduser(managed_path))
        if resolved.endswith(".tmp"):
            resolved = resolved[:-4]
        managed_outputs.add(resolved)

    seen_outputs = set(managed_outputs)

    # Resolve disabled templates and app theming setting from args or config.json
    disabled_templates = set(args.disabled_templates or [])
    app_theming_enabled = not args.disable_all_templates

    cfg_candidates = [
        os.path.expanduser("~/.config/asura/config.json"),
        os.path.expanduser("~/.config/quickshell/Asura/config/config.json"),
        os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "Asura", "config", "config.json")),
    ]
    for cfg_candidate in cfg_candidates:
        if os.path.isfile(cfg_candidate):
            try:
                with open(cfg_candidate, "r", encoding="utf-8") as f:
                    cdata = json.load(f)
                    if cdata.get("appThemingEnabled") is False:
                        app_theming_enabled = False
                    for item in cdata.get("disabledTemplates", []):
                        disabled_templates.add(item)
            except Exception as e:
                print(f"[render-templates] Warning reading config {cfg_candidate}: {e}", file=sys.stderr)
            break

    if not app_theming_enabled:
        print("[render-templates] App theming is globally disabled. Skipping templates.", file=sys.stderr)
        template_dirs = []

    for template_dir in template_dirs:
        template_dir = os.path.abspath(os.path.expanduser(template_dir))
        manifest_path = os.path.join(template_dir, "templates.json")
        legacy_config_path = os.path.join(template_dir, "config.toml")

        if os.path.isfile(manifest_path):
            try:
                with open(manifest_path, "r") as f:
                    manifest = json.load(f)
            except Exception as e:
                print(f"[render-templates] Error reading {manifest_path}: {e}", file=sys.stderr)
                continue

            templates_base = os.path.join(template_dir, "templates")
            if not os.path.isdir(templates_base):
                templates_base = template_dir

            for entry in manifest.get("templates", []):
                tpl_name = entry.get("name", "template")
                if tpl_name in disabled_templates or entry.get("enabled") is False:
                    print(f"[render-templates] Skipping disabled template: {tpl_name}", file=sys.stderr)
                    continue

                output_path = os.path.abspath(os.path.expanduser(entry["output"]))
                if output_path in seen_outputs:
                    continue
                seen_outputs.add(output_path)

                input_rel = entry["input"]
                tpl_candidate = os.path.join(templates_base, input_rel)
                if not os.path.isfile(tpl_candidate):
                    tpl_candidate = os.path.join(template_dir, input_rel)

                template_entries.append(
                    {
                        "name": tpl_name,
                        "template_path": tpl_candidate,
                        "output_path": output_path,
                        "post_hook": entry.get("post_hook"),
                    }
                )
        elif os.path.isfile(legacy_config_path):
            if tomllib is None:
                print(
                    "[render-templates] Legacy config.toml found but tomllib is unavailable, skipping",
                    file=sys.stderr,
                )
            else:
                try:
                    with open(legacy_config_path, "rb") as f:
                        legacy_config = tomllib.load(f)
                except Exception as e:
                    print(f"[render-templates] Error reading {legacy_config_path}: {e}", file=sys.stderr)
                    continue

                for name, entry in (legacy_config.get("templates") or {}).items():
                    if not isinstance(entry, dict):
                        continue

                    input_path = entry.get("input_path")
                    output_path = entry.get("output_path")
                    if not input_path or not output_path:
                        continue
                    if input_path == "/dev/null" or output_path == "/dev/null":
                        continue

                    resolved_input = os.path.expanduser(input_path)
                    resolved_output = os.path.abspath(os.path.expanduser(output_path))
                    if resolved_output in seen_outputs:
                        continue
                    seen_outputs.add(resolved_output)

                    if not os.path.isfile(resolved_input) and "/templates/" in input_path:
                        rel_input = input_path.split("/templates/", 1)[1].lstrip("/")
                        candidate = os.path.join(template_dir, "templates", rel_input)
                        if os.path.isfile(candidate):
                            resolved_input = candidate

                    post_hook = entry.get("post_hook")
                    template_entries.append(
                        {
                            "name": name,
                            "template_path": resolved_input,
                            "output_path": resolved_output,
                            "post_hook": post_hook,
                        }
                    )

    if not template_entries:
        # Nothing to render — either no manifest found or all entries were
        # invalid.  Color generation already succeeded, so exit cleanly.
        sys.exit(0)

    # Build both dark and light palettes so templates can use either variant.
    # The main `material_colors` dict was generated for the *current* mode;
    # we also need the opposite mode for templates like GTK4 that embed both.
    def _generate_palette(is_dark):
        if palette_dict is not None:
            return dict(palette_json)
        s = Scheme(hct, is_dark, 0.0)
        palette = {}
        for c in vars(MaterialDynamicColors).keys():
            cn = getattr(MaterialDynamicColors, c)
            if hasattr(cn, "get_hct"):
                g = cn.get_hct(s)
                if args.soften and args.scheme not in [
                    "scheme-tonal-spot",
                    "scheme-neutral",
                    "scheme-monochrome",
                ]:
                    g = Hct.from_hct(g.hue, g.chroma * 0.60, g.tone)
                palette[c] = rgba_to_hex(g.to_rgba())
        # source_color is the seed itself
        palette["source_color"] = argb_to_hex(argb)
        # Extended Material tokens (not in MaterialDynamicColors)
        if is_dark:
            palette["success"] = "#B5CCBA"
            palette["onSuccess"] = "#213528"
            palette["successContainer"] = "#374B3E"
            palette["onSuccessContainer"] = "#D1E9D6"
        else:
            palette["success"] = "#4F6354"
            palette["onSuccess"] = "#FFFFFF"
            palette["successContainer"] = "#D1E8D5"
            palette["onSuccessContainer"] = "#0C1F13"
        if is_dark == darkmode:
            palette["primary"] = material_colors.get("primary", palette.get("primary", ""))
            palette["onPrimary"] = material_colors.get("onPrimary", palette.get("onPrimary", ""))
        raw_contract = {
            "primary": palette.get("primary", ""),
            "on_primary": palette.get("onPrimary", ""),
            "primary_container": palette.get("primaryContainer", ""),
            "on_primary_container": palette.get("onPrimaryContainer", ""),
            "background": palette.get("background", ""),
            "on_background": palette.get("onBackground", ""),
            "surface": palette.get("surface", ""),
            "on_surface": palette.get("onSurface", ""),
            "surface_dim": palette.get("surfaceDim", ""),
            "surface_bright": palette.get("surfaceBright", ""),
            "surface_container_lowest": palette.get("surfaceContainerLowest", ""),
            "surface_container_low": palette.get("surfaceContainerLow", ""),
            "surface_container": palette.get("surfaceContainer", ""),
            "surface_container_high": palette.get("surfaceContainerHigh", ""),
            "surface_container_highest": palette.get("surfaceContainerHighest", ""),
            "on_surface_variant": palette.get("onSurfaceVariant", ""),
            "outline": palette.get("outline", ""),
            "outline_variant": palette.get("outlineVariant", ""),
        }
        palette.update(build_app_palette(raw_contract))
        return palette

    dark_palette = _generate_palette(True)
    light_palette = _generate_palette(False)
    default_palette = dark_palette if darkmode else light_palette

    # Build the nested `colors` namespace expected by the compatibility templates:
    #   colors.<token>.dark.hex          → "#rrggbb"
    #   colors.<token>.dark.hex_stripped  → "rrggbb"
    #   colors.<token>.dark.rgb          → "R, G, B" (decimal triplet)
    #   colors.<token>.light.hex
    #   colors.<token>.default.hex       → follows current mode
    class _Hex:
        """Wrapper for color formats with support for hex, stripped hex, rgb, rgba, and components."""

        __slots__ = ("hex", "hex_stripped", "rgb", "rgba", "r", "g", "b")

        def __init__(self, hexval):
            self.hex = hexval
            self.hex_stripped = hexval.lstrip("#")
            h = self.hex_stripped
            self.r = int(h[0:2], 16)
            self.g = int(h[2:4], 16)
            self.b = int(h[4:6], 16)
            self.rgb = f"rgb({self.r}, {self.g}, {self.b})"
            self.rgba = f"rgba({self.r}, {self.g}, {self.b}, 1.0)"

    class _Token:
        __slots__ = ("dark", "light", "default")

        def __init__(self, dk, lt, df):
            self.dark = _Hex(dk)
            self.light = _Hex(lt)
            self.default = _Hex(df)

    # Collect every token name that appears in either palette
    all_tokens = set(dark_palette.keys()) | set(light_palette.keys())
    colors_ns = {}

    def _camel_to_snake(name):
        """Convert camelCase to snake_case for compatibility template aliases."""
        return re.sub(r"(?<=[a-z0-9])([A-Z])", r"_\1", name).lower()

    for tok in all_tokens:
        dk = dark_palette.get(tok, "#000000")
        lt = light_palette.get(tok, "#000000")
        df = default_palette.get(tok, "#000000")
        token_obj = _Token(dk, lt, df)
        # Register under both camelCase and snake_case keys
        colors_ns[tok] = token_obj
        snake = _camel_to_snake(tok)
        if snake != tok:
            colors_ns[snake] = token_obj

    base16_ns = {}
    for i in range(16):
        key_l = f"base0{i:x}"
        key_u = f"base0{i:X}"
        val = colors_json.get(key_l, colors_json.get(key_u, "#000000"))
        tok_obj = _Token(val, val, val)
        base16_ns[key_l] = tok_obj
        base16_ns[key_u] = tok_obj
        colors_ns[key_l] = tok_obj
        colors_ns[key_u] = tok_obj

    _LOOP_RE = re.compile(
        r"<\*\s*for\s+(\w+)\s*,\s*(\w+)\s+in\s+colors\s*\*>(.*?)<\*\s*endfor\s*\*>",
        re.DOTALL,
    )

    def _expand_loops(text):
        def _repl(match):
            name_var, val_var, body = match.group(1), match.group(2), match.group(3)
            name_re = re.compile(r"\{\{\s*" + name_var + r"\s*\}\}")
            val_re = re.compile(r"\{\{\s*" + val_var + r"\.([a-zA-Z0-9_]+)\.([a-zA-Z0-9_]+)\s*\}\}")
            lines = []
            seen = set()
            for tok_name, tok_obj in colors_ns.items():
                snake_name = _camel_to_snake(tok_name)
                if snake_name in seen:
                    continue
                seen.add(snake_name)

                line = body
                line = name_re.sub(snake_name, line)

                def _val_repl(vm):
                    mode, prop = vm.group(1), vm.group(2)
                    mode_obj = getattr(tok_obj, mode, getattr(tok_obj, "default", None))
                    if mode_obj:
                        return str(getattr(mode_obj, prop, ""))
                    return vm.group(0)

                line = val_re.sub(_val_repl, line)
                lines.append(line.rstrip("\r\n"))
            return "\n".join(lines) + "\n"

        return _LOOP_RE.sub(_repl, text)

    _VAR_RE = re.compile(r"\{\{\s*(.*?)\s*\}\}")

    def _resolve(match):
        raw_expr = match.group(1).strip()
        if raw_expr == "image":
            return args.path or ""

        pipe_filter = None
        if "|" in raw_expr:
            parts_pipe = raw_expr.split("|", 1)
            expr = parts_pipe[0].strip()
            pipe_filter = parts_pipe[1].strip()
        else:
            expr = raw_expr

        parts = expr.split(".")

        # System, user, and path dynamic variables for generic multi-user templates
        if expr in ("home", "HOME"):
            return os.path.expanduser("~")
        if expr in ("user", "USER", "username", "USERNAME"):
            return os.environ.get("USER") or os.environ.get("USERNAME") or getpass.getuser()
        if expr in ("pictures", "PICTURES", "xdg_pictures", "XDG_PICTURES_DIR"):
            return os.environ.get("XDG_PICTURES_DIR") or os.path.expanduser("~/Pictures")
        if expr in ("screenshots", "SCREENSHOTS"):
            pics = os.environ.get("XDG_PICTURES_DIR") or os.path.expanduser("~/Pictures")
            return os.path.join(pics, "Screenshots")
        if expr.startswith("env."):
            env_var = expr.split(".", 1)[1].strip()
            return os.environ.get(env_var, "")
        if expr == "mode":
            return "dark" if darkmode else "light"

        if len(parts) == 4 and parts[0] in ("colors", "base16"):
            namespace, token, mode, prop = parts
            target_ns = base16_ns if namespace == "base16" else colors_ns
            tok_obj = target_ns.get(token)
            if tok_obj is None and namespace == "colors":
                token_alt = _camel_to_snake(token)
                tok_obj = colors_ns.get(token_alt)
            if tok_obj is None:
                return match.group(0)

            mode_obj = getattr(tok_obj, mode, None)
            if mode_obj is None:
                mode_obj = getattr(tok_obj, "default", None)
            if mode_obj is None:
                return match.group(0)

            val = getattr(mode_obj, prop, None)
            if val is None:
                return match.group(0)

            # Apply filters if present (e.g. | saturate: 20.0, hsl | set_alpha: 0.10)
            if pipe_filter:
                curr_r, curr_g, curr_b = mode_obj.r / 255.0, mode_obj.g / 255.0, mode_obj.b / 255.0
                curr_alpha = None
                for part in pipe_filter.split("|"):
                    part = part.strip()
                    if not part:
                        continue
                    if "set_alpha:" in part:
                        m_alpha = re.search(r"set_alpha:\s*([0-9.]+)", part)
                        if m_alpha:
                            curr_alpha = m_alpha.group(1)
                    elif "saturate:" in part:
                        m_sat = re.search(r"saturate:\s*([-+]?\d*\.?\d+)", part)
                        if m_sat:
                            amt = float(m_sat.group(1)) / 100.0
                            h, l, s = colorsys.rgb_to_hls(curr_r, curr_g, curr_b)
                            s = max(0.0, min(1.0, s + amt))
                            curr_r, curr_g, curr_b = colorsys.hls_to_rgb(h, l, s)
                    elif "desaturate:" in part:
                        m_desat = re.search(r"desaturate:\s*([-+]?\d*\.?\d+)", part)
                        if m_desat:
                            amt = float(m_desat.group(1)) / 100.0
                            h, l, s = colorsys.rgb_to_hls(curr_r, curr_g, curr_b)
                            s = max(0.0, min(1.0, s - amt))
                            curr_r, curr_g, curr_b = colorsys.hls_to_rgb(h, l, s)
                    elif "lighten:" in part:
                        m_light = re.search(r"lighten:\s*([-+]?\d*\.?\d+)", part)
                        if m_light:
                            amt = float(m_light.group(1)) / 100.0
                            h, l, s = colorsys.rgb_to_hls(curr_r, curr_g, curr_b)
                            l = max(0.0, min(1.0, l + amt))
                            curr_r, curr_g, curr_b = colorsys.hls_to_rgb(h, l, s)

                nr = int(round(curr_r * 255))
                ng = int(round(curr_g * 255))
                nb = int(round(curr_b * 255))

                if curr_alpha is not None or prop == "rgba":
                    alpha_str = curr_alpha if curr_alpha is not None else "1.0"
                    return f"rgba({nr}, {ng}, {nb}, {alpha_str})"
                elif prop == "hex_stripped":
                    return f"{nr:02X}{ng:02X}{nb:02X}"
                elif prop == "rgb":
                    return f"rgb({nr}, {ng}, {nb})"
                else:
                    return f"#{nr:02X}{ng:02X}{nb:02X}"

            return str(val)

        return match.group(0)

    rendered_count = 0

    for entry in template_entries:
        tpl_path = entry["template_path"]
        out_path = entry["output_path"]

        if not os.path.isfile(tpl_path):
            print(
                f"[render-templates] Skipping missing template: {tpl_path}",
                file=sys.stderr,
            )
            continue

        with open(tpl_path, "r") as f:
            content = f.read()

        rendered = _expand_loops(content)
        rendered = _VAR_RE.sub(_resolve, rendered)

        os.makedirs(os.path.dirname(out_path), exist_ok=True)
        # Ensure any referenced save path (e.g. flameshot savePath) directory exists
        for line in rendered.splitlines():
            if line.strip().startswith("savePath="):
                sp = line.strip().split("savePath=", 1)[1].strip()
                if sp and not os.path.exists(sp):
                    try:
                        os.makedirs(sp, exist_ok=True)
                    except Exception:
                        pass
        # Break symlinks before writing so we don't corrupt external themes
        if os.path.islink(out_path):
            print(
                f"[render-templates] Replacing symlink with regular file: {out_path}",
                file=sys.stderr,
            )
            os.remove(out_path)
        with open(out_path, "w") as f:
            f.write(rendered)
        rendered_count += 1

        post_hook = entry.get("post_hook")
        if post_hook:
            hook_cmd = post_hook.replace("{{mode}}", "dark" if darkmode else "light")
            hook_cmd = hook_cmd.replace("{{image}}", args.path or "")
            hook_cmd = hook_cmd.replace("{{script_dir}}", os.path.dirname(os.path.abspath(__file__)))
            if hook_cmd.startswith("~"):
                hook_cmd = os.path.expanduser("~") + hook_cmd[1:]
            try:
                import subprocess
                subprocess.run(hook_cmd, shell=True, timeout=5, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            except Exception as e:
                print(f"[render-templates] Hook failed for {entry['name']}: {e}", file=sys.stderr)

    if rendered_count > 0:
        print(
            f"[render-templates] Rendered {rendered_count} template(s)", file=sys.stderr
        )

    # SDDM sync post-hook: run only if script and theme exist
    sddm_sync = os.path.expanduser("~/.local/bin/sync-pixel-sddm.py")
    sddm_theme = "/usr/share/sddm/themes/ii-pixel"
    if os.path.isfile(sddm_sync) and os.path.isdir(sddm_theme):
        import subprocess

        subprocess.Popen(
            ["python3", sddm_sync],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
