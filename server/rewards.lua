-- 🎁 Rewards system for JR.DEV Battlepass
local ESX = exports["es_extended"]:getSharedObject()
local Rewards = {}

-- 💰 Give money reward
function Rewards.giveMoney(source, amount)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return false end
    
    xPlayer.addMoney(amount)
    return true
end

-- 🏦 Give bank money reward
function Rewards.giveBank(source, amount)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return false end
    
    xPlayer.addAccountMoney('bank', amount)
    return true
end

-- 📦 Give item reward
function Rewards.giveItem(source, itemName, count)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return false end
    
    -- Try ox_inventory first
    if exports.ox_inventory then
        local success = exports.ox_inventory:AddItem(source, itemName, count)
        return success
    else
        -- Fallback to ESX inventory
        xPlayer.addInventoryItem(itemName, count)
        return true
    end
end

-- 🔫 Give weapon reward
function Rewards.giveWeapon(source, weaponName, ammo)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return false end
    
    ammo = ammo or 0
    
    -- Check if player already has weapon
    if xPlayer.hasWeapon(weaponName) then
        -- Just add ammo
        xPlayer.addWeaponAmmo(weaponName, ammo)
    else
        -- Add weapon with ammo
        xPlayer.addWeapon(weaponName, ammo)
    end
    
    return true
end

-- 🚗 Give vehicle reward
function Rewards.giveVehicle(source, vehicleModel)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return false end
    
    -- This is a placeholder - implement according to your vehicle system
    -- Example for popular vehicle systems:
    
    if exports.esx_vehicleshop then
        -- ESX Vehicle Shop integration
        MySQL.Async.execute('INSERT INTO owned_vehicles (owner, plate, vehicle) VALUES (@owner, @plate, @vehicle)', {
            ['@owner'] = xPlayer.identifier,
            ['@plate'] = GenerateRandomPlate(),
            ['@vehicle'] = json.encode({
                model = GetHashKey(vehicleModel),
                plate = GenerateRandomPlate()
            })
        })
        return true
    elseif exports.qb_vehicleshop then
        -- QB Vehicle Shop integration
        -- Implement QB-Core vehicle giving logic here
        return true
    else
        -- Basic implementation - spawn vehicle near player
        local playerPed = GetPlayerPed(source)
        local coords = GetEntityCoords(playerPed)
        
        TriggerClientEvent('battlepass:spawnVehicle', source, vehicleModel, coords)
        return true
    end
end

-- 🪙 Give coins reward
function Rewards.giveCoins(source, amount)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return false end
    
    local Database = exports.jr_battlepassv2:getDatabase()
    return Database.updateCoins(xPlayer.identifier, amount)
end

-- 📦 Open loot box
function Rewards.openLootBox(source, boxType)
    local lootTable = Config.LootBoxes[boxType]
    if not lootTable then return false end
    
    -- Calculate total chance
    local totalChance = 0
    for _, item in pairs(lootTable) do
        totalChance = totalChance + item.chance
    end
    
    -- Generate random number
    local roll = math.random(1, totalChance)
    local currentChance = 0
    
    -- Find the reward
    for _, reward in pairs(lootTable) do
        currentChance = currentChance + reward.chance
        if roll <= currentChance then
            -- Give the reward
            local success = Rewards.giveReward(source, reward.type, reward)
            if success then
                TriggerClientEvent('battlepass:lootBoxReward', source, {
                    boxType = boxType,
                    reward = reward
                })
            end
            return success
        end
    end
    
    return false
end

-- 🎲 Get random weapon attachment
function Rewards.getRandomAttachment()
    local attachments = {
        'COMPONENT_AT_AR_FLSH',
        'COMPONENT_AT_AR_SUPP_02',
        'COMPONENT_AT_AR_AFGRIP',
        'COMPONENT_AT_SCOPE_MACRO',
        'COMPONENT_AT_SCOPE_SMALL',
        'COMPONENT_PISTOL_CLIP_02',
        'COMPONENT_AT_PI_FLSH',
        'COMPONENT_AT_PI_SUPP_02'
    }
    
    return attachments[math.random(#attachments)]
end

-- 🎯 Main reward giving function
function Rewards.giveReward(source, rewardType, rewardData)
    local success = false
    local label = ""
    
    if rewardType == 'money' then
        success = Rewards.giveMoney(source, rewardData.amount)
        label = _U('reward_money', rewardData.amount)
        
    elseif rewardType == 'bank' then
        success = Rewards.giveBank(source, rewardData.amount)
        label = _U('reward_bank', rewardData.amount)
        
    elseif rewardType == 'item' then
        success = Rewards.giveItem(source, rewardData.item, rewardData.count)
        label = _U('reward_item', rewardData.count, rewardData.item)
        
    elseif rewardType == 'weapon' then
        success = Rewards.giveWeapon(source, rewardData.weapon, rewardData.ammo)
        label = _U('reward_weapon', rewardData.weapon, rewardData.ammo or 0)
        
    elseif rewardType == 'vehicle' then
        success = Rewards.giveVehicle(source, rewardData.vehicle)
        label = _U('reward_vehicle', rewardData.vehicle)
        
    elseif rewardType == 'coins' then
        success = Rewards.giveCoins(source, rewardData.amount)
        label = _U('reward_coins', rewardData.amount)
        
    elseif rewardType == 'lootbox' then
        success = Rewards.openLootBox(source, rewardData.box)
        label = _U('reward_lootbox', rewardData.box)
        
    elseif rewardType == 'random_attachment' then
        local attachment = Rewards.getRandomAttachment()
        -- For now, give it as an item - you might want to integrate with weapon attachment system
        success = Rewards.giveItem(source, 'weapon_attachment', 1)
        label = "Random Weapon Attachment"
        
    elseif rewardType == 'mega_bonus' then
        success = true
        for _, reward in pairs(rewardData.rewards) do
            if not Rewards.giveReward(source, reward.type, reward) then
                success = false
                break
            end
        end
        label = rewardData.label or "Mega Bonus"
    end
    
    if success and label ~= "" then
        TriggerClientEvent('battlepass:showNotification', source, 
            _U('reward_received', label), 'success')
    end
    
    return success
end

-- 🛠️ Utility Functions
function GenerateRandomPlate()
    local pattern = "XXXXXX"
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local plate = ""
    
    for i = 1, string.len(pattern) do
        if string.sub(pattern, i, i) == "X" then
            plate = plate .. string.sub(chars, math.random(1, string.len(chars)), math.random(1, string.len(chars)))
        else
            plate = plate .. string.sub(pattern, i, i)
        end
    end
    
    return plate
end

-- 📊 Reward Statistics
function Rewards.getRewardStats()
    local stats = {
        totalRewardsGiven = 0,
        moneyGiven = 0,
        itemsGiven = 0,
        weaponsGiven = 0,
        vehiclesGiven = 0,
        coinsGiven = 0,
        lootBoxesOpened = 0
    }
    
    -- You could implement database queries here to get actual stats
    return stats
end

-- 🎁 Special Rewards (Premium features)
function Rewards.givePremiumBonus(source, baseReward)
    -- Premium players get additional rewards
    local bonusReward = {
        type = 'coins',
        amount = math.floor(baseReward.amount * 0.1) -- 10% bonus coins
    }
    
    return Rewards.giveReward(source, bonusReward.type, bonusReward)
end

-- 🔄 Daily Bonus Coins
function Rewards.giveDailyBonusCoins(source)
    return Rewards.giveCoins(source, Config.Currency.dailyBonusCoins)
end

-- 🏆 Achievement Rewards
function Rewards.giveAchievementReward(source, achievementId)
    local achievementRewards = {
        first_level_up = {type = 'coins', amount = 50},
        reach_level_10 = {type = 'lootbox', box = 'basic'},
        reach_level_25 = {type = 'lootbox', box = 'premium'},
        reach_level_50 = {type = 'vehicle', vehicle = 'sultan'},
        first_premium = {type = 'coins', amount = 100},
        complete_daily_mission = {type = 'coins', amount = 25},
        complete_weekly_mission = {type = 'coins', amount = 75},
        streak_7_days = {type = 'lootbox', box = 'premium'},
        streak_30_days = {type = 'vehicle', vehicle = 'elegy2'}
    }
    
    local reward = achievementRewards[achievementId]
    if reward then
        return Rewards.giveReward(source, reward.type, reward)
    end
    
    return false
end

-- Export the Rewards module
exports('getRewards', function()
    return Rewards
end)

print("^2[JR.DEV Battlepass]^7 Rewards system loaded successfully")

return Rewards