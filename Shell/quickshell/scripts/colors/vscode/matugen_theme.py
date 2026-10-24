#!/usr/bin/env python3
# Based on haikalllp/vscode-matugen-theme (MIT License)
# Adapted for Asura Shell

"""
Material You theme builder for VSCode.
Maps Material You color palettes
into a full VSCode color theme compatible with Material themes.
"""

import colorsys
import json
import subprocess
import sys
from pathlib import Path


# ── Color science utilities ──────────────────────────────────────────


def hex_to_rgb(hex_str: str) -> tuple[float, float, float]:
    """Convert hex string '#RRGGBB' to (r, g, b) with channels in [0, 1]."""
    h = hex_str.lstrip("#")
    return (
        int(h[0:2], 16) / 255.0,
        int(h[2:4], 16) / 255.0,
        int(h[4:6], 16) / 255.0,
    )


def rgb_to_hex(r: float, g: float, b: float) -> str:
    """Convert (r, g, b) in [0, 1] to '#RRGGBB'."""
    nr = max(0, min(255, int(round(r * 255.0))))
    ng = max(0, min(255, int(round(g * 255.0))))
    nb = max(0, min(255, int(round(b * 255.0))))
    return f"#{nr:02X}{ng:02X}{nb:02X}"


def luminosity(r: float, g: float, b: float) -> float:
    """Calculate WCAG relative luminance."""
    def _channel_lum(c: float) -> float:
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4

    return 0.2126 * _channel_lum(r) + 0.7152 * _channel_lum(g) + 0.0722 * _channel_lum(b)


def contrast_ratio(rgb1: tuple[float, float, float], rgb2: tuple[float, float, float]) -> float:
    """Calculate WCAG contrast ratio between two colors."""
    l1 = luminosity(*rgb1)
    l2 = luminosity(*rgb2)
    lighter = max(l1, l2)
    darker = min(l1, l2)
    return (lighter + 0.05) / (darker + 0.05)


def is_light_color(rgb: tuple[float, float, float]) -> bool:
    """Check if color is light based on WCAG luminance threshold 0.179."""
    return luminosity(*rgb) > 0.179


def darken(rgb: tuple[float, float, float], ratio: float) -> tuple[float, float, float]:
    """Darken color in HSL space."""
    h, l, s = colorsys.rgb_to_hls(*rgb)
    l = max(0.0, l - l * ratio)
    return colorsys.hls_to_rgb(h, l, s)


def lighten(rgb: tuple[float, float, float], ratio: float) -> tuple[float, float, float]:
    """Lighten color in HSL space."""
    h, l, s = colorsys.rgb_to_hls(*rgb)
    l = min(1.0, l + (1.0 - l) * ratio)
    return colorsys.hls_to_rgb(h, l, s)


def saturate(rgb: tuple[float, float, float], ratio: float) -> tuple[float, float, float]:
    """Saturate color by a ratio."""
    h, l, s = colorsys.rgb_to_hls(*rgb)
    s = min(1.0, s + s * ratio)
    return colorsys.hls_to_rgb(h, l, s)


def saturate_hsl_fixed(hex_str: str, amt_pct: float) -> str:
    """Add fixed percentage points to saturation in HSL space."""
    rgb = hex_to_rgb(hex_str)
    h, l, s = colorsys.rgb_to_hls(*rgb)
    s = max(0.0, min(1.0, s + (amt_pct / 100.0)))
    nr, ng, nb = colorsys.hls_to_rgb(h, l, s)
    return rgb_to_hex(nr, ng, nb)


def adjust_for_background(
    color: tuple[float, float, float],
    bg: tuple[float, float, float],
) -> tuple[float, float, float]:
    """Adjust color for visibility on dark/light background."""
    bg_is_light = is_light_color(bg)
    color_lum = luminosity(*color)
    if bg_is_light:
        if color_lum > 0.4:
            return saturate(darken(color, 0.3), 0.1)
    else:
        if color_lum < 0.15:
            return saturate(lighten(color, 0.3), 0.1)
    return color


def ensure_contrast(
    fg: tuple[float, float, float],
    bg: tuple[float, float, float],
    min_contrast: float = 4.5,
) -> tuple[float, float, float]:
    """Ensure minimum contrast ratio against background."""
    adjusted = fg
    bg_is_light = is_light_color(bg)
    for _ in range(20):
        if contrast_ratio(adjusted, bg) >= min_contrast:
            break
        adjusted = darken(adjusted, 0.1) if bg_is_light else lighten(adjusted, 0.1)
    return adjusted


# ── Palette extraction ──────────────────────────────────────────


def compute_matugen_palette(colors_data: dict) -> list[str]:
    """Calculate the 16 Matugen colors from Material tokens with HSL saturation boosts.

    Follows ~/.config/matugen/themes/vscode-colors.json specification.
    """
    asura_cache = Path.home() / ".local" / "state" / "quickshell" / "user" / "generated" / "vscode-colors.json"
    cache_path = asura_cache if asura_cache.is_file() else Path.home() / ".cache" / "matugen" / "vscode-colors.json"
    if cache_path.is_file():
        try:
            with open(cache_path, "r") as f:
                c_json = json.load(f)
            c_dict = c_json.get("colors", {})
            if len(c_dict) >= 16:
                return [c_dict[f"color{i}"] for i in range(16)]
        except Exception:
            pass

    bg = colors_data.get("background", colors_data.get("surface", "#0B0F0C"))
    on_surface = colors_data.get("on_surface", "#DFE8DD")
    on_bg = colors_data.get("on_background", on_surface)
    error = colors_data.get("error", "#FA746F")
    secondary = colors_data.get("secondary", "#B7CCB7")
    tertiary = colors_data.get("tertiary", "#F5FFC5")
    primary = colors_data.get("primary", "#A9D0AD")
    tertiary_fixed = colors_data.get("tertiary_fixed", "#F1FDBC")
    secondary_container = colors_data.get("secondary_container", "#2E4030")
    surface_variant = colors_data.get("surface_variant", "#202821")
    primary_fixed_dim = colors_data.get("primary_fixed_dim", "#B6DEBB")
    secondary_fixed = colors_data.get("secondary_fixed", "#D3E8D2")
    tertiary_fixed_dim = colors_data.get("tertiary_fixed_dim", "#E3EEAF")
    primary_container = colors_data.get("primary_container", "#375A3E")
    tertiary_container = colors_data.get("tertiary_container", "#E5F1B2")
    secondary_fixed_dim = colors_data.get("secondary_fixed_dim", "#C5DAC5")

    return [
        bg,
        saturate_hsl_fixed(error, 20.0),
        saturate_hsl_fixed(secondary, 25.0),
        saturate_hsl_fixed(tertiary, 25.0),
        saturate_hsl_fixed(primary, 15.0),
        saturate_hsl_fixed(tertiary_fixed, 20.0),
        saturate_hsl_fixed(secondary_container, 30.0),
        on_surface,
        surface_variant,
        saturate_hsl_fixed(primary_fixed_dim, 20.0),
        saturate_hsl_fixed(secondary_fixed, 20.0),
        saturate_hsl_fixed(tertiary_fixed_dim, 20.0),
        saturate_hsl_fixed(primary_container, 15.0),
        saturate_hsl_fixed(tertiary_container, 20.0),
        saturate_hsl_fixed(secondary_fixed_dim, 20.0),
        on_bg,
    ]


# ── Theme Generation ──────────────────────────────────────────


def try_node_generation(raw_colors: list[str], bordered: bool = False) -> dict | None:
    """Execute template.js from the installed matugen-theme extension via Node.js."""
    try:
        ext_dir = Path.home() / ".vscode" / "extensions"
        matches = list(ext_dir.glob("haikalllp.matugen-theme*/out/template.js"))
        if not matches:
            return None
        template_js = matches[0]
        node_modules = template_js.parent.parent / "node_modules"
        if not (node_modules / "color").exists():
            return None

        script = f"""
        const Color = require({json.dumps(str(node_modules / "color"))});
        const tmpl = require({json.dumps(str(template_js))}).default;
        const colors = {json.dumps(raw_colors)}.map(c => Color(c));
        const res = tmpl(colors, {str(bordered).lower()});
        console.log(JSON.stringify(res));
        """
        p = subprocess.run(
            ["node", "-e", script],
            capture_output=True,
            text=True,
            check=True,
            timeout=5,
        )
        return json.loads(p.stdout)
    except Exception:
        return None


def generate_matugen_theme_python(raw_colors: list[str], bordered: bool = False) -> dict:
    """Pure Python implementation of Matugen VSCode theme template."""
    rgb_colors = [hex_to_rgb(c) for c in raw_colors]
    bg_rgb = rgb_colors[0]
    is_dark = not is_light_color(bg_rgb)
    theme_type = "dark" if is_dark else "light"

    # Foreground contrast check
    fg_rgb = rgb_colors[7]
    if contrast_ratio(fg_rgb, bg_rgb) < 4.5:
        fg_rgb = hex_to_rgb("#e0e0e0") if is_dark else hex_to_rgb("#1a1a1a")

    fg_muted_rgb = darken(fg_rgb, 0.3) if is_dark else lighten(fg_rgb, 0.4)

    def _adj(c: tuple[float, float, float]) -> str:
        return rgb_to_hex(*ensure_contrast(adjust_for_background(c, bg_rgb), bg_rgb, 4.5))

    bg = rgb_to_hex(*bg_rgb)
    bg_elevated = rgb_to_hex(*(lighten(bg_rgb, 0.08) if is_dark else darken(bg_rgb, 0.03)))
    bg_highlight = rgb_to_hex(*(lighten(bg_rgb, 0.15) if is_dark else darken(bg_rgb, 0.06)))
    fg = rgb_to_hex(*fg_rgb)
    fg_muted = rgb_to_hex(*fg_muted_rgb)

    accent = _adj(rgb_colors[4])
    accent_sec = _adj(rgb_colors[6])
    error = _adj(rgb_colors[1])
    warning = _adj(rgb_colors[3])
    success = _adj(rgb_colors[2])
    info = _adj(rgb_colors[4])
    keyword = _adj(rgb_colors[5])
    string = _adj(rgb_colors[2])
    number = _adj(rgb_colors[3])
    func = _adj(rgb_colors[4])
    type_col = _adj(rgb_colors[6])
    var_col = _adj(rgb_colors[1])
    comment = fg_muted
    operator = _adj(rgb_colors[6])

    alpha = {
        "subtle": "15" if is_dark else "10",
        "light": "25" if is_dark else "18",
        "medium": "40" if is_dark else "30",
        "strong": "60" if is_dark else "50",
        "heavy": "80" if is_dark else "70",
        "solid": "cc",
        "muted": "99",
        "dimmed": "77",
        "faint": "33" if is_dark else "22",
    }

    contrast_fg = bg if is_dark else "#FFFFFF"

    # Active link hover
    accent_rgb = hex_to_rgb(accent)
    accent_hover = rgb_to_hex(*(lighten(accent_rgb, 0.2) if is_dark else darken(accent_rgb, 0.1)))

    colors = {
        "focusBorder": accent + alpha["dimmed"],
        "foreground": fg,
        "descriptionForeground": fg + alpha["muted"],
        "errorForeground": error,
        "widget.shadow": "#00000066" if is_dark else "#00000026",
        "selection.background": accent + alpha["medium"],
        "icon.foreground": fg,
        "textBlockQuote.background": bg_elevated,
        "textBlockQuote.border": accent + alpha["medium"],
        "textLink.foreground": accent,
        "textLink.activeForeground": accent_hover,
        "textPreformat.foreground": string,
        "textSeparator.foreground": fg_muted + alpha["faint"],
        "button.background": accent,
        "button.foreground": contrast_fg,
        "button.hoverBackground": accent_hover,
        "button.secondaryBackground": bg_highlight,
        "button.secondaryForeground": fg,
        "dropdown.background": bg_elevated,
        "dropdown.foreground": fg,
        "dropdown.border": fg_muted + alpha["faint"],
        "dropdown.listBackground": bg_elevated,
        "input.background": rgb_to_hex(*darken(bg_rgb, 0.1)) if is_dark else bg,
        "input.foreground": fg,
        "input.border": fg_muted + alpha["faint"],
        "input.placeholderForeground": fg_muted + alpha["dimmed"],
        "inputOption.activeBorder": accent,
        "inputOption.activeBackground": accent + alpha["light"],
        "inputOption.activeForeground": fg,
        "scrollbar.shadow": "#00000044" if is_dark else "#00000015",
        "scrollbarSlider.background": fg_muted + alpha["medium"],
        "scrollbarSlider.hoverBackground": fg_muted + alpha["strong"],
        "scrollbarSlider.activeBackground": fg_muted + alpha["heavy"],
        "badge.background": accent,
        "badge.foreground": contrast_fg,
        "progressBar.background": accent,
        "list.activeSelectionBackground": accent + alpha["light"],
        "list.activeSelectionForeground": fg,
        "list.focusBackground": accent + alpha["light"],
        "list.focusForeground": fg,
        "list.highlightForeground": accent,
        "list.hoverBackground": bg_highlight,
        "list.hoverForeground": fg,
        "list.inactiveSelectionBackground": bg_highlight,
        "list.inactiveSelectionForeground": fg,
        "activityBar.background": bg_elevated if bordered else bg,
        "activityBar.foreground": fg,
        "activityBar.inactiveForeground": fg_muted,
        "activityBar.activeBorder": accent,
        "activityBarBadge.background": accent,
        "activityBarBadge.foreground": contrast_fg,
        "sideBar.background": bg if bordered else bg_elevated,
        "sideBar.foreground": fg + alpha["muted"],
        "sideBarTitle.foreground": fg,
        "sideBarSectionHeader.background": bg,
        "sideBarSectionHeader.foreground": fg,
        "sideBarSectionHeader.border": fg_muted + alpha["faint"],
        "tab.activeBackground": bg,
        "tab.activeForeground": fg,
        "tab.inactiveBackground": bg if bordered else bg_elevated,
        "tab.hoverBackground": bg_highlight,
        "tab.hoverForeground": fg,
        "editorGroupHeader.tabsBackground": bg if bordered else bg_elevated,
        "editor.background": bg,
        "editor.foreground": fg,
        "editorLineNumber.foreground": fg_muted + alpha["dimmed"],
        "editorLineNumber.activeForeground": fg,
        "editorCursor.foreground": accent,
        "editorCursor.background": bg,
        "editor.selectionBackground": accent + alpha["medium"],
        "editor.inactiveSelectionBackground": fg_muted + alpha["light"],
        "editor.lineHighlightBackground": fg_muted + alpha["subtle"],
        "editorWhitespace.foreground": fg_muted + alpha["faint"],
        "editorIndentGuide.background1": fg_muted + alpha["faint"],
        "editorIndentGuide.activeBackground1": fg_muted + alpha["medium"],
        "statusBar.background": bg_elevated if bordered else bg,
        "statusBar.foreground": fg,
        "statusBar.border": fg_muted + alpha["faint"],
        "statusBarItem.hoverBackground": bg_highlight,
        "statusBarItem.remoteBackground": accent,
        "statusBarItem.remoteForeground": contrast_fg,
        "terminal.background": bg,
        "terminal.foreground": fg,
        "terminal.ansiBlack": raw_colors[0],
        "terminal.ansiRed": raw_colors[1],
        "terminal.ansiGreen": raw_colors[2],
        "terminal.ansiYellow": raw_colors[3],
        "terminal.ansiBlue": raw_colors[4],
        "terminal.ansiMagenta": raw_colors[5],
        "terminal.ansiCyan": raw_colors[6],
        "terminal.ansiWhite": raw_colors[7],
        "terminal.ansiBrightBlack": raw_colors[8],
        "terminal.ansiBrightRed": raw_colors[9],
        "terminal.ansiBrightGreen": raw_colors[10],
        "terminal.ansiBrightYellow": raw_colors[11],
        "terminal.ansiBrightBlue": raw_colors[12],
        "terminal.ansiBrightMagenta": raw_colors[13],
        "terminal.ansiBrightCyan": raw_colors[14],
        "terminal.ansiBrightWhite": raw_colors[15],
    }

    token_colors = [
        {"settings": {"background": bg, "foreground": fg}},
        {
            "name": "Comment",
            "scope": ["comment", "punctuation.definition.comment"],
            "settings": {"foreground": comment + alpha["solid"], "fontStyle": "italic"},
        },
        {
            "name": "String",
            "scope": ["string", "string.quoted", "string.template"],
            "settings": {"foreground": string},
        },
        {
            "name": "String Escape",
            "scope": ["constant.character.escape", "string.regexp"],
            "settings": {"foreground": type_col},
        },
        {
            "name": "Number",
            "scope": ["constant.numeric"],
            "settings": {"foreground": number},
        },
        {
            "name": "Constant",
            "scope": ["constant", "constant.language"],
            "settings": {"foreground": number},
        },
        {
            "name": "Built-in constant",
            "scope": ["support.constant"],
            "settings": {"foreground": number},
        },
        {
            "name": "Variable",
            "scope": ["variable", "variable.other", "variable.other.readwrite"],
            "settings": {"foreground": var_col},
        },
        {
            "name": "Variable Property",
            "scope": ["variable.other.property", "meta.object-literal.key"],
            "settings": {"foreground": var_col},
        },
        {
            "name": "Variable Constant",
            "scope": ["variable.other.constant"],
            "settings": {"foreground": number},
        },
        {
            "name": "Language Variable",
            "scope": ["variable.language"],
            "settings": {"foreground": var_col, "fontStyle": "italic"},
        },
        {
            "name": "Parameter",
            "scope": ["variable.parameter"],
            "settings": {"foreground": var_col, "fontStyle": "italic"},
        },
        {
            "name": "Keyword",
            "scope": ["keyword", "keyword.control"],
            "settings": {"foreground": keyword},
        },
        {
            "name": "Keyword Operator",
            "scope": ["keyword.operator"],
            "settings": {"foreground": operator},
        },
        {
            "name": "Keyword Other Unit",
            "scope": ["keyword.other.unit"],
            "settings": {"foreground": var_col},
        },
        {
            "name": "Storage",
            "scope": ["storage", "storage.type", "storage.modifier"],
            "settings": {"foreground": keyword},
        },
        {
            "name": "Function",
            "scope": ["entity.name.function", "meta.function-call"],
            "settings": {"foreground": func},
        },
        {
            "name": "Function Call",
            "scope": ["variable.function", "support.function"],
            "settings": {"foreground": func},
        },
        {
            "name": "Support Function",
            "scope": ["support.function.builtin"],
            "settings": {"foreground": type_col},
        },
        {
            "name": "Type",
            "scope": ["entity.name.type", "entity.name.class", "entity.name.namespace"],
            "settings": {"foreground": type_col},
        },
        {
            "name": "Type Primitive",
            "scope": ["support.type.primitive", "support.type.builtin"],
            "settings": {"foreground": type_col},
        },
        {
            "name": "Tag",
            "scope": ["entity.name.tag"],
            "settings": {"foreground": var_col},
        },
        {
            "name": "Tag Punctuation",
            "scope": ["punctuation.definition.tag"],
            "settings": {"foreground": fg_muted},
        },
        {
            "name": "Tag Attribute",
            "scope": ["entity.other.attribute-name"],
            "settings": {"foreground": number, "fontStyle": "italic"},
        },
        {
            "name": "CSS Property",
            "scope": ["support.type.property-name.css", "support.type.vendored.property-name.css"],
            "settings": {"foreground": type_col},
        },
        {
            "name": "JSON Key",
            "scope": ["support.type.property-name.json"],
            "settings": {"foreground": var_col},
        },
        {
            "name": "Diff Inserted",
            "scope": ["markup.inserted"],
            "settings": {"foreground": string},
        },
        {
            "name": "Diff Deleted",
            "scope": ["markup.deleted"],
            "settings": {"foreground": var_col},
        },
        {
            "name": "Diff Changed",
            "scope": ["markup.changed"],
            "settings": {"foreground": number},
        },
    ]

    return {
        "type": theme_type,
        "semanticHighlighting": True,
        "semanticTokenColors": {
            "enumMember": {"foreground": type_col},
            "variable.constant": {"foreground": number},
            "variable.defaultLibrary": {"foreground": type_col},
        },
        "colors": colors,
        "tokenColors": token_colors,
    }


def build_matugen_theme(raw_colors: list[str], bordered: bool = False) -> dict:
    """Build theme using Matugen's template with Node runner or Python fallback."""
    theme = try_node_generation(raw_colors, bordered)
    if theme:
        return theme
    return generate_matugen_theme_python(raw_colors, bordered)
