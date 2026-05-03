-- Wick's Stats
-- BuffImpact.lua: detect missing common raid buffs and estimate stat gain
--
-- For each buff we track: the spell's primary buff name (to scan UnitAura),
-- and a per-stat gain estimate at level 70 with typical talents.
--
-- Heuristic only: actual impact varies with talents (e.g., Improved Mark of
-- the Wild multiplier), but the lookup gives a useful "what am I missing"
-- nudge without scanning every aura on the player.

local WS = WicksStats

-- Each entry: name (aura name to match), short label, role (raid|class), and
-- a `gains` table of { statKey = approxAmount } for the typical max-rank buff.
-- We only include the most common raid-wide buffs; class-specific party buffs
-- (e.g., Power Word: Fortitude vs. Prayer of Fortitude) are unified by name.
WS.BUFFS = {
    { name = "Mark of the Wild",      gains = { str = 14, agi = 14, sta = 14, int = 14, spi = 14, allResist = 25 } },
    { name = "Gift of the Wild",      gains = { str = 14, agi = 14, sta = 14, int = 14, spi = 14, allResist = 25 } },
    { name = "Power Word: Fortitude", gains = { sta = 79 } },
    { name = "Prayer of Fortitude",   gains = { sta = 79 } },
    { name = "Divine Spirit",         gains = { spi = 50 } },
    { name = "Prayer of Spirit",      gains = { spi = 50 } },
    { name = "Arcane Intellect",      gains = { int = 40 } },
    { name = "Arcane Brilliance",     gains = { int = 40 } },
    { name = "Blessing of Kings",     gains = { stats_pct = 10 } },
    { name = "Blessing of Might",     gains = { ap = 220 } },
    { name = "Greater Blessing of Might", gains = { ap = 220 } },
    { name = "Blessing of Wisdom",    gains = { mp5 = 41 } },
    { name = "Greater Blessing of Wisdom", gains = { mp5 = 41 } },
    { name = "Battle Shout",          gains = { ap = 305 } },
    { name = "Trueshot Aura",         gains = { ap = 125 } },
    { name = "Unleashed Rage",        gains = { ap_pct = 10 } },
    { name = "Strength of Earth",     gains = { str = 86 } },  -- Cyclone totem rank
    { name = "Grace of Air",          gains = { agi = 77 } },
    { name = "Wrath of Air",          gains = { sp = 101 } },
    { name = "Totem of Wrath",        gains = { sp = 101, scrit_pct = 3 } },
    { name = "Mana Spring",           gains = { mp5 = 50 } },
    { name = "Moonkin Aura",          gains = { scrit_pct = 5 } },
    { name = "Inspiring Presence",    gains = { shitRating = 65 } },  -- Imp DM
    { name = "Ferocious Inspiration", gains = { dmg_pct = 3 } },
    { name = "Heroic Presence",       gains = { hitRating = 16 } },   -- Draenei racial-effect aura
    { name = "Misery",                gains = { sp_target_pct = 5 } }, -- target debuff
}

-- Returns a list of { name, gains } for buffs the player does NOT currently have.
function WS:DetectMissingBuffs()
    local active = {}
    for i = 1, 40 do
        local name = UnitBuff("player", i)
        if not name then break end
        active[name] = true
    end

    local missing = {}
    -- Collapse buff variants (e.g., MotW vs GotW) - if the player has any
    -- variant, treat the whole group as covered. Group by primary stat
    -- signature.
    local covered = {}
    for _, b in ipairs(WS.BUFFS) do
        if active[b.name] then
            for k in pairs(b.gains) do covered[k] = true end
        end
    end
    for _, b in ipairs(WS.BUFFS) do
        if not active[b.name] then
            -- Only flag if no other buff already covers all of its gains
            local stillMissing = false
            for k in pairs(b.gains) do
                if not covered[k] then stillMissing = true; break end
            end
            if stillMissing then
                table.insert(missing, b)
            end
        end
    end
    return missing
end
