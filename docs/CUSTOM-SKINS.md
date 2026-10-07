# Custom skins

The main PS1 embeds all presets. JSON files are import examples, not runtime dependencies. Interactive Custom starts from Dark Glass and prompts for each color/number. Non-interactive Custom requires `-SkinFile`.

## Schema version 1

| Property | Type / range | Dark Glass |
| --- | --- | --- |
| SchemaVersion | JSON number, exactly 1 | 1 |
| Name | 1–64 letters/numbers/spaces/underscore/hyphen; starts alphanumeric | Dark Glass |
| Header | `#RRGGBB` | #050C20 |
| HeaderOpacity | numeric 0..1 | 0.88 |
| PanelStart / StartOpacity | `#RRGGBB` / 0..1 | #050C20 / 0.94 |
| PanelMiddle / MiddleOpacity | `#RRGGBB` / 0..1 | #0C1630 / 0.90 |
| PanelEnd / EndOpacity | `#RRGGBB` / 0..1 | #231232 / 0.88 |
| Accent | `#RRGGBB` | #4B91FF |
| Border | `#RRGGBB` | #4391FF |
| Primary | `#RRGGBB` | #FFFFFF |
| SecondaryOpacity / MutedOpacity | numeric 0..1 applied to Primary | 0.72 / 0.55 |
| Blur | numeric 0..60 pixels | 28 |
| Radius | numeric 0..48 pixels | 22 |

All properties are required; unknown properties are refused. Hex colors are normalized in generated CSS. CSS expressions, named colors, arbitrary selectors, URLs, strings in numeric fields, NaN and infinity are rejected. Numeric formatting is invariant across locales. Inputs do not permit raw CSS injection.

Dark Glass uses a 145-degree panel gradient with stops at 0%, 55%, 100%, confirmed through read-only inspection of the existing prototype. The manager uses 150% backdrop saturation and includes blue underline/hover behavior. Header, login and launcher use the configured blur; the existing prototype header was observed at 24px while its panels were 28px. The configurable manager default is 28px consistently. This difference is intentional and still needs live visual review.

Other built-in palettes are new project defaults, not prior validated prototype findings. Light Glass uses dark primary text and higher text opacity. Custom values can create poor contrast; test them with your actual wallpaper, keyboard focus, disabled/error states and browser. Validation checks syntax/range, not visual accessibility certification.

Use `skins/custom-example.json`, change its validated properties and run Install with `-SkinFile`. JSON configuration never supplies logo/wallpaper/favicon/title/text; configure those in RAS Theme.
