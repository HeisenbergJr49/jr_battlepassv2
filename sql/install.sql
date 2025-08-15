-- jr_battlepassv2 Database Installation
-- Run this SQL script to install the battlepass system tables

-- Create battlepass_players table
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
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_level` (`level`),
    INDEX `idx_premium` (`premium`),
    INDEX `idx_season` (`season_id`)
);

-- Create battlepass_missions table
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
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_identifier` (`identifier`),
    INDEX `idx_expires` (`expires_at`),
    INDEX `idx_mission_type` (`mission_type`),
    INDEX `idx_completed` (`completed`),
    INDEX `idx_claimed` (`claimed`),
    UNIQUE KEY `unique_mission` (`identifier`, `mission_id`, `expires_at`)
);

-- Create battlepass_rewards table
CREATE TABLE IF NOT EXISTS `battlepass_rewards` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `identifier` VARCHAR(50),
    `reward_type` ENUM('daily', 'level_free', 'level_premium', 'mission', 'lootbox', 'premium_purchase'),
    `reward_data` JSON,
    `claimed_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_identifier` (`identifier`),
    INDEX `idx_claimed` (`claimed_at`),
    INDEX `idx_reward_type` (`reward_type`)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS `idx_battlepass_players_xp` ON `battlepass_players` (`xp` DESC);
CREATE INDEX IF NOT EXISTS `idx_battlepass_players_daily` ON `battlepass_players` (`last_daily_claim`, `daily_streak`);
CREATE INDEX IF NOT EXISTS `idx_battlepass_missions_progress` ON `battlepass_missions` (`identifier`, `mission_type`, `completed`);

-- Insert default data if needed
INSERT IGNORE INTO `battlepass_players` (`identifier`, `level`, `xp`, `season_id`) 
SELECT 'default_admin', 1, 0, 1 WHERE NOT EXISTS (SELECT 1 FROM `battlepass_players` WHERE `identifier` = 'default_admin');

-- Create stored procedures for common operations

DELIMITER $$

-- Procedure to get player battlepass summary
CREATE PROCEDURE IF NOT EXISTS `GetPlayerBattlepassSummary`(IN player_identifier VARCHAR(50))
BEGIN
    SELECT 
        bp.identifier,
        bp.level,
        bp.xp,
        bp.premium,
        bp.premium_expires,
        bp.daily_streak,
        bp.last_daily_claim,
        COUNT(bm.id) as active_missions,
        COUNT(CASE WHEN bm.completed = TRUE AND bm.claimed = FALSE THEN 1 END) as unclaimed_missions,
        COUNT(br.id) as total_rewards_claimed
    FROM battlepass_players bp
    LEFT JOIN battlepass_missions bm ON bp.identifier = bm.identifier AND bm.expires_at > NOW()
    LEFT JOIN battlepass_rewards br ON bp.identifier = br.identifier
    WHERE bp.identifier = player_identifier
    GROUP BY bp.identifier;
END$$

-- Procedure to clean old data
CREATE PROCEDURE IF NOT EXISTS `CleanOldBattlepassData`()
BEGIN
    -- Delete expired missions older than 7 days
    DELETE FROM battlepass_missions WHERE expires_at < DATE_SUB(NOW(), INTERVAL 7 DAY);
    
    -- Delete reward logs older than 90 days
    DELETE FROM battlepass_rewards WHERE claimed_at < DATE_SUB(NOW(), INTERVAL 90 DAY);
    
    -- Clean up orphaned mission records (no matching player)
    DELETE bm FROM battlepass_missions bm
    LEFT JOIN battlepass_players bp ON bm.identifier = bp.identifier
    WHERE bp.identifier IS NULL;
    
    SELECT ROW_COUNT() as cleaned_records;
END$$

-- Procedure to get battlepass statistics
CREATE PROCEDURE IF NOT EXISTS `GetBattlepassStatistics`(IN season_id_param INT)
BEGIN
    SELECT 
        COUNT(*) as total_players,
        AVG(level) as avg_level,
        MAX(level) as max_level,
        MIN(level) as min_level,
        SUM(CASE WHEN premium = TRUE THEN 1 ELSE 0 END) as premium_players,
        COUNT(DISTINCT DATE(created_at)) as active_days,
        AVG(xp) as avg_xp,
        SUM(xp) as total_xp_earned
    FROM battlepass_players 
    WHERE season_id = season_id_param;
END$$

-- Procedure to get top players
CREATE PROCEDURE IF NOT EXISTS `GetTopPlayers`(IN limit_count INT, IN season_id_param INT)
BEGIN
    SELECT 
        identifier,
        level,
        xp,
        premium,
        created_at,
        RANK() OVER (ORDER BY level DESC, xp DESC) as rank_position
    FROM battlepass_players 
    WHERE season_id = season_id_param
    ORDER BY level DESC, xp DESC
    LIMIT limit_count;
END$$

-- Function to calculate XP needed for next level
CREATE FUNCTION IF NOT EXISTS `CalculateXPForLevel`(target_level INT) 
RETURNS INT
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE total_xp INT DEFAULT 0;
    DECLARE current_level INT DEFAULT 1;
    DECLARE xp_for_level INT;
    
    WHILE current_level < target_level DO
        -- Calculate XP needed for current level based on formula
        IF current_level <= 10 THEN
            SET xp_for_level = current_level * 500;
        ELSEIF current_level <= 25 THEN
            SET xp_for_level = current_level * 750;
        ELSEIF current_level <= 50 THEN
            SET xp_for_level = current_level * 1000;
        ELSEIF current_level <= 75 THEN
            SET xp_for_level = current_level * 1250;
        ELSE
            SET xp_for_level = current_level * 1500;
        END IF;
        
        SET total_xp = total_xp + xp_for_level;
        SET current_level = current_level + 1;
    END WHILE;
    
    RETURN total_xp;
END$$

DELIMITER ;

-- Create triggers for automatic data management

-- Trigger to update last_updated timestamp
CREATE TRIGGER IF NOT EXISTS `tr_battlepass_players_update` 
    BEFORE UPDATE ON `battlepass_players`
    FOR EACH ROW 
    SET NEW.updated_at = CURRENT_TIMESTAMP;

-- Trigger to log level changes
CREATE TRIGGER IF NOT EXISTS `tr_battlepass_level_change`
    AFTER UPDATE ON `battlepass_players`
    FOR EACH ROW
    BEGIN
        IF OLD.level != NEW.level THEN
            INSERT INTO battlepass_rewards (identifier, reward_type, reward_data)
            VALUES (NEW.identifier, 'level_change', JSON_OBJECT(
                'old_level', OLD.level,
                'new_level', NEW.level,
                'xp_gained', NEW.xp - OLD.xp
            ));
        END IF;
    END;

-- Create views for common queries

-- View for active players with their current status
CREATE OR REPLACE VIEW `v_active_battlepass_players` AS
SELECT 
    bp.identifier,
    bp.level,
    bp.xp,
    bp.premium,
    bp.premium_expires,
    bp.daily_streak,
    bp.last_daily_claim,
    CASE 
        WHEN bp.premium AND bp.premium_expires > NOW() THEN 'Premium Active'
        WHEN bp.premium AND bp.premium_expires <= NOW() THEN 'Premium Expired'
        ELSE 'Free'
    END as premium_status,
    DATEDIFF(NOW(), bp.created_at) as days_since_join,
    COUNT(bm.id) as active_missions
FROM battlepass_players bp
LEFT JOIN battlepass_missions bm ON bp.identifier = bm.identifier AND bm.expires_at > NOW()
WHERE bp.updated_at > DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY bp.identifier;

-- View for mission completion statistics
CREATE OR REPLACE VIEW `v_mission_stats` AS
SELECT 
    mission_id,
    mission_type,
    COUNT(*) as total_assignments,
    SUM(CASE WHEN completed = TRUE THEN 1 ELSE 0 END) as completions,
    SUM(CASE WHEN claimed = TRUE THEN 1 ELSE 0 END) as claims,
    ROUND(SUM(CASE WHEN completed = TRUE THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) as completion_rate,
    AVG(progress) as avg_progress
FROM battlepass_missions
WHERE created_at > DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY mission_id, mission_type;

-- Insert sample configuration data
INSERT IGNORE INTO battlepass_rewards (identifier, reward_type, reward_data) VALUES
('system', 'level_free', '{"level": 1, "reward": {"type": "money", "amount": 1000}, "description": "Welcome bonus"}');

-- Create event scheduler for automatic cleanup (if event scheduler is enabled)
-- SET GLOBAL event_scheduler = ON;

CREATE EVENT IF NOT EXISTS `ev_cleanup_battlepass_data`
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP
DO
BEGIN
    CALL CleanOldBattlepassData();
END;

-- Optimization: Analyze tables for better performance
ANALYZE TABLE battlepass_players;
ANALYZE TABLE battlepass_missions; 
ANALYZE TABLE battlepass_rewards;

-- Show installation summary
SELECT 
    'battlepass_players' as table_name,
    COUNT(*) as record_count,
    'Player data storage' as description
FROM battlepass_players

UNION ALL

SELECT 
    'battlepass_missions' as table_name,
    COUNT(*) as record_count,
    'Mission tracking data' as description
FROM battlepass_missions

UNION ALL

SELECT 
    'battlepass_rewards' as table_name,
    COUNT(*) as record_count,
    'Reward claim logs' as description
FROM battlepass_rewards;

-- Success message
SELECT '✅ JR.DEV Battlepass System Database Installation Complete!' as status;