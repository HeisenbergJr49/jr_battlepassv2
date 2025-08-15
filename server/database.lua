-- 🗄️ Database module for JR.DEV Battlepass System
local Database = {}

-- 🔍 Check database connection
function Database.checkConnection()
    local success = false
    
    MySQL.Async.fetchAll('SELECT 1 as test', {}, function(result)
        if result then
            success = true
        end
    end)
    
    -- Wait for async operation
    while success == false do
        Citizen.Wait(10)
    end
    
    return success
end

-- 👤 Player Data Functions
function Database.getPlayerData(identifier)
    local result = nil
    local completed = false
    
    MySQL.Async.fetchAll('SELECT * FROM battlepass_players WHERE identifier = @identifier', {
        ['@identifier'] = identifier
    }, function(data)
        if data and data[1] then
            result = data[1]
            -- Convert TIMESTAMP to Unix timestamp
            if result.premium_expires then
                result.premium_expires = os.time(os.date("*t", result.premium_expires))
            end
            if result.last_daily_claim then
                result.last_daily_claim = os.time(os.date("*t", result.last_daily_claim))
            end
        end
        completed = true
    end)
    
    while not completed do
        Citizen.Wait(10)
    end
    
    return result
end

function Database.createPlayer(identifier)
    local success = false
    local result = nil
    
    MySQL.Async.execute('INSERT INTO battlepass_players (identifier, level, xp, coins, premium, daily_streak, season_id) VALUES (@identifier, @level, @xp, @coins, @premium, @daily_streak, @season_id)', {
        ['@identifier'] = identifier,
        ['@level'] = 1,
        ['@xp'] = 0,
        ['@coins'] = Config.Currency.startingCoins,
        ['@premium'] = false,
        ['@daily_streak'] = 0,
        ['@season_id'] = Config.Battlepass.currentSeason
    }, function(affectedRows)
        if affectedRows > 0 then
            success = true
            result = {
                identifier = identifier,
                level = 1,
                xp = 0,
                coins = Config.Currency.startingCoins,
                premium = false,
                premium_expires = nil,
                daily_streak = 0,
                last_daily_claim = nil,
                season_id = Config.Battlepass.currentSeason
            }
        end
    end)
    
    while not success and result == nil do
        Citizen.Wait(10)
    end
    
    return result
end

function Database.updatePlayerXP(identifier, level, xp)
    local success = false
    
    MySQL.Async.execute('UPDATE battlepass_players SET level = @level, xp = @xp WHERE identifier = @identifier', {
        ['@identifier'] = identifier,
        ['@level'] = level,
        ['@xp'] = xp
    }, function(affectedRows)
        success = affectedRows > 0
    end)
    
    while success == false do
        Citizen.Wait(10)
    end
    
    return success
end

function Database.updateDailyStreak(identifier, streak, timestamp)
    local success = false
    
    MySQL.Async.execute('UPDATE battlepass_players SET daily_streak = @streak, last_daily_claim = FROM_UNIXTIME(@timestamp) WHERE identifier = @identifier', {
        ['@identifier'] = identifier,
        ['@streak'] = streak,
        ['@timestamp'] = timestamp
    }, function(affectedRows)
        success = affectedRows > 0
    end)
    
    while success == false do
        Citizen.Wait(10)
    end
    
    return success
end

function Database.activatePremium(identifier, expiryTimestamp, cost)
    local success = false
    
    MySQL.Async.execute('UPDATE battlepass_players SET premium = @premium, premium_expires = FROM_UNIXTIME(@expires), coins = coins - @cost WHERE identifier = @identifier AND coins >= @cost', {
        ['@identifier'] = identifier,
        ['@premium'] = true,
        ['@expires'] = expiryTimestamp,
        ['@cost'] = cost
    }, function(affectedRows)
        success = affectedRows > 0
    end)
    
    while success == false do
        Citizen.Wait(10)
    end
    
    return success
end

function Database.updateCoins(identifier, amount)
    local success = false
    
    MySQL.Async.execute('UPDATE battlepass_players SET coins = coins + @amount WHERE identifier = @identifier', {
        ['@identifier'] = identifier,
        ['@amount'] = amount
    }, function(affectedRows)
        success = affectedRows > 0
    end)
    
    while success == false do
        Citizen.Wait(10)
    end
    
    return success
end

-- 🎯 Mission Data Functions
function Database.getActiveMissions(identifier)
    local result = nil
    local completed = false
    
    MySQL.Async.fetchAll('SELECT * FROM battlepass_missions WHERE identifier = @identifier AND expires_at > NOW()', {
        ['@identifier'] = identifier
    }, function(data)
        result = data or {}
        completed = true
    end)
    
    while not completed do
        Citizen.Wait(10)
    end
    
    return result
end

function Database.updateMissionProgress(identifier, missionId, progress, isCompleted)
    local success = false
    
    MySQL.Async.execute('UPDATE battlepass_missions SET progress = @progress, completed = @completed WHERE identifier = @identifier AND mission_id = @mission_id', {
        ['@identifier'] = identifier,
        ['@mission_id'] = missionId,
        ['@progress'] = progress,
        ['@completed'] = isCompleted
    }, function(affectedRows)
        success = affectedRows > 0
    end)
    
    while success == false do
        Citizen.Wait(10)
    end
    
    return success
end

function Database.createMission(identifier, missionId, missionType, expiresAt)
    local success = false
    
    MySQL.Async.execute('INSERT INTO battlepass_missions (identifier, mission_id, mission_type, expires_at) VALUES (@identifier, @mission_id, @mission_type, FROM_UNIXTIME(@expires)) ON DUPLICATE KEY UPDATE expires_at = FROM_UNIXTIME(@expires)', {
        ['@identifier'] = identifier,
        ['@mission_id'] = missionId,
        ['@mission_type'] = missionType,
        ['@expires'] = expiresAt
    }, function(affectedRows)
        success = affectedRows > 0
    end)
    
    while success == false do
        Citizen.Wait(10)
    end
    
    return success
end

function Database.claimMissionReward(identifier, missionId)
    local success = false
    
    MySQL.Async.execute('UPDATE battlepass_missions SET claimed = @claimed WHERE identifier = @identifier AND mission_id = @mission_id AND completed = @completed', {
        ['@identifier'] = identifier,
        ['@mission_id'] = missionId,
        ['@claimed'] = true,
        ['@completed'] = true
    }, function(affectedRows)
        success = affectedRows > 0
    end)
    
    while success == false do
        Citizen.Wait(10)
    end
    
    return success
end

function Database.resetExpiredMissions(missionType)
    local success = false
    
    MySQL.Async.execute('DELETE FROM battlepass_missions WHERE mission_type = @mission_type AND expires_at <= NOW()', {
        ['@mission_type'] = missionType
    }, function(affectedRows)
        success = true
        print(("^2[JR.DEV Battlepass]^7 Deleted %d expired %s missions"):format(affectedRows, missionType))
    end)
    
    while success == false do
        Citizen.Wait(10)
    end
    
    return success
end

-- 🏆 Level Rewards Functions
function Database.getLevelRewards(level, passType, seasonId)
    local result = nil
    local completed = false
    
    MySQL.Async.fetchAll('SELECT * FROM battlepass_level_rewards WHERE level = @level AND pass_type = @pass_type AND season_id = @season_id', {
        ['@level'] = level,
        ['@pass_type'] = passType,
        ['@season_id'] = seasonId
    }, function(data)
        result = data
        completed = true
    end)
    
    while not completed do
        Citizen.Wait(10)
    end
    
    return result
end

function Database.addLevelReward(level, passType, rewardType, rewardData, seasonId)
    local success = false
    
    MySQL.Async.execute('INSERT INTO battlepass_level_rewards (level, pass_type, reward_type, reward_data, season_id) VALUES (@level, @pass_type, @reward_type, @reward_data, @season_id) ON DUPLICATE KEY UPDATE reward_data = @reward_data', {
        ['@level'] = level,
        ['@pass_type'] = passType,
        ['@reward_type'] = rewardType,
        ['@reward_data'] = json.encode(rewardData),
        ['@season_id'] = seasonId
    }, function(affectedRows)
        success = affectedRows > 0
    end)
    
    while success == false do
        Citizen.Wait(10)
    end
    
    return success
end

-- 🎁 Reward Logging Functions
function Database.logReward(identifier, rewardType, rewardData, level)
    local success = false
    
    MySQL.Async.execute('INSERT INTO battlepass_rewards (identifier, reward_type, reward_data, level) VALUES (@identifier, @reward_type, @reward_data, @level)', {
        ['@identifier'] = identifier,
        ['@reward_type'] = rewardType,
        ['@reward_data'] = json.encode(rewardData),
        ['@level'] = level
    }, function(affectedRows)
        success = affectedRows > 0
    end)
    
    while success == false do
        Citizen.Wait(10)
    end
    
    return success
end

function Database.getPlayerRewardHistory(identifier, limit)
    local result = nil
    local completed = false
    
    limit = limit or 50
    
    MySQL.Async.fetchAll('SELECT * FROM battlepass_rewards WHERE identifier = @identifier ORDER BY claimed_at DESC LIMIT @limit', {
        ['@identifier'] = identifier,
        ['@limit'] = limit
    }, function(data)
        result = data or {}
        completed = true
    end)
    
    while not completed do
        Citizen.Wait(10)
    end
    
    return result
end

-- 📊 Statistics Functions
function Database.recordStatistic(identifier, statType, value)
    local success = false
    local today = os.date('%Y-%m-%d')
    
    MySQL.Async.execute('INSERT INTO battlepass_statistics (identifier, stat_type, stat_value, date_recorded) VALUES (@identifier, @stat_type, @stat_value, @date_recorded) ON DUPLICATE KEY UPDATE stat_value = stat_value + @stat_value', {
        ['@identifier'] = identifier,
        ['@stat_type'] = statType,
        ['@stat_value'] = value,
        ['@date_recorded'] = today
    }, function(affectedRows)
        success = affectedRows > 0
    end)
    
    while success == false do
        Citizen.Wait(10)
    end
    
    return success
end

-- 👑 Admin Functions
function Database.resetPlayer(identifier)
    local success = false
    
    -- Start transaction
    MySQL.Async.execute('START TRANSACTION', {}, function()
        -- Reset player data
        MySQL.Async.execute('UPDATE battlepass_players SET level = 1, xp = 0, daily_streak = 0, last_daily_claim = NULL, premium = FALSE, premium_expires = NULL WHERE identifier = @identifier', {
            ['@identifier'] = identifier
        }, function(affectedRows1)
            -- Delete missions
            MySQL.Async.execute('DELETE FROM battlepass_missions WHERE identifier = @identifier', {
                ['@identifier'] = identifier
            }, function(affectedRows2)
                -- Delete reward history
                MySQL.Async.execute('DELETE FROM battlepass_rewards WHERE identifier = @identifier', {
                    ['@identifier'] = identifier
                }, function(affectedRows3)
                    -- Commit transaction
                    MySQL.Async.execute('COMMIT', {}, function()
                        success = true
                    end)
                end)
            end)
        end)
    end)
    
    while success == false do
        Citizen.Wait(10)
    end
    
    return success
end

function Database.setPlayerLevel(identifier, level, xp)
    local success = false
    
    MySQL.Async.execute('UPDATE battlepass_players SET level = @level, xp = @xp WHERE identifier = @identifier', {
        ['@identifier'] = identifier,
        ['@level'] = math.max(1, math.min(level, Config.Battlepass.maxLevel)),
        ['@xp'] = math.max(0, xp)
    }, function(affectedRows)
        success = affectedRows > 0
    end)
    
    while success == false do
        Citizen.Wait(10)
    end
    
    return success
end

-- 🔄 Season Management
function Database.getCurrentSeason()
    local result = nil
    local completed = false
    
    MySQL.Async.fetchAll('SELECT * FROM battlepass_seasons WHERE active = TRUE ORDER BY id DESC LIMIT 1', {}, function(data)
        if data and data[1] then
            result = data[1]
        end
        completed = true
    end)
    
    while not completed do
        Citizen.Wait(10)
    end
    
    return result
end

function Database.createSeason(name, description, startDate, endDate)
    local success = false
    
    MySQL.Async.execute('INSERT INTO battlepass_seasons (name, description, start_date, end_date, active) VALUES (@name, @description, FROM_UNIXTIME(@start_date), FROM_UNIXTIME(@end_date), TRUE)', {
        ['@name'] = name,
        ['@description'] = description,
        ['@start_date'] = startDate,
        ['@end_date'] = endDate
    }, function(affectedRows)
        success = affectedRows > 0
    end)
    
    while success == false do
        Citizen.Wait(10)
    end
    
    return success
end

-- Export the Database module
exports('getDatabase', function()
    return Database
end)

return Database