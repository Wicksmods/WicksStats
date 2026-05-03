# Wick's Stats - Changelog

## 0.2.0 - 2026-05-03

### Buff Impact Preview

A new BUFF IMPACT panel section that lists missing common raid buffs at a glance, with the headline gain you're missing (e.g. Battle Shout +305 ap, Greater Blessing of Wisdom +41 mp5). Hover any row to see the full breakdown.

A gear button in the title bar opens a docked options window where you check which buffs to track. The list auto-seeds from your currently-active buffs the first time you open the addon, so you start with your real loadout. Three quick-action buttons let you re-snapshot, enable all, or clear all.

A "Simulate raid buffs" toggle in the options window adds enabled-but-missing buffs into your displayed stats so you can preview fully-buffed values for gearing decisions. The title bar shows a green [sim] tag while the preview is on.

### Live stat diff

Open the panel and your stats are baselined. Swap a piece of gear and value text colors bright fel-green if it went up, red if it went down. Hover any row for the exact delta.

Default behavior resets the baseline on close. A "Sticky stats" toggle in options keeps the baseline across opens, with a smart auto-refresh if your active buff set has drifted by more than 3 buffs (so a buffed-then-solo reopen does not make every value look like a regression). A "Reset baseline" button forces a fresh snapshot anytime.

### Stat weights

A WEIGHTS panel section shows the top stats ranked by gear-rating weight for your spec. SP = 1.00 baseline for casters and healers, AP = 1.00 for melee and ranged, STA = 1.00 for tanks. Cap-aware: capped stats show 0.00 with a (cap) tag. Spec auto-detects from your talent tree; override with `/wickstats spec <name>`.

### Snapshots

Named stat captures with chat-window diff, via slash commands:

- `/wickstats snap save <name>`
- `/wickstats snap list`
- `/wickstats snap diff <name>`
- `/wickstats snap rm <name>`

### Layout and chrome

- 3-column auto-reflow layout. Width is fixed at 720px and height auto-fits to row count.
- Two-tone "Wick's Stats" title (Wick's fel-green, Stats cream) matching the BIS and CD chrome.
- Options window scrolls when its content exceeds the main panel height.
- Options window locks to the main panel and auto-closes when the panel closes.

### Fixes

- Detect spec by scanning all `GetTalentTabInfo` returns for the spec name, robust to the return-order variation between WoW client versions. Fixes a startup error on Druids.
- `attr()` no longer crashes when `UnitStat` returns nil for the effective stat early in load.
- `ListSnapshots` filters out malformed entries before sorting.

## 0.1.0 - 2026-05-02

Initial release. Detailed character stat panel docked next to the character frame. Sectioned layout with attributes, melee, ranged, spell, defenses, resistances, and regen. Source-aware tooltips show Total / Base+Gear / Buffs / Debuffs breakdowns. Smart per-class display hides irrelevant rows. X-button toggle. Slash commands `/wickstats` and `/wstats`. Wick brand styling.
