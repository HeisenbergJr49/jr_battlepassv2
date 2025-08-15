// 🎮 JR.DEV Battlepass - Main Application Logic
class BattlepassApp {
    constructor() {
        this.isVisible = false;
        this.playerData = {};
        this.config = {};
        this.locales = {};
        this.currentTab = 'battlepass';
        this.animationsEnabled = true;
        this.debugMode = false;
        
        this.init();
    }
    
    init() {
        console.log('🚀 JR.DEV Battlepass - Initializing...');
        
        this.bindEvents();
        this.setupNUIListeners();
        this.initializeUI();
        
        console.log('✅ JR.DEV Battlepass - Initialized successfully!');
    }
    
    bindEvents() {
        // Close button
        document.getElementById('closeButton').addEventListener('click', () => {
            this.closeBattlepass();
        });
        
        // Navigation buttons
        document.querySelectorAll('.nav-button').forEach(btn => {
            btn.addEventListener('click', (e) => {
                const tab = e.currentTarget.dataset.tab;
                this.switchTab(tab);
            });
        });
        
        // Premium purchase button
        document.getElementById('buyPremiumBtn').addEventListener('click', () => {
            this.buyPremium();
        });
        
        // Daily reward claim button
        document.getElementById('claimDailyBtn').addEventListener('click', () => {
            this.claimDailyReward();
        });
        
        // Keyboard events
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape' && this.isVisible) {
                this.closeBattlepass();
            }
        });
        
        // Debug panel close
        const debugClose = document.getElementById('debugClose');
        if (debugClose) {
            debugClose.addEventListener('click', () => {
                document.getElementById('debugPanel').classList.add('hidden');
            });
        }
    }
    
    setupNUIListeners() {
        // Listen for messages from the game
        window.addEventListener('message', (event) => {
            const data = event.data;
            
            switch (data.type) {
                case 'openBattlepass':
                    this.openBattlepass(data.data);
                    break;
                    
                case 'closeBattlepass':
                    this.closeBattlepass();
                    break;
                    
                case 'toggleUI':
                    if (data.data.show) {
                        this.showUI();
                    } else {
                        this.hideUI();
                    }
                    break;
                    
                case 'updatePlayerData':
                    this.updatePlayerData(data.data.player);
                    break;
                    
                case 'updateMissions':
                    this.updateMissions(data.data.missions);
                    break;
                    
                case 'showNotification':
                    this.showNotification(data.data.message, data.data.type, data.data.duration);
                    break;
                    
                case 'showXPGain':
                    this.showXPGain(data.data.amount, data.data.reason);
                    break;
                    
                case 'showLevelUp':
                    this.showLevelUp(data.data.newLevel, data.data.oldLevel);
                    break;
                    
                case 'showRewardAnimation':
                    this.showRewardAnimation(data.data.reward);
                    break;
                    
                case 'dailyRewardClaimed':
                    this.handleDailyRewardClaimed(data.data);
                    break;
                    
                case 'premiumActivated':
                    this.handlePremiumActivated(data.data);
                    break;
                    
                case 'lootBoxOpened':
                    this.showLootBoxOpening(data.data.boxType, data.data.reward);
                    break;
                    
                case 'missionCompleted':
                    this.handleMissionCompleted(data.data);
                    break;
                    
                case 'updateTheme':
                    this.updateTheme(data.data.theme);
                    break;
                    
                case 'toggleAnimations':
                    this.animationsEnabled = data.data.enabled;
                    break;
                    
                case 'toggleDebugMode':
                    this.debugMode = data.data.enabled;
                    this.toggleDebugPanel();
                    break;
                    
                case 'showDebugInfo':
                    this.showDebugInfo(data.data);
                    break;
                    
                case 'reloadConfig':
                    this.config = data.data.config;
                    this.locales = data.data.locales;
                    break;
                    
                default:
                    console.log('🔍 Unknown message type:', data.type);
            }
        });
    }
    
    initializeUI() {
        // Set initial state
        this.hideUI();
        
        // Initialize timers
        this.startTimers();
        
        // Initialize reward tracks
        this.initializeRewardTracks();
        
        // Initialize daily rewards
        this.initializeDailyRewards();
        
        // Initialize missions
        this.initializeMissions();
    }
    
    openBattlepass(data) {
        this.playerData = data.player || {};
        this.config = data.config || {};
        this.locales = data.locales || {};
        
        this.updatePlayerDisplay();
        this.populateRewards();
        this.populateDailyRewards();
        this.populateMissions();
        
        this.showUI();
        this.switchTab(data.currentTab || this.currentTab);
        
        this.playSound('SELECT');
    }
    
    closeBattlepass() {
        this.hideUI();
        this.sendNUIMessage('closeBattlepass');
        this.playSound('BACK');
    }
    
    showUI() {
        this.isVisible = true;
        document.getElementById('loadingScreen').classList.add('hidden');
        document.getElementById('battlepassContainer').classList.remove('hidden');
        
        if (this.animationsEnabled) {
            document.getElementById('battlepassContainer').style.animation = 'fadeInUp 0.3s ease-out';
        }
    }
    
    hideUI() {
        this.isVisible = false;
        document.getElementById('battlepassContainer').classList.add('hidden');
        document.getElementById('loadingScreen').classList.add('hidden');
    }
    
    switchTab(tabName) {
        // Remove active class from all tabs
        document.querySelectorAll('.nav-button').forEach(btn => btn.classList.remove('active'));
        document.querySelectorAll('.content-tab').forEach(tab => tab.classList.remove('active'));
        
        // Add active class to selected tab
        document.querySelector(`[data-tab="${tabName}"]`).classList.add('active');
        document.getElementById(`${tabName}Tab`).classList.add('active');
        
        this.currentTab = tabName;
        this.playSound('NAV_UP_DOWN');
        
        // Send tab switch to game
        this.sendNUIMessage('switchTab', { tab: tabName });
    }
    
    updatePlayerData(playerData) {
        this.playerData = { ...this.playerData, ...playerData };
        this.updatePlayerDisplay();
        this.updateRewardAvailability();
    }
    
    updatePlayerDisplay() {
        const data = this.playerData;
        
        // Update level display
        const levelNumber = document.querySelector('.level-number');
        if (levelNumber) levelNumber.textContent = data.level || 1;
        
        // Update XP bar
        const xpFill = document.querySelector('.xp-fill');
        const xpText = document.querySelector('.xp-text');
        if (xpFill && xpText && this.config.xpPerLevel) {
            const currentXP = data.xp || 0;
            const xpForNextLevel = this.config.xpPerLevel * Math.pow(1.1, (data.level || 1) - 1);
            const xpPercentage = Math.min((currentXP / xpForNextLevel) * 100, 100);
            
            xpFill.style.width = xpPercentage + '%';
            xpText.textContent = `${currentXP.toLocaleString()} / ${Math.floor(xpForNextLevel).toLocaleString()} XP`;
        }
        
        // Update coins display
        const coinsAmount = document.querySelector('.currency-amount');
        if (coinsAmount) coinsAmount.textContent = (data.coins || 0).toLocaleString();
        
        // Update premium status
        const premiumBadge = document.querySelector('.premium-badge');
        const buyPremiumBtn = document.getElementById('buyPremiumBtn');
        
        if (data.premium && data.premium_expires && Date.now() / 1000 < data.premium_expires) {
            if (premiumBadge) {
                premiumBadge.classList.add('premium-active');
                premiumBadge.textContent = 'PREMIUM';
            }
            if (buyPremiumBtn) {
                buyPremiumBtn.style.display = 'none';
            }
        } else {
            if (premiumBadge) {
                premiumBadge.classList.remove('premium-active');
                premiumBadge.textContent = 'FREE';
            }
            if (buyPremiumBtn) {
                buyPremiumBtn.style.display = 'block';
            }
        }
        
        // Update streak display
        const streakCounter = document.querySelector('.streak-counter');
        if (streakCounter) streakCounter.textContent = `${data.daily_streak || 0} Tage`;
    }
    
    initializeRewardTracks() {
        const freeTrack = document.getElementById('freeTrack');
        const premiumTrack = document.getElementById('premiumTrack');
        
        if (!freeTrack || !premiumTrack) return;
        
        // Clear existing content
        freeTrack.innerHTML = '';
        premiumTrack.innerHTML = '';
        
        // Generate reward items for levels 1-100
        for (let level = 1; level <= (this.config.maxLevel || 100); level += 5) {
            freeTrack.appendChild(this.createRewardItem(level, 'free'));
            premiumTrack.appendChild(this.createRewardItem(level, 'premium'));
        }
    }
    
    createRewardItem(level, passType) {
        const item = document.createElement('div');
        item.className = 'reward-item';
        item.dataset.level = level;
        item.dataset.passType = passType;
        
        // Determine if reward is unlocked
        const isUnlocked = (this.playerData.level || 1) >= level;
        const isClaimed = false; // TODO: Check if reward is claimed
        
        if (isUnlocked && !isClaimed) {
            item.classList.add('unlocked');
        } else if (isClaimed) {
            item.classList.add('claimed');
        }
        
        // Create reward content
        const reward = this.getRewardForLevel(level, passType);
        
        item.innerHTML = `
            <div class="reward-level">${level}</div>
            <div class="reward-icon">${this.getRewardIcon(reward)}</div>
            <div class="reward-info">
                <div class="reward-name">${reward.name}</div>
                <div class="reward-description">${reward.description}</div>
            </div>
            ${isUnlocked && !isClaimed ? '<button class="claim-reward-btn">Einfordern</button>' : ''}
        `;
        
        // Add claim functionality
        const claimBtn = item.querySelector('.claim-reward-btn');
        if (claimBtn) {
            claimBtn.addEventListener('click', () => {
                this.claimLevelReward(level, passType);
            });
        }
        
        return item;
    }
    
    getRewardForLevel(level, passType) {
        // Generate rewards based on level and pass type
        const rewards = {
            free: {
                money: { name: `${level * 100}€ Bargeld`, description: 'Erhalte Bargeld', icon: '💰' },
                item: { name: 'Gegenstand', description: 'Nützlicher Gegenstand', icon: '📦' },
                coins: { name: `${level * 2} Coins`, description: 'Battlepass Coins', icon: '🪙' }
            },
            premium: {
                money: { name: `${level * 200}€ Bargeld`, description: 'Premium Bargeld', icon: '💎' },
                weapon: { name: 'Waffe', description: 'Seltene Waffe', icon: '🔫' },
                vehicle: { name: 'Fahrzeug', description: 'Exklusives Fahrzeug', icon: '🚗' },
                coins: { name: `${level * 5} Coins`, description: 'Premium Coins', icon: '👑' }
            }
        };
        
        const rewardTypes = Object.keys(rewards[passType]);
        const randomType = rewardTypes[level % rewardTypes.length];
        
        return rewards[passType][randomType];
    }
    
    getRewardIcon(reward) {
        return reward.icon || '🎁';
    }
    
    initializeDailyRewards() {
        const dailyGrid = document.getElementById('dailyGrid');
        if (!dailyGrid) return;
        
        dailyGrid.innerHTML = '';
        
        const dailyRewards = [
            { name: '2.000€ Bargeld', icon: '💰' },
            { name: '5x Erste-Hilfe', icon: '🏥' },
            { name: '3x Köder + 1.000€', icon: '🎣' },
            { name: 'Waffenaufsatz', icon: '🔧' },
            { name: '5.000€ Bank', icon: '🏦' },
            { name: 'Premium Box', icon: '📦' },
            { name: 'MEGA Bonus', icon: '🎊' }
        ];
        
        dailyRewards.forEach((reward, index) => {
            const day = index + 1;
            const currentStreak = this.playerData.daily_streak || 0;
            
            const rewardEl = document.createElement('div');
            rewardEl.className = 'daily-reward';
            
            if (currentStreak === day) {
                rewardEl.classList.add('current');
            } else if (currentStreak > day) {
                rewardEl.classList.add('claimed');
            } else {
                rewardEl.classList.add('future');
            }
            
            rewardEl.innerHTML = `
                <div class="daily-day">Tag ${day}</div>
                <div class="daily-reward-icon">${reward.icon}</div>
                <div class="daily-reward-name">${reward.name}</div>
            `;
            
            dailyGrid.appendChild(rewardEl);
        });
    }
    
    initializeMissions() {
        this.populateMissions();
    }
    
    populateRewards() {
        // This will be called when player data is updated
        // Rewards are already populated in initializeRewardTracks
        this.updateRewardAvailability();
    }
    
    populateDailyRewards() {
        // Already handled in initializeDailyRewards
        this.updateDailyRewardButton();
    }
    
    populateMissions(missions = []) {
        const dailyGrid = document.getElementById('dailyMissionsGrid');
        const weeklyGrid = document.getElementById('weeklyMissionsGrid');
        
        if (!dailyGrid || !weeklyGrid) return;
        
        dailyGrid.innerHTML = '';
        weeklyGrid.innerHTML = '';
        
        // Example missions if none provided
        if (missions.length === 0) {
            missions = [
                {
                    id: 'playtime_60',
                    name: 'Spiele 60 Minuten',
                    description: 'Verbringe 60 Minuten auf dem Server',
                    progress: 35,
                    target: 60,
                    xpReward: 500,
                    type: 'daily',
                    completed: false
                },
                {
                    id: 'catch_fish_10',
                    name: 'Fange 10 Fische',
                    description: 'Fange 10 Fische beim Angeln',
                    progress: 7,
                    target: 10,
                    xpReward: 300,
                    type: 'daily',
                    completed: false
                },
                {
                    id: 'win_races_5',
                    name: 'Gewinne 5 Rennen',
                    description: 'Gewinne 5 Rennen in verschiedenen Kategorien',
                    progress: 2,
                    target: 5,
                    xpReward: 2000,
                    type: 'weekly',
                    completed: false
                }
            ];
        }
        
        missions.forEach(mission => {
            const missionCard = this.createMissionCard(mission);
            
            if (mission.type === 'daily') {
                dailyGrid.appendChild(missionCard);
            } else if (mission.type === 'weekly') {
                weeklyGrid.appendChild(missionCard);
            }
        });
    }
    
    createMissionCard(mission) {
        const card = document.createElement('div');
        card.className = 'mission-card';
        card.dataset.missionId = mission.id;
        
        if (mission.completed) {
            card.classList.add('completed');
        }
        
        const progressPercentage = Math.min((mission.progress / mission.target) * 100, 100);
        const missionIcon = this.getMissionIcon(mission.id);
        
        card.innerHTML = `
            <div class="mission-header">
                <div class="mission-icon">${missionIcon}</div>
                <div class="mission-info">
                    <div class="mission-name">${mission.name}</div>
                    <div class="mission-description">${mission.description}</div>
                </div>
            </div>
            <div class="mission-progress">
                <div class="progress-bar">
                    <div class="progress-fill" style="width: ${progressPercentage}%"></div>
                </div>
                <div class="progress-text">
                    <span class="progress-current">${mission.progress}</span>
                    <span class="progress-target">/ ${mission.target}</span>
                </div>
            </div>
            <div class="mission-reward">
                <span class="reward-xp">+${mission.xpReward} XP</span>
                ${mission.completed && !mission.claimed ? '<button class="claim-mission-btn">Belohnung einfordern</button>' : ''}
            </div>
        `;
        
        // Add claim functionality
        const claimBtn = card.querySelector('.claim-mission-btn');
        if (claimBtn) {
            claimBtn.addEventListener('click', () => {
                this.claimMissionReward(mission.id);
            });
        }
        
        return card;
    }
    
    getMissionIcon(missionId) {
        const icons = {
            playtime_60: '⏱️',
            catch_fish_10: '🎣',
            drive_25km: '🚗',
            earn_10000: '💰',
            win_races_5: '🏁',
            complete_jobs_15: '💼',
            farm_drugs_50: '🌿',
            kill_npcs_25: '⚔️'
        };
        
        return icons[missionId] || '🎯';
    }
    
    updateRewardAvailability() {
        const rewardItems = document.querySelectorAll('.reward-item');
        
        rewardItems.forEach(item => {
            const level = parseInt(item.dataset.level);
            const passType = item.dataset.passType;
            
            const isUnlocked = (this.playerData.level || 1) >= level;
            const isPremiumRequired = passType === 'premium';
            const hasPremium = this.playerData.premium && 
                              this.playerData.premium_expires && 
                              Date.now() / 1000 < this.playerData.premium_expires;
            
            // Remove existing classes
            item.classList.remove('unlocked', 'claimed', 'locked');
            
            if (isUnlocked && (!isPremiumRequired || hasPremium)) {
                item.classList.add('unlocked');
            } else {
                item.classList.add('locked');
            }
        });
    }
    
    updateDailyRewardButton() {
        const claimBtn = document.getElementById('claimDailyBtn');
        if (!claimBtn) return;
        
        const lastClaim = this.playerData.last_daily_claim;
        const now = Date.now() / 1000;
        const oneDayInSeconds = 24 * 60 * 60;
        
        const canClaim = !lastClaim || (now - lastClaim) >= oneDayInSeconds;
        
        claimBtn.disabled = !canClaim;
        claimBtn.textContent = canClaim ? 
            'Tägliche Belohnung einfordern' : 
            'Bereits eingefordert';
    }
    
    startTimers() {
        // Update timers every second
        setInterval(() => {
            this.updateNextRewardTimer();
            this.updateMissionRefreshTimer();
        }, 1000);
    }
    
    updateNextRewardTimer() {
        const timerEl = document.getElementById('nextRewardTimer');
        if (!timerEl) return;
        
        const lastClaim = this.playerData.last_daily_claim;
        if (!lastClaim) {
            timerEl.textContent = '00:00:00';
            return;
        }
        
        const nextClaimTime = lastClaim + (24 * 60 * 60);
        const now = Date.now() / 1000;
        const timeLeft = Math.max(0, nextClaimTime - now);
        
        if (timeLeft === 0) {
            timerEl.textContent = '00:00:00';
        } else {
            const hours = Math.floor(timeLeft / 3600);
            const minutes = Math.floor((timeLeft % 3600) / 60);
            const seconds = Math.floor(timeLeft % 60);
            
            timerEl.textContent = 
                `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
        }
    }
    
    updateMissionRefreshTimer() {
        const timerEl = document.getElementById('missionRefreshTimer');
        if (!timerEl) return;
        
        // Calculate time until next daily reset (midnight)
        const now = new Date();
        const tomorrow = new Date(now);
        tomorrow.setDate(tomorrow.getDate() + 1);
        tomorrow.setHours(0, 0, 0, 0);
        
        const timeLeft = Math.max(0, (tomorrow.getTime() - now.getTime()) / 1000);
        
        const hours = Math.floor(timeLeft / 3600);
        const minutes = Math.floor((timeLeft % 3600) / 60);
        const seconds = Math.floor(timeLeft % 60);
        
        timerEl.textContent = 
            `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
    }
    
    // Action methods
    buyPremium() {
        this.sendNUIMessage('performAction', {
            action: 'buyPremium',
            params: {}
        });
    }
    
    claimDailyReward() {
        this.sendNUIMessage('performAction', {
            action: 'claimDailyReward',
            params: {}
        });
    }
    
    claimLevelReward(level, passType) {
        this.sendNUIMessage('performAction', {
            action: 'claimLevelReward',
            params: { level, passType }
        });
    }
    
    claimMissionReward(missionId) {
        this.sendNUIMessage('performAction', {
            action: 'claimMissionReward',
            params: { missionId }
        });
    }
    
    openLootBox(boxType) {
        this.sendNUIMessage('performAction', {
            action: 'openLootBox',
            params: { boxType }
        });
    }
    
    // Animation and effects
    showNotification(message, type = 'info', duration = 5000) {
        const container = document.getElementById('notificationContainer');
        if (!container) return;
        
        const notification = document.createElement('div');
        notification.className = `notification ${type}`;
        notification.textContent = message;
        
        container.appendChild(notification);
        
        if (this.animationsEnabled) {
            notification.style.animation = 'slideInRight 0.3s ease-out';
        }
        
        setTimeout(() => {
            if (this.animationsEnabled) {
                notification.style.animation = 'slideOutRight 0.3s ease-out';
                setTimeout(() => notification.remove(), 300);
            } else {
                notification.remove();
            }
        }, duration);
    }
    
    showXPGain(amount, reason) {
        const overlay = document.getElementById('xpGainOverlay');
        if (!overlay) return;
        
        overlay.querySelector('.xp-amount').textContent = `+${amount} XP`;
        overlay.querySelector('.xp-reason').textContent = reason || '';
        
        overlay.classList.remove('hidden');
        
        setTimeout(() => {
            overlay.classList.add('hidden');
        }, 3000);
    }
    
    showLevelUp(newLevel, oldLevel) {
        const overlay = document.getElementById('levelUpOverlay');
        if (!overlay) return;
        
        overlay.querySelector('.old-level').textContent = oldLevel;
        overlay.querySelector('.new-level').textContent = newLevel;
        
        overlay.classList.remove('hidden');
        
        setTimeout(() => {
            overlay.classList.add('hidden');
        }, 5000);
    }
    
    showRewardAnimation(reward) {
        const overlay = document.getElementById('rewardOverlay');
        if (!overlay) return;
        
        const img = overlay.querySelector('#rewardImage');
        const title = overlay.querySelector('#rewardTitle');
        const desc = overlay.querySelector('#rewardDescription');
        
        img.src = reward.image || 'assets/images/reward-default.png';
        title.textContent = reward.title || 'Belohnung erhalten!';
        desc.textContent = reward.description || 'Du hast eine Belohnung erhalten';
        
        overlay.classList.remove('hidden');
        
        setTimeout(() => {
            overlay.classList.add('hidden');
        }, 3000);
    }
    
    showLootBoxOpening(boxType, reward) {
        const overlay = document.getElementById('lootboxOverlay');
        if (!overlay) return;
        
        const rewardEl = document.getElementById('lootboxReward');
        const rewardImg = document.getElementById('lootboxRewardImage');
        const rewardTitle = document.getElementById('lootboxRewardTitle');
        
        overlay.classList.remove('hidden');
        rewardEl.classList.add('hidden');
        
        // Show opening animation
        setTimeout(() => {
            rewardEl.classList.remove('hidden');
            rewardImg.src = reward.image || 'assets/images/reward-default.png';
            rewardTitle.textContent = reward.title || reward.label || 'Belohnung!';
        }, 2000);
        
        // Hide after showing reward
        setTimeout(() => {
            overlay.classList.add('hidden');
        }, 5000);
    }
    
    // Event handlers
    handleDailyRewardClaimed(data) {
        this.playerData.daily_streak = data.streak;
        this.playerData.last_daily_claim = Date.now() / 1000;
        
        this.initializeDailyRewards();
        this.updateDailyRewardButton();
        this.updatePlayerDisplay();
        
        this.showNotification(`Tag ${data.streak} Belohnung eingefordert!`, 'success');
    }
    
    handlePremiumActivated(data) {
        this.playerData.premium = true;
        this.playerData.premium_expires = data.expires;
        
        this.updatePlayerDisplay();
        this.updateRewardAvailability();
        
        this.showNotification('Premium Pass aktiviert!', 'success');
    }
    
    handleMissionCompleted(data) {
        this.showNotification(`Mission "${data.config.label}" abgeschlossen!`, 'success');
        this.populateMissions(); // Refresh missions display
    }
    
    updateMissions(missions) {
        this.populateMissions(missions);
    }
    
    updateTheme(theme) {
        // Apply theme colors to CSS variables
        const root = document.documentElement;
        
        Object.entries(theme).forEach(([key, value]) => {
            root.style.setProperty(`--theme-${key}`, value);
        });
    }
    
    toggleDebugPanel() {
        const panel = document.getElementById('debugPanel');
        if (!panel) return;
        
        if (this.debugMode) {
            panel.classList.remove('hidden');
            this.updateDebugInfo();
        } else {
            panel.classList.add('hidden');
        }
    }
    
    showDebugInfo(data) {
        const playerDataEl = document.getElementById('debugPlayerData');
        const missionDataEl = document.getElementById('debugMissionData');
        const systemInfoEl = document.getElementById('debugSystemInfo');
        
        if (playerDataEl) {
            playerDataEl.textContent = JSON.stringify(data.data || {}, null, 2);
        }
        
        if (systemInfoEl) {
            const systemInfo = {
                currentTab: this.currentTab,
                animationsEnabled: this.animationsEnabled,
                isVisible: this.isVisible,
                timestamp: new Date().toISOString()
            };
            systemInfoEl.textContent = JSON.stringify(systemInfo, null, 2);
        }
        
        document.getElementById('debugPanel').classList.remove('hidden');
    }
    
    updateDebugInfo() {
        const playerDataEl = document.getElementById('debugPlayerData');
        const systemInfoEl = document.getElementById('debugSystemInfo');
        
        if (playerDataEl) {
            playerDataEl.textContent = JSON.stringify(this.playerData, null, 2);
        }
        
        if (systemInfoEl) {
            const systemInfo = {
                currentTab: this.currentTab,
                animationsEnabled: this.animationsEnabled,
                isVisible: this.isVisible,
                timestamp: new Date().toISOString()
            };
            systemInfoEl.textContent = JSON.stringify(systemInfo, null, 2);
        }
    }
    
    // Utility methods
    sendNUIMessage(type, data = {}) {
        fetch(`https://${GetParentResourceName()}/${type}`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json; charset=UTF-8'
            },
            body: JSON.stringify(data)
        });
    }
    
    playSound(sound, set = 'HUD_FRONTEND_DEFAULT_SOUNDSET') {
        this.sendNUIMessage('playSound', { sound, set });
    }
}

// Initialize the app when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    window.battlepassApp = new BattlepassApp();
});

// Global helper function for resource name
function GetParentResourceName() {
    return 'jr_battlepassv2';
}