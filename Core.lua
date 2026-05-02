-- Wick's Stats
-- Core.lua: stat collection + event wiring

local ADDON, ns = ...
WicksStats = WicksStats or {}
local WS = WicksStats
ns.WS = WS

local _, playerClass = UnitClass("player")
WS.playerClass = playerClass

local MANA_CLASSES = {
    PRIEST = true, MAGE = true, WARLOCK = true, PALADIN = true,
    DRUID = true, SHAMAN = true, HUNTER = true,
}
local HEAL_CAPABLE = {
    PRIEST = true, PALADIN = true, DRUID = true, SHAMAN = true,
}
local CAN_PARRY = {
    WARRIOR = true, PALADIN = true, ROGUE = true, HUNTER = true, SHAMAN = true,
}
local CAN_BLOCK = {
    WARRIOR = true, PALADIN = true, SHAMAN = true,
}

WS.showSpell  = true
WS.showHeal   = HEAL_CAPABLE[playerClass] or false
WS.showMana   = MANA_CLASSES[playerClass] or false
WS.showParry  = CAN_PARRY[playerClass] or false
WS.showBlock  = CAN_BLOCK[playerClass] or false

local function safeCall(fn, ...)
    if type(fn) ~= "function" then return 0 end
    local ok, v = pcall(fn, ...)
    if ok then return v or 0 end
    return 0
end

local function attr(idx)
    local _, eff, pos, neg = UnitStat("player", idx)
    return {
        total   = eff,
        pos     = pos or 0,
        neg     = neg or 0,
        baseGear = eff - (pos or 0) - (neg or 0),
    }
end

function WS:Collect()
    local s = {}

    s.str = attr(1)
    s.agi = attr(2)
    s.sta = attr(3)
    s.int = attr(4)
    s.spi = attr(5)

    s.hp = UnitHealthMax("player")
    s.mp = UnitPowerMax("player", 0)

    -- Melee
    local apBase, apPos, apNeg = UnitAttackPower("player")
    s.ap        = apBase + (apPos or 0) + (apNeg or 0)
    s.apBase    = apBase
    s.apPos     = apPos or 0
    s.apNeg     = apNeg or 0
    s.crit      = safeCall(GetCritChance)
    s.hitMelee  = (safeCall(GetHitModifier)) + safeCall(GetCombatRatingBonus, CR_HIT_MELEE)
    s.hitMeleeRating = safeCall(GetCombatRating, CR_HIT_MELEE)
    s.expRating = safeCall(GetCombatRating, CR_EXPERTISE)
    s.expertise = safeCall(GetExpertise)
    s.haste     = safeCall(GetCombatRatingBonus, CR_HASTE_MELEE)
    s.hasteRating = safeCall(GetCombatRating, CR_HASTE_MELEE)
    if UnitAttackBothHands then
        local mhB, mhM, ohB, ohM = UnitAttackBothHands("player")
        s.weaponSkillMH = (mhB or 0) + (mhM or 0)
        s.weaponSkillOH = (ohB or 0) + (ohM or 0)
    end
    local mhSpeed, ohSpeed = UnitAttackSpeed("player")
    s.atkSpeedMH = mhSpeed or 0
    s.atkSpeedOH = ohSpeed

    -- Ranged
    local rapBase, rapPos, rapNeg = UnitRangedAttackPower("player")
    s.rap        = rapBase + (rapPos or 0) + (rapNeg or 0)
    s.rapBase    = rapBase
    s.rapPos     = rapPos or 0
    s.rapNeg     = rapNeg or 0
    s.rcrit      = safeCall(GetRangedCritChance)
    s.rhit       = (safeCall(GetHitModifier)) + safeCall(GetCombatRatingBonus, CR_HIT_RANGED)
    s.rhitRating = safeCall(GetCombatRating, CR_HIT_RANGED)
    s.rhaste     = safeCall(GetCombatRatingBonus, CR_HASTE_RANGED)

    -- Spell power per school (school index for spell APIs: 1=Phys 2=Holy 3=Fire 4=Nature 5=Frost 6=Shadow 7=Arcane)
    s.spHoly   = safeCall(GetSpellBonusDamage, 2)
    s.spFire   = safeCall(GetSpellBonusDamage, 3)
    s.spNature = safeCall(GetSpellBonusDamage, 4)
    s.spFrost  = safeCall(GetSpellBonusDamage, 5)
    s.spShadow = safeCall(GetSpellBonusDamage, 6)
    s.spArcane = safeCall(GetSpellBonusDamage, 7)
    s.healing  = safeCall(GetSpellBonusHealing)

    local bestCrit, bestSchool = 0, 2
    for sch = 2, 7 do
        local c = safeCall(GetSpellCritChance, sch)
        if c > bestCrit then bestCrit = c; bestSchool = sch end
    end
    s.scrit       = bestCrit
    s.scritSchool = bestSchool
    s.scritHoly   = safeCall(GetSpellCritChance, 2)
    s.scritFire   = safeCall(GetSpellCritChance, 3)
    s.scritNature = safeCall(GetSpellCritChance, 4)
    s.scritFrost  = safeCall(GetSpellCritChance, 5)
    s.scritShadow = safeCall(GetSpellCritChance, 6)
    s.scritArcane = safeCall(GetSpellCritChance, 7)

    s.shitFlat   = safeCall(GetSpellHitModifier)
    s.shitRating = safeCall(GetCombatRating, CR_HIT_SPELL)
    s.shit       = s.shitFlat + safeCall(GetCombatRatingBonus, CR_HIT_SPELL)
    s.shaste     = safeCall(GetCombatRatingBonus, CR_HASTE_SPELL)
    s.shasteRating = safeCall(GetCombatRating, CR_HASTE_SPELL)
    s.spen       = safeCall(GetSpellPenetration)

    -- Defenses
    local _, armorEff, armor, armorPos, armorNeg = UnitArmor("player")
    s.armor          = armorEff or 0
    s.armorBaseGear  = armor or 0
    s.armorPos       = armorPos or 0
    s.armorNeg       = armorNeg or 0
    -- Damage reduction vs level 73 attacker (raid boss): armor / (armor + 11960)
    s.armorReduction = (s.armor / (s.armor + 11960)) * 100

    local defBase, defMod = UnitDefense("player")
    s.defenseBase    = defBase or 0
    s.defenseMod     = defMod or 0
    s.defense        = (defBase or 0) + (defMod or 0)
    s.defRating      = safeCall(GetCombatRating, CR_DEFENSE_SKILL)

    s.dodge      = safeCall(GetDodgeChance)
    s.dodgeRating = safeCall(GetCombatRating, CR_DODGE)
    s.parry      = safeCall(GetParryChance)
    s.parryRating = safeCall(GetCombatRating, CR_PARRY)
    s.block      = safeCall(GetBlockChance)
    s.blockRating = safeCall(GetCombatRating, CR_BLOCK)
    s.blockValue = safeCall(GetShieldBlock)

    -- Resilience: TBC ties to CR_CRIT_TAKEN_*; we use melee as the canonical resilience number
    s.resilienceRating  = safeCall(GetCombatRating, CR_CRIT_TAKEN_MELEE)
    s.resilienceCritReduce = safeCall(GetCombatRatingBonus, CR_CRIT_TAKEN_MELEE)

    -- Resistances (UnitResistance school: 1=Holy 2=Fire 3=Nature 4=Frost 5=Shadow 6=Arcane)
    local function resAt(idx)
        local _, val = UnitResistance("player", idx)
        return val or 0
    end
    s.resHoly   = resAt(1)
    s.resFire   = resAt(2)
    s.resNature = resAt(3)
    s.resFrost  = resAt(4)
    s.resShadow = resAt(5)
    s.resArcane = resAt(6)

    -- Mana regen (per second, multiply by 5 for MP5 display)
    local oFSR, iFSR = GetManaRegen()
    s.mp5out = (oFSR or 0) * 5
    s.mp5in  = (iFSR or 0) * 5

    self.stats = s
    return s
end

-- ====== EVENT WIRING ======

local f = CreateFrame("Frame")
WS.eventFrame = f

local EVENTS = {
    "PLAYER_ENTERING_WORLD",
    "PLAYER_LOGIN",
    "UNIT_AURA",
    "UNIT_INVENTORY_CHANGED",
    "UNIT_DAMAGE",
    "UNIT_RANGED_DAMAGE",
    "UNIT_ATTACK_POWER",
    "UNIT_RANGED_ATTACK_POWER",
    "UNIT_ATTACK_SPEED",
    "UNIT_RESISTANCES",
    "UNIT_STATS",
    "UNIT_DEFENSE",
    "UNIT_MAXHEALTH",
    "UNIT_MAXMANA",
    "COMBAT_RATING_UPDATE",
    "PLAYER_DAMAGE_DONE_MODS",
    "SPELL_POWER_CHANGED",
    "PLAYER_REGEN_DISABLED",
    "PLAYER_REGEN_ENABLED",
}
for _, e in ipairs(EVENTS) do
    pcall(f.RegisterEvent, f, e)
end

f:SetScript("OnEvent", function(self, event, arg1)
    if event == "PLAYER_LOGIN" then
        WicksStatsSettings = WicksStatsSettings or {}
        if WS.OnLogin then WS:OnLogin() end
        return
    end
    -- Unit-scoped events: ignore non-player units
    if arg1 and type(arg1) == "string" and arg1 ~= "player" then
        if event:sub(1,5) == "UNIT_" then return end
    end
    WS.dirty = true
end)

-- Slash command
SLASH_WICKSSTATS1 = "/wickstats"
SLASH_WICKSSTATS2 = "/wstats"
SlashCmdList.WICKSSTATS = function()
    if WS.Toggle then WS:Toggle() end
end
