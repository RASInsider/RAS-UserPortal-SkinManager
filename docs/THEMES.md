# Theme catalog — 0.1.1-dev

Independent community presentation presets. Neither the presets nor their names imply vendor endorsement. RAS continues to supply the logo, wallpaper, favicon, title and text. No product JS/CSS bundle or branding asset is replaced.

## Built-in choices

| Menu | Preset | Panel gradient: start → middle → end | Accent | Primary text |
| --- | --- | --- | --- | --- |
| 1 | Dark Glass | `#050C20` → `#0C1630` → `#231232` | `#4B91FF` | `#FFFFFF` |
| 2 | Midnight Blue | `#091B36` → `#102D50` → `#152943` | `#70B8FF` | `#FFFFFF` |
| 3 | Light Glass | `#FFFFFF` → `#EFF5FF` → `#E7EFFF` | `#175EBA` | `#15243A` |
| 4 | RASInsider | `#090F20` → `#122346` → `#201C43` | `#7BAEFF` | `#FFFFFF` |
| 5 | Custom | User-supplied; starts from Dark Glass | User-supplied | User-supplied |
| 6 | Graphite | `#181B20` → `#22262D` → `#292E36` | `#54C6BE` | `#F4F6F8` |
| 7 | Forest | `#10241F` → `#19332B` → `#203C33` | `#99C7AC` | `#F0F7F3` |
| 8 | Warm Ivory | `#FAF8F3` → `#F4F0E8` → `#EDE7DC` | `#805B35` | `#302C27` |
| 9 | Bordeaux | `#21191D` → `#2D2027` → `#39252E` | `#D6A2B4` | `#FAF2F5` |
| 10 | Aubergine | `#322646` → `#443458` → `#594471` | `#D3B8ED` | `#FAF5FF` |
| 11 | Liquid Glass | `#FFFFFF` → `#EDF4FC` → `#F4F7FC` | `#0065D0` | `#17283D` |
| 12 | Ruby | `#1B171B` → `#302026` → `#541F2C` | `#FF4053` | `#FFF7F8` |

Silver was discarded during design review because it was too close to Warm Ivory. Aubergine replaces it. The red preset's final name is **Ruby**.

## New preset details

| Preset | Header | Border | Header / panel opacity | Secondary / muted text opacity | Blur / radius |
| --- | --- | --- | --- | --- | --- |
| Graphite | `#181B20` | `#4B535F` | 0.96 / 0.96, 0.96, 0.96 | 0.78 / 0.68 | 28px / 22px |
| Forest | `#10241F` | `#567769` | 0.96 / 0.96, 0.96, 0.96 | 0.78 / 0.68 | 28px / 22px |
| Warm Ivory | `#FAF8F3` | `#C9BCA8` | 0.96 / 0.96, 0.96, 0.96 | 0.85 / 0.78 | 28px / 22px |
| Bordeaux | `#21191D` | `#7B5968` | 0.96 / 0.96, 0.96, 0.96 | 0.78 / 0.68 | 28px / 22px |
| Aubergine | `#292036` | `#9276AE` | 0.96 / 0.96, 0.96, 0.96 | 0.82 / 0.68 | 28px / 22px |
| Liquid Glass | `#EEF4FC` | `#FFFFFF` | 0.78 / 0.70, 0.64, 0.58 | 0.80 / 0.76 | 36px / 30px |
| Ruby | `#171316` | `#AD4051` | 0.96 / 0.96, 0.94, 0.92 | 0.78 / 0.68 | 28px / 22px |

Panel stops remain 0%, 55%, 100% at 145 degrees. Header/login/launcher use the configured blur with 150% saturation. Borders use the existing panel/launcher alpha multipliers; hover uses accent at 0.18 opacity.

Liquid Glass adds scoped inset highlights to the login panel/launcher/header and a 24px search radius with a pale translucent search surface. Its styling is selected by the saved skin name `Liquid Glass`, so a JSON import retaining that name receives the same treatment; renaming it produces the ordinary glass template. This is a CSS approximation, not Apple's native Liquid Glass rendering engine. The existing backdrop-filter fallback uses the solid panel-start color.

## Usage

```powershell
# Preview a rollout to all API-discovered Gateways.
.\RAS-UserPortal-SkinManager.ps1 -Action Install -LicensingServer ras-license.example.test `
  -AllSites -Preset 'Ruby' -MappingValidated -WhatIf

# After reviewing scope, mapping and pre-flight prerequisites.
.\RAS-UserPortal-SkinManager.ps1 -Action Install -LicensingServer ras-license.example.test `
  -AllSites -Preset 'Liquid Glass' -MappingValidated
```

Use Install/Change to select a different preset. Re-apply uses saved per-Gateway settings. State/configuration, hashes, transaction backups and recovery continue to use the existing ProgramData locations. The script is standalone; JSON files are optional examples.

## Validation limits

The palettes were approved through illustrative previews with simplified backgrounds. Those previews are not screenshots of all themes running in RAS. The new presets have not been deployed to the live lab by this update. Review actual wallpaper contrast, sign-in/launcher, active/hover/focus/error/disabled states, responsive layouts and browser backdrop-filter support before rollout. In particular, Liquid Glass transparency depends strongly on the RAS-supplied wallpaper.

Original presets are unchanged. The v0.1.0 tag/archive is unchanged; the theme expansion is development source 0.1.1-dev.
