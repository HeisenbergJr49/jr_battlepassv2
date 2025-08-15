-- 🎮 Client-side main script for JR.DEV Battlepass
local ESX = exports["es_extended"]:getSharedObject()
local PlayerData = {}
local BattlepassData = {}
local SecurityToken = nil
local BattlepassOpen = false

-- 📱 UI State Management
local UIState = {
    currentTab = 'battlepass', -- battlepass, daily, missions
    isLoading = false,
    lastUpdate = 0
}

-- 🚀 Initialize battlepass system
CreateThread(function()
    while ESX.GetPlayerData().job == nil do
        Citizen.Wait(10)
    end
    
    PlayerData = ESX.GetPlayerData()
    TriggerServerEvent('battlepass:playerLoaded')
    
    -- Register keybind
    RegisterKeyMapping('battlepass', _U('command_battlepass'), 'keyboard', Config.UI.keybind)
end)

-- 👤 Player loaded event
RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
    PlayerData = xPlayer
    TriggerServerEvent('battlepass:playerLoaded')
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
    PlayerData.job = job
end)

-- 📊 Receive player data from server
RegisterNetEvent('battlepass:receivePlayerData')
AddEventHandler('battlepass:receivePlayerData', function(data)
    BattlepassData = data.player
    SecurityToken = data.token
    
    -- Send initial data to NUI
    SendNUIMessage({
        type = 'updatePlayerData',
        data = {
            player = BattlepassData,
            config = data.config,
            locales = GetCurrentLocales()
        }
    })
    
    -- Show welcome message for new players
    if BattlepassData.level == 1 and BattlepassData.xp == 0 then
        ShowNotification(_U('battlepass') .. ' System aktiviert! Drücke ' .. Config.UI.keybind, 'success')
    end
end)

-- 🎯 Update player data
RegisterNetEvent('battlepass:updatePlayerData')
AddEventHandler('battlepass:updatePlayerData', function(newData)
    for key, value in pairs(newData) do
        BattlepassData[key] = value
    end
    
    -- Update NUI
    SendNUIMessage({
        type = 'updatePlayerData',
        data = {player = BattlepassData}
    })
end)

-- 📈 XP gained event
RegisterNetEvent('battlepass:xpGained')
AddEventHandler('battlepass:xpGained', function(amount, reason)
    ShowNotification(_U('xp_gained', amount), 'success')
    
    -- Show XP gain animation
    SendNUIMessage({
        type = 'showXPGain',
        data = {
            amount = amount,
            reason = reason or 'Unknown'
        }
    })
    
    -- Play sound effect
    if Config.UI.sounds then
        PlaySoundFrontend(-1, "PICK_UP", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
    end
end)

-- 🆙 Level up event
RegisterNetEvent('battlepass:levelUp')
AddEventHandler('battlepass:levelUp', function(newLevel, oldLevel)
    ShowNotification(_U('level_up', newLevel), 'success')
    
    -- Show level up animation
    SendNUIMessage({
        type = 'showLevelUp',
        data = {
            newLevel = newLevel,
            oldLevel = oldLevel
        }
    })
    
    -- Play level up sound
    if Config.UI.sounds then
        PlaySoundFrontend(-1, "RANK_UP", "HUD_AWARDS", false)
    end
    
    -- Screen effect
    StartScreenEffect("HeistCelebPass", 3000, false)
end)

-- 🎁 Daily reward claimed
RegisterNetEvent('battlepass:dailyRewardClaimed')
AddEventHandler('battlepass:dailyRewardClaimed', function(rewardData)
    BattlepassData.daily_streak = rewardData.streak
    BattlepassData.last_daily_claim = os.time()
    
    -- Update NUI
    SendNUIMessage({
        type = 'dailyRewardClaimed',
        data = rewardData
    })
    
    -- Play reward sound
    if Config.UI.sounds then
        PlaySoundFrontend(-1, "PURCHASE", "HUD_LIQUOR_STORE_SOUNDSET", false)
    end
end)

-- 💎 Premium activated
RegisterNetEvent('battlepass:premiumActivated')
AddEventHandler('battlepass:premiumActivated', function(expiryDate)
    BattlepassData.premium = true
    BattlepassData.premium_expires = expiryDate
    
    -- Update NUI
    SendNUIMessage({
        type = 'premiumActivated',
        data = {
            expires = expiryDate
        }
    })
    
    -- Show premium effect
    StartScreenEffect("HeistCelebPassBW", 5000, false)
end)

-- 📧 Show notification
RegisterNetEvent('battlepass:showNotification')
AddEventHandler('battlepass:showNotification', function(message, type)
    ShowNotification(message, type)
end)

-- 🎮 Commands
RegisterCommand('battlepass', function()
    if not PlayerData or not BattlepassData then
        ShowNotification('Battlepass data not loaded yet', 'error')
        return
    end
    
    ToggleBattlepass()
end)

-- 🖥️ UI Functions
function ToggleBattlepass()
    BattlepassOpen = not BattlepassOpen
    
    SetNuiFocus(BattlepassOpen, BattlepassOpen)
    
    SendNUIMessage({
        type = 'toggleUI',
        data = {
            show = BattlepassOpen,
            currentTab = UIState.currentTab
        }
    })
    
    if BattlepassOpen then
        -- Request fresh data when opening
        TriggerServerEvent('battlepass:requestUpdate')
        
        -- Disable controls while UI is open
        CreateThread(function()
            while BattlepassOpen do
                DisableControlAction(0, 1, true)   -- LookLeftRight
                DisableControlAction(0, 2, true)   -- LookUpDown
                DisableControlAction(0, 24, true)  -- Attack
                DisableControlAction(0, 257, true) -- Attack2
                DisableControlAction(0, 25, true)  -- Aim
                DisableControlAction(0, 263, true) -- MeleeAttack1
                
                Citizen.Wait(1)
            end
        end)
    end
end

function ShowNotification(message, type)
    -- ESX notification
    ESX.ShowNotification(message)
    
    -- Also send to NUI for custom notifications
    SendNUIMessage({
        type = 'showNotification',
        data = {
            message = message,
            type = type or 'info'
        }
    })
end

-- 🎯 Mission progress tracking
local MissionTrackers = {
    playtime = 0,
    distance = 0,
    lastPosition = nil,
    moneyEarned = 0,
    fishCaught = 0
}

-- ⏱️ Playtime tracker
CreateThread(function()
    while true do
        if PlayerData and PlayerData.job then
            MissionTrackers.playtime = MissionTrackers.playtime + 1
            
            -- Update mission progress every minute
            if MissionTrackers.playtime % 60 == 0 then
                TriggerServerEvent('battlepass:updateMissionProgress', 'playtime_60', MissionTrackers.playtime / 60)
            end
        end
        
        Citizen.Wait(60000) -- 1 minute
    end
end)

-- 🚗 Distance tracker
CreateThread(function()
    while true do
        if PlayerData and IsPedInAnyVehicle(PlayerPedId(), false) then
            local currentPos = GetEntityCoords(PlayerPedId())
            
            if MissionTrackers.lastPosition then
                local distance = #(currentPos - MissionTrackers.lastPosition)
                MissionTrackers.distance = MissionTrackers.distance + distance
                
                -- Update distance missions
                TriggerServerEvent('battlepass:updateMissionProgress', 'drive_25km', MissionTrackers.distance)
            end
            
            MissionTrackers.lastPosition = currentPos
        else
            MissionTrackers.lastPosition = nil
        end
        
        Citizen.Wait(1000)
    end
end)

-- 💰 Money tracking
RegisterNetEvent('esx:addedMoney')
AddEventHandler('esx:addedMoney', function(money)
    MissionTrackers.moneyEarned = MissionTrackers.moneyEarned + money
    TriggerServerEvent('battlepass:updateMissionProgress', 'earn_10000', MissionTrackers.moneyEarned)
end)

-- 🎣 Fishing tracking (integrate with your fishing system)
RegisterNetEvent('fishing:caughtFish') -- Example event from fishing script
AddEventHandler('fishing:caughtFish', function(fish)
    MissionTrackers.fishCaught = MissionTrackers.fishCaught + 1
    TriggerServerEvent('battlepass:updateMissionProgress', 'catch_fish_10', MissionTrackers.fishCaught)
end)

-- 🏁 Racing integration (example)
RegisterNetEvent('racing:raceWon')
AddEventHandler('racing:raceWon', function(raceData)
    TriggerServerEvent('battlepass:updateMissionProgress', 'win_races_5', 1)
end)

-- 💼 Job completion integration
RegisterNetEvent('esx:jobCompleted')
AddEventHandler('esx:jobCompleted', function(jobData)
    TriggerServerEvent('battlepass:updateMissionProgress', 'complete_jobs_15', 1)
end)

-- 💊 Drug farming integration (example)
RegisterNetEvent('drugs:harvested')
AddEventHandler('drugs:harvested', function(drugType, amount)
    TriggerServerEvent('battlepass:updateMissionProgress', 'farm_drugs_50', amount)
end)

-- ⚔️ Combat tracking
CreateThread(function()
    while true do
        local playerPed = PlayerPedId()
        
        if HasEntityBeenDamagedByAnyPed(playerPed) then
            local damager = GetPedSourceOfDamage(playerPed)
            
            if damager ~= 0 and not IsPedAPlayer(damager) then
                -- Player killed an NPC
                if IsEntityDead(damager) then
                    TriggerServerEvent('battlepass:updateMissionProgress', 'kill_npcs_25', 1)
                end
            end
        end
        
        Citizen.Wait(100)
    end
end)

-- 📱 NUI Callbacks
RegisterNUICallback('closeBattlepass', function(data, cb)
    ToggleBattlepass()
    cb('ok')
end)

RegisterNUICallback('switchTab', function(data, cb)
    UIState.currentTab = data.tab
    cb('ok')
end)

RegisterNUICallback('claimDailyReward', function(data, cb)
    TriggerServerEvent('battlepass:claimDailyReward', SecurityToken)
    cb('ok')
end)

RegisterNUICallback('claimLevelReward', function(data, cb)
    TriggerServerEvent('battlepass:claimLevelReward', data.level, data.passType, SecurityToken)
    cb('ok')
end)

RegisterNUICallback('buyPremium', function(data, cb)
    TriggerServerEvent('battlepass:buyPremium', SecurityToken)
    cb('ok')
end)

RegisterNUICallback('buyLevel', function(data, cb)
    TriggerServerEvent('battlepass:buyLevel', SecurityToken)
    cb('ok')
end)

RegisterNUICallback('claimMissionReward', function(data, cb)
    TriggerServerEvent('battlepass:claimMissionReward', data.missionId, SecurityToken)
    cb('ok')
end)

RegisterNUICallback('openLootBox', function(data, cb)
    TriggerServerEvent('battlepass:openLootBox', data.boxType, SecurityToken)
    cb('ok')
end)

-- 🔄 Utility functions
function GetCurrentLocales()
    -- Return current language locales
    local locale = GetConvar('locale', 'de')
    return Locales[locale] or Locales['en']
end

-- 🎨 Screen effects for rewards
RegisterNetEvent('battlepass:showRewardEffect')
AddEventHandler('battlepass:showRewardEffect', function(effectType)
    if effectType == 'premium' then
        StartScreenEffect("HeistCelebPassBW", 5000, false)
    elseif effectType == 'legendary' then
        StartScreenEffect("HeistCelebPass", 3000, false)
    elseif effectType == 'rare' then
        StartScreenEffect("MenuMGSelectionTint", 2000, false)
    end
end)

-- 📊 Debug information
RegisterNetEvent('battlepass:showDebugInfo')
AddEventHandler('battlepass:showDebugInfo', function(debugData)
    -- Send debug info to NUI
    SendNUIMessage({
        type = 'showDebugInfo',
        data = debugData
    })
end)

-- 🔄 Config reload
RegisterNetEvent('battlepass:reloadConfig')
AddEventHandler('battlepass:reloadConfig', function()
    -- Refresh client-side config
    SendNUIMessage({
        type = 'reloadConfig',
        data = {
            config = Config,
            locales = GetCurrentLocales()
        }
    })
end)

-- 🚨 Admin statistics display
RegisterNetEvent('battlepass:showAdminStats')
AddEventHandler('battlepass:showAdminStats', function(stats)
    SendNUIMessage({
        type = 'showAdminStats',
        data = stats
    })
end)

-- 🎁 Loot box opening result
RegisterNetEvent('battlepass:lootBoxReward')
AddEventHandler('battlepass:lootBoxReward', function(rewardData)
    SendNUIMessage({
        type = 'lootBoxOpened',
        data = rewardData
    })
    
    -- Play loot box opening sound
    if Config.UI.sounds then
        PlaySoundFrontend(-1, "LOSER", "HUD_AWARDS", false)
        Citizen.Wait(1000)
        PlaySoundFrontend(-1, "PURCHASE", "HUD_LIQUOR_STORE_SOUNDSET", false)
    end
end)

-- 📋 Receive missions data
RegisterNetEvent('battlepass:receiveMissions')
AddEventHandler('battlepass:receiveMissions', function(missions)
    SendNUIMessage({
        type = 'updateMissions',
        data = {missions = missions}
    })
end)

-- 🎯 Mission completed
RegisterNetEvent('battlepass:missionCompleted')
AddEventHandler('battlepass:missionCompleted', function(missionData)
    ShowNotification(_U('mission_completed'), 'success')
    
    SendNUIMessage({
        type = 'missionCompleted',
        data = missionData
    })
    
    if Config.UI.sounds then
        PlaySoundFrontend(-1, "CHALLENGE_UNLOCKED", "HUD_AWARDS", false)
    end
end)

-- 🛡️ Anti-cheat integration
CreateThread(function()
    while true do
        -- Basic anti-cheat checks
        if Config.Security.enableAntiCheat then
            local playerPed = PlayerPedId()
            
            -- Check for speed hacks
            if IsPedInAnyVehicle(playerPed, false) then
                local vehicle = GetVehiclePedIsIn(playerPed, false)
                local speed = GetEntitySpeed(vehicle) * 3.6 -- Convert to km/h
                
                if speed > 500 then -- Suspicious speed
                    TriggerServerEvent('battlepass:reportSuspiciousActivity', 'speed_hack', speed)
                end
            end
            
            -- Check for teleportation
            local currentPos = GetEntityCoords(playerPed)
            if MissionTrackers.lastPosition then
                local distance = #(currentPos - MissionTrackers.lastPosition)
                if distance > 1000 and not IsPedInAnyVehicle(playerPed, false) then
                    TriggerServerEvent('battlepass:reportSuspiciousActivity', 'teleportation', distance)
                end
            end
        end
        
        Citizen.Wait(5000)
    end
end)

print("^2[JR.DEV Battlepass]^7 Client main script loaded successfully")