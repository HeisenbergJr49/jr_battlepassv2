Config = {}

-- 🎯 Battlepass Configuration
Config.Battlepass = {
    maxLevel = 100,                    -- Maximum battlepass level
    xpPerLevel = 1000,                 -- XP required per level (increases by 10% each level)
    seasonDurationDays = 90,           -- Season length in days
    premiumCost = 1500,                -- Cost of premium pass in coins
    levelBuyCost = 50,                 -- Cost to buy one level in coins
    premiumXpMultiplier = 2.0,         -- XP multiplier for premium players
    currentSeason = 1                  -- Current season ID
}

-- 🎁 Daily Rewards Configuration (7-day cycle)
Config.DailyRewards = {
    [1] = {
        type = 'money',
        amount = 2000,
        label = '2.000€ Bargeld'
    },
    [2] = {
        type = 'item',
        item = 'firstaid',
        count = 5,
        label = '5x Erste-Hilfe-Kit'
    },
    [3] = {
        type = 'multi',
        rewards = {
            {type = 'item', item = 'fishing_bait', count = 3},
            {type = 'money', amount = 1000}
        },
        label = '3x Angel-Köder + 1.000€'
    },
    [4] = {
        type = 'random_attachment',
        label = 'Zufälliger Waffenaufsatz'
    },
    [5] = {
        type = 'bank',
        amount = 5000,
        label = '5.000€ Bankguthaben'
    },
    [6] = {
        type = 'lootbox',
        box = 'premium',
        label = 'Premium Loot-Box'
    },
    [7] = {
        type = 'mega_bonus',
        rewards = {
            {type = 'bank', amount = 15000},
            {type = 'item', item = 'gold_bar', count = 1}
        },
        label = 'MEGA-Bonus (15.000€ + seltenes Item)'
    }
}

-- 📋 Daily Missions Configuration
Config.DailyMissions = {
    {
        id = 'playtime_60',
        label = 'Spiele 60 Minuten',
        description = 'Verbringe 60 Minuten auf dem Server',
        target = 60,
        xpReward = 500,
        type = 'time'
    },
    {
        id = 'catch_fish_10',
        label = 'Fange 10 Fische',
        description = 'Fange 10 Fische beim Angeln',
        target = 10,
        xpReward = 300,
        extraReward = {type = 'item', item = 'fish', count = 2},
        type = 'fishing'
    },
    {
        id = 'drive_25km',
        label = 'Fahre 25km',
        description = 'Fahre insgesamt 25km mit Fahrzeugen',
        target = 25000,
        xpReward = 400,
        type = 'distance'
    },
    {
        id = 'earn_10000',
        label = 'Verdiene 10.000€',
        description = 'Verdiene 10.000€ durch Jobs oder Handel',
        target = 10000,
        xpReward = 600,
        type = 'money'
    }
}

-- 📅 Weekly Missions Configuration
Config.WeeklyMissions = {
    {
        id = 'win_races_5',
        label = 'Gewinne 5 Rennen',
        description = 'Gewinne 5 Rennen in verschiedenen Kategorien',
        target = 5,
        xpReward = 2000,
        type = 'racing'
    },
    {
        id = 'complete_jobs_15',
        label = 'Schließe 15 Jobs ab',
        description = 'Schließe 15 verschiedene Jobs erfolgreich ab',
        target = 15,
        xpReward = 2500,
        type = 'jobs'
    },
    {
        id = 'farm_drugs_50',
        label = 'Farme 50 Drogen',
        description = 'Sammle oder produziere 50 Drogen-Items',
        target = 50,
        xpReward = 1800,
        type = 'drugs'
    },
    {
        id = 'kill_npcs_25',
        label = 'Töte 25 NPCs',
        description = 'Eliminiere 25 NPCs in verschiedenen Aktivitäten',
        target = 25,
        xpReward = 1500,
        type = 'combat'
    }
}

-- 🎁 Loot Box Configuration
Config.LootBoxes = {
    basic = {
        {type = 'item', item = 'bread', count = 5, chance = 30, label = '5x Brot'},
        {type = 'item', item = 'water', count = 3, chance = 25, label = '3x Wasser'},
        {type = 'money', amount = 1000, chance = 20, label = '1.000€'},
        {type = 'item', item = 'bandage', count = 2, chance = 15, label = '2x Verband'},
        {type = 'item', item = 'phone', count = 1, chance = 10, label = '1x Handy'}
    },
    premium = {
        {type = 'money', amount = 5000, chance = 25, label = '5.000€'},
        {type = 'weapon', weapon = 'weapon_pistol', ammo = 50, chance = 15, label = 'Pistole + 50 Schuss'},
        {type = 'item', item = 'gold_bar', count = 1, chance = 20, label = '1x Goldbarren'},
        {type = 'vehicle', vehicle = 'sultan', chance = 5, label = 'Sultan (Fahrzeug)'},
        {type = 'coins', amount = 100, chance = 35, label = '100 Battlepass Coins'}
    }
}

-- 🏆 Level Rewards Configuration
Config.LevelRewards = {
    -- Free Pass Rewards
    free = {
        [5] = {type = 'money', amount = 1000},
        [10] = {type = 'item', item = 'bandage', count = 10},
        [15] = {type = 'coins', amount = 50},
        [20] = {type = 'lootbox', box = 'basic'},
        [25] = {type = 'money', amount = 2500},
        [30] = {type = 'item', item = 'lockpick', count = 5},
        [35] = {type = 'coins', amount = 75},
        [40] = {type = 'item', item = 'phone', count = 1},
        [45] = {type = 'money', amount = 5000},
        [50] = {type = 'lootbox', box = 'premium'},
        -- Continue pattern to level 100
    },
    -- Premium Pass Rewards
    premium = {
        [3] = {type = 'coins', amount = 25},
        [7] = {type = 'item', item = 'firstaid', count = 3},
        [12] = {type = 'weapon', weapon = 'weapon_knife', label = 'Kampfmesser'},
        [17] = {type = 'money', amount = 3000},
        [22] = {type = 'vehicle', vehicle = 'blista', label = 'Blista Compact'},
        [27] = {type = 'item', item = 'gold_bar', count = 1},
        [32] = {type = 'coins', amount = 150},
        [37] = {type = 'lootbox', box = 'premium'},
        [42] = {type = 'money', amount = 7500},
        [47] = {type = 'weapon', weapon = 'weapon_pistol', ammo = 100},
        -- Continue pattern to level 100
    }
}

-- 🔒 Security Configuration
Config.Security = {
    maxRequestsPerMinute = 10,         -- Rate limiting
    requireSessionToken = true,        -- Session token validation
    enableAntiCheat = true,           -- XP manipulation detection
    logSuspiciousActivity = true      -- Log potential cheating attempts
}

-- 🎨 UI Configuration
Config.UI = {
    theme = 'dark_gold',              -- UI theme
    animations = true,                -- Enable smooth animations
    sounds = true,                    -- Enable UI sounds
    keybind = 'F6',                   -- Default keybind to open battlepass
    autoClose = false                 -- Auto-close UI after inactivity
}

-- 💰 Currency Configuration
Config.Currency = {
    coinName = 'BP Coins',            -- Name of battlepass currency
    startingCoins = 100,              -- Starting coins for new players
    dailyBonusCoins = 25              -- Bonus coins for daily login
}

-- 🛡️ Admin Configuration
Config.Admin = {
    acePermission = 'battlepass.admin', -- Required ACE permission
    commands = {
        give_xp = 'bp_give',            -- Command to give XP
        set_level = 'bp_level',         -- Command to set level
        give_coins = 'bp_coins',        -- Command to give coins
        reset_player = 'bp_reset'       -- Command to reset player data
    }
}