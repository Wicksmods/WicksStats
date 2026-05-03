-- Wick's Stats
-- Weights.lua: per-spec stat weights and caps
--
-- Weights are gear-rating units, normalized so the "primary" stat = 1.00.
-- For casters: spell power = 1.00 baseline.
-- For healers: bonus healing = 1.00 baseline.
-- For melee/ranged: 1 attack power = 1.00 baseline.
-- For tanks: stamina = 1.00 baseline (effective health priority).
--
-- Sources: Elitist Jerks TBC compendium, Wowhead 2.4.3 class guides, common
-- T6-era theorycraft. Numbers are approximations for PvE single-target raid.
-- The cap-awareness layer in Caps.lua applies the most important runtime
-- adjustments (hit cap, expertise dodge cap, defense uncrittable).

local WS = WicksStats
WS.WEIGHTS = WS.WEIGHTS or {}

-- Stat keys used in weight tables (must match WS.stats fields where possible):
--   sp           = spell power (max of school)
--   healing      = bonus healing
--   int, spi, sta, str, agi
--   mp5          = mp5 outside FSR
--   ap, rap      = melee/ranged attack power
--   hitRating    = melee hit rating (below cap)
--   rhitRating   = ranged hit rating
--   shitRating   = spell hit rating
--   critRating   = melee crit rating
--   rcritRating  = ranged crit rating
--   scritRating  = spell crit rating
--   hasteRating  = melee haste rating
--   rhasteRating = ranged haste rating
--   shasteRating = spell haste rating
--   expRating    = expertise rating
--   armor, defRating, dodgeRating, parryRating, blockRating, blockValue, resilienceRating

WS.WEIGHTS.WARRIOR = {
    Arms = {
        primary = "ap",
        ap = 1.00, str = 1.00, agi = 0.40,
        hitRating = 1.15, critRating = 1.05, hasteRating = 0.45,
        expRating = 0.90,
    },
    Fury = {
        primary = "ap",
        ap = 1.00, str = 1.00, agi = 0.40,
        hitRating = 1.20, critRating = 0.95, hasteRating = 0.60,
        expRating = 0.95,
    },
    Protection = {
        primary = "sta",
        sta = 1.00, armor = 0.55, str = 0.55, ap = 0.40,
        defRating = 1.40, dodgeRating = 0.90, parryRating = 0.85,
        blockRating = 0.70, blockValue = 0.80,
        hitRating = 1.30, expRating = 1.10, critRating = 0.50,
    },
}

WS.WEIGHTS.PALADIN = {
    Holy = {
        primary = "healing",
        healing = 1.00, int = 0.55, spi = 0.10, mp5 = 1.20,
        scritRating = 0.50, shasteRating = 0.45,
    },
    Protection = {
        primary = "sta",
        sta = 1.30, armor = 0.50, str = 0.55, ap = 0.30,
        defRating = 1.50, dodgeRating = 0.85, parryRating = 0.80,
        blockRating = 0.75, blockValue = 0.95,
        sp = 0.50, int = 0.30, hitRating = 1.20, expRating = 1.05,
    },
    Retribution = {
        primary = "ap",
        ap = 1.00, str = 1.00, agi = 0.30, int = 0.30,
        hitRating = 1.10, critRating = 0.95, hasteRating = 0.40,
        expRating = 0.85,
    },
}

WS.WEIGHTS.HUNTER = {
    BeastMastery = {
        primary = "rap",
        rap = 1.00, agi = 1.20, int = 0.10,
        rhitRating = 1.50, rcritRating = 0.75, rhasteRating = 0.45,
    },
    Marksmanship = {
        primary = "rap",
        rap = 1.00, agi = 1.30, int = 0.10,
        rhitRating = 1.60, rcritRating = 0.85, rhasteRating = 0.55,
    },
    Survival = {
        primary = "rap",
        rap = 1.00, agi = 1.40, int = 0.10,
        rhitRating = 1.55, rcritRating = 0.70, rhasteRating = 0.40,
    },
}

WS.WEIGHTS.ROGUE = {
    Assassination = {
        primary = "ap",
        ap = 1.00, agi = 1.05, str = 1.00,
        hitRating = 1.35, critRating = 0.95, hasteRating = 0.60,
        expRating = 1.20,
    },
    Combat = {
        primary = "ap",
        ap = 1.00, agi = 1.10, str = 1.00,
        hitRating = 1.30, critRating = 0.85, hasteRating = 0.55,
        expRating = 1.40,
    },
    Subtlety = {
        primary = "ap",
        ap = 1.00, agi = 1.15, str = 1.00,
        hitRating = 1.40, critRating = 1.00, hasteRating = 0.55,
        expRating = 1.10,
    },
}

WS.WEIGHTS.PRIEST = {
    Discipline = {
        primary = "healing",
        healing = 1.00, int = 0.50, spi = 0.30, mp5 = 1.00,
        scritRating = 0.85, shasteRating = 0.65,
    },
    Holy = {
        primary = "healing",
        healing = 1.00, int = 0.40, spi = 0.65, mp5 = 1.10,
        scritRating = 0.55, shasteRating = 0.45,
    },
    Shadow = {
        primary = "sp",
        sp = 1.00, int = 0.30, spi = 0.10,
        shitRating = 1.55, scritRating = 0.70, shasteRating = 1.05,
    },
}

WS.WEIGHTS.DRUID = {
    Balance = {
        primary = "sp",
        sp = 1.00, int = 0.30, spi = 0.10,
        shitRating = 1.40, scritRating = 0.85, shasteRating = 0.90,
    },
    -- Druid Feral splits into Cat (DPS) and Bear (Tank). Auto-detection picks
    -- "Feral_Cat" by default; user can switch to "Feral_Bear".
    Feral_Cat = {
        primary = "ap",
        ap = 1.00, str = 1.00, agi = 1.10,
        hitRating = 1.20, critRating = 0.60, hasteRating = 0.50,
        expRating = 0.55,
    },
    Feral_Bear = {
        primary = "sta",
        sta = 1.00, armor = 0.40, agi = 0.70, str = 0.30,
        defRating = 1.50, dodgeRating = 1.00,
        hitRating = 0.80, expRating = 0.85, ap = 0.30,
    },
    Restoration = {
        primary = "healing",
        healing = 1.00, int = 0.40, spi = 0.30, mp5 = 1.05,
        scritRating = 0.30, shasteRating = 0.65,
    },
}

WS.WEIGHTS.SHAMAN = {
    Elemental = {
        primary = "sp",
        sp = 1.00, int = 0.30, spi = 0.10,
        shitRating = 1.40, scritRating = 0.75, shasteRating = 0.85,
    },
    Enhancement = {
        primary = "ap",
        ap = 1.00, str = 1.00, agi = 1.45, int = 0.20,
        hitRating = 1.30, critRating = 0.80, hasteRating = 0.55,
        expRating = 0.85,
    },
    Restoration = {
        primary = "healing",
        healing = 1.00, int = 0.35, spi = 0.10, mp5 = 1.30,
        scritRating = 0.65, shasteRating = 1.00,
    },
}

WS.WEIGHTS.MAGE = {
    Arcane = {
        primary = "sp",
        sp = 1.00, int = 0.40, mp5 = 0.30,
        shitRating = 1.40, scritRating = 0.85, shasteRating = 0.95,
    },
    Fire = {
        primary = "sp",
        sp = 1.00, int = 0.30,
        shitRating = 1.40, scritRating = 1.20, shasteRating = 0.85,
    },
    Frost = {
        primary = "sp",
        sp = 1.00, int = 0.30, mp5 = 0.20,
        shitRating = 1.45, scritRating = 0.84, shasteRating = 0.83,
    },
}

WS.WEIGHTS.WARLOCK = {
    Affliction = {
        primary = "sp",
        sp = 1.00, int = 0.20, sta = 0.05,
        shitRating = 1.50, scritRating = 0.45, shasteRating = 0.95,
    },
    Demonology = {
        primary = "sp",
        sp = 1.00, int = 0.20, sta = 0.10,
        shitRating = 1.45, scritRating = 0.65, shasteRating = 1.00,
    },
    Destruction = {
        primary = "sp",
        sp = 1.00, int = 0.20, sta = 0.10,
        shitRating = 1.55, scritRating = 0.85, shasteRating = 0.86,
    },
}

-- ============================================================================
-- Caps (TBC, level 70 player vs. level 73 raid boss target)
-- ============================================================================
WS.CAPS = {
    -- Hit
    meleeHitRating_special     = 142,  -- ~9% (yellow swing cap on lvl 73)
    meleeHitRating_dualWield   = 491,  -- ~28% (white DW vs. lvl 73, requires Draenei or 2H)
    rangedHitRating_yellow     = 142,  -- ~9% for hunters
    spellHitRating_pveCap      = 202,  -- ~12.6% (boss base hit rate for casters; 16% if no Misery, with talents adjusted)
    spellHitRating_pveCap_misery = 159,  -- ~10% with 3% Misery debuff up
    spellHitRating_warlock     = 159,  -- with Suppression talent
    spellHitRating_lockShadow  = 76,   -- with Shadow Mastery talents and Misery (~16% - 6% talents - 3% misery)

    -- Expertise (each point = 0.25% reduction; 4 points = 1%)
    expertise_dodgeCap         = 26,   -- 6.5% (eliminates dodge from lvl 73)
    expertise_parryCap         = 56,   -- 14% (eliminates parry; behind-the-target play makes this less useful)
    expertiseRating_dodgeCap   = 102,  -- 26 expertise from rating (3.9 rating per expertise)
    expertiseRating_parryCap   = 220,

    -- Defense (uncrittable)
    defense_uncritCap          = 490,  -- 5.6% reduction in crit chance vs. lvl 73 boss
    defenseRating_perPoint     = 2.37, -- defense skill per defense rating point

    -- Tank thresholds
    avoidance_uncrushableCap   = 102.4, -- dodge + parry + block + miss + base = 102.4% to remove crushing blows
}

-- ============================================================================
-- Spec list (display order, used for the dropdown override)
-- ============================================================================
WS.SPEC_LIST = {
    WARRIOR = { "Arms", "Fury", "Protection" },
    PALADIN = { "Holy", "Protection", "Retribution" },
    HUNTER  = { "BeastMastery", "Marksmanship", "Survival" },
    ROGUE   = { "Assassination", "Combat", "Subtlety" },
    PRIEST  = { "Discipline", "Holy", "Shadow" },
    DRUID   = { "Balance", "Feral_Cat", "Feral_Bear", "Restoration" },
    SHAMAN  = { "Elemental", "Enhancement", "Restoration" },
    MAGE    = { "Arcane", "Fire", "Frost" },
    WARLOCK = { "Affliction", "Demonology", "Destruction" },
}

-- Display labels for Druid feral split
WS.SPEC_LABELS = {
    Feral_Cat  = "Feral (Cat)",
    Feral_Bear = "Feral (Bear)",
    BeastMastery = "Beast Mastery",
}

-- ============================================================================
-- Detect active spec from talent tree
--
-- GetTalentTabInfo's return order varies between WoW client versions. To stay
-- robust we scan every returned value: pick the first string that maps to a
-- known spec NAME, and the first non-negative integer in [0, 71] as points.
-- ============================================================================
local NAME_TO_SPEC = {
    -- Warrior
    ["Arms"] = "Arms", ["Fury"] = "Fury", ["Protection"] = "Protection",
    -- Paladin (Protection shares with Warrior; class context disambiguates)
    ["Holy"] = "Holy", ["Retribution"] = "Retribution",
    -- Hunter
    ["Beast Mastery"] = "BeastMastery", ["Marksmanship"] = "Marksmanship",
    ["Survival"] = "Survival",
    -- Rogue
    ["Assassination"] = "Assassination", ["Combat"] = "Combat",
    ["Subtlety"] = "Subtlety",
    -- Priest
    ["Discipline"] = "Discipline", ["Shadow"] = "Shadow",
    -- Druid
    ["Balance"] = "Balance", ["Feral Combat"] = "Feral_Cat",
    ["Feral"] = "Feral_Cat", ["Restoration"] = "Restoration",
    -- Shaman
    ["Elemental"] = "Elemental", ["Elemental Combat"] = "Elemental",
    ["Enhancement"] = "Enhancement",
    -- Mage
    ["Arcane"] = "Arcane", ["Fire"] = "Fire", ["Frost"] = "Frost",
    -- Warlock
    ["Affliction"] = "Affliction", ["Demonology"] = "Demonology",
    ["Destruction"] = "Destruction",
}

function WS:DetectSpec()
    local _, class = UnitClass("player")
    if not class or not WS.WEIGHTS[class] then return nil end

    local numTabs = (GetNumTalentTabs and GetNumTalentTabs()) or 3
    local bestSpec, bestPts = nil, -1
    for i = 1, numTabs do
        local results = { GetTalentTabInfo(i) }
        if #results > 0 then
            -- Find the spec name: first string that resolves to a known spec
            local specKey
            for _, v in ipairs(results) do
                if type(v) == "string" then
                    local s = NAME_TO_SPEC[v]
                    if s and WS.WEIGHTS[class][s] then
                        specKey = s
                        break
                    end
                end
            end
            -- Druid: NAME_TO_SPEC["Feral Combat"] -> Feral_Cat by default;
            -- only Feral_Cat is in WS.WEIGHTS[class], so the lookup works.
            -- The Feral_Bear variant is selected via /wickstats spec override.

            -- Find points spent: first non-negative integer in [0, 71]
            -- (icons are large file IDs, names are strings)
            local pts = 0
            for _, v in ipairs(results) do
                if type(v) == "number" and v >= 0 and v <= 71 and v == math.floor(v) then
                    pts = v
                    break
                end
            end

            if specKey and pts > bestPts then
                bestSpec = specKey
                bestPts = pts
            end
        end
    end
    return bestSpec
end

-- ============================================================================
-- Apply runtime cap-awareness to a weight table.
-- Returns a modified copy where stats past their cap have weight reduced or zeroed.
-- ============================================================================
function WS:WeightsWithCaps(specWeights, stats)
    if not specWeights or not stats then return specWeights end
    local w = {}
    for k, v in pairs(specWeights) do w[k] = v end
    if not w.primary then w.primary = "sp" end

    -- Melee hit cap (special attacks; below cap full weight, above cap zero)
    if w.hitRating and w.hitRating > 0 then
        local hr = stats.hitMeleeRating or 0
        if hr >= WS.CAPS.meleeHitRating_special then
            w.hitRating = 0
            w._hitCapped = true
        end
    end

    -- Ranged hit cap (yellow shots)
    if w.rhitRating and w.rhitRating > 0 then
        local rhr = stats.rhitRating or 0
        if rhr >= WS.CAPS.rangedHitRating_yellow then
            w.rhitRating = 0
            w._rhitCapped = true
        end
    end

    -- Spell hit cap (use the conservative "no Misery" cap; users with Misery
    -- in raid will be over-capped a touch, which is fine)
    if w.shitRating and w.shitRating > 0 then
        local shr = stats.shitRating or 0
        if shr >= WS.CAPS.spellHitRating_pveCap then
            w.shitRating = 0
            w._shitCapped = true
        end
    end

    -- Expertise: full weight up to dodge cap, halved between dodge and parry,
    -- zero past parry. Most players target dodge cap and stop there.
    if w.expRating and w.expRating > 0 then
        local er = stats.expRating or 0
        if er >= WS.CAPS.expertiseRating_parryCap then
            w.expRating = 0
            w._expCapped = "parry"
        elseif er >= WS.CAPS.expertiseRating_dodgeCap then
            w.expRating = w.expRating * 0.4  -- only parry remains, much smaller value
            w._expCapped = "dodge"
        end
    end

    -- Defense: zero weight past uncrittable cap (490) UNLESS this is a tank
    -- spec where we want to keep some weight for avoidance scaling
    if w.defRating and w.defRating > 0 then
        local def = stats.defense or 0
        if def >= WS.CAPS.defense_uncritCap then
            -- Tanks still benefit (avoidance), but the priority drops sharply
            w.defRating = w.defRating * 0.25
            w._defCapped = true
        end
    end

    return w
end

