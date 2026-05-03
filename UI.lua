-- Wick's Stats
-- UI.lua: side panel docked next to the character frame

local ADDON, ns = ...
local WS = WicksStats

-- Wick brand palette (mirror of WTBT/UI.lua)
local C_BG          = { 0.051, 0.039, 0.078, 0.97 }
local C_HEADER_BG   = { 0.090, 0.067, 0.141, 1 }
local C_BORDER      = { 0.220, 0.188, 0.345, 1 }
local C_GREEN       = { 0.310, 0.780, 0.471, 1 }
local C_TEXT_DIM    = { 0.42, 0.35, 0.54, 1 }
local C_TEXT_NORMAL = { 0.831, 0.784, 0.631, 1 }
local C_ROW_HOVER   = { 0.310, 0.780, 0.471, 0.06 }

local PANEL_W_DEFAULT = 720
local PANEL_W_MIN     = 480
local PANEL_W_MAX     = 1400
local TITLE_H      = 28
local SECTION_H    = 20
local ROW_H        = 17
local SECTION_GAP  = 6
local PADDING      = 8
local COL_GAP      = 10
local COL_W_TARGET = 220   -- desired column width; numCols computed from panel width

-- ============================================================
-- helpers
-- ============================================================
local function SetRGBA(tex, c)
    tex:SetColorTexture(c[1], c[2], c[3], c[4] or 1)
end

local function NewTexture(parent, layer, c)
    local t = parent:CreateTexture(nil, layer or "BACKGROUND")
    if c then SetRGBA(t, c) end
    return t
end

local function NewText(parent, size, c)
    local f = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f:SetFont("Fonts\\FRIZQT__.TTF", (size or 11) + 1, "")
    if c then f:SetTextColor(c[1], c[2], c[3], c[4] or 1) end
    return f
end

local function AddBorder(frame, c)
    c = c or C_BORDER
    local function edge(p1, p2, w, h)
        local t = frame:CreateTexture(nil, "BORDER")
        t:SetColorTexture(c[1], c[2], c[3], c[4] or 1)
        t:SetPoint(p1); t:SetPoint(p2)
        if w then t:SetWidth(w) end
        if h then t:SetHeight(h) end
    end
    edge("TOPLEFT",    "TOPRIGHT",    nil, 1)
    edge("BOTTOMLEFT", "BOTTOMRIGHT", nil, 1)
    edge("TOPLEFT",    "BOTTOMLEFT",  1,   nil)
    edge("TOPRIGHT",   "BOTTOMRIGHT", 1,   nil)
end

local function AddCornerAccents(frame)
    local arm, thick = 10, 2
    local g = C_GREEN
    local function brk(anchor, sx, sy, hArm, vArm)
        local h = frame:CreateTexture(nil, "OVERLAY")
        h:SetColorTexture(g[1], g[2], g[3], 1)
        h:SetPoint(anchor, sx, sy); h:SetSize(hArm, thick)
        local v = frame:CreateTexture(nil, "OVERLAY")
        v:SetColorTexture(g[1], g[2], g[3], 1)
        v:SetPoint(anchor, sx, sy); v:SetSize(thick, vArm)
    end
    brk("TOPLEFT",     0,  0, arm, arm)
    brk("TOPRIGHT",    0,  0, arm, arm)
    brk("BOTTOMLEFT",  0,  0, arm, arm)
    brk("BOTTOMRIGHT", 0,  0, arm, arm)
end

local function fmtInt(n)
    if not n then return "0" end
    return tostring(math.floor(n + 0.5))
end

local function fmtPct(p)
    if not p then return "0.00%" end
    return string.format("%.2f%%", p)
end

local function fmtSpeed(s)
    if not s or s == 0 then return "--" end
    return string.format("%.2f", s)
end

local function colorBuff(pos, neg)
    -- pick value color: green if pos buff > 0, red if net negative, normal otherwise
    if (pos or 0) > 0 and (neg or 0) >= 0 then return 0.31, 0.78, 0.47 end
    if (neg or 0) < 0 then return 0.87, 0.45, 0.45 end
    return C_TEXT_NORMAL[1], C_TEXT_NORMAL[2], C_TEXT_NORMAL[3]
end

-- ============================================================
-- weights: row-key -> weight-table-key mapping + active weights cache
-- ============================================================
-- Row key -> stats[key] for live-diff lookup. Not every row has a stable
-- single-field source (e.g. spMax is computed from 6 school SPs); skip those.
local ROW_TO_STAT_KEY = {
    str = "str", agi = "agi", sta = "sta", int = "int", spi = "spi",
    hp  = "hp",  mp  = "mp",
    ap  = "ap",  crit = "crit", hitMelee = "hitMelee",
    expertise = "expertise", haste = "haste",
    rap = "rap", rcrit = "rcrit", rhit = "rhit", rhaste = "rhaste",
    healing = "healing", scrit = "scrit", shit = "shit",
    shaste = "shaste", spen = "spen",
    armor = "armor", defense = "defense",
    dodge = "dodge", parry = "parry", block = "block",
    blockValue = "blockValue", resilience = "resilienceRating",
    mp5out = "mp5out", mp5in = "mp5in",
}

local STAT_TO_WEIGHT_KEY = {
    str = "str", agi = "agi", sta = "sta", int = "int", spi = "spi",
    hp = "sta", mp = "int",
    ap = "ap", crit = "critRating", hitMelee = "hitRating",
    expertise = "expRating", haste = "hasteRating",
    rap = "rap", rcrit = "rcritRating", rhit = "rhitRating", rhaste = "rhasteRating",
    spMax = "sp", healing = "healing", scrit = "scritRating",
    shit = "shitRating", shaste = "shasteRating",
    armor = "armor", defense = "defRating", dodge = "dodgeRating",
    parry = "parryRating", block = "blockRating", blockValue = "blockValue",
    resilience = "resilienceRating",
    mp5out = "mp5", mp5in = "mp5",
}

local STAT_LABEL = {
    sp = "Spell Power", healing = "Bonus Healing",
    int = "Intellect", spi = "Spirit", sta = "Stamina",
    str = "Strength", agi = "Agility",
    ap = "Attack Power", rap = "Ranged AP",
    hitRating = "Hit", rhitRating = "Ranged Hit", shitRating = "Spell Hit",
    critRating = "Crit", rcritRating = "Ranged Crit", scritRating = "Spell Crit",
    hasteRating = "Haste", rhasteRating = "Ranged Haste", shasteRating = "Spell Haste",
    expRating = "Expertise", mp5 = "MP5",
    armor = "Armor", defRating = "Defense",
    dodgeRating = "Dodge", parryRating = "Parry", blockRating = "Block",
    blockValue = "Block Value", resilienceRating = "Resilience",
}

local function getActiveWeights()
    local stats = WS.stats
    if not stats then return nil, nil end
    local class = WS.playerClass
    if not class or not WS.WEIGHTS or not WS.WEIGHTS[class] then return nil, nil end
    local spec = WicksStatsSettings and WicksStatsSettings.specOverride
    if not spec or not WS.WEIGHTS[class][spec] then
        spec = WS.DetectSpec and WS:DetectSpec()
    end
    if not spec or not WS.WEIGHTS[class][spec] then return nil, nil end
    return WS:WeightsWithCaps(WS.WEIGHTS[class][spec], stats), spec
end

-- Tooltip closures for dynamic rows (weights, buffs). The row's data is set
-- at render time on row._weightData / row._buffData; tooltip reads it on hover.
local function weightTooltipFor(rowKey)
    return function()
        local row = rows[rowKey]
        if not row or not row._weightData then return end
        local d = row._weightData
        GameTooltip:AddLine(d.label or d.k or "Stat", 1, 1, 1)
        GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine("Weight", string.format("%.2f", d.v),
            0.7, 0.7, 0.7,
            (d.v == 0) and 0.95 or C_GREEN[1],
            (d.v == 0) and 0.40 or C_GREEN[2],
            (d.v == 0) and 0.40 or C_GREEN[3])
        if d.cap then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(d.cap, 0.7, 0.7, 0.7)
        end
    end
end

local PCT_GAIN_KEYS = {
    stats_pct = true, ap_pct = true, scrit_pct = true, dmg_pct = true,
    sp_target_pct = true, holy_dmg_pct = true, dmg_taken_pct = true,
    threat_pct = true,
}

local function buffTooltipFor(rowKey)
    return function()
        local row = rows[rowKey]
        if not row or not row._buffData then return end
        local b = row._buffData
        GameTooltip:AddLine(b.name, 1, 1, 1)
        if b.category then
            GameTooltip:AddLine(b.category, C_TEXT_DIM[1], C_TEXT_DIM[2], C_TEXT_DIM[3])
        end
        GameTooltip:AddLine(" ")
        for k, v in pairs(b.gains) do
            local valStr
            if type(v) == "number" then
                if PCT_GAIN_KEYS[k] then
                    valStr = (v >= 0 and "+" or "") .. v .. "%"
                else
                    valStr = (v >= 0 and "+" or "") .. v
                end
            else
                valStr = tostring(v)
            end
            GameTooltip:AddDoubleLine(k, valStr,
                0.7, 0.7, 0.7, C_GREEN[1], C_GREEN[2], C_GREEN[3])
        end
        if not b._isActive then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("(missing)", 0.95, 0.40, 0.40)
        end
    end
end

local function appendDeltaFooter(rowKey)
    if not WS.HasBaseline or not WS:HasBaseline() then return end
    local statKey = ROW_TO_STAT_KEY[rowKey]
    if not statKey then return end
    local d = WS:GetBaselineDelta(statKey)
    if not d or math.abs(d) < 0.001 then return end
    GameTooltip:AddLine(" ")
    local sign = d > 0 and "+" or ""
    local color = d > 0 and { 0.40, 0.95, 0.55 } or { 0.95, 0.40, 0.40 }
    local fmt = (math.abs(d) < 1) and "%s%.2f" or "%s%.0f"
    GameTooltip:AddDoubleLine("Δ since open",
        string.format(fmt, sign, d),
        0.7, 0.7, 0.7, color[1], color[2], color[3])
end

local function appendWeightFooter(rowKey)
    local wkey = STAT_TO_WEIGHT_KEY[rowKey]
    if not wkey then return end
    local active = getActiveWeights()
    if not active then return end
    local v = active[wkey]
    if v == nil then return end
    GameTooltip:AddLine(" ")
    if v == 0 then
        GameTooltip:AddDoubleLine("Stat weight", "0.00 (capped)",
            0.7, 0.7, 0.7, 0.87, 0.45, 0.45)
    else
        GameTooltip:AddDoubleLine("Stat weight", string.format("%.2f", v),
            0.7, 0.7, 0.7, C_GREEN[1], C_GREEN[2], C_GREEN[3])
    end
end

-- ============================================================
-- panel scaffolding
-- ============================================================
local panel
local rows = {}    -- key -> row frame
local sections = {}

local function CreateRow(parent)
    -- Position and width are set later by applyLayout()
    local r = CreateFrame("Frame", nil, parent)
    r:SetHeight(ROW_H)
    r:SetWidth(200)  -- placeholder; applyLayout sets real width

    local hover = NewTexture(r, "BACKGROUND")
    hover:SetAllPoints()
    hover:SetColorTexture(0, 0, 0, 0)
    r.hover = hover

    local lbl = NewText(r, 10, C_TEXT_DIM)
    lbl:SetPoint("LEFT", r, "LEFT", 4, 0)
    r.label = lbl

    local val = NewText(r, 10, C_TEXT_NORMAL)
    val:SetPoint("RIGHT", r, "RIGHT", -4, 0)
    val:SetText("--")
    r.value = val

    return r
end

local function CreateSectionHeader(parent, title)
    -- Position is set by applyLayout(); width auto-stretches via TOPLEFT+TOPRIGHT
    local h = CreateFrame("Frame", nil, parent)
    h:SetHeight(SECTION_H)

    local bg = NewTexture(h, "BACKGROUND", C_HEADER_BG)
    bg:SetAllPoints()

    local txt = NewText(h, 10, C_GREEN)
    txt:SetPoint("LEFT", h, "LEFT", 8, 0)
    txt:SetText(title)
    h.label = txt
    return h
end

local function attachTooltip(row, fn, rowKey)
    local hasWeight = rowKey and STAT_TO_WEIGHT_KEY[rowKey]
    if not fn and not hasWeight then return end
    row:EnableMouse(true)
    row:SetScript("OnEnter", function(self)
        SetRGBA(self.hover, C_ROW_HOVER)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        if fn then
            fn()
        else
            local label = row.label and row.label:GetText() or ""
            GameTooltip:AddLine(label, 1, 1, 1)
        end
        if hasWeight then appendWeightFooter(rowKey) end
        appendDeltaFooter(rowKey)
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function(self)
        self.hover:SetColorTexture(0, 0, 0, 0)
        GameTooltip:Hide()
    end)
end

local function makeAttrTooltip(label, key)
    return function()
        local s = WS.stats and WS.stats[key]
        if not s then return end
        GameTooltip:AddLine(label, 1, 1, 1)
        GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine("Total",     fmtInt(s.total),    1, 1, 1, C_GREEN[1], C_GREEN[2], C_GREEN[3])
        GameTooltip:AddDoubleLine("Base + Gear", fmtInt(s.baseGear), 0.7, 0.7, 0.7, 1, 1, 1)
        if (s.pos or 0) > 0 then
            GameTooltip:AddDoubleLine("Buffs",  "+" .. fmtInt(s.pos), 0.7, 0.7, 0.7, 0.31, 0.78, 0.47)
        end
        if (s.neg or 0) < 0 then
            GameTooltip:AddDoubleLine("Debuffs", fmtInt(s.neg),       0.7, 0.7, 0.7, 0.87, 0.45, 0.45)
        end
    end
end

-- ============================================================
-- build the panel
-- ============================================================
local sectionSpecs = {}  -- { { title, rows = { {key,label,tooltipFn}, ... } }, ... }
local _curSection

local function S(title)
    _curSection = { title = title, rows = {} }
    table.insert(sectionSpecs, _curSection)
end
local function R(key, label, tooltipFn)
    table.insert(_curSection.rows, { key = key, label = label, tooltipFn = tooltipFn })
end
local function Rif(cond, key, label, tooltipFn)
    if cond then R(key, label, tooltipFn) end
end

local function buildSpecs()
    -- ATTRIBUTES
    S("ATTRIBUTES")
    R("str", "Strength",  makeAttrTooltip("Strength",  "str"))
    R("agi", "Agility",   makeAttrTooltip("Agility",   "agi"))
    R("sta", "Stamina",   makeAttrTooltip("Stamina",   "sta"))
    R("int", "Intellect", makeAttrTooltip("Intellect", "int"))
    R("spi", "Spirit",    makeAttrTooltip("Spirit",    "spi"))
    R("hp",  "Health")
    Rif(WS.showMana, "mp", "Mana")

    -- MELEE
    S("MELEE")
    R("ap",        "Attack Power", function()
        local s = WS.stats; if not s then return end
        GameTooltip:AddLine("Attack Power", 1, 1, 1)
        GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine("Total",       fmtInt(s.ap),     1, 1, 1, C_GREEN[1], C_GREEN[2], C_GREEN[3])
        GameTooltip:AddDoubleLine("Base + Gear", fmtInt(s.apBase), 0.7, 0.7, 0.7, 1, 1, 1)
        if s.apPos > 0 then GameTooltip:AddDoubleLine("Buffs",   "+" .. fmtInt(s.apPos), 0.7, 0.7, 0.7, 0.31, 0.78, 0.47) end
        if s.apNeg < 0 then GameTooltip:AddDoubleLine("Debuffs", fmtInt(s.apNeg),         0.7, 0.7, 0.7, 0.87, 0.45, 0.45) end
    end)
    R("crit",      "Crit Chance")
    R("hitMelee",  "Hit Chance",  function()
        local s = WS.stats; if not s then return end
        GameTooltip:AddLine("Melee Hit", 1, 1, 1)
        GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine("Total",  fmtPct(s.hitMelee), 1, 1, 1, C_GREEN[1], C_GREEN[2], C_GREEN[3])
        GameTooltip:AddDoubleLine("Rating", fmtInt(s.hitMeleeRating), 0.7, 0.7, 0.7, 1, 1, 1)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Soft caps:", 0.7, 0.7, 0.7)
        GameTooltip:AddLine("9% vs. raid boss (yellow swing)", 0.7, 0.7, 0.7)
        GameTooltip:AddLine("28% vs. raid boss (dual-wield white)", 0.7, 0.7, 0.7)
    end)
    R("expertise", "Expertise",   function()
        local s = WS.stats; if not s then return end
        local pct = (s.expertise or 0) * 0.25
        GameTooltip:AddLine("Expertise", 1, 1, 1)
        GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine("Skill",  fmtInt(s.expertise),    0.7, 0.7, 0.7, 1, 1, 1)
        GameTooltip:AddDoubleLine("Rating", fmtInt(s.expRating),    0.7, 0.7, 0.7, 1, 1, 1)
        GameTooltip:AddDoubleLine("Dodge / Parry reduction", fmtPct(pct), 0.7, 0.7, 0.7, C_GREEN[1], C_GREEN[2], C_GREEN[3])
    end)
    R("haste",     "Haste",       function()
        local s = WS.stats; if not s then return end
        GameTooltip:AddLine("Melee Haste", 1, 1, 1)
        GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine("From rating", fmtPct(s.haste),       1, 1, 1, C_GREEN[1], C_GREEN[2], C_GREEN[3])
        GameTooltip:AddDoubleLine("Rating",      fmtInt(s.hasteRating), 0.7, 0.7, 0.7, 1, 1, 1)
    end)
    R("weaponSkillMH", "Weapon Skill MH")
    R("weaponSkillOH", "Weapon Skill OH")
    R("atkSpeedMH",    "Speed MH")
    R("atkSpeedOH",    "Speed OH")

    -- RANGED
    S("RANGED")
    R("rap",   "Attack Power")
    R("rcrit", "Crit Chance")
    R("rhit",  "Hit Chance", function()
        local s = WS.stats; if not s then return end
        GameTooltip:AddLine("Ranged Hit", 1, 1, 1)
        GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine("Total",  fmtPct(s.rhit),        1, 1, 1, C_GREEN[1], C_GREEN[2], C_GREEN[3])
        GameTooltip:AddDoubleLine("Rating", fmtInt(s.rhitRating),  0.7, 0.7, 0.7, 1, 1, 1)
    end)
    R("rhaste", "Haste")

    -- SPELL (always shown; even rogue can run with spell hit gear, and casters care)
    S("SPELL")
    R("spMax", "Spell Power", function()
        local s = WS.stats; if not s then return end
        GameTooltip:AddLine("Spell Power by School", 1, 1, 1)
        GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine("Holy",   fmtInt(s.spHoly),   0.95, 0.90, 0.50, 1, 1, 1)
        GameTooltip:AddDoubleLine("Fire",   fmtInt(s.spFire),   0.95, 0.40, 0.20, 1, 1, 1)
        GameTooltip:AddDoubleLine("Nature", fmtInt(s.spNature), 0.30, 0.85, 0.30, 1, 1, 1)
        GameTooltip:AddDoubleLine("Frost",  fmtInt(s.spFrost),  0.40, 0.70, 1.00, 1, 1, 1)
        GameTooltip:AddDoubleLine("Shadow", fmtInt(s.spShadow), 0.65, 0.30, 0.85, 1, 1, 1)
        GameTooltip:AddDoubleLine("Arcane", fmtInt(s.spArcane), 0.85, 0.40, 0.85, 1, 1, 1)
    end)
    Rif(WS.showHeal, "healing", "Bonus Healing")
    R("scrit", "Spell Crit", function()
        local s = WS.stats; if not s then return end
        GameTooltip:AddLine("Spell Crit by School", 1, 1, 1)
        GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine("Holy",   fmtPct(s.scritHoly),   0.95, 0.90, 0.50, 1, 1, 1)
        GameTooltip:AddDoubleLine("Fire",   fmtPct(s.scritFire),   0.95, 0.40, 0.20, 1, 1, 1)
        GameTooltip:AddDoubleLine("Nature", fmtPct(s.scritNature), 0.30, 0.85, 0.30, 1, 1, 1)
        GameTooltip:AddDoubleLine("Frost",  fmtPct(s.scritFrost),  0.40, 0.70, 1.00, 1, 1, 1)
        GameTooltip:AddDoubleLine("Shadow", fmtPct(s.scritShadow), 0.65, 0.30, 0.85, 1, 1, 1)
        GameTooltip:AddDoubleLine("Arcane", fmtPct(s.scritArcane), 0.85, 0.40, 0.85, 1, 1, 1)
    end)
    R("shit", "Hit Chance", function()
        local s = WS.stats; if not s then return end
        GameTooltip:AddLine("Spell Hit", 1, 1, 1)
        GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine("Total",         fmtPct(s.shit),        1, 1, 1, C_GREEN[1], C_GREEN[2], C_GREEN[3])
        GameTooltip:AddDoubleLine("From rating",   fmtInt(s.shitRating),  0.7, 0.7, 0.7, 1, 1, 1)
        GameTooltip:AddDoubleLine("From talents",  fmtPct(s.shitFlat),    0.7, 0.7, 0.7, 1, 1, 1)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Soft cap vs. lvl 73 boss: 16%", 0.7, 0.7, 0.7)
    end)
    R("shaste", "Haste", function()
        local s = WS.stats; if not s then return end
        GameTooltip:AddLine("Spell Haste", 1, 1, 1)
        GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine("From rating", fmtPct(s.shaste),       1, 1, 1, C_GREEN[1], C_GREEN[2], C_GREEN[3])
        GameTooltip:AddDoubleLine("Rating",      fmtInt(s.shasteRating), 0.7, 0.7, 0.7, 1, 1, 1)
    end)
    R("spen", "Penetration")

    -- DEFENSES
    S("DEFENSES")
    R("armor", "Armor", function()
        local s = WS.stats; if not s then return end
        GameTooltip:AddLine("Armor", 1, 1, 1)
        GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine("Total",       fmtInt(s.armor),         1, 1, 1, C_GREEN[1], C_GREEN[2], C_GREEN[3])
        GameTooltip:AddDoubleLine("Base + Gear", fmtInt(s.armorBaseGear), 0.7, 0.7, 0.7, 1, 1, 1)
        if s.armorPos > 0 then GameTooltip:AddDoubleLine("Buffs",   "+" .. fmtInt(s.armorPos), 0.7, 0.7, 0.7, 0.31, 0.78, 0.47) end
        if s.armorNeg < 0 then GameTooltip:AddDoubleLine("Debuffs", fmtInt(s.armorNeg),         0.7, 0.7, 0.7, 0.87, 0.45, 0.45) end
        GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine("Reduction vs. lvl 73", fmtPct(s.armorReduction), 0.7, 0.7, 0.7, C_GREEN[1], C_GREEN[2], C_GREEN[3])
    end)
    R("defense", "Defense", function()
        local s = WS.stats; if not s then return end
        GameTooltip:AddLine("Defense", 1, 1, 1)
        GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine("Skill",     fmtInt(s.defense),     1, 1, 1, C_GREEN[1], C_GREEN[2], C_GREEN[3])
        GameTooltip:AddDoubleLine("Base",      fmtInt(s.defenseBase), 0.7, 0.7, 0.7, 1, 1, 1)
        if s.defenseMod ~= 0 then
            GameTooltip:AddDoubleLine("From rating", "+" .. fmtInt(s.defenseMod), 0.7, 0.7, 0.7, 0.31, 0.78, 0.47)
        end
        GameTooltip:AddDoubleLine("Rating",    fmtInt(s.defRating),   0.7, 0.7, 0.7, 1, 1, 1)
        GameTooltip:AddLine(" ")
        local skillVsBoss = s.defense - 350  -- lvl 73 boss = 365 weapon skill, defense cap = 490
        GameTooltip:AddLine("Uncrittable cap: 490 (vs. lvl 73 boss)", 0.7, 0.7, 0.7)
    end)
    R("dodge", "Dodge")
    Rif(WS.showParry, "parry", "Parry")
    Rif(WS.showBlock, "block", "Block")
    Rif(WS.showBlock, "blockValue", "Block Value")
    R("resilience", "Resilience", function()
        local s = WS.stats; if not s then return end
        GameTooltip:AddLine("Resilience", 1, 1, 1)
        GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine("Rating",       fmtInt(s.resilienceRating),     1, 1, 1, C_GREEN[1], C_GREEN[2], C_GREEN[3])
        GameTooltip:AddDoubleLine("Crit reduction", fmtPct(s.resilienceCritReduce), 0.7, 0.7, 0.7, 1, 1, 1)
    end)

    -- RESISTANCES
    S("RESISTANCES")
    R("resHoly",   "Holy")
    R("resFire",   "Fire")
    R("resNature", "Nature")
    R("resFrost",  "Frost")
    R("resShadow", "Shadow")
    R("resArcane", "Arcane")

    -- REGEN
    if WS.showMana then
        S("REGEN")
        R("mp5out", "MP5 (no FSR)")
        R("mp5in",  "MP5 (in FSR)")
    end

    -- WEIGHTS (populated dynamically in Render())
    S("WEIGHTS")
    R("specRow", "Spec", function()
        local _, spec = getActiveWeights()
        GameTooltip:AddLine("Spec", 1, 1, 1)
        GameTooltip:AddLine(" ")
        if spec then
            local label = WS.SPEC_LABELS and WS.SPEC_LABELS[spec] or spec
            GameTooltip:AddLine(label, C_GREEN[1], C_GREEN[2], C_GREEN[3])
        else
            GameTooltip:AddLine("(unknown)", C_TEXT_DIM[1], C_TEXT_DIM[2], C_TEXT_DIM[3])
        end
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Override with /wickstats spec <name>", 0.7, 0.7, 0.7)
        GameTooltip:AddLine("Reset with /wickstats spec auto", 0.7, 0.7, 0.7)
    end)
    for i = 1, 8 do
        local key = "weight" .. i
        R(key, "", weightTooltipFor(key))
    end

    -- BUFF IMPACT (missing raid buffs, populated dynamically)
    S("BUFF IMPACT")
    for i = 1, 12 do
        local key = "buff" .. i
        R(key, "", buffTooltipFor(key))
    end
end

local function buildPanel()
    panel = CreateFrame("Frame", "WicksStatsFrame", UIParent)
    panel:SetFrameStrata("HIGH")
    panel:SetClampedToScreen(true)
    panel:Hide()

    local bg = NewTexture(panel, "BACKGROUND", C_BG)
    bg:SetAllPoints()
    AddBorder(panel, C_BORDER)
    AddCornerAccents(panel)

    -- Title strip
    local title = CreateFrame("Frame", nil, panel)
    title:SetPoint("TOPLEFT",  panel, "TOPLEFT",  1, -1)
    title:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -1, -1)
    title:SetHeight(TITLE_H)
    NewTexture(title, "BACKGROUND", C_HEADER_BG):SetAllPoints()

    -- Two-tone title: "Wick's" fel-green, "Stats" cream. Matches BIS/CD chrome.
    local tApo = NewText(title, 12, C_GREEN)
    tApo:SetPoint("LEFT", title, "LEFT", 10, 0)
    tApo:SetText("Wick's")

    local tName = NewText(title, 12, C_TEXT_NORMAL)
    tName:SetPoint("LEFT", tApo, "RIGHT", 4, 0)
    tName:SetText("Stats")

    -- Close (X) button
    local closeBtn = CreateFrame("Button", nil, title)
    closeBtn:SetSize(22, TITLE_H)
    closeBtn:SetPoint("RIGHT", title, "RIGHT", -2, 0)
    local closeX = closeBtn:CreateFontString(nil, "OVERLAY")
    closeX:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    closeX:SetPoint("CENTER")
    closeX:SetText("×")
    closeX:SetTextColor(C_TEXT_DIM[1], C_TEXT_DIM[2], C_TEXT_DIM[3], 1)
    closeBtn:SetScript("OnEnter", function()
        closeX:SetTextColor(C_GREEN[1], C_GREEN[2], C_GREEN[3], 1)
    end)
    closeBtn:SetScript("OnLeave", function()
        closeX:SetTextColor(C_TEXT_DIM[1], C_TEXT_DIM[2], C_TEXT_DIM[3], 1)
    end)
    closeBtn:SetScript("OnClick", function()
        WicksStatsSettings.userHidden = true
        panel:Hide()
    end)

    -- Options (gear) button -- uses Blizzard's gear texture, vertex-tinted
    local optBtn = CreateFrame("Button", nil, title)
    optBtn:SetSize(22, TITLE_H)
    optBtn:SetPoint("RIGHT", closeBtn, "LEFT", -2, 0)
    local optGear = optBtn:CreateTexture(nil, "OVERLAY")
    optGear:SetTexture("Interface\\Buttons\\UI-OptionsButton")
    optGear:SetSize(14, 14)
    optGear:SetPoint("CENTER")
    optGear:SetVertexColor(C_TEXT_DIM[1], C_TEXT_DIM[2], C_TEXT_DIM[3], 1)
    optBtn:SetScript("OnEnter", function()
        optGear:SetVertexColor(C_GREEN[1], C_GREEN[2], C_GREEN[3], 1)
        GameTooltip:SetOwner(optBtn, "ANCHOR_BOTTOMLEFT")
        GameTooltip:AddLine("Buff tracking options", 1, 1, 1)
        GameTooltip:Show()
    end)
    optBtn:SetScript("OnLeave", function()
        optGear:SetVertexColor(C_TEXT_DIM[1], C_TEXT_DIM[2], C_TEXT_DIM[3], 1)
        GameTooltip:Hide()
    end)
    optBtn:SetScript("OnClick", function()
        if WS.ToggleOptions then WS:ToggleOptions() end
    end)

    local subText = NewText(title, 9, C_TEXT_DIM)
    subText:SetPoint("RIGHT", optBtn, "LEFT", -4, 0)
    subText:SetText(UnitName("player") or "")

    -- "[sim]" tag visible only when raid-buff simulation is on
    local simTag = NewText(title, 9, C_GREEN)
    simTag:SetPoint("RIGHT", subText, "LEFT", -6, 0)
    simTag:SetText("[sim]")
    simTag:Hide()
    panel._simTag = simTag

    -- Build all section headers + row frames (positions applied later by applyLayout)
    for _, section in ipairs(sectionSpecs) do
        local sec = { title = section.title, rowFrames = {} }
        sec.header = CreateSectionHeader(panel, section.title)
        for _, spec in ipairs(section.rows) do
            local r = CreateRow(panel)
            r.label:SetText(spec.label)
            attachTooltip(r, spec.tooltipFn, spec.key)
            rows[spec.key] = r
            table.insert(sec.rowFrames, r)
        end
        table.insert(sections, sec)
    end

    panel:SetWidth(PANEL_W_DEFAULT)
    panel:SetHeight(200)  -- placeholder, applyLayout sets real height

    -- Live-diff baseline: snapshot on show, clear on hide (unless sticky).
    -- Sticky mode keeps the baseline across opens, BUT auto-refreshes if the
    -- player's active buffs have meaningfully changed (so a "stale" baseline
    -- captured under raid buffs doesn't make solo state look like a regression).
    panel:HookScript("OnShow", function()
        if WS.CaptureBaseline then
            local sticky = WicksStatsSettings and WicksStatsSettings.stickyStats
            if not sticky then
                WS:CaptureBaseline()
            elseif not WS:HasBaseline() then
                WS:CaptureBaseline()
            elseif WS.ShouldRefreshBaselineForBuffs and WS:ShouldRefreshBaselineForBuffs() then
                WS:CaptureBaseline()
            end
        end
        WS.dirty = true
    end)
    panel:HookScript("OnHide", function()
        if not (WicksStatsSettings and WicksStatsSettings.stickyStats) then
            if WS.ClearBaseline then WS:ClearBaseline() end
        end
        -- Options window is locked to the main panel; hide it too.
        if optionsFrame then optionsFrame:Hide() end
    end)
end

-- ============================================================
-- render
-- ============================================================
-- ============================================================
-- layout: position section headers and rows for the current panel width
-- ============================================================
local function applyLayout()
    if not panel or #sections == 0 then return end
    local panelW = panel:GetWidth()
    local innerW = panelW - 2 * PADDING
    local numCols = math.max(2, math.floor((innerW + COL_GAP) / (COL_W_TARGET + COL_GAP)))
    local colW = (innerW - (numCols - 1) * COL_GAP) / numCols

    local cursor = -(TITLE_H + 4)
    for _, sec in ipairs(sections) do
        cursor = cursor - SECTION_GAP

        sec.header:ClearAllPoints()
        sec.header:SetPoint("TOPLEFT",  panel, "TOPLEFT",  PADDING, cursor)
        sec.header:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -PADDING, cursor)
        cursor = cursor - SECTION_H - 2

        local n = #sec.rowFrames
        if n > 0 then
            local rowsPerCol = math.ceil(n / numCols)
            for i, rowFrame in ipairs(sec.rowFrames) do
                local col  = math.ceil(i / rowsPerCol)
                local slot = (i - 1) % rowsPerCol
                local x = PADDING + (col - 1) * (colW + COL_GAP)
                local y = cursor - slot * ROW_H
                rowFrame:ClearAllPoints()
                rowFrame:SetPoint("TOPLEFT", panel, "TOPLEFT", x, y)
                rowFrame:SetWidth(colW)
            end
            cursor = cursor - rowsPerCol * ROW_H
        end
    end

    panel:SetHeight(math.abs(cursor) + PADDING)
end
WS._applyLayout = applyLayout

local function setVal(key, text, r, g, b)
    local row = rows[key]
    if not row then return end
    row.value:SetText(text or "--")
    if r then row.value:SetTextColor(r, g, b, 1)
    else row.value:SetTextColor(C_TEXT_NORMAL[1], C_TEXT_NORMAL[2], C_TEXT_NORMAL[3], 1) end
end

local function setAttrVal(key)
    local row = rows[key]; if not row then return end
    local s = WS.stats[key]; if not s then return end
    row.value:SetText(fmtInt(s.total))
    local r, g, b = colorBuff(s.pos, s.neg)
    row.value:SetTextColor(r, g, b, 1)
end

function WS:Render()
    if not panel then return end
    local s = self:Collect()

    if panel._simTag then
        if s._simulated then panel._simTag:Show() else panel._simTag:Hide() end
    end

    setAttrVal("str")
    setAttrVal("agi")
    setAttrVal("sta")
    setAttrVal("int")
    setAttrVal("spi")
    setVal("hp", fmtInt(s.hp))
    setVal("mp", fmtInt(s.mp))

    -- Melee
    do
        local r, g, b = colorBuff(s.apPos, s.apNeg)
        setVal("ap", fmtInt(s.ap), r, g, b)
    end
    setVal("crit",      fmtPct(s.crit))
    setVal("hitMelee",  fmtPct(s.hitMelee))
    setVal("expertise", fmtInt(s.expertise))
    setVal("haste",     fmtPct(s.haste))
    setVal("weaponSkillMH", fmtInt(s.weaponSkillMH))
    setVal("weaponSkillOH", s.weaponSkillOH and s.weaponSkillOH > 0 and fmtInt(s.weaponSkillOH) or "--")
    setVal("atkSpeedMH", fmtSpeed(s.atkSpeedMH))
    setVal("atkSpeedOH", fmtSpeed(s.atkSpeedOH))

    -- Ranged
    do
        local r, g, b = colorBuff(s.rapPos, s.rapNeg)
        setVal("rap", fmtInt(s.rap), r, g, b)
    end
    setVal("rcrit",  fmtPct(s.rcrit))
    setVal("rhit",   fmtPct(s.rhit))
    setVal("rhaste", fmtPct(s.rhaste))

    -- Spell
    local maxSP = math.max(s.spHoly, s.spFire, s.spNature, s.spFrost, s.spShadow, s.spArcane)
    setVal("spMax",   fmtInt(maxSP))
    setVal("healing", fmtInt(s.healing))
    setVal("scrit",   fmtPct(s.scrit))
    setVal("shit",    fmtPct(s.shit))
    setVal("shaste",  fmtPct(s.shaste))
    setVal("spen",    fmtInt(s.spen))

    -- Defenses
    setVal("armor",      fmtInt(s.armor))
    setVal("defense",    fmtInt(s.defense))
    setVal("dodge",      fmtPct(s.dodge))
    setVal("parry",      fmtPct(s.parry))
    setVal("block",      fmtPct(s.block))
    setVal("blockValue", fmtInt(s.blockValue))
    setVal("resilience", fmtInt(s.resilienceRating))

    -- Resistances
    setVal("resHoly",   fmtInt(s.resHoly))
    setVal("resFire",   fmtInt(s.resFire))
    setVal("resNature", fmtInt(s.resNature))
    setVal("resFrost",  fmtInt(s.resFrost))
    setVal("resShadow", fmtInt(s.resShadow))
    setVal("resArcane", fmtInt(s.resArcane))

    -- Regen
    setVal("mp5out", fmtInt(s.mp5out))
    setVal("mp5in",  fmtInt(s.mp5in))

    -- WEIGHTS section
    do
        local active, spec = getActiveWeights()
        if rows.specRow then
            if spec then
                local label = (WS.SPEC_LABELS and WS.SPEC_LABELS[spec]) or spec
                rows.specRow.value:SetText(label)
                rows.specRow.value:SetTextColor(C_GREEN[1], C_GREEN[2], C_GREEN[3], 1)
            else
                rows.specRow.value:SetText("(unknown)")
                rows.specRow.value:SetTextColor(C_TEXT_DIM[1], C_TEXT_DIM[2], C_TEXT_DIM[3], 1)
            end
        end
        if active then
            local list = {}
            for k, v in pairs(active) do
                if type(v) == "number" and not k:match("^_") and k ~= "primary" then
                    table.insert(list, { k = k, v = v })
                end
            end
            table.sort(list, function(a, b) return a.v > b.v end)
            for i = 1, 8 do
                local row = rows["weight" .. i]
                if row then
                    local entry = list[i]
                    if entry then
                        local cap = ""
                        local capDesc
                        if active._hitCapped  and entry.k == "hitRating"  then cap = " (cap)";    capDesc = "Past melee hit cap (~9% / 142 rating vs lvl 73)." end
                        if active._rhitCapped and entry.k == "rhitRating" then cap = " (cap)";    capDesc = "Past ranged hit cap." end
                        if active._shitCapped and entry.k == "shitRating" then cap = " (cap)";    capDesc = "Past spell hit cap." end
                        if active._expCapped  and entry.k == "expRating"  then cap = " (" .. active._expCapped .. " cap)"; capDesc = "Past expertise " .. active._expCapped .. " cap." end
                        if active._defCapped  and entry.k == "defRating"  then cap = " (uncrit)"; capDesc = "Past uncrittable cap (defense 490)." end
                        local label = STAT_LABEL[entry.k] or entry.k
                        row.label:SetText(label .. cap)
                        row.value:SetText(string.format("%.2f", entry.v))
                        if entry.v == 0 then
                            row.value:SetTextColor(C_TEXT_DIM[1], C_TEXT_DIM[2], C_TEXT_DIM[3], 1)
                        else
                            row.value:SetTextColor(C_TEXT_NORMAL[1], C_TEXT_NORMAL[2], C_TEXT_NORMAL[3], 1)
                        end
                        row._weightData = { k = entry.k, v = entry.v, label = label, cap = capDesc }
                    else
                        row.label:SetText("")
                        row.value:SetText("")
                        row._weightData = nil
                    end
                end
            end
        else
            for i = 1, 8 do
                local row = rows["weight" .. i]
                if row then row.label:SetText(""); row.value:SetText("") end
            end
        end
    end

    -- BUFF IMPACT section
    do
        local missing = (WS.DetectMissingBuffs and WS:DetectMissingBuffs()) or {}
        if #missing == 0 and rows.buff1 then
            -- Distinguish "nothing tracked" from "tracked buffs all up"
            local anyEnabled = false
            if WicksStatsSettings and WicksStatsSettings.buffsEnabled then
                for _ in pairs(WicksStatsSettings.buffsEnabled) do
                    anyEnabled = true; break
                end
            end
            if anyEnabled then
                rows.buff1.label:SetText("All tracked buffs active")
                rows.buff1.label:SetTextColor(C_GREEN[1], C_GREEN[2], C_GREEN[3], 1)
            else
                rows.buff1.label:SetText("No buffs tracked")
                rows.buff1.label:SetTextColor(C_TEXT_DIM[1], C_TEXT_DIM[2], C_TEXT_DIM[3], 1)
            end
            rows.buff1.value:SetText("")
            rows.buff1._buffData = nil
            for i = 2, 12 do
                local row = rows["buff" .. i]
                if row then row.label:SetText(""); row.value:SetText(""); row._buffData = nil end
            end
        else
            for i = 1, 12 do
                local row = rows["buff" .. i]
                if not row then break end
                local entry = missing[i]
                if entry then
                    -- Pick the headline gain (largest single absolute number, prefer primary stats)
                    local headline
                    local PRIORITY = { sp = 1, ap = 1, healing = 1, rap = 1,
                        stats_pct = 2, ap_pct = 2,
                        sta = 3, str = 3, agi = 3, int = 3, spi = 3,
                        mp5 = 4, scrit_pct = 4, dmg_pct = 4, allResist = 5,
                        hitRating = 6, sp_target_pct = 7 }
                    local bestPri, bestK, bestV = 999, nil, nil
                    for k, v in pairs(entry.gains) do
                        local p = PRIORITY[k] or 99
                        if p < bestPri then bestPri, bestK, bestV = p, k, v end
                    end
                    if bestK == "stats_pct" then
                        headline = "+" .. bestV .. "% stats"
                    elseif bestK == "ap_pct" then
                        headline = "+" .. bestV .. "% AP"
                    elseif bestK == "scrit_pct" then
                        headline = "+" .. bestV .. "% scrit"
                    elseif bestK == "dmg_pct" then
                        headline = "+" .. bestV .. "% dmg"
                    elseif bestK == "sp_target_pct" then
                        headline = "+" .. bestV .. "% target SP"
                    elseif bestK == "allResist" then
                        headline = "+" .. bestV .. " resist"
                    elseif bestK then
                        headline = "+" .. bestV .. " " .. bestK
                    else
                        headline = "missing"
                    end
                    row.label:SetText(entry.name)
                    row.label:SetTextColor(C_TEXT_DIM[1], C_TEXT_DIM[2], C_TEXT_DIM[3], 1)
                    row.value:SetText(headline)
                    row.value:SetTextColor(C_TEXT_NORMAL[1], C_TEXT_NORMAL[2], C_TEXT_NORMAL[3], 1)
                    row._buffData = entry
                else
                    row.label:SetText("")
                    row.value:SetText("")
                    row._buffData = nil
                end
            end
        end
    end

    -- Live diff coloring: tint stat values that drifted from the baseline
    if WS.HasBaseline and WS:HasBaseline() then
        for rowKey, statKey in pairs(ROW_TO_STAT_KEY) do
            local row = rows[rowKey]
            if row then
                local d = WS:GetBaselineDelta(statKey)
                if d and math.abs(d) > 0.001 then
                    if d > 0 then
                        row.value:SetTextColor(0.40, 0.95, 0.55, 1)  -- bright green
                    else
                        row.value:SetTextColor(0.95, 0.40, 0.40, 1)  -- bright red
                    end
                end
            end
        end
    end
end

-- ============================================================
-- options window: per-buff enable/disable
-- ============================================================
local optionsFrame
local optionsRefreshList = {}  -- registered checkbox refresh callbacks

local function refreshAllOptionsCheckboxes()
    for _, fn in ipairs(optionsRefreshList) do fn() end
end

local function CreateMiniButton(parent, label, onClick)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetHeight(ROW_H)
    local txt = NewText(btn, 9, C_GREEN)
    txt:SetPoint("CENTER", btn, "CENTER", 0, 0)
    txt:SetText(label)
    btn:SetWidth(txt:GetStringWidth() + 16)

    local bg = NewTexture(btn, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(C_HEADER_BG[1], C_HEADER_BG[2], C_HEADER_BG[3], 1)

    -- 1px fel-green border
    local function edge(p1, p2, w, h)
        local t = btn:CreateTexture(nil, "BORDER")
        t:SetColorTexture(C_GREEN[1], C_GREEN[2], C_GREEN[3], 0.6)
        t:SetPoint(p1); t:SetPoint(p2)
        if w then t:SetWidth(w) end; if h then t:SetHeight(h) end
    end
    edge("TOPLEFT","TOPRIGHT", nil, 1)
    edge("BOTTOMLEFT","BOTTOMRIGHT", nil, 1)
    edge("TOPLEFT","BOTTOMLEFT", 1, nil)
    edge("TOPRIGHT","BOTTOMRIGHT", 1, nil)

    btn:SetScript("OnEnter", function()
        bg:SetColorTexture(C_GREEN[1], C_GREEN[2], C_GREEN[3], 0.20)
    end)
    btn:SetScript("OnLeave", function()
        bg:SetColorTexture(C_HEADER_BG[1], C_HEADER_BG[2], C_HEADER_BG[3], 1)
    end)
    btn:SetScript("OnClick", onClick)
    return btn
end

local function CreateOptionsCheckbox(parent, label, isCheckedFn, onToggle)
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(ROW_H)
    row:EnableMouse(true)

    local hover = NewTexture(row, "BACKGROUND")
    hover:SetAllPoints()
    hover:SetColorTexture(0, 0, 0, 0)

    -- Box: outer fel-green border + inner C_BG with check on top
    local cb = CreateFrame("Frame", nil, row)
    cb:SetSize(11, 11)
    cb:SetPoint("LEFT", row, "LEFT", 6, 0)
    local cbBorder = NewTexture(cb, "BACKGROUND")
    cbBorder:SetAllPoints()
    cbBorder:SetColorTexture(C_BORDER[1], C_BORDER[2], C_BORDER[3], 1)
    local cbInner = NewTexture(cb, "BORDER")
    cbInner:SetPoint("TOPLEFT", cb, "TOPLEFT", 1, -1)
    cbInner:SetPoint("BOTTOMRIGHT", cb, "BOTTOMRIGHT", -1, 1)
    cbInner:SetColorTexture(C_BG[1], C_BG[2], C_BG[3], 1)
    local cbCheck = NewTexture(cb, "OVERLAY")
    cbCheck:SetPoint("TOPLEFT", cb, "TOPLEFT", 2, -2)
    cbCheck:SetPoint("BOTTOMRIGHT", cb, "BOTTOMRIGHT", -2, 2)
    cbCheck:SetColorTexture(C_GREEN[1], C_GREEN[2], C_GREEN[3], 1)

    local lbl = NewText(row, 10, C_TEXT_NORMAL)
    lbl:SetPoint("LEFT", cb, "RIGHT", 6, 0)
    lbl:SetText(label)

    local function refresh()
        if isCheckedFn() then cbCheck:Show() else cbCheck:Hide() end
        if isCheckedFn() then
            lbl:SetTextColor(C_TEXT_NORMAL[1], C_TEXT_NORMAL[2], C_TEXT_NORMAL[3], 1)
        else
            lbl:SetTextColor(C_TEXT_DIM[1], C_TEXT_DIM[2], C_TEXT_DIM[3], 1)
        end
    end
    refresh()
    table.insert(optionsRefreshList, refresh)

    row:SetScript("OnEnter", function() SetRGBA(hover, C_ROW_HOVER) end)
    row:SetScript("OnLeave", function() hover:SetColorTexture(0, 0, 0, 0) end)
    row:SetScript("OnMouseUp", function(_, button)
        if button == "LeftButton" then
            onToggle()
            refresh()
        end
    end)

    return row
end

local function buildOptionsWindow()
    if optionsFrame then return optionsFrame end

    local OPT_W = 280
    local f = CreateFrame("Frame", "WicksStatsOptionsFrame", UIParent)
    f:SetFrameStrata("HIGH")
    f:SetWidth(OPT_W)
    f:Hide()

    local bg = NewTexture(f, "BACKGROUND", C_BG)
    bg:SetAllPoints()
    AddBorder(f, C_BORDER)
    AddCornerAccents(f)

    -- Title strip (locked, no drag — position is anchored to main panel)
    local title = CreateFrame("Frame", nil, f)
    title:SetPoint("TOPLEFT",  f, "TOPLEFT",  1, -1)
    title:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, -1)
    title:SetHeight(TITLE_H)
    NewTexture(title, "BACKGROUND", C_HEADER_BG):SetAllPoints()

    local tApo = NewText(title, 12, C_GREEN)
    tApo:SetPoint("LEFT", title, "LEFT", 10, 0)
    tApo:SetText("Wick's")
    local tName = NewText(title, 12, C_TEXT_NORMAL)
    tName:SetPoint("LEFT", tApo, "RIGHT", 4, 0)
    tName:SetText("Stats / Buffs")

    local closeBtn = CreateFrame("Button", nil, title)
    closeBtn:SetSize(22, TITLE_H)
    closeBtn:SetPoint("RIGHT", title, "RIGHT", -2, 0)
    local closeX = closeBtn:CreateFontString(nil, "OVERLAY")
    closeX:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    closeX:SetPoint("CENTER")
    closeX:SetText("×")
    closeX:SetTextColor(C_TEXT_DIM[1], C_TEXT_DIM[2], C_TEXT_DIM[3], 1)
    closeBtn:SetScript("OnEnter", function()
        closeX:SetTextColor(C_GREEN[1], C_GREEN[2], C_GREEN[3], 1)
    end)
    closeBtn:SetScript("OnLeave", function()
        closeX:SetTextColor(C_TEXT_DIM[1], C_TEXT_DIM[2], C_TEXT_DIM[3], 1)
    end)
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    -- Scrollable body: ScrollFrame + content child. Mouse wheel scrolling, no
    -- visible scrollbar (Blizzard's default scrollbar texture would clash).
    local scroll = CreateFrame("ScrollFrame", nil, f)
    scroll:SetPoint("TOPLEFT",  f, "TOPLEFT",  1, -(TITLE_H + 1))
    scroll:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -1, 1)
    scroll:EnableMouseWheel(true)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(OPT_W - 2, 1)  -- height set after rows are placed
    scroll:SetScrollChild(content)

    scroll:SetScript("OnMouseWheel", function(self, delta)
        local newY = (self:GetVerticalScroll() or 0) - delta * 30
        local maxY = math.max(0, content:GetHeight() - self:GetHeight())
        if newY < 0 then newY = 0 end
        if newY > maxY then newY = maxY end
        self:SetVerticalScroll(newY)
    end)

    -- Body: group buffs by category
    local categories, byCat = {}, {}
    for _, b in ipairs(WS.BUFFS or {}) do
        if not byCat[b.category] then
            byCat[b.category] = {}
            table.insert(categories, b.category)
        end
        table.insert(byCat[b.category], b)
    end

    local cursor = 0

    -- Bulk-action row
    cursor = cursor - SECTION_GAP
    do
        local row = CreateFrame("Frame", nil, content)
        row:SetHeight(ROW_H + 4)
        row:SetPoint("TOPLEFT",  content, "TOPLEFT",  PADDING, cursor)
        row:SetPoint("TOPRIGHT", content, "TOPRIGHT", -PADDING, cursor)

        local b1 = CreateMiniButton(row, "Match current", function()
            WS:MatchEnabledToCurrent()
            refreshAllOptionsCheckboxes()
            WS.dirty = true
        end)
        b1:SetPoint("LEFT", row, "LEFT", 0, 0)

        local b2 = CreateMiniButton(row, "Enable all", function()
            WS:SetAllBuffsEnabled(true)
            refreshAllOptionsCheckboxes()
            WS.dirty = true
        end)
        b2:SetPoint("LEFT", b1, "RIGHT", 6, 0)

        local b3 = CreateMiniButton(row, "Clear all", function()
            WS:SetAllBuffsEnabled(false)
            refreshAllOptionsCheckboxes()
            WS.dirty = true
        end)
        b3:SetPoint("LEFT", b2, "RIGHT", 6, 0)

        cursor = cursor - ROW_H - 6
    end

    -- "Simulate raid buffs" master toggle (above category list)
    cursor = cursor - SECTION_GAP
    do
        local h = CreateFrame("Frame", nil, content)
        h:SetHeight(SECTION_H)
        h:SetPoint("TOPLEFT",  content, "TOPLEFT",  PADDING, cursor)
        h:SetPoint("TOPRIGHT", content, "TOPRIGHT", -PADDING, cursor)
        NewTexture(h, "BACKGROUND", C_HEADER_BG):SetAllPoints()
        local lbl = NewText(h, 10, C_GREEN)
        lbl:SetPoint("LEFT", h, "LEFT", 8, 0)
        lbl:SetText("PREVIEW")
        cursor = cursor - SECTION_H - 2

        local row = CreateOptionsCheckbox(content, "Simulate raid buffs",
            function() return WicksStatsSettings.simulateRaidBuffs end,
            function()
                WicksStatsSettings.simulateRaidBuffs = not WicksStatsSettings.simulateRaidBuffs
                WS.dirty = true
            end)
        row:SetPoint("TOPLEFT",  content, "TOPLEFT",  PADDING, cursor)
        row:SetPoint("TOPRIGHT", content, "TOPRIGHT", -PADDING, cursor)
        cursor = cursor - ROW_H

        -- Sticky stats: keep diff baseline across panel close/reopen
        local stickyRow = CreateOptionsCheckbox(content, "Sticky stats (persist diff baseline)",
            function() return WicksStatsSettings.stickyStats end,
            function()
                WicksStatsSettings.stickyStats = not WicksStatsSettings.stickyStats
                WS.dirty = true
            end)
        stickyRow:SetPoint("TOPLEFT",  content, "TOPLEFT",  PADDING, cursor)
        stickyRow:SetPoint("TOPRIGHT", content, "TOPRIGHT", -PADDING, cursor)
        cursor = cursor - ROW_H

        -- Reset baseline button (forces a fresh snapshot now)
        local resetRow = CreateFrame("Frame", nil, content)
        resetRow:SetHeight(ROW_H + 2)
        resetRow:SetPoint("TOPLEFT",  content, "TOPLEFT",  PADDING, cursor)
        resetRow:SetPoint("TOPRIGHT", content, "TOPRIGHT", -PADDING, cursor)
        local resetBtn = CreateMiniButton(resetRow, "Reset baseline", function()
            if WS.CaptureBaseline then WS:CaptureBaseline() end
            WS.dirty = true
        end)
        resetBtn:SetPoint("LEFT", resetRow, "LEFT", 22, 0)
        cursor = cursor - ROW_H - 4
    end

    for _, cat in ipairs(categories) do
        cursor = cursor - SECTION_GAP

        local h = CreateFrame("Frame", nil, content)
        h:SetHeight(SECTION_H)
        h:SetPoint("TOPLEFT",  content, "TOPLEFT",  PADDING, cursor)
        h:SetPoint("TOPRIGHT", content, "TOPRIGHT", -PADDING, cursor)
        NewTexture(h, "BACKGROUND", C_HEADER_BG):SetAllPoints()
        local lbl = NewText(h, 10, C_GREEN)
        lbl:SetPoint("LEFT", h, "LEFT", 8, 0)
        lbl:SetText(cat:upper())
        cursor = cursor - SECTION_H - 2

        for _, b in ipairs(byCat[cat]) do
            local buffName = b.name
            local row = CreateOptionsCheckbox(content, buffName,
                function() return WS:IsBuffEnabled(buffName) end,
                function()
                    WS:SetBuffEnabled(buffName, not WS:IsBuffEnabled(buffName))
                    WS.dirty = true
                end)
            row:SetPoint("TOPLEFT",  content, "TOPLEFT",  PADDING, cursor)
            row:SetPoint("TOPRIGHT", content, "TOPRIGHT", -PADDING, cursor)
            cursor = cursor - ROW_H
        end
    end

    -- Set sizes: content height fits all rows; frame height capped to main panel.
    local contentH = math.abs(cursor) + PADDING
    content:SetHeight(contentH)
    local mainH = (panel and panel:GetHeight()) or 600
    f:SetHeight(math.min(mainH, contentH + TITLE_H + 4))

    optionsFrame = f
    return f
end

function WS:ToggleOptions()
    local f = buildOptionsWindow()
    if f:IsShown() then
        f:Hide()
        return
    end
    f:ClearAllPoints()
    if panel then
        f:SetPoint("TOPLEFT", panel, "TOPRIGHT", 4, 0)
    else
        f:SetPoint("CENTER", UIParent, "CENTER", 240, 0)
    end
    f:Show()
end

-- ============================================================
-- character frame integration
-- ============================================================
local function HookCharacterFrame()
    if not CharacterFrame then return end
    if WS._hooked then return end
    WS._hooked = true

    panel:SetParent(CharacterFrame)
    panel:ClearAllPoints()
    panel:SetPoint("TOPLEFT", CharacterFrame, "TOPRIGHT", -34, -12)

    CharacterFrame:HookScript("OnShow", function()
        if not WicksStatsSettings.userHidden then
            panel:Show()
            WS.dirty = true
        end
    end)
    CharacterFrame:HookScript("OnHide", function()
        panel:Hide()
    end)

    if CharacterFrame:IsShown() and not WicksStatsSettings.userHidden then
        panel:Show()
        WS.dirty = true
    end
end

function WS:Toggle()
    if not panel then return end
    WicksStatsSettings.userHidden = not WicksStatsSettings.userHidden
    if WicksStatsSettings.userHidden then
        panel:Hide()
    else
        if CharacterFrame and CharacterFrame:IsShown() then
            panel:Show()
            WS.dirty = true
        else
            ShowUIPanel(CharacterFrame)
        end
    end
end

-- ============================================================
-- bootstrap
-- ============================================================
function WS:OnLogin()
    WicksStatsSettings = WicksStatsSettings or {}
    if WicksStatsSettings.userHidden == nil then WicksStatsSettings.userHidden = false end

    buildSpecs()
    buildPanel()
    HookCharacterFrame()

    -- Width is fixed; layout fits height to the actual row count
    applyLayout()

    self.dirty = true
    panel:SetScript("OnUpdate", function(self, elapsed)
        if not self:IsShown() then return end
        WS._next = (WS._next or 0) - elapsed
        if WS.dirty and WS._next <= 0 then
            WS:Render()
            WS.dirty = false
            WS._next = 0.2
        end
    end)
end
