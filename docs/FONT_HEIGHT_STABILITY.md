# Shared font-height stability investigation

Baseline: published v1.6.7, commit 3553aca8e386c77be2c1af20a719117c14199df2. No release metadata is changed.

## Failure path and uncertainty

RefreshControlsNow calls H.Safe(H.Scan, ...). Scoped Visit sends each owned FontString through H.Font, and the initial H.Scan region pass also called S.Font directly. Neither shared path validated the native height returned by GetFont.

The public EUI Font facade forwards to WSkin.Font. In pinned EllesmereUI d84a1e19d0b63a9a944dd8023e436290a1b7a173, WindowEngine.lua captures cur from GetFont, checks secrecy, primes the shadow FontObject and calls SetFont(Theme.fontPath, size or cur or 12, ...). Lua zero is truthy: cur=0 survives that fallback and reaches SetFont unchanged. Shadow priming precedes the invalid call, so validation must precede delegation, not catch its exception.

A strict native-setter fixture runs the actual pinned public facade, WSkin.Font and PrimeFontShadow against the released shared scanner. It does not identify the production FontString, explain why its native metric was zero, or establish the user's installed EUI build. Taint context identifies execution context, not fault ownership. This is an unvalidated shared input interacting with the font API; the originating integration remains unknown.

Published direct RefreshControlsNow callers are Altoholic, DBM, Details, Gargul, Guildy, ItemRack and Myslot. Queued control refreshes are shared by scoped adapters. All 55 released runtime Lua files were reviewed for helper calls. PR #92 and its native prototype are excluded.

## Correction and ownership

IsValidFontHeight accepts only non-secret, numeric, positive, finite heights, checking secrecy before comparisons. Zero, negative, NaN, infinities, strings, false, nil and secret heights are left untouched.

H.Font validates before calling S.Font. Initial H.Scan region styling uses that boundary. The existing scoped color/custom-font proxy validates before dispatching custom font code. Multiline EditBox styling now requires a valid native size instead of using a guessed fallback. CreateFontOverride rejects invalid current/cached sizes and secret tuples before caching/comparing/restoring them; KiwiFarm is its released caller.

Valid fractional and ordinary sizes, flags, colors and restoration semantics remain unchanged. Initializing/inherited text stays native; an existing later refresh can style its now-valid metric. No size clamp, global FontObject modification, new pcall, event, timer, hook or scan is added. EUI is not patched. Addon-specific writers outside these boundaries are not globally intercepted.

H.Safe and its deduplicated error reporting remain unchanged. A skipped input does not call the unsafe setter or prime shadow artwork.

## Verification and limits

Coverage includes activation, RefreshControlsNow, first generic scan, custom callbacks, multiline text, positive/fractional and invalid/secret/nil metrics, later valid metrics, colors, concrete override/restoration, missing secret API, combat/disabled routes and 1,000 warm invalid refreshes. CI must show that restoring Widgets.lua and Scoped.lua from the exact release fails the zero-height assertion, then rerun the corrected files. Identical five-trial valid-font workloads compare time, writes, object/hooks and retained memory.

The full suite and package validation cover Retail/Forever manifests and existing integrations. Pinned EUI sources remain in the hosted runner and outside the runtime ZIP. Hosted timing/mocks cannot prove WoW FPS, rendering or taint safety.

For live acceptance, open/reopen addon options and dynamic pages, scroll pooled entries, change fonts/theme and test combat recovery. If installed, toggle KiwiFarm EUI fonts on/off. Confirm no zero-height error, changed native size, blocked action or restoration issue.

Candidate for the next stability release once tests and live acceptance pass; v1.6.8 remains provisional. No merge, tag, version bump or publication is authorized.
