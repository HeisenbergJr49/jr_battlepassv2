-- Admin commands and management for battlepass system

-- Check if player is admin
function IsPlayerAdmin(playerId)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return false end
    
    local playerGroup = xPlayer.getGroup()
    for _, adminGroup in pairs(Config.AdminGroups) do
        if playerGroup == adminGroup then
            return true
        end
    end
    
    return false
end

-- Give XP command
RegisterCommand('bp_givexp', function(source, args, rawCommand)
    if source == 0 then
        -- Console command
        if #args < 2 then
            print('Usage: bp_givexp <playerId> <amount> [reason]')
            return
        end
        
        local targetId = tonumber(args[1])
        local amount = tonumber(args[2])
        local reason = args[3] or 'Admin Command'
        
        if targetId and amount then
            if GivePlayerXP(targetId, amount, reason) then
                print(('Gave %s XP to player %s'):format(amount, targetId))
            else
                print('Failed to give XP')
            end
        end
        
    elseif IsPlayerAdmin(source) then
        if #args < 2 then
            TriggerClientEvent('chat:addMessage', source, {
                color = {255, 0, 0},
                multiline = true,
                args = {'System', 'Usage: /bp_givexp <playerId> <amount> [reason]'}
            })
            return
        end
        
        local targetId = tonumber(args[1])
        local amount = tonumber(args[2])
        local reason = args[3] or 'Admin Command'
        
        if targetId and amount then
            local targetPlayer = ESX.GetPlayerFromId(targetId)
            if targetPlayer then
                if GivePlayerXP(targetId, amount, reason) then
                    TriggerClientEvent('chat:addMessage', source, {
                        color = {0, 255, 0},
                        multiline = true,
                        args = {'Admin', ('Gave %s XP to %s'):format(amount, targetPlayer.getName())}
                    })
                else
                    TriggerClientEvent('chat:addMessage', source, {
                        color = {255, 0, 0},
                        multiline = true,
                        args = {'Admin', 'Failed to give XP'}
                    })
                end
            else
                TriggerClientEvent('chat:addMessage', source, {
                    color = {255, 0, 0},
                    multiline = true,
                    args = {'Admin', 'Player not found'}
                })
            end
        end
    end
end, false)

-- Set level command
RegisterCommand('bp_setlevel', function(source, args, rawCommand)
    if source == 0 then
        -- Console command
        if #args < 2 then
            print('Usage: bp_setlevel <playerId> <level>')
            return
        end
        
        local targetId = tonumber(args[1])
        local level = tonumber(args[2])
        
        if targetId and level and level >= 1 and level <= Config.MaxLevel then
            SetPlayerLevel(targetId, level)
            print(('Set player %s to level %s'):format(targetId, level))
        end
        
    elseif IsPlayerAdmin(source) then
        if #args < 2 then
            TriggerClientEvent('chat:addMessage', source, {
                color = {255, 0, 0},
                multiline = true,
                args = {'System', 'Usage: /bp_setlevel <playerId> <level>'}
            })
            return
        end
        
        local targetId = tonumber(args[1])
        local level = tonumber(args[2])
        
        if targetId and level and level >= 1 and level <= Config.MaxLevel then
            local targetPlayer = ESX.GetPlayerFromId(targetId)
            if targetPlayer then
                SetPlayerLevel(targetId, level)
                TriggerClientEvent('chat:addMessage', source, {
                    color = {0, 255, 0},
                    multiline = true,
                    args = {'Admin', ('Set %s to level %s'):format(targetPlayer.getName(), level)}
                })
            else
                TriggerClientEvent('chat:addMessage', source, {
                    color = {255, 0, 0},
                    multiline = true,
                    args = {'Admin', 'Player not found'}
                })
            end
        else
            TriggerClientEvent('chat:addMessage', source, {
                color = {255, 0, 0},
                multiline = true,
                args = {'Admin', ('Level must be between 1 and %s'):format(Config.MaxLevel)}
            })
        end
    end
end, false)

-- Give premium command
RegisterCommand('bp_givepremium', function(source, args, rawCommand)
    if source == 0 then
        -- Console command
        if #args < 1 then
            print('Usage: bp_givepremium <playerId> [days]')
            return
        end
        
        local targetId = tonumber(args[1])
        local days = tonumber(args[2]) or 30
        
        if targetId then
            GivePlayerPremium(targetId, days)
            print(('Gave premium to player %s for %s days'):format(targetId, days))
        end
        
    elseif IsPlayerAdmin(source) then
        if #args < 1 then
            TriggerClientEvent('chat:addMessage', source, {
                color = {255, 0, 0},
                multiline = true,
                args = {'System', 'Usage: /bp_givepremium <playerId> [days]'}
            })
            return
        end
        
        local targetId = tonumber(args[1])
        local days = tonumber(args[2]) or 30
        
        if targetId then
            local targetPlayer = ESX.GetPlayerFromId(targetId)
            if targetPlayer then
                GivePlayerPremium(targetId, days)
                TriggerClientEvent('chat:addMessage', source, {
                    color = {0, 255, 0},
                    multiline = true,
                    args = {'Admin', ('Gave premium to %s for %s days'):format(targetPlayer.getName(), days)}
                })
            else
                TriggerClientEvent('chat:addMessage', source, {
                    color = {255, 0, 0},
                    multiline = true,
                    args = {'Admin', 'Player not found'}
                })
            end
        end
    end
end, false)

-- Reset player command
RegisterCommand('bp_reset', function(source, args, rawCommand)
    if source == 0 then
        -- Console command
        if #args < 1 then
            print('Usage: bp_reset <playerId>')
            return
        end
        
        local targetId = tonumber(args[1])
        if targetId then
            ResetPlayerBattlepass(targetId)
            print(('Reset battlepass for player %s'):format(targetId))
        end
        
    elseif IsPlayerAdmin(source) then
        if #args < 1 then
            TriggerClientEvent('chat:addMessage', source, {
                color = {255, 0, 0},
                multiline = true,
                args = {'System', 'Usage: /bp_reset <playerId>'}
            })
            return
        end
        
        local targetId = tonumber(args[1])
        if targetId then
            local targetPlayer = ESX.GetPlayerFromId(targetId)
            if targetPlayer then
                ResetPlayerBattlepass(targetId)
                TriggerClientEvent('chat:addMessage', source, {
                    color = {0, 255, 0},
                    multiline = true,
                    args = {'Admin', ('Reset battlepass for %s'):format(targetPlayer.getName())}
                })
            else
                TriggerClientEvent('chat:addMessage', source, {
                    color = {255, 0, 0},
                    multiline = true,
                    args = {'Admin', 'Player not found'}
                })
            end
        end
    end
end, false)

-- Statistics command
RegisterCommand('bp_stats', function(source, args, rawCommand)
    if source == 0 or IsPlayerAdmin(source) then
        GetBattlepassStatistics(function(stats)
            if stats then
                local message = ('Battlepass Statistics:\n' ..
                    'Total Players: %s\n' ..
                    'Average Level: %.2f\n' ..
                    'Max Level: %s\n' ..
                    'Premium Players: %s'):format(
                    stats.total_players or 0,
                    stats.avg_level or 0,
                    stats.max_level or 0,
                    stats.premium_players or 0
                )
                
                if source == 0 then
                    print(message)
                else
                    TriggerClientEvent('chat:addMessage', source, {
                        color = {0, 255, 255},
                        multiline = true,
                        args = {'Admin', message}
                    })
                end
            end
        end)
    end
end, false)

-- Top players command
RegisterCommand('bp_top', function(source, args, rawCommand)
    if source == 0 or IsPlayerAdmin(source) then
        local limit = tonumber(args[1]) or 10
        
        GetTopPlayers(limit, function(players)
            local message = 'Top Players:'
            
            for i, player in pairs(players) do
                -- Try to get player name from identifier
                local playerName = player.identifier
                -- This would need integration with your user system to get actual names
                message = message .. ('\n%s. %s - Level %s (%s XP)'):format(i, playerName, player.level, player.xp)
            end
            
            if source == 0 then
                print(message)
            else
                TriggerClientEvent('chat:addMessage', source, {
                    color = {0, 255, 255},
                    multiline = true,
                    args = {'Admin', message}
                })
            end
        end)
    end
end, false)

-- Give lootbox command
RegisterCommand('bp_givelootbox', function(source, args, rawCommand)
    if source == 0 then
        -- Console command
        if #args < 2 then
            print('Usage: bp_givelootbox <playerId> <boxType>')
            print('Box types: basic, premium, legendary')
            return
        end
        
        local targetId = tonumber(args[1])
        local boxType = args[2]
        
        if targetId and Config.LootBoxes[boxType] then
            local rewards = OpenLootBox(targetId, boxType)
            if rewards then
                print(('Gave %s lootbox to player %s'):format(boxType, targetId))
            end
        end
        
    elseif IsPlayerAdmin(source) then
        if #args < 2 then
            TriggerClientEvent('chat:addMessage', source, {
                color = {255, 0, 0},
                multiline = true,
                args = {'System', 'Usage: /bp_givelootbox <playerId> <boxType>\nBox types: basic, premium, legendary'}
            })
            return
        end
        
        local targetId = tonumber(args[1])
        local boxType = args[2]
        
        if targetId and Config.LootBoxes[boxType] then
            local targetPlayer = ESX.GetPlayerFromId(targetId)
            if targetPlayer then
                local rewards = OpenLootBox(targetId, boxType)
                if rewards then
                    TriggerClientEvent('chat:addMessage', source, {
                        color = {0, 255, 0},
                        multiline = true,
                        args = {'Admin', ('Gave %s lootbox to %s'):format(boxType, targetPlayer.getName())}
                    })
                    
                    TriggerClientEvent('jr_battlepass:lootboxOpened', targetId, rewards)
                end
            else
                TriggerClientEvent('chat:addMessage', source, {
                    color = {255, 0, 0},
                    multiline = true,
                    args = {'Admin', 'Player not found'}
                })
            end
        else
            TriggerClientEvent('chat:addMessage', source, {
                color = {255, 0, 0},
                multiline = true,
                args = {'Admin', 'Invalid box type. Available: basic, premium, legendary'}
            })
        end
    end
end, false)

-- Helper functions
function SetPlayerLevel(playerId, level)
    local data = playerData[playerId]
    if not data then return false end
    
    local oldLevel = data.level
    data.level = level
    
    -- Calculate required XP for this level
    local totalXP = 0
    for i = 1, level - 1 do
        totalXP = totalXP + (Config.XPPerLevel[i] or 0)
    end
    data.xp = totalXP
    
    SavePlayerBattlepassData(playerId)
    TriggerClientEvent('jr_battlepass:receivePlayerData', playerId, data)
    
    -- Give level rewards if leveling up
    if level > oldLevel then
        HandleLevelUp(playerId, oldLevel, level)
    end
    
    return true
end

function GivePlayerPremium(playerId, days)
    local data = playerData[playerId]
    if not data then return false end
    
    data.premium = true
    data.premium_expires = os.date('%Y-%m-%d %H:%M:%S', os.time() + (days * 24 * 60 * 60))
    
    SavePlayerBattlepassData(playerId)
    TriggerClientEvent('jr_battlepass:premiumPurchased', playerId, true)
    
    -- Give premium welcome bonus if not already premium
    GivePremiumWelcomeBonus(playerId)
    
    return true
end

function ResetPlayerBattlepass(playerId)
    local data = playerData[playerId]
    if not data then return false end
    
    data.level = 1
    data.xp = 0
    data.coins = 0
    data.premium = false
    data.premium_expires = nil
    data.daily_streak = 0
    data.last_daily_claim = nil
    
    SavePlayerBattlepassData(playerId)
    TriggerClientEvent('jr_battlepass:receivePlayerData', playerId, data)
    
    -- Clear missions
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if xPlayer then
        MySQL.Async.execute('DELETE FROM battlepass_missions WHERE identifier = @identifier', {
            ['@identifier'] = xPlayer.getIdentifier()
        })
    end
    
    return true
end

-- Season management commands
RegisterCommand('bp_newseason', function(source, args, rawCommand)
    if source == 0 then
        -- Console command
        if #args < 1 then
            print('Usage: bp_newseason <seasonId> [seasonName]')
            return
        end
        
        local seasonId = tonumber(args[1])
        local seasonName = args[2] or ('Season %s'):format(seasonId)
        
        if seasonId then
            StartNewSeason(seasonId, seasonName)
            print(('Started new season: %s'):format(seasonName))
        end
        
    elseif IsPlayerAdmin(source) and ESX.GetPlayerFromId(source).getGroup() == 'owner' then
        -- Only owner can start new seasons
        if #args < 1 then
            TriggerClientEvent('chat:addMessage', source, {
                color = {255, 0, 0},
                multiline = true,
                args = {'System', 'Usage: /bp_newseason <seasonId> [seasonName]'}
            })
            return
        end
        
        local seasonId = tonumber(args[1])
        local seasonName = args[2] or ('Season %s'):format(seasonId)
        
        if seasonId then
            StartNewSeason(seasonId, seasonName)
            TriggerClientEvent('chat:addMessage', source, {
                color = {0, 255, 0},
                multiline = true,
                args = {'Admin', ('Started new season: %s'):format(seasonName)}
            })
            
            -- Notify all players
            TriggerClientEvent('chat:addMessage', -1, {
                color = {255, 215, 0},
                multiline = true,
                args = {'Battlepass', ('🎉 New Season Started: %s'):format(seasonName)}
            })
        end
    end
end, false)

function StartNewSeason(seasonId, seasonName)
    -- Backup current data
    BackupPlayerData(function(result)
        print('[jr_battlepass] Player data backed up for new season')
    end)
    
    -- Update config
    Config.SeasonId = seasonId
    Config.SeasonName = seasonName
    
    -- Reset all players would be done via database migration
    -- This is a simplified version - in production you'd want more sophisticated season transitions
    
    print(('[jr_battlepass] New season started: %s (ID: %s)'):format(seasonName, seasonId))
end

-- Debug command
RegisterCommand('bp_debug', function(source, args, rawCommand)
    if source == 0 or IsPlayerAdmin(source) then
        Config.Debug = not Config.Debug
        local message = ('Debug mode: %s'):format(Config.Debug and 'ON' or 'OFF')
        
        if source == 0 then
            print(message)
        else
            TriggerClientEvent('chat:addMessage', source, {
                color = {255, 255, 0},
                multiline = true,
                args = {'Admin', message}
            })
        end
    end
end, false)

-- Export admin functions
exports('isPlayerAdmin', IsPlayerAdmin)
exports('setPlayerLevel', SetPlayerLevel)
exports('givePlayerPremium', GivePlayerPremium)
exports('resetPlayerBattlepass', ResetPlayerBattlepass)
exports('startNewSeason', StartNewSeason)