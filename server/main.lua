local QBCore = exports[Config.CoreName]:GetCoreObject()

local vehicleStates = {}
local playerCooldowns = {}
local playerHeat = {}
local playerRep = {}
local playerOrders = {}

local function dbg(...)
    if Config.Debug then print('[astro-npcscrap:server]', ...) end
end

local function now()
    return os.time()
end

local function roll(chance)
    chance = tonumber(chance) or 0
    if chance <= 0 then return false end
    if chance >= 100 then return true end
    return (math.random() * 100) <= chance
end

local function rand(min, max)
    min = tonumber(min) or 1
    max = tonumber(max) or min
    if max < min then max = min end
    return math.random(min, max)
end

local function stateKey(plate, model)
    plate = tostring(plate or 'UNKNOWN'):gsub('%s+', '')
    return plate .. ':' .. tostring(model or 0)
end

local function getVehicleState(plate, model)
    local key = stateKey(plate, model)
    vehicleStates[key] = vehicleStates[key] or {
        created = now(),
        actions = {},
        crushed = false,
    }
    return key, vehicleStates[key]
end

local function getCitizenId(src)
    local Player = QBCore.Functions.GetPlayer(src)
    return Player and Player.PlayerData and Player.PlayerData.citizenid or tostring(src)
end

local function gradeForVehicle(state, class)
    if state.grade then return state.grade end
    local boost = (Config.Scanner and Config.Scanner.classGradeBoost and Config.Scanner.classGradeBoost[class]) or 0
    local score = math.random(1, 100) + boost
    if score >= 88 then state.grade = 'A'
    elseif score >= 62 then state.grade = 'B'
    elseif score >= 32 then state.grade = 'C'
    else state.grade = 'D' end
    return state.grade
end

local function repLevel(points)
    local selected = (Config.Reputation.levels and Config.Reputation.levels[1]) or { label = 'Rookie Scrapper', rewardMultiplier = 1.0 }
    for _, level in ipairs(Config.Reputation.levels or {}) do
        if points >= (level.required or 0) then selected = level end
    end
    return selected
end

local function addRep(src, amount)
    if not Config.Reputation or not Config.Reputation.enabled then return end
    amount = tonumber(amount) or 0
    if amount <= 0 then return end
    local cid = getCitizenId(src)
    playerRep[cid] = (playerRep[cid] or 0) + amount
end

local function getOrdersFor(src)
    local cid = getCitizenId(src)
    local resetAfter = (Config.Orders and Config.Orders.resetMinutes or 180) * 60
    if not playerOrders[cid] or now() > playerOrders[cid].resetAt then
        playerOrders[cid] = { resetAt = now() + resetAfter, progress = {}, completed = {} }
    end
    return playerOrders[cid]
end

local function updateOrders(src, actionName)
    if not Config.Orders or not Config.Orders.enabled then return end
    local data = getOrdersFor(src)
    for _, order in ipairs(Config.Orders.list or {}) do
        if order.action == actionName and not data.completed[order.id] then
            data.progress[order.id] = (data.progress[order.id] or 0) + 1
            if data.progress[order.id] >= (order.amount or 1) then
                data.completed[order.id] = true
                addRep(src, order.rep or 0)
                if (order.money or 0) > 0 then Bridge.AddMoney(src, 'cash', order.money, 'scrapyard-order') end
                Bridge.Notify(src, ('Order complete: %s | +%s rep | $%s'):format(order.label, order.rep or 0, order.money or 0), 'success', 8500)
            else
                Bridge.Notify(src, ('Order progress: %s %s/%s'):format(order.label, data.progress[order.id], order.amount or 1), 'primary')
            end
        end
    end
end

local function cleanupStates()
    local expiry = now() - ((Config.VehicleCooldownMinutes or 120) * 60)
    for key, data in pairs(vehicleStates) do
        if data.created < expiry then vehicleStates[key] = nil end
    end
end

CreateThread(function()
    while true do
        cleanupStates()
        Wait(10 * 60 * 1000)
    end
end)

local function isPlayerOwnedPlate(plate)
    if not plate then return false end
    local clean = tostring(plate):gsub('^%s*(.-)%s*$', '%1')
    local row = MySQL.single.await('SELECT plate FROM player_vehicles WHERE plate = ? LIMIT 1', { clean })
    return row ~= nil
end

local function isVehicleAllowed(model, class)
    if Config.BlacklistedClasses[class] then return false, 'This vehicle class cannot be scrapped.' end
    if Config.BlacklistedModels[model] then return false, 'This vehicle model cannot be scrapped.' end
    return true
end


local function itemLabel(item)
    if Config.GetItemLabel then return Config.GetItemLabel(item) end
    return (Config.ItemLabels and Config.ItemLabels[item]) or item
end

local function prerequisitesDone(state, actionName)
    local prereqs = Config.ActionPrerequisites and Config.ActionPrerequisites[actionName]
    if not prereqs then return true end

    for _, requiredAction in ipairs(prereqs) do
        if not state.actions[requiredAction] then
            local label = (Config.Actions[requiredAction] and Config.Actions[requiredAction].label) or requiredAction
            return false, ('You must complete %s first.'):format(label)
        end
    end

    return true
end

local function addHeat(src)
    if not Config.Heat.enabled then return end
    local cid = tostring(src)
    local resetAfter = (Config.Heat.resetMinutes or 60) * 60
    playerHeat[cid] = playerHeat[cid] or { count = 0, resetAt = now() + resetAfter }

    if now() > playerHeat[cid].resetAt then
        playerHeat[cid] = { count = 0, resetAt = now() + resetAfter }
    end

    playerHeat[cid].count = playerHeat[cid].count + 1

    if playerHeat[cid].count > (Config.Heat.safeActionsPerWindow or 5) and roll(Config.Heat.alertChanceAfterSafe or 25) then
        TriggerEvent(Config.Heat.alertEvent, Config.Heat.alertMessage)
    end
end

local function giveRewards(src, rewardList, multiplier)
    multiplier = multiplier or 1.0
    local given = {}

    for _, reward in ipairs(rewardList or {}) do
        if roll(reward.chance) then
            local amount = rand(reward.min, reward.max)
            amount = math.max(1, math.floor(amount * multiplier))
            if Bridge.AddItem(src, reward.item, amount) then
                given[#given + 1] = ('%sx %s'):format(amount, itemLabel(reward.item))
            end
        end
    end

    if #given > 0 then
        Bridge.Notify(src, 'Received: ' .. table.concat(given, ', '), 'success', 7500)
    else
        Bridge.Notify(src, 'You did not find anything useful.', 'primary')
    end
end

local function removeToolChance(src, item)
    if not item then return end
    local chance = Config.ToolBreakChance[item] or 0
    if chance > 0 and roll(chance) then
        Bridge.RemoveItem(src, item, 1)
        Bridge.Notify(src, ('Your %s broke during the job.'):format(itemLabel(item)), 'error')
    end
end

QBCore.Functions.CreateCallback('astro-npcscrap:server:canAction', function(src, cb, actionName, vehNet, plate, model, class)
    if not actionName or not Config.Actions[actionName] then
        cb(false, 'Invalid scrapyard action.')
        return
    end

    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then cb(false, 'Player not found.') return end

    if (Config.PlayerScrapCooldownSeconds or 0) > 0 and playerCooldowns[src] and playerCooldowns[src] > now() then
        cb(false, 'Slow down before doing another scrapyard action.')
        return
    end

    local allowed, reason = isVehicleAllowed(model, class)
    if not allowed then cb(false, reason) return end

    if isPlayerOwnedPlate(plate) then
        cb(false, 'This plate belongs to a player-owned vehicle. You cannot scrap it.')
        return
    end

    local _, state = getVehicleState(plate, model)
    if state.crushed then
        cb(false, 'This vehicle has already been crushed.')
        return
    end

    if state.actions[actionName] then
        cb(false, 'You already completed this step on this vehicle.')
        return
    end

    local prereqOk, prereqMsg = prerequisitesDone(state, actionName)
    if not prereqOk then
        cb(false, prereqMsg)
        return
    end

    local requiredItem = Config.RequiredTools[actionName]
    if requiredItem and not Bridge.HasItem(src, requiredItem, 1) then
        cb(false, ('You need %s for this action.'):format(itemLabel(requiredItem)))
        return
    end

    if actionName == 'CrushVehicle' and not (state.actions.TorchVehicle or state.actions.StripEngine or state.actions.StripBrakes or state.actions.SearchTrunk or state.actions.CleanStrip or state.actions.PartOut) then
        cb(false, 'Search, strip, part-out, or torch the vehicle before crushing it.')
        return
    end

    cb(true)
end)

RegisterNetEvent('astro-npcscrap:server:finishAction', function(actionName, vehNet, plate, model, class)
    local src = source
    if not actionName or not Config.Actions[actionName] then return end

    local allowed = isVehicleAllowed(model, class)
    if not allowed then return end
    if isPlayerOwnedPlate(plate) then
        Bridge.Notify(src, 'This is player-owned. Scrapping blocked.', 'error')
        return
    end

    local key, state = getVehicleState(plate, model)
    if state.crushed or state.actions[actionName] then return end

    local prereqOk, prereqMsg = prerequisitesDone(state, actionName)
    if not prereqOk then
        Bridge.Notify(src, prereqMsg or 'Previous scrapyard step required first.', 'error')
        return
    end

    local requiredItem = Config.RequiredTools[actionName]
    if requiredItem and not Bridge.HasItem(src, requiredItem, 1) then
        Bridge.Notify(src, ('You need %s for this action.'):format(itemLabel(requiredItem)), 'error')
        return
    end

    if (Config.PlayerScrapCooldownSeconds or 0) > 0 then
        playerCooldowns[src] = now() + (Config.PlayerScrapCooldownSeconds or 0)
    end
    state.actions[actionName] = true
    if actionName == 'CrushVehicle' or actionName == 'QuickDump' then state.crushed = true end

    removeToolChance(src, requiredItem)
    addHeat(src)

    local baseRep = (Config.Reputation and Config.Reputation.points and Config.Reputation.points[actionName]) or 0
    addRep(src, baseRep)

    if actionName == 'ScanVehicle' then
        local grade = gradeForVehicle(state, class)
        local gradeText = (Config.Scanner and Config.Scanner.gradeLabels and Config.Scanner.gradeLabels[grade]) or grade
        Bridge.Notify(src, ('Scan complete: %s (%s grade). Better grade means better scrap potential.'):format(gradeText, grade), 'primary', 8500)
        updateOrders(src, actionName)
        return
    end

    local cid = getCitizenId(src)
    local rep = playerRep[cid] or 0
    local level = repLevel(rep)
    local multiplier = level.rewardMultiplier or 1.0
    if actionName == 'CrushVehicle' or actionName == 'CleanStrip' or actionName == 'PartOut' or actionName == 'QuickDump' then
        multiplier = multiplier * (Config.VehicleClassBonus[class] or 1.0)
    end

    giveRewards(src, Config.Rewards[actionName], multiplier)

    -- Extra high-value non-EV mechanic part rolls for higher vehicle classes.
    -- This keeps normal NPC cars balanced while making muscle/sports/super/commercial vehicles more valuable.
    if actionName == 'StripEngine' or actionName == 'CleanStrip' or actionName == 'PartOut' then
        local classBonusRewards = Config.ClassBonusRewards and Config.ClassBonusRewards[class]
        if classBonusRewards then
            giveRewards(src, classBonusRewards, 1.0)
        end
    end

    updateOrders(src, actionName)
    dbg(('Action %s complete for %s by %s'):format(actionName, key, src))
end)

QBCore.Functions.CreateCallback('astro-npcscrap:server:getStatus', function(src, cb)
    local cid = getCitizenId(src)
    local rep = playerRep[cid] or 0
    local level = repLevel(rep)
    local orders = {}
    if Config.Orders and Config.Orders.enabled then
        local data = getOrdersFor(src)
        for _, order in ipairs(Config.Orders.list or {}) do
            orders[#orders + 1] = {
                id = order.id,
                label = order.label,
                amount = order.amount,
                rep = order.rep,
                money = order.money,
                progress = math.min(data.progress[order.id] or 0, order.amount or 1),
                completed = data.completed[order.id] or false,
            }
        end
    end
    cb({ rep = rep, level = level.label, orders = orders })
end)


local function buildTradeData(src)
    local trades = {}
    for dirtyItem, outputs in pairs(Config.RecyclingTrades or {}) do
        local outputLabels = {}
        for _, output in ipairs(outputs or {}) do
            outputLabels[#outputLabels + 1] = ('%s-%s %s'):format(output.min or 1, output.max or output.min or 1, itemLabel(output.item))
        end
        trades[#trades + 1] = {
            item = dirtyItem,
            label = itemLabel(dirtyItem),
            count = Bridge.GetItemCount(src, dirtyItem),
            outputs = outputLabels
        }
    end
    table.sort(trades, function(a, b) return a.label < b.label end)
    return trades
end

QBCore.Functions.CreateCallback('astro-npcscrap:server:getUiData', function(src, cb, plate, model, class)
    local _, state = getVehicleState(plate, model)
    local cid = getCitizenId(src)
    local rep = playerRep[cid] or 0
    local level = repLevel(rep)
    local actions = {}
    for actionName, _ in pairs(Config.Actions or {}) do
        actions[actionName] = state.actions[actionName] == true
    end

    local orders = {}
    if Config.Orders and Config.Orders.enabled then
        local data = getOrdersFor(src)
        for _, order in ipairs(Config.Orders.list or {}) do
            orders[#orders + 1] = {
                id = order.id,
                label = order.label,
                amount = order.amount,
                progress = math.min(data.progress[order.id] or 0, order.amount or 1),
                completed = data.completed[order.id] or false,
            }
        end
    end

    cb({
        plate = tostring(plate or ''):gsub('^%s*(.-)%s*$', '%1'),
        grade = state.grade,
        crushed = state.crushed == true,
        actions = actions,
        rep = rep,
        level = level.label,
        orders = orders,
        trades = buildTradeData(src),
    })
end)


local function doRecycleItem(src, item)
    local trades = Config.RecyclingTrades[item]
    if not trades then
        Bridge.Notify(src, 'That item cannot be recycled here.', 'error')
        return false
    end
    if not Bridge.HasItem(src, item, 1) then
        Bridge.Notify(src, ('You do not have any %s.'):format(itemLabel(item)), 'error')
        return false
    end
    local removed = 0
    for i = 1, 100 do
        if Bridge.HasItem(src, item, 1) then
            if Bridge.RemoveItem(src, item, 1) then removed = removed + 1 else break end
        else break end
    end
    if removed <= 0 then
        Bridge.Notify(src, 'Nothing was recycled.', 'error')
        return false
    end
    local received = {}
    for i = 1, removed do
        for _, output in ipairs(trades) do
            local amount = rand(output.min, output.max)
            if Bridge.AddItem(src, output.item, amount) then
                received[output.item] = (received[output.item] or 0) + amount
            end
        end
    end
    local parts = {}
    for outputItem, amount in pairs(received) do parts[#parts + 1] = ('%sx %s'):format(amount, itemLabel(outputItem)) end
    Bridge.Notify(src, ('Recycled %sx %s into: %s'):format(removed, itemLabel(item), table.concat(parts, ', ')), 'success', 8500)
    return true
end

QBCore.Functions.CreateCallback('astro-npcscrap:server:recycleItem', function(src, cb, item)
    local ok = doRecycleItem(src, item)
    cb(ok, buildTradeData(src))
end)

RegisterNetEvent('astro-npcscrap:server:recycleItem', function(item)
    doRecycleItem(source, item)
end)
