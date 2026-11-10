# Spy Forever — Concept A composition

Draft PR #77, based on released v1.6.5. The prior build is functionally stable,
but its visual appearance is **not approved**. The Concept A image is the visual
target. This redesign is awaiting real WoW screenshots; tests do not approve it.
All repository operations/testing/packaging use GitHub cloud APIs and Actions.

[Reference comparison recorded before runtime edits](SPY_CONCEPT_A_REDESIGN.md).
[Performance comparison and limits](SPY_FOREVER_PERFORMANCE.md).

## Composition and proportions

The public EllesmereUI Heavy Bronze window rim (when supported) encloses a shaded seven-unit
bronze bezel, a distinct warm header material and a separately recessed list well.
This is a surface/layout redesign, not additional thin rules around the old bars.

The list well starts seven units inside each side, at native y=-32, and ends
three units below the native window's bottom. The cosmetic outer rim extends
nine units below it; this gives the final native row a bottom recess without
changing row budgets, clipping flags or saved height. The normal cosmetic top
starts at the native top instead of seven units below it. The visual envelope is
moderately taller, while native width/height, drag/resize functions and saved
profile dimensions remain unchanged. Decorative gutter art takes no mouse input.

The inner well uses the shared textured chamfered rim with subdued bronze tint
and three-unit inward shadow gradients. Seven-unit side gutters have directional
bronze light/dark gradients; their bottom segment does not overlap either side.
The main rim uses native UI-Frame-Metal artwork through the public Heavy API,
without its opaque native title-band fill. Older EUI builds retain the textured
chamfered fallback. This creates a physical bezel and a visibly separate panel rather than a thin
extra outline. No new artwork asset or copied addon art is bundled.

## Header and typography

At ordinary widths (180+), native title, controls and count remain on one line.
The title is inset 12 units and controls/count stay toward the right, retaining
order, size, padding, actions, hitboxes, tooltips and state art. The title gains a
minimum 14-unit font size using the current EUI font family/flags; larger configured
EUI typography is retained. Standard/disable restore the current framework font,
not a stale font snapshot after appearance changes.

A dedicated bronze header gradient/grain ends where the list begins. The upper
gradient and existing rim provide restrained highlight; a two-unit copper rule
and two-unit dark ledge make the lower divider substantial. There is no separate
normal-width toolbar row or decorative button. Existing helper black boxes stay
suppressed only in Forever.

Where GetResizeBounds/SetResizeBounds expose valid restorable limits, Forever
raises the resize floor toward 180 units, **never above current width**. It
never calls SetWidth/SetHeight on the native main window or writes Spy's saved
dimensions. Original limits restore in Standard/disable. Missing/unknown bounds
APIs leave native sizing unchanged. Existing custom widths below 180 are
preserved and can be widened; once widened, future resizing uses the new floor.

Five unchanged button hitboxes plus title/counter cannot fit at legacy 90-unit
width. The existing compact emergency reflow is retained only for such saved
tiny widths, avoiding forced resizing or lost native functions. This is a
compatibility compromise: it is not the intended Concept A presentation. At
normal widths the header is one horizontal band. Roughly 280+ units is recommended
for the full long/localized title; native text truncates at tighter widths.

Body font size, row height/spacing and list density remain under Spy's native
settings. Widen the window or increase its native row-height/font setting for
more of the reference's breathing room; no profile preferences are overwritten.

## Rows and native texture ownership

Each visual row sits inside the panel: chrome is nine units inward from the
secure row edges, and the native fill ten units inward, with one-unit vertical
clearance. One reusable full-surface gradient replaces its two short edge strips. Warm
upper lighting (alpha 0.16) transitions into a controlled dark lower shade
(alpha 0.28). This gives broad matte curvature and controlled muting while Spy's
chosen texture remains visible, with no overlapping pair of row glazes.
Fine existing copper edges and genuine hover emphasis complete the surface.

There is **one fewer texture per row, no new per-row frames or hooks**. No full opaque plate replaces
the native bar and no class/status RGB, status value, texture path or region
alpha is overwritten. Decorative material layers are distinct from Spy's fill
opacity, like the existing edge chrome. Their modest coverage is intentionally
part of the Forever material, not a replacement texture selector.

Right metadata is anchored four units inside the visual bar. Native name text
is anchored four units inside the left edge and six units before metadata.
These constraints use normal FontString truncation, not parsed/custom names.
Spy's SetBar still runs unmodified and keeps its native width/text writes;
dual anchors constrain the visual width without a hot-path hook. Right-aligned
metadata and usable name width update through native geometry.

The secure row's original anchor, size, macro/click actions and pool identity
stay untouched. Original bar/label anchors are captured and restored for
Standard/disable, retirement and slot transfer. Rows/columns never move on every
player paint; no texture/RGB hook or hierarchy scan is added to SetBar.

## Opacity and ownership

Header and list have **separate, non-overlapping** background surfaces. Both use
the RestedXP-style neutral white plate + warm gradient and grain alpha budget:
at target t, grain alpha is 0.12t and plate alpha is (t-0.12t)/(1-0.12t).
Their effective region background is exactly t, including default 75%, saved
0/100 and Reset. Gutter materials use the same target. Fixed rim/divider/shadow
edges are cosmetic border lighting, not stacked full-area fills.

The main native background and released Standard shell are excluded in Forever.
Slider changes affect background materials only, never parent alpha, text, buttons
or native class fills. At 0 the full-area surfaces are hidden; borders and row
chrome remain readable. Spy's whole-window fading remains independent.

The list plate/grain and mask belong to the unregistered well host; header
materials belong to the unregistered header host. Secure rows are excluded from
generic EUI texture cleanup. Existing native bar/text remain outside filled
sibling overlays. Art has no mouse/motion input, no global scans and no polling.

## Lifecycle and supported surfaces

The existing **single secure posthook on Spy:ShowTooltip** dispatches only current
owned rows. Forks missing that method retain the existing scoped fallback.
Native OnEnter/OnLeave scripts, tooltips, additive highlight and targeting remain.
No persistent selection/threat state is invented.

Nearby, Last Hour, Ignore and KOS share the redesigned main panel. Native unknown
metadata and warning/class/status colours stay meaningful. Statistics, alerts/
Watch severity, menus/reason dialogs and native settings retain their prior skin
treatment; they are not enlarged to imitate the mockup. EUI AddonSkins submenu,
Automatic/Standard/Forever, /euispy, opacity persistence and Reset are unchanged.

Acquisition/slot replacement reuse art; retired callbacks cannot repaint a new
owner. Hide/show, native resize, title/count updates and theme changes use existing
boundaries. Combat defers geometry/material changes to existing recovery. The
main native rows already defer protected show/hide in ManageBarsDisplayed.
Warm updates allocate no new art or hooks. See the comparison for nonzero cold,
theme, row-transfer and changed-opacity costs.

## Deliberate compromises and screenshot checklist

Concept A's lighting, bezel, inset panel and broad row surfaces are implemented.
Its oversized typography, extra heading row, class icons, exact pixel dimensions,
heavy glow and implied sticky selection are not copied. The native texture can
vary with the user's chosen texture; do not claim pixel identity to the mockup.

1. Install the commit-labelled ZIP with existing SavedVariables. Capture **Nearby
   and KOS at normal and wide widths**, including short and long titles. Use
   normal UI scale and bright/dark scenery. Judge the substantial bezel, single
   normal header, separate recessed panel and broad row depth against Concept A.
2. Include all five class examples plus unknown/status entries, partial/empty
   fills, long names and metadata. Text must stay readable without column overlap.
3. Change Spy's own texture/colours/opacity, row height/font and window size.
   Check clipping, final-row clearance, native row ordering and full-name tooltips.
4. Hover/leave, target/modifier click, hide/reopen, mode switch and recycle rows.
   Native buttons/tooltips/states and hover clearing must work.
5. Cycle Automatic/Standard/Forever and native EUI font changes. Standard must
   restore anchors/fonts/resize limits with no leftover art or saved-size changes.
6. Save/reload background 0%, 75%, 100%, then Reset. Header/list transparency must
   match, controls stay readable and whole-window fading remain native.
7. Test combat changes/recovery, EUI cleanup and a long session. Watch for taint,
   retained/stale art, clipping, footer overdraw and unintended resize persistence.

The maintainer decides visual acceptance after these WoW screenshots. Mock UI
counts/timing cannot prove rendering, secure hit-testing, FPS, native/GPU memory,
taint freedom or behavior in every Spy fork/client. No merge/version/tag or
publication is authorized.
