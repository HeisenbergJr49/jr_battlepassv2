// 🎬 JR.DEV Battlepass - Animation System
class AnimationSystem {
    constructor() {
        this.isEnabled = true;
        this.particleSystem = null;
        this.init();
    }
    
    init() {
        console.log('🎬 Animation System - Initializing...');
        
        this.setupParticleSystem();
        this.setupIntersectionObserver();
        this.setupHoverEffects();
        
        console.log('✅ Animation System - Initialized successfully!');
    }
    
    setupParticleSystem() {
        // Create canvas for particle effects
        const canvas = document.createElement('canvas');
        canvas.id = 'particleCanvas';
        canvas.style.position = 'fixed';
        canvas.style.top = '0';
        canvas.style.left = '0';
        canvas.style.width = '100%';
        canvas.style.height = '100%';
        canvas.style.pointerEvents = 'none';
        canvas.style.zIndex = '100';
        canvas.style.opacity = '0.7';
        
        document.body.appendChild(canvas);
        
        this.particleSystem = new ParticleSystem(canvas);
    }
    
    setupIntersectionObserver() {
        // Animate elements when they come into view
        const observer = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    entry.target.classList.add('animate-in');
                }
            });
        }, {
            threshold: 0.1
        });
        
        // Observe all animatable elements
        document.querySelectorAll('.reward-item, .mission-card, .daily-reward').forEach(el => {
            observer.observe(el);
        });
    }
    
    setupHoverEffects() {
        // Add hover effects to interactive elements
        this.addHoverEffect('.nav-button', {
            scale: 1.05,
            glow: true
        });
        
        this.addHoverEffect('.reward-item', {
            translateX: 10,
            glow: true
        });
        
        this.addHoverEffect('.mission-card', {
            translateY: -5,
            shadow: true
        });
        
        this.addHoverEffect('.daily-reward', {
            scale: 1.1,
            rotate: 5
        });
        
        this.addHoverEffect('button', {
            scale: 1.05,
            brightness: 1.1
        });
    }
    
    addHoverEffect(selector, effects) {
        document.querySelectorAll(selector).forEach(element => {
            element.addEventListener('mouseenter', () => {
                if (!this.isEnabled) return;
                
                let transform = '';
                let filter = '';
                
                if (effects.scale) {
                    transform += `scale(${effects.scale}) `;
                }
                if (effects.translateX) {
                    transform += `translateX(${effects.translateX}px) `;
                }
                if (effects.translateY) {
                    transform += `translateY(${effects.translateY}px) `;
                }
                if (effects.rotate) {
                    transform += `rotate(${effects.rotate}deg) `;
                }
                if (effects.brightness) {
                    filter += `brightness(${effects.brightness}) `;
                }
                if (effects.glow) {
                    element.style.boxShadow = '0 0 20px rgba(255, 215, 0, 0.5)';
                }
                if (effects.shadow) {
                    element.style.boxShadow = '0 20px 25px rgba(0, 0, 0, 0.6)';
                }
                
                element.style.transform = transform;
                element.style.filter = filter;
                element.style.transition = 'all 0.3s ease-out';
            });
            
            element.addEventListener('mouseleave', () => {
                if (!this.isEnabled) return;
                
                element.style.transform = '';
                element.style.filter = '';
                element.style.boxShadow = '';
            });
        });
    }
    
    // Specific animations for battlepass events
    animateXPGain(amount, element) {
        if (!this.isEnabled) return;
        
        const xpElement = document.createElement('div');
        xpElement.className = 'xp-gain-animation';
        xpElement.textContent = `+${amount} XP`;
        xpElement.style.cssText = `
            position: absolute;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            color: #FFD700;
            font-weight: bold;
            font-size: 24px;
            pointer-events: none;
            z-index: 1000;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.8);
        `;
        
        element.appendChild(xpElement);
        
        // Animate upward and fade out
        xpElement.animate([
            { transform: 'translate(-50%, -50%)', opacity: 1 },
            { transform: 'translate(-50%, -150%)', opacity: 0 }
        ], {
            duration: 2000,
            easing: 'ease-out'
        }).onfinish = () => {
            xpElement.remove();
        };
        
        // Create particle burst
        this.particleSystem.createBurst(
            element.offsetLeft + element.offsetWidth / 2,
            element.offsetTop + element.offsetHeight / 2,
            'xp'
        );
    }
    
    animateLevelUp(newLevel, oldLevel) {
        if (!this.isEnabled) return;
        
        // Screen flash effect
        this.createScreenFlash('#FFD700', 0.3, 1000);
        
        // Create fireworks particles
        for (let i = 0; i < 5; i++) {
            setTimeout(() => {
                this.particleSystem.createFirework(
                    Math.random() * window.innerWidth,
                    Math.random() * window.innerHeight * 0.5 + 100
                );
            }, i * 200);
        }
        
        // Animate level badge
        const levelBadge = document.querySelector('.level-badge');
        if (levelBadge) {
            levelBadge.animate([
                { transform: 'scale(1)', boxShadow: '0 0 20px rgba(255, 215, 0, 0.5)' },
                { transform: 'scale(1.3)', boxShadow: '0 0 50px rgba(255, 215, 0, 1)' },
                { transform: 'scale(1)', boxShadow: '0 0 20px rgba(255, 215, 0, 0.5)' }
            ], {
                duration: 1500,
                easing: 'ease-out'
            });
        }
        
        // Animate XP bar
        const xpBar = document.querySelector('.xp-fill');
        if (xpBar) {
            xpBar.animate([
                { width: xpBar.style.width },
                { width: '100%', backgroundColor: '#FFD700' },
                { width: '0%', backgroundColor: '#FFD700' },
                { width: xpBar.style.width, backgroundColor: '#FFD700' }
            ], {
                duration: 2000,
                easing: 'ease-in-out'
            });
        }
    }
    
    animateRewardClaim(element, rewardType) {
        if (!this.isEnabled) return;
        
        // Add claimed class with animation
        element.classList.add('claiming');
        
        // Create success particles
        this.particleSystem.createBurst(
            element.offsetLeft + element.offsetWidth / 2,
            element.offsetTop + element.offsetHeight / 2,
            rewardType
        );
        
        // Animate the element
        element.animate([
            { transform: 'scale(1)', filter: 'brightness(1)' },
            { transform: 'scale(1.1)', filter: 'brightness(1.5)' },
            { transform: 'scale(1)', filter: 'brightness(0.7)' }
        ], {
            duration: 800,
            easing: 'ease-out'
        }).onfinish = () => {
            element.classList.remove('claiming');
            element.classList.add('claimed');
        };
    }
    
    animateDailyReward(dayElement) {
        if (!this.isEnabled) return;
        
        // Glowing effect
        dayElement.animate([
            { boxShadow: '0 0 10px rgba(255, 215, 0, 0.5)' },
            { boxShadow: '0 0 30px rgba(255, 215, 0, 1)' },
            { boxShadow: '0 0 10px rgba(255, 215, 0, 0.5)' }
        ], {
            duration: 2000,
            iterations: Infinity,
            easing: 'ease-in-out'
        });
        
        // Floating animation
        dayElement.animate([
            { transform: 'translateY(0px)' },
            { transform: 'translateY(-10px)' },
            { transform: 'translateY(0px)' }
        ], {
            duration: 3000,
            iterations: Infinity,
            easing: 'ease-in-out'
        });
    }
    
    animatePremiumUpgrade() {
        if (!this.isEnabled) return;
        
        // Golden shower effect
        this.createScreenFlash('#FFD700', 0.4, 2000);
        
        // Create premium particles
        for (let i = 0; i < 20; i++) {
            setTimeout(() => {
                this.particleSystem.createPremiumParticle(
                    Math.random() * window.innerWidth,
                    -50
                );
            }, i * 100);
        }
        
        // Animate premium badge
        const premiumBadge = document.querySelector('.premium-badge');
        if (premiumBadge) {
            premiumBadge.animate([
                { transform: 'scale(1)', background: 'linear-gradient(135deg, #FFD700, #FFA500)' },
                { transform: 'scale(1.2)', background: 'linear-gradient(135deg, #FFD700, #FFA500, #FF6347)' },
                { transform: 'scale(1)', background: 'linear-gradient(135deg, #FFD700, #FFA500, #FF6347)' }
            ], {
                duration: 1500,
                easing: 'ease-out'
            });
        }
    }
    
    animateMissionComplete(missionCard) {
        if (!this.isEnabled) return;
        
        // Success glow
        missionCard.animate([
            { borderColor: 'rgba(255, 215, 0, 0.2)', backgroundColor: 'rgba(255, 255, 255, 0.05)' },
            { borderColor: 'rgba(40, 167, 69, 1)', backgroundColor: 'rgba(40, 167, 69, 0.2)' }
        ], {
            duration: 1000,
            easing: 'ease-out',
            fill: 'forwards'
        });
        
        // Checkmark animation
        const checkmark = document.createElement('div');
        checkmark.innerHTML = '✓';
        checkmark.style.cssText = `
            position: absolute;
            top: 10px;
            right: 10px;
            color: #28a745;
            font-size: 24px;
            font-weight: bold;
            opacity: 0;
        `;
        
        missionCard.style.position = 'relative';
        missionCard.appendChild(checkmark);
        
        checkmark.animate([
            { opacity: 0, transform: 'scale(0)' },
            { opacity: 1, transform: 'scale(1.2)' },
            { opacity: 1, transform: 'scale(1)' }
        ], {
            duration: 500,
            easing: 'ease-out'
        });
        
        // Particle effect
        this.particleSystem.createBurst(
            missionCard.offsetLeft + missionCard.offsetWidth - 50,
            missionCard.offsetTop + 50,
            'success'
        );
    }
    
    animateLootBoxOpening(lootboxElement) {
        if (!this.isEnabled) return;
        
        const lid = lootboxElement.querySelector('.lootbox-lid');
        const body = lootboxElement.querySelector('.lootbox-body');
        
        // Opening animation
        if (lid) {
            lid.animate([
                { transform: 'rotateX(0deg)' },
                { transform: 'rotateX(-120deg)' }
            ], {
                duration: 1000,
                easing: 'ease-out',
                fill: 'forwards'
            });
        }
        
        // Light burst effect
        setTimeout(() => {
            this.createScreenFlash('#FFD700', 0.6, 500);
            
            // Create magical particles
            for (let i = 0; i < 15; i++) {
                setTimeout(() => {
                    this.particleSystem.createMagicalParticle(
                        lootboxElement.offsetLeft + lootboxElement.offsetWidth / 2,
                        lootboxElement.offsetTop + lootboxElement.offsetHeight / 2
                    );
                }, i * 50);
            }
        }, 800);
    }
    
    // Utility animation methods
    createScreenFlash(color, opacity, duration) {
        const flash = document.createElement('div');
        flash.style.cssText = `
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: ${color};
            opacity: 0;
            pointer-events: none;
            z-index: 9998;
        `;
        
        document.body.appendChild(flash);
        
        flash.animate([
            { opacity: 0 },
            { opacity: opacity },
            { opacity: 0 }
        ], {
            duration: duration,
            easing: 'ease-out'
        }).onfinish = () => {
            flash.remove();
        };
    }
    
    pulseElement(element, scale = 1.05, duration = 1000) {
        if (!this.isEnabled) return;
        
        element.animate([
            { transform: 'scale(1)' },
            { transform: `scale(${scale})` },
            { transform: 'scale(1)' }
        ], {
            duration: duration,
            easing: 'ease-in-out',
            iterations: Infinity
        });
    }
    
    shakeElement(element, intensity = 5, duration = 500) {
        if (!this.isEnabled) return;
        
        const keyframes = [];
        const steps = 10;
        
        for (let i = 0; i <= steps; i++) {
            keyframes.push({
                transform: `translateX(${Math.sin(i * 0.5) * intensity * Math.cos(i * 0.1)}px)`
            });
        }
        
        element.animate(keyframes, {
            duration: duration,
            easing: 'ease-out'
        });
    }
    
    typewriterEffect(element, text, speed = 50) {
        if (!this.isEnabled) return Promise.resolve();
        
        return new Promise(resolve => {
            element.textContent = '';
            let i = 0;
            
            const type = () => {
                if (i < text.length) {
                    element.textContent += text.charAt(i);
                    i++;
                    setTimeout(type, speed);
                } else {
                    resolve();
                }
            };
            
            type();
        });
    }
    
    countUp(element, start, end, duration = 1000) {
        if (!this.isEnabled) return;
        
        const range = end - start;
        const increment = range / (duration / 16);
        let current = start;
        
        const timer = setInterval(() => {
            current += increment;
            if (current >= end) {
                current = end;
                clearInterval(timer);
            }
            element.textContent = Math.floor(current).toLocaleString();
        }, 16);
    }
    
    // Control methods
    enable() {
        this.isEnabled = true;
        document.body.classList.remove('animations-disabled');
    }
    
    disable() {
        this.isEnabled = false;
        document.body.classList.add('animations-disabled');
        
        // Stop all running animations
        document.getAnimations().forEach(animation => {
            animation.cancel();
        });
    }
    
    toggle() {
        if (this.isEnabled) {
            this.disable();
        } else {
            this.enable();
        }
    }
}

// Particle System for advanced visual effects
class ParticleSystem {
    constructor(canvas) {
        this.canvas = canvas;
        this.ctx = canvas.getContext('2d');
        this.particles = [];
        this.isRunning = false;
        
        this.resize();
        this.start();
        
        window.addEventListener('resize', () => this.resize());
    }
    
    resize() {
        this.canvas.width = window.innerWidth;
        this.canvas.height = window.innerHeight;
    }
    
    start() {
        if (this.isRunning) return;
        
        this.isRunning = true;
        this.animate();
    }
    
    stop() {
        this.isRunning = false;
    }
    
    animate() {
        if (!this.isRunning) return;
        
        this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
        
        // Update and draw particles
        this.particles.forEach((particle, index) => {
            particle.update();
            particle.draw(this.ctx);
            
            if (particle.isDead()) {
                this.particles.splice(index, 1);
            }
        });
        
        requestAnimationFrame(() => this.animate());
    }
    
    createBurst(x, y, type = 'default') {
        const particleCount = type === 'xp' ? 10 : 20;
        const colors = this.getColorsForType(type);
        
        for (let i = 0; i < particleCount; i++) {
            this.particles.push(new Particle({
                x: x,
                y: y,
                vx: (Math.random() - 0.5) * 10,
                vy: (Math.random() - 0.5) * 10,
                color: colors[Math.floor(Math.random() * colors.length)],
                size: Math.random() * 5 + 2,
                life: 60,
                type: 'burst'
            }));
        }
    }
    
    createFirework(x, y) {
        const colors = ['#FFD700', '#FFA500', '#FF6347', '#FF1493', '#00BFFF'];
        
        for (let i = 0; i < 30; i++) {
            const angle = (Math.PI * 2 * i) / 30;
            const speed = Math.random() * 5 + 2;
            
            this.particles.push(new Particle({
                x: x,
                y: y,
                vx: Math.cos(angle) * speed,
                vy: Math.sin(angle) * speed,
                color: colors[Math.floor(Math.random() * colors.length)],
                size: Math.random() * 4 + 2,
                life: 80,
                type: 'firework',
                gravity: 0.1
            }));
        }
    }
    
    createPremiumParticle(x, y) {
        this.particles.push(new Particle({
            x: x,
            y: y,
            vx: (Math.random() - 0.5) * 2,
            vy: Math.random() * 3 + 2,
            color: '#FFD700',
            size: Math.random() * 8 + 4,
            life: 120,
            type: 'premium',
            sparkle: true
        }));
    }
    
    createMagicalParticle(x, y) {
        const colors = ['#9D4EDD', '#C77DFF', '#E0AAFF', '#C7CEEA', '#FFB3FF'];
        
        this.particles.push(new Particle({
            x: x,
            y: y,
            vx: (Math.random() - 0.5) * 4,
            vy: -(Math.random() * 6 + 2),
            color: colors[Math.floor(Math.random() * colors.length)],
            size: Math.random() * 6 + 3,
            life: 100,
            type: 'magical',
            glow: true
        }));
    }
    
    getColorsForType(type) {
        const colorSets = {
            xp: ['#FFD700', '#FFA500', '#FFFF00'],
            success: ['#28a745', '#20c997', '#17a2b8'],
            error: ['#dc3545', '#fd7e14', '#ffc107'],
            premium: ['#FFD700', '#FFA500', '#FF6347'],
            default: ['#FFD700', '#FFA500', '#FF6347', '#FF1493']
        };
        
        return colorSets[type] || colorSets.default;
    }
}

// Individual Particle class
class Particle {
    constructor(options) {
        this.x = options.x || 0;
        this.y = options.y || 0;
        this.vx = options.vx || 0;
        this.vy = options.vy || 0;
        this.color = options.color || '#FFD700';
        this.size = options.size || 3;
        this.life = options.life || 60;
        this.maxLife = this.life;
        this.type = options.type || 'default';
        this.gravity = options.gravity || 0;
        this.sparkle = options.sparkle || false;
        this.glow = options.glow || false;
        this.rotation = 0;
        this.rotationSpeed = (Math.random() - 0.5) * 0.2;
    }
    
    update() {
        this.x += this.vx;
        this.y += this.vy;
        
        if (this.gravity) {
            this.vy += this.gravity;
        }
        
        if (this.type === 'premium') {
            this.vx *= 0.99;
            this.vy *= 0.99;
        }
        
        if (this.type === 'magical') {
            this.vx *= 0.98;
            this.vy += 0.05;
        }
        
        this.rotation += this.rotationSpeed;
        this.life--;
    }
    
    draw(ctx) {
        const alpha = this.life / this.maxLife;
        
        ctx.save();
        ctx.globalAlpha = alpha;
        
        if (this.glow) {
            ctx.shadowColor = this.color;
            ctx.shadowBlur = this.size * 2;
        }
        
        ctx.translate(this.x, this.y);
        ctx.rotate(this.rotation);
        
        ctx.fillStyle = this.color;
        
        if (this.type === 'premium' || this.sparkle) {
            // Draw star shape
            this.drawStar(ctx, 0, 0, this.size, this.size * 0.5, 5);
        } else if (this.type === 'magical') {
            // Draw diamond shape
            this.drawDiamond(ctx, 0, 0, this.size);
        } else {
            // Draw circle
            ctx.beginPath();
            ctx.arc(0, 0, this.size, 0, Math.PI * 2);
            ctx.fill();
        }
        
        ctx.restore();
    }
    
    drawStar(ctx, cx, cy, outerRadius, innerRadius, points) {
        const angle = Math.PI / points;
        
        ctx.beginPath();
        ctx.moveTo(cx, cy - outerRadius);
        
        for (let i = 0; i < 2 * points; i++) {
            const radius = i % 2 === 0 ? innerRadius : outerRadius;
            const x = cx + Math.sin(i * angle) * radius;
            const y = cy - Math.cos(i * angle) * radius;
            ctx.lineTo(x, y);
        }
        
        ctx.closePath();
        ctx.fill();
    }
    
    drawDiamond(ctx, cx, cy, size) {
        ctx.beginPath();
        ctx.moveTo(cx, cy - size);
        ctx.lineTo(cx + size, cy);
        ctx.lineTo(cx, cy + size);
        ctx.lineTo(cx - size, cy);
        ctx.closePath();
        ctx.fill();
    }
    
    isDead() {
        return this.life <= 0;
    }
}

// Initialize animation system when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    window.animationSystem = new AnimationSystem();
});

// Export for use in main app
if (typeof module !== 'undefined' && module.exports) {
    module.exports = { AnimationSystem, ParticleSystem, Particle };
}