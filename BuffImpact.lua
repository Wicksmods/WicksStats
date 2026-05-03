-- Wick's Stats
-- BuffImpact.lua: detect missing common raid buffs and estimate stat gain
--
-- Each buff has an optional `group` (mutually-exclusive variants share a
-- group; e.g., Mark of the Wild and Gift of the Wild) and a `category`
-- (used by the options UI for grouping). The detector treats group
-- membership as the dedupe key: if any member of a group is active, the
-- whole group is "covered". If a whole group is missing, only the FIRST
-- entry in the table for that group is reported.

local WS = WicksStats

WS.BUFFS = {
    -- Druid
    { name = "Gift of the Wild",          group = "wild",   category = "Druid",   gains = { str = 14, agi = 14, sta = 14, int = 14, spi = 14, allResist = 25 } },
    { name = "Mark of the Wild",          group = "wild",   category = "Druid",   gains = { str = 14, agi = 14, sta = 14, int = 14, spi = 14, allResist = 25 } },
    { name = "Moonkin Aura",              category = "Druid",   gains = { scrit_pct = 5 } },
    { name = "Tree of Life",              category = "Druid",   gains = { healing_aura = "+25% healing recv" } },

    -- Priest
    { name = "Prayer of Fortitude",       group = "fort",   category = "Priest",  gains = { sta = 79 } },
    { name = "Power Word: Fortitude",     group = "fort",   category = "Priest",  gains = { sta = 79 } },
    { name = "Prayer of Spirit",          group = "spirit", category = "Priest",  gains = { spi = 50 } },
    { name = "Divine Spirit",             group = "spirit", category = "Priest",  gains = { spi = 50 } },

    -- Mage
    { name = "Arcane Brilliance",         group = "int",    category = "Mage",    gains = { int = 40 } },
    { name = "Arcane Intellect",          group = "int",    category = "Mage",    gains = { int = 40 } },

    -- Paladin (blessings)
    { name = "Greater Blessing of Kings", group = "kings",  category = "Paladin", gains = { stats_pct = 10 } },
    { name = "Blessing of Kings",         group = "kings",  category = "Paladin", gains = { stats_pct = 10 } },
    { name = "Greater Blessing of Might", group = "might",  category = "Paladin", gains = { ap = 220 } },
    { name = "Blessing of Might",         group = "might",  category = "Paladin", gains = { ap = 220 } },
    { name = "Greater Blessing of Wisdom", group = "wisdom", category = "Paladin", gains = { mp5 = 41 } },
    { name = "Blessing of Wisdom",        group = "wisdom", category = "Paladin", gains = { mp5 = 41 } },
    { name = "Greater Blessing of Salvation", group = "salv", category = "Paladin", gains = { threat_pct = -30 } },
    { name = "Blessing of Salvation",     group = "salv",   category = "Paladin", gains = { threat_pct = -30 } },
    { name = "Greater Blessing of Sanctuary", group = "sanc", category = "Paladin", gains = { dmg_taken_pct = -3 } },
    { name = "Blessing of Sanctuary",     group = "sanc",   category = "Paladin", gains = { dmg_taken_pct = -3 } },
    -- Paladin auras
    { name = "Devotion Aura",             category = "Paladin", gains = { armor = 1205 } },
    { name = "Retribution Aura",          category = "Paladin", gains = { ret_dmg = "passive holy dmg" } },
    { name = "Sanctity Aura",             category = "Paladin", gains = { holy_dmg_pct = 10 } },

    -- Warrior
    { name = "Battle Shout",              category = "Warrior", gains = { ap = 305 } },
    { name = "Commanding Shout",          category = "Warrior", gains = { hp = 1080 } },

    -- Hunter
    { name = "Trueshot Aura",             category = "Hunter",  gains = { ap = 125 } },
    { name = "Ferocious Inspiration",     category = "Hunter",  gains = { dmg_pct = 3 } },

    -- Shaman
    { name = "Strength of Earth",         category = "Shaman",  gains = { str = 86 } },
    { name = "Grace of Air",              category = "Shaman",  gains = { agi = 77 } },
    { name = "Windfury Totem",            category = "Shaman",  gains = { wf_haste = "WF procs" } },
    { name = "Wrath of Air Totem",        category = "Shaman",  gains = { sp = 101 } },
    { name = "Totem of Wrath",            category = "Shaman",  gains = { sp = 101, scrit_pct = 3 } },
    { name = "Mana Spring Totem",         category = "Shaman",  gains = { mp5 = 50 } },
    { name = "Unleashed Rage",            category = "Shaman",  gains = { ap_pct = 10 } },

    -- Racial
    { name = "Heroic Presence",           category = "Other",   gains = { hitRating = 16 } },

    -- Target debuffs that affect player damage (informational)
    { name = "Misery",                    category = "Debuffs", gains = { sp_target_pct = 5 } },
}

-- Buffs are opt-in: default OFF. Only buffs in WicksStatsSettings.buffsEnabled
-- with a true value are tracked.
function WS:IsBuffEnabled(name)
    if not WicksStatsSettings or not WicksStatsSettings.buffsEnabled then return false end
    return WicksStatsSettings.buffsEnabled[name] == true
end

function WS:SetBuffEnabled(name, enabled)
    WicksStatsSettings = WicksStatsSettings or {}
    WicksStatsSettings.buffsEnabled = WicksStatsSettings.buffsEnabled or {}
    if enabled then
        WicksStatsSettings.buffsEnabled[name] = true
    else
        WicksStatsSettings.buffsEnabled[name] = nil
    end
end

function WS:SetAllBuffsEnabled(enabled)
    WicksStatsSettings = WicksStatsSettings or {}
    WicksStatsSettings.buffsEnabled = WicksStatsSettings.buffsEnabled or {}
    if enabled then
        for _, b in ipairs(WS.BUFFS) do
            WicksStatsSettings.buffsEnabled[b.name] = true
        end
    else
        WicksStatsSettings.buffsEnabled = {}
    end
end

-- Snapshot currently-active buffs into the enabled list (replaces previous)
function WS:MatchEnabledToCurrent()
    WicksStatsSettings = WicksStatsSettings or {}
    WicksStatsSettings.buffsEnabled = {}
    local known = {}
    for _, b in ipairs(WS.BUFFS) do known[b.name] = true end
    for i = 1, 40 do
        local name = UnitBuff("player", i)
        if not name then break end
        if known[name] then
            WicksStatsSettings.buffsEnabled[name] = true
        end
    end
end

-- Apply enabled-but-missing raid buffs to a stats table in place. Used to
-- preview "what would my stats look like fully buffed" without needing the
-- raid composition to actually apply them.
--
-- Two passes:
--   1. Additive gains (raw stat boosts, ratings, hp/mp deltas)
--   2. Percentage multipliers (Blessing of Kings, Unleashed Rage)
function WS:SimulateRaidBuffs(s)
    if not s then return end
    local missing = self:DetectMissingBuffs()

    local function bumpAttr(key, amt)
        local a = s[key]; if not a or type(amt) ~= "number" then return end
        a.total    = (a.total or 0) + amt
        a.pos      = (a.pos or 0) + amt
        a.baseGear = (a.baseGear or 0)  -- unchanged; sim contributes via pos
    end

    -- Pass 1: additive
    for _, b in ipairs(missing) do
        for stat, gain in pairs(b.gains) do
            if type(gain) == "number" then
                if stat == "str" or stat == "agi" or stat == "sta" or stat == "int" or stat == "spi" then
                    bumpAttr(stat, gain)
                elseif stat == "ap" then
                    s.ap = (s.ap or 0) + gain
                    s.apPos = (s.apPos or 0) + gain
                elseif stat == "rap" then
                    s.rap = (s.rap or 0) + gain
                    s.rapPos = (s.rapPos or 0) + gain
                elseif stat == "sp" then
                    s.spHoly   = (s.spHoly or 0) + gain
                    s.spFire   = (s.spFire or 0) + gain
                    s.spNature = (s.spNature or 0) + gain
                    s.spFrost  = (s.spFrost or 0) + gain
                    s.spShadow = (s.spShadow or 0) + gain
                    s.spArcane = (s.spArcane or 0) + gain
                elseif stat == "healing" then
                    s.healing = (s.healing or 0) + gain
                elseif stat == "mp5" then
                    s.mp5out = (s.mp5out or 0) + gain
                    s.mp5in  = (s.mp5in or 0) + gain
                elseif stat == "hp" then
                    s.hp = (s.hp or 0) + gain
                elseif stat == "scrit_pct" then
                    s.scrit       = (s.scrit or 0) + gain
                    s.scritHoly   = (s.scritHoly or 0) + gain
                    s.scritFire   = (s.scritFire or 0) + gain
                    s.scritNature = (s.scritNature or 0) + gain
                    s.scritFrost  = (s.scritFrost or 0) + gain
                    s.scritShadow = (s.scritShadow or 0) + gain
                    s.scritArcane = (s.scritArcane or 0) + gain
                elseif stat == "armor" then
                    s.armor = (s.armor or 0) + gain
                    s.armorReduction = (s.armor / (s.armor + 11960)) * 100
                elseif stat == "allResist" then
                    s.resHoly   = (s.resHoly or 0) + gain
                    s.resFire   = (s.resFire or 0) + gain
                    s.resNature = (s.resNature or 0) + gain
                    s.resFrost  = (s.resFrost or 0) + gain
                    s.resShadow = (s.resShadow or 0) + gain
                    s.resArcane = (s.resArcane or 0) + gain
                elseif stat == "hitRating" then
                    s.hitMeleeRating = (s.hitMeleeRating or 0) + gain
                    s.rhitRating     = (s.rhitRating or 0) + gain
                    s.shitRating     = (s.shitRating or 0) + gain
                    -- approximate percentage update (~15.77 rating per 1%)
                    s.hitMelee = (s.hitMelee or 0) + gain / 15.77
                    s.rhit     = (s.rhit or 0) + gain / 15.77
                    s.shit     = (s.shit or 0) + gain / 12.61
                end
            end
        end
    end

    -- Pass 2: percentage multipliers (after additive so they compound correctly)
    for _, b in ipairs(missing) do
        for stat, gain in pairs(b.gains) do
            if type(gain) == "number" then
                if stat == "stats_pct" then
                    local mul = 1 + gain / 100
                    for _, k in ipairs({"str","agi","sta","int","spi"}) do
                        local a = s[k]
                        if a then
                            local extra = math.floor((a.total or 0) * (mul - 1) + 0.5)
                            a.total = a.total + extra
                            a.pos   = a.pos + extra
                        end
                    end
                    s.hp = math.floor((s.hp or 0) * mul + 0.5)
                    s.mp = math.floor((s.mp or 0) * mul + 0.5)
                elseif stat == "ap_pct" then
                    local mul = 1 + gain / 100
                    local extra = math.floor((s.ap or 0) * (mul - 1) + 0.5)
                    s.ap = (s.ap or 0) + extra
                    s.apPos = (s.apPos or 0) + extra
                end
            end
        end
    end

    s._simulated = true
end

function WS:DetectMissingBuffs()
    local active = {}
    for i = 1, 40 do
        local name = UnitBuff("player", i)
        if not name then break end
        active[name] = true
    end

    -- A group is covered if ANY of its members is active
    local activeGroups = {}
    for _, b in ipairs(WS.BUFFS) do
        if active[b.name] and b.group then
            activeGroups[b.group] = true
        end
    end

    local seenGroups = {}
    local missing = {}
    for _, b in ipairs(WS.BUFFS) do
        if not active[b.name] and self:IsBuffEnabled(b.name) then
            if b.group then
                if not activeGroups[b.group] and not seenGroups[b.group] then
                    seenGroups[b.group] = true
                    table.insert(missing, b)
                end
            else
                table.insert(missing, b)
            end
        end
    end
    return missing
end
