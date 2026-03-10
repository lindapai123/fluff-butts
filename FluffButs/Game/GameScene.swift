import SpriteKit

// MARK: - Physics Categories
struct PhysicsCategory {
    static let none:       UInt32 = 0
    static let ground:     UInt32 = 0x1 << 0
    static let dog:        UInt32 = 0x1 << 1
    static let treat:      UInt32 = 0x1 << 2
    static let obstacle:   UInt32 = 0x1 << 3
    static let finishLine: UInt32 = 0x1 << 4
    static let water:      UInt32 = 0x1 << 5
}

// MARK: - GameScene
final class GameScene: SKScene, @preconcurrency SKPhysicsContactDelegate {

    // MARK: Nodes
    private var dogNode: DogNode!
    private var treats: [TreatNode] = []
    private var gameCamera: SKCameraNode!

    // MARK: Breed & State
    private let breed: DogBreed
    private var isCourseComplete = false
    private var hitObstacleCount = 0
    private var gotWet = false
    private var lastUpdateTime: TimeInterval = 0

    // MARK: Bones
    static let totalCourseBonesCount = 5
    private var bonesCollected = 0

    // MARK: Callback — fires when course is complete
    var onCourseComplete: ((GameResult) -> Void)?

    // MARK: Layout
    private let groundY: CGFloat = -180

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
        setupCourse()   // obstacles + bones + puddles + finish line
        setupDog()
        setupCamera()
        setupHUD()
    }

    // MARK: - Physics World

    private func setupPhysicsWorld() {
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        physicsWorld.contactDelegate = self
    }

    // MARK: - Background

    private func setupBackground() {
        // Clouds
        for cloudX in stride(from: 200, through: 1800, by: 340) {
            addCloud(at: CGPoint(x: CGFloat(cloudX),
                                y: groundY + CGFloat.random(in: 200...360)))
        }
        // Sky gradient rectangle
        let sky = SKShapeNode(rectOf: CGSize(width: 6000, height: 800))
        sky.fillColor = SKColor(red: 0.53, green: 0.81, blue: 0.92, alpha: 1.0)
        sky.strokeColor = .clear
        sky.position = CGPoint(x: 3000, y: groundY + 400)
        sky.zPosition = -3
        addChild(sky)

        // Grass field
        let grass = SKShapeNode(rectOf: CGSize(width: 6000, height: 400))
        grass.fillColor = SKColor(red: 0.40, green: 0.72, blue: 0.30, alpha: 1.0)
        grass.strokeColor = .clear
        grass.position = CGPoint(x: 3000, y: groundY - 200)
        grass.zPosition = -3
        addChild(grass)
    }

    private func addCloud(at pos: CGPoint) {
        let cloud = SKNode()
        cloud.position = pos
        cloud.zPosition = -2

        let blobs: [(CGFloat, CGFloat, CGFloat)] = [(0, 0, 26), (-24, -8, 20), (24, -8, 20), (0, -14, 22)]
        for (bx, by, r) in blobs {
            let b = SKShapeNode(circleOfRadius: r)
            b.fillColor = .white
            b.strokeColor = .clear
            b.alpha = 0.90
            b.position = CGPoint(x: bx, y: by)
            cloud.addChild(b)
        }
        addChild(cloud)
        // Slow drift
        let drift = SKAction.moveBy(x: CGFloat.random(in: -30...30), y: 0, duration: 8.0)
        cloud.run(SKAction.repeatForever(SKAction.sequence([drift, drift.reversed()])))
    }

    // MARK: - Ground

    private func setupGround() {
        let groundWidth: CGFloat = 6000
        let groundHeight: CGFloat = 60

        let dirt = SKShapeNode(rectOf: CGSize(width: groundWidth, height: groundHeight))
        dirt.fillColor = SKColor(red: 0.58, green: 0.36, blue: 0.16, alpha: 1.0)
        dirt.strokeColor = .clear
        dirt.position = CGPoint(x: groundWidth / 2 - 200, y: groundY - groundHeight / 2 - 16)
        dirt.zPosition = -1

        let dirtBody = SKPhysicsBody(rectangleOf: CGSize(width: groundWidth, height: groundHeight))
        dirtBody.isDynamic = false
        dirtBody.categoryBitMask    = PhysicsCategory.ground
        dirtBody.collisionBitMask   = PhysicsCategory.dog
        dirtBody.contactTestBitMask = PhysicsCategory.none
        dirt.physicsBody = dirtBody
        addChild(dirt)

        let grassStrip = SKShapeNode(rectOf: CGSize(width: groundWidth, height: 16))
        grassStrip.fillColor = SKColor(red: 0.28, green: 0.62, blue: 0.18, alpha: 1.0)
        grassStrip.strokeColor = .clear
        grassStrip.position = CGPoint(x: groundWidth / 2 - 200, y: groundY - 8)
        grassStrip.zPosition = -1
        addChild(grassStrip)
    }

    // MARK: - Course (obstacles + puddles + bones + finish)

    // Layout:  Dog(60) — Bone(150) — Rock(300) — Bone(450) — Puddle(580) — Rock(720)
    //          — Bone(850) — Rock(980) — Bone(1100) — Rock(1280) — Bone(1420) — Finish(1650)
    private func setupCourse() {
        // Rocks: (x, w, h)
        let rocks: [(CGFloat, CGFloat, CGFloat)] = [
            (300, 52, 64),
            (720, 66, 88),
            (980, 50, 72),
            (1280, 64, 96)
        ]
        for r in rocks { addRock(x: r.0, w: r.1, h: r.2) }

        // Water puddles: (x, width)
        let puddles: [(CGFloat, CGFloat)] = [(580, 100), (1130, 80)]
        for p in puddles { addPuddle(x: p.0, width: p.1) }

        // 5 bones spread across the course
        let boneXs: [CGFloat] = [150, 450, 850, 1100, 1420]
        for x in boneXs {
            let treat = TreatNode()
            treat.position = CGPoint(x: x, y: groundY + 22)
            addChild(treat)
            treats.append(treat)
        }

        setupFinishLine(at: 1650)
    }

    private func addRock(x: CGFloat, w: CGFloat, h: CGFloat) {
        let rock = SKShapeNode(rectOf: CGSize(width: w, height: h), cornerRadius: 10)
        rock.fillColor = SKColor(red: 0.50, green: 0.32, blue: 0.13, alpha: 1.0)
        rock.strokeColor = SKColor(red: 0.35, green: 0.22, blue: 0.08, alpha: 1.0)
        rock.lineWidth = 2
        rock.position = CGPoint(x: x, y: groundY + h / 2)

        // Highlight stripe
        let hi = SKShapeNode(rectOf: CGSize(width: w - 12, height: 8), cornerRadius: 3)
        hi.fillColor = SKColor(white: 1.0, alpha: 0.18)
        hi.strokeColor = .clear
        hi.position = CGPoint(x: 0, y: h / 2 - 8)
        rock.addChild(hi)

        // Physics — solid wall
        let body = SKPhysicsBody(rectangleOf: CGSize(width: w, height: h))
        body.isDynamic = false
        body.categoryBitMask    = PhysicsCategory.obstacle
        body.collisionBitMask   = PhysicsCategory.dog
        body.contactTestBitMask = PhysicsCategory.dog
        rock.physicsBody = body
        addChild(rock)
    }

    private func addPuddle(x: CGFloat, width: CGFloat) {
        let puddle = SKShapeNode(rectOf: CGSize(width: width, height: 12), cornerRadius: 6)
        puddle.fillColor = SKColor(red: 0.30, green: 0.65, blue: 0.95, alpha: 0.75)
        puddle.strokeColor = SKColor(red: 0.20, green: 0.50, blue: 0.85, alpha: 1.0)
        puddle.lineWidth = 1.5
        puddle.position = CGPoint(x: x, y: groundY + 1)

        // Shimmer ripple animation
        let ripple = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.5, duration: 0.8),
            SKAction.fadeAlpha(to: 0.75, duration: 0.8)
        ])
        puddle.run(SKAction.repeatForever(ripple))

        // Splash label
        let splash = SKLabelNode(text: "💧")
        splash.fontSize = 14
        splash.position = CGPoint(x: 0, y: 10)
        puddle.addChild(splash)

        // Contact sensor (no collision — dog walks through)
        let body = SKPhysicsBody(rectangleOf: CGSize(width: width, height: 12))
        body.isDynamic = false
        body.categoryBitMask    = PhysicsCategory.water
        body.collisionBitMask   = PhysicsCategory.none
        body.contactTestBitMask = PhysicsCategory.dog
        puddle.physicsBody = body
        addChild(puddle)
    }

    // MARK: - Finish Line

    private func setupFinishLine(at x: CGFloat) {
        // Checkered flag pattern
        let flagNode = buildCheckerFlag()
        flagNode.position = CGPoint(x: x, y: groundY + 120)
        addChild(flagNode)

        // Post
        let post = SKShapeNode(rectOf: CGSize(width: 8, height: 200), cornerRadius: 4)
        post.fillColor = .white
        post.strokeColor = SKColor(white: 0.7, alpha: 1)
        post.position = CGPoint(x: x, y: groundY + 100)
        addChild(post)

        // Banner
        let bannerBG = SKShapeNode(rectOf: CGSize(width: 120, height: 32), cornerRadius: 8)
        bannerBG.fillColor = SKColor(red: 0.20, green: 0.65, blue: 0.25, alpha: 1.0)
        bannerBG.strokeColor = .clear
        bannerBG.position = CGPoint(x: x, y: groundY + 218)
        addChild(bannerBG)

        let banner = SKLabelNode(text: "FINISH! 🏁")
        banner.fontSize = 18
        banner.fontName = UIFont.boldSystemFont(ofSize: 1).fontName
        banner.fontColor = .white
        banner.verticalAlignmentMode = .center
        banner.horizontalAlignmentMode = .center
        banner.position = CGPoint(x: x, y: groundY + 218)
        addChild(banner)

        // Physics trigger
        let trigger = SKNode()
        trigger.position = CGPoint(x: x, y: groundY + 100)
        let tBody = SKPhysicsBody(rectangleOf: CGSize(width: 30, height: 220))
        tBody.isDynamic = false
        tBody.affectedByGravity = false
        tBody.categoryBitMask    = PhysicsCategory.finishLine
        tBody.collisionBitMask   = PhysicsCategory.none
        tBody.contactTestBitMask = PhysicsCategory.dog
        trigger.physicsBody = tBody
        addChild(trigger)
    }

    private func buildCheckerFlag() -> SKNode {
        let flag = SKNode()
        let cols = 4, rows = 3
        let cellSize: CGFloat = 12
        for r in 0..<rows {
            for c in 0..<cols {
                let cell = SKShapeNode(rectOf: CGSize(width: cellSize, height: cellSize))
                cell.fillColor = (r + c) % 2 == 0 ? .black : .white
                cell.strokeColor = .clear
                cell.position = CGPoint(
                    x: CGFloat(c) * cellSize - CGFloat(cols) * cellSize / 2 + cellSize / 2,
                    y: CGFloat(r) * cellSize - CGFloat(rows) * cellSize / 2 + cellSize / 2
                )
                flag.addChild(cell)
            }
        }
        return flag
    }

    // MARK: - Dog

    private func setupDog() {
        dogNode = DogNode(breed: breed)
        dogNode.position = CGPoint(x: 60, y: groundY + 50)
        dogNode.onGotWet = { [weak self] in
            self?.gotWet = true
        }
        addChild(dogNode)
    }

    // MARK: - Camera

    private func setupCamera() {
        gameCamera = SKCameraNode()
        camera = gameCamera
        addChild(gameCamera)
        gameCamera.position = CGPoint(x: dogNode.position.x, y: 0)
    }

    // MARK: - HUD

    private func setupHUD() {
        // Bone counter
        updateBoneCounterHUD()

        // Hint
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
        bg.addChild(hint)
        gameCamera.addChild(bg)

        bg.run(SKAction.sequence([
            SKAction.wait(forDuration: 4.0),
            SKAction.fadeOut(withDuration: 1.0),
            SKAction.removeFromParent()
        ]))
    }

    private func updateBoneCounterHUD() {
        gameCamera.childNode(withName: "boneCounter")?.removeFromParent()

        let total = GameScene.totalCourseBonesCount
        var boneStr = ""
        for i in 0..<total {
            boneStr += i < bonesCollected ? "🟤" : "⬜"
        }

        let label = SKLabelNode(text: "🦴 \(bonesCollected)/\(total)  \(boneStr)")
        label.fontSize = 14
        label.fontName = UIFont.boldSystemFont(ofSize: 1).fontName
        label.fontColor = .white
        label.horizontalAlignmentMode = .right
        label.verticalAlignmentMode = .top
        label.name = "boneCounter"

        let bg = SKShapeNode(rectOf: CGSize(width: 180, height: 30), cornerRadius: 10)
        bg.fillColor = SKColor(white: 0, alpha: 0.40)
        bg.strokeColor = .clear
        bg.name = "boneCounter"
        bg.position = CGPoint(x: size.width / 2 - 20, y: size.height / 2 - 70)

        label.position = CGPoint(x: 80, y: 10)
        bg.addChild(label)
        gameCamera.addChild(bg)
    }

    // MARK: - Touch

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isCourseComplete, let touch = touches.first else { return }
        let loc = touch.location(in: self)
        let treat = TreatNode()
        treat.position = CGPoint(x: loc.x, y: groundY + 22)
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
        let dt = lastUpdateTime == 0 ? 0 : currentTime - lastUpdateTime
        lastUpdateTime = currentTime

        dogNode.updateMovement(deltaTime: dt)

        // Check bone collection
        for treat in treats where !treat.isCollected {
            let dist = hypot(treat.position.x - dogNode.position.x,
                             treat.position.y - dogNode.position.y)
            if dist < 48 {
                treat.collect()
                // Only count the pre-placed course bones (first 5)
                if treats.firstIndex(where: { $0 === treat }).map({ $0 < GameScene.totalCourseBonesCount }) == true {
                    bonesCollected += 1
                    updateBoneCounterHUD()
                    showCollectStar()
                }
                seekNearestTreat()
            }
        }

        // Smooth camera follow
        let targetX = dogNode.position.x
        let smoothX = gameCamera.position.x + (targetX - gameCamera.position.x) * 0.12
        gameCamera.position = CGPoint(x: smoothX, y: 0)
    }

    private func showCollectStar() {
        let star = SKLabelNode(text: "⭐")
        star.fontSize = 24
        star.position = CGPoint(x: dogNode.position.x, y: dogNode.position.y + 50)
        addChild(star)
        star.run(SKAction.sequence([
            SKAction.group([
                SKAction.moveBy(x: 0, y: 40, duration: 0.6),
                SKAction.fadeOut(withDuration: 0.6)
            ]),
            SKAction.removeFromParent()
        ]))
    }

    // MARK: - Physics Contact

    func didBegin(_ contact: SKPhysicsContact) {
        let a = contact.bodyA.categoryBitMask
        let b = contact.bodyB.categoryBitMask

        let isDogFinish = (a == PhysicsCategory.dog   && b == PhysicsCategory.finishLine) ||
                          (a == PhysicsCategory.finishLine && b == PhysicsCategory.dog)
        let isDogWater  = (a == PhysicsCategory.dog   && b == PhysicsCategory.water) ||
                          (a == PhysicsCategory.water  && b == PhysicsCategory.dog)
        let isDogRock   = (a == PhysicsCategory.dog   && b == PhysicsCategory.obstacle) ||
                          (a == PhysicsCategory.obstacle && b == PhysicsCategory.dog)

        if isDogFinish { handleCourseComplete() }
        if isDogWater  { handleWater() }
        if isDogRock   { handleRockHit() }
    }

    private func handleWater() {
        if breed == .lincoln { dogNode.getWet() }
        else {
            // Memphis deer-hops over puddles!
            dogNode.deerHop()
        }
    }

    private func handleRockHit() {
        hitObstacleCount += 1
        // Camera shake
        let shake = SKAction.sequence([
            SKAction.moveBy(x: -8, y: 0, duration: 0.05),
            SKAction.moveBy(x: 8, y: 0, duration: 0.05),
            SKAction.moveBy(x: -6, y: 0, duration: 0.05),
            SKAction.moveBy(x: 6, y: 0, duration: 0.05),
            SKAction.moveBy(x: 0, y: 0, duration: 0.0)
        ])
        gameCamera.run(shake)
    }

    // MARK: - Course Complete

    private func handleCourseComplete() {
        guard !isCourseComplete else { return }
        isCourseComplete = true
        dogNode.stopMoving()

        let result = GameResult(
            breed: breed,
            bonesCollected: bonesCollected,
            totalBones: GameScene.totalCourseBonesCount,
            gotWet: gotWet,
            hitObstacles: hitObstacleCount
        )

        // Show star rating overlay briefly
        showStarOverlay(stars: result.stars)

        // Fire callback after a short delay (let stars display)
        run(SKAction.sequence([
            SKAction.wait(forDuration: 2.5),
            SKAction.run { [weak self] in
                self?.onCourseComplete?(result)
            }
        ]))
    }

    private func showStarOverlay(stars: Int) {
        let bg = SKShapeNode(rectOf: CGSize(width: 300, height: 140), cornerRadius: 20)
        bg.fillColor = SKColor(white: 0, alpha: 0.75)
        bg.strokeColor = .clear
        bg.position = CGPoint(x: 0, y: 20)
        gameCamera.addChild(bg)

        let title = SKLabelNode(text: "Course Complete!")
        title.fontSize = 22
        title.fontName = UIFont.boldSystemFont(ofSize: 1).fontName
        title.fontColor = .white
        title.verticalAlignmentMode = .center
        title.horizontalAlignmentMode = .center
        title.position = CGPoint(x: 0, y: 40)
        bg.addChild(title)

        let starStr = String(repeating: "⭐", count: stars) + String(repeating: "☆", count: 3 - stars)
        let starLabel = SKLabelNode(text: starStr)
        starLabel.fontSize = 36
        starLabel.verticalAlignmentMode = .center
        starLabel.horizontalAlignmentMode = .center
        starLabel.position = CGPoint(x: 0, y: -10)
        bg.addChild(starLabel)

        let sub = SKLabelNode(text: "Grooming time! 🐕")
        sub.fontSize = 16
        sub.fontColor = SKColor(white: 0.85, alpha: 1)
        sub.fontName = UIFont.systemFont(ofSize: 1, weight: .medium).fontName
        sub.verticalAlignmentMode = .center
        sub.horizontalAlignmentMode = .center
        sub.position = CGPoint(x: 0, y: -52)
        bg.addChild(sub)

        bg.setScale(0.1)
        bg.run(SKAction.sequence([
            SKAction.scale(to: 1.0, duration: 0.3),
            SKAction.wait(forDuration: 1.8),
            SKAction.fadeOut(withDuration: 0.4)
        ]))
    }
}
