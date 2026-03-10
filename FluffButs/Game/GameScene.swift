import SpriteKit

// MARK: - Physics Categories
struct PhysicsCategory {
    static let none:       UInt32 = 0
    static let ground:     UInt32 = 0x1 << 0
    static let dog:        UInt32 = 0x1 << 1
    static let treat:      UInt32 = 0x1 << 2
    static let obstacle:   UInt32 = 0x1 << 3
    static let finishLine: UInt32 = 0x1 << 4
}

// MARK: - GameScene
final class GameScene: SKScene, @preconcurrency SKPhysicsContactDelegate {

    // MARK: Nodes
    private var dogNode: DogNode!
    private var treats: [TreatNode] = []
    private var gameCamera: SKCameraNode!

    // MARK: Breed
    private let breed: DogBreed

    // MARK: Layout
    // Ground surface Y in scene coordinates (Y-up)
    // We position everything relative to this.
    private let groundY: CGFloat = -180

    // MARK: State
    private var isCourseComplete = false

    // MARK: - Init

    init(size: CGSize, breed: DogBreed = .memphis) {
        self.breed = breed
        super.init(size: size)
    }

    required init?(coder: NSCoder) {
        self.breed = .memphis
        super.init(coder: coder)
    }

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        setupPhysicsWorld()
        setupBackground()
        setupGround()
        setupObstacles()
        setupFinishLine()
        setupDog()
        setupCamera()
        setupInitialBones()
        setupHint()
    }

    // MARK: - Physics World

    private func setupPhysicsWorld() {
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        physicsWorld.contactDelegate = self
    }

    // MARK: - Background

    private func setupBackground() {
        // Sky
        let sky = SKShapeNode(rectOf: CGSize(width: 6000, height: 800))
        sky.fillColor = SKColor(red: 0.53, green: 0.81, blue: 0.92, alpha: 1.0)
        sky.strokeColor = .clear
        sky.position = CGPoint(x: 3000, y: groundY + 400)
        sky.zPosition = -2
        addChild(sky)

        // Grass field
        let grass = SKShapeNode(rectOf: CGSize(width: 6000, height: 400))
        grass.fillColor = SKColor(red: 0.40, green: 0.72, blue: 0.30, alpha: 1.0)
        grass.strokeColor = .clear
        grass.position = CGPoint(x: 3000, y: groundY - 200)
        grass.zPosition = -2
        addChild(grass)
    }

    // MARK: - Ground

    private func setupGround() {
        let groundWidth: CGFloat = 6000
        let groundHeight: CGFloat = 60

        // Dirt
        let dirt = SKShapeNode(rectOf: CGSize(width: groundWidth, height: groundHeight))
        dirt.fillColor = SKColor(red: 0.58, green: 0.36, blue: 0.16, alpha: 1.0)
        dirt.strokeColor = .clear
        dirt.position = CGPoint(x: groundWidth / 2 - 200, y: groundY - groundHeight / 2 - 16)
        dirt.zPosition = -1

        let dirtBody = SKPhysicsBody(rectangleOf: CGSize(width: groundWidth, height: groundHeight))
        dirtBody.isDynamic = false
        dirtBody.categoryBitMask = PhysicsCategory.ground
        dirtBody.collisionBitMask = PhysicsCategory.dog
        dirtBody.contactTestBitMask = PhysicsCategory.none
        dirt.physicsBody = dirtBody
        addChild(dirt)

        // Grass strip on top of dirt
        let grassStrip = SKShapeNode(rectOf: CGSize(width: groundWidth, height: 16))
        grassStrip.fillColor = SKColor(red: 0.28, green: 0.62, blue: 0.18, alpha: 1.0)
        grassStrip.strokeColor = .clear
        grassStrip.position = CGPoint(x: groundWidth / 2 - 200, y: groundY - 8)
        grassStrip.zPosition = -1
        addChild(grassStrip)
    }

    // MARK: - Obstacles

    private func setupObstacles() {
        // (x, width, height) — x is in scene world space starting near the dog
        let specs: [(x: CGFloat, w: CGFloat, h: CGFloat)] = [
            (320,  52, 64),
            (620,  66, 88),
            (950,  50, 72),
            (1300, 64, 96)
        ]
        for spec in specs {
            let size = CGSize(width: spec.w, height: spec.h)
            let rock = SKShapeNode(rectOf: size, cornerRadius: 10)
            rock.fillColor = SKColor(red: 0.50, green: 0.32, blue: 0.13, alpha: 1.0)
            rock.strokeColor = SKColor(red: 0.35, green: 0.22, blue: 0.08, alpha: 1.0)
            rock.lineWidth = 2

            // Highlight on top
            let highlight = SKShapeNode(rectOf: CGSize(width: spec.w - 12, height: 8), cornerRadius: 3)
            highlight.fillColor = SKColor(white: 1.0, alpha: 0.18)
            highlight.strokeColor = .clear
            highlight.position = CGPoint(x: 0, y: spec.h / 2 - 8)
            rock.addChild(highlight)

            rock.position = CGPoint(x: spec.x, y: groundY + spec.h / 2)
            addChild(rock)
        }
    }

    // MARK: - Finish Line

    private func setupFinishLine() {
        let finishX: CGFloat = 1700

        let post = SKShapeNode(rectOf: CGSize(width: 8, height: 160), cornerRadius: 4)
        post.fillColor = .white
        post.strokeColor = SKColor(white: 0.7, alpha: 1)
        post.position = CGPoint(x: finishX, y: groundY + 80)
        addChild(post)

        let flagLabel = SKLabelNode(text: "FINISH!")
        flagLabel.fontSize = 20
        flagLabel.fontName = UIFont.boldSystemFont(ofSize: 1).fontName
        flagLabel.fontColor = .white
        flagLabel.verticalAlignmentMode = .center
        flagLabel.horizontalAlignmentMode = .center
        flagLabel.position = CGPoint(x: finishX, y: groundY + 180)

        // Background pill for finish label
        let pill = SKShapeNode(rectOf: CGSize(width: 100, height: 30), cornerRadius: 8)
        pill.fillColor = SKColor(red: 0.20, green: 0.65, blue: 0.25, alpha: 1.0)
        pill.strokeColor = .clear
        pill.position = CGPoint(x: finishX, y: groundY + 180)
        addChild(pill)
        addChild(flagLabel)

        // Physics trigger
        let trigger = SKNode()
        trigger.position = CGPoint(x: finishX, y: groundY + 80)
        let triggerBody = SKPhysicsBody(rectangleOf: CGSize(width: 30, height: 200))
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
        dogNode = DogNode(breed: breed)
        // Start at left side, sitting on the ground
        dogNode.position = CGPoint(x: 60, y: groundY + 50)
        addChild(dogNode)
    }

    // MARK: - Pre-placed Bones

    private func setupInitialBones() {
        let bonePositions: [CGFloat] = [160, 260, 380]
        for x in bonePositions {
            let treat = TreatNode()
            treat.position = CGPoint(x: x, y: groundY + 22)
            addChild(treat)
            treats.append(treat)
        }
    }

    // MARK: - Camera

    private func setupCamera() {
        gameCamera = SKCameraNode()
        camera = gameCamera
        addChild(gameCamera)
        // Start centered on the dog
        gameCamera.position = CGPoint(x: dogNode.position.x, y: 0)
    }

    // MARK: - HUD

    private func setupHint() {
        let bg = SKShapeNode(rectOf: CGSize(width: 280, height: 36), cornerRadius: 18)
        bg.fillColor = SKColor(white: 0, alpha: 0.42)
        bg.strokeColor = .clear
        bg.position = CGPoint(x: 0, y: (size.height / 2) - 80)
        bg.name = "hintBG"

        let hint = SKLabelNode(text: "Tap anywhere to drop a bone!")
        hint.fontSize = 15
        hint.fontName = UIFont.systemFont(ofSize: 1, weight: .medium).fontName
        hint.fontColor = .white
        hint.verticalAlignmentMode = .center
        hint.horizontalAlignmentMode = .center
        hint.name = "hintLabel"

        bg.addChild(hint)
        gameCamera.addChild(bg)

        let wait   = SKAction.wait(forDuration: 4.0)
        let fade   = SKAction.fadeOut(withDuration: 1.0)
        let remove = SKAction.removeFromParent()
        bg.run(SKAction.sequence([wait, fade, remove]))
    }

    // MARK: - Touch

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isCourseComplete, let touch = touches.first else { return }
        let sceneLocation = touch.location(in: self)
        let treatPos = CGPoint(x: sceneLocation.x, y: groundY + 22)
        let treat = TreatNode()
        treat.position = treatPos
        addChild(treat)
        treats.append(treat)
        seekNearestTreat()
    }

    // MARK: - Dog AI

    private func seekNearestTreat() {
        let active = treats.filter { !$0.isCollected }
        guard !active.isEmpty else { return }
        let nearest = active.min {
            hypot($0.position.x - dogNode.position.x, $0.position.y - dogNode.position.y) <
            hypot($1.position.x - dogNode.position.x, $1.position.y - dogNode.position.y)
        }
        if let nearest { dogNode.moveTo(position: nearest.position) }
    }

    // MARK: - Update

    override func update(_ currentTime: TimeInterval) {
        dogNode.updateMovement()

        for treat in treats where !treat.isCollected {
            let dist = hypot(treat.position.x - dogNode.position.x,
                             treat.position.y - dogNode.position.y)
            if dist < 48 {
                treat.collect()
                seekNearestTreat()
            }
        }

        // Smooth camera follow
        let targetX = dogNode.position.x
        let smoothX  = gameCamera.position.x + (targetX - gameCamera.position.x) * 0.12
        gameCamera.position = CGPoint(x: smoothX, y: 0)
    }

    // MARK: - Physics Contact

    func didBegin(_ contact: SKPhysicsContact) {
        let a = contact.bodyA.categoryBitMask, b = contact.bodyB.categoryBitMask
        let isDogFinish = (a == PhysicsCategory.dog && b == PhysicsCategory.finishLine) ||
                          (a == PhysicsCategory.finishLine && b == PhysicsCategory.dog)
        if isDogFinish { handleCourseComplete() }
    }

    // MARK: - Course Complete

    private func handleCourseComplete() {
        guard !isCourseComplete else { return }
        isCourseComplete = true
        dogNode.stopMoving()

        let celebrate = SKLabelNode(text: "Course Complete!")
        celebrate.fontSize = 28
        celebrate.fontName = UIFont.boldSystemFont(ofSize: 1).fontName
        celebrate.fontColor = .white
        celebrate.verticalAlignmentMode = .center
        celebrate.horizontalAlignmentMode = .center
        celebrate.position = CGPoint(x: 0, y: 60)

        let pill = SKShapeNode(rectOf: CGSize(width: 280, height: 50), cornerRadius: 14)
        pill.fillColor = SKColor(red: 0.20, green: 0.65, blue: 0.25, alpha: 0.90)
        pill.strokeColor = .clear
        pill.position = CGPoint(x: 0, y: 60)

        gameCamera.addChild(pill)
        gameCamera.addChild(celebrate)

        celebrate.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.scale(to: 1.1, duration: 0.4),
            SKAction.scale(to: 1.0, duration: 0.4)
        ])))
    }
}
