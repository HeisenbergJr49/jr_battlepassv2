Config = {}

-- General Settings
Config.Locale = 'en'
Config.Debug = false
Config.UseOxInventory = true
Config.Currency = 'bank' -- 'money' or 'bank'

-- Battlepass Settings
Config.MaxLevel = 100
Config.SeasonId = 1
Config.SeasonName = "Season 1: Urban Legends"

-- XP Requirements per level (1-100)
Config.XPPerLevel = {}
for i = 1, 100 do
    if i <= 10 then
        Config.XPPerLevel[i] = i * 500  -- 500, 1000, 1500, etc.
    elseif i <= 25 then
        Config.XPPerLevel[i] = i * 750  -- 750 per level
    elseif i <= 50 then
        Config.XPPerLevel[i] = i * 1000 -- 1000 per level
    elseif i <= 75 then
        Config.XPPerLevel[i] = i * 1250 -- 1250 per level
    else
        Config.XPPerLevel[i] = i * 1500 -- 1500 per level
    end
end

-- Premium Battlepass
Config.PremiumPrice = 25000 -- Cost in bank money
Config.PremiumBenefits = {
    xpMultiplier = 1.5,
    exclusiveRewards = true,
    dailyBonusMultiplier = 2.0
}

-- Daily Rewards (7-day cycle)
Config.DailyRewards = {
    [1] = { type = 'money', amount = 2000, label = '€2,000 Cash' },
    [2] = { type = 'item', item = 'medikit', amount = 5, label = '5x First Aid Kit' },
    [3] = { type = 'mixed', items = {{item = 'fishing_bait', amount = 3}}, money = 1000, label = '3x Fishing Bait + €1,000' },
    [4] = { type = 'item', item = 'weapon_attachment', amount = 1, label = 'Random Weapon Attachment' },
    [5] = { type = 'bank', amount = 5000, label = '€5,000 Bank Money' },
    [6] = { type = 'lootbox', box = 'premium', label = 'Premium Loot Box' },
    [7] = { type = 'mega', money = 15000, item = 'rare_car_key', label = 'MEGA Bonus: €15,000 + Rare Item' }
}

-- Daily Missions
Config.DailyMissions = {
    {
        id = 'playtime',
        label = 'Play for 60 minutes',
        description = 'Stay online for 60 minutes',
        target = 3600, -- seconds
        reward = { xp = 500 },
        type = 'time'
    },
    {
        id = 'fishing',
        label = 'Catch 10 fish',
        description = 'Go fishing and catch 10 fish',
        target = 10,
        reward = { xp = 300, items = {{item = 'fish', amount = 2}} },
        type = 'activity'
    },
    {
        id = 'driving',
        label = 'Drive 25km',
        description = 'Drive a total of 25 kilometers',
        target = 25000, -- meters
        reward = { xp = 400 },
        type = 'distance'
    },
    {
        id = 'money',
        label = 'Earn €10,000',
        description = 'Earn 10,000 in cash or bank',
        target = 10000,
        reward = { xp = 600 },
        type = 'money'
    }
}

-- Weekly Missions
Config.WeeklyMissions = {
    {
        id = 'races',
        label = 'Win 5 races',
        description = 'Win any type of race 5 times',
        target = 5,
        reward = { xp = 2000, money = 5000 },
        type = 'activity'
    },
    {
        id = 'jobs',
        label = 'Complete 15 jobs',
        description = 'Complete any ESX job 15 times',
        target = 15,
        reward = { xp = 2500, money = 7500 },
        type = 'activity'
    },
    {
        id = 'farming',
        label = 'Farm 50 drugs',
        description = 'Process or farm 50 drug items',
        target = 50,
        reward = { xp = 1800, items = {{item = 'weapon_pistol', amount = 1}} },
        type = 'activity'
    },
    {
        id = 'combat',
        label = 'Kill 25 NPCs',
        description = 'Eliminate 25 NPC enemies',
        target = 25,
        reward = { xp = 1500, money = 3000 },
        type = 'combat'
    }
}

-- Level Rewards (Free Track)
Config.LevelRewards = {
    [5] = { type = 'money', amount = 2500, label = '€2,500' },
    [10] = { type = 'item', item = 'weapon_pistol', amount = 1, label = 'Pistol' },
    [15] = { type = 'money', amount = 5000, label = '€5,000' },
    [20] = { type = 'item', item = 'medikit', amount = 10, label = '10x First Aid Kit' },
    [25] = { type = 'lootbox', box = 'basic', label = 'Basic Loot Box' },
    [30] = { type = 'money', amount = 7500, label = '€7,500' },
    [35] = { type = 'item', item = 'weapon_smg', amount = 1, label = 'SMG' },
    [40] = { type = 'money', amount = 10000, label = '€10,000' },
    [45] = { type = 'lootbox', box = 'premium', label = 'Premium Loot Box' },
    [50] = { type = 'vehicle', model = 'sultanrs', label = 'Sultan RS' }
}

-- Premium Level Rewards
Config.PremiumLevelRewards = {
    [3] = { type = 'money', amount = 5000, label = '€5,000 (Premium)' },
    [7] = { type = 'item', item = 'armor', amount = 5, label = '5x Body Armor' },
    [12] = { type = 'money', amount = 10000, label = '€10,000 (Premium)' },
    [17] = { type = 'item', item = 'weapon_assaultrifle', amount = 1, label = 'Assault Rifle' },
    [22] = { type = 'lootbox', box = 'legendary', label = 'Legendary Loot Box' },
    [27] = { type = 'money', amount = 15000, label = '€15,000 (Premium)' },
    [32] = { type = 'item', item = 'weapon_sniper', amount = 1, label = 'Sniper Rifle' },
    [37] = { type = 'money', amount = 20000, label = '€20,000 (Premium)' },
    [42] = { type = 'lootbox', box = 'legendary', label = 'Legendary Loot Box' },
    [47] = { type = 'vehicle', model = 'zentorno', label = 'Zentorno (Premium)' }
}

-- Loot Box Configuration
Config.LootBoxes = {
    basic = {
        name = 'Basic Loot Box',
        items = {
            { item = 'bread', amount = 5, chance = 30 },
            { item = 'water', amount = 3, chance = 25 },
            { item = 'money', amount = 1000, chance = 20 },
            { item = 'medikit', amount = 2, chance = 15 },
            { item = 'weapon_knife', amount = 1, chance = 10 }
        }
    },
    premium = {
        name = 'Premium Loot Box',
        items = {
            { item = 'weapon_pistol', amount = 1, chance = 25 },
            { item = 'money', amount = 5000, chance = 20 },
            { item = 'armor', amount = 1, chance = 20 },
            { item = 'medikit', amount = 5, chance = 15 },
            { item = 'weapon_smg', amount = 1, chance = 10 },
            { item = 'gold_bar', amount = 1, chance = 10 }
        }
    },
    legendary = {
        name = 'Legendary Loot Box',
        items = {
            { item = 'weapon_assaultrifle', amount = 1, chance = 20 },
            { item = 'money', amount = 25000, chance = 15 },
            { item = 'diamond', amount = 1, chance = 15 },
            { item = 'weapon_sniper', amount = 1, chance = 15 },
            { item = 'rare_car_key', amount = 1, chance = 10 },
            { item = 'gold_bar', amount = 5, chance = 10 },
            { item = 'legendary_item', amount = 1, chance = 15 }
        }
    }
}

-- Key Bindings
Config.Keys = {
    openBattlepass = 'F6'
}

-- Admin Settings
Config.AdminGroups = {
    'admin',
    'superadmin',
    'owner'
}

-- Security Settings
Config.Security = {
    rateLimitSeconds = 2, -- Minimum seconds between actions
    maxXPPerHour = 5000,  -- Anti-cheat XP limit per hour
    validateServerSide = true
}

-- Notification Settings
Config.Notifications = {
    position = 'top-right',
    duration = 5000,
    showXPGain = true,
    showLevelUp = true,
    showMissionComplete = true
}