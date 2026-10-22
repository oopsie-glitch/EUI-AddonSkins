# 1.2.0 development history

> Historical development snapshot. Versions, branch status and validation counts describe that snapshot; use [the engineering guide](../../ENGINEERING.md) and [release procedure](../../RELEASING.md) for current work.

## 1.2.0-alpha.15 — Details plugin menu refresh (untagged)

- Avoid the obsolete CoolTip injection path after switching raid plugins.
- Refresh the active native attribute menu through its existing handler; close safely if no handler exists.
- Preserve callback arguments, return values and popup ownership.

## 1.2.0-alpha.14 — Details toolbar and plugin menus (untagged)

- Anchor header controls independently and clear custom anchors before restoring native layouts.
- Release the custom layout before Details resets its window skin.
- Correct the receiver passed to native raid-plugin menu callbacks, including Compare and Vanguard.

## 1.2.0-alpha.13 — Details restoration guard (untagged)

- Restore saved appearance settings without resetting a Details window that does not exist.
- Cover unbuilt and closed instances when toggling meter styling.

## 1.2.0-alpha.12 — Details quick controls and Tiny Threat (untagged)

- Add EUI AddonSkins controls to Details' settings pop-out.
- Separate Details meter and Tiny Threat styling, with independent restoration.
- Retain native Tiny Threat values, colours and actions through row refreshes.

## 1.2.0-alpha.11 — ThreatClassic2 menu toggles (untagged)

- Reapply EUI menu fonts after Lock and Test Mode rebuild their checkbox entries.
- Use scoped menu initializers without duplicating callbacks or replacing native actions.

## 1.2.0-alpha.10 — ThreatClassic2 menu reuse (untagged)

- Use supported font objects for Blizzard compositor menus; avoid forbidden SetFont calls.
- Use renderer-managed menu backgrounds instead of persistent child frames.
- Preserve menu contents and actions through repeated reopening and pooled reuse.

## 1.2.0-alpha.9 — ThreatClassic2 (untagged)

- Reintroduced ThreatClassic2 with the shared Details-style meter palette, fonts and bar texture.
- Added a matching header menu icon and styled context menus and Ace options.
- Preserved native threat colours, values, columns, row geometry and window controls.

## 1.2.0-alpha.8 — Details input spacing and Designer (untagged)

- Preserve native text-field geometry so backgrounds do not overlap descriptions.
- Populate the lazy Designer list once and style object controls and pooled labels immediately after native refreshes.

## 1.2.0-alpha.7 — Details options navigation (untagged)

- Keep options categories consistently styled as EUI tabs through native template resets.
- Update category selection and lazy controls synchronously after page changes.
- Prevent native labels and category markers from overlapping EUI navigation.

## 1.2.0-alpha.6 — Details pop-out menus (untagged)

- Apply flat EUI backgrounds, soft borders, accent hover fills and subtle separators to Details pop-out menus and submenus.
- Prevent native rounded backgrounds from covering the menu skin.
- Preserve warning icons and actions; restore native artwork when shared menus change owners.

## 1.2.0-alpha.5 — Details startup icon sizing (untagged)

- Keep header artwork at its EUI size independently of native button dimensions.
- Reapply button geometry after native size-change events, without opening options.

## 1.2.0-alpha.4 — Details header icons (untagged)

- Keep toolbar icons visible independently of Details native button fades.
- Keep icons synchronized with native button visibility and retain native actions.

## 1.2.0-alpha.3 — Details meter layout (untagged)

- Added an independent dark header with EUI title styling and a segment combat timer.
- Aligned native toolbar controls and reused installed EUI meter icons where available.
- Combined total and DPS/HPS through Details native formatting; aligned the value column.
- Removed native header art and footer labels/grip artwork while retaining their actions.
- Restores original formatting and control positions when meter matching is disabled.

## 1.2.0-alpha.2 — Details controls (untagged)

- Added independent menus/options and meter-appearance switches under Settings > AddOns > EUI AddonSkins: Details (`/euidetails`).
- Made meter matching opt-in and added restoration of its captured visual settings.
- Kept meter positions, sizes, groups, data and interactions under Details control.

## 1.2.0-alpha — Details preview (untagged)

- Added an experimental Details! skin for meter windows, bars, options, breakdown/report windows and menus.
- Matches available EUI damage-meter font, bar texture, height, spacing and background settings.
- Preserves combat data, class colours, icons, window positions and native actions.
- Development build only; no CurseForge release tag.

