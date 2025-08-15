ESX = exports['es_extended']:getSharedObject()

-- Player data cache
local playerData = {}
local rateLimitCache = {}

-- Initialize database
CreateThread(function()
    MySQL.ready(function()
        print('[jr_battlepass] Database connection established')
    end)
end)

-- Handle player loaded
RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(playerId, xPlayer)
    LoadPlayerBattlepassData(playerId)
end)

-- Handle player dropped
RegisterNetEvent('esx:playerDropped')
AddEventHandler('esx:playerDropped', function(playerId)
    if playerData[playerId] then
        SavePlayerBattlepassData(playerId)
        playerData[playerId] = nil
    end
    
    if rateLimitCache[playerId] then
        rateLimitCache[playerId] = nil
    end
end)

-- Load player battlepass data
function LoadPlayerBattlepassData(playerId)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return end
    
    local identifier = xPlayer.getIdentifier()
    
    MySQL.Async.fetchAll('SELECT * FROM battlepass_players WHERE identifier = @identifier', {
        ['@identifier'] = identifier
    }, function(result)
        if result[1] then
            playerData[playerId] = {
                identifier = identifier,
                level = result[1].level,
                xp = result[1].xp,
                coins = result[1].coins,
                premium = result[1].premium,
                premium_expires = result[1].premium_expires,
                daily_streak = result[1].daily_streak,
                last_daily_claim = result[1].last_daily_claim,
                season_id = result[1].season_id
            }
        else
            -- Create new player record
            MySQL.Async.execute('INSERT INTO battlepass_players (identifier) VALUES (@identifier)', {
                ['@identifier'] = identifier
            }, function(rowsChanged)
                if rowsChanged > 0 then
                    playerData[playerId] = {
                        identifier = identifier,
                        level = 1,
                        xp = 0,
                        coins = 0,
                        premium = false,
                        premium_expires = nil,
                        daily_streak = 0,
                        last_daily_claim = nil,
                        season_id = Config.SeasonId
                    }
                end
            end)
        end
    end)
end

-- Save player battlepass data
function SavePlayerBattlepassData(playerId)
    local data = playerData[playerId]
    if not data then return end
    
    MySQL.Async.execute('UPDATE battlepass_players SET level = @level, xp = @xp, coins = @coins, premium = @premium, premium_expires = @premium_expires, daily_streak = @daily_streak, last_daily_claim = @last_daily_claim, season_id = @season_id WHERE identifier = @identifier', {
        ['@identifier'] = data.identifier,
        ['@level'] = data.level,
        ['@xp'] = data.xp,
        ['@coins'] = data.coins,
        ['@premium'] = data.premium,
        ['@premium_expires'] = data.premium_expires,
        ['@daily_streak'] = data.daily_streak,
        ['@last_daily_claim'] = data.last_daily_claim,
        ['@season_id'] = data.season_id
    })
end

-- Rate limiting check
function IsRateLimited(playerId)
    local currentTime = os.time()
    if rateLimitCache[playerId] and (currentTime - rateLimitCache[playerId]) < Config.Security.rateLimitSeconds then
        return true
    end
    rateLimitCache[playerId] = currentTime
    return false
end

-- Request player data
RegisterNetEvent('jr_battlepass:requestPlayerData')
AddEventHandler('jr_battlepass:requestPlayerData', function()
    local playerId = source
    local data = playerData[playerId]
    
    if data then
        -- Check if premium has expired
        if data.premium and data.premium_expires then
            local currentTime = os.time()
            local expiresTime = data.premium_expires
            
            if type(expiresTime) == 'string' then
                -- Convert MySQL timestamp to Unix timestamp
                expiresTime = os.time(string.gmatch(expiresTime, "(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)"))
            end
            
            if currentTime > expiresTime then
                data.premium = false
                data.premium_expires = nil
            end
        end
        
        TriggerClientEvent('jr_battlepass:receivePlayerData', playerId, data)
    end
end)

-- Give XP to player
function GivePlayerXP(playerId, amount, reason)
    local data = playerData[playerId]
    if not data then return false end
    
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return false end
    
    -- Apply premium multiplier
    if data.premium and Config.PremiumBenefits.xpMultiplier then
        amount = math.floor(amount * Config.PremiumBenefits.xpMultiplier)
    end
    
    -- Anti-cheat: Check XP per hour limit
    if Config.Security.maxXPPerHour and amount > Config.Security.maxXPPerHour then
        print(('[jr_battlepass] WARNING: Player %s tried to gain %s XP (limit: %s)'):format(xPlayer.getName(), amount, Config.Security.maxXPPerHour))
        return false
    end
    
    data.xp = data.xp + amount
    local oldLevel = data.level
    local newLevel = CalculateLevel(data.xp)
    
    if newLevel > oldLevel then
        data.level = newLevel
        -- Handle level up rewards
        HandleLevelUp(playerId, oldLevel, newLevel)
    end
    
    -- Save to database
    SavePlayerBattlepassData(playerId)
    
    -- Notify client
    TriggerClientEvent('jr_battlepass:xpGained', playerId, amount, data.xp, data.level)
    
    if Config.Debug then
        print(('[jr_battlepass] Player %s gained %s XP (%s)'):format(xPlayer.getName(), amount, reason or 'Unknown'))
    end
    
    return true
end

-- Calculate level based on XP
function CalculateLevel(xp)
    local level = 1
    local totalXPNeeded = 0
    
    for i = 1, Config.MaxLevel do
        totalXPNeeded = totalXPNeeded + (Config.XPPerLevel[i] or 0)
        if xp >= totalXPNeeded then
            level = i + 1
        else
            break
        end
    end
    
    return math.min(level, Config.MaxLevel)
end

-- Handle level up rewards
function HandleLevelUp(playerId, oldLevel, newLevel)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return end
    
    -- Give rewards for each level gained
    for level = oldLevel + 1, newLevel do
        -- Free track reward
        if Config.LevelRewards[level] then
            GiveReward(playerId, Config.LevelRewards[level], 'level_free')
        end
        
        -- Premium track reward
        local data = playerData[playerId]
        if data and data.premium and Config.PremiumLevelRewards[level] then
            GiveReward(playerId, Config.PremiumLevelRewards[level], 'level_premium')
        end
    end
    
    -- Special notification for milestone levels
    if newLevel % 10 == 0 or newLevel == Config.MaxLevel then
        TriggerClientEvent('jr_battlepass:specialReward', playerId, 'milestone', {
            level = newLevel,
            label = ('Level %s Milestone!'):format(newLevel)
        })
    end
end

-- Generic reward giving function
function GiveReward(playerId, reward, rewardType)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return false end
    
    local success = true
    local message = ''
    
    if reward.type == 'money' then
        xPlayer.addMoney(reward.amount)
        message = ('Received €%s cash'):format(reward.amount)
        
    elseif reward.type == 'bank' then
        xPlayer.addAccountMoney('bank', reward.amount)
        message = ('Received €%s in bank'):format(reward.amount)
        
    elseif reward.type == 'item' then
        if xPlayer.canCarryItem(reward.item, reward.amount) then
            xPlayer.addInventoryItem(reward.item, reward.amount)
            message = ('Received %sx %s'):format(reward.amount, reward.item)
        else
            success = false
            message = 'Inventory full!'
        end
        
    elseif reward.type == 'vehicle' then
        -- Handle vehicle spawning (requires integration with vehicle system)
        success = HandleVehicleReward(playerId, reward)
        message = success and ('Received vehicle: %s'):format(reward.label) or 'Failed to receive vehicle'
        
    elseif reward.type == 'lootbox' then
        success = OpenLootBox(playerId, reward.box)
        message = success and ('Received %s'):format(reward.label) or 'Failed to open loot box'
        
    elseif reward.type == 'mixed' then
        if reward.money then
            xPlayer.addMoney(reward.money)
        end
        if reward.items then
            for _, item in pairs(reward.items) do
                if xPlayer.canCarryItem(item.item, item.amount) then
                    xPlayer.addInventoryItem(item.item, item.amount)
                end
            end
        end
        message = reward.label or 'Received mixed rewards'
        
    elseif reward.type == 'mega' then
        xPlayer.addMoney(reward.money or 15000)
        if reward.item then
            xPlayer.addInventoryItem(reward.item, 1)
        end
        message = 'MEGA BONUS RECEIVED!'
        
        TriggerClientEvent('jr_battlepass:specialReward', playerId, 'mega', {
            money = reward.money or 15000,
            item_label = reward.label
        })
    end
    
    -- Log reward to database
    LogReward(playerId, rewardType, reward, success)
    
    return success, message
end

-- Handle vehicle rewards
function HandleVehicleReward(playerId, reward)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return false end
    
    -- This would need integration with your vehicle system
    -- Example implementation:
    TriggerEvent('esx_vehicleshop:setVehicleOwned', xPlayer.getIdentifier(), reward.model, {})
    
    -- Special notification for vehicle
    TriggerClientEvent('jr_battlepass:specialReward', playerId, 'vehicle', reward)
    
    return true
end

-- Log reward to database
function LogReward(playerId, rewardType, rewardData, success)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return end
    
    MySQL.Async.execute('INSERT INTO battlepass_rewards (identifier, reward_type, reward_data) VALUES (@identifier, @type, @data)', {
        ['@identifier'] = xPlayer.getIdentifier(),
        ['@type'] = rewardType,
        ['@data'] = json.encode(rewardData)
    })
end

-- Claim reward event
RegisterNetEvent('jr_battlepass:claimReward')
AddEventHandler('jr_battlepass:claimReward', function(rewardType, level)
    local playerId = source
    
    if IsRateLimited(playerId) then
        TriggerClientEvent('jr_battlepass:rewardClaimed', playerId, false, 'Please wait before claiming another reward')
        return
    end
    
    local data = playerData[playerId]
    if not data then return end
    
    local reward = nil
    local canClaim = false
    
    if rewardType == 'free' and Config.LevelRewards[level] then
        reward = Config.LevelRewards[level]
        canClaim = data.level >= level
    elseif rewardType == 'premium' and Config.PremiumLevelRewards[level] then
        reward = Config.PremiumLevelRewards[level]
        canClaim = data.level >= level and data.premium
    end
    
    if reward and canClaim then
        local success, message = GiveReward(playerId, reward, rewardType)
        TriggerClientEvent('jr_battlepass:rewardClaimed', playerId, success, message)
    else
        TriggerClientEvent('jr_battlepass:rewardClaimed', playerId, false, 'Cannot claim this reward')
    end
end)

-- Handle mission update
RegisterNetEvent('jr_battlepass:updateMission')
AddEventHandler('jr_battlepass:updateMission', function(missionId, progress)
    local playerId = source
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return end
    
    if IsRateLimited(playerId) then
        return
    end
    
    local identifier = xPlayer.getIdentifier()
    local missionType = 'daily'
    local expiresAt = os.date('%Y-%m-%d 23:59:59')
    
    -- Check if it's a weekly mission
    local weeklyMissions = {'races', 'jobs', 'farming', 'combat'}
    for _, weeklyId in pairs(weeklyMissions) do
        if missionId == weeklyId then
            missionType = 'weekly'
            -- Calculate next Sunday
            local currentTime = os.time()
            local nextSunday = currentTime + (7 - os.date('*t', currentTime).wday) * 86400
            expiresAt = os.date('%Y-%m-%d 23:59:59', nextSunday)
            break
        end
    end
    
    -- Update mission progress
    UpdateMissionProgress(identifier, missionId, progress, missionType, expiresAt, function(success)
        if success then
            -- Check if mission is completed
            local missionData = nil
            local missions = missionType == 'daily' and Config.DailyMissions or Config.WeeklyMissions
            
            for _, mission in pairs(missions) do
                if mission.id == missionId then
                    missionData = mission
                    break
                end
            end
            
            if missionData and progress >= missionData.target then
                -- Mission completed!
                CompleteMission(identifier, missionId, function(completed)
                    if completed then
                        -- Give rewards
                        local reward = missionData.reward
                        if reward.xp then
                            GivePlayerXP(playerId, reward.xp, 'Mission: ' .. missionData.label)
                        end
                        if reward.money then
                            xPlayer.addMoney(reward.money)
                        end
                        if reward.items then
                            for _, item in pairs(reward.items) do
                                if xPlayer.canCarryItem(item.item, item.amount) then
                                    xPlayer.addInventoryItem(item.item, item.amount)
                                end
                            end
                        end
                        
                        -- Notify client
                        TriggerClientEvent('jr_battlepass:missionCompleted', playerId, missionData, reward)
                        
                        -- Log reward
                        LogReward(playerId, 'mission', missionData)
                    end
                end)
            end
            
            -- Send updated missions to client
            GetPlayerMissions(identifier, function(missions)
                TriggerClientEvent('jr_battlepass:missionUpdate', playerId, missions)
            end)
        end
    end)
end)

-- Request missions
RegisterNetEvent('jr_battlepass:requestMissions')
AddEventHandler('jr_battlepass:requestMissions', function()
    local playerId = source
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return end
    
    local identifier = xPlayer.getIdentifier()
    
    GetPlayerMissions(identifier, function(missions)
        -- Format missions for client
        local formattedMissions = {
            daily = {},
            weekly = {}
        }
        
        -- Add configured missions that don't exist yet
        for _, mission in pairs(Config.DailyMissions) do
            local found = false
            for _, playerMission in pairs(missions) do
                if playerMission.mission_id == mission.id and playerMission.mission_type == 'daily' then
                    found = true
                    break
                end
            end
            if not found then
                -- Create new mission
                local expiresAt = os.date('%Y-%m-%d 23:59:59')
                UpdateMissionProgress(identifier, mission.id, 0, 'daily', expiresAt)
            end
        end
        
        for _, mission in pairs(Config.WeeklyMissions) do
            local found = false
            for _, playerMission in pairs(missions) do
                if playerMission.mission_id == mission.id and playerMission.mission_type == 'weekly' then
                    found = true
                    break
                end
            end
            if not found then
                -- Create new mission
                local currentTime = os.time()
                local nextSunday = currentTime + (7 - os.date('*t', currentTime).wday) * 86400
                local expiresAt = os.date('%Y-%m-%d 23:59:59', nextSunday)
                UpdateMissionProgress(identifier, mission.id, 0, 'weekly', expiresAt)
            end
        end
        
        -- Get updated missions
        GetPlayerMissions(identifier, function(updatedMissions)
            for _, playerMission in pairs(updatedMissions) do
                local missionConfig = nil
                local missions = playerMission.mission_type == 'daily' and Config.DailyMissions or Config.WeeklyMissions
                
                for _, mission in pairs(missions) do
                    if mission.id == playerMission.mission_id then
                        missionConfig = mission
                        break
                    end
                end
                
                if missionConfig then
                    local missionData = {
                        id = playerMission.mission_id,
                        label = missionConfig.label,
                        description = missionConfig.description,
                        target = missionConfig.target,
                        reward = missionConfig.reward,
                        progress = playerMission.progress,
                        completed = playerMission.completed,
                        claimed = playerMission.claimed,
                        expires_at = playerMission.expires_at
                    }
                    
                    if playerMission.mission_type == 'daily' then
                        table.insert(formattedMissions.daily, missionData)
                    else
                        table.insert(formattedMissions.weekly, missionData)
                    end
                end
            end
            
            TriggerClientEvent('jr_battlepass:receiveMissions', playerId, formattedMissions)
        end)
    end)
end)

-- Export functions
exports('givePlayerXP', GivePlayerXP)
exports('getPlayerBattlepassData', function(playerId)
    return playerData[playerId]
end)
exports('getPlayerLevel', function(playerId)
    return playerData[playerId] and playerData[playerId].level or 1
end)
exports('getPlayerXP', function(playerId)
    return playerData[playerId] and playerData[playerId].xp or 0
end)

-- Save all player data periodically
CreateThread(function()
    while true do
        Wait(300000) -- Save every 5 minutes
        
        for playerId, _ in pairs(playerData) do
            SavePlayerBattlepassData(playerId)
        end
        
        if Config.Debug then
            print('[jr_battlepass] Saved all player data')
        end
    end
end)

-- Resource stop handler
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        -- Save all player data before stopping
        for playerId, _ in pairs(playerData) do
            SavePlayerBattlepassData(playerId)
        end
        print('[jr_battlepass] Saved all player data before stopping')
    end
end)