-- 🎯 Mission management system for JR.DEV Battlepass
local MissionSystem = {}

-- 📊 Mission progress tracking
local ActiveMissions = {}
local MissionStats = {
    dailyProgress = {},
    weeklyProgress = {},
    lastReset = {
        daily = 0,
        weekly = 0
    }
}

-- 🎯 Initialize mission system
CreateThread(function()
    -- Wait for player data to be loaded
    while not ESX.GetPlayerData().identifier do
        Citizen.Wait(100)
    end
    
    -- Request active missions from server
    TriggerServerEvent('battlepass:requestActiveMissions')
end)

-- 📋 Receive missions from server
RegisterNetEvent('battlepass:receiveActiveMissions')
AddEventHandler('battlepass:receiveActiveMissions', function(missions)
    ActiveMissions = missions
    
    -- Initialize progress tracking
    for _, mission in pairs(missions) do
        if mission.mission_type == 'daily' then
            MissionStats.dailyProgress[mission.mission_id] = mission.progress or 0
        elseif mission.mission_type == 'weekly' then
            MissionStats.weeklyProgress[mission.mission_id] = mission.progress or 0
        end
    end
    
    -- Send to NUI
    SendNUIMessage({
        type = 'updateActiveMissions',
        data = {missions = ActiveMissions}
    })
    
    print("^2[JR.DEV Battlepass]^7 Loaded " .. #ActiveMissions .. " active missions")
end)

-- 🎯 Mission progress update
function MissionSystem.updateProgress(missionId, progress, isIncrement)
    local mission = nil
    
    -- Find the mission
    for _, m in pairs(ActiveMissions) do
        if m.mission_id == missionId then
            mission = m
            break
        end
    end
    
    if not mission then
        -- Create new mission if it doesn't exist (daily missions are auto-created)
        local missionConfig = GetMissionConfig(missionId)
        if missionConfig then
            TriggerServerEvent('battlepass:createMission', missionId, missionConfig.type)
            return
        end
    end
    
    local newProgress = progress
    if isIncrement then
        local currentProgress = 0
        if mission.mission_type == 'daily' then
            currentProgress = MissionStats.dailyProgress[missionId] or 0
        elseif mission.mission_type == 'weekly' then
            currentProgress = MissionStats.weeklyProgress[missionId] or 0
        end
        newProgress = currentProgress + progress
    end
    
    -- Update local progress
    if mission.mission_type == 'daily' then
        MissionStats.dailyProgress[missionId] = newProgress
    elseif mission.mission_type == 'weekly' then
        MissionStats.weeklyProgress[missionId] = newProgress
    end
    
    -- Check if mission is completed
    local missionConfig = GetMissionConfig(missionId)
    if missionConfig and newProgress >= missionConfig.target then
        newProgress = missionConfig.target -- Cap at target
        
        if not mission.completed then
            TriggerEvent('battlepass:missionCompleted', {
                missionId = missionId,
                config = missionConfig,
                progress = newProgress
            })
        end
    end
    
    -- Update server
    TriggerServerEvent('battlepass:updateMissionProgress', missionId, newProgress)
    
    -- Update NUI
    SendNUIMessage({
        type = 'updateMissionProgress',
        data = {
            missionId = missionId,
            progress = newProgress,
            completed = newProgress >= (missionConfig and missionConfig.target or 100)
        }
    })
end

-- 🔍 Get mission configuration
function GetMissionConfig(missionId)
    -- Check daily missions
    for _, mission in pairs(Config.DailyMissions) do
        if mission.id == missionId then
            return mission
        end
    end
    
    -- Check weekly missions
    for _, mission in pairs(Config.WeeklyMissions) do
        if mission.id == missionId then
            return mission
        end
    end
    
    return nil
end

-- ⏱️ Playtime mission tracker
local PlaytimeTracker = {
    startTime = GetGameTimer(),
    sessionTime = 0,
    lastUpdate = GetGameTimer()
}

CreateThread(function()
    while true do
        local currentTime = GetGameTimer()
        local deltaTime = currentTime - PlaytimeTracker.lastUpdate
        
        if deltaTime >= 60000 then -- Update every minute
            PlaytimeTracker.sessionTime = PlaytimeTracker.sessionTime + 1
            PlaytimeTracker.lastUpdate = currentTime
            
            -- Update playtime missions
            MissionSystem.updateProgress('playtime_60', 1, true)
            
            -- Debug info
            if Config.Debug then
                print("^3[Battlepass Debug]^7 Playtime: " .. PlaytimeTracker.sessionTime .. " minutes")
            end
        end
        
        Citizen.Wait(1000)
    end
end)

-- 🚗 Distance mission tracker
local DistanceTracker = {
    lastPosition = nil,
    totalDistance = 0,
    sessionDistance = 0,
    updateInterval = 1000
}

CreateThread(function()
    while true do
        local playerPed = PlayerPedId()
        
        if IsPedInAnyVehicle(playerPed, false) then
            local currentPos = GetEntityCoords(playerPed)
            
            if DistanceTracker.lastPosition then
                local distance = #(currentPos - DistanceTracker.lastPosition)
                
                -- Only count reasonable distances (anti-cheat)
                if distance > 0 and distance < 500 then -- Max 500m per second
                    DistanceTracker.totalDistance = DistanceTracker.totalDistance + distance
                    DistanceTracker.sessionDistance = DistanceTracker.sessionDistance + distance
                    
                    -- Convert to kilometers and update mission
                    local distanceKm = DistanceTracker.totalDistance / 1000
                    MissionSystem.updateProgress('drive_25km', math.floor(distanceKm), false)
                end
            end
            
            DistanceTracker.lastPosition = currentPos
        else
            DistanceTracker.lastPosition = nil
        end
        
        Citizen.Wait(DistanceTracker.updateInterval)
    end
end)

-- 💰 Money earning tracker
local MoneyTracker = {
    sessionEarnings = 0,
    totalEarnings = 0,
    lastMoney = 0
}

-- Hook into ESX money events
RegisterNetEvent('esx:addedMoney')
AddEventHandler('esx:addedMoney', function(money)
    if money > 0 then
        MoneyTracker.sessionEarnings = MoneyTracker.sessionEarnings + money
        MoneyTracker.totalEarnings = MoneyTracker.totalEarnings + money
        
        MissionSystem.updateProgress('earn_10000', money, true)
        
        if Config.Debug then
            print("^3[Battlepass Debug]^7 Money earned: $" .. money .. " (Total: $" .. MoneyTracker.totalEarnings .. ")")
        end
    end
end)

-- Track bank money too
RegisterNetEvent('esx:addedAccountMoney')
AddEventHandler('esx:addedAccountMoney', function(account, money)
    if account == 'bank' and money > 0 then
        MoneyTracker.sessionEarnings = MoneyTracker.sessionEarnings + money
        MoneyTracker.totalEarnings = MoneyTracker.totalEarnings + money
        
        MissionSystem.updateProgress('earn_10000', money, true)
    end
end)

-- 🎣 Fishing mission integration
-- This is an example integration - adapt to your fishing system
RegisterNetEvent('esx_fishing:fishCaught') -- Example event name
AddEventHandler('esx_fishing:fishCaught', function(fishData)
    MissionSystem.updateProgress('catch_fish_10', 1, true)
    
    if Config.Debug then
        print("^3[Battlepass Debug]^7 Fish caught: " .. (fishData.name or "unknown"))
    end
end)

-- Alternative fishing integration
RegisterNetEvent('fishing:caughtFish')
AddEventHandler('fishing:caughtFish', function(fish)
    MissionSystem.updateProgress('catch_fish_10', 1, true)
end)

-- 🏁 Racing mission integration
-- Example for various racing systems
RegisterNetEvent('streetrace:raceFinished')
AddEventHandler('streetrace:raceFinished', function(raceData)
    if raceData.position == 1 then -- First place
        MissionSystem.updateProgress('win_races_5', 1, true)
        
        if Config.Debug then
            print("^3[Battlepass Debug]^7 Race won: " .. (raceData.raceName or "Unknown"))
        end
    end
end)

RegisterNetEvent('racing:raceWon')
AddEventHandler('racing:raceWon', function(raceData)
    MissionSystem.updateProgress('win_races_5', 1, true)
end)

-- 💼 Job completion tracking
local JobTracker = {
    completedJobs = 0,
    jobTypes = {}
}

-- Generic job completion event
RegisterNetEvent('esx:jobCompleted')
AddEventHandler('esx:jobCompleted', function(jobData)
    JobTracker.completedJobs = JobTracker.completedJobs + 1
    
    local jobType = jobData.type or jobData.name or 'unknown'
    JobTracker.jobTypes[jobType] = (JobTracker.jobTypes[jobType] or 0) + 1
    
    MissionSystem.updateProgress('complete_jobs_15', 1, true)
    
    if Config.Debug then
        print("^3[Battlepass Debug]^7 Job completed: " .. jobType .. " (Total: " .. JobTracker.completedJobs .. ")")
    end
end)

-- Specific job integrations
RegisterNetEvent('esx_taxi:jobCompleted')
AddEventHandler('esx_taxi:jobCompleted', function()
    MissionSystem.updateProgress('complete_jobs_15', 1, true)
end)

RegisterNetEvent('esx_trucker:deliveryCompleted')
AddEventHandler('esx_trucker:deliveryCompleted', function()
    MissionSystem.updateProgress('complete_jobs_15', 1, true)
end)

RegisterNetEvent('esx_garbage:jobCompleted')
AddEventHandler('esx_garbage:jobCompleted', function()
    MissionSystem.updateProgress('complete_jobs_15', 1, true)
end)

-- 💊 Drug farming integration
local DrugTracker = {
    harvestedDrugs = 0,
    drugTypes = {}
}

RegisterNetEvent('esx_drugs:harvested')
AddEventHandler('esx_drugs:harvested', function(drugType, amount)
    amount = amount or 1
    DrugTracker.harvestedDrugs = DrugTracker.harvestedDrugs + amount
    DrugTracker.drugTypes[drugType] = (DrugTracker.drugTypes[drugType] or 0) + amount
    
    MissionSystem.updateProgress('farm_drugs_50', amount, true)
    
    if Config.Debug then
        print("^3[Battlepass Debug]^7 Drugs harvested: " .. amount .. "x " .. drugType)
    end
end)

-- Alternative drug system integrations
RegisterNetEvent('drugs:harvested')
AddEventHandler('drugs:harvested', function(drugType, amount)
    MissionSystem.updateProgress('farm_drugs_50', amount or 1, true)
end)

RegisterNetEvent('esx_drugs:processingComplete')
AddEventHandler('esx_drugs:processingComplete', function(drugType, amount)
    MissionSystem.updateProgress('farm_drugs_50', amount or 1, true)
end)

-- ⚔️ Combat/NPC kill tracking
local CombatTracker = {
    npcKills = 0,
    playerKills = 0,
    lastKillTime = 0
}

CreateThread(function()
    while true do
        local playerPed = PlayerPedId()
        
        -- Check if player has killed someone recently
        if HasEntityBeenDamagedByEntity(playerPed, playerPed, 0) then
            local coords = GetEntityCoords(playerPed)
            local nearbyPeds = GetNearbyPeds(coords, 50.0)
            
            for _, ped in pairs(nearbyPeds) do
                if IsEntityDead(ped) and not IsPedAPlayer(ped) then
                    -- Check if this is a recent kill
                    local currentTime = GetGameTimer()
                    if currentTime - CombatTracker.lastKillTime > 1000 then -- Prevent double counting
                        CombatTracker.npcKills = CombatTracker.npcKills + 1
                        CombatTracker.lastKillTime = currentTime
                        
                        MissionSystem.updateProgress('kill_npcs_25', 1, true)
                        
                        if Config.Debug then
                            print("^3[Battlepass Debug]^7 NPC killed (Total: " .. CombatTracker.npcKills .. ")")
                        end
                    end
                end
            end
        end
        
        Citizen.Wait(500)
    end
end)

-- 🛠️ Helper function to get nearby peds
function GetNearbyPeds(coords, radius)
    local peds = {}
    local handle, ped = FindFirstPed()
    local success
    
    repeat
        local pedCoords = GetEntityCoords(ped)
        local distance = #(coords - pedCoords)
        
        if distance <= radius and ped ~= PlayerPedId() then
            table.insert(peds, ped)
        end
        
        success, ped = FindNextPed(handle)
    until not success
    
    EndFindPed(handle)
    return peds
end

-- 🎯 Mission claim handling
RegisterNetEvent('battlepass:claimMissionReward')
AddEventHandler('battlepass:claimMissionReward', function(missionId)
    -- Find and update mission status
    for i, mission in pairs(ActiveMissions) do
        if mission.mission_id == missionId then
            ActiveMissions[i].claimed = true
            break
        end
    end
    
    -- Update NUI
    SendNUIMessage({
        type = 'missionRewardClaimed',
        data = {missionId = missionId}
    })
end)

-- 🔄 Mission reset handling
RegisterNetEvent('battlepass:missionsReset')
AddEventHandler('battlepass:missionsReset', function(missionType)
    if missionType == 'daily' then
        MissionStats.dailyProgress = {}
        MissionStats.lastReset.daily = os.time()
        
        ShowNotification('Daily missions have been reset!', 'info')
    elseif missionType == 'weekly' then
        MissionStats.weeklyProgress = {}
        MissionStats.lastReset.weekly = os.time()
        
        ShowNotification('Weekly missions have been reset!', 'info')
    end
    
    -- Request new missions
    TriggerServerEvent('battlepass:requestActiveMissions')
end)

-- 📊 Get mission statistics
function MissionSystem.getStats()
    return {
        playtime = PlaytimeTracker.sessionTime,
        distance = DistanceTracker.sessionDistance / 1000, -- Convert to km
        moneyEarned = MoneyTracker.sessionEarnings,
        npcKills = CombatTracker.npcKills,
        jobsCompleted = JobTracker.completedJobs,
        drugsHarvested = DrugTracker.harvestedDrugs,
        dailyProgress = MissionStats.dailyProgress,
        weeklyProgress = MissionStats.weeklyProgress
    }
end

-- 🎮 Export functions for other resources
exports('updateMissionProgress', function(missionId, progress, isIncrement)
    MissionSystem.updateProgress(missionId, progress, isIncrement or false)
end)

exports('getMissionStats', function()
    return MissionSystem.getStats()
end)

exports('getActiveMissions', function()
    return ActiveMissions
end)

-- 🔄 Auto-save mission progress
CreateThread(function()
    while true do
        Citizen.Wait(300000) -- Save every 5 minutes
        
        -- Send current progress to server for backup
        local stats = MissionSystem.getStats()
        TriggerServerEvent('battlepass:saveMissionProgress', stats)
    end
end)

print("^2[JR.DEV Battlepass]^7 Mission system loaded successfully")