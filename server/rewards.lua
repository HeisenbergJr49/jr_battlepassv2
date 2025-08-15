-- Rewards system for battlepass
-- Handles daily rewards, loot boxes, and special rewards

local dailyRewardCache = {}

-- Daily reward system
RegisterNetEvent('jr_battlepass:requestDailyReward')
AddEventHandler('jr_battlepass:requestDailyReward', function()
    local playerId = source
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return end
    
    local data = playerData[playerId]
    if not data then return end
    
    local dailyData = GetDailyRewardData(data)
    
    TriggerClientEvent('jr_battlepass:sendDailyReward', playerId, 
        dailyData.day, 
        dailyData.reward, 
        dailyData.canClaim, 
        dailyData.timeLeft
    )
end)

-- Get daily reward data
function GetDailyRewardData(data)
    local currentTime = os.time()
    local lastClaim = data.last_daily_claim
    local streak = data.daily_streak or 0
    
    local canClaim = false
    local timeLeft = 0
    local currentDay = 1
    
    if lastClaim then
        -- Convert MySQL timestamp to Unix timestamp if needed
        if type(lastClaim) == 'string' then
            local year, month, day, hour, min, sec = lastClaim:match("(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)")
            if year then
                lastClaim = os.time({year=year, month=month, day=day, hour=hour, min=min, sec=sec})
            else
                lastClaim = 0
            end
        end
        
        local timeDiff = currentTime - lastClaim
        local daysSinceLastClaim = math.floor(timeDiff / 86400) -- 86400 seconds in a day
        
        if daysSinceLastClaim >= 1 then
            canClaim = true
            if daysSinceLastClaim == 1 then
                -- Continue streak
                currentDay = (streak % 7) + 1
            else
                -- Reset streak
                streak = 0
                currentDay = 1
            end
        else
            -- Already claimed today
            canClaim = false
            timeLeft = 86400 - (timeDiff % 86400)
            currentDay = (streak % 7) + 1
        end
    else
        -- First time claiming
        canClaim = true
        currentDay = 1
    end
    
    local reward = Config.DailyRewards[currentDay] or Config.DailyRewards[1]
    
    return {
        day = currentDay,
        reward = reward,
        canClaim = canClaim,
        timeLeft = timeLeft,
        streak = streak
    }
end

-- Claim daily reward
RegisterNetEvent('jr_battlepass:claimDailyReward')
AddEventHandler('jr_battlepass:claimDailyReward', function()
    local playerId = source
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return end
    
    if IsRateLimited(playerId) then
        TriggerClientEvent('jr_battlepass:rewardClaimed', playerId, false, 'Please wait before claiming another reward')
        return
    end
    
    local data = playerData[playerId]
    if not data then return end
    
    local dailyData = GetDailyRewardData(data)
    
    if not dailyData.canClaim then
        TriggerClientEvent('jr_battlepass:rewardClaimed', playerId, false, 'Daily reward not available yet')
        return
    end
    
    local reward = dailyData.reward
    local multiplier = (data.premium and Config.PremiumBenefits.dailyBonusMultiplier) or 1
    
    -- Apply premium multiplier to rewards
    if multiplier > 1 then
        if reward.amount then
            reward = table.copy(reward)
            reward.amount = math.floor(reward.amount * multiplier)
        end
    end
    
    local success, message = GiveReward(playerId, reward, 'daily')
    
    if success then
        -- Update streak and last claim time
        data.daily_streak = dailyData.streak + 1
        data.last_daily_claim = os.date('%Y-%m-%d %H:%M:%S')
        
        -- Special handling for day 7 (reset streak)
        if dailyData.day == 7 then
            data.daily_streak = 0
            TriggerClientEvent('jr_battlepass:specialReward', playerId, 'mega', {
                money = reward.money or 15000,
                item_label = reward.label
            })
        end
        
        SavePlayerBattlepassData(playerId)
        
        local finalMessage = ('Daily Reward Claimed! Day %s/7'):format(dailyData.day)
        if multiplier > 1 then
            finalMessage = finalMessage .. ' (Premium Bonus Applied!)'
        end
        
        TriggerClientEvent('jr_battlepass:rewardClaimed', playerId, true, finalMessage)
    else
        TriggerClientEvent('jr_battlepass:rewardClaimed', playerId, false, message)
    end
end)

-- Loot box system
RegisterNetEvent('jr_battlepass:openLootbox')
AddEventHandler('jr_battlepass:openLootbox', function(boxType)
    local playerId = source
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return end
    
    if IsRateLimited(playerId) then
        TriggerClientEvent('jr_battlepass:rewardClaimed', playerId, false, 'Please wait before opening another loot box')
        return
    end
    
    if not Config.LootBoxes[boxType] then
        TriggerClientEvent('jr_battlepass:rewardClaimed', playerId, false, 'Invalid loot box type')
        return
    end
    
    local rewards = OpenLootBox(playerId, boxType)
    if rewards then
        TriggerClientEvent('jr_battlepass:lootboxOpened', playerId, rewards)
        LogReward(playerId, 'lootbox', {boxType = boxType, rewards = rewards})
    else
        TriggerClientEvent('jr_battlepass:rewardClaimed', playerId, false, 'Failed to open loot box')
    end
end)

-- Open loot box and return rewards
function OpenLootBox(playerId, boxType)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return nil end
    
    local lootBox = Config.LootBoxes[boxType]
    if not lootBox then return nil end
    
    local rewards = {}
    local totalChance = 0
    
    -- Calculate total chance
    for _, item in pairs(lootBox.items) do
        totalChance = totalChance + item.chance
    end
    
    -- Roll for reward
    local roll = math.random(1, totalChance)
    local currentChance = 0
    
    for _, item in pairs(lootBox.items) do
        currentChance = currentChance + item.chance
        if roll <= currentChance then
            -- This item was selected
            local success = false
            local rewardLabel = ''
            
            if item.item == 'money' then
                xPlayer.addMoney(item.amount)
                success = true
                rewardLabel = ('€%s Cash'):format(item.amount)
            elseif item.item == 'bank' then
                xPlayer.addAccountMoney('bank', item.amount)
                success = true
                rewardLabel = ('€%s Bank'):format(item.amount)
            else
                if xPlayer.canCarryItem(item.item, item.amount) then
                    xPlayer.addInventoryItem(item.item, item.amount)
                    success = true
                    rewardLabel = ('%sx %s'):format(item.amount, item.item)
                else
                    -- Give money instead if inventory is full
                    xPlayer.addMoney(1000)
                    success = true
                    rewardLabel = '€1,000 (Inventory Full)'
                end
            end
            
            if success then
                table.insert(rewards, {
                    item = item.item,
                    amount = item.amount,
                    label = rewardLabel,
                    rarity = GetItemRarity(boxType, item.chance)
                })
            end
            
            break
        end
    end
    
    return #rewards > 0 and rewards or nil
end

-- Get item rarity based on loot box type and chance
function GetItemRarity(boxType, chance)
    if boxType == 'legendary' then
        if chance <= 10 then return 'legendary'
        elseif chance <= 20 then return 'epic'
        else return 'rare'
        end
    elseif boxType == 'premium' then
        if chance <= 10 then return 'epic'
        elseif chance <= 20 then return 'rare'
        else return 'common'
        end
    else
        if chance <= 10 then return 'rare'
        elseif chance <= 20 then return 'uncommon'
        else return 'common'
        end
    end
end

-- Premium battlepass purchase
RegisterNetEvent('jr_battlepass:buyPremium')
AddEventHandler('jr_battlepass:buyPremium', function()
    local playerId = source
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return end
    
    if IsRateLimited(playerId) then
        TriggerClientEvent('jr_battlepass:premiumPurchased', playerId, false)
        return
    end
    
    local data = playerData[playerId]
    if not data then return end
    
    if data.premium then
        TriggerClientEvent('jr_battlepass:rewardClaimed', playerId, false, 'You already have premium!')
        return
    end
    
    local bankAccount = xPlayer.getAccount('bank')
    if bankAccount.money < Config.PremiumPrice then
        TriggerClientEvent('jr_battlepass:rewardClaimed', playerId, false, 'Not enough money in bank!')
        return
    end
    
    -- Deduct money and activate premium
    xPlayer.removeAccountMoney('bank', Config.PremiumPrice)
    data.premium = true
    data.premium_expires = os.date('%Y-%m-%d %H:%M:%S', os.time() + (30 * 24 * 60 * 60)) -- 30 days
    
    SavePlayerBattlepassData(playerId)
    
    TriggerClientEvent('jr_battlepass:premiumPurchased', playerId, true)
    
    -- Log the purchase
    LogReward(playerId, 'premium_purchase', {
        price = Config.PremiumPrice,
        expires = data.premium_expires
    })
    
    -- Give immediate premium bonuses
    GivePremiumWelcomeBonus(playerId)
end)

-- Give premium welcome bonus
function GivePremiumWelcomeBonus(playerId)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return end
    
    -- Welcome bonus: 1000 XP and some premium currency
    GivePlayerXP(playerId, 1000, 'Premium Welcome Bonus')
    xPlayer.addMoney(5000)
    
    TriggerClientEvent('jr_battlepass:rewardClaimed', playerId, true, 'Premium Welcome Bonus: +1000 XP + €5,000!')
end

-- Check and handle expired premium subscriptions
CreateThread(function()
    while true do
        Wait(3600000) -- Check every hour
        
        local currentTime = os.time()
        
        for playerId, data in pairs(playerData) do
            if data.premium and data.premium_expires then
                local expiresTime = data.premium_expires
                
                -- Convert MySQL timestamp to Unix timestamp if needed
                if type(expiresTime) == 'string' then
                    local year, month, day, hour, min, sec = expiresTime:match("(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)")
                    if year then
                        expiresTime = os.time({year=year, month=month, day=day, hour=hour, min=min, sec=sec})
                    else
                        expiresTime = 0
                    end
                end
                
                if currentTime > expiresTime then
                    data.premium = false
                    data.premium_expires = nil
                    SavePlayerBattlepassData(playerId)
                    
                    local xPlayer = ESX.GetPlayerFromId(playerId)
                    if xPlayer then
                        TriggerClientEvent('jr_battlepass:rewardClaimed', playerId, false, 'Your Premium Battlepass has expired!')
                    end
                end
            end
        end
    end
end)

-- Utility function to copy tables
function table.copy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[table.copy(orig_key)] = table.copy(orig_value)
        end
        setmetatable(copy, table.copy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

-- Export functions
exports('openLootBox', OpenLootBox)
exports('getDailyRewardData', GetDailyRewardData)
exports('givePremiumWelcomeBonus', GivePremiumWelcomeBonus)