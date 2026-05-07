# Animation, Audio & Input Systems
## Skeletal Animation, Web Audio, Virtual Joystick

---

## 1. Animation System

### AnimationSystem.js
```javascript
class AnimationSystem {
    _mixers = new Map();  // actorId → THREE.AnimationMixer
    
    // Register an animated GLB model
    registerActor(actor, gltf) {
        if (!gltf.animations || gltf.animations.length === 0) return;
        
        const mixer = new THREE.AnimationMixer(gltf.scene);
        this._mixers.set(actor.id, mixer);
        
        // Store clips by name for easy access
        actor._animClips = {};
        gltf.animations.forEach(clip => {
            actor._animClips[clip.name] = clip;
        });
        
        return mixer;
    }
    
    update(dt) {
        this._mixers.forEach(mixer => mixer.update(dt));
    }
    
    unregister(actor) {
        const mixer = this._mixers.get(actor.id);
        if (mixer) {
            mixer.stopAllAction();
            this._mixers.delete(actor.id);
        }
    }
}
```

### AnimatorComponent.js — State machine for animations
```javascript
class AnimatorComponent extends Component {
    _mixer = null;
    _actions = new Map();    // name → THREE.AnimationAction
    _current = null;
    _states = new Map();     // state name → config
    _currentState = null;
    
    // Transition config
    _defaultBlendTime = 0.2;  // seconds
    
    onAttach(actor) {
        super.onAttach(actor);
        this._mixer = AnimationSystem.registerActor(actor, actor._gltf);
    }
    
    // Add animation state (like UE's Animation Blueprint state)
    addState(name, config) {
        this._states.set(name, {
            clip: config.clip,           // animation clip name
            loop: config.loop ?? true,
            speed: config.speed ?? 1.0,
            blendTime: config.blendTime ?? this._defaultBlendTime,
            onEnter: config.onEnter,
            onExit: config.onExit
        });
        return this;
    }
    
    // Transition to state
    play(stateName, blendTime = null) {
        if (this._currentState === stateName) return;
        
        const state = this._states.get(stateName);
        if (!state) { console.warn(`[Animator] Unknown state: ${stateName}`); return; }
        
        const clip = this.actor._animClips[state.clip];
        if (!clip) { console.warn(`[Animator] Clip not found: ${state.clip}`); return; }
        
        // Get or create action
        if (!this._actions.has(stateName)) {
            const action = this._mixer.clipAction(clip);
            action.loop = state.loop ? THREE.LoopRepeat : THREE.LoopOnce;
            action.timeScale = state.speed;
            if (!state.loop) action.clampWhenFinished = true;
            this._actions.set(stateName, action);
        }
        
        const newAction = this._actions.get(stateName);
        const bt = blendTime ?? state.blendTime;
        
        // Crossfade from current
        if (this._current && this._current !== newAction) {
            newAction.reset().play();
            this._current.crossFadeTo(newAction, bt, true);
        } else {
            newAction.reset().play();
        }
        
        state.onEnter?.();
        this._states.get(this._currentState)?.onExit?.();
        this._currentState = stateName;
        this._current = newAction;
    }
    
    // Blend two animations by weight (for directional movement)
    blend(stateA, stateB, weight) {
        const actionA = this._actions.get(stateA);
        const actionB = this._actions.get(stateB);
        if (!actionA || !actionB) return;
        
        actionA.weight = 1 - weight;
        actionB.weight = weight;
    }
    
    // One-shot animation (attack, jump, etc.)
    playOnce(clipName, blendTime = 0.1) {
        const clip = this.actor._animClips[clipName];
        if (!clip) return;
        
        const action = this._mixer.clipAction(clip);
        action.loop = THREE.LoopOnce;
        action.clampWhenFinished = false;
        action.reset().play();
        
        if (this._current) {
            this._current.crossFadeTo(action, blendTime, true);
        }
        
        // Return to previous state when done
        this._mixer.addEventListener('finished', (e) => {
            if (e.action === action && this._currentState) {
                this.play(this._currentState, blendTime);
            }
        });
    }
    
    get currentState() { return this._currentState; }
}

// Example usage — Character animator
const animator = player.addComponent(AnimatorComponent);
animator
    .addState('idle',   { clip: 'Idle',   loop: true,  speed: 1.0 })
    .addState('walk',   { clip: 'Walk',   loop: true,  speed: 1.0 })
    .addState('run',    { clip: 'Run',    loop: true,  speed: 1.2 })
    .addState('jump',   { clip: 'Jump',   loop: false, blendTime: 0.1 })
    .addState('death',  { clip: 'Death',  loop: false, blendTime: 0.15 });

animator.play('idle');
```

---

## 2. Audio System

### AudioSystem.js
```javascript
class AudioSystem {
    _context = null;
    _masterGain = null;
    _musicGain = null;
    _sfxGain = null;
    _cache = new Map();  // url → AudioBuffer
    
    async init() {
        // Create on first user interaction (browser policy)
        this._context = new (window.AudioContext || window.webkitAudioContext)();
        
        // Master → Music/SFX gain nodes
        this._masterGain = this._context.createGain();
        this._masterGain.connect(this._context.destination);
        
        this._musicGain = this._context.createGain();
        this._musicGain.connect(this._masterGain);
        
        this._sfxGain = this._context.createGain();
        this._sfxGain.connect(this._masterGain);
        
        // Compressor for consistent volume
        const compressor = this._context.createDynamicsCompressor();
        compressor.threshold.value = -24;
        compressor.knee.value = 30;
        compressor.ratio.value = 12;
        compressor.attack.value = 0.003;
        compressor.release.value = 0.25;
        this._masterGain.connect(compressor);
        compressor.connect(this._context.destination);
        
        // Resume on user interaction (mobile requirement)
        document.addEventListener('touchstart', () => {
            if (this._context.state === 'suspended') {
                this._context.resume();
            }
        }, { once: true });
    }
    
    // Load audio file → AudioBuffer (cached)
    async load(url) {
        if (this._cache.has(url)) return this._cache.get(url);
        
        const response = await fetch(url);
        const arrayBuffer = await response.arrayBuffer();
        const audioBuffer = await this._context.decodeAudioData(arrayBuffer);
        
        this._cache.set(url, audioBuffer);
        return audioBuffer;
    }
    
    // Play one-shot SFX
    async playSFX(url, options = {}) {
        const buffer = await this.load(url);
        const source = this._context.createBufferSource();
        source.buffer = buffer;
        source.playbackRate.value = options.pitch ?? 1.0;
        
        // Optional: random pitch variation for variety
        if (options.pitchVariance) {
            source.playbackRate.value += (Math.random() - 0.5) * options.pitchVariance;
        }
        
        const gainNode = this._context.createGain();
        gainNode.gain.value = options.volume ?? 1.0;
        
        source.connect(gainNode);
        gainNode.connect(this._sfxGain);
        source.start(0, options.offset ?? 0);
        
        return source;
    }
    
    // Play spatial (3D) audio
    async playSpatial(url, position, options = {}) {
        const buffer = await this.load(url);
        const source = this._context.createBufferSource();
        source.buffer = buffer;
        source.loop = options.loop ?? false;
        
        // Panner node for 3D positioning
        const panner = this._context.createPanner();
        panner.panningModel = 'HRTF';
        panner.distanceModel = 'inverse';
        panner.refDistance = options.refDistance ?? 1;
        panner.maxDistance = options.maxDistance ?? 50;
        panner.rolloffFactor = options.rolloff ?? 1;
        panner.setPosition(position.x, position.y, position.z);
        
        source.connect(panner);
        panner.connect(this._sfxGain);
        source.start();
        
        return { source, panner };
    }
    
    // Update listener position (call each frame)
    updateListener(camera) {
        const listener = this._context.listener;
        const pos = camera.position;
        const fwd = new THREE.Vector3();
        camera.getWorldDirection(fwd);
        
        if (listener.positionX) {
            listener.positionX.value = pos.x;
            listener.positionY.value = pos.y;
            listener.positionZ.value = pos.z;
            listener.forwardX.value = fwd.x;
            listener.forwardY.value = fwd.y;
            listener.forwardZ.value = fwd.z;
        } else {
            listener.setPosition(pos.x, pos.y, pos.z);
            listener.setOrientation(fwd.x, fwd.y, fwd.z, 0, 1, 0);
        }
    }
    
    // Background music with crossfade
    _currentMusic = null;
    _currentMusicGain = null;
    
    async playMusic(url, fadeTime = 1.0) {
        const buffer = await this.load(url);
        
        // Fade out current music
        if (this._currentMusicGain) {
            const oldGain = this._currentMusicGain;
            oldGain.gain.linearRampToValueAtTime(0, this._context.currentTime + fadeTime);
            setTimeout(() => oldGain.disconnect(), fadeTime * 1000 + 100);
        }
        
        // Start new music
        const source = this._context.createBufferSource();
        source.buffer = buffer;
        source.loop = true;
        
        const gainNode = this._context.createGain();
        gainNode.gain.value = 0;
        gainNode.gain.linearRampToValueAtTime(1.0, this._context.currentTime + fadeTime);
        
        source.connect(gainNode);
        gainNode.connect(this._musicGain);
        source.start();
        
        this._currentMusic = source;
        this._currentMusicGain = gainNode;
    }
    
    // Volume controls
    setMasterVolume(v) { this._masterGain.gain.value = v; }
    setMusicVolume(v)  { this._musicGain.gain.value = v; }
    setSFXVolume(v)    { this._sfxGain.gain.value = v; }
}
```

---

## 3. Input System

### InputSystem.js — Unified touch + keyboard
```javascript
class InputSystem {
    // Virtual button states
    _buttons = new Map();   // name → { pressed, justPressed, justReleased }
    _axes    = new Map();   // name → float (-1 to 1)
    
    // Raw touch data
    _touches = new Map();   // touchId → { x, y, startX, startY }
    
    // Gesture detection
    _pinchStartDist = 0;
    _lastTapTime = 0;
    
    init() {
        // Touch events
        document.addEventListener('touchstart',  this._onTouchStart.bind(this),  { passive: false });
        document.addEventListener('touchmove',   this._onTouchMove.bind(this),   { passive: false });
        document.addEventListener('touchend',    this._onTouchEnd.bind(this),    { passive: false });
        document.addEventListener('touchcancel', this._onTouchEnd.bind(this),    { passive: false });
        
        // Keyboard (for desktop testing)
        document.addEventListener('keydown', this._onKeyDown.bind(this));
        document.addEventListener('keyup',   this._onKeyUp.bind(this));
        
        // Map keyboard to virtual buttons
        this._keyMap = {
            'ArrowUp': 'up', 'w': 'up',
            'ArrowDown': 'down', 's': 'down',
            'ArrowLeft': 'left', 'a': 'left',
            'ArrowRight': 'right', 'd': 'right',
            ' ': 'jump',
            'e': 'interact',
            'Escape': 'pause'
        };
    }
    
    // Called at start of each frame — reset just-pressed/released
    update() {
        this._buttons.forEach((btn, name) => {
            btn.justPressed  = false;
            btn.justReleased = false;
        });
    }
    
    _setButton(name, pressed) {
        if (!this._buttons.has(name)) {
            this._buttons.set(name, { pressed: false, justPressed: false, justReleased: false });
        }
        const btn = this._buttons.get(name);
        if (pressed && !btn.pressed) btn.justPressed = true;
        if (!pressed && btn.pressed) btn.justReleased = true;
        btn.pressed = pressed;
    }
    
    // Query methods
    isPressed(name)      { return this._buttons.get(name)?.pressed ?? false; }
    isJustPressed(name)  { return this._buttons.get(name)?.justPressed ?? false; }
    isJustReleased(name) { return this._buttons.get(name)?.justReleased ?? false; }
    getAxis(name)        { return this._axes.get(name) ?? 0; }
    
    _onKeyDown(e) {
        const btn = this._keyMap[e.key];
        if (btn) this._setButton(btn, true);
    }
    
    _onKeyUp(e) {
        const btn = this._keyMap[e.key];
        if (btn) this._setButton(btn, false);
    }
    
    _onTouchStart(e) {
        e.preventDefault();
        Array.from(e.changedTouches).forEach(t => {
            this._touches.set(t.identifier, {
                x: t.clientX, y: t.clientY,
                startX: t.clientX, startY: t.clientY,
                startTime: performance.now()
            });
        });
        
        // Pinch detection
        if (e.touches.length === 2) {
            const t1 = e.touches[0], t2 = e.touches[1];
            this._pinchStartDist = Math.hypot(t2.clientX - t1.clientX, t2.clientY - t1.clientY);
        }
        
        EventBus.emit('input:touchstart', { touches: e.changedTouches });
    }
    
    _onTouchMove(e) {
        e.preventDefault();
        Array.from(e.changedTouches).forEach(t => {
            const touch = this._touches.get(t.identifier);
            if (touch) {
                touch.dx = t.clientX - touch.x;
                touch.dy = t.clientY - touch.y;
                touch.x = t.clientX;
                touch.y = t.clientY;
            }
        });
        
        // Pinch zoom
        if (e.touches.length === 2) {
            const t1 = e.touches[0], t2 = e.touches[1];
            const dist = Math.hypot(t2.clientX - t1.clientX, t2.clientY - t1.clientY);
            const delta = dist - this._pinchStartDist;
            this._axes.set('pinch', delta / 100);
            this._pinchStartDist = dist;
            EventBus.emit('input:pinch', { delta });
        }
        
        EventBus.emit('input:touchmove', { touches: e.changedTouches });
    }
    
    _onTouchEnd(e) {
        Array.from(e.changedTouches).forEach(t => {
            const touch = this._touches.get(t.identifier);
            if (touch) {
                const dt = performance.now() - touch.startTime;
                const dx = t.clientX - touch.startX;
                const dy = t.clientY - touch.startY;
                const dist = Math.hypot(dx, dy);
                
                // Tap detection
                if (dist < 10 && dt < 300) {
                    EventBus.emit('input:tap', { x: t.clientX, y: t.clientY });
                    
                    // Double tap
                    if (performance.now() - this._lastTapTime < 300) {
                        EventBus.emit('input:doubletap', { x: t.clientX, y: t.clientY });
                    }
                    this._lastTapTime = performance.now();
                }
                
                // Swipe detection
                if (dist > 50 && dt < 500) {
                    const angle = Math.atan2(dy, dx) * 180 / Math.PI;
                    let dir = 'right';
                    if (angle > -45 && angle <= 45) dir = 'right';
                    else if (angle > 45 && angle <= 135) dir = 'down';
                    else if (angle > 135 || angle <= -135) dir = 'left';
                    else dir = 'up';
                    EventBus.emit('input:swipe', { dir, dx, dy, speed: dist / dt });
                }
            }
            this._touches.delete(t.identifier);
        });
        
        this._axes.set('pinch', 0);
        EventBus.emit('input:touchend', { touches: e.changedTouches });
    }
}
```

---

## 4. Virtual Joystick

```javascript
class VirtualJoystick {
    // On-screen joystick for mobile movement
    _canvas = null;
    _ctx = null;
    _active = false;
    _baseX = 0; _baseY = 0;
    _stickX = 0; _stickY = 0;
    _touchId = null;
    _radius = 60;
    _stickRadius = 25;
    
    // Output axes
    axisX = 0;
    axisY = 0;
    
    init(side = 'left') {
        this._canvas = document.createElement('canvas');
        this._canvas.style.cssText = `
            position: fixed;
            bottom: 20px;
            ${side}: 20px;
            width: 140px;
            height: 140px;
            z-index: 1000;
            pointer-events: none;
            opacity: 0.6;
        `;
        this._canvas.width = 140;
        this._canvas.height = 140;
        this._ctx = this._canvas.getContext('2d');
        document.body.appendChild(this._canvas);
        
        // Touch zone covers left/right half of screen
        const zone = document.createElement('div');
        zone.style.cssText = `
            position: fixed;
            top: 0; bottom: 0;
            ${side}: 0;
            width: 50%;
            z-index: 999;
            touch-action: none;
        `;
        document.body.appendChild(zone);
        
        zone.addEventListener('touchstart', this._onStart.bind(this), { passive: false });
        zone.addEventListener('touchmove',  this._onMove.bind(this),  { passive: false });
        zone.addEventListener('touchend',   this._onEnd.bind(this),   { passive: false });
        
        this._render();
    }
    
    _onStart(e) {
        e.preventDefault();
        const t = e.changedTouches[0];
        this._touchId = t.identifier;
        this._baseX = t.clientX;
        this._baseY = t.clientY;
        this._stickX = t.clientX;
        this._stickY = t.clientY;
        this._active = true;
        
        // Move joystick base to touch position
        this._canvas.style.left = (t.clientX - 70) + 'px';
        this._canvas.style.bottom = (window.innerHeight - t.clientY - 70) + 'px';
    }
    
    _onMove(e) {
        e.preventDefault();
        const t = Array.from(e.changedTouches).find(t => t.identifier === this._touchId);
        if (!t) return;
        
        const dx = t.clientX - this._baseX;
        const dy = t.clientY - this._baseY;
        const dist = Math.min(Math.hypot(dx, dy), this._radius);
        const angle = Math.atan2(dy, dx);
        
        this._stickX = this._baseX + Math.cos(angle) * dist;
        this._stickY = this._baseY + Math.sin(angle) * dist;
        
        this.axisX = Math.cos(angle) * (dist / this._radius);
        this.axisY = Math.sin(angle) * (dist / this._radius);
    }
    
    _onEnd(e) {
        const t = Array.from(e.changedTouches).find(t => t.identifier === this._touchId);
        if (!t) return;
        
        this._active = false;
        this._touchId = null;
        this.axisX = 0;
        this.axisY = 0;
        this._stickX = this._baseX;
        this._stickY = this._baseY;
    }
    
    _render() {
        requestAnimationFrame(this._render.bind(this));
        
        const ctx = this._ctx;
        const cx = 70, cy = 70;
        ctx.clearRect(0, 0, 140, 140);
        
        if (!this._active) {
            // Idle state — small indicator
            ctx.beginPath();
            ctx.arc(cx, cy, this._radius, 0, Math.PI * 2);
            ctx.strokeStyle = 'rgba(255,255,255,0.3)';
            ctx.lineWidth = 2;
            ctx.stroke();
            return;
        }
        
        // Base ring
        ctx.beginPath();
        ctx.arc(cx, cy, this._radius, 0, Math.PI * 2);
        ctx.strokeStyle = 'rgba(255,255,255,0.5)';
        ctx.lineWidth = 3;
        ctx.stroke();
        ctx.fillStyle = 'rgba(255,255,255,0.1)';
        ctx.fill();
        
        // Stick
        const sx = cx + (this._stickX - this._baseX);
        const sy = cy + (this._stickY - this._baseY);
        ctx.beginPath();
        ctx.arc(sx, sy, this._stickRadius, 0, Math.PI * 2);
        ctx.fillStyle = 'rgba(255,255,255,0.7)';
        ctx.fill();
    }
    
    // Get movement vector (normalized)
    getVector() {
        return new THREE.Vector3(this.axisX, 0, this.axisY);
    }
}
```
