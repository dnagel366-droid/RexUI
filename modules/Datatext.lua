-- =========================================================
-- RexUI modules/Datatext.lua (FINAL)
-- 3 Slots als Boxen (left / center / right)
-- - Lock/Unlock: Lock AUS => Drag + grüner Rahmen
-- - Mouseover: sichtbar nur bei Hover (auch über Minimap)
-- - Breite: Minimap-basiert oder feste Breite
-- - Offsets X/Y nur im Minimap-Modus (wenn nicht custom gezogen)
-- - Custom Position speichert point/relPoint/x/y + useCustomPos=true
-- - Spacing zwischen Boxen (0 möglich)
-- =========================================================

local _G = _G
local floor = math.floor
local format = string.format

local SLOT_KEYS = { "left", "center", "right" }

-- ---------------------------------------------------------
-- DB helper (passt zu deiner Config)
-- ---------------------------------------------------------
local function GetDB()
    local p = _G.RexUI_GetDB and _G.RexUI_GetDB()
    if not p then return nil end

    p.datatext = p.datatext or {}
    local db = p.datatext

    if db.enabled == nil then db.enabled = true end
    if db.lock == nil then db.lock = true end
    if db.mouseover == nil then db.mouseover = false end

    if db.matchMinimapWidth == nil then db.matchMinimapWidth = true end
    if db.width == nil then db.width = 220 end
    if db.height == nil then db.height = 22 end
    if db.spacing == nil then db.spacing = 0 end
    if db.offsetX == nil then db.offsetX = 0 end
    if db.offsetY == nil then db.offsetY = -6 end

    if db.useCustomPos == nil then db.useCustomPos = false end

    if db.alpha == nil then db.alpha = 0.90 end
    if db.fontSize == nil then db.fontSize = 12 end
    if db.bgColor == nil then db.bgColor = { 0, 0, 0 } end
    if db.borderSize == nil then db.borderSize = 1 end
    if db.borderColor == nil then db.borderColor = { 0.20, 0.20, 0.20, 1.00 } end

    db.slots = db.slots or {}
    db.slots.left   = db.slots.left   or { mode = "durability" }
    db.slots.center = db.slots.center or { mode = "none" }
    db.slots.right  = db.slots.right  or { mode = "time" }

    return db
end

-- ---------------------------------------------------------
-- Frame refs
-- ---------------------------------------------------------
local Anchor
local Boxes = {} -- [1..3] Buttons

-- ---------------------------------------------------------
-- Data helpers
-- ---------------------------------------------------------
local function GetDurabilityPercent()
    local total, current = 0, 0
    for slot = 1, 18 do
        local c, t = GetInventoryItemDurability(slot)
        if c and t and t > 0 then
            current = current + c
            total   = total + t
        end
    end
    if total <= 0 then return nil end
    return floor((current / total) * 100 + 0.5)
end

local function GetFreeBagSlots()
    local free = 0
    if C_Container and C_Container.GetContainerNumFreeSlots then
        for i = 0, NUM_BAG_SLOTS do
            free = free + (C_Container.GetContainerNumFreeSlots(i) or 0)
        end
    elseif GetContainerNumFreeSlots then
        for i = 0, NUM_BAG_SLOTS do
            free = free + (GetContainerNumFreeSlots(i) or 0)
        end
    end
    return free
end

local function TextForMode(mode)
    if mode == "none" then return "" end

    if mode == "fps" then
        return floor((GetFramerate() or 0) + 0.5) .. " |cff00ff00FPS|r"

    elseif mode == "ms" then
        local _, _, _, lagWorld = GetNetStats()
        return (lagWorld or 0) .. " |cff00ff00MS|r"

    elseif mode == "time" then
        local h, m = GetGameTime()
        return format("%02d:%02d", h, m)

    elseif mode == "durability" then
        local p = GetDurabilityPercent()
        if not p then return "Dur: -" end
        return format("Dur: %d%%", p)

    elseif mode == "bags" then
        return "Bags: " .. GetFreeBagSlots()

    elseif mode == "gold" then
        local money = GetMoney and GetMoney() or 0
        return format("%dg", floor(money / 10000))

    elseif mode == "guild" then
        if not IsInGuild() then return "No Guild" end
        return (GetGuildInfo("player") or "Guild")
    end

    return tostring(mode or "")
end

local function ClickForMode(mode)
    if mode == "ms" and StatsFrame then ToggleFrame(StatsFrame) return end
    if mode == "durability" then ToggleCharacter("PaperDollFrame") return end
    if mode == "bags" then ToggleAllBags() return end
    if mode == "gold" then ToggleCharacter("TokenFrame") return end
    if mode == "guild" then ToggleGuildFrame() return end
    if mode == "time" and TimeManagerFrame then ToggleFrame(TimeManagerFrame) return end
end

-- ---------------------------------------------------------
-- Mouseover
-- ---------------------------------------------------------
local function ApplyMouseover()
    local db = GetDB()
    if not db or not Anchor then return end

    Anchor:SetScript("OnEnter", nil)
    Anchor:SetScript("OnLeave", nil)

    -- nicht jedes Mal Minimap-Hooks neu setzen (nur einmal)
    if not Anchor._rexuiMinimapHooked and _G.Minimap then
        Anchor._rexuiMinimapHooked = true
        Minimap:HookScript("OnEnter", function()
            local d = GetDB()
            if d and d.mouseover and d.lock ~= false and Anchor then
                Anchor:SetAlpha(1)
            end
        end)
        Minimap:HookScript("OnLeave", function()
            local d = GetDB()
            if d and d.mouseover and d.lock ~= false and Anchor then
                Anchor:SetAlpha(0)
            end
        end)
    end

    if db.mouseover and db.lock ~= false then
        Anchor:SetAlpha(0)
        Anchor:SetScript("OnEnter", function() Anchor:SetAlpha(1) end)
        Anchor:SetScript("OnLeave", function() Anchor:SetAlpha(0) end)
    else
        Anchor:SetAlpha(1)
    end
end

-- ---------------------------------------------------------
-- Lock / Edit mode
-- ---------------------------------------------------------
function RexUI_UpdateDatatextLock()
    local db = GetDB()
    if not db or not Anchor then return end

    if db.lock == false then
        -- Edit Mode
        Anchor:EnableMouse(true)
        Anchor:SetMovable(true)
        Anchor._editBorder:Show()

        -- Boxen nicht klickbar, damit Drag sicher klappt
        for i=1,3 do
            if Boxes[i] then Boxes[i]:EnableMouse(false) end
        end
    else
        -- Locked
        Anchor:SetMovable(false)
        Anchor:EnableMouse(true) -- für Mouseover
        Anchor._editBorder:Hide()

        for i=1,3 do
            if Boxes[i] then Boxes[i]:EnableMouse(true) end
        end
    end

    ApplyMouseover()
end
_G.RexUI_UpdateDatatextLock = RexUI_UpdateDatatextLock

-- ---------------------------------------------------------
-- Layout + Apply
-- ---------------------------------------------------------
local function ActiveKeys(db)
    local list = {}
    for _, key in ipairs(SLOT_KEYS) do
        local mode = (db.slots[key] and db.slots[key].mode) or "none"
        if mode ~= "none" then
            table.insert(list, key)
        end
    end
    return list
end

function RexUI_ApplyDatatext()
    local db = GetDB()
    if not db or not Anchor then return end

    if db.enabled == false then
        Anchor:Hide()
        return
    end
    Anchor:Show()

    -- Position:
    -- - wenn custom gezogen => gespeicherte point/relPoint/x/y
    -- - sonst => unter Minimap (TOPLEFT->BOTTOMLEFT) mit offsetX/offsetY
    if db.useCustomPos and db.point and db.relPoint and db.x and db.y then
        Anchor:ClearAllPoints()
        Anchor:SetPoint(db.point, UIParent, db.relPoint, db.x, db.y)
    else
        Anchor:ClearAllPoints()
        if Minimap then
            Anchor:SetPoint("TOPLEFT", Minimap, "BOTTOMLEFT", db.offsetX or 0, db.offsetY or -6)
        else
            Anchor:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 20, 60)
        end
    end

    -- Breite bestimmen
    local targetW = db.width or 220
    if db.matchMinimapWidth ~= false and Minimap and Minimap.GetWidth then
        targetW = Minimap:GetWidth()
    end

    local h = db.height or 22
    Anchor:SetSize(targetW, h)

    -- aktive Slots
    local active = ActiveKeys(db)
    local n = #active
    if n == 0 then
        for i=1,3 do Boxes[i]:Hide() end
        RexUI_UpdateDatatextLock()
        return
    end

    local spacing = db.spacing or 0
    local totalSpacing = spacing * (n - 1)
    local eachW = floor((targetW - totalSpacing) / n)
    if eachW < 20 then eachW = 20 end

    -- Look
    local bg = db.bgColor or {0,0,0}
    local a  = db.alpha or 0.9
    local bc = db.borderColor or {0.2,0.2,0.2,1}
    local bs = db.borderSize or 1
    local fs = db.fontSize or 12

    local x = 0
    for pos, key in ipairs(active) do
        local mode = (db.slots[key] and db.slots[key].mode) or "none"

        -- box index mapping: left=1 center=2 right=3
        local idx = (key == "left" and 1) or (key == "center" and 2) or 3
        local b = Boxes[idx]

        b:Show()
        b:ClearAllPoints()
        b:SetPoint("LEFT", Anchor, "LEFT", x, 0)
        b:SetSize(eachW, h)

        b:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = bs,
        })
        b:SetBackdropColor(bg[1] or 0, bg[2] or 0, bg[3] or 0, a)
        b:SetBackdropBorderColor(bc[1] or 0.2, bc[2] or 0.2, bc[3] or 0.2, bc[4] or 1)

        b.Text:SetFont(STANDARD_TEXT_FONT, fs, "OUTLINE")
        b.Text:SetText(TextForMode(mode))

        b:SetScript("OnClick", function()
            local d = GetDB()
            if not d then return end
            local m = (d.slots[key] and d.slots[key].mode) or "none"
            if m ~= "none" then ClickForMode(m) end
        end)

        x = x + eachW
        if pos < n then x = x + spacing end
    end

    -- inaktive Boxen ausblenden
    for i=1,3 do
        local key = SLOT_KEYS[i]
        local mode = (db.slots[key] and db.slots[key].mode) or "none"
        if mode == "none" then
            Boxes[i]:Hide()
        end
    end

    RexUI_UpdateDatatextLock()
end
_G.RexUI_ApplyDatatext = RexUI_ApplyDatatext

-- ---------------------------------------------------------
-- Init
-- ---------------------------------------------------------
function RexUI_InitDatatext()
    if Anchor then return end

    local db = GetDB()
    if not db then return end

    Anchor = CreateFrame("Frame", "RexUI_DatatextAnchor", UIParent, "BackdropTemplate")
    Anchor:SetFrameStrata("HIGH")
    Anchor:SetClampedToScreen(true)
    Anchor:SetMovable(true)
    Anchor:EnableMouse(true)

    -- grüner Rahmen (Edit Mode)
    local eb = CreateFrame("Frame", nil, Anchor, "BackdropTemplate")
    eb:SetAllPoints()
    eb:SetBackdrop({ edgeFile="Interface\\Buttons\\WHITE8x8", edgeSize=2 })
    eb:SetBackdropBorderColor(0,1,0,1)
    eb:Hide()
    Anchor._editBorder = eb

    -- Drag nur wenn Lock AUS
    Anchor:RegisterForDrag("LeftButton")
    Anchor:SetScript("OnDragStart", function(self)
        local d = GetDB()
        if not d or d.lock ~= false then return end
        self:StartMoving()
    end)
    Anchor:SetScript("OnDragStop", function(self)
        local d = GetDB()
        if not d then return end
        self:StopMovingOrSizing()
        local p, _, rp, x, y = self:GetPoint(1)
        d.point, d.relPoint, d.x, d.y = p, rp, x, y
        d.useCustomPos = true
        RexUI_ApplyDatatext()
    end)

    -- Boxen
    for i=1,3 do
        local b = CreateFrame("Button", nil, Anchor, "BackdropTemplate")
        b:EnableMouse(true)
        b.Text = b:CreateFontString(nil, "OVERLAY")
        b.Text:SetPoint("CENTER")
        Boxes[i] = b
    end

    -- Update Loop (1 Sek)
    local t = 0
    Anchor:SetScript("OnUpdate", function(self, elapsed)
        t = t + elapsed
        if t >= 1 then
            local d = GetDB()
            if d and d.enabled ~= false then
                for i, key in ipairs(SLOT_KEYS) do
                    local mode = (d.slots[key] and d.slots[key].mode) or "none"
                    if Boxes[i] and Boxes[i]:IsShown() then
                        Boxes[i].Text:SetText(TextForMode(mode))
                    end
                end
            end
            t = 0
        end
    end)

    RexUI_ApplyDatatext()
end
_G.RexUI_InitDatatext = RexUI_InitDatatext
