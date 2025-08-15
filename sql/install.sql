-- Database Installation Script for JR.DEV Battlepass System
-- Import this file into your MySQL database

-- Create battlepass_players table
CREATE TABLE IF NOT EXISTS `battlepass_players` (
    `identifier` VARCHAR(50) NOT NULL PRIMARY KEY,
    `level` INT NOT NULL DEFAULT 1,
    `xp` INT NOT NULL DEFAULT 0,
    `coins` INT NOT NULL DEFAULT 100,
    `premium` BOOLEAN NOT NULL DEFAULT FALSE,
    `premium_expires` TIMESTAMP NULL DEFAULT NULL,
    `daily_streak` INT NOT NULL DEFAULT 0,
    `last_daily_claim` TIMESTAMP NULL DEFAULT NULL,
    `season_id` INT NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX `idx_level` (`level`),
    INDEX `idx_premium` (`premium`),
    INDEX `idx_season` (`season_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Create battlepass_missions table
CREATE TABLE IF NOT EXISTS `battlepass_missions` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `identifier` VARCHAR(50) NOT NULL,
    `mission_id` VARCHAR(50) NOT NULL,
    `progress` INT NOT NULL DEFAULT 0,
    `completed` BOOLEAN NOT NULL DEFAULT FALSE,
    `claimed` BOOLEAN NOT NULL DEFAULT FALSE,
    `mission_type` ENUM('daily', 'weekly') NOT NULL,
    `expires_at` TIMESTAMP NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX `idx_identifier` (`identifier`),
    INDEX `idx_mission_id` (`mission_id`),
    INDEX `idx_expires` (`expires_at`),
    INDEX `idx_type_completed` (`mission_type`, `completed`),
    
    UNIQUE KEY `unique_player_mission` (`identifier`, `mission_id`, `expires_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Create battlepass_rewards table
CREATE TABLE IF NOT EXISTS `battlepass_rewards` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `identifier` VARCHAR(50) NOT NULL,
    `reward_type` ENUM('daily', 'level', 'mission', 'lootbox') NOT NULL,
    `reward_data` JSON NOT NULL,
    `level` INT DEFAULT NULL,
    `claimed_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX `idx_identifier` (`identifier`),
    INDEX `idx_type` (`reward_type`),
    INDEX `idx_claimed` (`claimed_at`),
    INDEX `idx_level` (`level`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Create battlepass_seasons table
CREATE TABLE IF NOT EXISTS `battlepass_seasons` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(100) NOT NULL,
    `description` TEXT,
    `start_date` TIMESTAMP NOT NULL,
    `end_date` TIMESTAMP NOT NULL,
    `active` BOOLEAN NOT NULL DEFAULT TRUE,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX `idx_active` (`active`),
    INDEX `idx_dates` (`start_date`, `end_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Create battlepass_level_rewards table for dynamic reward management
CREATE TABLE IF NOT EXISTS `battlepass_level_rewards` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `level` INT NOT NULL,
    `pass_type` ENUM('free', 'premium') NOT NULL,
    `reward_type` ENUM('money', 'bank', 'item', 'weapon', 'vehicle', 'coins', 'lootbox') NOT NULL,
    `reward_data` JSON NOT NULL,
    `season_id` INT NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX `idx_level_type` (`level`, `pass_type`),
    INDEX `idx_season` (`season_id`),
    
    UNIQUE KEY `unique_level_pass_season` (`level`, `pass_type`, `season_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Create battlepass_statistics table for analytics
CREATE TABLE IF NOT EXISTS `battlepass_statistics` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `identifier` VARCHAR(50) NOT NULL,
    `stat_type` VARCHAR(50) NOT NULL,
    `stat_value` INT NOT NULL DEFAULT 0,
    `date_recorded` DATE NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX `idx_identifier_type` (`identifier`, `stat_type`),
    INDEX `idx_date` (`date_recorded`),
    
    UNIQUE KEY `unique_player_stat_date` (`identifier`, `stat_type`, `date_recorded`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insert default season
INSERT INTO `battlepass_seasons` (`name`, `description`, `start_date`, `end_date`, `active`) 
VALUES ('Season 1', 'Die erste Season des JR.DEV Battlepass Systems', NOW(), DATE_ADD(NOW(), INTERVAL 90 DAY), TRUE)
ON DUPLICATE KEY UPDATE `name` = `name`;

-- Insert some default level rewards for Season 1
INSERT INTO `battlepass_level_rewards` (`level`, `pass_type`, `reward_type`, `reward_data`, `season_id`) VALUES
-- Free Pass Rewards
(5, 'free', 'money', '{"amount": 1000, "label": "1.000€ Bargeld"}', 1),
(10, 'free', 'item', '{"item": "bandage", "count": 10, "label": "10x Verband"}', 1),
(15, 'free', 'coins', '{"amount": 50, "label": "50 BP Coins"}', 1),
(20, 'free', 'lootbox', '{"box": "basic", "label": "Basic Loot-Box"}', 1),
(25, 'free', 'money', '{"amount": 2500, "label": "2.500€ Bargeld"}', 1),
(30, 'free', 'item', '{"item": "lockpick", "count": 5, "label": "5x Lockpick"}', 1),
(35, 'free', 'coins', '{"amount": 75, "label": "75 BP Coins"}', 1),
(40, 'free', 'item', '{"item": "phone", "count": 1, "label": "1x Handy"}', 1),
(45, 'free', 'money', '{"amount": 5000, "label": "5.000€ Bargeld"}', 1),
(50, 'free', 'lootbox', '{"box": "premium", "label": "Premium Loot-Box"}', 1),

-- Premium Pass Rewards
(3, 'premium', 'coins', '{"amount": 25, "label": "25 BP Coins"}', 1),
(7, 'premium', 'item', '{"item": "firstaid", "count": 3, "label": "3x Erste-Hilfe-Kit"}', 1),
(12, 'premium', 'weapon', '{"weapon": "weapon_knife", "label": "Kampfmesser"}', 1),
(17, 'premium', 'money', '{"amount": 3000, "label": "3.000€ Bargeld"}', 1),
(22, 'premium', 'vehicle', '{"vehicle": "blista", "label": "Blista Compact"}', 1),
(27, 'premium', 'item', '{"item": "gold_bar", "count": 1, "label": "1x Goldbarren"}', 1),
(32, 'premium', 'coins', '{"amount": 150, "label": "150 BP Coins"}', 1),
(37, 'premium', 'lootbox', '{"box": "premium", "label": "Premium Loot-Box"}', 1),
(42, 'premium', 'bank', '{"amount": 7500, "label": "7.500€ Bankguthaben"}', 1),
(47, 'premium', 'weapon', '{"weapon": "weapon_pistol", "ammo": 100, "label": "Pistole + 100 Schuss"}', 1)
ON DUPLICATE KEY UPDATE `reward_data` = VALUES(`reward_data`);

-- Add indexes for better performance
ALTER TABLE `battlepass_players` 
ADD INDEX IF NOT EXISTS `idx_daily_streak` (`daily_streak`),
ADD INDEX IF NOT EXISTS `idx_last_claim` (`last_daily_claim`);

ALTER TABLE `battlepass_missions`
ADD INDEX IF NOT EXISTS `idx_completed_claimed` (`completed`, `claimed`),
ADD INDEX IF NOT EXISTS `idx_identifier_type` (`identifier`, `mission_type`);

-- Success message
SELECT 'JR.DEV Battlepass Database Schema installed successfully!' as message;