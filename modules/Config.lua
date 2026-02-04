-- =========================================================
-- RexUI modules/Config.lua (REPARIERT & VOLLSTÄNDIG)
-- =========================================================

local AceConfig       = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local function DB()
    return RexUI_GetDB()
end

-- Hilfsfunktion für Datatext Datenbank (erzeugt Tabellen falls nötig)
local function DDB()
    local db = DB()
    db.datatext = db.datatext or {}
    db.datatext.slots = db.datatext.slots or {}
    db.datatext.slots.left   = db.datatext.slots.left   or { mode = "none" }
    db.datatext.slots.center = db.datatext.slots.center or { mode = "none" }
    db.datatext.slots.right  = db.datatext.slots.right  or { mode = "none" }
    return db.datatext
end

local function MDB()
    local db = DB()
    db.minimap = db.minimap or {}
    db.minimap.widgets = db.minimap.widgets or {}
    db.minimap.widgets.calendar = db.minimap.widgets.calendar or {}
    db.minimap.widgets.tracking = db.minimap.widgets.tracking or {}
    db.minimap.widgets.mail     = db.minimap.widgets.mail or {}
    db.minimap.widgets.queueEye = db.minimap.widgets.queueEye or {}
    return db.minimap
end

local function W(id)
    local m = MDB()
    m.widgets[id] = m.widgets[id] or {}
    return m.widgets[id]
end

local function Apply()
    if _G.RexUI_ApplyAll then _G.RexUI_ApplyAll() end
end

local CORNERS = {
    TOPLEFT="Oben Links",
    TOPRIGHT="Oben Rechts",
    BOTTOMLEFT="Unten Links",
    BOTTOMRIGHT="Unten Rechts",
}

local function BuildOptions()
    return {
        type = "group",
        name = "RexUI",
        childGroups = "tab",
        args = {
            -- =========================================================
            -- Allgemein (Original-Zustand)
            -- =========================================================
            general = {
                type = "group",
                name = "Allgemein",
                order = 1,
                args = {
                    info = {
                        type = "description",
                        name = "RexUI – Einstellungen\n\nHinweis: Icons werden NICHT per Drag bewegt.\nAlles läuft über Slider (X/Y/Skalierung) für stabile Speicherung.",
                        order = 1,
                    },
                    reloadBtn = {
                        type = "execute",
                        name = "UI neu laden (Reload)",
                        width = "full",
                        order = 2,
                        func = function() ReloadUI() end,
                    },
                },
            },

profile = {
    type = "group",
    name = "Profile",
    order = 99,
    args = {

        info = {
            type = "description",
            name = [[Hier kannst du dein RexUI-Profil exportieren oder importieren.

Workflow:
1. Auf Charakter A → "Profil exportieren"
2. String kopieren
3. Auf Charakter B → einfügen
4. "Profil importieren"]],
            order = 1,
        },

        export = {
            type = "execute",
            name = "Profil exportieren",
            order = 2,
            width = "full",
            func = function()
                RexUI_ProfileString = RexUI_ExportProfile()
            end,
        },

        import = {
            type = "execute",
            name = "Profil importieren",
            order = 3,
            width = "full",
            confirm = true,
            confirmText = "Achtung: Das aktuelle Profil wird überschrieben. Fortfahren?",
            func = function()
                local ok = RexUI_ImportProfile(RexUI_ProfileString)
                if ok then
                    ReloadUI()
                end
            end,
        },

        text = {
            type = "input",
            name = "Profil-String",
            order = 4,
            width = "full",
            multiline = 12,
            get = function()
                return RexUI_ProfileString or ""
            end,
            set = function(_, v)
                RexUI_ProfileString = v
            end,
        },
    },
},

            -- =========================================================
            -- Minimap (Exakt nach deiner Vorlage)
            -- =========================================================
            minimap = {
                type = "group",
                name = "Minimap",
                order = 2,
                args = {
                    h0 = { type="header", name="Minimap – Größe & Rahmen", order=1 },
                    enabled = {
                        type="toggle", name="Minimap-Modul aktiv", order=2,
                        get=function() return MDB().enabled ~= false end,
                        set=function(_, v) MDB().enabled = v; Apply() end,
                    },
                    size = {
                        type="range", name="Map Größe (Pixel)", order=3, min=120, max=420, step=1,
                        get=function() return MDB().size or 190 end,
                        set=function(_, v) MDB().size = v; Apply() end,
                    },
                    scale = {
                        type="range", name="Minimap Skalierung", order=4, min=0.60, max=1.80, step=0.01,
                        get=function() return MDB().scale or 1.0 end,
                        set=function(_, v) MDB().scale = v; Apply() end,
                    },
                    borderSize = {
                        type="range", name="Randstärke", order=5, min=0, max=10, step=1,
                        get=function() return MDB().borderSize or 1 end,
                        set=function(_, v) MDB().borderSize = v; Apply() end,
                    },
                    borderColor = {
                        type="color", name="Randfarbe", order=6, hasAlpha=true,
                        get=function()
                            local c = MDB().borderColor or {0.10,0.10,0.10,1.00}
                            return c[1],c[2],c[3],c[4]
                        end,
                        set=function(_, r,g,b,a)
                            MDB().borderColor = {r,g,b,a}
                            Apply()
                        end,
                    },
                    h1 = { type="header", name="Sperren", order=20 },
                    lockMinimap = {
                        type="toggle", name="Minimap sperren (kein Verschieben)", order=21,
                        get=function() return MDB().lockMinimap == true end,
                        set=function(_, v) MDB().lockMinimap = v; Apply() end,
                    },
                    lockButton = {
                        type="toggle", name="RexUI Button sperren", order=22,
                        get=function() return MDB().lockButton == true end,
                        set=function(_, v) MDB().lockButton = v; Apply() end,
                    },
                    h2 = { type="header", name="RexUI Minimap-Button", order=40 },
                    btnScale = {
                        type="range", name="RexUI Button Skalierung", order=41, min=0.50, max=2.0, step=0.05,
                        get=function() return MDB().btnScale or 1.0 end,
                        set=function(_, v) MDB().btnScale = v; Apply() end,
                    },
                    btnRadius = {
                        type="range", name="RexUI Button Abstand (Radius)", order=42, min=40, max=220, step=1,
                        get=function() return MDB().btnRadius or 96 end,
                        set=function(_, v) MDB().btnRadius = v; Apply() end,
                    },
                    btnAngle = {
                        type="range", name="RexUI Button Winkel", order=43, min=0, max=360, step=1,
                        get=function() return MDB().btnAngle or 210 end,
                        set=function(_, v) MDB().btnAngle = v; Apply() end,
                    },
                    h3 = { type="header", name="Zone & Uhr", order=60 },
                    showZoneLabel = {
                        type="toggle", name="Zonentext anzeigen", order=61,
                        get=function() return MDB().showZoneLabel ~= false end,
                        set=function(_, v) MDB().showZoneLabel = v; Apply() end,
                    },
                    zoneSize = {
                        type="range", name="Zonentext Größe", order=62, min=8, max=24, step=1,
                        get=function() return MDB().zoneSize or 12 end,
                        set=function(_, v) MDB().zoneSize = v; Apply() end,
                    },
                    zoneX = {
                        type="range", name="Zonentext X", order=63, min=-200, max=200, step=1,
                        get=function() return MDB().zoneX or 0 end,
                        set=function(_, v) MDB().zoneX = v; Apply() end,
                    },
                    zoneY = {
                        type="range", name="Zonentext Y", order=64, min=-200, max=200, step=1,
                        get=function() return MDB().zoneY or 0 end,
                        set=function(_, v) MDB().zoneY = v; Apply() end,
                    },
                    zoneUppercase = {
                        type="toggle", name="Zonentext Großbuchstaben", order=65,
                        get=function() return MDB().zoneUppercase == true end,
                        set=function(_, v) MDB().zoneUppercase = v; Apply() end,
                    },
                    zoneClassColor = {
                        type="toggle", name="Zonentext Klassenfarbe", order=66,
                        get=function() return MDB().zoneClassColor == true end,
                        set=function(_, v) MDB().zoneClassColor = v; Apply() end,
                    },
                    showClock = {
                        type="toggle", name="Uhr anzeigen", order=70,
                        get=function() return MDB().showClock ~= false end,
                        set=function(_, v) MDB().showClock = v; Apply() end,
                    },
                    clockSize = {
                        type="range", name="Uhr Größe", order=71, min=8, max=24, step=1,
                        get=function() return MDB().clockSize or 12 end,
                        set=function(_, v) MDB().clockSize = v; Apply() end,
                    },
                    clockX = {
                        type="range", name="Uhr X", order=72, min=-200, max=200, step=1,
                        get=function() return MDB().clockX or 0 end,
                        set=function(_, v) MDB().clockX = v; Apply() end,
                    },
                    clockY = {
                        type="range", name="Uhr Y", order=73, min=-200, max=200, step=1,
                        get=function() return MDB().clockY or 0 end,
                        set=function(_, v) MDB().clockY = v; Apply() end,
                    },
                    h4 = { type="header", name="Minimap Icons (Slider)", order=90 },
                    showCalendar = {
                        type="toggle", name="Kalender anzeigen", order=91,
                        get=function() return MDB().showCalendar ~= false end,
                        set=function(_, v) MDB().showCalendar = v; Apply() end,
                    },
                    calScale = {
                        type="range", name="Kalender Skalierung", order=92, min=0.50, max=2.0, step=0.05,
                        get=function() return W("calendar").scale or 1.0 end,
                        set=function(_, v) W("calendar").scale = v; Apply() end,
                    },
                    calX = {
                        type="range", name="Kalender X", order=93, min=-200, max=200, step=1,
                        get=function() return W("calendar").x or -2 end,
                        set=function(_, v) W("calendar").x = v; Apply() end,
                    },
                    calY = {
                        type="range", name="Kalender Y", order=94, min=-200, max=200, step=1,
                        get=function() return W("calendar").y or -18 end,
                        set=function(_, v) W("calendar").y = v; Apply() end,
                    },
                    showTracking = {
                        type="toggle", name="Tracking anzeigen", order=100,
                        get=function() return MDB().showTracking ~= false end,
                        set=function(_, v) MDB().showTracking = v; Apply() end,
                    },
                    trackScale = {
                        type="range", name="Tracking Skalierung", order=101, min=0.50, max=2.0, step=0.05,
                        get=function() return W("tracking").scale or 1.0 end,
                        set=function(_, v) W("tracking").scale = v; Apply() end,
                    },
                    trackX = {
                        type="range", name="Tracking X", order=102, min=-200, max=200, step=1,
                        get=function() return W("tracking").x or 2 end,
                        set=function(_, v) W("tracking").x = v; Apply() end,
                    },
                    trackY = {
                        type="range", name="Tracking Y", order=103, min=-200, max=200, step=1,
                        get=function() return W("tracking").y or -18 end,
                        set=function(_, v) W("tracking").y = v; Apply() end,
                    },
                    showMail = {
                        type="toggle", name="Post-Icon anzeigen", order=110,
                        get=function() return MDB().showMail ~= false end,
                        set=function(_, v) MDB().showMail = v; Apply() end,
                    },
                    mailScale = {
                        type="range", name="Post Skalierung", order=111, min=0.50, max=2.0, step=0.05,
                        get=function() return W("mail").scale or 1.0 end,
                        set=function(_, v) W("mail").scale = v; Apply() end,
                    },
                    mailX = {
                        type="range", name="Post X", order=112, min=-200, max=200, step=1,
                        get=function() return W("mail").x or 2 end,
                        set=function(_, v) W("mail").x = v; Apply() end,
                    },
                    mailY = {
                        type="range", name="Post Y", order=113, min=-200, max=200, step=1,
                        get=function() return W("mail").y or 2 end,
                        set=function(_, v) W("mail").y = v; Apply() end,
                    },
                    showQueueEye = {
                        type="toggle", name="LFG Auge anzeigen", order=120,
                        get=function() return MDB().showQueueEye ~= false end,
                        set=function(_, v) MDB().showQueueEye = v; Apply() end,
                    },
                    eyeCorner = {
                        type="select", name="LFG Auge Ecke", order=121, values=CORNERS,
                        get=function() return W("queueEye").corner or "TOPLEFT" end,
                        set=function(_, v) W("queueEye").corner = v; Apply() end,
                    },
                    eyeScale = {
                        type="range", name="LFG Auge Skalierung", order=122, min=0.50, max=2.0, step=0.05,
                        get=function() return W("queueEye").scale or 0.90 end,
                        set=function(_, v) W("queueEye").scale = v; Apply() end,
                    },
                    eyeX = {
                        type="range", name="LFG Auge X", order=123, min=-200, max=200, step=1,
                        get=function() return W("queueEye").x or 2 end,
                        set=function(_, v) W("queueEye").x = v; Apply() end,
                    },
                    eyeY = {
                        type="range", name="LFG Auge Y", order=124, min=-200, max=200, step=1,
                        get=function() return W("queueEye").y or -2 end,
                        set=function(_, v) W("queueEye").y = v; Apply() end,
                    },
                    h9 = { type="header", name="Reset", order=200 },
                    resetPos = {
                        type="execute", name="Position zurücksetzen", order=201,
                        func=function()
                            local m = MDB()
                            m.point, m.relPoint, m.x, m.y = nil, nil, nil, nil
                            Apply()
                        end,
                    },
                },
            },

            -- =========================================================
            -- Datatext (Erweiterung)
            -- =========================================================
                        datatext = {
                type = "group",
                name = "Datatext",
                order = 3,
                args = {
                    h0 = { type="header", name="Datatext – Box", order=1 },

                    enabled = {
                        type="toggle",
                        name="Box aktiv",
                        order=2,
                        get=function() return DDB().enabled ~= false end,
                        set=function(_, v) DDB().enabled = v; Apply() end,
                    },

                    lock = {
                        type="toggle",
                        name="Position sperren (Lock)",
                        desc="Wenn AUS: grüner Rahmen + mit Maus ziehen.",
                        order=3,
                        get=function() return DDB().lock ~= false end,
                        set=function(_, v) DDB().lock = v; Apply() end,
                    },

                    mouseover = {
                        type="toggle",
                        name="Mouseover (nur bei Hover anzeigen)",
                        order=4,
                        get=function() return DDB().mouseover == true end,
                        set=function(_, v) DDB().mouseover = v; Apply() end,
                    },

                    resetPos = {
                        type="execute",
                        name="Position zurücksetzen (Offsets wieder aktiv)",
                        order=5,
                        func=function()
                            local d = DDB()
                            d.useCustomPos = false
                            d.point, d.relPoint, d.x, d.y = nil, nil, nil, nil
                            Apply()
                            print("|cff00ff00RexUI: Datatext Position zurückgesetzt.|r")
                        end,
                    },

                    h1 = { type="header", name="Größe & Position", order=10 },

                    matchMinimapWidth = {
                        type="toggle",
                        name="Breite = Minimap",
                        order=11,
                        get=function() return DDB().matchMinimapWidth ~= false end,
                        set=function(_, v) DDB().matchMinimapWidth = v; Apply() end,
                    },

                    width = {
                        type="range",
                        name="Breite (wenn nicht Minimap)",
                        order=12,
                        min=120, max=800, step=1,
                        disabled=function() return DDB().matchMinimapWidth ~= false end,
                        get=function() return DDB().width or 220 end,
                        set=function(_, v) DDB().width = v; Apply() end,
                    },

                    height = {
                        type="range",
                        name="Höhe",
                        order=13,
                        min=12, max=60, step=1,
                        get=function() return DDB().height or 22 end,
                        set=function(_, v) DDB().height = v; Apply() end,
                    },

                    spacing = {
                        type="range",
                        name="Abstand zwischen Slots",
                        order=14,
                        min=0, max=30, step=1,
                        get=function() return DDB().spacing or 0 end,
                        set=function(_, v) DDB().spacing = v; Apply() end,
                    },

                    offsetX = {
                        type="range",
                        name="Offset X (nur wenn nicht gezogen)",
                        order=15,
                        min=-200, max=200, step=1,
                        get=function() return DDB().offsetX or 0 end,
                        set=function(_, v) DDB().offsetX = v; Apply() end,
                    },

                    offsetY = {
                        type="range",
                        name="Offset Y (nur wenn nicht gezogen)",
                        order=16,
                        min=-200, max=200, step=1,
                        get=function() return DDB().offsetY or -6 end,
                        set=function(_, v) DDB().offsetY = v; Apply() end,
                    },

                    h2 = { type="header", name="Look", order=30 },

                    alpha = {
                        type="range",
                        name="Transparenz",
                        order=31,
                        min=0, max=1, step=0.01,
                        get=function() return DDB().alpha or 0.90 end,
                        set=function(_, v) DDB().alpha = v; Apply() end,
                    },

                    fontSize = {
                        type="range",
                        name="Textgröße",
                        order=32,
                        min=8, max=24, step=1,
                        get=function() return DDB().fontSize or 12 end,
                        set=function(_, v) DDB().fontSize = v; Apply() end,
                    },

                    bgColor = {
                        type="color",
                        name="Hintergrundfarbe",
                        order=33,
                        get=function()
                            local c = DDB().bgColor or {0,0,0}
                            return c[1], c[2], c[3], 1
                        end,
                        set=function(_, r,g,b)
                            DDB().bgColor = {r,g,b}
                            Apply()
                        end,
                    },

                    borderSize = {
                        type="range",
                        name="Rahmenstärke",
                        order=34,
                        min=0, max=6, step=1,
                        get=function() return DDB().borderSize or 1 end,
                        set=function(_, v) DDB().borderSize = v; Apply() end,
                    },

                    borderColor = {
                        type="color",
                        name="Rahmenfarbe",
                        order=35,
                        hasAlpha=true,
                        get=function()
                            local c = DDB().borderColor or {0.20,0.20,0.20,1.00}
                            return c[1], c[2], c[3], c[4]
                        end,
                        set=function(_, r,g,b,a)
                            DDB().borderColor = {r,g,b,a}
                            Apply()
                        end,
                    },

                    h3 = { type="header", name="Slots (Links / Mitte / Rechts)", order=50 },

                    leftMode = {
                        type="select", name="Slot Links", order=51,
                        values={ none="(leer)", time="Zeit", fps="FPS", ms="MS", durability="Durability / Gear %", bags="Bags (frei)", gold="Gold", guild="Gilde" },
                        get=function() return DDB().slots.left.mode or "none" end,
                        set=function(_, v) DDB().slots.left.mode = v; Apply() end,
                    },

                    centerMode = {
                        type="select", name="Slot Mitte", order=52,
                        values={ none="(leer)", time="Zeit", fps="FPS", ms="MS", durability="Durability / Gear %", bags="Bags (frei)", gold="Gold", guild="Gilde" },
                        get=function() return DDB().slots.center.mode or "none" end,
                        set=function(_, v) DDB().slots.center.mode = v; Apply() end,
                    },

                    rightMode = {
                        type="select", name="Slot Rechts", order=53,
                        values={ none="(leer)", time="Zeit", fps="FPS", ms="MS", durability="Durability / Gear %", bags="Bags (frei)", gold="Gold", guild="Gilde" },
                        get=function() return DDB().slots.right.mode or "none" end,
                        set=function(_, v) DDB().slots.right.mode = v; Apply() end,
                    },
                },
            },
        },
    }
end

function RexUI_InitConfig()
    AceConfig:RegisterOptionsTable("RexUI", BuildOptions())
    if AceConfigDialog.SetDefaultSize then
        AceConfigDialog:SetDefaultSize("RexUI", 900, 650)
    end
end
_G.RexUI_InitConfig = RexUI_InitConfig

function RexUI_OpenConfig()
    AceConfigDialog:Open("RexUI")
end
_G.RexUI_OpenConfig = RexUI_OpenConfig