# Altoholic development alpha

Version: `1.2.1-alpha.2`, based on stable `v1.2.0` (`b8e0125`). Source is kept on the untagged `development` branch. Do not create a tag or GitHub Release until publication is requested. Ordinary branch pushes publish to neither CurseForge nor Wago.

AddonFactory stores scrollbar border textures on the parent ScrollFrame. The Altoholic adapter now fades those named decorative textures and uses an 8 × 18 vertical thumb with full texture coordinates. Slider hit areas, anchors, values, ranges, mouse-wheel handling and native arrow actions remain unchanged.

Altoholic creates twelve summary cells, but `DrawRealmLine` hides only cells 2–10. The adapter hides cells 11–12 on realm rows, including initial scans and subsequent row redraws. Character rows retain access to all cells. No upstream files are modified.

Run `python3 scripts/package.py` for all regression suites and installation ZIP validation. Tests cover native scrollbar art, thumb dimensions, preserved arrow actions/ranges/anchors, realm-to-character row reuse, repeat refreshes, combat deferral and disabled integrations. Actual in-game appearance has not been verified.

AddonFactory rebuilds category atlas textures and font objects during navigation. Scoped post-hooks on its category setters and owned list updates restore EUI styling synchronously, including new pooled buttons. Native data, callbacks, labels, submenu indentation and visibility remain unchanged. Regression tests cover all three category depths, selection changes, warm refreshes, late buttons, theme changes and disabled styling.
