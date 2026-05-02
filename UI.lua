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

local PANEL_W      = 480
local TITLE_H      = 28
local SECTION_H    = 20
local ROW_H        = 17
local SECTION_GAP  = 6
local PADDING      = 8
local COL_GAP      = 10
local COL_W        = (PANEL_W - 2 * PADDING - COL_GAP) / 2

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
-- panel scaffolding
-- ============================================================
local panel
local rows = {}    -- key -> row frame
local sections = {}

local function CreateRow(parent, yOffset, col)
    -- col: 1 = left, 2 = right
    local r = CreateFrame("Frame", nil, parent)
    r:SetSize(COL_W, ROW_H)
    local xOffset = (col == 2) and (PADDING + COL_W + COL_GAP) or PADDING
    r:SetPoint("TOPLEFT", parent, "TOPLEFT", xOffset, yOffset)

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

local function CreateSectionHeader(parent, yOffset, title)
    local h = CreateFrame("Frame", nil, parent)
    h:SetSize(PANEL_W - 2 * PADDING, SECTION_H)
    h:SetPoint("TOPLEFT", parent, "TOPLEFT", PADDING, yOffset)

    local bg = NewTexture(h, "BACKGROUND", C_HEADER_BG)
    bg:SetAllPoints()

    local txt = NewText(h, 10, C_GREEN)
    txt:SetPoint("LEFT", h, "LEFT", 8, 0)
    txt:SetText(title)
    h.label = txt
    return h
end

local function attachTooltip(row, fn)
    row:EnableMouse(true)
    row:SetScript("OnEnter", function(self)
        SetRGBA(self.hover, C_ROW_HOVER)
        if fn then
            GameTooltip:SetOwner(self, "ANCHOR_LEFT")
            fn()
            GameTooltip:Show()
        end
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

    local tText = NewText(title, 12, C_GREEN)
    tText:SetPoint("LEFT", title, "LEFT", 10, 0)
    tText:SetText("WICK'S STATS")

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

    local subText = NewText(title, 9, C_TEXT_DIM)
    subText:SetPoint("RIGHT", closeBtn, "LEFT", -4, 0)
    subText:SetText(UnitName("player") or "")

    -- Build sections + 2-column rows
    local cursor = -(TITLE_H + 4)
    for _, section in ipairs(sectionSpecs) do
        cursor = cursor - SECTION_GAP
        local h = CreateSectionHeader(panel, cursor, section.title)
        table.insert(sections, h)
        cursor = cursor - SECTION_H - 2

        local n = #section.rows
        if n > 0 then
            local leftCount = math.ceil(n / 2)
            local rowsTop = cursor
            for i, spec in ipairs(section.rows) do
                local col, slot
                if i <= leftCount then
                    col, slot = 1, i - 1
                else
                    col, slot = 2, i - leftCount - 1
                end
                local y = rowsTop - slot * ROW_H
                local r = CreateRow(panel, y, col)
                r.label:SetText(spec.label)
                if spec.tooltipFn then attachTooltip(r, spec.tooltipFn) end
                rows[spec.key] = r
            end
            cursor = rowsTop - leftCount * ROW_H
        end
    end

    panel:SetSize(PANEL_W, math.abs(cursor) + PADDING)

    -- Resize grip (drag bottom-right corner to scale)
    local grip = CreateFrame("Frame", nil, panel)
    grip:SetSize(14, 14)
    grip:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", 0, 0)
    grip:EnableMouse(true)
    grip:SetFrameLevel(panel:GetFrameLevel() + 5)

    local hint = grip:CreateTexture(nil, "OVERLAY")
    hint:SetAllPoints()
    hint:SetColorTexture(C_GREEN[1], C_GREEN[2], C_GREEN[3], 0)

    grip:SetScript("OnEnter", function()
        hint:SetColorTexture(C_GREEN[1], C_GREEN[2], C_GREEN[3], 0.30)
        SetCursor("Interface\\Cursor\\UI-Cursor-Size")
    end)
    grip:SetScript("OnLeave", function()
        hint:SetColorTexture(C_GREEN[1], C_GREEN[2], C_GREEN[3], 0)
        SetCursor(nil)
    end)
    grip:SetScript("OnMouseDown", function(self, button)
        if button ~= "LeftButton" then return end
        self._dragging = true
        self._startScale = panel:GetScale()
        self._startW = panel:GetWidth()
        self._startH = panel:GetHeight()
        local mx, my = GetCursorPosition()
        self._startMX, self._startMY = mx, my
    end)
    grip:SetScript("OnMouseUp", function(self, button)
        if not self._dragging then return end
        self._dragging = false
        WicksStatsSettings.scale = panel:GetScale()
    end)
    grip:SetScript("OnUpdate", function(self)
        if not self._dragging then return end
        local mx, my = GetCursorPosition()
        local uiScale = UIParent:GetEffectiveScale()
        local dx = (mx - self._startMX) / uiScale
        local dy = (self._startMY - my) / uiScale
        local addX = dx / self._startW
        local addY = dy / self._startH
        local add = (addX + addY) / 2
        local newScale = math.max(0.7, math.min(1.8, self._startScale + add))
        panel:SetScale(newScale)
    end)
end

-- ============================================================
-- render
-- ============================================================
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

    if WicksStatsSettings.scale then
        panel:SetScale(WicksStatsSettings.scale)
    end

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
