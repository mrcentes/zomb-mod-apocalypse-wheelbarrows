# Wheelbarrow Build 42

This is a focused Build 42 maintenance and enhancement pass for the wheelbarrow mod, with a stable local mod id:

- Workshop ID: `3780565327`
- Mod id: `ApocalypseWheelbarrows`
- Mod name: `Apocalypse Wheelbarrows`
- Available: [Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=3780565327)

Both weight leverage and the skill levels required to craft each wheelbarrow tier are configurable through sandbox settings in a single `Apocalypse Wheelbarrows` settings page.

## What This Is

This mod exists because the original Wheelbarrow mod is great.

We genuinely love the original mod's idea, feel, and utility. The goal here is not to replace it with something different, but to keep it alive and usable in Build 42 while staying as respectful as possible to the original work.

Massive credit to the [original author](https://steamcommunity.com/sharedfiles/filedetails/?id=2926995676).

If the original author reaches out and asks for this to be taken down, it will be taken down.

## Why The Capacity Works Differently

Build 42 appears to clamp bag-style containers in ways that make the old large-capacity wheelbarrow behavior unreliable. In local testing, the wheelbarrow could show a higher number briefly, but still behave like it had a much smaller effective limit. There is also a hard `50` bag-side cap in the current item script setup that matches the Build 42 behavior we observed.

Instead of fighting that directly, this mod now uses a leverage approach:

- the wheelbarrow item itself remains a normal container
- items placed into it have their live weight reduced while inside it
- when items leave the wheelbarrow, their original weight is restored
- the original per-item weight metadata is cleared when it is no longer needed

This preserves the core fantasy of a wheelbarrow helping you move heavy stuff without pretending the Build 42 container cap is gone.

## Features

- Fixed the equipped-drop crash path for wheelbarrows in Build 42.
- Added three wheelbarrow variants:
  - `Wooden`
  - `Reinforced`
  - `Metal`
- Added per-variant world models, held models, icons, and textures.
- Added per-variant leverage settings for single-player and multiplayer servers.
- Added Build 42 JSON-based localization support.
- Added a shared logger for clearer diagnostics.

## Wheelbarrow Types

- `Wooden Wheelbarrow`
  baseline version
- `Reinforced Wheelbarrow`
  reinforced mid-tier version
- `Metal Wheelbarrow`
  highest-tier version

## Settings

In the sandbox UI, the mod uses one `Apocalypse Wheelbarrows` settings page. Because Build 42 custom sandbox options do not expose the same section-header support the hardcoded vanilla tabs use, the settings are grouped by name and kept in a fixed order by wheelbarrow type.

The page is ordered as:

- one leverage setting
- the recipe skill requirement settings for that wheelbarrow tier

### Wooden Wheelbarrow

- `Wooden Wheelbarrow Advantage`
  Default: `4`
- `Wooden Wheelbarrow Woodwork`
  Default: `Woodwork 2`

### Reinforced Wheelbarrow

- `Reinforced Wheelbarrow Advantage`
  Default: `6`
- `Reinforced Wheelbarrow Woodwork`
  Default: `Woodwork 4`
- `Reinforced Wheelbarrow Mechanics`
  Default: `Mechanics 2`

### Metal Wheelbarrow

- `Metal Wheelbarrow Advantage`
  Default: `8`
- `Metal Wheelbarrow Mechanics`
  Default: `Mechanics 4`
- `Metal Wheelbarrow Metal Welding`
  Default: `Metal Welding 4`

Higher leverage values mean more mechanical advantage.

Setting a recipe skill requirement to `0` removes that specific requirement entirely.

Single-player:

- set these through the save's sandbox settings before loading the save

Multiplayer:

- set these through the server sandbox settings
- the server values are authoritative for all players

## Localization

Build 42 localization support now lives here:

- `mods/ApocalypseWheelbarrows/42/media/lua/shared/Translate/EN/ItemName.json`
- `mods/ApocalypseWheelbarrows/42/media/lua/shared/Translate/EN/Recipes.json`
- `mods/ApocalypseWheelbarrows/42/media/lua/shared/Translate/EN/IG_UI.json`
- `mods/ApocalypseWheelbarrows/42/media/lua/shared/translate/en/sandbox.json`

Current localized content includes:

- item names
- recipe names
- wheelbarrow UI/context menu labels
- wheelbarrow leverage option labels and descriptions

## Confirmed Fixes

### Issue 1: dropping an equipped wheelbarrow could crash

- Symptom:
  `attempted index: getActualWeight of non-table: null`
- Cause:
  the custom wheelbarrow drop path could route an equipped wheelbarrow into a bad vanilla drop action path
- Remediation:
  the custom drop action now unequips the wheelbarrow if needed, then transfers it safely to the floor
- Status:
  confirmed working in local Build 42 testing

### Issue 2: Build 42 capacity handling

- Symptom:
  the wheelbarrow did not behave like a true high-capacity container in Build 42
- Remediation:
  moved to a leverage-based weight-reduction model instead of trying to force legacy raw capacity behavior
- Status:
  working locally and now configurable per wheelbarrow type

## Art And Model Help Wanted

The current three-variant setup works, but we would love help from someone who knows the Blender side of Project Zomboid modding.

If you know how to improve:

- wheelbarrow meshes
- held/equipped presentation
- textures and material polish
- variant-specific visual detail

please reach out or contribute. Better models and better texture work would make this mod substantially stronger.

## Notes

- This mod is now structured as a Build 42-only package.
- The logger lives at:
  `mods/ApocalypseWheelbarrows/42/media/lua/shared/Wheelbarrow/WheelbarrowLogger.lua` and can be used to change the logLevel.
- Some recipe/material choices are still pragmatic placeholders chosen to get the three variants working cleanly in Build 42.
