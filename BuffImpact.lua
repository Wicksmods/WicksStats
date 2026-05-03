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

function WS:IsBuffEnabled(name)
    if not WicksStatsSettings then return true end
    local d = WicksStatsSettings.buffsDisabled
    if not d then return true end
    return not d[name]
end

function WS:SetBuffEnabled(name, enabled)
    WicksStatsSettings = WicksStatsSettings or {}
    WicksStatsSettings.buffsDisabled = WicksStatsSettings.buffsDisabled or {}
    if enabled then
        WicksStatsSettings.buffsDisabled[name] = nil
    else
        WicksStatsSettings.buffsDisabled[name] = true
    end
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
