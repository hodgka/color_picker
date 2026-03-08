# Color Picker

A native desktop color picker built with [Odin](https://odin-lang.org/) and [Raylib](https://www.raylib.com/). Features a color wheel and square picker, RGB/HSV sliders, hex input, color harmony generation, WCAG contrast checking, color vision deficiency simulation, palette management, and image palette extraction.

![Color Picker screenshot](color_picker_screenshot.png)

## Features

- **Dual picker modes** — color wheel and saturation/value square
- **RGB & HSV sliders** with direct hex input
- **Color harmonies** — analogous, complementary, triadic, split-complementary, square, compound, monochromatic, and shades
- **WCAG contrast checker** — foreground/background slots with AA/AAA ratings for normal and large text
- **Color vision deficiency simulation** — protanopia, deuteranopia, and tritanopia (Machado 2009 model)
- **Eyedropper** — pick any color from your screen (macOS `screencapture`, Linux via `grim`/`scrot`/`import`)
- **Image palette extraction** — extract dominant colors from an image using median cut
- **Palette management** — save, reorder (drag-and-drop), and persist palettes
- **Export** — ASE, GPL (GIMP), CSS custom properties, Tailwind config, JSON, PNG swatch strip, and plain text
- **Color history** — recent picks tracked automatically
- **Shade generation** — configurable shade count and value range
- **Settings persistence** — window position, picker mode, harmony type, and preferences saved to `~/.config/color_picker/settings.json`

## Requirements

- [Odin compiler](https://odin-lang.org/docs/install/)
- Raylib (included with Odin's vendor collection)
- macOS 12+ or Linux

## Building

Build the binary directly:

```sh
odin build . -out:bin/color_picker
```

Or use the bundling script to create a macOS `.app` bundle and `.dmg`:

```sh
./bundle.sh
```

The `ODIN` environment variable can point to your Odin compiler if it isn't at `~/odin/odin`:

```sh
ODIN=/usr/local/bin/odin ./bundle.sh
```

## Installing

After building, run the install script to symlink the CLI command and copy the app bundle to `/Applications`:

```sh
./install.sh
```

This creates:

- `/usr/local/bin/color_picker` — CLI symlink
- `/Applications/Color Picker.app` — app bundle
- `~/Desktop/ColorPicker.dmg` — distributable disk image

## Running

```sh
# From the build directory
./bin/color_picker

# Or after installing
color_picker
```

On macOS you can also launch from Spotlight: **Cmd+Space** and type "Color Picker".

## Running Tests

```sh
odin test .
```

## Project Structure

| File | Purpose |
|---|---|
| `main.odin` | Entry point, main loop, input handling, and UI drawing |
| `app_state.odin` | Application state struct and top-level update helpers |
| `color.odin` | Core color state (HSV/RGB conversion, getters/setters) |
| `draw.odin` | All rendering: picker, sliders, swatches, panels |
| `layout.odin` | Layout constants and geometry |
| `ui.odin` | UI widgets (buttons, sliders, dropdowns, text input) |
| `harmony.odin` | Color harmony computation |
| `shade.odin` | Shade strip generation |
| `contrast.odin` | WCAG relative luminance and contrast ratio |
| `colorblind.odin` | CVD simulation matrices and distinguishability checks |
| `eyedropper.odin` | Screen capture for the eyedropper tool |
| `image_extract.odin` | Median-cut palette extraction from images |
| `hex.odin` | Hex string parsing and formatting |
| `history.odin` | Circular buffer color history |
| `palette.odin` | Palette load/save (JSON) |
| `export.odin` | Palette export (ASE, GPL, CSS, Tailwind, JSON, PNG, TXT) |
| `settings.odin` | Settings persistence (`~/.config/color_picker/`) |
| `wheel.odin` | HSV color wheel image generation |
| `theme.odin` | UI color theme constants |
| `tooltip.odin` | Tooltip state and rendering |
| `bundle.sh` | macOS `.app` bundle and `.dmg` creation |
| `install.sh` | Local installation script |

## License

MIT License. See [LICENSE](LICENSE) for details.

