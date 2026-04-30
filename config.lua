Config = Config or {}

Config.Debug = false

-- Inventory options: '', 'auto', 'qb', 'qb-inventory', 'tgiann', or 'ox'
-- Leave empty to auto-detect.
Config.Inventory = ''

-- Interaction options: '', 'auto', 'qb-target', 'ox_target', or 'drawtext'
-- Leave empty to auto-detect.
Config.Interaction = ''

Config.CoreName = 'qb-core'
Config.TargetName = ''

Config.Author = 'Opie Winters'
Config.ResourceName = 'astro-npcscrap'

Config.Scrapyard = {
    Ped = {
        enabled = true,
        model = 's_m_y_construct_01',
        coords = vector4(2403.53, 3127.88, 48.15, 249.13),
        scenario = 'WORLD_HUMAN_CLIPBOARD',
    },
    VehicleZone = {
        coords = vector3(2408.88, 3124.68, 48.15),
        radius = 8.0,
    },
    Blip = {
        enabled = true,
        sprite = 643,
        color = 5,
        scale = 0.75,
        label = 'Astro NPC Scrap'
    }
}

Config.RecyclingCenter = {
    Ped = {
        enabled = false,
        model = 's_m_m_dockwork_01',
        coords = vector4(2351.13, 3133.21, 48.21, 255.36),
        scenario = 'WORLD_HUMAN_CLIPBOARD',
    },
    Blip = {
        enabled = true,
        sprite = 365,
        color = 2,
        scale = 0.7,
        label = 'Scrap Recycling'
    }
}

Config.RequiredTools = {
    ScanVehicle = nil,
    SearchGlovebox = nil,
    SearchTrunk = 'advancedlockpick',
    StripEngine = 'advancedlockpick', -- change to wrench/toolbox if you use one
    StripBrakes = 'repairkit',
    TorchVehicle = 'blowtorch',
    CrushVehicle = nil,
    CleanStrip = 'advancedlockpick',
    PartOut = 'advancedlockpick',
    QuickDump = nil,
}

Config.Torching = {
    -- Uses visual particles/debris only instead of StartScriptFire so it will not burn players standing nearby.
    SafeVisualFire = true,
    VisualBurnSeconds = 18,
    SpawnBurnProps = false,
    BurnProps = {},
}

Config.Scanner = {
    enabled = true,
    gradeLabels = { A = 'Excellent Scrap Grade', B = 'Good Scrap Grade', C = 'Average Scrap Grade', D = 'Poor Scrap Grade' },
    classGradeBoost = {
        [2] = 8, [4] = 8, [6] = 10, [7] = 12, [10] = 15, [11] = 12, [12] = 12, [20] = 15
    }
}

Config.Reputation = {
    enabled = true,
    points = {
        ScanVehicle = 1, SearchGlovebox = 1, SearchTrunk = 2, StripEngine = 4, StripBrakes = 3,
        TorchVehicle = 5, CrushVehicle = 6, CleanStrip = 8, PartOut = 10, QuickDump = 2
    },
    levels = {
        { label = 'Rookie Scrapper', required = 0, rewardMultiplier = 1.00 },
        { label = 'Yard Hand', required = 50, rewardMultiplier = 1.05 },
        { label = 'Part Puller', required = 125, rewardMultiplier = 1.08 },
        { label = 'Scrap Specialist', required = 250, rewardMultiplier = 1.12 },
        { label = 'Junkyard Boss', required = 500, rewardMultiplier = 1.18 },
    }
}

Config.Orders = {
    enabled = true,
    resetMinutes = 180,
    list = {
        { id = 'crush_3', label = 'Crush 3 NPC vehicles', action = 'CrushVehicle', amount = 3, rep = 20, money = 350 },
        { id = 'torch_2', label = 'Torch 2 NPC vehicles safely', action = 'TorchVehicle', amount = 2, rep = 15, money = 250 },
        { id = 'strip_2', label = 'Clean strip 2 vehicles', action = 'CleanStrip', amount = 2, rep = 22, money = 375 },
        { id = 'partout_1', label = 'Part-out 1 vehicle', action = 'PartOut', amount = 1, rep = 18, money = 300 },
    }
}

Config.ToolBreakChance = {
    lockpick = 10,
    advancedlockpick = 5,
    repairkit = 3,
    blowtorch = 2,
}

Config.BlacklistedClasses = {
    [13] = true, -- cycles
    [14] = true, -- boats
    [15] = true, -- helicopters
    [16] = true, -- planes
    [18] = true, -- emergency
    [19] = true, -- military
    [21] = true, -- trains
}

Config.BlacklistedModels = {
    [`police`] = true,
    [`police2`] = true,
    [`police3`] = true,
    [`police4`] = true,
    [`policeb`] = true,
    [`ambulance`] = true,
    [`firetruk`] = true,
}

Config.Actions = {
    ScanVehicle = {
        label = 'Scan Scrap Grade',
        icon = 'fas fa-magnifying-glass-chart',
        duration = 5000,
        anim = { dict = 'amb@code_human_in_bus_passenger_idles@female@tablet@base', name = 'base' },
        prop = {
            model = 'prop_cs_tablet',
            fallbackModel = 'prop_cs_clipboard',
            bone = 28422,
            pos = vector3(0.0, -0.03, 0.0),
            rot = vector3(20.0, -90.0, 0.0),
        },
        distance = 4.0,
    },
    SearchGlovebox = {
        label = 'Search Glovebox',
        icon = 'fas fa-box-open',
        duration = 6500,
        anim = { dict = 'amb@prop_human_bum_bin@base', name = 'base' },
        distance = 3.0,
    },
    SearchTrunk = {
        label = 'Search Trunk',
        icon = 'fas fa-car-rear',
        duration = 8500,
        anim = { dict = 'mini@repair', name = 'fixing_a_ped' },
        distance = 3.5,
    },
    StripEngine = {
        label = 'Strip Engine Bay',
        icon = 'fas fa-screwdriver-wrench',
        duration = 12000,
        anim = { dict = 'mini@repair', name = 'fixing_a_ped' },
        distance = 3.5,
    },
    StripBrakes = {
        label = 'Strip Wheels / Brakes',
        icon = 'fas fa-gear',
        duration = 11000,
        anim = { dict = 'mini@repair', name = 'fixing_a_ped' },
        distance = 3.5,
    },
    TorchVehicle = {
        label = 'Torch Vehicle',
        icon = 'fas fa-fire',
        duration = 14000,
        anim = { dict = 'amb@world_human_welding@male@base', name = 'base' },
        prop = {
            model = 'prop_weld_torch',
            fallbackModel = 'prop_tool_hammer',
            bone = 28422,
            pos = vector3(0.08, 0.02, -0.02),
            rot = vector3(-80.0, 20.0, 10.0),
        },
        distance = 4.0,
    },
    CrushVehicle = {
        label = 'Crush Vehicle',
        icon = 'fas fa-recycle',
        duration = 16000,
        anim = { dict = 'amb@prop_human_bum_bin@base', name = 'base' },
        distance = 6.0,
    },
    CleanStrip = {
        label = 'Clean Strip Vehicle',
        icon = 'fas fa-screwdriver-wrench',
        duration = 22000,
        anim = { dict = 'mini@repair', name = 'fixing_a_ped' },
        distance = 4.0,
    },
    PartOut = {
        label = 'Part-Out Vehicle',
        icon = 'fas fa-gears',
        duration = 26000,
        anim = { dict = 'mini@repair', name = 'fixing_a_ped' },
        distance = 4.0,
    },
    QuickDump = {
        label = 'Quick Dump Shell',
        icon = 'fas fa-truck-ramp-box',
        duration = 9000,
        anim = { dict = 'amb@prop_human_bum_bin@base', name = 'base' },
        distance = 6.0,
    },
}



-- Workflow rules:
-- ScanVehicle is the first required step. Nothing else can happen until the vehicle is scanned.
-- There is NO cooldown between tasks; players can keep working through the menu after each progress bar.
Config.Workflow = {
    ForceScanFirst = true,
    ReturnToPedAfterAction = true,
    ReopenMenuAfterAction = true,
    WalkTimeoutSeconds = 15,
    ReturnTimeoutSeconds = 15,
    VehicleStopDistance = 1.6,
    PedStopDistance = 1.4,
    ActionOffsets = {
        ScanVehicle = vector3(0.0, -2.6, 0.0),
        SearchGlovebox = vector3(0.9, 0.35, 0.0),
        SearchTrunk = vector3(0.0, -2.6, 0.0),
        StripEngine = vector3(0.0, 2.6, 0.0),
        StripBrakes = vector3(-1.2, -0.8, 0.0),
        TorchVehicle = vector3(0.0, -2.8, 0.0),
        CrushVehicle = vector3(0.0, -3.2, 0.0),
        CleanStrip = vector3(0.0, 2.6, 0.0),
        PartOut = vector3(0.0, 2.6, 0.0),
        QuickDump = vector3(0.0, -3.2, 0.0),
    }
}

-- Action prerequisites are checked server-side too, so players cannot skip the first scan step.
Config.ActionPrerequisites = {
    SearchGlovebox = { 'ScanVehicle' },
    SearchTrunk = { 'ScanVehicle' },
    StripEngine = { 'ScanVehicle' },
    StripBrakes = { 'ScanVehicle' },
    TorchVehicle = { 'ScanVehicle' },
    CleanStrip = { 'ScanVehicle' },
    PartOut = { 'ScanVehicle' },
    CrushVehicle = { 'ScanVehicle' },
    QuickDump = { 'ScanVehicle' },
}

-- Prevent the same vehicle from being farmed repeatedly.
Config.VehicleCooldownMinutes = 120
Config.PlayerScrapCooldownSeconds = 0

-- Heat / police alert balancing.
Config.Heat = {
    enabled = true,
    resetMinutes = 60,
    safeActionsPerWindow = 5,
    alertChanceAfterSafe = 25,
    alertEvent = 'police:server:policeAlert',
    alertMessage = 'Suspicious vehicle scrapping activity reported near the scrapyard.',
}

-- Chance helper uses 1-100. Decimal chances like 0.5 are supported.
Config.Rewards = {
    ScanVehicle = {},
    SearchGlovebox = {
        { item = 'scrap_papers', min = 1, max = 3, chance = 50 },
        { item = 'parking_ticket', min = 1, max = 1, chance = 25 },
        { item = 'phone_charger', min = 1, max = 1, chance = 15 },
        { item = 'lockpick', min = 1, max = 1, chance = 8 },
    },
    SearchTrunk = {
        { item = 'burnt_rubber', min = 1, max = 2, chance = 45 },
        { item = 'wire_bundle', min = 1, max = 2, chance = 35 },
        { item = 'dirty_plastic', min = 1, max = 3, chance = 55 },
        { item = 'broken_glass', min = 1, max = 3, chance = 45 },
    },
    StripEngine = {
        -- Common mechanic pulls
        { item = 'engine_oil', min = 1, max = 2, chance = 35 },
        { item = 'spark_plug', min = 1, max = 4, chance = 30 },
        { item = 'air_filter', min = 1, max = 1, chance = 25 },
        { item = 'brakepad_replacement', min = 1, max = 1, chance = 15 },
        { item = 'turbocharger', min = 1, max = 1, chance = 6 },
        { item = 'scrap_engine_block', min = 1, max = 1, chance = 22 },
        { item = 'used_oil', min = 1, max = 2, chance = 55 },

        -- High-value non-EV mechanic pulls
        { item = 'performance_part', min = 1, max = 1, chance = 3 },
        { item = 'intercooler', min = 1, max = 1, chance = 2 },
        { item = 'ecu_module', min = 1, max = 1, chance = 1.6 },
        { item = 'v6_engine', min = 1, max = 1, chance = 0.9 },
        { item = 'v8_engine', min = 1, max = 1, chance = 0.6 },
        { item = 'v12_engine', min = 1, max = 1, chance = 0.25 },
    },
    StripBrakes = {
        { item = 'brakepad_replacement', min = 1, max = 1, chance = 28 },
        { item = 'burnt_rubber', min = 1, max = 3, chance = 65 },
        { item = 'wire_bundle', min = 1, max = 2, chance = 25 },
        { item = 'dirty_plastic', min = 1, max = 3, chance = 45 },
    },
    TorchVehicle = {
        { item = 'burnt_rubber', min = 2, max = 5, chance = 100 },
        { item = 'dirty_plastic', min = 2, max = 5, chance = 90 },
        { item = 'broken_glass', min = 1, max = 4, chance = 75 },
        { item = 'wire_bundle', min = 1, max = 3, chance = 55 },
        { item = 'used_oil', min = 1, max = 2, chance = 45 },
    },
    CrushVehicle = {
        { item = 'crushed_metal', min = 4, max = 9, chance = 100 },
        { item = 'burnt_rubber', min = 1, max = 4, chance = 85 },
        { item = 'broken_glass', min = 1, max = 5, chance = 80 },
        { item = 'wire_bundle', min = 1, max = 4, chance = 70 },
        { item = 'dirty_plastic', min = 2, max = 6, chance = 80 },
        { item = 'used_oil', min = 1, max = 2, chance = 55 },
        { item = 'scrap_engine_block', min = 1, max = 1, chance = 30 },
    },
    CleanStrip = {
        { item = 'crushed_metal', min = 3, max = 7, chance = 100 },
        { item = 'wire_bundle', min = 2, max = 4, chance = 85 },
        { item = 'dirty_plastic', min = 2, max = 5, chance = 85 },
        { item = 'engine_oil', min = 1, max = 2, chance = 45 },
        { item = 'spark_plug', min = 2, max = 5, chance = 40 },
        { item = 'air_filter', min = 1, max = 1, chance = 30 },
        { item = 'brakepad_replacement', min = 1, max = 1, chance = 25 },
        { item = 'performance_part', min = 1, max = 1, chance = 5 },
        { item = 'intercooler', min = 1, max = 1, chance = 3 },
        { item = 'slick_tyres', min = 1, max = 1, chance = 2 },
    },
    PartOut = {
        { item = 'crushed_metal', min = 5, max = 10, chance = 100 },
        { item = 'wire_bundle', min = 2, max = 5, chance = 90 },
        { item = 'scrap_engine_block', min = 1, max = 1, chance = 45 },
        { item = 'turbocharger', min = 1, max = 1, chance = 9 },
        { item = 'performance_part', min = 1, max = 1, chance = 6 },
        { item = 'intercooler', min = 1, max = 1, chance = 5 },
        { item = 'ecu_module', min = 1, max = 1, chance = 3 },
        { item = 'v6_engine', min = 1, max = 1, chance = 2 },
        { item = 'v8_engine', min = 1, max = 1, chance = 1.2 },
        { item = 'v12_engine', min = 1, max = 1, chance = 0.4 },
        { item = 'used_oil', min = 1, max = 3, chance = 70 },
    },
    QuickDump = {
        { item = 'crushed_metal', min = 2, max = 5, chance = 100 },
        { item = 'dirty_plastic', min = 1, max = 3, chance = 70 },
        { item = 'broken_glass', min = 1, max = 3, chance = 65 },
    }
}

Config.HighValueMechanicParts = {
    -- 9 high-value non-EV parts used by astro-npcscrap.
    -- EV parts are intentionally not included.
    'v6_engine',
    'v8_engine',
    'v12_engine',
    'performance_part',
    'bodykit_type',
    'ceramic_brakes',
    'slick_tyres',
    'ecu_module',
    'intercooler',
}

Config.ClassBonusRewards = {
    -- Higher class vehicles get extra rare rolls.
    -- GTA vehicle class ids: 4 muscle, 5 sports classic, 6 sports, 7 super, 10 industrial, 11 utility, 12 vans, 20 commercial.
    [4] = {
        { item = 'v6_engine', min = 1, max = 1, chance = 1.2 },
        { item = 'v8_engine', min = 1, max = 1, chance = 0.8 },
        { item = 'performance_part', min = 1, max = 1, chance = 2.5 },
    },
    [5] = {
        { item = 'v6_engine', min = 1, max = 1, chance = 1.1 },
        { item = 'v8_engine', min = 1, max = 1, chance = 0.7 },
        { item = 'bodykit_type', min = 1, max = 1, chance = 1.0 },
    },
    [6] = {
        { item = 'v6_engine', min = 1, max = 1, chance = 1.4 },
        { item = 'performance_part', min = 1, max = 1, chance = 3.0 },
        { item = 'intercooler', min = 1, max = 1, chance = 2.2 },
        { item = 'slick_tyres', min = 1, max = 1, chance = 1.5 },
    },
    [7] = {
        { item = 'v8_engine', min = 1, max = 1, chance = 1.5 },
        { item = 'v12_engine', min = 1, max = 1, chance = 0.8 },
        { item = 'performance_part', min = 1, max = 1, chance = 3.5 },
        { item = 'ceramic_brakes', min = 1, max = 1, chance = 1.4 },
        { item = 'ecu_module', min = 1, max = 1, chance = 1.4 },
    },
    [10] = {
        { item = 'v8_engine', min = 1, max = 1, chance = 0.9 },
        { item = 'ceramic_brakes', min = 1, max = 1, chance = 1.0 },
    },
    [11] = {
        { item = 'v6_engine', min = 1, max = 1, chance = 0.9 },
        { item = 'ecu_module', min = 1, max = 1, chance = 1.1 },
    },
    [12] = {
        { item = 'v6_engine', min = 1, max = 1, chance = 0.9 },
        { item = 'performance_part', min = 1, max = 1, chance = 1.4 },
    },
    [20] = {
        { item = 'v8_engine', min = 1, max = 1, chance = 1.0 },
        { item = 'v12_engine', min = 1, max = 1, chance = 0.35 },
        { item = 'ecu_module', min = 1, max = 1, chance = 1.0 },
    },
}

Config.VehicleClassBonus = {
    -- class = multiplier for CrushVehicle dirty scrap only
    [0] = 1.00, -- compacts
    [1] = 1.05, -- sedans
    [2] = 1.20, -- SUVs
    [3] = 1.05, -- coupes
    [4] = 1.15, -- muscle
    [5] = 1.10, -- sports classic
    [6] = 1.10, -- sports
    [7] = 1.15, -- super
    [8] = 0.55, -- motorcycles
    [9] = 1.20, -- off-road
    [10] = 1.45, -- industrial
    [11] = 1.35, -- utility
    [12] = 1.30, -- vans
    [17] = 1.20, -- service
    [20] = 1.55, -- commercial
}


Config.ItemLabels = {
    crushed_metal = 'Crushed Metal',
    burnt_rubber = 'Burnt Rubber',
    broken_glass = 'Broken Glass',
    wire_bundle = 'Wire Bundle',
    dirty_plastic = 'Dirty Plastic',
    used_oil = 'Used Oil',
    scrap_engine_block = 'Scrap Engine Block',
    metalscrap = 'Metal Scrap',
    steel = 'Steel',
    rubber = 'Rubber',
    glass = 'Glass',
    copper = 'Copper',
    plastic = 'Plastic',
    engine_oil = 'Engine Oil',
    aluminum = 'Aluminum',
}

function Config.GetItemLabel(item)
    return (Config.ItemLabels and Config.ItemLabels[item]) or item
end

Config.RecyclingTrades = {
    crushed_metal = {
        { item = 'metalscrap', min = 2, max = 4 },
        { item = 'steel', min = 1, max = 3 },
    },
    burnt_rubber = {
        { item = 'rubber', min = 2, max = 4 },
    },
    broken_glass = {
        { item = 'glass', min = 1, max = 3 },
    },
    wire_bundle = {
        { item = 'copper', min = 1, max = 2 },
        { item = 'metalscrap', min = 1, max = 2 },
    },
    dirty_plastic = {
        { item = 'plastic', min = 2, max = 5 },
    },
    used_oil = {
        { item = 'engine_oil', min = 1, max = 1 },
    },
    scrap_engine_block = {
        { item = 'steel', min = 3, max = 6 },
        { item = 'metalscrap', min = 3, max = 6 },
        { item = 'aluminum', min = 1, max = 3 },
    },
}
