local missionProgress = {}
local sessionStartTime = GetGameTimer()
local totalDistance = 0
local lastPosition = nil
local sessionMoney = 0

-- Initialize mission tracking
CreateThread(function()
    while ESX == nil do
        Wait(100)
    end
    
    -- Request mission data from server
    TriggerServerEvent('jr_battlepass:requestMissions')
end)

-- Receive missions from server
RegisterNetEvent('jr_battlepass:receiveMissions')
AddEventHandler('jr_battlepass:receiveMissions', function(missions)
    missionProgress = missions or {}
end)

-- Track playtime mission
CreateThread(function()
    while true do
        Wait(60000) -- Check every minute
        
        local currentTime = GetGameTimer()
        local sessionTime = (currentTime - sessionStartTime) / 1000 -- Convert to seconds
        
        -- Update playtime mission
        TriggerServerEvent('jr_battlepass:updateMission', 'playtime', math.floor(sessionTime))
        
        Wait(60000)
    end
end)

-- Track driving distance
CreateThread(function()
    while true do
        Wait(1000) -- Check every second
        
        local playerPed = PlayerPedId()
        if IsPedInAnyVehicle(playerPed, false) then
            local vehicle = GetVehiclePedIsIn(playerPed, false)
            if GetPedInVehicleSeat(vehicle, -1) == playerPed then -- Driver seat
                local currentPos = GetEntityCoords(playerPed)
                
                if lastPosition then
                    local distance = #(currentPos - lastPosition)
                    if distance < 100 then -- Prevent teleport cheating
                        totalDistance = totalDistance + distance
                        
                        -- Update driving mission every 1km
                        if totalDistance >= 1000 then
                            TriggerServerEvent('jr_battlepass:updateMission', 'driving', math.floor(totalDistance))
                        end
                    end
                end
                
                lastPosition = currentPos
            end
        else
            lastPosition = nil
        end
    end
end)

-- Track money earned
RegisterNetEvent('esx:addInventoryItem')
AddEventHandler('esx:addInventoryItem', function(item, count)
    -- Track certain valuable items as "money earned"
    local valuableItems = {
        gold = 1000,
        diamond = 2000,
        weed = 50,
        coke = 100
    }
    
    if valuableItems[item] then
        local value = valuableItems[item] * count
        sessionMoney = sessionMoney + value
        TriggerServerEvent('jr_battlepass:updateMission', 'money', sessionMoney)
    end
end)

-- Track money changes
local lastMoney = 0
local lastBank = 0

CreateThread(function()
    while true do
        Wait(5000) -- Check every 5 seconds
        
        if PlayerData and PlayerData.money and PlayerData.accounts then
            local currentMoney = PlayerData.money
            local currentBank = 0
            
            for _, account in pairs(PlayerData.accounts) do
                if account.name == 'bank' then
                    currentBank = account.money
                    break
                end
            end
            
            local moneyGained = 0
            if currentMoney > lastMoney then
                moneyGained = moneyGained + (currentMoney - lastMoney)
            end
            if currentBank > lastBank then
                moneyGained = moneyGained + (currentBank - lastBank)
            end
            
            if moneyGained > 0 then
                sessionMoney = sessionMoney + moneyGained
                TriggerServerEvent('jr_battlepass:updateMission', 'money', sessionMoney)
            end
            
            lastMoney = currentMoney
            lastBank = currentBank
        end
    end
end)

-- Track fishing (when using fishing rod)
CreateThread(function()
    while true do
        Wait(1000)
        
        local playerPed = PlayerPedId()
        local weapon = GetSelectedPedWeapon(playerPed)
        
        -- Check if player is using fishing rod (replace with actual fishing rod hash)
        if weapon == GetHashKey('weapon_fishing_rod') or IsPlayerFishing() then
            -- This would need integration with your fishing system
            -- TriggerServerEvent('jr_battlepass:updateMission', 'fishing', 1)
        end
    end
end)

-- Custom function to check if player is fishing (implement based on your fishing system)
function IsPlayerFishing()
    -- This should integrate with your server's fishing system
    -- Return true if player is currently fishing
    return false
end

-- Track job completions
RegisterNetEvent('esx:onJobComplete')
AddEventHandler('esx:onJobComplete', function(jobName)
    TriggerServerEvent('jr_battlepass:updateMission', 'jobs', 1)
end)

-- Track race wins
RegisterNetEvent('jr_battlepass:raceWon')
AddEventHandler('jr_battlepass:raceWon', function()
    TriggerServerEvent('jr_battlepass:updateMission', 'races', 1)
end)

-- Track combat (NPC kills)
CreateThread(function()
    while true do
        Wait(1000)
        
        local playerPed = PlayerPedId()
        if HasEntityBeenDamagedByAnyPed(playerPed) or HasEntityBeenDamagedByAnyVehicle(playerPed) then
            -- Check if player killed an NPC recently
            local nearbyPeds = GetNearbyPeds(playerPed, 50.0)
            for _, ped in pairs(nearbyPeds) do
                if IsEntityDead(ped) and not IsPedAPlayer(ped) then
                    -- Check if this NPC was killed by player recently
                    if HasEntityBeenDamagedByEntity(ped, playerPed, 0) then
                        TriggerServerEvent('jr_battlepass:updateMission', 'combat', 1)
                        break
                    end
                end
            end
        end
    end
end)

-- Helper function to get nearby peds
function GetNearbyPeds(playerPed, radius)
    local peds = {}
    local handle, ped = FindFirstPed()
    local success
    
    repeat
        local pos = GetEntityCoords(ped)
        local playerPos = GetEntityCoords(playerPed)
        
        if #(pos - playerPos) <= radius and ped ~= playerPed then
            table.insert(peds, ped)
        end
        
        success, ped = FindNextPed(handle)
    until not success
    
    EndFindPed(handle)
    return peds
end

-- Track drug farming/processing
RegisterNetEvent('jr_battlepass:drugProcessed')
AddEventHandler('jr_battlepass:drugProcessed', function(amount)
    TriggerServerEvent('jr_battlepass:updateMission', 'farming', amount or 1)
end)

-- Mission completion handler
RegisterNetEvent('jr_battlepass:missionCompleted')
AddEventHandler('jr_battlepass:missionCompleted', function(missionData, reward)
    local message = ('Mission Complete: %s'):format(missionData.label)
    ESX.ShowNotification(message, 'success')
    
    -- Play completion sound
    PlaySoundFrontend(-1, "CHALLENGE_UNLOCKED", "HUD_AWARDS", false)
    
    -- Show reward notification
    if reward.xp and reward.xp > 0 then
        ESX.ShowNotification(('+%s XP'):format(reward.xp), 'info')
    end
    
    if reward.money and reward.money > 0 then
        ESX.ShowNotification(('+€%s'):format(reward.money), 'info')
    end
    
    if reward.items then
        for _, item in pairs(reward.items) do
            ESX.ShowNotification(('+%s %s'):format(item.amount, item.item), 'info')
        end
    end
    
    -- Update UI if battlepass is open
    if battlepassOpen then
        SendNUIMessage({
            type = 'missionCompleted',
            mission = missionData
        })
    end
end)

-- Daily mission reset notification
RegisterNetEvent('jr_battlepass:dailyReset')
AddEventHandler('jr_battlepass:dailyReset', function()
    ESX.ShowNotification('Daily missions have been reset!', 'info')
    sessionMoney = 0
    totalDistance = 0
    sessionStartTime = GetGameTimer()
    
    -- Request new missions
    TriggerServerEvent('jr_battlepass:requestMissions')
end)

-- Weekly mission reset notification
RegisterNetEvent('jr_battlepass:weeklyReset')
AddEventHandler('jr_battlepass:weeklyReset', function()
    ESX.ShowNotification('Weekly missions have been reset!', 'info')
    
    -- Request new missions
    TriggerServerEvent('jr_battlepass:requestMissions')
end)

-- Export mission progress for other resources
exports('getMissionProgress', function()
    return missionProgress
end)

exports('updateMissionProgress', function(missionId, progress)
    TriggerServerEvent('jr_battlepass:updateMission', missionId, progress)
end)

-- Integration hooks for popular resources
CreateThread(function()
    -- ESX Jobs integration
    if GetResourceState('esx_jobs') == 'started' then
        RegisterNetEvent('esx_jobs:jobCompleted')
        AddEventHandler('esx_jobs:jobCompleted', function()
            TriggerServerEvent('jr_battlepass:updateMission', 'jobs', 1)
        end)
    end
    
    -- Fishing integration (example for esx_fishing)
    if GetResourceState('esx_fishing') == 'started' then
        RegisterNetEvent('esx_fishing:fishCaught')
        AddEventHandler('esx_fishing:fishCaught', function()
            TriggerServerEvent('jr_battlepass:updateMission', 'fishing', 1)
        end)
    end
    
    -- Racing integration (example for esx_racing)
    if GetResourceState('esx_racing') == 'started' then
        RegisterNetEvent('esx_racing:raceWon')
        AddEventHandler('esx_racing:raceWon', function()
            TriggerServerEvent('jr_battlepass:updateMission', 'races', 1)
        end)
    end
end)