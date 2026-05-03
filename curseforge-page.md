# Wick's Stats: CurseForge page content

Update when shipping new versions. Copy/paste into the CurseForge web UI (no API for descriptions).

No em-dashes in shipped copy.

---

## Short summary (CurseForge Summary field, 256-char limit)

> Detailed character stat panel docked next to the character frame. Buff impact preview, simulate-raid-buffs toggle, live gear-swap diffs, per-spec stat weights with cap awareness, and named stat snapshots. Shows what Blizzard hides.

---

## Long description (CurseForge body)

**Wick's Stats** is a detailed character stat panel for TBC Classic Anniversary (2.5.5). It docks beside the character frame and surfaces every stat Blizzard buries or hides altogether.

**NEW in 0.2.0: Buff Impact Preview**

A dedicated BUFF IMPACT panel section lists missing common raid buffs at a glance with the headline gain you're missing. Hover any row for the full breakdown.

A gear button in the title bar opens a docked options window where you tick which buffs to track. The list auto-seeds from your currently-active buffs the first time you use the addon, so you start with your real loadout. Three quick-action buttons let you re-snapshot to current, enable all, or clear all.

A "Simulate raid buffs" toggle adds enabled-but-missing buffs into your displayed stats so you can preview your fully-buffed values for gearing decisions. The title bar shows a green [sim] tag while the preview is on, so you never forget it's active.

**Live stat diff**

Open the panel and your stats are baselined. Swap a piece of gear and value text colors bright fel-green if it went up, red if it went down. Hover any row for the exact delta.

The default behavior resets the baseline on close. A "Sticky stats" toggle keeps it across opens, with a smart auto-refresh if your active buff set drifts by more than 3 buffs (so a buffed-then-solo reopen does not make every value look like a regression). A "Reset baseline" button forces a fresh snapshot anytime.

**Stat weights with cap awareness**

A WEIGHTS panel section shows the top stats ranked by gear-rating weight for your spec. SP = 1.00 baseline for casters and healers, AP = 1.00 for melee and ranged, STA = 1.00 for tanks. Cap-aware: hit rating zeroes past the cap, expertise drops past the dodge cap, defense drops past the uncrittable threshold. Auto-detects your spec from your talent tree.

**What it shows**

Sectioned into a clean three-column layout:

- **Attributes**: Strength, Agility, Stamina, Intellect, Spirit, plus Health and Mana. Hover any attribute for a full Total / Base+Gear / Buffs / Debuffs breakdown.
- **Melee**: Attack Power, Crit, Hit, Expertise (with dodge/parry reduction in the tooltip), Haste, weapon skill MH/OH, attack speed.
- **Ranged**: AP, Crit, Hit, Haste.
- **Spell**: Spell Power with per-school breakdown on hover, Bonus Healing for healers, Spell Crit per school, Hit, Haste, Penetration.
- **Defenses**: Armor (with damage-reduction percent vs. level 73 attackers), Defense, Dodge, Parry, Block, Block Value, Resilience.
- **Resistances**: Holy, Fire, Nature, Frost, Shadow, Arcane.
- **Regen**: MP5 outside and inside the Five-Second Rule.

**Smart per-class display**

Bonus Healing is hidden if you can't heal. Parry and Block are hidden if your class can't use them. Mana and Regen only appear for mana classes. No clutter you don't need.

**Snapshots**

Capture, list, diff, and remove named stat snapshots via slash commands:

- `/wickstats snap save <name>`
- `/wickstats snap list`
- `/wickstats snap diff <name>`
- `/wickstats snap rm <name>`

**UI**

- Three-column layout, 720px wide. Height auto-fits to your row count.
- Auto-shows when you open the character panel, hides when you close it.
- An X in the panel header lets you hide the panel without closing the character pane.
- Wick brand styling: dark purple panel, fel-green corner accents, 1px border, two-tone "Wick's Stats" title.

**Commands**

- `/wickstats` or `/wstats` toggles the panel.
- `/wickstats spec <name>` overrides the auto-detected spec; `/wickstats spec auto` reverts.

**Per-character settings**

All settings (tracked buffs, snapshots, sticky baseline, simulate-raid-buffs toggle) save per character, so each alt has its own loadout.

**Requirements**

TBC Classic Anniversary (2.5.5). Pure Lua, no library dependencies.
