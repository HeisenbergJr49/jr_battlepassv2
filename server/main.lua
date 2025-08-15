local ESX = exports["es_extended"]:getSharedObject()
local Database = exports.jr_battlepassv2:getDatabase()
local Rewards = exports.jr_battlepassv2:getRewards()

-- 📊 Player data cache for performance
local PlayerCache = {}

-- 🔒 Rate limiting and security
local RateLimit = {}
local SecurityTokens = {}

-- 🎮 Initialize battlepass system
CreateThread(function()
    print("^2[JR.DEV Battlepass]^7 Starting battlepass system...")
    
    -- Check database connection
    if Database.checkConnection() then
        print("^2[JR.DEV Battlepass]^7 Database connection successful")
        
        -- Initialize daily missions reset timer
        SetTimeout(60000, function()
            ResetDailyMissions()
        end)
        
        -- Initialize weekly missions reset timer  
        SetTimeout(120000, function()
            ResetWeeklyMissions()
        end)
    else
        print("^1[JR.DEV Battlepass]^7 Database connection failed!")
    end
end)

-- 🔐 Security Functions
function ValidatePlayer(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    return xPlayer ~= nil
end

function CheckRateLimit(source)
    local identifier = GetPlayerIdentifier(source, 0)
    local currentTime = os.time()
    
    if not RateLimit[identifier] then
        RateLimit[identifier] = {requests = 0, lastReset = currentTime}
    end
    
    local timeDiff = currentTime - RateLimit[identifier].lastReset
    if timeDiff >= 60 then -- Reset every minute
        RateLimit[identifier] = {requests = 0, lastReset = currentTime}
    end
    
    RateLimit[identifier].requests = RateLimit[identifier].requests + 1
    
    if RateLimit[identifier].requests > Config.Security.maxRequestsPerMinute then
        print(("^3[JR.DEV Battlepass]^7 Rate limit exceeded for player %s"):format(identifier))
        return false
    end
    
    return true
end

function GenerateSecurityToken(identifier)
    local token = math.random(100000, 999999) .. "_" .. os.time()
    SecurityTokens[identifier] = {token = token, expires = os.time() + 300} -- 5 minutes
    return token
end

function ValidateSecurityToken(identifier, token)
    if not Config.Security.requireSessionToken then return true end
    
    local stored = SecurityTokens[identifier]
    if not stored or stored.token ~= token or stored.expires < os.time() then
        return false
    end
    
    return true
end

-- 👤 Player Management
RegisterServerEvent('battlepass:playerLoaded')
AddEventHandler('battlepass:playerLoaded', function()
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then return end
    
    local identifier = xPlayer.identifier
    
    -- Load or create player data
    CreateThread(function()
        local playerData = Database.getPlayerData(identifier)
        
        if not playerData then
            -- Create new player
            playerData = Database.createPlayer(identifier)
            print(("^2[JR.DEV Battlepass]^7 Created new battlepass profile for %s"):format(identifier))
        end
        
        -- Cache player data
        PlayerCache[source] = playerData
        
        -- Generate security token
        local token = GenerateSecurityToken(identifier)
        
        -- Send initial data to client
        TriggerClientEvent('battlepass:receivePlayerData', source, {
            player = playerData,
            token = token,
            config = {
                maxLevel = Config.Battlepass.maxLevel,
                xpPerLevel = Config.Battlepass.xpPerLevel,
                premiumCost = Config.Battlepass.premiumCost
            }
        })
        
        -- Load active missions
        local missions = Database.getActiveMissions(identifier)
        TriggerClientEvent('battlepass:receiveMissions', source, missions)
    end)
end)

RegisterServerEvent('esx:playerDropped')
AddEventHandler('esx:playerDropped', function(playerId)
    local identifier = GetPlayerIdentifier(playerId, 0)
    
    -- Clean up cache and security tokens
    PlayerCache[playerId] = nil
    SecurityTokens[identifier] = nil
    RateLimit[identifier] = nil
end)

-- 📈 XP and Level System
RegisterServerEvent('battlepass:giveXP')
AddEventHandler('battlepass:giveXP', function(amount, reason)
    local source = source
    
    if not ValidatePlayer(source) or not CheckRateLimit(source) then return end
    
    local xPlayer = ESX.GetPlayerFromId(source)
    local identifier = xPlayer.identifier
    local playerData = PlayerCache[source]
    
    if not playerData then return end
    
    -- Anti-cheat: Validate XP amount
    if amount > 10000 or amount <= 0 then
        print(("^3[JR.DEV Battlepass]^7 Suspicious XP amount (%s) from player %s"):format(amount, identifier))
        return
    end
    
    -- Apply premium multiplier
    if playerData.premium and playerData.premium_expires and 
       os.time() < playerData.premium_expires then
        amount = math.floor(amount * Config.Battlepass.premiumXpMultiplier)
    end
    
    -- Update XP and check for level up
    local newXP = playerData.xp + amount
    local newLevel = playerData.level
    
    -- Calculate level progression
    local xpNeededForNextLevel = Config.Battlepass.xpPerLevel * (1.1 ^ (playerData.level - 1))
    
    while newXP >= xpNeededForNextLevel and newLevel < Config.Battlepass.maxLevel do
        newXP = newXP - xpNeededForNextLevel
        newLevel = newLevel + 1
        xpNeededForNextLevel = Config.Battlepass.xpPerLevel * (1.1 ^ (newLevel - 1))
    end
    
    -- Update database
    if Database.updatePlayerXP(identifier, newLevel, newXP) then
        -- Update cache
        PlayerCache[source].level = newLevel
        PlayerCache[source].xp = newXP
        
        -- Notify client
        TriggerClientEvent('battlepass:xpGained', source, amount, reason)
        
        if newLevel > playerData.level then
            TriggerClientEvent('battlepass:levelUp', source, newLevel, playerData.level)
            
            -- Check for level rewards
            CheckLevelRewards(source, newLevel, playerData.level)
        end
        
        -- Update client data
        TriggerClientEvent('battlepass:updatePlayerData', source, {
            level = newLevel,
            xp = newXP
        })
    end
end)

function CheckLevelRewards(source, newLevel, oldLevel)
    local xPlayer = ESX.GetPlayerFromId(source)
    local identifier = xPlayer.identifier
    local playerData = PlayerCache[source]
    
    if not playerData then return end
    
    for level = oldLevel + 1, newLevel do
        -- Check free rewards
        local freeRewards = Database.getLevelRewards(level, 'free', Config.Battlepass.currentSeason)
        if freeRewards then
            for _, reward in pairs(freeRewards) do
                Rewards.giveReward(source, reward.reward_type, reward.reward_data)
                Database.logReward(identifier, 'level', reward.reward_data, level)
            end
        end
        
        -- Check premium rewards
        if playerData.premium then
            local premiumRewards = Database.getLevelRewards(level, 'premium', Config.Battlepass.currentSeason)
            if premiumRewards then
                for _, reward in pairs(premiumRewards) do
                    Rewards.giveReward(source, reward.reward_type, reward.reward_data)
                    Database.logReward(identifier, 'level', reward.reward_data, level)
                end
            end
        end
    end
end

-- 🎁 Daily Rewards System
RegisterServerEvent('battlepass:claimDailyReward')
AddEventHandler('battlepass:claimDailyReward', function(token)
    local source = source
    
    if not ValidatePlayer(source) or not CheckRateLimit(source) then return end
    
    local xPlayer = ESX.GetPlayerFromId(source)
    local identifier = xPlayer.identifier
    
    if not ValidateSecurityToken(identifier, token) then
        print(("^3[JR.DEV Battlepass]^7 Invalid security token from player %s"):format(identifier))
        return
    end
    
    local playerData = PlayerCache[source]
    if not playerData then return end
    
    -- Check if player can claim daily reward
    local currentTime = os.time()
    local lastClaim = playerData.last_daily_claim
    local streak = playerData.daily_streak
    
    if lastClaim then
        local timeDiff = currentTime - lastClaim
        local oneDayInSeconds = 24 * 60 * 60
        
        -- Can't claim if less than 24 hours
        if timeDiff < oneDayInSeconds then
            TriggerClientEvent('battlepass:showNotification', source, _U('daily_reward_claimed'), 'error')
            return
        end
        
        -- Reset streak if more than 48 hours
        if timeDiff > (oneDayInSeconds * 2) then
            streak = 0
            TriggerClientEvent('battlepass:showNotification', source, _U('streak_broken'), 'warning')
        end
    end
    
    -- Increment streak
    streak = (streak % 7) + 1
    
    -- Get reward for current day
    local rewardConfig = Config.DailyRewards[streak]
    if not rewardConfig then return end
    
    -- Give reward
    local success = false
    if rewardConfig.type == 'multi' then
        success = true
        for _, reward in pairs(rewardConfig.rewards) do
            if not Rewards.giveReward(source, reward.type, reward) then
                success = false
                break
            end
        end
    else
        success = Rewards.giveReward(source, rewardConfig.type, rewardConfig)
    end
    
    if success then
        -- Update database
        if Database.updateDailyStreak(identifier, streak, currentTime) then
            -- Update cache
            PlayerCache[source].daily_streak = streak
            PlayerCache[source].last_daily_claim = currentTime
            
            -- Log reward
            Database.logReward(identifier, 'daily', rewardConfig)
            
            -- Notify client
            TriggerClientEvent('battlepass:dailyRewardClaimed', source, {
                streak = streak,
                reward = rewardConfig,
                nextReward = Config.DailyRewards[(streak % 7) + 1]
            })
            
            TriggerClientEvent('battlepass:showNotification', source, 
                _U('streak_maintained', streak), 'success')
        end
    else
        TriggerClientEvent('battlepass:showNotification', source, _U('error_occurred'), 'error')
    end
end)

-- 🎯 Mission System
function ResetDailyMissions()
    print("^2[JR.DEV Battlepass]^7 Resetting daily missions...")
    Database.resetExpiredMissions('daily')
    
    -- Schedule next reset (24 hours)
    SetTimeout(24 * 60 * 60 * 1000, function()
        ResetDailyMissions()
    end)
end

function ResetWeeklyMissions()
    print("^2[JR.DEV Battlepass]^7 Resetting weekly missions...")
    Database.resetExpiredMissions('weekly')
    
    -- Schedule next reset (7 days)
    SetTimeout(7 * 24 * 60 * 60 * 1000, function()
        ResetWeeklyMissions()
    end)
end

-- 💰 Premium System
RegisterServerEvent('battlepass:buyPremium')
AddEventHandler('battlepass:buyPremium', function(token)
    local source = source
    
    if not ValidatePlayer(source) or not CheckRateLimit(source) then return end
    
    local xPlayer = ESX.GetPlayerFromId(source)
    local identifier = xPlayer.identifier
    
    if not ValidateSecurityToken(identifier, token) then return end
    
    local playerData = PlayerCache[source]
    if not playerData then return end
    
    -- Check if player has enough coins
    if playerData.coins < Config.Battlepass.premiumCost then
        TriggerClientEvent('battlepass:showNotification', source, _U('insufficient_coins'), 'error')
        return
    end
    
    -- Calculate expiry date (90 days from now)
    local expiryDate = os.time() + (Config.Battlepass.seasonDurationDays * 24 * 60 * 60)
    
    -- Update database
    if Database.activatePremium(identifier, expiryDate, Config.Battlepass.premiumCost) then
        -- Update cache
        PlayerCache[source].premium = true
        PlayerCache[source].premium_expires = expiryDate
        PlayerCache[source].coins = playerData.coins - Config.Battlepass.premiumCost
        
        -- Notify client
        TriggerClientEvent('battlepass:premiumActivated', source, expiryDate)
        TriggerClientEvent('battlepass:showNotification', source, _U('premium_activated'), 'success')
    else
        TriggerClientEvent('battlepass:showNotification', source, _U('error_occurred'), 'error')
    end
end)

-- 📤 Export functions for other resources
exports('giveXP', function(playerId, amount, reason)
    TriggerEvent('battlepass:giveXP', amount, reason or 'External')
end)

exports('getPlayerData', function(playerId)
    return PlayerCache[playerId]
end)

exports('getDatabase', function()
    return Database
end)

exports('getRewards', function()
    return Rewards
end)

print("^2[JR.DEV Battlepass]^7 Server main script loaded successfully")