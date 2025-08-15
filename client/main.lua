ESX = exports['es_extended']:getSharedObject()
local PlayerData = {}
local battlepassOpen = false
local currentLevel = 1
local currentXP = 0
local premiumStatus = false

-- Initialize ESX
RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
    PlayerData = xPlayer
    TriggerServerEvent('jr_battlepass:requestPlayerData')
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
    PlayerData.job = job
end)

-- Request player data on resource start
CreateThread(function()
    while ESX == nil do
        Wait(100)
    end
    
    while ESX.GetPlayerData() == nil do
        Wait(100)
    end
    
    PlayerData = ESX.GetPlayerData()
    TriggerServerEvent('jr_battlepass:requestPlayerData')
end)

-- Handle player data from server
RegisterNetEvent('jr_battlepass:receivePlayerData')
AddEventHandler('jr_battlepass:receivePlayerData', function(data)
    if data then
        currentLevel = data.level or 1
        currentXP = data.xp or 0
        premiumStatus = data.premium or false
        
        -- Update UI if open
        if battlepassOpen then
            SendNUIMessage({
                type = 'updatePlayerData',
                data = {
                    level = currentLevel,
                    xp = currentXP,
                    premium = premiumStatus,
                    xpNeeded = Config.XPPerLevel[currentLevel] or 0
                }
            })
        end
    end
end)

-- Key mapping for opening battlepass
RegisterKeyMapping('battlepass', 'Open Battlepass', 'keyboard', Config.Keys.openBattlepass)

-- Command to open battlepass
RegisterCommand('battlepass', function()
    ToggleBattlepass()
end, false)

-- Function to toggle battlepass UI
function ToggleBattlepass()
    if battlepassOpen then
        CloseBattlepass()
    else
        OpenBattlepass()
    end
end

-- Function to open battlepass
function OpenBattlepass()
    if battlepassOpen then return end
    
    battlepassOpen = true
    SetNuiFocus(true, true)
    
    -- Request fresh data from server
    TriggerServerEvent('jr_battlepass:requestPlayerData')
    TriggerServerEvent('jr_battlepass:requestMissions')
    
    SendNUIMessage({
        type = 'openBattlepass',
        data = {
            level = currentLevel,
            xp = currentXP,
            premium = premiumStatus,
            xpNeeded = Config.XPPerLevel[currentLevel] or 0,
            seasonName = Config.SeasonName,
            maxLevel = Config.MaxLevel
        }
    })
    
    -- Play opening sound
    PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
end

-- Function to close battlepass
function CloseBattlepass()
    if not battlepassOpen then return end
    
    battlepassOpen = false
    SetNuiFocus(false, false)
    
    SendNUIMessage({
        type = 'closeBattlepass'
    })
    
    -- Play closing sound
    PlaySoundFrontend(-1, "BACK", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
end

-- NUI Callbacks
RegisterNUICallback('closeBattlepass', function(data, cb)
    CloseBattlepass()
    cb('ok')
end)

RegisterNUICallback('claimReward', function(data, cb)
    if data.type and data.level then
        TriggerServerEvent('jr_battlepass:claimReward', data.type, data.level)
        cb('ok')
    else
        cb('error')
    end
end)

RegisterNUICallback('claimDailyReward', function(data, cb)
    TriggerServerEvent('jr_battlepass:claimDailyReward')
    cb('ok')
end)

RegisterNUICallback('buyPremium', function(data, cb)
    TriggerServerEvent('jr_battlepass:buyPremium')
    cb('ok')
end)

RegisterNUICallback('openLootbox', function(data, cb)
    if data.boxType then
        TriggerServerEvent('jr_battlepass:openLootbox', data.boxType)
        cb('ok')
    else
        cb('error')
    end
end)

-- Handle reward claim response
RegisterNetEvent('jr_battlepass:rewardClaimed')
AddEventHandler('jr_battlepass:rewardClaimed', function(success, message)
    if success then
        ESX.ShowNotification(message, 'success')
        -- Request updated data
        TriggerServerEvent('jr_battlepass:requestPlayerData')
    else
        ESX.ShowNotification(message, 'error')
    end
end)

-- Handle XP gain
RegisterNetEvent('jr_battlepass:xpGained')
AddEventHandler('jr_battlepass:xpGained', function(amount, newXP, newLevel)
    currentXP = newXP
    
    if newLevel > currentLevel then
        -- Level up!
        currentLevel = newLevel
        ESX.ShowNotification(('Level Up! You are now level %s'):format(newLevel), 'success')
        
        -- Play level up sound
        PlaySoundFrontend(-1, "RANK_UP", "HUD_AWARDS", false)
        
        -- Show level up animation if battlepass is open
        if battlepassOpen then
            SendNUIMessage({
                type = 'levelUp',
                level = newLevel
            })
        end
    end
    
    -- Show XP gain notification
    if Config.Notifications.showXPGain and amount > 0 then
        ESX.ShowNotification(('+%s XP'):format(amount), 'info')
    end
    
    -- Update UI if open
    if battlepassOpen then
        SendNUIMessage({
            type = 'updateXP',
            xp = currentXP,
            level = currentLevel,
            xpNeeded = Config.XPPerLevel[currentLevel] or 0
        })
    end
end)

-- Handle mission updates
RegisterNetEvent('jr_battlepass:missionUpdate')
AddEventHandler('jr_battlepass:missionUpdate', function(missions)
    if battlepassOpen then
        SendNUIMessage({
            type = 'updateMissions',
            missions = missions
        })
    end
end)

-- Handle lootbox opening
RegisterNetEvent('jr_battlepass:lootboxOpened')
AddEventHandler('jr_battlepass:lootboxOpened', function(rewards)
    if battlepassOpen then
        SendNUIMessage({
            type = 'showLootboxRewards',
            rewards = rewards
        })
    end
    
    -- Show notification for each reward
    for _, reward in pairs(rewards) do
        local message = ('Loot Box: +%s %s'):format(reward.amount or 1, reward.label or reward.item)
        ESX.ShowNotification(message, 'success')
    end
end)

-- Handle premium purchase
RegisterNetEvent('jr_battlepass:premiumPurchased')
AddEventHandler('jr_battlepass:premiumPurchased', function(success)
    if success then
        premiumStatus = true
        ESX.ShowNotification('Premium Battlepass activated!', 'success')
        
        if battlepassOpen then
            SendNUIMessage({
                type = 'premiumActivated'
            })
        end
    else
        ESX.ShowNotification('Failed to purchase Premium Battlepass', 'error')
    end
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        if battlepassOpen then
            SetNuiFocus(false, false)
            battlepassOpen = false
        end
    end
end)

-- Export functions for other resources
exports('getBattlepassLevel', function()
    return currentLevel
end)

exports('getBattlepassXP', function()
    return currentXP
end)

exports('isPremium', function()
    return premiumStatus
end)

exports('isBattlepassOpen', function()
    return battlepassOpen
end)