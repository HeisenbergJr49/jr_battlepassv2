// JR.DEV Battlepass - Animations JavaScript

// Animation system for battlepass UI
class BattlepassAnimations {
    constructor() {
        this.particles = [];
        this.animationQueue = [];
        this.isAnimating = false;
    }

    // Initialize animation system
    init() {
        this.createParticleCanvas();
        this.startAnimationLoop();
    }

    // Create particle canvas for effects
    createParticleCanvas() {
        const canvas = document.createElement('canvas');
        canvas.id = 'particleCanvas';
        canvas.style.position = 'fixed';
        canvas.style.top = '0';
        canvas.style.left = '0';
        canvas.style.width = '100vw';
        canvas.style.height = '100vh';
        canvas.style.pointerEvents = 'none';
        canvas.style.zIndex = '999';
        canvas.width = window.innerWidth;
        canvas.height = window.innerHeight;
        
        document.body.appendChild(canvas);
        this.canvas = canvas;
        this.ctx = canvas.getContext('2d');

        // Resize canvas on window resize
        window.addEventListener('resize', () => {
            canvas.width = window.innerWidth;
            canvas.height = window.innerHeight;
        });
    }

    // Start main animation loop
    startAnimationLoop() {
        const animate = () => {
            this.updateParticles();
            this.renderParticles();
            requestAnimationFrame(animate);
        };
        animate();
    }

    // Level up celebration animation
    triggerLevelUpAnimation() {
        this.createConfetti();
        this.createStarburst();
        this.addScreenFlash();
        this.animateElement('.level-up-animation', 'levelUpPulse', 2000);
    }

    // XP gain animation
    triggerXPGainAnimation(element, amount) {
        const xpGain = document.createElement('div');
        xpGain.className = 'xp-gain-animation';
        xpGain.textContent = `+${amount} XP`;
        xpGain.style.position = 'absolute';
        xpGain.style.color = '#ffd700';
        xpGain.style.fontSize = '20px';
        xpGain.style.fontWeight = 'bold';
        xpGain.style.pointerEvents = 'none';
        xpGain.style.zIndex = '1000';
        xpGain.style.animation = 'xpGainFloat 2s ease-out forwards';
        
        if (element) {
            const rect = element.getBoundingClientRect();
            xpGain.style.left = `${rect.left + rect.width / 2}px`;
            xpGain.style.top = `${rect.top}px`;
        } else {
            xpGain.style.left = '50%';
            xpGain.style.top = '50%';
            xpGain.style.transform = 'translateX(-50%)';
        }
        
        document.body.appendChild(xpGain);
        
        setTimeout(() => {
            if (xpGain.parentNode) {
                xpGain.parentNode.removeChild(xpGain);
            }
        }, 2000);
    }

    // Reward claim animation
    triggerRewardClaimAnimation(element) {
        if (!element) return;
        
        // Create pulsing effect
        element.style.transform = 'scale(1.1)';
        element.style.transition = 'transform 0.3s ease';
        
        setTimeout(() => {
            element.style.transform = 'scale(1)';
        }, 300);
        
        // Create particle burst at element position
        const rect = element.getBoundingClientRect();
        this.createParticleBurst(
            rect.left + rect.width / 2,
            rect.top + rect.height / 2,
            '#ffd700'
        );
    }

    // Loot box opening animation
    triggerLootboxOpenAnimation() {
        const lootboxIcon = document.querySelector('.lootbox-opening .lootbox-icon i');
        if (lootboxIcon) {
            lootboxIcon.style.animation = 'lootboxShake 0.1s infinite';
            
            setTimeout(() => {
                lootboxIcon.style.animation = 'lootboxExplode 0.5s ease-out';
                this.createLootboxExplosion();
            }, 2000);
        }
    }

    // Mission completion animation
    triggerMissionCompleteAnimation(missionCard) {
        if (!missionCard) return;
        
        // Add completed class with animation
        missionCard.classList.add('mission-completing');
        
        // Create success particle effect
        const rect = missionCard.getBoundingClientRect();
        this.createParticleBurst(
            rect.left + rect.width / 2,
            rect.top + rect.height / 2,
            '#10b981'
        );
        
        // Progress bar animation
        const progressBar = missionCard.querySelector('.mission-progress-fill');
        if (progressBar) {
            progressBar.style.width = '100%';
            progressBar.style.background = 'linear-gradient(90deg, #10b981, #34d399)';
            progressBar.style.animation = 'progressComplete 1s ease-out';
        }
        
        setTimeout(() => {
            missionCard.classList.remove('mission-completing');
            missionCard.classList.add('completed');
        }, 1000);
    }

    // Daily streak animation
    triggerDailyStreakAnimation(day) {
        const dailyCard = document.querySelector(`#dailyReward-${day}`);
        if (dailyCard) {
            dailyCard.style.animation = 'dailyStreakPulse 1s ease-out';
            
            if (day === 7) {
                // Special mega bonus animation
                this.createMegaBonusAnimation(dailyCard);
            }
        }
    }

    // Premium activation animation
    triggerPremiumActivationAnimation() {
        const premiumStatus = document.getElementById('premiumStatus');
        if (premiumStatus) {
            premiumStatus.style.animation = 'premiumActivate 2s ease-out';
            
            // Golden particle cascade
            this.createGoldenCascade();
        }
        
        // Update all premium elements with glow effect
        const premiumElements = document.querySelectorAll('.premium');
        premiumElements.forEach(element => {
            element.style.animation = 'premiumGlow 3s ease-out';
        });
    }

    // Create confetti particles
    createConfetti() {
        const colors = ['#ffd700', '#ff6b6b', '#4ecdc4', '#45b7d1', '#96ceb4'];
        
        for (let i = 0; i < 50; i++) {
            const particle = {
                x: Math.random() * window.innerWidth,
                y: -10,
                vx: (Math.random() - 0.5) * 10,
                vy: Math.random() * 5 + 2,
                color: colors[Math.floor(Math.random() * colors.length)],
                size: Math.random() * 8 + 4,
                rotation: Math.random() * 360,
                rotationSpeed: (Math.random() - 0.5) * 10,
                life: 3000,
                type: 'confetti'
            };
            this.particles.push(particle);
        }
    }

    // Create starburst effect
    createStarburst() {
        const centerX = window.innerWidth / 2;
        const centerY = window.innerHeight / 2;
        
        for (let i = 0; i < 12; i++) {
            const angle = (i / 12) * Math.PI * 2;
            const particle = {
                x: centerX,
                y: centerY,
                vx: Math.cos(angle) * 15,
                vy: Math.sin(angle) * 15,
                color: '#ffd700',
                size: 6,
                life: 2000,
                type: 'star'
            };
            this.particles.push(particle);
        }
    }

    // Create particle burst at position
    createParticleBurst(x, y, color = '#ffd700') {
        for (let i = 0; i < 20; i++) {
            const angle = (i / 20) * Math.PI * 2;
            const speed = Math.random() * 8 + 2;
            const particle = {
                x: x,
                y: y,
                vx: Math.cos(angle) * speed,
                vy: Math.sin(angle) * speed,
                color: color,
                size: Math.random() * 4 + 2,
                life: 1500,
                type: 'burst'
            };
            this.particles.push(particle);
        }
    }

    // Create loot box explosion effect
    createLootboxExplosion() {
        const centerX = window.innerWidth / 2;
        const centerY = window.innerHeight / 2;
        
        // Main explosion
        this.createParticleBurst(centerX, centerY, '#ffd700');
        
        // Secondary bursts
        setTimeout(() => {
            this.createParticleBurst(centerX - 50, centerY - 30, '#ff6b6b');
            this.createParticleBurst(centerX + 50, centerY - 30, '#4ecdc4');
        }, 200);
        
        // Screen shake
        this.addScreenShake(500);
    }

    // Create mega bonus animation
    createMegaBonusAnimation(element) {
        // Rainbow particle spiral
        const rect = element.getBoundingClientRect();
        const centerX = rect.left + rect.width / 2;
        const centerY = rect.top + rect.height / 2;
        
        const colors = ['#ff0000', '#ff8000', '#ffff00', '#80ff00', '#00ff00', '#00ff80', '#00ffff', '#0080ff', '#0000ff', '#8000ff', '#ff00ff', '#ff0080'];
        
        for (let i = 0; i < 60; i++) {
            const angle = (i / 60) * Math.PI * 8; // Multiple spirals
            const radius = (i / 60) * 100;
            
            setTimeout(() => {
                const particle = {
                    x: centerX + Math.cos(angle) * radius,
                    y: centerY + Math.sin(angle) * radius,
                    vx: Math.cos(angle) * 2,
                    vy: Math.sin(angle) * 2,
                    color: colors[i % colors.length],
                    size: 8,
                    life: 2000,
                    type: 'rainbow'
                };
                this.particles.push(particle);
            }, i * 50);
        }
    }

    // Create golden cascade for premium
    createGoldenCascade() {
        for (let i = 0; i < 30; i++) {
            setTimeout(() => {
                const particle = {
                    x: Math.random() * window.innerWidth,
                    y: -10,
                    vx: (Math.random() - 0.5) * 4,
                    vy: Math.random() * 3 + 2,
                    color: '#ffd700',
                    size: Math.random() * 6 + 3,
                    life: 4000,
                    type: 'golden',
                    shimmer: true
                };
                this.particles.push(particle);
            }, i * 200);
        }
    }

    // Add screen flash effect
    addScreenFlash() {
        const flash = document.createElement('div');
        flash.style.position = 'fixed';
        flash.style.top = '0';
        flash.style.left = '0';
        flash.style.width = '100vw';
        flash.style.height = '100vh';
        flash.style.backgroundColor = 'rgba(255, 215, 0, 0.3)';
        flash.style.pointerEvents = 'none';
        flash.style.zIndex = '998';
        flash.style.animation = 'screenFlash 0.5s ease-out';
        
        document.body.appendChild(flash);
        
        setTimeout(() => {
            if (flash.parentNode) {
                flash.parentNode.removeChild(flash);
            }
        }, 500);
    }

    // Add screen shake effect
    addScreenShake(duration = 500) {
        const app = document.getElementById('app');
        if (app) {
            app.style.animation = `screenShake 0.1s infinite`;
            
            setTimeout(() => {
                app.style.animation = '';
            }, duration);
        }
    }

    // Animate specific element
    animateElement(selector, animationName, duration = 1000) {
        const element = document.querySelector(selector);
        if (element) {
            element.style.animation = `${animationName} ${duration}ms ease-out`;
            
            setTimeout(() => {
                element.style.animation = '';
            }, duration);
        }
    }

    // Update particles
    updateParticles() {
        for (let i = this.particles.length - 1; i >= 0; i--) {
            const particle = this.particles[i];
            
            // Update position
            particle.x += particle.vx;
            particle.y += particle.vy;
            
            // Update rotation if applicable
            if (particle.rotation !== undefined) {
                particle.rotation += particle.rotationSpeed || 0;
            }
            
            // Apply gravity
            if (particle.type === 'confetti' || particle.type === 'burst') {
                particle.vy += 0.3;
            }
            
            // Reduce life
            particle.life -= 16; // Assuming 60 FPS
            
            // Remove dead particles
            if (particle.life <= 0 || particle.y > window.innerHeight + 50) {
                this.particles.splice(i, 1);
            }
        }
    }

    // Render particles
    renderParticles() {
        if (!this.ctx) return;
        
        this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
        
        this.particles.forEach(particle => {
            this.ctx.save();
            
            // Set alpha based on life
            const alpha = Math.max(0, particle.life / 2000);
            this.ctx.globalAlpha = alpha;
            
            // Move to particle position
            this.ctx.translate(particle.x, particle.y);
            
            // Apply rotation if applicable
            if (particle.rotation !== undefined) {
                this.ctx.rotate(particle.rotation * Math.PI / 180);
            }
            
            // Set color
            this.ctx.fillStyle = particle.color;
            
            // Render based on type
            switch (particle.type) {
                case 'confetti':
                    this.ctx.fillRect(-particle.size / 2, -particle.size / 2, particle.size, particle.size);
                    break;
                    
                case 'star':
                    this.drawStar(particle.size);
                    break;
                    
                case 'burst':
                case 'golden':
                case 'rainbow':
                    this.ctx.beginPath();
                    this.ctx.arc(0, 0, particle.size, 0, Math.PI * 2);
                    this.ctx.fill();
                    
                    // Add shimmer effect for golden particles
                    if (particle.shimmer) {
                        this.ctx.shadowBlur = 10;
                        this.ctx.shadowColor = particle.color;
                        this.ctx.fill();
                    }
                    break;
            }
            
            this.ctx.restore();
        });
    }

    // Draw star shape
    drawStar(size) {
        this.ctx.beginPath();
        for (let i = 0; i < 5; i++) {
            const angle = (i / 5) * Math.PI * 2 - Math.PI / 2;
            const x = Math.cos(angle) * size;
            const y = Math.sin(angle) * size;
            
            if (i === 0) {
                this.ctx.moveTo(x, y);
            } else {
                this.ctx.lineTo(x, y);
            }
            
            // Inner point
            const innerAngle = ((i + 0.5) / 5) * Math.PI * 2 - Math.PI / 2;
            const innerX = Math.cos(innerAngle) * (size * 0.4);
            const innerY = Math.sin(innerAngle) * (size * 0.4);
            this.ctx.lineTo(innerX, innerY);
        }
        this.ctx.closePath();
        this.ctx.fill();
    }

    // Smooth number counting animation
    animateNumber(element, from, to, duration = 1000) {
        const startTime = performance.now();
        
        const animate = (currentTime) => {
            const elapsed = currentTime - startTime;
            const progress = Math.min(elapsed / duration, 1);
            
            // Easing function
            const easeOut = 1 - Math.pow(1 - progress, 3);
            const currentValue = Math.floor(from + (to - from) * easeOut);
            
            element.textContent = currentValue.toLocaleString();
            
            if (progress < 1) {
                requestAnimationFrame(animate);
            }
        };
        
        requestAnimationFrame(animate);
    }

    // Progress bar animation
    animateProgressBar(element, to, duration = 1000) {
        element.style.transition = `width ${duration}ms ease-out`;
        element.style.width = `${to}%`;
    }

    // Chain multiple animations
    chainAnimations(animations) {
        let delay = 0;
        
        animations.forEach(animation => {
            setTimeout(() => {
                animation.function.call(this, ...animation.args);
            }, delay);
            delay += animation.delay || 0;
        });
    }

    // Cleanup method
    cleanup() {
        this.particles = [];
        if (this.canvas && this.canvas.parentNode) {
            this.canvas.parentNode.removeChild(this.canvas);
        }
    }
}

// CSS Animations (injected dynamically)
const animationCSS = `
    @keyframes xpGainFloat {
        0% {
            transform: translateY(0) scale(1);
            opacity: 1;
        }
        100% {
            transform: translateY(-100px) scale(1.2);
            opacity: 0;
        }
    }
    
    @keyframes levelUpPulse {
        0%, 100% { transform: scale(1); }
        25% { transform: scale(1.1); }
        50% { transform: scale(1.05); }
        75% { transform: scale(1.15); }
    }
    
    @keyframes lootboxShake {
        0%, 100% { transform: rotate(0deg) scale(1); }
        25% { transform: rotate(-5deg) scale(1.05); }
        75% { transform: rotate(5deg) scale(1.05); }
    }
    
    @keyframes lootboxExplode {
        0% { transform: scale(1); opacity: 1; }
        50% { transform: scale(1.5); opacity: 0.8; }
        100% { transform: scale(2); opacity: 0; }
    }
    
    @keyframes progressComplete {
        0% { box-shadow: 0 0 0 rgba(16, 185, 129, 0.5); }
        50% { box-shadow: 0 0 20px rgba(16, 185, 129, 0.8); }
        100% { box-shadow: 0 0 0 rgba(16, 185, 129, 0.5); }
    }
    
    @keyframes dailyStreakPulse {
        0%, 100% { transform: scale(1); filter: brightness(1); }
        50% { transform: scale(1.1); filter: brightness(1.3); }
    }
    
    @keyframes premiumActivate {
        0% { transform: scale(1); filter: brightness(1); }
        25% { transform: scale(1.1); filter: brightness(1.5); }
        50% { transform: scale(1); filter: brightness(1.2); }
        75% { transform: scale(1.05); filter: brightness(1.3); }
        100% { transform: scale(1); filter: brightness(1); }
    }
    
    @keyframes premiumGlow {
        0%, 100% { box-shadow: 0 0 0 rgba(255, 215, 0, 0.3); }
        50% { box-shadow: 0 0 30px rgba(255, 215, 0, 0.8); }
    }
    
    @keyframes screenFlash {
        0% { opacity: 0; }
        50% { opacity: 1; }
        100% { opacity: 0; }
    }
    
    @keyframes screenShake {
        0%, 100% { transform: translateX(0); }
        25% { transform: translateX(-5px); }
        75% { transform: translateX(5px); }
    }
    
    @keyframes mission-completing {
        0% { background: rgba(0, 0, 0, 0.3); }
        50% { background: rgba(16, 185, 129, 0.2); }
        100% { background: rgba(16, 185, 129, 0.1); }
    }
`;

// Inject CSS animations
const style = document.createElement('style');
style.textContent = animationCSS;
document.head.appendChild(style);

// Initialize animation system
const animations = new BattlepassAnimations();
animations.init();

// Export animation functions for global use
window.triggerLevelUpAnimation = () => animations.triggerLevelUpAnimation();
window.triggerXPGainAnimation = (element, amount) => animations.triggerXPGainAnimation(element, amount);
window.triggerRewardClaimAnimation = (element) => animations.triggerRewardClaimAnimation(element);
window.triggerLootboxOpenAnimation = () => animations.triggerLootboxOpenAnimation();
window.triggerMissionCompleteAnimation = (element) => animations.triggerMissionCompleteAnimation(element);
window.triggerDailyStreakAnimation = (day) => animations.triggerDailyStreakAnimation(day);
window.triggerPremiumActivationAnimation = () => animations.triggerPremiumActivationAnimation();

// Export animation instance
window.battlepassAnimations = animations;