local uiAnimations = {}
local soundSettings = {
    enabled = true,
    volume = 0.8
}

-- NUI Message Handlers
RegisterNUICallback('requestData', function(data, cb)
    -- Send current battlepass data to UI
    TriggerServerEvent('jr_battlepass:requestPlayerData')
    TriggerServerEvent('jr_battlepass:requestMissions')
    TriggerServerEvent('jr_battlepass:requestDailyReward')
    
    cb('ok')
end)

RegisterNUICallback('playSound', function(data, cb)
    if soundSettings.enabled and data.sound then
        PlayUISound(data.sound, data.set or "HUD_FRONTEND_DEFAULT_SOUNDSET")
    end
    cb('ok')
end)

RegisterNUICallback('requestLevelRewards', function(data, cb)
    if data.level then
        local freeReward = Config.LevelRewards[data.level]
        local premiumReward = Config.PremiumLevelRewards[data.level]
        
        cb({
            free = freeReward,
            premium = premiumReward
        })
    else
        cb('error')
    end
end)

RegisterNUICallback('requestMissionData', function(data, cb)
    cb({
        daily = Config.DailyMissions,
        weekly = Config.WeeklyMissions
    })
end)

RegisterNUICallback('requestLootboxData', function(data, cb)
    if data.boxType and Config.LootBoxes[data.boxType] then
        cb(Config.LootBoxes[data.boxType])
    else
        cb('error')
    end
end)

RegisterNUICallback('toggleSound', function(data, cb)
    soundSettings.enabled = not soundSettings.enabled
    ESX.ShowNotification('Sound ' .. (soundSettings.enabled and 'enabled' or 'disabled'), 'info')
    cb('ok')
end)

-- Handle animation requests from UI
RegisterNUICallback('triggerAnimation', function(data, cb)
    if data.type then
        TriggerUIAnimation(data.type, data.params or {})
    end
    cb('ok')
end)

-- Handle UI state changes
RegisterNUICallback('uiStateChanged', function(data, cb)
    if data.state then
        HandleUIStateChange(data.state, data.params or {})
    end
    cb('ok')
end)

-- Function to play UI sounds
function PlayUISound(soundName, soundSet)
    if soundSettings.enabled then
        PlaySoundFrontend(-1, soundName, soundSet or "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
    end
end

-- Function to trigger UI animations
function TriggerUIAnimation(animType, params)
    SendNUIMessage({
        type = 'triggerAnimation',
        animation = animType,
        params = params
    })
end)

-- Handle UI state changes
function HandleUIStateChange(state, params)
    if state == 'tabChanged' then
        PlayUISound("NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET")
    elseif state == 'rewardClaimed' then
        PlayUISound("CHALLENGE_UNLOCKED", "HUD_AWARDS")
        TriggerUIAnimation('rewardClaim', params)
    elseif state == 'levelUp' then
        PlayUISound("RANK_UP", "HUD_AWARDS")
        TriggerUIAnimation('levelUp', params)
    elseif state == 'lootboxOpen' then
        PlayUISound("LOSER", "HUD_AWARDS")
        TriggerUIAnimation('lootboxOpen', params)
    end
end)

-- Send level rewards data to UI
RegisterNetEvent('jr_battlepass:sendLevelRewards')
AddEventHandler('jr_battlepass:sendLevelRewards', function(level, freeReward, premiumReward, canClaimFree, canClaimPremium)
    if battlepassOpen then
        SendNUIMessage({
            type = 'updateLevelRewards',
            level = level,
            freeReward = freeReward,
            premiumReward = premiumReward,
            canClaimFree = canClaimFree,
            canClaimPremium = canClaimPremium
        })
    end
end)

-- Send daily reward data to UI
RegisterNetEvent('jr_battlepass:sendDailyReward')
AddEventHandler('jr_battlepass:sendDailyReward', function(day, reward, canClaim, timeLeft)
    if battlepassOpen then
        SendNUIMessage({
            type = 'updateDailyReward',
            day = day,
            reward = reward,
            canClaim = canClaim,
            timeLeft = timeLeft
        })
    end
end)

-- Handle premium benefits UI update
RegisterNetEvent('jr_battlepass:updatePremiumBenefits')
AddEventHandler('jr_battlepass:updatePremiumBenefits', function(benefits)
    if battlepassOpen then
        SendNUIMessage({
            type = 'updatePremiumBenefits',
            benefits = benefits
        })
    end
end)

-- Handle battlepass statistics
RegisterNetEvent('jr_battlepass:sendStatistics')
AddEventHandler('jr_battlepass:sendStatistics', function(stats)
    if battlepassOpen then
        SendNUIMessage({
            type = 'updateStatistics',
            stats = stats
        })
    end
end)

-- Particle effects for special events
function CreateUIParticleEffect(effectName, position)
    if effectName == 'levelUp' then
        -- Create level up particle effect
        local dict = 'scr_bike_business'
        local particleName = 'scr_bike_cfid_plane_trail'
        
        RequestNamedPtfxAsset(dict)
        while not HasNamedPtfxAssetLoaded(dict) do
            Wait(1)
        end
        
        UseParticleFxAssetNextCall(dict)
        local particle = StartParticleFxLoopedOnEntity(particleName, PlayerPedId(), 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0, false, false, false)
        
        -- Stop particle after 3 seconds
        SetTimeout(3000, function()
            if particle then
                StopParticleFxLooped(particle, 0)
            end
        end)
        
    elseif effectName == 'rewardClaim' then
        -- Create reward claim effect
        local dict = 'core'
        local particleName = 'ent_sht_money'
        
        RequestNamedPtfxAsset(dict)
        while not HasNamedPtfxAssetLoaded(dict) do
            Wait(1)
        end
        
        UseParticleFxAssetNextCall(dict)
        StartParticleFxNonLoopedAtCoord(particleName, position.x, position.y, position.z, 0.0, 0.0, 0.0, 1.0, false, false, false)
    end
end)

-- Screen effects for special events
function CreateScreenEffect(effectType, duration)
    duration = duration or 2000
    
    if effectType == 'levelUp' then
        -- Flash effect for level up
        DoScreenFadeOut(100)
        Wait(200)
        DoScreenFadeIn(800)
        
        -- Add screen flash
        AnimpostfxPlay("DrugsTrevorClownsFight", duration, true)
        
        SetTimeout(duration, function()
            AnimpostfxStop("DrugsTrevorClownsFight")
        end)
        
    elseif effectType == 'rewardClaim' then
        -- Subtle glow effect
        AnimpostfxPlay("MP_Corona_Switch", 1000, true)
        
        SetTimeout(1000, function()
            AnimpostfxStop("MP_Corona_Switch")
        end)
    end
end

-- Handle special reward animations
RegisterNetEvent('jr_battlepass:specialReward')
AddEventHandler('jr_battlepass:specialReward', function(rewardType, rewardData)
    if rewardType == 'vehicle' then
        -- Special animation for vehicle rewards
        CreateScreenEffect('rewardClaim', 3000)
        CreateUIParticleEffect('rewardClaim', GetEntityCoords(PlayerPedId()))
        
        ESX.ShowNotification(('🚗 Vehicle Unlocked: %s'):format(rewardData.label), 'success')
        
    elseif rewardType == 'legendary' then
        -- Special animation for legendary items
        CreateScreenEffect('levelUp', 4000)
        CreateUIParticleEffect('levelUp')
        
        ESX.ShowNotification(('⭐ Legendary Reward: %s'):format(rewardData.label), 'success')
        
    elseif rewardType == 'mega' then
        -- MEGA bonus animation
        CreateScreenEffect('levelUp', 5000)
        CreateUIParticleEffect('levelUp')
        
        -- Multiple notifications for mega bonus
        ESX.ShowNotification('💎 MEGA BONUS UNLOCKED!', 'success')
        SetTimeout(1000, function()
            ESX.ShowNotification(('💰 +€%s'):format(rewardData.money), 'info')
        end)
        SetTimeout(2000, function()
            ESX.ShowNotification(('🎁 +%s'):format(rewardData.item_label), 'info')
        end)
    end
end)

-- UI Data synchronization
function SyncUIData()
    if battlepassOpen then
        TriggerServerEvent('jr_battlepass:requestPlayerData')
        TriggerServerEvent('jr_battlepass:requestMissions')
        TriggerServerEvent('jr_battlepass:requestDailyReward')
    end
end

-- Periodic UI updates
CreateThread(function()
    while true do
        Wait(30000) -- Update every 30 seconds
        
        if battlepassOpen then
            SyncUIData()
        end
    end
end)

-- Handle UI error messages
RegisterNUICallback('showError', function(data, cb)
    if data.message then
        ESX.ShowNotification(data.message, 'error')
    end
    cb('ok')
end)

-- Handle UI success messages
RegisterNUICallback('showSuccess', function(data, cb)
    if data.message then
        ESX.ShowNotification(data.message, 'success')
    end
    cb('ok')
end)

-- Handle UI info messages
RegisterNUICallback('showInfo', function(data, cb)
    if data.message then
        ESX.ShowNotification(data.message, 'info')
    end
    cb('ok')
end)

-- Export UI functions for other resources
exports('triggerUIAnimation', TriggerUIAnimation)
exports('createScreenEffect', CreateScreenEffect)
exports('syncUIData', SyncUIData)
exports('playUISound', PlayUISound)