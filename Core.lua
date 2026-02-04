-- =========================================================
-- RexUI Core.lua (Ace3 stabil) - FINAL (Clean)
-- =========================================================

local ADDON_NAME = ...

local AceAddon   = LibStub("AceAddon-3.0")
local AceConsole = LibStub("AceConsole-3.0")
local AceEvent   = LibStub("AceEvent-3.0")
local AceDB      = LibStub("AceDB-3.0")

RexUI = AceAddon:NewAddon("RexUI", "AceConsole-3.0", "AceEvent-3.0")
_G.RexUI = RexUI

-- =========================================================
-- Defaults
-- =========================================================
local defaults = {
    profile = {
        general = {
            -- optional später
        },
        minimap = {
            enabled = true,
            size  = 190,
            scale = 1.0,
            lockMinimap = false,
            lockButton  = false,
            btnAngle  = 210,
            btnRadius = 96,
            btnScale  = 1.0,
            borderSize  = 1,
            borderColor = {0.10, 0.10, 0.10, 1.00},
            showCalendar = true,
            showTracking = true,
            showMail     = true,
            showQueueEye = true,
            showZoneLabel = true,
            showClock     = true,
            zoneX = 0,
            zoneY = 0,
            zoneSize = 12,
            zoneUppercase = false,
            zoneClassColor = false,
            clockX = 0,
            clockY = 0,
            clockSize = 12,
            widgets = {
                calendar = { x = -2, y = -18, scale = 1.0 },
                tracking = { x =  2, y = -18, scale = 1.0 },
                mail     = { x =  2, y =   2, scale = 1.0 },
                queueEye = { corner = "TOPLEFT", x = 2, y = -2, scale = 0.90 },
            },
        },

        datatext = {
            enabled = true,
            lock = true,
            width = 220,
            height = 22,
            offsetX = 0,
            offsetY = -6,
            alpha = 0.9,
            matchMinimapWidth = true,
            slots = {
                left   = { mode = "durability" },
                center = { mode = "none" },
                right  = { mode = "time" },
            }
        },

        unitframes = {},
        chat = {},
    }
}

-- =========================================================
-- Public DB helper
-- =========================================================
function RexUI_GetDB()
    if RexUI and RexUI.db and RexUI.db.profile then
        return RexUI.db.profile
    end
    return defaults.profile
end
_G.RexUI_GetDB = RexUI_GetDB

-- Apply all modules (Wird aufgerufen, wenn sich im Menü was ändert)
function RexUI_ApplyAll()
    if _G.RexUI_ApplyMinimapSkin then _G.RexUI_ApplyMinimapSkin() end
    if _G.RexUI_UpdateMinimapButtonPosition then _G.RexUI_UpdateMinimapButtonPosition() end
    if _G.RexUI_ApplyDatatext then _G.RexUI_ApplyDatatext() end
end
_G.RexUI_ApplyAll = RexUI_ApplyAll

-- Toggle config
function RexUI_ToggleConfig()
    if _G.RexUI_OpenConfig then
        _G.RexUI_OpenConfig()
        return
    end
    print("|cffff4444RexUI: Config nicht geladen.|r")
end
_G.RexUI_ToggleConfig = RexUI_ToggleConfig

-- =========================================================
-- Lifecycle
-- =========================================================
function RexUI:OnInitialize()
    -- Kein globales Default-Profil mehr!
    self.db = AceDB:New("RexUIDB", defaults)

    -- Jeder Charakter bekommt automatisch sein eigenes Profil
    local charKey = UnitName("player") .. "-" .. GetRealmName()
    self.db:SetProfile(charKey)

    if _G.RexUI_InitConfig then
        _G.RexUI_InitConfig()
    end

    self:RegisterChatCommand("rex",   RexUI_ToggleConfig)
    self:RegisterChatCommand("rexui", RexUI_ToggleConfig)
end


function RexUI:OnEnable()
    if _G.RexUI_InitMinimap then
        _G.RexUI_InitMinimap()
    end

    if _G.RexUI_InitDatatext then
        _G.RexUI_InitDatatext()
    end

    RexUI_ApplyAll()
    print("|cff00ff00RexUI geladen. /rex öffnet die Einstellungen.|r")
end

-- =========================================================
-- Reload helpers
-- =========================================================
function RexUI_Reload()
    ReloadUI()
end
_G.RexUI_Reload = RexUI_Reload

SLASH_REXUI_RL1 = "/rl"
SlashCmdList["REXUI_RL"] = function() RexUI_Reload() end

SLASH_REXUI_RELOAD1 = "/reload"
SlashCmdList["REXUI_RELOAD"] = function() RexUI_Reload() end
