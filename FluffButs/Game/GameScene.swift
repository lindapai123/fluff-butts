import SpriteKit

// MARK: - Physics Categories
struct PhysicsCategory {
    static let none:       UInt32 = 0
    static let ground:     UInt32 = 0x1 << 0   // 1
    static let dog:        UInt32 = 0x1 << 1   // 2
    static let treat:      UInt32 = 0x1 << 2   // 4
    static let obstacle:   UInt32 = 0x1 << 3   // 8
    static let finishLine: UInt32 = 0x1 << 4   // 16
}

// MARK: - GameScene
final class GameScene: SKScene, SKPhysicsContactDelegate {

    // MARK: Nodes
    private var dogNode: DogNode!
    private var treats: [TreatNode] = []
    private var gameCamera: SKCameraNode!

    // MARK: Layout constants (set in didMove)
    private var groundSurfaceY: CGFloat = 0   // Top of the grass layer

    // MARK: State
    private var isCourseComplete = false

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        setupScene()
        setupPhysics()
        setupGround()
        setupObstacles()
        setupFinishLine()
        setupDog()
        setupCamera()
        setupStartLabel()
    }

    // MARK: - Scene Setup

    private func setupScene() {
        // Warm grass-green background
        backgroundColor = SKColor(red: 0.40, green: 0.68, blue: 0.30, alpha: 1.0)
    }

    private func setupPhysics() {
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        physicsWorld.contactDelegate = self
    }

    // MARK: - Ground

    private func setupGround() {
        let groundHeight: CGFloat = 80
        let grassHeight:  CGFloat = 18
        let courseWidth:  CGFloat = 5000

        // The Y coordinate of the top surface dogs/treats stand on
        groundSurfaceY = frame.minY + groundHeight + grassHeight

        // --- Dirt layer ---
        let dirtSize = CGSize(width: courseWidth, height: groundHeight)
        let dirt = SKShapeNode(rectOf: dirtSize)
        dirt.fillColor = SKColor(red: 0.58, green: 0.36, blue: 0.16, alpha: 1.0)
        dirt.strokeColor = .clear
        // Centre the wide rect so the course starts at the left edge of the screen
        dirt.position = CGPoint(
            x: courseWidth / 2 + frame.minX,
            y: frame.minY + groundHeight / 2
        )

        let dirtBody = SKPhysicsBody(rectangleOf: dirtSize)
        dirtBody.isDynamic = false
        dirtBody.categoryBitMask = PhysicsCategory.ground
        dirtBody.collisionBitMask = PhysicsCategory.dog
        dirtBody.contactTestBitMask = PhysicsCategory.none
        dirt.physicsBody = dirtBody
        addChild(dirt)

        // --- Grass strip on top ---
        let grassSize = CGSize(width: courseWidth, height: grassHeight)
        let grass = SKShapeNode(rectOf: grassSize)
        grass.fillColor = SKColor(red: 0.28, green: 0.60, blue: 0.16, alpha: 1.0)
        grass.strokeColor = .clear
        grass.position = CGPoint(
            x: courseWidth / 2 + frame.minX,
            y: frame.minY + groundHeight + grassHeight / 2
        )
        addChild(grass)
    }

    // MARK: - Obstacles (visual only — rocks/barriers the player steers around)

    private func setupObstacles() {
        // (x, width, height) — positioned in world space; dog starts near x = 0
        let specs: [(x: CGFloat, w: CGFloat, h: CGFloat)] = [
            (380,  58, 72),
            (730,  72, 115),
            (1080, 52, 84),
            (1480, 68, 98)
        ]

        for spec in specs {
            let size = CGSize(width: spec.w, height: spec.h)
            let rock = SKShapeNode(rectOf: size, cornerRadius: 10)
            rock.fillColor = SKColor(red: 0.50, green: 0.32, blue: 0.13, alpha: 1.0)
            rock.strokeColor = SKColor(red: 0.35, green: 0.22, blue: 0.08, alpha: 1.0)
            rock.lineWidth = 2
            rock.position = CGPoint(x: spec.x, y: groundSurfaceY + spec.h / 2)
            addChild(rock)
        }
    }

    // MARK: - Finish Line

    private func setupFinishLine() {
        let finishX: CGFloat = 1900
        let postHeight: CGFloat = 180

        // Post
        let post = SKShapeNode(rectOf: CGSize(width: 8, height: postHeight), cornerRadius: 4)
        post.fillColor = .white
        post.strokeColor = SKColor(white: 0.7, alpha: 1.0)
        post.position = CGPoint(x: finishX, y: groundSurfaceY + postHeight / 2)
        addChild(post)

        // Finish flag emoji
        let flag = SKLabelNode(text: "🏁")
        flag.fontSize = 54
        flag.verticalAlignmentMode = .center
        flag.horizontalAlignmentMode = .left
        flag.position = CGPoint(x: finishX + 6, y: groundSurfaceY + postHeight - 18)
        addChild(flag)

        // FINISH text
        let finishLabel = SKLabelNode(text: "FINISH!")
        finishLabel.fontSize = 18
        finishLabel.fontName = "AvenirNext-Bold"
        finishLabel.fontColor = .white
        finishLabel.verticalAlignmentMode = .center
        finishLabel.horizontalAlignmentMode = .center
        finishLabel.position = CGPoint(x: finishX, y: groundSurfaceY + postHeight + 22)
        addChild(finishLabel)

        // Invisible physics sensor so we detect when the dog arrives
        let triggerSize = CGSize(width: 30, height: postHeight + 80)
        let trigger = SKNode()
        trigger.position = CGPoint(x: finishX, y: groundSurfaceY + triggerSize.height / 2)

        let triggerBody = SKPhysicsBody(rectangleOf: triggerSize)
        triggerBody.isDynamic = false
        triggerBody.affectedByGravity = false
        triggerBody.categoryBitMask = PhysicsCategory.finishLine
        triggerBody.collisionBitMask = PhysicsCategory.none
        triggerBody.contactTestBitMask = PhysicsCategory.dog
        trigger.physicsBody = triggerBody
        addChild(trigger)
    }

    // MARK: - Dog

    private func setupDog() {
        dogNode = DogNode()
        // Start near the left side, sitting on the ground surface
        dogNode.position = CGPoint(x: -80, y: groundSurfaceY + 32)
        addChild(dogNode)
    }

    // MARK: - Camera

    private func setupCamera() {
        gameCamera = SKCameraNode()
        camera = gameCamera
        addChild(gameCamera)
        // Start centred on the dog
        gameCamera.position = CGPoint(x: dogNode.position.x, y: frame.midY)
    }

    // MARK: - HUD

    private func setupStartLabel() {
        // "TAP TO DROP A BONE" hint — shown in camera space so it stays on screen
        let hint = SKLabelNode(text: "Tap anywhere to drop a bone 🦴")
        hint.fontSize = 16
        hint.fontName = "AvenirNext-Medium"
        hint.fontColor = SKColor(white: 1.0, alpha: 0.85)
        hint.verticalAlignmentMode = .center
        hint.horizontalAlignmentMode = .center
        hint.position = CGPoint(x: 0, y: frame.height / 2 - 60)
        hint.name = "hintLabel"

        // Fade out after 4 seconds
        let wait   = SKAction.wait(forDuration: 4.0)
        let fade   = SKAction.fadeOut(withDuration: 1.0)
        let remove = SKAction.removeFromParent()
        hint.run(SKAction.sequence([wait, fade, remove]))

        gameCamera.addChild(hint)
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isCourseComplete, let touch = touches.first else { return }

        // location(in: self) already accounts for the camera transform
        let sceneLocation = touch.location(in: self)

        // Drop treat on the ground surface at the tapped X position
        let treatPos = CGPoint(x: sceneLocation.x, y: groundSurfaceY + 22)
        let treat = TreatNode()
        treat.position = treatPos
        addChild(treat)
        treats.append(treat)

        // Direct the dog toward the nearest uncollected treat
        seekNearestTreat()
    }

    // MARK: - Dog AI

    private func seekNearestTreat() {
        let active = treats.filter { !$0.isCollected }
        guard !active.isEmpty else { return }

        // Pick the treat closest to the dog (by straight-line distance)
        let nearest = active.min { a, b in
            let da = hypot(a.position.x - dogNode.position.x,
                           a.position.y - dogNode.position.y)
            let db = hypot(b.position.x - dogNode.position.x,
                           b.position.y - dogNode.position.y)
            return da < db
        }

        if let nearest = nearest {
            dogNode.moveTo(position: nearest.position)
        }
    }

    // MARK: - Update Loop

    override func update(_ currentTime: TimeInterval) {
        // 1. Apply dog physics velocity toward its target
        dogNode.updateMovement()

        // 2. Check if the dog has reached any treat
        for treat in treats where !treat.isCollected {
            let dist = hypot(treat.position.x - dogNode.position.x,
                             treat.position.y - dogNode.position.y)
            if dist < 48 {
                treat.collect()
                // After collecting, head for the next nearest treat
                seekNearestTreat()
            }
        }

        // 3. Smooth camera follow on the X axis; Y stays at scene mid
        let targetX = dogNode.position.x
        let currentX = gameCamera.position.x
        let smoothedX = currentX + (targetX - currentX) * 0.12
        gameCamera.position = CGPoint(x: smoothedX, y: frame.midY)
    }

    // MARK: - Physics Contact

    func didBegin(_ contact: SKPhysicsContact) {
        let maskA = contact.bodyA.categoryBitMask
        let maskB = contact.bodyB.categoryBitMask

        let dogHitsFinish =
            (maskA == PhysicsCategory.dog   && maskB == PhysicsCategory.finishLine) ||
            (maskA == PhysicsCategory.finishLine && maskB == PhysicsCategory.dog)

        if dogHitsFinish {
            handleCourseComplete()
        }
    }

    // MARK: - Course Complete

    private func handleCourseComplete() {
        guard !isCourseComplete else { return }
        isCourseComplete = true
        dogNode.stopMoving()

        print("Course complete! 🎉")

        // Big celebration label — added to camera so it stays centred on screen
        let celebrate = SKLabelNode(text: "🎉 Course Complete! 🐾")
        celebrate.fontSize = 30
        celebrate.fontName = "AvenirNext-Bold"
        celebrate.fontColor = .white
        celebrate.verticalAlignmentMode = .center
        celebrate.horizontalAlignmentMode = .center
        celebrate.position = CGPoint(x: 0, y: 60)

        // Shadow
        let shadow = SKLabelNode(text: "🎉 Course Complete! 🐾")
        shadow.fontSize = 30
        shadow.fontName = "AvenirNext-Bold"
        shadow.fontColor = SKColor(white: 0, alpha: 0.3)
        shadow.verticalAlignmentMode = .center
        shadow.horizontalAlignmentMode = .center
        shadow.position = CGPoint(x: 2, y: 58)
        gameCamera.addChild(shadow)
        gameCamera.addChild(celebrate)

        // Gentle pulse
        let scaleUp   = SKAction.scale(to: 1.15, duration: 0.4)
        let scaleDown = SKAction.scale(to: 1.0,  duration: 0.4)
        celebrate.run(SKAction.repeatForever(SKAction.sequence([scaleUp, scaleDown])))

        // Sub-label
        let sub = SKLabelNode(text: "Tap Play Now to try again!")
        sub.fontSize = 16
        sub.fontName = "AvenirNext-Medium"
        sub.fontColor = SKColor(white: 1.0, alpha: 0.85)
        sub.verticalAlignmentMode = .center
        sub.horizontalAlignmentMode = .center
        sub.position = CGPoint(x: 0, y: 28)
        gameCamera.addChild(sub)
    }
}
