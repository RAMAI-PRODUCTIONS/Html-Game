# ECS & Gameplay Systems
## Entity-Component-System, Game Loop, State Machines, AI

---

## 1. Entity-Component-System (ECS)

The ECS is the backbone of all gameplay. Inspired by Unreal's Actor-Component model but with data-oriented internals.

### Entity (Actor) Registry

```javascript
class ActorRegistry {
    // Flat typed arrays for cache-friendly iteration
    _ids       = new Uint32Array(10000);
    _active    = new Uint8Array(10000);
    _count     = 0;
    _nextId    = 1;
    
    // Component storage — one array per component type
    _components = new Map();  // ComponentClass → Array
    
    // Tag index for fast lookup
    _tagIndex = new Map();    // tag → Set<actorId>
    
    spawn(config = {}) {
        const id = this._nextId++;
        const idx = this._count++;
        
        this._ids[idx] = id;
        this._active[idx] = 1;
        
        const actor = new Actor(id, config);
        
        // Auto-add components from config
        if (config.components) {
            config.components.forEach(([CompClass, compConfig]) => {
                actor.addComponent(CompClass, compConfig);
            });
        }
        
        // Tag indexing
        if (config.tags) {
            config.tags.forEach(tag => {
                if (!this._tagIndex.has(tag)) this._tagIndex.set(tag, new Set());
                this._tagIndex.get(tag).add(id);
            });
        }
        
        return actor;
    }
    
    destroy(actor) {
        actor.active = false;
        actor.components.forEach(comp => comp.onDetach());
        
        // Remove from tag index
        actor.tags.forEach(tag => {
            this._tagIndex.get(tag)?.delete(actor.id);
        });
        
        // Return to pool
        ObjectPool.release(actor);
    }
    
    // Fast tag query — O(1) lookup
    findByTag(tag) {
        return this._tagIndex.get(tag) ?? new Set();
    }
    
    // Iterate all active actors of a type
    forEach(callback) {
        for (let i = 0; i < this._count; i++) {
            if (this._active[i]) callback(this._actors[i]);
        }
    }
}
```

---

## 2. Component System

```javascript
// Base Component
class Component {
    actor = null;
    enabled = true;
    _tickEnabled = false;
    
    onAttach(actor) { this.actor = actor; }
    onDetach() { this.actor = null; }
    tick(dt) { }
    
    // Convenience accessors
    get transform() { return this.actor.transform; }
    get world() { return this.actor.world; }
    
    // Get sibling component
    getComponent(CompClass) { return this.actor.getComponent(CompClass); }
    
    // Emit event
    emit(event, data) { EventBus.emit(event, { actor: this.actor, ...data }); }
}

// ── Built-in Components ──────────────────────────────────────────────

class MeshComponent extends Component {
    mesh = null;
    castShadow = true;
    receiveShadow = true;
    
    onAttach(actor) {
        super.onAttach(actor);
        // Mesh is set externally after GLB load
    }
    
    setMesh(threeObject) {
        if (this.mesh) scene.remove(this.mesh);
        this.mesh = threeObject;
        this.mesh.castShadow = this.castShadow;
        this.mesh.receiveShadow = this.receiveShadow;
        scene.add(this.mesh);
    }
    
    tick(dt) {
        if (this.mesh) {
            // Sync Three.js object to actor transform
            const t = this.actor.transform;
            this.mesh.position.copy(t.position);
            this.mesh.quaternion.copy(t.rotation);
            this.mesh.scale.copy(t.scale);
        }
    }
    
    onDetach() {
        if (this.mesh) {
            scene.remove(this.mesh);
            this.mesh.geometry?.dispose();
            this.mesh.material?.dispose();
        }
        super.onDetach();
    }
}

class HealthComponent extends Component {
    maxHealth = 100;
    health = 100;
    invincible = false;
    _regenRate = 0;
    
    takeDamage(amount, source = null) {
        if (this.invincible) return;
        
        this.health = Math.max(0, this.health - amount);
        this.emit('damage', { amount, source, remaining: this.health });
        
        if (this.health <= 0) {
            this.emit('death', { source });
            this.actor.onDeath?.(source);
        }
    }
    
    heal(amount) {
        this.health = Math.min(this.maxHealth, this.health + amount);
        this.emit('heal', { amount });
    }
    
    tick(dt) {
        if (this._regenRate > 0 && this.health < this.maxHealth) {
            this.heal(this._regenRate * dt);
        }
    }
    
    get percentage() { return this.health / this.maxHealth; }
    get isDead() { return this.health <= 0; }
}

class MovementComponent extends Component {
    speed = 5.0;
    sprintSpeed = 10.0;
    jumpForce = 8.0;
    _velocity = new THREE.Vector3();
    _isSprinting = false;
    
    moveInDirection(dir, dt) {
        const speed = this._isSprinting ? this.sprintSpeed : this.speed;
        const rb = this.getComponent(RigidBodyComponent);
        
        if (rb) {
            // Physics-based movement
            const force = dir.clone().multiplyScalar(speed * 10);
            rb.addForce(force.x, force.y, force.z);
        } else {
            // Direct transform movement
            const delta = dir.clone().multiplyScalar(speed * dt);
            this.transform.position.add(delta);
        }
    }
    
    jump() {
        const rb = this.getComponent(RigidBodyComponent);
        if (rb) rb.addImpulse(0, this.jumpForce, 0);
    }
    
    lookAt(target) {
        const dir = target.clone().sub(this.transform.position).normalize();
        const angle = Math.atan2(dir.x, dir.z);
        this.transform.rotation.setFromAxisAngle(new THREE.Vector3(0,1,0), angle);
    }
}

class ScriptComponent extends Component {
    // Attach arbitrary gameplay logic
    // Like UE's Blueprint or C++ gameplay class
    
    constructor(scriptObj) {
        super();
        Object.assign(this, scriptObj);
    }
}
```

---

## 3. Game State Machine

```javascript
// Finite State Machine — for game flow (like UE's GameMode states)
class StateMachine {
    _states = new Map();
    _current = null;
    _previous = null;
    
    addState(name, state) {
        this._states.set(name, {
            name,
            onEnter:  state.onEnter  ?? (() => {}),
            onExit:   state.onExit   ?? (() => {}),
            onUpdate: state.onUpdate ?? (() => {}),
            transitions: state.transitions ?? {}
        });
        return this;
    }
    
    start(initialState) {
        this._current = this._states.get(initialState);
        this._current.onEnter(null);
    }
    
    transition(toState, data = {}) {
        if (!this._states.has(toState)) {
            console.warn(`[FSM] Unknown state: ${toState}`);
            return;
        }
        
        this._previous = this._current;
        this._current.onExit(toState, data);
        this._current = this._states.get(toState);
        this._current.onEnter(this._previous?.name, data);
        
        EventBus.emit('state:changed', { from: this._previous?.name, to: toState });
    }
    
    update(dt) {
        this._current?.onUpdate(dt);
    }
    
    get state() { return this._current?.name; }
    get previousState() { return this._previous?.name; }
}

// Example: Game flow state machine
const GameFSM = new StateMachine()
    .addState('BOOT', {
        onEnter: () => { showSplashScreen(); },
        onUpdate: (dt) => { /* loading progress */ },
        transitions: { MENU: 'loadingComplete' }
    })
    .addState('MENU', {
        onEnter: () => { UI.showMainMenu(); },
        onExit:  () => { UI.hideMainMenu(); },
        transitions: { PLAYING: 'startGame', SETTINGS: 'openSettings' }
    })
    .addState('PLAYING', {
        onEnter: (from, data) => { World.load(data.levelId); },
        onUpdate: (dt) => { World.tick(dt); },
        onExit:  () => { World.pause(); },
        transitions: { PAUSED: 'pause', MENU: 'quit', GAMEOVER: 'playerDied' }
    })
    .addState('PAUSED', {
        onEnter: () => { UI.showPauseMenu(); Time.timeScale = 0; },
        onExit:  () => { UI.hidePauseMenu(); Time.timeScale = 1; },
        transitions: { PLAYING: 'resume', MENU: 'quit' }
    })
    .addState('GAMEOVER', {
        onEnter: (from, data) => { UI.showGameOver(data.score); },
        transitions: { PLAYING: 'retry', MENU: 'mainMenu' }
    });
```

---

## 4. AI System

```javascript
// Simple AI for mobile games — behavior trees + steering
class AISystem {
    _agents = [];
    
    // Steering behaviors (like UE's AI Move To)
    static Steering = {
        // Seek: move toward target
        seek(agent, target, speed) {
            const dir = target.clone().sub(agent.position).normalize();
            return dir.multiplyScalar(speed);
        },
        
        // Flee: move away from target
        flee(agent, target, speed) {
            const dir = agent.position.clone().sub(target).normalize();
            return dir.multiplyScalar(speed);
        },
        
        // Arrive: slow down near target
        arrive(agent, target, speed, slowRadius = 3) {
            const toTarget = target.clone().sub(agent.position);
            const dist = toTarget.length();
            
            if (dist < 0.1) return new THREE.Vector3();
            
            const desiredSpeed = dist < slowRadius
                ? speed * (dist / slowRadius)
                : speed;
            
            return toTarget.normalize().multiplyScalar(desiredSpeed);
        },
        
        // Wander: random wandering
        wander(agent, wanderAngle, speed) {
            wanderAngle += (Math.random() - 0.5) * 0.5;
            const dir = new THREE.Vector3(
                Math.sin(wanderAngle),
                0,
                Math.cos(wanderAngle)
            );
            return dir.multiplyScalar(speed);
        },
        
        // Separation: avoid crowding
        separation(agent, neighbors, radius, strength) {
            const force = new THREE.Vector3();
            neighbors.forEach(other => {
                const dist = agent.position.distanceTo(other.position);
                if (dist < radius && dist > 0) {
                    const away = agent.position.clone().sub(other.position);
                    force.add(away.normalize().multiplyScalar(strength / dist));
                }
            });
            return force;
        }
    };
    
    // Simple behavior tree node types
    static BT = {
        // Sequence: run children in order, fail if any fails
        sequence(...children) {
            return (agent, dt) => {
                for (const child of children) {
                    if (!child(agent, dt)) return false;
                }
                return true;
            };
        },
        
        // Selector: run children until one succeeds
        selector(...children) {
            return (agent, dt) => {
                for (const child of children) {
                    if (child(agent, dt)) return true;
                }
                return false;
            };
        },
        
        // Condition check
        condition(fn) {
            return (agent, dt) => fn(agent);
        },
        
        // Action
        action(fn) {
            return (agent, dt) => fn(agent, dt);
        }
    };
}

// Example enemy AI behavior tree
const EnemyBT = AISystem.BT.selector(
    // If player is close, attack
    AISystem.BT.sequence(
        AISystem.BT.condition(agent => agent.distToPlayer < 2),
        AISystem.BT.action((agent, dt) => { agent.attack(); return true; })
    ),
    // If player is visible, chase
    AISystem.BT.sequence(
        AISystem.BT.condition(agent => agent.canSeePlayer),
        AISystem.BT.action((agent, dt) => {
            const vel = AISystem.Steering.arrive(
                agent.transform.position,
                agent.playerPos,
                agent.speed
            );
            agent.getComponent(MovementComponent).moveInDirection(vel, dt);
            return true;
        })
    ),
    // Otherwise, wander
    AISystem.BT.action((agent, dt) => {
        agent._wanderAngle = agent._wanderAngle ?? 0;
        const vel = AISystem.Steering.wander(agent, agent._wanderAngle, 2);
        agent._wanderAngle += (Math.random() - 0.5) * 0.3;
        agent.getComponent(MovementComponent).moveInDirection(vel, dt);
        return true;
    })
);
```

---

## 5. Save / Load System

```javascript
class SaveSystem {
    static SLOT_COUNT = 3;
    
    // Save game state to localStorage
    save(slotIndex, gameState) {
        const data = {
            version: Engine.VERSION,
            timestamp: Date.now(),
            playtime: Timer.totalTime,
            level: gameState.currentLevel,
            player: {
                position: gameState.player.transform.position.toArray(),
                health: gameState.player.getComponent(HealthComponent).health,
                inventory: gameState.inventory.serialize()
            },
            world: gameState.world.serialize(),
            settings: gameState.settings
        };
        
        try {
            localStorage.setItem(`save_${slotIndex}`, JSON.stringify(data));
            return true;
        } catch (e) {
            console.error('[Save] Failed:', e);
            return false;
        }
    }
    
    load(slotIndex) {
        try {
            const raw = localStorage.getItem(`save_${slotIndex}`);
            if (!raw) return null;
            
            const data = JSON.parse(raw);
            
            // Version migration
            if (data.version !== Engine.VERSION) {
                data = this._migrate(data);
            }
            
            return data;
        } catch (e) {
            console.error('[Load] Failed:', e);
            return null;
        }
    }
    
    getSaveInfo(slotIndex) {
        const raw = localStorage.getItem(`save_${slotIndex}`);
        if (!raw) return null;
        
        const data = JSON.parse(raw);
        return {
            exists: true,
            timestamp: data.timestamp,
            level: data.level,
            playtime: data.playtime
        };
    }
    
    deleteSave(slotIndex) {
        localStorage.removeItem(`save_${slotIndex}`);
    }
}
```

---

## 6. Event System (Full Implementation)

```javascript
class EventBus {
    _listeners = new Map();  // event → [{callback, priority, once}]
    _deferred  = [];         // events to fire next frame
    
    on(event, callback, priority = 0) {
        if (!this._listeners.has(event)) {
            this._listeners.set(event, []);
        }
        const list = this._listeners.get(event);
        list.push({ callback, priority, once: false });
        list.sort((a, b) => b.priority - a.priority);
        
        // Return unsubscribe function
        return () => this.off(event, callback);
    }
    
    once(event, callback) {
        if (!this._listeners.has(event)) {
            this._listeners.set(event, []);
        }
        this._listeners.get(event).push({ callback, priority: 0, once: true });
    }
    
    off(event, callback) {
        const list = this._listeners.get(event);
        if (!list) return;
        const idx = list.findIndex(l => l.callback === callback);
        if (idx !== -1) list.splice(idx, 1);
    }
    
    emit(event, data = {}) {
        const list = this._listeners.get(event);
        if (!list) return;
        
        // Iterate copy to allow unsubscribe during emit
        [...list].forEach(listener => {
            listener.callback(data);
            if (listener.once) this.off(event, listener.callback);
        });
    }
    
    // Fire next frame (safe for physics callbacks)
    emitDeferred(event, data = {}) {
        this._deferred.push({ event, data });
    }
    
    flushDeferred() {
        const pending = this._deferred.splice(0);
        pending.forEach(({ event, data }) => this.emit(event, data));
    }
}

// Global singleton
const EventBus = new EventBus();

// Usage examples:
EventBus.on('player:died', ({ actor, killer }) => {
    UI.showDeathScreen();
    Analytics.track('player_death', { level: World.currentLevel });
});

EventBus.on('enemy:killed', ({ actor, reward }) => {
    Score.add(reward);
    SpawnSystem.onEnemyKilled(actor);
});

EventBus.on('collision:begin', ({ actor1, actor2 }) => {
    if (actor1.hasTag('bullet') && actor2.hasTag('enemy')) {
        actor2.getComponent(HealthComponent).takeDamage(25, actor1);
        actor1.destroy();
    }
});
```
