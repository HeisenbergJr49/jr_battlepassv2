-- 🎨 UI management for JR.DEV Battlepass
local UIManager = {}

-- 📱 UI state
local UIState = {
    isOpen = false,
    currentTab = 'battlepass',
    isLoading = false,
    animations = true,
    debugMode = false
}

-- 🎯 Animation system
local AnimationSystem = {
    fadeInDuration = 300,
    fadeOutDuration = 200,
    slideDistance = 50,
    scaleEffect = true
}

-- 🎮 Initialize UI system
CreateThread(function()
    -- Wait for game to load
    while not HasStreamedTextureDictLoaded("mpleaderboard") do
        RequestStreamedTextureDict("mpleaderboard", true)
        Citizen.Wait(100)
    end
    
    -- Set default NUI settings
    SetNuiFocusKeepInput(false)
    
    print("^2[JR.DEV Battlepass]^7 UI system initialized")
end)

-- 🖼️ Texture loading for UI
CreateThread(function()
    local textures = {
        "mpleaderboard",
        "mpgui",
        "commonmenu",
        "mphud"
    }
    
    for _, texture in pairs(textures) do
        if not HasStreamedTextureDictLoaded(texture) then
            RequestStreamedTextureDict(texture, true)
            
            while not HasStreamedTextureDictLoaded(texture) do
                Citizen.Wait(10)
            end
        end
    end
end)

-- 🎨 Theme management
local ThemeManager = {
    currentTheme = 'dark_gold',
    themes = {
        dark_gold = {
            primary = '#FFD700',
            secondary = '#1a1a1a',
            accent = '#FFA500',
            background = '#0d1117',
            text = '#ffffff',
            success = '#28a745',
            warning = '#ffc107',
            error = '#dc3545'
        },
        blue_cyber = {
            primary = '#00ffff',
            secondary = '#0f0f0f',
            accent = '#0080ff',
            background = '#0a0a0a',
            text = '#ffffff',
            success = '#00ff00',
            warning = '#ffff00',
            error = '#ff0040'
        }
    }
}

-- 🎯 Open battlepass UI
function UIManager.openBattlepass()
    if UIState.isOpen then return end
    
    UIState.isOpen = true
    UIState.isLoading = true
    
    -- Set NUI focus
    SetNuiFocus(true, true)
    
    -- Get current player data
    local playerData = BattlepassData or {}
    local theme = ThemeManager.themes[ThemeManager.currentTheme] or ThemeManager.themes.dark_gold
    
    -- Send open message to NUI
    SendNUIMessage({
        type = 'openBattlepass',
        data = {
            player = playerData,
            theme = theme,
            currentTab = UIState.currentTab,
            config = {
                maxLevel = Config.Battlepass.maxLevel,
                xpPerLevel = Config.Battlepass.xpPerLevel,
                premiumCost = Config.Battlepass.premiumCost,
                animations = UIState.animations,
                sounds = Config.UI.sounds
            },
            locales = GetCurrentLocales()
        }
    })
    
    -- Play UI open sound
    if Config.UI.sounds then
        PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
    end
    
    -- UI animation effect
    if UIState.animations then
        DoScreenFadeOut(100)
        Citizen.Wait(100)
        DoScreenFadeIn(300)
    end
    
    UIState.isLoading = false
end

-- 🚪 Close battlepass UI
function UIManager.closeBattlepass()
    if not UIState.isOpen then return end
    
    UIState.isOpen = false
    
    -- Remove NUI focus
    SetNuiFocus(false, false)
    
    -- Send close message to NUI
    SendNUIMessage({
        type = 'closeBattlepass',
        data = {}
    })
    
    -- Play UI close sound
    if Config.UI.sounds then
        PlaySoundFrontend(-1, "BACK", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
    end
    
    -- UI animation effect
    if UIState.animations then
        DoScreenFadeOut(100)
        Citizen.Wait(100)
        DoScreenFadeIn(200)
    end
end

-- 🔄 Toggle battlepass UI
function UIManager.toggleBattlepass()
    if UIState.isOpen then
        UIManager.closeBattlepass()
    else
        UIManager.openBattlepass()
    end
end

-- 📑 Switch UI tab
function UIManager.switchTab(tabName)
    if not UIState.isOpen then return end
    
    UIState.currentTab = tabName
    
    SendNUIMessage({
        type = 'switchTab',
        data = {
            tab = tabName,
            animation = UIState.animations
        }
    })
    
    -- Play tab switch sound
    if Config.UI.sounds then
        PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
    end
end

-- 🎁 Show reward animation
function UIManager.showRewardAnimation(rewardData)
    SendNUIMessage({
        type = 'showRewardAnimation',
        data = {
            reward = rewardData,
            duration = 3000,
            effects = true
        }
    })
    
    -- Screen effects based on reward rarity
    if rewardData.rarity == 'legendary' then
        StartScreenEffect("HeistCelebPass", 3000, false)
        if Config.UI.sounds then
            PlaySoundFrontend(-1, "CHALLENGE_UNLOCKED", "HUD_AWARDS", false)
        end
    elseif rewardData.rarity == 'epic' then
        StartScreenEffect("MenuMGSelectionTint", 2000, false)
        if Config.UI.sounds then
            PlaySoundFrontend(-1, "PURCHASE", "HUD_LIQUOR_STORE_SOUNDSET", false)
        end
    end
end

-- 📊 Show XP gain animation
function UIManager.showXPGain(amount, reason)
    SendNUIMessage({
        type = 'showXPGain',
        data = {
            amount = amount,
            reason = reason,
            animation = UIState.animations
        }
    })
    
    -- Subtle screen effect for XP gain
    SetTimecycleModifier("hud_def_blur")
    SetTimecycleModifierStrength(0.3)
    
    CreateThread(function()
        Citizen.Wait(1000)
        ClearTimecycleModifier()
    end)
end

-- 🆙 Show level up animation
function UIManager.showLevelUp(newLevel, oldLevel)
    SendNUIMessage({
        type = 'showLevelUp',
        data = {
            newLevel = newLevel,
            oldLevel = oldLevel,
            animation = UIState.animations,
            duration = 5000
        }
    })
    
    -- Major screen effects for level up
    StartScreenEffect("HeistCelebPass", 5000, false)
    
    if Config.UI.sounds then
        PlaySoundFrontend(-1, "RANK_UP", "HUD_AWARDS", false)
    end
    
    -- Camera shake effect
    ShakeGameplayCam("SMALL_EXPLOSION_SHAKE", 0.3)
end

-- 🎁 Show loot box opening
function UIManager.showLootBoxOpening(boxType, reward)
    SendNUIMessage({
        type = 'showLootBoxOpening',
        data = {
            boxType = boxType,
            reward = reward,
            animation = UIState.animations,
            duration = 4000
        }
    })
    
    -- Loot box opening effects
    if Config.UI.sounds then
        PlaySoundFrontend(-1, "LOSER", "HUD_AWARDS", false)
        
        CreateThread(function()
            Citizen.Wait(2000)
            PlaySoundFrontend(-1, "PURCHASE", "HUD_LIQUOR_STORE_SOUNDSET", false)
        end)
    end
    
    -- Screen effects during opening
    SetTimecycleModifier("hud_def_blur")
    SetTimecycleModifierStrength(0.5)
    
    CreateThread(function()
        Citizen.Wait(4000)
        ClearTimecycleModifier()
    end)
end

-- 📱 Show notification
function UIManager.showNotification(message, type, duration)
    duration = duration or 5000
    type = type or 'info'
    
    SendNUIMessage({
        type = 'showNotification',
        data = {
            message = message,
            type = type,
            duration = duration,
            animation = UIState.animations
        }
    })
    
    -- Play notification sound
    if Config.UI.sounds then
        if type == 'success' then
            PlaySoundFrontend(-1, "PURCHASE", "HUD_LIQUOR_STORE_SOUNDSET", false)
        elseif type == 'error' then
            PlaySoundFrontend(-1, "ERROR", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
        elseif type == 'warning' then
            PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
        else
            PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
        end
    end
end

-- 🎨 Update theme
function UIManager.setTheme(themeName)
    local theme = ThemeManager.themes[themeName]
    if not theme then return false end
    
    ThemeManager.currentTheme = themeName
    
    SendNUIMessage({
        type = 'updateTheme',
        data = {theme = theme}
    })
    
    return true
end

-- 🔧 Toggle animations
function UIManager.toggleAnimations()
    UIState.animations = not UIState.animations
    
    SendNUIMessage({
        type = 'toggleAnimations',
        data = {enabled = UIState.animations}
    })
    
    UIManager.showNotification(
        'Animations ' .. (UIState.animations and 'enabled' or 'disabled'),
        'info'
    )
end

-- 🐛 Toggle debug mode
function UIManager.toggleDebugMode()
    UIState.debugMode = not UIState.debugMode
    
    SendNUIMessage({
        type = 'toggleDebugMode',
        data = {enabled = UIState.debugMode}
    })
    
    if UIState.debugMode then
        UIManager.showNotification('Debug mode enabled', 'info')
    else
        UIManager.showNotification('Debug mode disabled', 'info')
    end
end

-- 📊 Show loading screen
function UIManager.showLoading(message, duration)
    UIState.isLoading = true
    
    SendNUIMessage({
        type = 'showLoading',
        data = {
            message = message or 'Loading...',
            duration = duration or 2000
        }
    })
    
    if duration then
        CreateThread(function()
            Citizen.Wait(duration)
            UIManager.hideLoading()
        end)
    end
end

-- 🚫 Hide loading screen
function UIManager.hideLoading()
    UIState.isLoading = false
    
    SendNUIMessage({
        type = 'hideLoading',
        data = {}
    })
end

-- 🎯 Update progress bars
function UIManager.updateProgress(progressData)
    SendNUIMessage({
        type = 'updateProgress',
        data = progressData
    })
end

-- 📈 Show statistics
function UIManager.showStatistics(stats)
    SendNUIMessage({
        type = 'showStatistics',
        data = {
            stats = stats,
            animation = UIState.animations
        }
    })
end

-- 🏆 Show achievement
function UIManager.showAchievement(achievement)
    SendNUIMessage({
        type = 'showAchievement',
        data = {
            achievement = achievement,
            duration = 5000,
            animation = UIState.animations
        }
    })
    
    -- Achievement effects
    if Config.UI.sounds then
        PlaySoundFrontend(-1, "CHALLENGE_UNLOCKED", "HUD_AWARDS", false)
    end
    
    StartScreenEffect("MenuMGSelectionTint", 3000, false)
end

-- 📱 NUI Callback Handlers
RegisterNUICallback('closeUI', function(data, cb)
    UIManager.closeBattlepass()
    cb('ok')
end)

RegisterNUICallback('switchTab', function(data, cb)
    UIManager.switchTab(data.tab)
    cb('ok')
end)

RegisterNUICallback('playSound', function(data, cb)
    if Config.UI.sounds then
        PlaySoundFrontend(-1, data.sound or "SELECT", data.set or "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
    end
    cb('ok')
end)

RegisterNUICallback('requestData', function(data, cb)
    local responseData = {}
    
    if data.type == 'playerData' then
        responseData = BattlepassData or {}
    elseif data.type == 'missions' then
        responseData = ActiveMissions or {}
    elseif data.type == 'config' then
        responseData = Config
    end
    
    cb(responseData)
end)

RegisterNUICallback('performAction', function(data, cb)
    local action = data.action
    local params = data.params or {}
    
    if action == 'claimDailyReward' then
        TriggerServerEvent('battlepass:claimDailyReward', SecurityToken)
    elseif action == 'claimLevelReward' then
        TriggerServerEvent('battlepass:claimLevelReward', params.level, params.passType, SecurityToken)
    elseif action == 'buyPremium' then
        TriggerServerEvent('battlepass:buyPremium', SecurityToken)
    elseif action == 'buyLevel' then
        TriggerServerEvent('battlepass:buyLevel', SecurityToken)
    elseif action == 'claimMissionReward' then
        TriggerServerEvent('battlepass:claimMissionReward', params.missionId, SecurityToken)
    elseif action == 'openLootBox' then
        TriggerServerEvent('battlepass:openLootBox', params.boxType, SecurityToken)
    end
    
    cb('ok')
end)

RegisterNUICallback('updateSettings', function(data, cb)
    if data.animations ~= nil then
        UIState.animations = data.animations
    end
    
    if data.theme then
        UIManager.setTheme(data.theme)
    end
    
    cb('ok')
end)

-- 🎮 Key bindings
RegisterKeyMapping('battlepass', _U('command_battlepass'), 'keyboard', Config.UI.keybind)

RegisterCommand('battlepass', function()
    UIManager.toggleBattlepass()
end)

-- Debug commands (only in debug mode)
if Config.Debug then
    RegisterCommand('bp_debug_ui', function()
        UIManager.toggleDebugMode()
    end)
    
    RegisterCommand('bp_test_notification', function(source, args)
        local message = table.concat(args, ' ') or 'Test notification'
        UIManager.showNotification(message, 'info')
    end)
    
    RegisterCommand('bp_test_xp', function()
        UIManager.showXPGain(100, 'Debug Test')
    end)
    
    RegisterCommand('bp_test_levelup', function()
        UIManager.showLevelUp(5, 4)
    end)
end

-- 📱 Export UI functions for other resources
exports('openBattlepass', function()
    UIManager.openBattlepass()
end)

exports('closeBattlepass', function()
    UIManager.closeBattlepass()
end)

exports('showNotification', function(message, type, duration)
    UIManager.showNotification(message, type, duration)
end)

exports('showXPGain', function(amount, reason)
    UIManager.showXPGain(amount, reason)
end)

exports('showLevelUp', function(newLevel, oldLevel)
    UIManager.showLevelUp(newLevel, oldLevel)
end)

exports('isUIOpen', function()
    return UIState.isOpen
end)

-- 🔄 Handle UI updates from server
RegisterNetEvent('battlepass:updateUI')
AddEventHandler('battlepass:updateUI', function(updateData)
    if updateData.type == 'playerData' then
        SendNUIMessage({
            type = 'updatePlayerData',
            data = updateData.data
        })
    elseif updateData.type == 'missions' then
        SendNUIMessage({
            type = 'updateMissions',
            data = updateData.data
        })
    elseif updateData.type == 'theme' then
        UIManager.setTheme(updateData.data.theme)
    end
end)

-- Override default ShowNotification function
function ShowNotification(message, type)
    UIManager.showNotification(message, type)
end

print("^2[JR.DEV Battlepass]^7 UI system loaded successfully")