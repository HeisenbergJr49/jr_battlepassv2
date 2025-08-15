# 🎮 JR.DEV Battlepass System v2.0

A comprehensive FiveM ESX Battlepass system with modern UI, XP progression, daily rewards, missions, and premium features.

## ✨ Features

### 🎯 Core System
- **100 Level Progression** - Dynamic XP requirements per level
- **Premium Battlepass** - Exclusive rewards and XP bonuses  
- **Season System** - Configurable seasons with unique themes
- **Multi-language Support** - English and German included

### 🎁 Reward System
- **Daily Login Rewards** - 7-day streak cycle with mega bonus
- **Level Rewards** - Free and premium track rewards
- **Loot Boxes** - Basic, Premium, and Legendary tiers
- **Mission Rewards** - XP, money, and item rewards

### 📋 Mission System
- **Daily Missions** - Playtime, fishing, driving, money earning
- **Weekly Missions** - Races, jobs, combat, farming
- **Auto-tracking** - Progress tracked automatically
- **Real-time Updates** - Live mission progress updates

### 🎨 Modern UI
- **GTA Online Inspired** - Professional battlepass interface
- **Glassmorphism Design** - Modern visual effects
- **Smooth Animations** - Level up effects and particles
- **Responsive Layout** - Works on all screen sizes

### ⚙️ Admin Features
- **Admin Commands** - Give XP, set levels, manage premium
- **Statistics Dashboard** - Player stats and leaderboards
- **Debug Tools** - Development and testing features
- **Season Management** - Start new seasons and reset data

## 🔧 Installation

### 1. Database Setup
```sql
-- Run the SQL installation script
source sql/install.sql
```

### 2. Server Configuration
```lua
-- Add to server.cfg
ensure jr_battlepassv2

-- Dependencies required
ensure es_extended
ensure ox_inventory  # Optional but recommended
```

### 3. Configuration
Edit `config.lua` to customize:
- XP requirements per level
- Mission objectives and rewards  
- Daily reward cycle
- Loot box contents
- Premium pricing

## 🎮 Usage

### Player Commands
- **F6** - Open/Close Battlepass
- **ESC** - Close battlepass interface

### Admin Commands
```bash
/bp_givexp <playerId> <amount> [reason]    # Give XP to player
/bp_setlevel <playerId> <level>            # Set player level  
/bp_givepremium <playerId> [days]          # Give premium access
/bp_reset <playerId>                       # Reset player progress
/bp_stats                                  # View statistics
/bp_top [limit]                           # Show leaderboard
/bp_givelootbox <playerId> <boxType>      # Give loot box
/bp_debug                                 # Toggle debug mode
/bp_newseason <seasonId> [name]           # Start new season (owner only)
```

## 🔌 Integration

### Mission Tracking
The system automatically tracks player activities:
- **Playtime** - Session time monitoring
- **Driving** - Distance tracking while in vehicle
- **Fishing** - Integration with fishing systems
- **Money** - Bank and cash earning detection
- **Jobs** - ESX job completion tracking
- **Combat** - NPC elimination tracking

### ESX Integration
```lua
-- Give XP from other resources
exports.jr_battlepassv2:givePlayerXP(playerId, amount, reason)

-- Check player data
local level = exports.jr_battlepassv2:getPlayerLevel(playerId)
local xp = exports.jr_battlepassv2:getPlayerXP(playerId)
local data = exports.jr_battlepassv2:getPlayerBattlepassData(playerId)
```

## 📁 File Structure
```
jr_battlepassv2/
├── client/
│   ├── main.lua          # Core client functionality
│   ├── missions.lua      # Mission tracking system
│   └── ui.lua            # NUI communication
├── server/
│   ├── main.lua          # Core server logic
│   ├── database.lua      # Database operations
│   ├── rewards.lua       # Reward system
│   └── admin.lua         # Admin commands
├── html/
│   ├── index.html        # NUI interface
│   ├── css/style.css     # Modern styling
│   └── js/
│       ├── app.js        # Main JavaScript
│       └── animations.js # Animation system
├── sql/
│   └── install.sql       # Database schema
├── locales/
│   ├── en.lua           # English translations
│   └── de.lua           # German translations
├── config.lua           # Configuration file
└── fxmanifest.lua      # Resource manifest
```

## 🛠️ Dependencies

### Required
- **es_extended** - ESX Framework

### Optional  
- **ox_inventory** - Enhanced inventory system
- **mysql-async** - Database operations

## 📊 Database Tables

- **battlepass_players** - Player progression data
- **battlepass_missions** - Mission progress tracking  
- **battlepass_rewards** - Reward claim history

## 🎯 Configuration Options

### XP System
- Configurable XP per level (1-100)
- Premium XP multiplier
- Anti-cheat XP limits

### Missions
- Daily/Weekly mission cycles
- Custom objectives and rewards
- Automatic progress tracking

### Rewards
- 7-day daily reward cycle
- Level milestone rewards
- Premium exclusive items

### Security
- Rate limiting protection
- Server-side validation
- SQL injection prevention

## 🆘 Support

For support and updates:
- **Author**: JR.DEV
- **Version**: 2.0.0
- **License**: Custom License

## 🔄 Updates

### v2.0.0
- Complete system rewrite
- Modern UI implementation
- Enhanced mission system
- Improved database structure
- Multi-language support
- Admin management tools

---

**⚠️ Note**: This is a production-ready battlepass system designed for FiveM ESX servers. Ensure proper configuration and testing before deploying to a live server.
