# Physics System — Rapier.js Integration
## Rigid Body, Collision, Raycasting for AAA Mobile

---

## Physics Engine Choice

| Option | Size | Performance | Mobile | Recommendation |
|--------|------|-------------|--------|----------------|
| Cannon.js | 150KB | Good | ✅ | Legacy, no longer maintained |
| Cannon-es | 150KB | Good | ✅ | Modern fork, good choice |
| Rapier.js | 800KB WASM | Excellent | ✅ | **Best choice — Rust-based, deterministic** |
| Ammo.js | 1.5MB | Excellent | ⚠️ | Too heavy for mobile |
| Custom AABB | 5KB | Basic | ✅ | For simple games only |

**Recommendation: Rapier.js** for AAA titles, **custom AABB** for simple games.

---

## 1. Physics System Architecture

```javascript
class PhysicsSystem {
    _world = null;          // Rapier.World
    _bodies = new Map();    // actorId → RigidBody
    _colliders = new Map(); // actorId → Collider
    _eventQueue = null;     // collision events
    
    // Fixed timestep — same as Unreal default
    FIXED_DT = 1 / 60;
    
    async init() {
        // Load Rapier WASM
        await RAPIER.init();
        
        const gravity = { x: 0.0, y: -9.81, z: 0.0 };
        this._world = new RAPIER.World(gravity);
        this._eventQueue = new RAPIER.EventQueue(true);
    }
    
    step(dt) {
        this._world.step(this._eventQueue);
        this._syncTransforms();
        this._processCollisionEvents();
    }
    
    // Sync physics positions → Three.js transforms
    _syncTransforms() {
        this._bodies.forEach((body, actorId) => {
            if (body.isFixed()) return;
            
            const pos = body.translation();
            const rot = body.rotation();
            
            const actor = World.findById(actorId);
            if (actor) {
                actor.transform.position.set(pos.x, pos.y, pos.z);
                actor.transform.rotation.set(rot.x, rot.y, rot.z, rot.w);
            }
        });
    }
    
    // Process collision events — fire to EventBus
    _processCollisionEvents() {
        this._eventQueue.drainCollisionEvents((h1, h2, started) => {
            const actor1 = this._getActorByHandle(h1);
            const actor2 = this._getActorByHandle(h2);
            
            if (started) {
                EventBus.emit('collision:begin', { actor1, actor2 });
                actor1?.onCollisionBegin?.(actor2);
                actor2?.onCollisionBegin?.(actor1);
            } else {
                EventBus.emit('collision:end', { actor1, actor2 });
                actor1?.onCollisionEnd?.(actor2);
                actor2?.onCollisionEnd?.(actor1);
            }
        });
    }
}
```

---

## 2. Rigid Body Component

```javascript
class RigidBodyComponent extends Component {
    _body = null;
    
    // Body types (like UE's Physics Body)
    static TYPE = {
        DYNAMIC:   'dynamic',    // affected by forces
        KINEMATIC: 'kinematic',  // moved by code, affects others
        FIXED:     'fixed'       // immovable (static geometry)
    };
    
    onAttach(actor) {
        super.onAttach(actor);
        
        const pos = actor.transform.position;
        const rot = actor.transform.rotation;
        
        let bodyDesc;
        switch (this.config.type) {
            case RigidBodyComponent.TYPE.DYNAMIC:
                bodyDesc = RAPIER.RigidBodyDesc.dynamic();
                break;
            case RigidBodyComponent.TYPE.KINEMATIC:
                bodyDesc = RAPIER.RigidBodyDesc.kinematicPositionBased();
                break;
            default:
                bodyDesc = RAPIER.RigidBodyDesc.fixed();
        }
        
        bodyDesc.setTranslation(pos.x, pos.y, pos.z);
        bodyDesc.setRotation({ x: rot.x, y: rot.y, z: rot.z, w: rot.w });
        
        // Linear/angular damping (air resistance)
        bodyDesc.setLinearDamping(this.config.linearDamping ?? 0.1);
        bodyDesc.setAngularDamping(this.config.angularDamping ?? 0.1);
        
        this._body = physics._world.createRigidBody(bodyDesc);
        physics._bodies.set(actor.id, this._body);
    }
    
    // Apply forces (like UE's AddForce)
    addForce(x, y, z) {
        this._body.addForce({ x, y, z }, true);
    }
    
    // Instant velocity change (like UE's AddImpulse)
    addImpulse(x, y, z) {
        this._body.applyImpulse({ x, y, z }, true);
    }
    
    // Set velocity directly (for kinematic bodies)
    setVelocity(x, y, z) {
        this._body.setLinvel({ x, y, z }, true);
    }
    
    getVelocity() {
        return this._body.linvel();
    }
    
    // Teleport (bypass physics)
    setPosition(x, y, z) {
        this._body.setTranslation({ x, y, z }, true);
    }
}
```

---

## 3. Collider Component

```javascript
class ColliderComponent extends Component {
    _collider = null;
    
    // Collider shapes
    static SHAPE = {
        BOX:      'box',
        SPHERE:   'sphere',
        CAPSULE:  'capsule',
        CYLINDER: 'cylinder',
        MESH:     'mesh',       // trimesh — expensive, use sparingly
        CONVEX:   'convex'      // convex hull — better than trimesh
    };
    
    onAttach(actor) {
        super.onAttach(actor);
        
        const body = physics._bodies.get(actor.id);
        let colliderDesc;
        
        switch (this.config.shape) {
            case ColliderComponent.SHAPE.BOX:
                colliderDesc = RAPIER.ColliderDesc.cuboid(
                    this.config.halfX ?? 0.5,
                    this.config.halfY ?? 0.5,
                    this.config.halfZ ?? 0.5
                );
                break;
            case ColliderComponent.SHAPE.SPHERE:
                colliderDesc = RAPIER.ColliderDesc.ball(this.config.radius ?? 0.5);
                break;
            case ColliderComponent.SHAPE.CAPSULE:
                colliderDesc = RAPIER.ColliderDesc.capsule(
                    this.config.halfHeight ?? 0.5,
                    this.config.radius ?? 0.25
                );
                break;
            case ColliderComponent.SHAPE.CONVEX:
                // Build convex hull from mesh vertices
                const verts = this._extractVertices(actor);
                colliderDesc = RAPIER.ColliderDesc.convexHull(verts);
                break;
        }
        
        // Physics material
        colliderDesc.setFriction(this.config.friction ?? 0.5);
        colliderDesc.setRestitution(this.config.restitution ?? 0.3);  // bounciness
        colliderDesc.setDensity(this.config.density ?? 1.0);
        
        // Collision groups (like UE's collision channels)
        colliderDesc.setCollisionGroups(this.config.group ?? 0xFFFFFFFF);
        colliderDesc.setSolverGroups(this.config.solverGroup ?? 0xFFFFFFFF);
        
        // Sensor (trigger volume — no physical response)
        if (this.config.isSensor) {
            colliderDesc.setSensor(true);
        }
        
        this._collider = physics._world.createCollider(colliderDesc, body);
        physics._colliders.set(actor.id, this._collider);
    }
}
```

---

## 4. Raycasting

```javascript
class Raycast {
    // Single ray query (like UE's LineTraceSingleByChannel)
    static single(origin, direction, maxDist = 100, filter = null) {
        const ray = new RAPIER.Ray(
            { x: origin.x, y: origin.y, z: origin.z },
            { x: direction.x, y: direction.y, z: direction.z }
        );
        
        const hit = physics._world.castRay(ray, maxDist, true, filter);
        
        if (!hit) return null;
        
        const hitPoint = ray.pointAt(hit.toi);
        const actor = physics._getActorByHandle(hit.collider.handle);
        
        return {
            actor,
            point: new THREE.Vector3(hitPoint.x, hitPoint.y, hitPoint.z),
            normal: hit.normal ? new THREE.Vector3(hit.normal.x, hit.normal.y, hit.normal.z) : null,
            distance: hit.toi
        };
    }
    
    // Multi-hit ray (like UE's LineTraceMultiByChannel)
    static multi(origin, direction, maxDist = 100) {
        const results = [];
        const ray = new RAPIER.Ray(
            { x: origin.x, y: origin.y, z: origin.z },
            { x: direction.x, y: direction.y, z: direction.z }
        );
        
        physics._world.intersectionsWithRay(ray, maxDist, true, (hit) => {
            const hitPoint = ray.pointAt(hit.toi);
            results.push({
                actor: physics._getActorByHandle(hit.collider.handle),
                point: new THREE.Vector3(hitPoint.x, hitPoint.y, hitPoint.z),
                distance: hit.toi
            });
            return true; // continue
        });
        
        return results.sort((a, b) => a.distance - b.distance);
    }
    
    // Screen-to-world ray (for touch picking)
    static fromScreen(screenX, screenY, camera) {
        const ndc = new THREE.Vector2(
            (screenX / window.innerWidth) * 2 - 1,
            -(screenY / window.innerHeight) * 2 + 1
        );
        
        const raycaster = new THREE.Raycaster();
        raycaster.setFromCamera(ndc, camera);
        
        return Raycast.single(
            raycaster.ray.origin,
            raycaster.ray.direction
        );
    }
    
    // Sphere overlap (like UE's OverlapMultiByChannel)
    static overlapSphere(center, radius) {
        const shape = new RAPIER.Ball(radius);
        const results = [];
        
        physics._world.intersectionsWithShape(
            { x: center.x, y: center.y, z: center.z },
            { x: 0, y: 0, z: 0, w: 1 },
            shape,
            (collider) => {
                results.push(physics._getActorByHandle(collider.handle));
                return true;
            }
        );
        
        return results;
    }
}
```

---

## 5. Character Controller (for Player/NPCs)

```javascript
class CharacterController {
    // Kinematic character controller — like UE's CharacterMovementComponent
    _controller = null;
    _body = null;
    
    init(actor, config = {}) {
        this._controller = physics._world.createCharacterController(0.01); // offset
        
        // Slope limit (45 degrees)
        this._controller.setMaxSlopeClimbAngle(45 * Math.PI / 180);
        this._controller.setMinSlopeSlideAngle(30 * Math.PI / 180);
        
        // Auto step-up height
        this._controller.enableAutostep(0.5, 0.2, true);
        
        // Snap to ground
        this._controller.enableSnapToGround(0.5);
        
        this._body = physics._bodies.get(actor.id);
        this._collider = physics._colliders.get(actor.id);
    }
    
    move(desiredTranslation, dt) {
        this._controller.computeColliderMovement(
            this._collider,
            { x: desiredTranslation.x, y: desiredTranslation.y, z: desiredTranslation.z }
        );
        
        const corrected = this._controller.computedMovement();
        const pos = this._body.translation();
        
        this._body.setNextKinematicTranslation({
            x: pos.x + corrected.x,
            y: pos.y + corrected.y,
            z: pos.z + corrected.z
        });
    }
    
    isGrounded() {
        return this._controller.computedGrounded();
    }
}
```

---

## 6. Lightweight AABB Physics (No WASM — for simple games)

```javascript
// Zero-dependency physics for simple mobile games
// Suitable for: platformers, top-down, casual games
class SimplePhysics {
    _bodies = [];
    gravity = -20;
    
    createBody(config) {
        return {
            x: config.x, y: config.y, z: config.z,
            vx: 0, vy: 0, vz: 0,
            w: config.w ?? 1, h: config.h ?? 1, d: config.d ?? 1,
            mass: config.mass ?? 1,
            isStatic: config.isStatic ?? false,
            restitution: config.restitution ?? 0.3,
            friction: config.friction ?? 0.5,
            onGround: false
        };
    }
    
    step(dt) {
        this._bodies.forEach(b => {
            if (b.isStatic) return;
            
            // Gravity
            b.vy += this.gravity * dt;
            
            // Integrate
            b.x += b.vx * dt;
            b.y += b.vy * dt;
            b.z += b.vz * dt;
            
            // Ground plane
            if (b.y - b.h/2 < 0) {
                b.y = b.h/2;
                b.vy = -b.vy * b.restitution;
                b.vx *= (1 - b.friction * dt);
                b.vz *= (1 - b.friction * dt);
                b.onGround = true;
            } else {
                b.onGround = false;
            }
        });
        
        // AABB vs AABB collision
        this._resolveCollisions();
    }
    
    _aabbOverlap(a, b) {
        return Math.abs(a.x - b.x) < (a.w + b.w) / 2 &&
               Math.abs(a.y - b.y) < (a.h + b.h) / 2 &&
               Math.abs(a.z - b.z) < (a.d + b.d) / 2;
    }
}
```
