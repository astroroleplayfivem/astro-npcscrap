Bridge = Bridge or {}

local function resourceStarted(name)
    return name and name ~= '' and GetResourceState(name) == 'started'
end

local function getQBCore()
    return exports[Config.CoreName or 'qb-core']:GetCoreObject()
end

function Bridge.Core()
    return getQBCore()
end

function Bridge.InventoryType()
    local selected = Config.Inventory
    if selected and selected ~= '' and selected ~= 'auto' then return selected end
    if resourceStarted('tgiann-inventory') then return 'tgiann' end
    if resourceStarted('ox_inventory') then return 'ox' end
    if resourceStarted('qb-inventory') then return 'qb-inventory' end
    return 'qb'
end

function Bridge.Notify(src, msg, msgType, time)
    msgType = msgType or 'primary'
    time = time or 5000
    if src and src > 0 then
        TriggerClientEvent('QBCore:Notify', src, msg, msgType, time)
    else
        TriggerEvent('QBCore:Notify', msg, msgType, time)
    end
end

function Bridge.ClientNotify(msg, msgType, time)
    TriggerEvent('QBCore:Notify', msg, msgType or 'primary', time or 5000)
end

local function getPlayerItem(src, item)
    local QBCore = Bridge.Core()
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return nil, nil, QBCore end
    return Player.Functions.GetItemByName(item), Player, QBCore
end

function Bridge.HasItem(src, item, amount)
    if not item or item == '' then return true end
    amount = amount or 1
    local inv = Bridge.InventoryType()

    if inv == 'ox' then
        local count = exports.ox_inventory:Search(src, 'count', item) or 0
        return count >= amount
    end

    if inv == 'qb-inventory' and resourceStarted('qb-inventory') and exports['qb-inventory'].HasItem then
        local ok, hasItem = pcall(function()
            return exports['qb-inventory']:HasItem(src, item, amount)
        end)
        if ok then return hasItem == true end
    end

    local data = getPlayerItem(src, item)
    return data and (data.amount or data.count or 0) >= amount
end

function Bridge.GetItemCount(src, item)
    if not item or item == '' then return 0 end
    local inv = Bridge.InventoryType()

    if inv == 'ox' then
        return exports.ox_inventory:Search(src, 'count', item) or 0
    end

    local data = getPlayerItem(src, item)
    return data and (data.amount or data.count or 0) or 0
end

function Bridge.AddItem(src, item, amount, metadata)
    amount = amount or 1
    metadata = metadata or {}
    local inv = Bridge.InventoryType()

    if inv == 'ox' then
        return exports.ox_inventory:AddItem(src, item, amount, metadata)
    end

    if inv == 'tgiann' and resourceStarted('tgiann-inventory') and exports['tgiann-inventory'].AddItem then
        local ok, result = pcall(function()
            return exports['tgiann-inventory']:AddItem(src, item, amount, nil, metadata)
        end)
        if ok and result ~= false then return result end
    end

    if inv == 'qb-inventory' and resourceStarted('qb-inventory') and exports['qb-inventory'].AddItem then
        local ok, result = pcall(function()
            return exports['qb-inventory']:AddItem(src, item, amount, false, metadata, 'astro-npcscrap')
        end)
        if ok and result ~= false then
            local QBCore = Bridge.Core()
            if QBCore.Shared and QBCore.Shared.Items then
                TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[item], 'add', amount)
            end
            return result
        end
    end

    local _, Player, QBCore = getPlayerItem(src, item)
    if not Player then return false end
    local ok = Player.Functions.AddItem(item, amount, false, metadata)
    if ok and QBCore.Shared and QBCore.Shared.Items then
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[item], 'add', amount)
    end
    return ok
end

function Bridge.RemoveItem(src, item, amount)
    if not item or item == '' then return true end
    amount = amount or 1
    local inv = Bridge.InventoryType()

    if inv == 'ox' then
        return exports.ox_inventory:RemoveItem(src, item, amount)
    end

    if inv == 'tgiann' and resourceStarted('tgiann-inventory') and exports['tgiann-inventory'].RemoveItem then
        local ok, result = pcall(function()
            return exports['tgiann-inventory']:RemoveItem(src, item, amount)
        end)
        if ok and result ~= false then return result end
    end

    if inv == 'qb-inventory' and resourceStarted('qb-inventory') and exports['qb-inventory'].RemoveItem then
        local ok, result = pcall(function()
            return exports['qb-inventory']:RemoveItem(src, item, amount, false, 'astro-npcscrap')
        end)
        if ok and result ~= false then
            local QBCore = Bridge.Core()
            if QBCore.Shared and QBCore.Shared.Items then
                TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[item], 'remove', amount)
            end
            return result
        end
    end

    local _, Player, QBCore = getPlayerItem(src, item)
    if not Player then return false end
    local ok = Player.Functions.RemoveItem(item, amount)
    if ok and QBCore.Shared and QBCore.Shared.Items then
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[item], 'remove', amount)
    end
    return ok
end

function Bridge.AddMoney(src, account, amount, reason)
    amount = tonumber(amount) or 0
    if amount <= 0 then return false end
    local QBCore = Bridge.Core()
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end
    return Player.Functions.AddMoney(account or 'cash', amount, reason or 'astro-npcscrap')
end
