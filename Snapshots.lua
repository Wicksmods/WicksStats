-- Wick's Stats
-- Snapshots.lua: capture, save, list, and diff stat snapshots
--
-- Stored in WicksStatsSettings.snapshots = { [name] = { ts, stats } }
-- A snapshot is the entire WS.stats table at capture time.

local WS = WicksStats

-- Stats fields we capture for diffing. Anything not in this list is ignored
-- (e.g., transient buff/debuff metadata that wouldn't diff cleanly).
local DIFF_FIELDS = {
    "hp", "mp", "ap", "crit", "hitMelee", "hitMeleeRating",
    "expertise", "expRating", "haste", "hasteRating",
    "rap", "rcrit", "rhit", "rhitRating", "rhaste",
    "spHoly", "spFire", "spNature", "spFrost", "spShadow", "spArcane",
    "healing", "scrit", "shit", "shitRating", "shaste", "shasteRating",
    "spen", "armor", "defense", "defRating",
    "dodge", "dodgeRating", "parry", "parryRating", "block", "blockRating",
    "blockValue", "resilienceRating",
    "resHoly", "resFire", "resNature", "resFrost", "resShadow", "resArcane",
    "mp5out", "mp5in",
}
-- Attribute fields stored as { total, baseGear, pos, neg } structs
local DIFF_ATTRS = { "str", "agi", "sta", "int", "spi" }

local function snapshotFromStats(s)
    local snap = { ts = time(), v = {} }
    for _, k in ipairs(DIFF_FIELDS) do
        snap.v[k] = s[k]
    end
    for _, k in ipairs(DIFF_ATTRS) do
        local a = s[k]
        if a then
            snap.v[k] = { total = a.total, baseGear = a.baseGear, pos = a.pos, neg = a.neg }
        end
    end
    return snap
end

function WS:SaveSnapshot(name)
    if not name or name == "" then return false, "name required" end
    WicksStatsSettings.snapshots = WicksStatsSettings.snapshots or {}
    if not self.stats then self:Collect() end
    WicksStatsSettings.snapshots[name] = snapshotFromStats(self.stats)
    return true
end

function WS:DeleteSnapshot(name)
    if not WicksStatsSettings.snapshots then return false end
    if WicksStatsSettings.snapshots[name] then
        WicksStatsSettings.snapshots[name] = nil
        return true
    end
    return false
end

function WS:ListSnapshots()
    local out = {}
    if not WicksStatsSettings.snapshots then return out end
    for name, snap in pairs(WicksStatsSettings.snapshots) do
        table.insert(out, { name = name, ts = snap.ts })
    end
    table.sort(out, function(a, b) return a.ts > b.ts end)
    return out
end

-- Diff against a saved snapshot. Returns a table of { key, oldVal, newVal, delta }
-- for stats that changed.
function WS:DiffSnapshot(name)
    if not WicksStatsSettings.snapshots or not WicksStatsSettings.snapshots[name] then
        return nil
    end
    local snap = WicksStatsSettings.snapshots[name]
    if not self.stats then self:Collect() end

    local diffs = {}
    for _, k in ipairs(DIFF_FIELDS) do
        local oldV = snap.v[k] or 0
        local newV = self.stats[k] or 0
        if math.abs(newV - oldV) > 0.001 then
            table.insert(diffs, { key = k, old = oldV, new = newV, delta = newV - oldV })
        end
    end
    for _, k in ipairs(DIFF_ATTRS) do
        local oldA = snap.v[k]
        local newA = self.stats[k]
        if oldA and newA then
            local delta = (newA.total or 0) - (oldA.total or 0)
            if math.abs(delta) > 0.001 then
                table.insert(diffs, { key = k, old = oldA.total, new = newA.total, delta = delta, attr = true })
            end
        end
    end
    return { name = name, ts = snap.ts, diffs = diffs }
end

-- Slash command handlers (registered from Core.lua)
function WS:HandleSnapshotCommand(args)
    args = args or ""
    local op, rest = args:match("^(%S+)%s*(.*)$")
    op = op and op:lower() or "list"

    if op == "save" then
        local name = (rest or ""):gsub("^%s*(.-)%s*$", "%1")
        if name == "" then
            print("|cff4FC778Wick's Stats|r: usage `/wickstats snap save <name>`")
            return
        end
        local ok, err = self:SaveSnapshot(name)
        if ok then
            print(string.format("|cff4FC778Wick's Stats|r: saved snapshot |cffD4C8A1%s|r", name))
        else
            print("|cff4FC778Wick's Stats|r: " .. (err or "save failed"))
        end
    elseif op == "list" or op == "ls" then
        local list = self:ListSnapshots()
        if #list == 0 then
            print("|cff4FC778Wick's Stats|r: no snapshots. `/wickstats snap save <name>` to create one.")
            return
        end
        print("|cff4FC778Wick's Stats|r snapshots:")
        for _, s in ipairs(list) do
            print(string.format("  |cffD4C8A1%s|r - %s", s.name, date("%Y-%m-%d %H:%M", s.ts)))
        end
    elseif op == "diff" or op == "d" then
        local name = (rest or ""):gsub("^%s*(.-)%s*$", "%1")
        if name == "" then
            print("|cff4FC778Wick's Stats|r: usage `/wickstats snap diff <name>`")
            return
        end
        local d = self:DiffSnapshot(name)
        if not d then
            print(string.format("|cff4FC778Wick's Stats|r: no snapshot named |cffD4C8A1%s|r", name))
            return
        end
        if #d.diffs == 0 then
            print(string.format("|cff4FC778Wick's Stats|r: no changes since |cffD4C8A1%s|r", name))
            return
        end
        print(string.format("|cff4FC778Wick's Stats|r diff vs |cffD4C8A1%s|r:", name))
        table.sort(d.diffs, function(a, b) return math.abs(a.delta) > math.abs(b.delta) end)
        for _, c in ipairs(d.diffs) do
            local sign = c.delta > 0 and "|cff50fa7b+" or "|cffff5555"
            print(string.format("  %s%s|r  %s  (%.1f -> %.1f)", sign, string.format("%+.2f", c.delta), c.key, c.old, c.new))
        end
    elseif op == "rm" or op == "delete" or op == "del" then
        local name = (rest or ""):gsub("^%s*(.-)%s*$", "%1")
        if self:DeleteSnapshot(name) then
            print(string.format("|cff4FC778Wick's Stats|r: deleted |cffD4C8A1%s|r", name))
        else
            print("|cff4FC778Wick's Stats|r: snapshot not found")
        end
    else
        print("|cff4FC778Wick's Stats|r snap commands: save <name> | list | diff <name> | rm <name>")
    end
end
