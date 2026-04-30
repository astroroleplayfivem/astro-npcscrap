local QBCore = exports[Config.CoreName]:GetCoreObject()
local createdPeds = {}
local currentVehicleNet = nil
local actionLocks = {}
local openScrapyardMenu
local uiOpen = false
local currentUiVehicle = nil

local function dbg(...)
    if Config.Debug then print('[astro-npcscrap:client]', ...) end
end

local function loadModel(model)
    local hash = type(model) == 'number' and model or joaat(model)
    if not IsModelInCdimage(hash) then return nil end
    RequestModel(hash)
    local timeout = GetGameTimer() + 8000
    while not HasModelLoaded(hash) and GetGameTimer() < timeout do Wait(25) end
    if not HasModelLoaded(hash) then return nil end
    return hash
end

local function createBlip(data, coords)
    if not data or not data.enabled then return end
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, data.sprite or 1)
    SetBlipColour(blip, data.color or 0)
    SetBlipScale(blip, data.scale or 0.7)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(data.label or 'Astro Location')
    EndTextCommandSetBlipName(blip)
end

local function getInteractionType()
    local interaction = Config.Interaction
    if interaction and interaction ~= '' and interaction ~= 'auto' then return interaction end
    if GetResourceState('ox_target') == 'started' then return 'ox_target' end
    if GetResourceState(Config.TargetName or '') == 'started' then return 'qb-target' end
    if GetResourceState('qb-target') == 'started' then return 'qb-target' end
    return 'drawtext'
end

local function getQbTargetName()
    if Config.TargetName and Config.TargetName ~= '' then return Config.TargetName end
    return 'qb-target'
end

local function addPedTarget(ped, id, targetOptions)
    local interaction = getInteractionType()

    if interaction == 'ox_target' and GetResourceState('ox_target') == 'started' then
        local oxOptions = {}
        for i, option in ipairs(targetOptions or {}) do
            oxOptions[#oxOptions + 1] = {
                name = ('astro_npcscrap_%s_%s'):format(id or 'ped', i),
                icon = option.icon,
                label = option.label,
                distance = option.distance or 2.5,
                onSelect = function()
                    if option.action then option.action() end
                end
            }
        end
        exports.ox_target:addLocalEntity(ped, oxOptions)
        return
    end

    local qbTarget = getQbTargetName()
    if interaction == 'qb-target' and GetResourceState(qbTarget) == 'started' then
        exports[qbTarget]:AddTargetEntity(ped, {
            options = targetOptions,
            distance = 2.5
        })
    end
end

local function spawnPed(pedData, id, targetOptions)
    if not pedData or not pedData.enabled then return end
    local hash = loadModel(pedData.model)
    if not hash then print(('[astro-npcscrap] Invalid ped model for %s'):format(id)) return end
    local c = pedData.coords
    local ped = CreatePed(0, hash, c.x, c.y, c.z - 1.0, c.w, false, true)
    SetEntityAsMissionEntity(ped, true, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedFleeAttributes(ped, 0, false)
    SetPedDiesWhenInjured(ped, false)
    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)
    if pedData.scenario then TaskStartScenarioInPlace(ped, pedData.scenario, 0, true) end
    createdPeds[#createdPeds + 1] = ped

    addPedTarget(ped, id, targetOptions)
end

local function getClosestVehicleToScrapyard()
    local coords = Config.Scrapyard.VehicleZone.coords
    local radius = Config.Scrapyard.VehicleZone.radius
    local veh = GetClosestVehicle(coords.x, coords.y, coords.z, radius, 0, 70)
    if veh == 0 then return nil end
    return veh
end

local function isVehicleInScrapyard(vehicle)
    if not vehicle or vehicle == 0 then return false end
    local dist = #(GetEntityCoords(vehicle) - Config.Scrapyard.VehicleZone.coords)
    return dist <= Config.Scrapyard.VehicleZone.radius
end

local function getVehNet(vehicle)
    if not NetworkGetEntityIsNetworked(vehicle) then
        NetworkRegisterEntityAsNetworked(vehicle)
        Wait(50)
    end
    return VehToNet(vehicle)
end

local function requestControl(entity)
    local timeout = GetGameTimer() + 5000
    NetworkRequestControlOfEntity(entity)
    while not NetworkHasControlOfEntity(entity) and GetGameTimer() < timeout do
        NetworkRequestControlOfEntity(entity)
        Wait(25)
    end
    return NetworkHasControlOfEntity(entity)
end

local function attachWorkProp(propConfig)
    if not propConfig or not propConfig.model then return nil end

    local ped = PlayerPedId()
    local hash = loadModel(propConfig.model)
    if not hash and propConfig.fallbackModel then
        hash = loadModel(propConfig.fallbackModel)
    end
    if not hash then return nil end

    local coords = GetEntityCoords(ped)
    local prop = CreateObject(hash, coords.x, coords.y, coords.z + 0.2, true, true, false)
    if not prop or prop == 0 then return nil end

    SetEntityAsMissionEntity(prop, true, true)
    AttachEntityToEntity(prop, ped, GetPedBoneIndex(ped, propConfig.bone or 28422),
        propConfig.pos and propConfig.pos.x or 0.0, propConfig.pos and propConfig.pos.y or 0.0, propConfig.pos and propConfig.pos.z or 0.0,
        propConfig.rot and propConfig.rot.x or 0.0, propConfig.rot and propConfig.rot.y or 0.0, propConfig.rot and propConfig.rot.z or 0.0,
        true, true, false, true, 1, true)

    return prop
end

local function deleteWorkProp(prop)
    if prop and prop ~= 0 and DoesEntityExist(prop) then
        DetachEntity(prop, true, true)
        DeleteEntity(prop)
    end
end

local function safeTorchVisuals(vehicle)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return end
    local coords = GetEntityCoords(vehicle)
    local spawnedProps = {}
    local particles = {}

    -- Scorched/broken shell look without real script fire damage.
    SetEntityRenderScorched(vehicle, true)
    SetVehicleEngineHealth(vehicle, 0.0)
    SetVehicleBodyHealth(vehicle, 100.0)
    SetVehicleDirtLevel(vehicle, 15.0)
    SmashVehicleWindow(vehicle, 0)
    SmashVehicleWindow(vehicle, 1)
    SmashVehicleWindow(vehicle, 2)
    SmashVehicleWindow(vehicle, 3)
    StartVehicleAlarm(vehicle)

    if Config.Torching and Config.Torching.SpawnBurnProps then
        for i, model in ipairs(Config.Torching.BurnProps or {}) do
            local hash = loadModel(model)
            if hash then
                local offset = GetOffsetFromEntityInWorldCoords(vehicle, (i - 2) * 0.9, -1.6 + (i * 0.45), -0.35)
                local prop = CreateObject(hash, offset.x, offset.y, offset.z, true, true, false)
                if prop and prop ~= 0 then
                    SetEntityHeading(prop, GetEntityHeading(vehicle) + (i * 33.0))
                    PlaceObjectOnGroundProperly(prop)
                    SetEntityAsMissionEntity(prop, true, true)
                    spawnedProps[#spawnedProps + 1] = prop
                end
            end
        end
    end

    RequestNamedPtfxAsset('core')
    local timeout = GetGameTimer() + 3000
    while not HasNamedPtfxAssetLoaded('core') and GetGameTimer() < timeout do Wait(10) end

    if HasNamedPtfxAssetLoaded('core') then
        local points = {
            GetOffsetFromEntityInWorldCoords(vehicle, 0.0, 0.0, 0.25),
            GetOffsetFromEntityInWorldCoords(vehicle, 0.75, -1.0, 0.15),
            GetOffsetFromEntityInWorldCoords(vehicle, -0.75, -1.0, 0.15),
        }
        for _, p in ipairs(points) do
            UseParticleFxAssetNextCall('core')
            local fx = StartParticleFxLoopedAtCoord('ent_amb_fbi_fire_lg', p.x, p.y, p.z, 0.0, 0.0, 0.0, 0.65, false, false, false, false)
            if fx then particles[#particles + 1] = fx end
        end
    end

    CreateThread(function()
        Wait((Config.Torching and Config.Torching.VisualBurnSeconds or 18) * 1000)
        for _, fx in ipairs(particles) do StopParticleFxLooped(fx, false) end
        for _, prop in ipairs(spawnedProps) do if DoesEntityExist(prop) then DeleteEntity(prop) end end
    end)
end

local function progress(label, duration, anim, propConfig)
    local ped = PlayerPedId()
    local workProp = attachWorkProp(propConfig)

    if anim and anim.dict then
        RequestAnimDict(anim.dict)
        while not HasAnimDictLoaded(anim.dict) do Wait(10) end
        TaskPlayAnim(ped, anim.dict, anim.name, 2.0, 2.0, -1, 49, 0, false, false, false)
    end

    local finished = false
    QBCore.Functions.Progressbar('astro_npcscrap_' .. tostring(GetGameTimer()), label, duration, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function()
        finished = true
        ClearPedTasks(ped)
        deleteWorkProp(workProp)
    end, function()
        finished = false
        ClearPedTasks(ped)
        deleteWorkProp(workProp)
    end)

    local waitUntil = GetGameTimer() + duration + 1000
    while GetGameTimer() < waitUntil do
        Wait(100)
        if finished then return true end
    end

    deleteWorkProp(workProp)
    ClearPedTasks(ped)
    return false
end


local function walkToCoords(coords, stopDistance, timeoutSeconds)
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        TaskLeaveVehicle(ped, GetVehiclePedIsIn(ped, false), 0)
        local leaveTimeout = GetGameTimer() + 5000
        while IsPedInAnyVehicle(ped, false) and GetGameTimer() < leaveTimeout do Wait(100) end
    end

    TaskGoStraightToCoord(ped, coords.x, coords.y, coords.z, 1.0, -1, 0.0, 0.0)
    local timeout = GetGameTimer() + ((timeoutSeconds or 12) * 1000)
    while GetGameTimer() < timeout do
        Wait(150)
        if #(GetEntityCoords(ped) - coords) <= (stopDistance or 1.6) then
            ClearPedTasks(ped)
            return true
        end
    end
    ClearPedTasks(ped)
    return #(GetEntityCoords(ped) - coords) <= ((stopDistance or 1.6) + 1.0)
end

local function getActionWorkCoords(vehicle, actionName)
    local offsets = Config.Workflow and Config.Workflow.ActionOffsets or {}
    local offset = offsets[actionName] or vector3(0.0, -2.4, 0.0)
    return GetOffsetFromEntityInWorldCoords(vehicle, offset.x, offset.y, offset.z)
end

local function faceEntity(entity)
    local ped = PlayerPedId()
    local pCoords = GetEntityCoords(ped)
    local eCoords = GetEntityCoords(entity)
    TaskTurnPedToFaceCoord(ped, eCoords.x, eCoords.y, eCoords.z, 1000)
    Wait(450)
end

local function returnToScrapPedAndReopen()
    if not Config.Workflow or not Config.Workflow.ReturnToPedAfterAction then return end
    local pedCoords = vector3(Config.Scrapyard.Ped.coords.x, Config.Scrapyard.Ped.coords.y, Config.Scrapyard.Ped.coords.z)
    walkToCoords(pedCoords, Config.Workflow.PedStopDistance or 1.4, Config.Workflow.ReturnTimeoutSeconds or 15)
    if Config.Workflow.ReopenMenuAfterAction then
        Wait(250)
        openScrapyardMenu()
    end
end

local function closeScrapyardUi()
    if not uiOpen then return end
    uiOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

local function startAction(actionName)
    closeScrapyardUi()
    TriggerEvent('qb-menu:closeMenu')
    if actionLocks[actionName] then return end
    local action = Config.Actions[actionName]
    if not action then return end

    local vehicle = currentVehicleNet and NetToVeh(currentVehicleNet) or getClosestVehicleToScrapyard()
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then
        Bridge.ClientNotify('No vehicle found inside the scrapyard zone.', 'error')
        return
    end
    if not isVehicleInScrapyard(vehicle) then
        Bridge.ClientNotify('Bring the vehicle closer to the scrapyard processing area.', 'error')
        return
    end

    local vehNet = getVehNet(vehicle)
    local plate = QBCore.Functions.GetPlate(vehicle)
    local model = GetEntityModel(vehicle)
    local class = GetVehicleClass(vehicle)

    actionLocks[actionName] = true
    QBCore.Functions.TriggerCallback('astro-npcscrap:server:canAction', function(ok, msg)
        if not ok then
            Bridge.ClientNotify(msg or 'You cannot do that right now.', 'error')
            actionLocks[actionName] = false
            return
        end

        local workCoords = getActionWorkCoords(vehicle, actionName)
        local walked = walkToCoords(workCoords, Config.Workflow and Config.Workflow.VehicleStopDistance or 1.6, Config.Workflow and Config.Workflow.WalkTimeoutSeconds or 15)
        if not walked then
            Bridge.ClientNotify('You could not reach the vehicle.', 'error')
            actionLocks[actionName] = false
            returnToScrapPedAndReopen()
            return
        end
        faceEntity(vehicle)

        if actionName == 'SearchTrunk' then
            SetVehicleDoorOpen(vehicle, 5, false, false)
        elseif actionName == 'StripEngine' or actionName == 'CleanStrip' or actionName == 'PartOut' then
            SetVehicleDoorOpen(vehicle, 4, false, false)
            SetVehicleDoorOpen(vehicle, 5, false, false)
            for door = 0, 3 do SetVehicleDoorOpen(vehicle, door, false, false) end
        elseif actionName == 'SearchGlovebox' then
            SetVehicleDoorOpen(vehicle, 0, false, false)
        end

        local done = progress(action.label, action.duration, action.anim, action.prop)
        if not done then
            Bridge.ClientNotify('Action cancelled.', 'error')
            actionLocks[actionName] = false
            returnToScrapPedAndReopen()
            return
        end

        if actionName == 'TorchVehicle' then
            safeTorchVisuals(vehicle)
            Wait(1500)
        end

        TriggerServerEvent('astro-npcscrap:server:finishAction', actionName, vehNet, plate, model, class)

        if actionName == 'CrushVehicle' or actionName == 'QuickDump' then
            if requestControl(vehicle) then
                SetEntityAsMissionEntity(vehicle, true, true)
                DeleteVehicle(vehicle)
                if DoesEntityExist(vehicle) then DeleteEntity(vehicle) end
            end
            currentVehicleNet = nil
        end

        actionLocks[actionName] = false
        returnToScrapPedAndReopen()
    end, actionName, vehNet, plate, model, class)
end

local function openScrapyardUiWithVehicle(vehicle)
    local plate, model, class = '', 0, 0
    if vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) then
        currentVehicleNet = getVehNet(vehicle)
        plate = QBCore.Functions.GetPlate(vehicle)
        model = GetEntityModel(vehicle)
        class = GetVehicleClass(vehicle)
    else
        currentVehicleNet = nil
    end

    currentUiVehicle = { plate = plate, class = class, model = model }

    QBCore.Functions.TriggerCallback('astro-npcscrap:server:getUiData', function(data)
        uiOpen = true
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = 'open',
            data = data or {},
            vehicle = currentUiVehicle
        })
    end, plate, model, class)
end

openScrapyardMenu = function()
    local vehicle = getClosestVehicleToScrapyard()
    openScrapyardUiWithVehicle(vehicle)
end

local function refreshScrapyardUi()
    local vehicle = currentVehicleNet and NetToVeh(currentVehicleNet) or getClosestVehicleToScrapyard()
    openScrapyardUiWithVehicle(vehicle)
end

RegisterNUICallback('close', function(_, cb)
    closeScrapyardUi()
    cb({ ok = true })
end)

RegisterNUICallback('action', function(data, cb)
    local actionName = data and data.actionName
    closeScrapyardUi()
    if actionName then startAction(actionName) end
    cb({ ok = true })
end)

RegisterNUICallback('trade', function(data, cb)
    local item = data and data.item
    if not item then cb({ ok = false }) return end
    QBCore.Functions.TriggerCallback('astro-npcscrap:server:recycleItem', function(ok, trades)
        SendNUIMessage({ action = 'trades', trades = trades or {} })
        cb({ ok = ok == true, trades = trades or {} })
    end, item)
end)

local function openRecycleMenu()
    openScrapyardUiWithVehicle(getClosestVehicleToScrapyard())
end

RegisterNetEvent('astro-npcscrap:client:doAction', function(actionName)
    startAction(actionName)
end)

RegisterNetEvent('astro-npcscrap:client:recycleItem', function(item)
    TriggerServerEvent('astro-npcscrap:server:recycleItem', item)
end)

RegisterNetEvent('astro-npcscrap:client:statusMenu', function()
    QBCore.Functions.TriggerCallback('astro-npcscrap:server:getStatus', function(data)
        local menu = {
            { header = 'Scrapyard Status', txt = 'Developed by Opie Winters', isMenuHeader = true },
            { header = data.level or 'Rookie Scrapper', txt = ('Reputation: %s points'):format(data.rep or 0), isMenuHeader = true },
        }
        if data.orders and #data.orders > 0 then
            for _, order in ipairs(data.orders) do
                menu[#menu + 1] = {
                    header = order.label,
                    txt = ('Progress: %s/%s | Reward: $%s + %s rep'):format(order.progress or 0, order.amount or 0, order.money or 0, order.rep or 0),
                    isMenuHeader = true
                }
            end
        else
            menu[#menu + 1] = { header = 'No active orders', txt = 'Orders are disabled in config.', isMenuHeader = true }
        end
        menu[#menu + 1] = { header = 'Back', params = { event = 'astro-npcscrap:client:openScrapyard' } }
        menu[#menu + 1] = { header = 'Close', params = { event = 'qb-menu:closeMenu' } }
        exports['qb-menu']:openMenu(menu)
    end)
end)

RegisterNetEvent('astro-npcscrap:client:openScrapyard', openScrapyardMenu)
RegisterNetEvent('astro-npcscrap:client:openRecycle', openRecycleMenu)

CreateThread(function()
    createBlip(Config.Scrapyard.Blip, Config.Scrapyard.Ped.coords)
    createBlip(Config.RecyclingCenter.Blip, Config.RecyclingCenter.Ped.coords)

    spawnPed(Config.Scrapyard.Ped, 'scrapyard', {
        {
            icon = 'fas fa-car-burst',
            label = 'Open Scrapyard',
            action = function() openScrapyardMenu() end,
        }
    })

    spawnPed(Config.RecyclingCenter.Ped, 'recycling', {
        {
            icon = 'fas fa-recycle',
            label = 'Recycle Dirty Scrap',
            action = function() openRecycleMenu() end,
        }
    })
end)

CreateThread(function()
    if getInteractionType() ~= 'drawtext' then return end
    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)

        local sCoords = vector3(Config.Scrapyard.Ped.coords.x, Config.Scrapyard.Ped.coords.y, Config.Scrapyard.Ped.coords.z)
        if #(coords - sCoords) < 2.0 then
            sleep = 0
            DrawText3D(sCoords.x, sCoords.y, sCoords.z + 1.0, '[E] Open Scrapyard')
            if IsControlJustPressed(0, 38) then openScrapyardMenu() end
        end

        local rCoords = vector3(Config.RecyclingCenter.Ped.coords.x, Config.RecyclingCenter.Ped.coords.y, Config.RecyclingCenter.Ped.coords.z)
        if #(coords - rCoords) < 2.0 then
            sleep = 0
            DrawText3D(rCoords.x, rCoords.y, rCoords.z + 1.0, '[E] Recycle Dirty Scrap')
            if IsControlJustPressed(0, 38) then openRecycleMenu() end
        end

        Wait(sleep)
    end
end)

function DrawText3D(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry('STRING')
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0125, 0.017 + factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    closeScrapyardUi()
    for _, ped in ipairs(createdPeds) do
        if DoesEntityExist(ped) then DeleteEntity(ped) end
    end
end)
