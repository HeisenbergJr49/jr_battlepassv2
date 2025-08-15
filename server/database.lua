-- Database queries and management for battlepass system

-- Initialize database tables
MySQL.ready(function()
    -- Check if tables exist and create them if not
    CreateBattlepassTables()
    print('[jr_battlepass] Database initialized')
end)

-- Create battlepass database tables
function CreateBattlepassTables()
    -- Players table
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `battlepass_players` (
            `identifier` VARCHAR(50) PRIMARY KEY,
            `level` INT DEFAULT 1,
            `xp` INT DEFAULT 0,
            `coins` INT DEFAULT 0,
            `premium` BOOLEAN DEFAULT FALSE,
            `premium_expires` TIMESTAMP NULL,
            `daily_streak` INT DEFAULT 0,
            `last_daily_claim` TIMESTAMP NULL,
            `season_id` INT DEFAULT 1,
            `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        )
    ]], {})
    
    -- Missions table
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `battlepass_missions` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `identifier` VARCHAR(50),
            `mission_id` VARCHAR(50),
            `progress` INT DEFAULT 0,
            `completed` BOOLEAN DEFAULT FALSE,
            `claimed` BOOLEAN DEFAULT FALSE,
            `mission_type` ENUM('daily', 'weekly'),
            `expires_at` TIMESTAMP,
            `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX `idx_identifier` (`identifier`),
            INDEX `idx_expires` (`expires_at`),
            INDEX `idx_mission_type` (`mission_type`)
        )
    ]], {})
    
    -- Rewards table
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `battlepass_rewards` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `identifier` VARCHAR(50),
            `reward_type` ENUM('daily', 'level_free', 'level_premium', 'mission', 'lootbox'),
            `reward_data` JSON,
            `claimed_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX `idx_identifier` (`identifier`),
            INDEX `idx_claimed` (`claimed_at`),
            INDEX `idx_reward_type` (`reward_type`)
        )
    ]], {})
end

-- Get player battlepass data
function GetPlayerBattlepassData(identifier, callback)
    MySQL.Async.fetchAll('SELECT * FROM battlepass_players WHERE identifier = @identifier', {
        ['@identifier'] = identifier
    }, function(result)
        callback(result[1])
    end)
end

-- Create new player record
function CreatePlayerRecord(identifier, callback)
    MySQL.Async.execute('INSERT INTO battlepass_players (identifier, season_id) VALUES (@identifier, @season_id)', {
        ['@identifier'] = identifier,
        ['@season_id'] = Config.SeasonId
    }, function(rowsChanged)
        callback(rowsChanged > 0)
    end)
end

-- Update player battlepass data
function UpdatePlayerBattlepassData(data, callback)
    if not data or not data.identifier then
        if callback then callback(false) end
        return
    end
    
    MySQL.Async.execute([[
        UPDATE battlepass_players SET 
            level = @level, 
            xp = @xp, 
            coins = @coins, 
            premium = @premium, 
            premium_expires = @premium_expires, 
            daily_streak = @daily_streak, 
            last_daily_claim = @last_daily_claim, 
            season_id = @season_id 
        WHERE identifier = @identifier
    ]], {
        ['@identifier'] = data.identifier,
        ['@level'] = data.level or 1,
        ['@xp'] = data.xp or 0,
        ['@coins'] = data.coins or 0,
        ['@premium'] = data.premium or false,
        ['@premium_expires'] = data.premium_expires,
        ['@daily_streak'] = data.daily_streak or 0,
        ['@last_daily_claim'] = data.last_daily_claim,
        ['@season_id'] = data.season_id or Config.SeasonId
    }, function(rowsChanged)
        if callback then callback(rowsChanged > 0) end
    end)
end

-- Get player missions
function GetPlayerMissions(identifier, callback)
    MySQL.Async.fetchAll([[
        SELECT * FROM battlepass_missions 
        WHERE identifier = @identifier 
        AND expires_at > NOW() 
        ORDER BY mission_type, created_at DESC
    ]], {
        ['@identifier'] = identifier
    }, function(result)
        callback(result)
    end)
end

-- Create or update mission progress
function UpdateMissionProgress(identifier, missionId, progress, missionType, expiresAt, callback)
    -- First try to update existing mission
    MySQL.Async.execute([[
        UPDATE battlepass_missions SET 
            progress = GREATEST(progress, @progress),
            updated_at = NOW()
        WHERE identifier = @identifier 
        AND mission_id = @mission_id 
        AND expires_at > NOW()
    ]], {
        ['@identifier'] = identifier,
        ['@mission_id'] = missionId,
        ['@progress'] = progress
    }, function(rowsChanged)
        if rowsChanged == 0 then
            -- Insert new mission record
            MySQL.Async.execute([[
                INSERT INTO battlepass_missions 
                (identifier, mission_id, progress, mission_type, expires_at) 
                VALUES (@identifier, @mission_id, @progress, @mission_type, @expires_at)
            ]], {
                ['@identifier'] = identifier,
                ['@mission_id'] = missionId,
                ['@progress'] = progress,
                ['@mission_type'] = missionType,
                ['@expires_at'] = expiresAt
            }, function(insertId)
                if callback then callback(insertId > 0) end
            end)
        else
            if callback then callback(true) end
        end
    end)
end

-- Mark mission as completed
function CompleteMission(identifier, missionId, callback)
    MySQL.Async.execute([[
        UPDATE battlepass_missions SET 
            completed = TRUE,
            updated_at = NOW()
        WHERE identifier = @identifier 
        AND mission_id = @mission_id 
        AND expires_at > NOW()
    ]], {
        ['@identifier'] = identifier,
        ['@mission_id'] = missionId
    }, function(rowsChanged)
        if callback then callback(rowsChanged > 0) end
    end)
end

-- Mark mission as claimed
function ClaimMission(identifier, missionId, callback)
    MySQL.Async.execute([[
        UPDATE battlepass_missions SET 
            claimed = TRUE,
            updated_at = NOW()
        WHERE identifier = @identifier 
        AND mission_id = @mission_id 
        AND completed = TRUE
    ]], {
        ['@identifier'] = identifier,
        ['@mission_id'] = missionId
    }, function(rowsChanged)
        if callback then callback(rowsChanged > 0) end
    end)
end

-- Clean up expired missions
function CleanExpiredMissions()
    MySQL.Async.execute('DELETE FROM battlepass_missions WHERE expires_at < NOW()', {}, function(rowsChanged)
        if Config.Debug and rowsChanged > 0 then
            print(('[jr_battlepass] Cleaned up %s expired missions'):format(rowsChanged))
        end
    end)
end

-- Log reward claim
function LogRewardClaim(identifier, rewardType, rewardData, callback)
    MySQL.Async.execute('INSERT INTO battlepass_rewards (identifier, reward_type, reward_data) VALUES (@identifier, @type, @data)', {
        ['@identifier'] = identifier,
        ['@type'] = rewardType,
        ['@data'] = json.encode(rewardData)
    }, function(insertId)
        if callback then callback(insertId > 0) end
    end)
end

-- Get player reward history
function GetPlayerRewardHistory(identifier, limit, callback)
    limit = limit or 50
    
    MySQL.Async.fetchAll([[
        SELECT * FROM battlepass_rewards 
        WHERE identifier = @identifier 
        ORDER BY claimed_at DESC 
        LIMIT @limit
    ]], {
        ['@identifier'] = identifier,
        ['@limit'] = limit
    }, function(result)
        callback(result)
    end)
end

-- Get battlepass statistics
function GetBattlepassStatistics(callback)
    MySQL.Async.fetchAll([[
        SELECT 
            COUNT(*) as total_players,
            AVG(level) as avg_level,
            MAX(level) as max_level,
            SUM(premium) as premium_players,
            COUNT(DISTINCT DATE(created_at)) as active_days
        FROM battlepass_players 
        WHERE season_id = @season_id
    ]], {
        ['@season_id'] = Config.SeasonId
    }, function(result)
        callback(result[1])
    end)
end

-- Get top players by level
function GetTopPlayers(limit, callback)
    limit = limit or 10
    
    MySQL.Async.fetchAll([[
        SELECT identifier, level, xp 
        FROM battlepass_players 
        WHERE season_id = @season_id
        ORDER BY level DESC, xp DESC 
        LIMIT @limit
    ]], {
        ['@season_id'] = Config.SeasonId,
        ['@limit'] = limit
    }, function(result)
        callback(result)
    end)
end

-- Reset player data for new season
function ResetPlayerForNewSeason(identifier, callback)
    MySQL.Async.execute([[
        UPDATE battlepass_players SET 
            level = 1,
            xp = 0,
            coins = 0,
            premium = FALSE,
            premium_expires = NULL,
            daily_streak = 0,
            last_daily_claim = NULL,
            season_id = @season_id
        WHERE identifier = @identifier
    ]], {
        ['@identifier'] = identifier,
        ['@season_id'] = Config.SeasonId
    }, function(rowsChanged)
        if callback then callback(rowsChanged > 0) end
    end)
end

-- Backup player data before season reset
function BackupPlayerData(callback)
    local backupTable = 'battlepass_players_backup_' .. os.date('%Y%m%d_%H%M%S')
    
    MySQL.Async.execute(([[
        CREATE TABLE %s AS SELECT * FROM battlepass_players
    ]]):format(backupTable), {}, function(result)
        if callback then callback(result) end
        print(('[jr_battlepass] Player data backed up to %s'):format(backupTable))
    end)
end

-- Clean up old backup tables (keep last 3)
function CleanupBackups()
    MySQL.Async.fetchAll("SHOW TABLES LIKE 'battlepass_players_backup_%'", {}, function(tables)
        if #tables > 3 then
            -- Sort tables by name (which includes timestamp) and keep only the 3 most recent
            table.sort(tables, function(a, b)
                return tables[a] > tables[b]
            end)
            
            for i = 4, #tables do
                local tableName = tables[i]['Tables_in_' .. GetConvar('mysql_database', 'es_extended')]
                MySQL.Async.execute(('DROP TABLE %s'):format(tableName), {})
                print(('[jr_battlepass] Cleaned up old backup table: %s'):format(tableName))
            end
        end
    end)
end

-- Scheduled cleanup tasks
CreateThread(function()
    while true do
        Wait(3600000) -- Run every hour
        
        -- Clean expired missions
        CleanExpiredMissions()
        
        -- Clean old backups (once per day)
        local hour = tonumber(os.date('%H'))
        if hour == 3 then -- 3 AM
            CleanupBackups()
        end
    end
end)

-- Export database functions
exports('getPlayerBattlepassData', GetPlayerBattlepassData)
exports('updatePlayerBattlepassData', UpdatePlayerBattlepassData)
exports('getPlayerMissions', GetPlayerMissions)
exports('updateMissionProgress', UpdateMissionProgress)
exports('completeMission', CompleteMission)
exports('getBattlepassStatistics', GetBattlepassStatistics)
exports('getTopPlayers', GetTopPlayers)
exports('resetPlayerForNewSeason', ResetPlayerForNewSeason)
exports('backupPlayerData', BackupPlayerData)