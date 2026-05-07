# UI Framework — Canvas 2D Game HUD
## Menus, HUD, Dialogs, Buttons — No DOM Overhead

---

## Design Philosophy

For AAA mobile games, UI should be:
- **Canvas 2D** for game HUD (fast, no DOM reflow)
- **HTML/CSS** for menus (easier to style, accessibility)
- **Hybrid** approach: canvas for in-game, HTML for out-of-game

---

## 1. UI System Architecture

```javascript
class UISystem {
    _canvas = null;
    _ctx = null;
    _elements = [];
    _screens = new Map();   // name → UIScreen
    _activeScreen = null;
    
    // Font preloading
    _fonts = {};
    
    init() {
        // Overlay canvas on top of WebGL canvas
        this._canvas = document.createElement('canvas');
        this._canvas.style.cssText = `
            position: fixed;
            top: 0; left: 0;
            width: 100%; height: 100%;
            pointer-events: none;
            z-index: 500;
        `;
        this._canvas.width  = window.innerWidth;
        this._canvas.height = window.innerHeight;
        this._ctx = this._canvas.getContext('2d');
        document.body.appendChild(this._canvas);
        
        window.addEventListener('resize', () => {
            this._canvas.width  = window.innerWidth;
            this._canvas.height = window.innerHeight;
        });
    }
    
    render() {
        const ctx = this._ctx;
        ctx.clearRect(0, 0, this._canvas.width, this._canvas.height);
        
        // Render active screen
        this._activeScreen?.render(ctx);
        
        // Render persistent HUD elements
        this._elements.forEach(el => {
            if (el.visible) el.render(ctx);
        });
    }
    
    showScreen(name, data = {}) {
        this._activeScreen?.onHide();
        this._activeScreen = this._screens.get(name);
        this._activeScreen?.onShow(data);
    }
    
    hideScreen() {
        this._activeScreen?.onHide();
        this._activeScreen = null;
    }
    
    addHUDElement(element) {
        this._elements.push(element);
        return element;
    }
}
```

---

## 2. HUD Elements

```javascript
// ── Health Bar ──────────────────────────────────────────────────────
class HealthBar {
    constructor(config) {
        this.x = config.x ?? 20;
        this.y = config.y ?? 20;
        this.w = config.w ?? 200;
        this.h = config.h ?? 20;
        this.value = 1.0;  // 0-1
        this.visible = true;
        
        // Colors
        this.bgColor    = config.bgColor    ?? 'rgba(0,0,0,0.5)';
        this.fillColor  = config.fillColor  ?? '#e74c3c';
        this.borderColor = config.borderColor ?? 'rgba(255,255,255,0.3)';
        this.label      = config.label      ?? 'HP';
    }
    
    render(ctx) {
        const { x, y, w, h } = this;
        
        // Background
        ctx.fillStyle = this.bgColor;
        ctx.beginPath();
        ctx.roundRect(x, y, w, h, 4);
        ctx.fill();
        
        // Fill (with color transition: green → yellow → red)
        const r = Math.floor(255 * (1 - this.value));
        const g = Math.floor(255 * this.value);
        ctx.fillStyle = `rgb(${r},${g},0)`;
        ctx.beginPath();
        ctx.roundRect(x + 1, y + 1, (w - 2) * this.value, h - 2, 3);
        ctx.fill();
        
        // Border
        ctx.strokeStyle = this.borderColor;
        ctx.lineWidth = 1;
        ctx.beginPath();
        ctx.roundRect(x, y, w, h, 4);
        ctx.stroke();
        
        // Label
        ctx.fillStyle = '#fff';
        ctx.font = 'bold 11px "Courier New"';
        ctx.textAlign = 'left';
        ctx.fillText(this.label, x + 5, y + h - 5);
        
        // Value text
        ctx.textAlign = 'right';
        ctx.fillText(Math.round(this.value * 100) + '%', x + w - 5, y + h - 5);
    }
}

// ── Score Display ───────────────────────────────────────────────────
class ScoreDisplay {
    constructor(config) {
        this.x = config.x ?? window.innerWidth / 2;
        this.y = config.y ?? 30;
        this.score = 0;
        this._displayScore = 0;  // animated counter
        this.visible = true;
    }
    
    setScore(value) {
        this.score = value;
    }
    
    render(ctx) {
        // Smooth counter animation
        this._displayScore += (this.score - this._displayScore) * 0.1;
        
        ctx.save();
        ctx.textAlign = 'center';
        ctx.font = 'bold 28px "Courier New"';
        
        // Shadow
        ctx.fillStyle = 'rgba(0,0,0,0.5)';
        ctx.fillText(Math.floor(this._displayScore).toLocaleString(), this.x + 2, this.y + 2);
        
        // Text
        ctx.fillStyle = '#fff';
        ctx.fillText(Math.floor(this._displayScore).toLocaleString(), this.x, this.y);
        
        ctx.restore();
    }
}

// ── Minimap ─────────────────────────────────────────────────────────
class Minimap {
    constructor(config) {
        this.x = config.x ?? window.innerWidth - 120;
        this.y = config.y ?? 20;
        this.size = config.size ?? 100;
        this.worldSize = config.worldSize ?? 200;
        this.visible = true;
        this._dots = [];  // { x, z, color, size }
    }
    
    addDot(worldX, worldZ, color = '#fff', size = 3) {
        this._dots.push({ x: worldX, z: worldZ, color, size });
    }
    
    clearDots() { this._dots = []; }
    
    render(ctx) {
        const { x, y, size } = this;
        const half = size / 2;
        
        // Background
        ctx.save();
        ctx.beginPath();
        ctx.arc(x + half, y + half, half, 0, Math.PI * 2);
        ctx.clip();
        
        ctx.fillStyle = 'rgba(0,0,0,0.6)';
        ctx.fill();
        
        // Grid lines
        ctx.strokeStyle = 'rgba(255,255,255,0.1)';
        ctx.lineWidth = 0.5;
        for (let i = 0; i <= 4; i++) {
            const p = (i / 4) * size;
            ctx.beginPath(); ctx.moveTo(x + p, y); ctx.lineTo(x + p, y + size); ctx.stroke();
            ctx.beginPath(); ctx.moveTo(x, y + p); ctx.lineTo(x + size, y + p); ctx.stroke();
        }
        
        // Dots
        this._dots.forEach(dot => {
            const mx = x + half + (dot.x / this.worldSize) * half;
            const my = y + half + (dot.z / this.worldSize) * half;
            ctx.beginPath();
            ctx.arc(mx, my, dot.size, 0, Math.PI * 2);
            ctx.fillStyle = dot.color;
            ctx.fill();
        });
        
        ctx.restore();
        
        // Border
        ctx.beginPath();
        ctx.arc(x + half, y + half, half, 0, Math.PI * 2);
        ctx.strokeStyle = 'rgba(255,255,255,0.4)';
        ctx.lineWidth = 2;
        ctx.stroke();
    }
}

// ── Crosshair ───────────────────────────────────────────────────────
class Crosshair {
    constructor(config = {}) {
        this.size = config.size ?? 10;
        this.gap  = config.gap  ?? 4;
        this.color = config.color ?? 'rgba(255,255,255,0.8)';
        this.visible = true;
    }
    
    render(ctx) {
        const cx = window.innerWidth / 2;
        const cy = window.innerHeight / 2;
        const { size, gap } = this;
        
        ctx.strokeStyle = this.color;
        ctx.lineWidth = 2;
        ctx.lineCap = 'round';
        
        // Horizontal
        ctx.beginPath();
        ctx.moveTo(cx - size - gap, cy);
        ctx.lineTo(cx - gap, cy);
        ctx.moveTo(cx + gap, cy);
        ctx.lineTo(cx + size + gap, cy);
        ctx.stroke();
        
        // Vertical
        ctx.beginPath();
        ctx.moveTo(cx, cy - size - gap);
        ctx.lineTo(cx, cy - gap);
        ctx.moveTo(cx, cy + gap);
        ctx.lineTo(cx, cy + size + gap);
        ctx.stroke();
        
        // Center dot
        ctx.beginPath();
        ctx.arc(cx, cy, 2, 0, Math.PI * 2);
        ctx.fillStyle = this.color;
        ctx.fill();
    }
}

// ── Damage Numbers (floating text) ──────────────────────────────────
class DamageNumbers {
    _numbers = [];
    
    spawn(worldPos, value, color = '#ff4444') {
        // Project world position to screen
        const screenPos = worldPos.clone().project(camera);
        const x = (screenPos.x + 1) / 2 * window.innerWidth;
        const y = (-screenPos.y + 1) / 2 * window.innerHeight;
        
        this._numbers.push({
            x, y, value,
            color,
            alpha: 1.0,
            vy: -2,  // float upward
            life: 1.0
        });
    }
    
    render(ctx) {
        const dt = 1/60;
        this._numbers = this._numbers.filter(n => n.life > 0);
        
        this._numbers.forEach(n => {
            n.y += n.vy;
            n.life -= dt;
            n.alpha = n.life;
            
            ctx.save();
            ctx.globalAlpha = n.alpha;
            ctx.font = 'bold 20px "Courier New"';
            ctx.textAlign = 'center';
            
            // Outline
            ctx.strokeStyle = '#000';
            ctx.lineWidth = 3;
            ctx.strokeText(n.value, n.x, n.y);
            
            // Fill
            ctx.fillStyle = n.color;
            ctx.fillText(n.value, n.x, n.y);
            
            ctx.restore();
        });
    }
}
```

---

## 3. Menu Screens (HTML-based)

```javascript
// Main Menu — HTML overlay
class MainMenuScreen {
    _el = null;
    
    create() {
        this._el = document.createElement('div');
        this._el.id = 'mainMenu';
        this._el.innerHTML = `
            <div class="menu-overlay">
                <div class="menu-panel">
                    <h1 class="game-title">GAME TITLE</h1>
                    <div class="menu-buttons">
                        <button class="menu-btn primary" id="btnPlay">PLAY</button>
                        <button class="menu-btn" id="btnSettings">SETTINGS</button>
                        <button class="menu-btn" id="btnCredits">CREDITS</button>
                    </div>
                    <div class="version">v1.0.0</div>
                </div>
            </div>
        `;
        
        // Inject styles
        const style = document.createElement('style');
        style.textContent = `
            .menu-overlay {
                position: fixed; inset: 0;
                background: rgba(0,0,0,0.85);
                backdrop-filter: blur(8px);
                display: flex; align-items: center; justify-content: center;
                z-index: 1000;
                font-family: 'Courier New', monospace;
            }
            .menu-panel {
                text-align: center;
                padding: 40px;
            }
            .game-title {
                font-size: 48px;
                color: #fff;
                text-shadow: 0 0 20px rgba(100,200,255,0.8);
                margin-bottom: 40px;
                letter-spacing: 4px;
            }
            .menu-buttons {
                display: flex;
                flex-direction: column;
                gap: 12px;
                min-width: 240px;
            }
            .menu-btn {
                padding: 14px 28px;
                font-size: 16px;
                font-family: inherit;
                font-weight: bold;
                letter-spacing: 2px;
                border: 2px solid rgba(255,255,255,0.3);
                background: rgba(255,255,255,0.05);
                color: #fff;
                border-radius: 6px;
                cursor: pointer;
                transition: all 0.15s ease;
                touch-action: manipulation;
            }
            .menu-btn:active {
                transform: scale(0.96);
                background: rgba(255,255,255,0.15);
            }
            .menu-btn.primary {
                background: rgba(41,128,185,0.6);
                border-color: rgba(41,128,185,0.8);
            }
            .menu-btn.primary:active {
                background: rgba(41,128,185,0.9);
            }
            .version {
                margin-top: 30px;
                color: rgba(255,255,255,0.3);
                font-size: 11px;
            }
        `;
        document.head.appendChild(style);
        document.body.appendChild(this._el);
        
        // Wire buttons
        document.getElementById('btnPlay').onclick = () => {
            GameFSM.transition('PLAYING', { levelId: 1 });
        };
        document.getElementById('btnSettings').onclick = () => {
            GameFSM.transition('SETTINGS');
        };
    }
    
    onShow() { this._el.style.display = 'flex'; }
    onHide() { this._el.style.display = 'none'; }
}
```

---

## 4. Performance HUD (Upgraded from Current)

```javascript
// Upgraded version of the existing HUD
class PerformanceHUD {
    _el = null;
    _visible = true;
    
    // Rolling averages
    _fpsHistory = new Float32Array(60);
    _msHistory  = new Float32Array(60);
    _idx = 0;
    
    create() {
        this._el = document.createElement('div');
        this._el.id = 'perfHUD';
        this._el.innerHTML = `
            <div class="hud-row">FPS  <span id="hFps" class="val">--</span></div>
            <div class="hud-row">MS   <span id="hMs"  class="val">--</span></div>
            <div class="hud-row">DRAW <span id="hDraw" class="val">--</span></div>
            <div class="hud-row">TRIS <span id="hTris" class="val">--</span></div>
            <div class="hud-row">INST <span id="hInst" class="val">0</span></div>
            <div class="hud-row">MEM  <span id="hMem"  class="val">--</span></div>
            <div class="hud-row">QUAL <span id="hQual" class="val">--</span></div>
            <div class="hud-row">PHY  <span id="hPhy"  class="val">--</span></div>
        `;
        document.body.appendChild(this._el);
    }
    
    update(stats) {
        this._fpsHistory[this._idx % 60] = stats.fps;
        this._msHistory[this._idx % 60]  = stats.ms;
        this._idx++;
        
        const avgFps = this._fpsHistory.reduce((a,b) => a+b) / 60;
        const avgMs  = this._msHistory.reduce((a,b) => a+b) / 60;
        
        const fpsEl = document.getElementById('hFps');
        fpsEl.textContent = avgFps.toFixed(0);
        fpsEl.className = avgFps >= 55 ? 'val good' : avgFps >= 30 ? 'val warn' : 'val bad';
        
        document.getElementById('hMs').textContent   = avgMs.toFixed(1);
        document.getElementById('hDraw').textContent = stats.drawCalls;
        document.getElementById('hTris').textContent = (stats.triangles / 1000).toFixed(0) + 'K';
        document.getElementById('hInst').textContent = stats.instances?.toLocaleString() ?? '0';
        document.getElementById('hMem').textContent  = stats.memory ? (stats.memory / 1048576).toFixed(0) + 'MB' : '--';
        document.getElementById('hQual').textContent = stats.quality ?? '--';
        document.getElementById('hPhy').textContent  = stats.physicsMs ? stats.physicsMs.toFixed(1) + 'ms' : '--';
    }
    
    toggle() {
        this._visible = !this._visible;
        this._el.style.display = this._visible ? 'block' : 'none';
    }
}
```
