-- =========================================================
-- RexUI modules/Minimap.lua (CLEAN + STABIL + Calendar Click Fix)
-- =========================================================

local hiddenParent = CreateFrame("Frame")
hiddenParent:Hide()
hiddenParent.Layout = function() end

-- =========================================================
-- DB
-- =========================================================
local function GetDB()
    local db = RexUI_GetDB()
    db.minimap = db.minimap or {}
    db.minimap.widgets = db.minimap.widgets or {}
    db.minimap.widgets.calendar = db.minimap.widgets.calendar or {}
    db.minimap.widgets.tracking = db.minimap.widgets.tracking or {}
    db.minimap.widgets.mail     = db.minimap.widgets.mail or {}
    db.minimap.widgets.queueEye = db.minimap.widgets.queueEye or {}
    return db.minimap
end

-- =========================================================
-- Helpers
-- =========================================================
local function ClampNumber(v, fallback, minv, maxv)
    v = tonumber(v)
    if not v then v = fallback end
    if minv and v < minv then v = minv end
    if maxv and v > maxv then v = maxv end
    return v
end

local function SafeHide(obj)
    if not obj then return end
    if obj.UnregisterAllEvents then obj:UnregisterAllEvents() end
    obj:Hide()
    obj:SetAlpha(0)
end

local function EnsureLayoutMethods()
    if Minimap and not Minimap.Layout then Minimap.Layout = function() end end
    if MinimapCluster and MinimapCluster.IndicatorFrame and not MinimapCluster.IndicatorFrame.Layout then
        MinimapCluster.IndicatorFrame.Layout = function() end
    end
end

local function HideBlizzardRingArt()
    SafeHide(_G.MinimapBorder)
    SafeHide(_G.MinimapBorderTop)
    SafeHide(_G.MinimapBackdrop)
    SafeHide(_G.MinimapCompassTexture)
    SafeHide(_G.MinimapNorthTag)

    SafeHide(_G.MinimapZoomIn)
    SafeHide(_G.MinimapZoomOut)

    -- Blizzard ZoneText ausblenden (damit nix doppelt ist)
    SafeHide(_G.MinimapZoneTextButton)
    SafeHide(_G.MinimapZoneText)

    if MinimapCluster then
        SafeHide(MinimapCluster.BorderTop)
        SafeHide(MinimapCluster.Border)
        if MinimapCluster.ZoneTextButton then SafeHide(MinimapCluster.ZoneTextButton) end
    end
end

local function SetWidgetScaleAbsolute(frame, widgetScale)
    local mdb = GetDB()
    local mapScale = ClampNumber(mdb.scale, 1.0, 0.1, 5.0)
    local want = ClampNumber(widgetScale, 1.0, 0.1, 5.0)
    frame:SetScale(want / mapScale) -- ABSOLUT on screen
end

local function PositionFrame(frame, corner, x, y)
    frame:ClearAllPoints()
    frame:SetPoint(corner, Minimap, corner, x or 0, y or 0)
end

local function GetClassColorRGB()
    local _, class = UnitClass("player")
    local c = (CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class]) or RAID_CLASS_COLORS[class]
    if c then return c.r, c.g, c.b end
    return 1, 0.82, 0
end

-- =========================================================
-- Square + Ring Off
-- =========================================================
local function ForceSquareMinimap()
    if not Minimap then return end

    Minimap:SetMaskTexture("Interface\\Buttons\\WHITE8x8")

    if not _G.RexUI_MinimapShapeSet then
        _G.GetMinimapShape = function() return "SQUARE" end
        _G.RexUI_MinimapShapeSet = true
    end

    if Minimap.SetArchBlobRingScalar then
        Minimap:SetArchBlobRingScalar(0)
        Minimap:SetArchBlobRingAlpha(0)
    end
    if Minimap.SetQuestBlobRingScalar then
        Minimap:SetQuestBlobRingScalar(0)
        Minimap:SetQuestBlobRingAlpha(0)
    end

    HideBlizzardRingArt()
end

-- =========================================================
-- Border
-- =========================================================
local function EnsureRexBorder()
    local mdb = GetDB()
    mdb.borderSize = ClampNumber(mdb.borderSize, 1, 0, 20)
    mdb.borderColor = mdb.borderColor or {0.10,0.10,0.10,1.00}

    if not Minimap.rexBorder then
        Minimap.rexBorder = CreateFrame("Frame", "RexUI_MinimapBorder", Minimap, "BackdropTemplate")
    end

    local b = Minimap.rexBorder
    local bs = mdb.borderSize

    b:SetFrameLevel(Minimap:GetFrameLevel() + 10)
    b:ClearAllPoints()
    b:SetPoint("TOPLEFT", -bs, bs)
    b:SetPoint("BOTTOMRIGHT", bs, -bs)
    b:SetBackdrop({ edgeFile="Interface\\Buttons\\WHITE8x8", edgeSize=math.max(1, bs) })

    local c = mdb.borderColor
    b:SetBackdropBorderColor(c[1],c[2],c[3],c[4] or 1)
    b:SetShown(bs > 0)
end

-- =========================================================
-- Minimap Drag
-- =========================================================
local function EnableMinimapDrag()
    Minimap:SetMovable(true)
    Minimap:EnableMouse(true)
    Minimap:RegisterForDrag("LeftButton")
    Minimap:SetClampedToScreen(true)

    Minimap:SetScript("OnDragStart", function(self)
        if GetDB().lockMinimap then return end
        self:StartMoving()
    end)

    Minimap:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local p, _, rp, x, y = self:GetPoint(1)
        local db = GetDB()
        db.point, db.relPoint, db.x, db.y = p, rp, x, y
    end)
end

-- =========================================================
-- RexUI Minimap Button
-- =========================================================
local function UpdateButtonPosition(btn)
    local mdb = GetDB()
    mdb.btnRadius = ClampNumber(mdb.btnRadius, 96, 40, 400)
    mdb.btnAngle  = ClampNumber(mdb.btnAngle, 210, -720, 720)
    mdb.btnScale  = ClampNumber(mdb.btnScale, 1.0, 0.2, 5.0)

    btn:SetScale(mdb.btnScale)

    local angle = math.rad(mdb.btnAngle)
    local radius = mdb.btnRadius
    local x = math.cos(angle) * radius
    local y = math.sin(angle) * radius

    btn:ClearAllPoints()
    btn:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

function RexUI_UpdateMinimapButtonPosition()
    local btn = _G.RexUI_MinimapButton
    if btn then UpdateButtonPosition(btn) end
end

local function CreateMinimapButton()
    if _G.RexUI_MinimapButton then return end

    local btn = CreateFrame("Button", "RexUI_MinimapButton", Minimap)
    btn:SetSize(32, 32)
    btn:SetFrameStrata("HIGH")
    btn:SetClampedToScreen(true)

    btn:SetNormalTexture("Interface\\AddOns\\RexUI\\media\\RexUILogo.tga")
    btn:GetNormalTexture():SetAllPoints()

    btn:RegisterForDrag("LeftButton")

    btn:SetScript("OnDragStart", function()
        if GetDB().lockButton then return end

        btn:SetScript("OnUpdate", function()
            local mx, my = Minimap:GetCenter()
            local px, py = GetCursorPosition()
            local scale = UIParent:GetScale()
            px, py = px / scale, py / scale

            GetDB().btnAngle = math.deg(math.atan2(py - my, px - mx))
            UpdateButtonPosition(btn)
        end)
    end)

    btn:SetScript("OnDragStop", function()
        btn:SetScript("OnUpdate", nil)
    end)

    btn:SetScript("OnClick", function()
        if RexUI_ToggleConfig then RexUI_ToggleConfig() end
    end)

    UpdateButtonPosition(btn)
end

-- =========================================================
-- Zone Overlay (eigener Button, kein Doppel)
-- =========================================================
local rexZone
local zoneWatcher

local function ApplyZoneOverlay()
    local mdb = GetDB()

    if not rexZone then
        rexZone = CreateFrame("Button", "RexUI_ZoneOverlay", Minimap)
        rexZone:SetFrameStrata("HIGH")
        rexZone:SetFrameLevel(Minimap:GetFrameLevel() + 200)
        rexZone:RegisterForClicks("LeftButtonUp")

        rexZone.text = rexZone:CreateFontString(nil, "OVERLAY")
        rexZone.text:SetPoint("CENTER", rexZone, "CENTER", 0, 0)

        rexZone:SetScript("OnClick", function(_, button)
            if button ~= "LeftButton" then return end
            if ToggleWorldMap then
                ToggleWorldMap()
            elseif WorldMapFrame then
                if WorldMapFrame:IsShown() then WorldMapFrame:Hide() else WorldMapFrame:Show() end
            end
        end)
    end

    local show = (mdb.showZoneLabel ~= false)
    rexZone:SetShown(show)
    if not show then return end

    local txt = GetMinimapZoneText() or ""
    if mdb.zoneUppercase then txt = string.upper(txt) end

    local fs = ClampNumber(mdb.zoneSize, 12, 8, 30)
    rexZone.text:SetFont(STANDARD_TEXT_FONT, fs, "OUTLINE")
    rexZone.text:SetText(txt)

    if mdb.zoneClassColor then
        local r,g,b = GetClassColorRGB()
        rexZone.text:SetTextColor(r,g,b,1)
    else
        rexZone.text:SetTextColor(1, 0.82, 0, 1)
    end

    rexZone:SetSize(math.max(100, rexZone.text:GetStringWidth() + 20), fs + 10)
    rexZone:ClearAllPoints()
    rexZone:SetPoint("TOP", Minimap, "TOP", mdb.zoneX or 0, (0 + (mdb.zoneY or 0)))

    if not zoneWatcher then
        zoneWatcher = CreateFrame("Frame")
        zoneWatcher:RegisterEvent("ZONE_CHANGED")
        zoneWatcher:RegisterEvent("ZONE_CHANGED_INDOORS")
        zoneWatcher:RegisterEvent("ZONE_CHANGED_NEW_AREA")
        zoneWatcher:SetScript("OnEvent", ApplyZoneOverlay)
    end
end

-- =========================================================
-- Clock (Blizzard Button)
-- =========================================================
local function ApplyClock()
    local mdb = GetDB()
    local clk = _G.TimeManagerClockButton
    if not clk then return end

    clk:SetParent(Minimap)
    clk:SetFrameStrata("HIGH")
    clk:SetFrameLevel(Minimap:GetFrameLevel() + 60)
    clk:ClearAllPoints()
    clk:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", (-4 + (mdb.clockX or 0)), (2 + (mdb.clockY or 0)))
    clk:SetShown(mdb.showClock ~= false)

    local fs = clk.GetFontString and clk:GetFontString()
    if fs then
        fs:SetFont(STANDARD_TEXT_FONT, ClampNumber(mdb.clockSize, 12, 8, 30), "OUTLINE")
        fs:Show()
    end
end

-- =========================================================
-- Calendar (Icon) + CLICK FIX (Overlay auf UIParent)
-- =========================================================
local rexCalOverlay

local function EnsureCalendarClickFix(cal)
    if not cal then return end

    if not rexCalOverlay then
        rexCalOverlay = CreateFrame("Button", "RexUI_CalendarClickOverlay", UIParent)
        rexCalOverlay:SetFrameStrata("TOOLTIP") -- sehr weit oben
        rexCalOverlay:RegisterForClicks("LeftButtonUp")

        -- WICHTIG: Zoom/MouseWheel "schlucken", damit nix durchrutscht
        rexCalOverlay:EnableMouseWheel(true)
        rexCalOverlay:SetScript("OnMouseWheel", function() end)

        rexCalOverlay:SetScript("OnClick", function()
            -- robust: GameTimeFrame_OnClick bevorzugen
            if _G.GameTimeFrame_OnClick and _G.GameTimeFrame then
                _G.GameTimeFrame_OnClick(_G.GameTimeFrame)
            elseif ToggleCalendar then
                ToggleCalendar()
            elseif _G.CalendarFrame and _G.CalendarFrame.Toggle then
                _G.CalendarFrame:Toggle()
            end
        end)
    end

    -- Klickfläche exakt über dem Icon halten (egal welche Scale)
    rexCalOverlay:ClearAllPoints()
    rexCalOverlay:SetAllPoints(cal)

    -- Mindestgröße, damit man es immer klicken kann
    local w = cal:GetWidth() or 0
    local h = cal:GetHeight() or 0
    if w < 24 or h < 24 then
        rexCalOverlay:SetSize(24, 24)
    end
end

local function ApplyCalendar()
    local mdb = GetDB()
    local w = mdb.widgets.calendar or {}
    local cal = _G.GameTimeFrame
    if not cal then return end

    if mdb.showCalendar == false then
        cal:SetParent(hiddenParent)
        cal:Hide()
        if rexCalOverlay then rexCalOverlay:Hide() end
        return
    end

    cal:SetParent(Minimap)
    cal:Show()
    cal:SetFrameStrata("HIGH")
    cal:SetFrameLevel(Minimap:GetFrameLevel() + 65)

    PositionFrame(cal, "TOPRIGHT", w.x or -2, w.y or -18)
    SetWidgetScaleAbsolute(cal, w.scale or 1.0)

    -- Klick-Fix (Overlay) – funktioniert auch bei kleiner Scale
    EnsureCalendarClickFix(cal)
    rexCalOverlay:Show()
end

-- =========================================================
-- Tracking / Mail
-- =========================================================
local function FindTrackingFrame()
    return _G.MiniMapTracking
        or _G.MiniMapTrackingButton
        or (MinimapCluster and MinimapCluster.Tracking)
        or (MinimapCluster and MinimapCluster.TrackingFrame)
end

local function ApplyTracking()
    local mdb = GetDB()
    local w = mdb.widgets.tracking or {}
    local t = FindTrackingFrame()
    if not t then return end

    if mdb.showTracking == false then
        t:SetParent(hiddenParent)
        t:Hide()
        return
    end

    t:SetParent(Minimap)
    t:Show()
    t:SetFrameStrata("HIGH")
    t:SetFrameLevel(Minimap:GetFrameLevel() + 65)

    PositionFrame(t, "TOPLEFT", w.x or 2, w.y or -18)
    SetWidgetScaleAbsolute(t, w.scale or 1.0)
end

local function FindMailFrame()
    if MinimapCluster and MinimapCluster.IndicatorFrame and MinimapCluster.IndicatorFrame.MailFrame then
        return MinimapCluster.IndicatorFrame.MailFrame
    end
    if _G.MiniMapMailFrame then
        return _G.MiniMapMailFrame
    end
    return nil
end

local function ApplyMail()
    local mdb = GetDB()
    local w = mdb.widgets.mail or {}
    local mail = FindMailFrame()
    if not mail then return end

    if not mail.Layout then mail.Layout = function() end end

    if mdb.showMail == false then
        mail:SetParent(hiddenParent)
        mail:Hide()
        return
    end

    mail:SetParent(Minimap)
    mail:SetFrameStrata("HIGH")
    mail:SetFrameLevel(Minimap:GetFrameLevel() + 65)

    PositionFrame(mail, "BOTTOMLEFT", w.x or 2, w.y or 2)
    SetWidgetScaleAbsolute(mail, w.scale or 1.0)
end

-- =========================================================
-- Queue Eye Hook (stabil gegen Blizzard Reset)
-- =========================================================
local queueEyeHooked = false
local queueEyeOrig = { parent=nil, point=nil, scale=nil }

local function ApplyQueueEye()
    local mdb = GetDB()
    local w = mdb.widgets.queueEye or {}
    local q = _G.QueueStatusButton
    if not q then return end

    if mdb.showQueueEye == false then
        if queueEyeOrig.parent then q:SetParent(queueEyeOrig.parent) end
        if queueEyeOrig.point then
            q:ClearAllPoints()
            q:SetPoint(unpack(queueEyeOrig.point))
        end
        if queueEyeOrig.scale then q:SetScale(queueEyeOrig.scale) else q:SetScale(1) end
        q:Hide()
        return
    end

    if not queueEyeOrig.parent then
        queueEyeOrig.parent = q:GetParent()
        local p, rt, rp, x, y = q:GetPoint(1)
        if p then queueEyeOrig.point = {p, rt, rp, x, y} end
        queueEyeOrig.scale = q:GetScale()
    end

    q:SetParent(Minimap)
    q:SetFrameStrata("HIGH")
    q:SetFrameLevel(Minimap:GetFrameLevel() + 80)

    local corner = w.corner or "TOPLEFT"
    PositionFrame(q, corner, w.x or 2, w.y or -2)
    SetWidgetScaleAbsolute(q, w.scale or 0.90)
end

local function HookQueueEye()
    if queueEyeHooked then return end
    local q = _G.QueueStatusButton
    if not q then return end
    queueEyeHooked = true

    if q.UpdatePosition then
        hooksecurefunc(q, "UpdatePosition", function()
            if C_Timer then C_Timer.After(0, ApplyQueueEye) else ApplyQueueEye() end
        end)
    end

    q:HookScript("OnShow", function()
        if C_Timer then C_Timer.After(0, ApplyQueueEye) else ApplyQueueEye() end
    end)
end

-- =========================================================
-- Main Apply
-- =========================================================
function RexUI_ApplyMinimapSkin()
    EnsureLayoutMethods()

    local mdb = GetDB()
    if mdb.enabled == false then return end

    -- Size/Scale
    mdb.size  = ClampNumber(mdb.size, 190, 80, 800)
    mdb.scale = ClampNumber(mdb.scale, 1.0, 0.1, 5.0)

    Minimap:SetSize(mdb.size, mdb.size)
    Minimap:SetScale(mdb.scale)
    Minimap:SetAlpha(1)
    Minimap:Show()

    -- Position restore
    Minimap:ClearAllPoints()
    if mdb.point then
        Minimap:SetPoint(mdb.point, UIParent, mdb.relPoint or mdb.point, mdb.x or 0, mdb.y or 0)
    else
        Minimap:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -20, -20)
    end

    ForceSquareMinimap()
    EnsureRexBorder()

    ApplyZoneOverlay()
    ApplyClock()

    ApplyCalendar()
    ApplyTracking()
    ApplyMail()

    HookQueueEye()
    ApplyQueueEye()

    RexUI_UpdateMinimapButtonPosition()
end
_G.RexUI_ApplyMinimapSkin = RexUI_ApplyMinimapSkin

function RexUI_InitMinimap()
    EnableMinimapDrag()
    CreateMinimapButton()

    RexUI_ApplyMinimapSkin()

    if C_Timer and C_Timer.After then
        C_Timer.After(0.5, RexUI_ApplyMinimapSkin)
        C_Timer.After(1.5, RexUI_ApplyMinimapSkin)
    end
end
_G.RexUI_InitMinimap = RexUI_InitMinimap
