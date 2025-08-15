-- 👑 Admin system for JR.DEV Battlepass
local ESX = exports["es_extended"]:getSharedObject()
local Database = exports.jr_battlepassv2:getDatabase()
local Rewards = exports.jr_battlepassv2:getRewards()

-- 🔐 Check admin permission
function HasAdminPermission(source)
    return IsPlayerAceAllowed(source, Config.Admin.acePermission)
end

-- 🎯 Give XP Command
RegisterCommand(Config.Admin.commands.give_xp, function(source, args)
    if not HasAdminPermission(source) then
        TriggerClientEvent('battlepass:showNotification', source, 'No permission', 'error')
        return
    end
    
    if #args < 2 then
        TriggerClientEvent('battlepass:showNotification', source, 
            'Usage: /' .. Config.Admin.commands.give_xp .. ' [player_id] [amount]', 'info')
        return
    end
    
    local targetId = tonumber(args[1])
    local amount = tonumber(args[2])
    
    if not targetId or not amount then
        TriggerClientEvent('battlepass:showNotification', source, _U('admin_invalid_amount'), 'error')
        return
    end
    
    local targetPlayer = ESX.GetPlayerFromId(targetId)
    if not targetPlayer then
        TriggerClientEvent('battlepass:showNotification', source, _U('admin_invalid_player'), 'error')
        return
    end
    
    -- Give XP to target player
    TriggerEvent('battlepass:giveXP', amount, 'Admin Command')
    TriggerEvent('battlepass:giveXP', amount, 'Admin Command', targetId)  -- Specify target
    
    -- Notify both players
    local adminName = GetPlayerName(source)
    TriggerClientEvent('battlepass:showNotification', source, 
        _U('admin_xp_given', amount, targetPlayer.getName()), 'success')
    TriggerClientEvent('battlepass:showNotification', targetId, 
        'Admin ' .. adminName .. ' gave you ' .. amount .. ' XP', 'info')
    
    -- Log admin action
    print(("^2[JR.DEV Battlepass]^7 Admin %s (%s) gave %d XP to %s (%s)"):format(
        adminName, GetPlayerIdentifier(source, 0), amount, 
        targetPlayer.getName(), targetPlayer.identifier))
end)

-- 📈 Set Level Command
RegisterCommand(Config.Admin.commands.set_level, function(source, args)
    if not HasAdminPermission(source) then
        TriggerClientEvent('battlepass:showNotification', source, 'No permission', 'error')
        return
    end
    
    if #args < 2 then
        TriggerClientEvent('battlepass:showNotification', source, 
            'Usage: /' .. Config.Admin.commands.set_level .. ' [player_id] [level]', 'info')
        return
    end
    
    local targetId = tonumber(args[1])
    local level = tonumber(args[2])
    
    if not targetId or not level then
        TriggerClientEvent('battlepass:showNotification', source, _U('admin_invalid_amount'), 'error')
        return
    end
    
    if level < 1 or level > Config.Battlepass.maxLevel then
        TriggerClientEvent('battlepass:showNotification', source, 
            'Level must be between 1 and ' .. Config.Battlepass.maxLevel, 'error')
        return
    end
    
    local targetPlayer = ESX.GetPlayerFromId(targetId)
    if not targetPlayer then
        TriggerClientEvent('battlepass:showNotification', source, _U('admin_invalid_player'), 'error')
        return
    end
    
    -- Set player level
    if Database.setPlayerLevel(targetPlayer.identifier, level, 0) then
        -- Notify both players
        local adminName = GetPlayerName(source)
        TriggerClientEvent('battlepass:showNotification', source, 
            _U('admin_level_set', targetPlayer.getName(), level), 'success')
        TriggerClientEvent('battlepass:showNotification', targetId, 
            'Admin ' .. adminName .. ' set your level to ' .. level, 'info')
        
        -- Update client data
        TriggerClientEvent('battlepass:updatePlayerData', targetId, {
            level = level,
            xp = 0
        })
        
        -- Log admin action
        print(("^2[JR.DEV Battlepass]^7 Admin %s (%s) set %s (%s) level to %d"):format(
            adminName, GetPlayerIdentifier(source, 0), 
            targetPlayer.getName(), targetPlayer.identifier, level))
    else
        TriggerClientEvent('battlepass:showNotification', source, _U('database_error'), 'error')
    end
end)

-- 🪙 Give Coins Command
RegisterCommand(Config.Admin.commands.give_coins, function(source, args)
    if not HasAdminPermission(source) then
        TriggerClientEvent('battlepass:showNotification', source, 'No permission', 'error')
        return
    end
    
    if #args < 2 then
        TriggerClientEvent('battlepass:showNotification', source, 
            'Usage: /' .. Config.Admin.commands.give_coins .. ' [player_id] [amount]', 'info')
        return
    end
    
    local targetId = tonumber(args[1])
    local amount = tonumber(args[2])
    
    if not targetId or not amount then
        TriggerClientEvent('battlepass:showNotification', source, _U('admin_invalid_amount'), 'error')
        return
    end
    
    local targetPlayer = ESX.GetPlayerFromId(targetId)
    if not targetPlayer then
        TriggerClientEvent('battlepass:showNotification', source, _U('admin_invalid_player'), 'error')
        return
    end
    
    -- Give coins to target player
    if Rewards.giveCoins(targetId, amount) then
        -- Notify both players
        local adminName = GetPlayerName(source)
        TriggerClientEvent('battlepass:showNotification', source, 
            _U('admin_coins_given', amount, targetPlayer.getName()), 'success')
        TriggerClientEvent('battlepass:showNotification', targetId, 
            'Admin ' .. adminName .. ' gave you ' .. amount .. ' coins', 'info')
        
        -- Log admin action
        print(("^2[JR.DEV Battlepass]^7 Admin %s (%s) gave %d coins to %s (%s)"):format(
            adminName, GetPlayerIdentifier(source, 0), amount, 
            targetPlayer.getName(), targetPlayer.identifier))
    else
        TriggerClientEvent('battlepass:showNotification', source, _U('database_error'), 'error')
    end
end)

-- 🔄 Reset Player Command
RegisterCommand(Config.Admin.commands.reset_player, function(source, args)
    if not HasAdminPermission(source) then
        TriggerClientEvent('battlepass:showNotification', source, 'No permission', 'error')
        return
    end
    
    if #args < 1 then
        TriggerClientEvent('battlepass:showNotification', source, 
            'Usage: /' .. Config.Admin.commands.reset_player .. ' [player_id]', 'info')
        return
    end
    
    local targetId = tonumber(args[1])
    
    if not targetId then
        TriggerClientEvent('battlepass:showNotification', source, _U('admin_invalid_player'), 'error')
        return
    end
    
    local targetPlayer = ESX.GetPlayerFromId(targetId)
    if not targetPlayer then
        TriggerClientEvent('battlepass:showNotification', source, _U('admin_invalid_player'), 'error')
        return
    end
    
    -- Reset player data
    if Database.resetPlayer(targetPlayer.identifier) then
        -- Notify both players
        local adminName = GetPlayerName(source)
        TriggerClientEvent('battlepass:showNotification', source, 
            _U('admin_player_reset', targetPlayer.getName()), 'success')
        TriggerClientEvent('battlepass:showNotification', targetId, 
            'Admin ' .. adminName .. ' reset your battlepass data', 'warning')
        
        -- Reload player data
        TriggerEvent('battlepass:playerLoaded', targetId)
        
        -- Log admin action
        print(("^2[JR.DEV Battlepass]^7 Admin %s (%s) reset battlepass data for %s (%s)"):format(
            adminName, GetPlayerIdentifier(source, 0), 
            targetPlayer.getName(), targetPlayer.identifier))
    else
        TriggerClientEvent('battlepass:showNotification', source, _U('database_error'), 'error')
    end
end)

-- 📊 Admin Statistics Command
RegisterCommand('bp_stats', function(source, args)
    if not HasAdminPermission(source) then
        TriggerClientEvent('battlepass:showNotification', source, 'No permission', 'error')
        return
    end
    
    -- Get server statistics
    local stats = {
        totalPlayers = 0,
        premiumPlayers = 0,
        averageLevel = 0,
        totalXPGiven = 0,
        totalCoinsGiven = 0,
        totalRewardsGiven = 0
    }
    
    -- Query database for stats (implement these queries in database.lua)
    MySQL.Async.fetchAll('SELECT COUNT(*) as total, AVG(level) as avg_level, SUM(xp) as total_xp, COUNT(CASE WHEN premium = TRUE THEN 1 END) as premium_count FROM battlepass_players', {}, function(result)
        if result and result[1] then
            stats.totalPlayers = result[1].total or 0
            stats.averageLevel = math.floor(result[1].avg_level or 0)
            stats.totalXPGiven = result[1].total_xp or 0
            stats.premiumPlayers = result[1].premium_count or 0
        end
        
        -- Send stats to admin
        TriggerClientEvent('battlepass:showAdminStats', source, stats)
    end)
end)

-- 🎁 Give Reward Command
RegisterCommand('bp_reward', function(source, args)
    if not HasAdminPermission(source) then
        TriggerClientEvent('battlepass:showNotification', source, 'No permission', 'error')
        return
    end
    
    if #args < 3 then
        TriggerClientEvent('battlepass:showNotification', source, 
            'Usage: /bp_reward [player_id] [reward_type] [amount/item]', 'info')
        TriggerClientEvent('battlepass:showNotification', source, 
            'Types: money, bank, item, weapon, coins, lootbox', 'info')
        return
    end
    
    local targetId = tonumber(args[1])
    local rewardType = args[2]
    local rewardValue = args[3]
    local rewardAmount = tonumber(args[4]) or 1
    
    if not targetId then
        TriggerClientEvent('battlepass:showNotification', source, _U('admin_invalid_player'), 'error')
        return
    end
    
    local targetPlayer = ESX.GetPlayerFromId(targetId)
    if not targetPlayer then
        TriggerClientEvent('battlepass:showNotification', source, _U('admin_invalid_player'), 'error')
        return
    end
    
    -- Prepare reward data
    local rewardData = {}
    
    if rewardType == 'money' or rewardType == 'bank' or rewardType == 'coins' then
        rewardAmount = tonumber(rewardValue)
        if not rewardAmount then
            TriggerClientEvent('battlepass:showNotification', source, _U('admin_invalid_amount'), 'error')
            return
        end
        rewardData = {amount = rewardAmount}
        
    elseif rewardType == 'item' then
        rewardData = {item = rewardValue, count = rewardAmount}
        
    elseif rewardType == 'weapon' then
        rewardData = {weapon = rewardValue, ammo = rewardAmount}
        
    elseif rewardType == 'lootbox' then
        rewardData = {box = rewardValue}
        
    else
        TriggerClientEvent('battlepass:showNotification', source, 
            'Invalid reward type. Use: money, bank, item, weapon, coins, lootbox', 'error')
        return
    end
    
    -- Give reward
    if Rewards.giveReward(targetId, rewardType, rewardData) then
        local adminName = GetPlayerName(source)
        TriggerClientEvent('battlepass:showNotification', source, 
            'Gave ' .. rewardType .. ' reward to ' .. targetPlayer.getName(), 'success')
        TriggerClientEvent('battlepass:showNotification', targetId, 
            'Admin ' .. adminName .. ' gave you a reward!', 'info')
        
        -- Log admin action
        print(("^2[JR.DEV Battlepass]^7 Admin %s (%s) gave %s reward to %s (%s)"):format(
            adminName, GetPlayerIdentifier(source, 0), rewardType,
            targetPlayer.getName(), targetPlayer.identifier))
    else
        TriggerClientEvent('battlepass:showNotification', source, _U('database_error'), 'error')
    end
end)

-- 🔄 Reload Config Command
RegisterCommand('bp_reload', function(source, args)
    if not HasAdminPermission(source) then
        TriggerClientEvent('battlepass:showNotification', source, 'No permission', 'error')
        return
    end
    
    -- Refresh config for all clients
    TriggerClientEvent('battlepass:reloadConfig', -1)
    TriggerClientEvent('battlepass:showNotification', source, 'Config reloaded for all players', 'success')
    
    print(("^2[JR.DEV Battlepass]^7 Admin %s (%s) reloaded battlepass config"):format(
        GetPlayerName(source), GetPlayerIdentifier(source, 0)))
end)

-- 🎯 Season Management Commands
RegisterCommand('bp_season', function(source, args)
    if not HasAdminPermission(source) then
        TriggerClientEvent('battlepass:showNotification', source, 'No permission', 'error')
        return
    end
    
    if #args < 1 then
        TriggerClientEvent('battlepass:showNotification', source, 
            'Usage: /bp_season [create/end/info] [name] [description]', 'info')
        return
    end
    
    local action = args[1]
    
    if action == 'info' then
        local currentSeason = Database.getCurrentSeason()
        if currentSeason then
            TriggerClientEvent('battlepass:showNotification', source, 
                'Current Season: ' .. currentSeason.name .. ' (ID: ' .. currentSeason.id .. ')', 'info')
        else
            TriggerClientEvent('battlepass:showNotification', source, 'No active season', 'warning')
        end
        
    elseif action == 'create' then
        if #args < 3 then
            TriggerClientEvent('battlepass:showNotification', source, 
                'Usage: /bp_season create [name] [description]', 'info')
            return
        end
        
        local name = args[2]
        local description = table.concat(args, ' ', 3)
        local startDate = os.time()
        local endDate = os.time() + (Config.Battlepass.seasonDurationDays * 24 * 60 * 60)
        
        if Database.createSeason(name, description, startDate, endDate) then
            TriggerClientEvent('battlepass:showNotification', source, 
                'Created new season: ' .. name, 'success')
                
            print(("^2[JR.DEV Battlepass]^7 Admin %s (%s) created new season: %s"):format(
                GetPlayerName(source), GetPlayerIdentifier(source, 0), name))
        else
            TriggerClientEvent('battlepass:showNotification', source, _U('database_error'), 'error')
        end
    end
end)

-- 🔍 Debug Player Command
RegisterCommand('bp_debug', function(source, args)
    if not HasAdminPermission(source) then
        TriggerClientEvent('battlepass:showNotification', source, 'No permission', 'error')
        return
    end
    
    local targetId = args[1] and tonumber(args[1]) or source
    local targetPlayer = ESX.GetPlayerFromId(targetId)
    
    if not targetPlayer then
        TriggerClientEvent('battlepass:showNotification', source, _U('admin_invalid_player'), 'error')
        return
    end
    
    -- Get player data and send debug info
    local playerData = Database.getPlayerData(targetPlayer.identifier)
    if playerData then
        TriggerClientEvent('battlepass:showDebugInfo', source, {
            player = targetPlayer.getName(),
            identifier = targetPlayer.identifier,
            data = playerData
        })
    else
        TriggerClientEvent('battlepass:showNotification', source, _U('player_not_found'), 'error')
    end
end)

print("^2[JR.DEV Battlepass]^7 Admin system loaded successfully")