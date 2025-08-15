// JR.DEV Battlepass - Main Application JavaScript

// Global variables
let playerData = {
    level: 1,
    xp: 0,
    premium: false,
    seasonName: "Season 1: Urban Legends"
};

let missions = {
    daily: [],
    weekly: []
};

let currentTab = 'overview';
let soundEnabled = true;

// DOM Elements
const app = document.getElementById('app');
const closeBtn = document.getElementById('closeBtn');
const navBtns = document.querySelectorAll('.nav-btn');
const tabContents = document.querySelectorAll('.tab-content');
const premiumUpgrade = document.getElementById('premiumUpgrade');
const buyPremiumBtn = document.getElementById('buyPremiumBtn');

// Initialize application
document.addEventListener('DOMContentLoaded', function() {
    initializeEventListeners();
    requestInitialData();
});

// Event Listeners
function initializeEventListeners() {
    // Close button
    closeBtn.addEventListener('click', closeBattlepass);
    
    // Navigation
    navBtns.forEach(btn => {
        btn.addEventListener('click', function() {
            const tab = this.getAttribute('data-tab');
            switchTab(tab);
            playSound('click');
        });
    });
    
    // Premium purchase
    if (buyPremiumBtn) {
        buyPremiumBtn.addEventListener('click', function() {
            purchasePremium();
            playSound('click');
        });
    }
    
    // Keyboard shortcuts
    document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape') {
            closeBattlepass();
        }
    });
}

// Tab switching
function switchTab(tabName) {
    currentTab = tabName;
    
    // Update navigation
    navBtns.forEach(btn => {
        btn.classList.remove('active');
        if (btn.getAttribute('data-tab') === tabName) {
            btn.classList.add('active');
        }
    });
    
    // Update content
    tabContents.forEach(content => {
        content.classList.remove('active');
        if (content.id === tabName) {
            content.classList.add('active');
        }
    });
    
    // Load tab-specific data
    loadTabData(tabName);
}

// Load tab-specific data
function loadTabData(tabName) {
    switch(tabName) {
        case 'overview':
            generateLevelTrack();
            break;
        case 'missions':
            loadMissions();
            break;
        case 'daily':
            loadDailyRewards();
            break;
        case 'lootboxes':
            loadLootboxes();
            break;
        case 'stats':
            loadStatistics();
            break;
    }
}

// Generate level track
function generateLevelTrack() {
    const trackLevels = document.getElementById('trackLevels');
    if (!trackLevels) return;
    
    trackLevels.innerHTML = '';
    
    const visibleLevels = Math.min(20, 100); // Show first 20 levels or up to max
    
    for (let level = 1; level <= visibleLevels; level++) {
        const levelItem = document.createElement('div');
        levelItem.className = 'level-item';
        
        let circleClass = 'locked';
        if (level <= playerData.level) {
            circleClass = 'unlocked';
        }
        if (level === playerData.level) {
            circleClass = 'current';
        }
        
        levelItem.innerHTML = `
            <div class="level-circle ${circleClass}" onclick="showLevelRewards(${level})">
                ${level}
            </div>
            <div class="level-reward" id="level-reward-${level}">
                Level ${level}
            </div>
        `;
        
        trackLevels.appendChild(levelItem);
    }
    
    // Update premium visibility
    updatePremiumUpgrade();
}

// Update premium upgrade section
function updatePremiumUpgrade() {
    if (!premiumUpgrade) return;
    
    if (playerData.premium) {
        premiumUpgrade.style.display = 'none';
    } else {
        premiumUpgrade.style.display = 'block';
    }
}

// Show level rewards
function showLevelRewards(level) {
    fetch(`https://jr_battlepassv2/requestLevelRewards`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({
            level: level
        })
    })
    .then(response => response.json())
    .then(data => {
        if (data.free || data.premium) {
            showLevelRewardModal(level, data);
        }
    })
    .catch(error => {
        console.error('Error requesting level rewards:', error);
    });
}

// Show level reward modal
function showLevelRewardModal(level, rewards) {
    const modal = document.createElement('div');
    modal.className = 'modal show';
    modal.id = 'levelRewardModal';
    
    const freeReward = rewards.free ? `
        <div class="reward-section">
            <h4>Free Track</h4>
            <div class="reward-item">
                ${formatReward(rewards.free)}
                <button class="reward-claim-btn" onclick="claimReward('free', ${level})" ${playerData.level >= level ? '' : 'disabled'}>
                    ${playerData.level >= level ? 'Claim' : 'Locked'}
                </button>
            </div>
        </div>
    ` : '';
    
    const premiumReward = rewards.premium ? `
        <div class="reward-section">
            <h4>Premium Track</h4>
            <div class="reward-item premium">
                ${formatReward(rewards.premium)}
                <button class="reward-claim-btn premium" onclick="claimReward('premium', ${level})" ${(playerData.level >= level && playerData.premium) ? '' : 'disabled'}>
                    ${(playerData.level >= level && playerData.premium) ? 'Claim' : (playerData.premium ? 'Locked' : 'Premium Required')}
                </button>
            </div>
        </div>
    ` : '';
    
    modal.innerHTML = `
        <div class="modal-content">
            <h3>Level ${level} Rewards</h3>
            ${freeReward}
            ${premiumReward}
            <button class="modal-btn" onclick="closeLevelRewardModal()">Close</button>
        </div>
    `;
    
    document.body.appendChild(modal);
}

// Format reward display
function formatReward(reward) {
    switch(reward.type) {
        case 'money':
            return `<i class="fas fa-coins"></i> €${reward.amount}`;
        case 'bank':
            return `<i class="fas fa-university"></i> €${reward.amount} Bank`;
        case 'item':
            return `<i class="fas fa-box"></i> ${reward.amount}x ${reward.item}`;
        case 'vehicle':
            return `<i class="fas fa-car"></i> ${reward.label || reward.model}`;
        case 'lootbox':
            return `<i class="fas fa-treasure-chest"></i> ${reward.label}`;
        case 'xp':
            return `<i class="fas fa-star"></i> ${reward.amount} XP`;
        default:
            return reward.label || 'Unknown Reward';
    }
}

// Close level reward modal
function closeLevelRewardModal() {
    const modal = document.getElementById('levelRewardModal');
    if (modal) {
        modal.remove();
    }
}

// Claim reward
function claimReward(type, level) {
    fetch(`https://jr_battlepassv2/claimReward`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({
            type: type,
            level: level
        })
    })
    .then(response => response.json())
    .then(data => {
        if (data === 'ok') {
            showNotification('Reward claimed!', 'success');
            closeLevelRewardModal();
            playSound('reward');
        }
    })
    .catch(error => {
        console.error('Error claiming reward:', error);
        showNotification('Failed to claim reward', 'error');
    });
}

// Load missions
function loadMissions() {
    const dailyMissions = document.getElementById('dailyMissions');
    const weeklyMissions = document.getElementById('weeklyMissions');
    
    if (dailyMissions) {
        dailyMissions.innerHTML = '';
        missions.daily.forEach(mission => {
            dailyMissions.appendChild(createMissionCard(mission, 'daily'));
        });
    }
    
    if (weeklyMissions) {
        weeklyMissions.innerHTML = '';
        missions.weekly.forEach(mission => {
            weeklyMissions.appendChild(createMissionCard(mission, 'weekly'));
        });
    }
    
    updateMissionTimers();
}

// Create mission card
function createMissionCard(mission, type) {
    const card = document.createElement('div');
    card.className = `mission-card ${mission.completed ? 'completed' : ''}`;
    
    const progressPercent = Math.min((mission.progress / mission.target) * 100, 100);
    const canClaim = mission.completed && !mission.claimed;
    
    card.innerHTML = `
        <div class="mission-header">
            <div>
                <div class="mission-title">${mission.label}</div>
                <div class="mission-description">${mission.description}</div>
            </div>
            <div class="mission-reward">
                ${formatMissionReward(mission.reward)}
            </div>
        </div>
        <div class="mission-progress">
            <div class="mission-progress-bar">
                <div class="mission-progress-fill" style="width: ${progressPercent}%"></div>
            </div>
            <div class="mission-progress-text">
                <span>${mission.progress}/${mission.target}</span>
                <span>${Math.round(progressPercent)}%</span>
            </div>
        </div>
        <button class="mission-claim" onclick="claimMissionReward('${mission.id}')" ${canClaim ? '' : 'disabled'}>
            ${mission.claimed ? 'Claimed' : (mission.completed ? 'Claim Reward' : 'In Progress')}
        </button>
    `;
    
    return card;
}

// Format mission reward
function formatMissionReward(reward) {
    let rewardText = '';
    if (reward.xp) rewardText += `+${reward.xp} XP `;
    if (reward.money) rewardText += `+€${reward.money} `;
    if (reward.items) {
        reward.items.forEach(item => {
            rewardText += `+${item.amount}x ${item.item} `;
        });
    }
    return rewardText.trim();
}

// Claim mission reward
function claimMissionReward(missionId) {
    fetch(`https://jr_battlepassv2/claimMissionReward`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({
            missionId: missionId
        })
    })
    .then(response => response.json())
    .then(data => {
        if (data === 'ok') {
            showNotification('Mission reward claimed!', 'success');
            loadMissions(); // Refresh missions
            playSound('reward');
        }
    })
    .catch(error => {
        console.error('Error claiming mission reward:', error);
        showNotification('Failed to claim mission reward', 'error');
    });
}

// Load daily rewards
function loadDailyRewards() {
    const dailyRewardsGrid = document.getElementById('dailyRewardsGrid');
    if (!dailyRewardsGrid) return;
    
    dailyRewardsGrid.innerHTML = '';
    
    for (let day = 1; day <= 7; day++) {
        const card = document.createElement('div');
        card.className = `daily-reward-card ${day === 7 ? 'mega' : ''}`;
        
        card.innerHTML = `
            <div class="daily-day">Day ${day}</div>
            <div class="daily-reward-icon">
                ${getDailyRewardIcon(day)}
            </div>
            <div class="daily-reward-label">
                ${getDailyRewardLabel(day)}
            </div>
            <button class="daily-claim-btn" onclick="claimDailyReward()" id="dailyClaimBtn-${day}">
                Claim
            </button>
        `;
        
        dailyRewardsGrid.appendChild(card);
    }
    
    updateDailyRewardStatus();
}

// Get daily reward icon
function getDailyRewardIcon(day) {
    const icons = {
        1: '<i class="fas fa-coins"></i>',
        2: '<i class="fas fa-medkit"></i>',
        3: '<i class="fas fa-fish"></i>',
        4: '<i class="fas fa-wrench"></i>',
        5: '<i class="fas fa-university"></i>',
        6: '<i class="fas fa-treasure-chest"></i>',
        7: '<i class="fas fa-crown"></i>'
    };
    return icons[day] || '<i class="fas fa-gift"></i>';
}

// Get daily reward label
function getDailyRewardLabel(day) {
    const labels = {
        1: '€2,000 Cash',
        2: '5x First Aid Kit',
        3: '3x Fishing Bait + €1,000',
        4: 'Random Weapon Attachment',
        5: '€5,000 Bank Money',
        6: 'Premium Loot Box',
        7: 'MEGA Bonus: €15,000 + Rare Item'
    };
    return labels[day] || 'Mystery Reward';
}

// Update daily reward status
function updateDailyRewardStatus() {
    // This would be updated by server data
    // For now, just enable day 1 as an example
    const claimBtn = document.getElementById('dailyClaimBtn-1');
    if (claimBtn) {
        claimBtn.disabled = false;
    }
}

// Claim daily reward
function claimDailyReward() {
    fetch(`https://jr_battlepassv2/claimDailyReward`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({})
    })
    .then(response => response.json())
    .then(data => {
        if (data === 'ok') {
            showNotification('Daily reward claimed!', 'success');
            loadDailyRewards(); // Refresh daily rewards
            playSound('reward');
        }
    })
    .catch(error => {
        console.error('Error claiming daily reward:', error);
        showNotification('Failed to claim daily reward', 'error');
    });
}

// Load loot boxes
function loadLootboxes() {
    const lootboxesGrid = document.getElementById('lootboxesGrid');
    if (!lootboxesGrid) return;
    
    const lootboxTypes = [
        {
            type: 'basic',
            name: 'Basic Loot Box',
            description: 'Contains common items and small amounts of money',
            icon: '<i class="fas fa-box"></i>',
            available: true
        },
        {
            type: 'premium',
            name: 'Premium Loot Box',
            description: 'Contains rare items and weapons',
            icon: '<i class="fas fa-treasure-chest"></i>',
            available: playerData.premium
        },
        {
            type: 'legendary',
            name: 'Legendary Loot Box',
            description: 'Contains the rarest and most valuable items',
            icon: '<i class="fas fa-crown"></i>',
            available: playerData.premium && playerData.level >= 25
        }
    ];
    
    lootboxesGrid.innerHTML = '';
    
    lootboxTypes.forEach(lootbox => {
        const card = document.createElement('div');
        card.className = `lootbox-card ${lootbox.type}`;
        
        card.innerHTML = `
            <div class="lootbox-icon">${lootbox.icon}</div>
            <div class="lootbox-name">${lootbox.name}</div>
            <div class="lootbox-description">${lootbox.description}</div>
            <button class="lootbox-open-btn" onclick="openLootbox('${lootbox.type}')" ${lootbox.available ? '' : 'disabled'}>
                ${lootbox.available ? 'Open Loot Box' : 'Unavailable'}
            </button>
        `;
        
        lootboxesGrid.appendChild(card);
    });
}

// Open loot box
function openLootbox(boxType) {
    showLootboxModal(boxType);
    
    fetch(`https://jr_battlepassv2/openLootbox`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({
            boxType: boxType
        })
    })
    .then(response => response.json())
    .then(data => {
        if (data === 'ok') {
            // The server will send loot box results via event
            playSound('lootbox');
        } else {
            closeLootboxModal();
            showNotification('Failed to open loot box', 'error');
        }
    })
    .catch(error => {
        console.error('Error opening loot box:', error);
        closeLootboxModal();
        showNotification('Failed to open loot box', 'error');
    });
}

// Show loot box modal
function showLootboxModal(boxType) {
    const modal = document.getElementById('lootboxModal');
    if (modal) {
        modal.classList.add('show');
        
        // Reset modal state
        const animation = document.getElementById('lootboxAnimation');
        const results = document.getElementById('lootboxResults');
        
        if (animation) animation.classList.remove('hidden');
        if (results) results.classList.add('hidden');
        
        // Start opening animation
        setTimeout(() => {
            triggerLootboxAnimation(boxType);
        }, 2000);
    }
}

// Trigger loot box animation
function triggerLootboxAnimation(boxType) {
    const animation = document.getElementById('lootboxAnimation');
    const results = document.getElementById('lootboxResults');
    
    if (animation && results) {
        animation.classList.add('hidden');
        results.classList.remove('hidden');
    }
}

// Close loot box modal
function closeLootboxModal() {
    const modal = document.getElementById('lootboxModal');
    if (modal) {
        modal.classList.remove('show');
    }
}

// Load statistics
function loadStatistics() {
    const statsGrid = document.getElementById('statsGrid');
    if (!statsGrid) return;
    
    const stats = [
        { icon: 'fas fa-trophy', value: `#${Math.floor(Math.random() * 100) + 1}`, label: 'Your Rank' },
        { icon: 'fas fa-star', value: playerData.xp.toLocaleString(), label: 'Total XP' },
        { icon: 'fas fa-tasks', value: Math.floor(Math.random() * 50) + 10, label: 'Missions Completed' },
        { icon: 'fas fa-gift', value: Math.floor(Math.random() * 20) + 5, label: 'Rewards Claimed' },
        { icon: 'fas fa-calendar', value: Math.floor(Math.random() * 30) + 1, label: 'Days Active' },
        { icon: 'fas fa-users', value: Math.floor(Math.random() * 1000) + 500, label: 'Total Players' }
    ];
    
    statsGrid.innerHTML = '';
    
    stats.forEach(stat => {
        const card = document.createElement('div');
        card.className = 'stat-card';
        
        card.innerHTML = `
            <div class="stat-icon"><i class="${stat.icon}"></i></div>
            <div class="stat-value">${stat.value}</div>
            <div class="stat-label">${stat.label}</div>
        `;
        
        statsGrid.appendChild(card);
    });
    
    loadLeaderboard();
}

// Load leaderboard
function loadLeaderboard() {
    const leaderboard = document.getElementById('leaderboard');
    if (!leaderboard) return;
    
    // Mock leaderboard data
    const players = [
        { rank: 1, name: 'Player1', level: 87, xp: 245000 },
        { rank: 2, name: 'Player2', level: 82, xp: 220000 },
        { rank: 3, name: 'Player3', level: 79, xp: 205000 },
        { rank: 4, name: 'Player4', level: 76, xp: 190000 },
        { rank: 5, name: 'Player5', level: 73, xp: 175000 }
    ];
    
    leaderboard.innerHTML = '';
    
    players.forEach(player => {
        const item = document.createElement('div');
        item.className = 'leaderboard-item';
        
        item.innerHTML = `
            <div class="leaderboard-rank">#${player.rank}</div>
            <div class="leaderboard-name">${player.name}</div>
            <div class="leaderboard-level">Level ${player.level}</div>
            <div class="leaderboard-xp">${player.xp.toLocaleString()} XP</div>
        `;
        
        leaderboard.appendChild(item);
    });
}

// Purchase premium
function purchasePremium() {
    fetch(`https://jr_battlepassv2/buyPremium`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({})
    })
    .then(response => response.json())
    .then(data => {
        if (data === 'ok') {
            showNotification('Premium purchased successfully!', 'success');
            playerData.premium = true;
            updatePremiumStatus();
            playSound('reward');
        }
    })
    .catch(error => {
        console.error('Error purchasing premium:', error);
        showNotification('Failed to purchase premium', 'error');
    });
}

// Update premium status display
function updatePremiumStatus() {
    const premiumStatus = document.getElementById('premiumStatus');
    if (premiumStatus) {
        if (playerData.premium) {
            premiumStatus.innerHTML = '<i class="fas fa-crown"></i> <span>PREMIUM</span>';
            premiumStatus.className = 'premium-status premium';
        } else {
            premiumStatus.innerHTML = '<i class="fas fa-gem"></i> <span>FREE</span>';
            premiumStatus.className = 'premium-status free';
        }
    }
    
    updatePremiumUpgrade();
}

// Update mission timers
function updateMissionTimers() {
    const dailyReset = document.getElementById('dailyReset');
    const weeklyReset = document.getElementById('weeklyReset');
    
    if (dailyReset) {
        // Calculate time until next daily reset (next midnight)
        const now = new Date();
        const tomorrow = new Date(now);
        tomorrow.setDate(now.getDate() + 1);
        tomorrow.setHours(0, 0, 0, 0);
        
        const timeLeft = tomorrow - now;
        dailyReset.textContent = `Resets in ${formatTime(timeLeft)}`;
    }
    
    if (weeklyReset) {
        // Calculate time until next weekly reset (next Sunday)
        const now = new Date();
        const nextSunday = new Date(now);
        const daysUntilSunday = 7 - now.getDay();
        nextSunday.setDate(now.getDate() + daysUntilSunday);
        nextSunday.setHours(0, 0, 0, 0);
        
        const timeLeft = nextSunday - now;
        weeklyReset.textContent = `Resets in ${formatTime(timeLeft)}`;
    }
}

// Format time duration
function formatTime(milliseconds) {
    const seconds = Math.floor(milliseconds / 1000);
    const minutes = Math.floor(seconds / 60);
    const hours = Math.floor(minutes / 60);
    const days = Math.floor(hours / 24);
    
    if (days > 0) {
        return `${days}d ${hours % 24}:${String(minutes % 60).padStart(2, '0')}:${String(seconds % 60).padStart(2, '0')}`;
    } else {
        return `${String(hours).padStart(2, '0')}:${String(minutes % 60).padStart(2, '0')}:${String(seconds % 60).padStart(2, '0')}`;
    }
}

// Show notification
function showNotification(message, type = 'info') {
    const container = document.getElementById('notificationContainer');
    if (!container) return;
    
    const notification = document.createElement('div');
    notification.className = `notification ${type}`;
    notification.textContent = message;
    
    container.appendChild(notification);
    
    // Auto remove after 5 seconds
    setTimeout(() => {
        if (notification.parentNode) {
            notification.parentNode.removeChild(notification);
        }
    }, 5000);
}

// Play sound
function playSound(soundType) {
    if (!soundEnabled) return;
    
    fetch(`https://jr_battlepassv2/playSound`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({
            sound: soundType
        })
    })
    .catch(() => {}); // Ignore errors
}

// Close battlepass
function closeBattlepass() {
    fetch(`https://jr_battlepassv2/closeBattlepass`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({})
    })
    .then(() => {
        app.style.display = 'none';
    })
    .catch(error => {
        console.error('Error closing battlepass:', error);
        app.style.display = 'none';
    });
}

// Request initial data from server
function requestInitialData() {
    fetch(`https://jr_battlepassv2/requestData`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({})
    })
    .catch(error => {
        console.error('Error requesting initial data:', error);
    });
}

// Update player data display
function updatePlayerData(data) {
    if (data.level) {
        playerData.level = data.level;
        const levelElement = document.getElementById('playerLevel');
        if (levelElement) levelElement.textContent = data.level;
    }
    
    if (typeof data.xp !== 'undefined') {
        playerData.xp = data.xp;
        updateXPBar(data.xp, data.xpNeeded || 1000);
    }
    
    if (typeof data.premium !== 'undefined') {
        playerData.premium = data.premium;
        updatePremiumStatus();
    }
    
    if (data.seasonName) {
        playerData.seasonName = data.seasonName;
        const seasonElement = document.getElementById('seasonName');
        if (seasonElement) seasonElement.textContent = data.seasonName;
    }
}

// Update XP bar
function updateXPBar(currentXP, neededXP) {
    const xpBar = document.getElementById('xpBar');
    const xpText = document.getElementById('xpText');
    
    if (xpBar && xpText) {
        const percentage = (currentXP / neededXP) * 100;
        xpBar.style.width = `${Math.min(percentage, 100)}%`;
        xpText.textContent = `${currentXP.toLocaleString()} / ${neededXP.toLocaleString()} XP`;
    }
}

// Handle NUI messages from client
window.addEventListener('message', function(event) {
    const data = event.data;
    
    switch(data.type) {
        case 'openBattlepass':
            app.style.display = 'block';
            updatePlayerData(data.data);
            loadTabData(currentTab);
            break;
            
        case 'closeBattlepass':
            app.style.display = 'none';
            break;
            
        case 'updatePlayerData':
            updatePlayerData(data.data);
            break;
            
        case 'updateXP':
            updateXPBar(data.xp, data.xpNeeded);
            if (currentTab === 'overview') {
                generateLevelTrack();
            }
            break;
            
        case 'levelUp':
            showLevelUpModal(data.level);
            break;
            
        case 'updateMissions':
            missions = data.missions;
            if (currentTab === 'missions') {
                loadMissions();
            }
            break;
            
        case 'showLootboxRewards':
            showLootboxResults(data.rewards);
            break;
            
        case 'premiumActivated':
            playerData.premium = true;
            updatePremiumStatus();
            showNotification('Premium activated!', 'success');
            break;
            
        case 'missionCompleted':
            showNotification(`Mission completed: ${data.mission.label}`, 'success');
            if (currentTab === 'missions') {
                loadMissions();
            }
            break;
            
        case 'updateDailyReward':
            // Update daily reward display
            break;
    }
});

// Show level up modal
function showLevelUpModal(level) {
    const modal = document.getElementById('levelUpModal');
    const newLevelSpan = document.getElementById('newLevel');
    
    if (modal && newLevelSpan) {
        newLevelSpan.textContent = level;
        modal.classList.add('show');
        playSound('levelup');
        
        // Trigger celebration animation
        triggerLevelUpAnimation();
    }
}

// Close level up modal
function closeLevelUpModal() {
    const modal = document.getElementById('levelUpModal');
    if (modal) {
        modal.classList.remove('show');
    }
}

// Show loot box results
function showLootboxResults(rewards) {
    const lootboxRewards = document.getElementById('lootboxRewards');
    const animation = document.getElementById('lootboxAnimation');
    const results = document.getElementById('lootboxResults');
    
    if (lootboxRewards && animation && results) {
        lootboxRewards.innerHTML = '';
        
        rewards.forEach(reward => {
            const item = document.createElement('div');
            item.className = `lootbox-reward-item ${reward.rarity || 'common'}`;
            item.textContent = reward.label;
            lootboxRewards.appendChild(item);
        });
        
        animation.classList.add('hidden');
        results.classList.remove('hidden');
        
        playSound('reward');
    }
}

// Start timer updates
setInterval(updateMissionTimers, 1000);

// Export functions for global access
window.closeLevelUpModal = closeLevelUpModal;
window.closeLootboxModal = closeLootboxModal;
window.showLevelRewards = showLevelRewards;
window.claimReward = claimReward;
window.claimMissionReward = claimMissionReward;
window.claimDailyReward = claimDailyReward;
window.openLootbox = openLootbox;
window.closeLevelRewardModal = closeLevelRewardModal;