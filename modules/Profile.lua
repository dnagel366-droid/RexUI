-- =========================================================
-- RexUI Profile – Export / Import (FINAL Clean, FULL CLONE)
-- =========================================================

local ADDON, ns = ...
local AceSerializer = LibStub("AceSerializer-3.0")

local function GetProfile()
    if not RexUI or not RexUI.db or not RexUI.db.profile then
        return nil
    end
    return RexUI.db.profile
end

-- =========================================================
-- EXPORT
-- =========================================================
function RexUI_ExportProfile()
    local profile = GetProfile()
    if not profile then
        print("|cffff4444RexUI: Kein Profil zum Exportieren.|r")
        return ""
    end
    return AceSerializer:Serialize(profile)
end
_G.RexUI_ExportProfile = RexUI_ExportProfile

-- =========================================================
-- IMPORT (FULL CLONE)
-- =========================================================
function RexUI_ImportProfile(serialized)
    if type(serialized) ~= "string" then
        print("|cffff4444RexUI: Ungültiger Import-Text.|r")
        return false
    end

    serialized = strtrim(serialized)
    if serialized == "" then
        print("|cffff4444RexUI: Ungültiger Import-Text.|r")
        return false
    end

    local ok, data = AceSerializer:Deserialize(serialized)
    if not ok or type(data) ~= "table" then
        print("|cffff4444RexUI: Import fehlgeschlagen.|r")
        return false
    end

    -- AceDB-sicher: Referenz behalten, Inhalt ersetzen
    local p = RexUI.db.profile
    if type(p) ~= "table" then
        RexUI.db.profile = {}
        p = RexUI.db.profile
    end

    wipe(p)
    for k, v in pairs(data) do
        p[k] = v
    end

    if RexUI_ApplyAll then RexUI_ApplyAll() end

    print("|cff00ff00RexUI: Profil 1:1 importiert (A → B).|r")
    return true
end
_G.RexUI_ImportProfile = RexUI_ImportProfile
