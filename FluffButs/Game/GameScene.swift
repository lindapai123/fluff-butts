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
    private var gameStarted = false
    private var hitObstacleCount = 0
    private var gotWet = false
    private var lastUpdateTime: TimeInterval = 0

    // MARK: Bones
    static let totalTrayBones = 5
    private var bonesCollected = 0

    // MARK: Drag state
    private var draggedBoneNode: SKShapeNode?    // the visual dragged from tray
    private var draggedSlotIndex: Int = -1
    private var traySlotUsed: [Bool] = Array(repeating: false, count: totalTrayBones)


    // MARK: Layout
    private let groundY: CGFloat = -180

    // MARK: Callback
    var onCourseComplete: ((GameResult) -> Void)?

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
        setupCourse()
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
        for cloudX in stride(from: 200, through: 1800, by: 340) {
            addCloud(at: CGPoint(x: CGFloat(cloudX), y: groundY + CGFloat.random(in: 200...360)))
        }
        let sky = SKShapeNode(rectOf: CGSize(width: 6000, height: 800))
        sky.fillColor = SKColor(red: 0.53, green: 0.81, blue: 0.92, alpha: 1.0)
        sky.strokeColor = .clear
        sky.position = CGPoint(x: 3000, y: groundY + 400)
        sky.zPosition = -3
        addChild(sky)

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
        for (bx, by, r): (CGFloat, CGFloat, CGFloat) in [(0,0,26),(-24,-8,20),(24,-8,20),(0,-14,22)] {
            let b = SKShapeNode(circleOfRadius: r)
            b.fillColor = .white; b.strokeColor = .clear; b.alpha = 0.9
            b.position = CGPoint(x: bx, y: by)
            cloud.addChild(b)
        }
        addChild(cloud)
        let drift = SKAction.moveBy(x: CGFloat.random(in: -30...30), y: 0, duration: 8)
        cloud.run(SKAction.repeatForever(SKAction.sequence([drift, drift.reversed()])))
    }

    // MARK: - Ground

    private func setupGround() {
        let w: CGFloat = 6000, h: CGFloat = 60
        let dirt = SKShapeNode(rectOf: CGSize(width: w, height: h))
        dirt.fillColor = SKColor(red: 0.58, green: 0.36, blue: 0.16, alpha: 1.0)
        dirt.strokeColor = .clear
        dirt.position = CGPoint(x: w/2 - 200, y: groundY - h/2 - 16)
        dirt.zPosition = -1
        let db = SKPhysicsBody(rectangleOf: CGSize(width: w, height: h))
        db.isDynamic = false
        db.categoryBitMask = PhysicsCategory.ground
        db.collisionBitMask = PhysicsCategory.dog
        db.contactTestBitMask = PhysicsCategory.dog
        dirt.physicsBody = db
        addChild(dirt)

        let gs = SKShapeNode(rectOf: CGSize(width: w, height: 16))
        gs.fillColor = SKColor(red: 0.28, green: 0.62, blue: 0.18, alpha: 1.0)
        gs.strokeColor = .clear
        gs.position = CGPoint(x: w/2 - 200, y: groundY - 8)
        gs.zPosition = -1
        addChild(gs)
    }

    // MARK: - Course

    private func setupCourse() {
        for (x,w,h): (CGFloat,CGFloat,CGFloat) in [(300,52,64),(720,66,88),(980,50,72),(1280,64,96)] {
            addRock(x: x, w: w, h: h)
        }
        for (x,w): (CGFloat,CGFloat) in [(580,100),(1130,80)] {
            addPuddle(x: x, width: w)
        }
        setupFinishLine(at: 1650)
    }

    private func addRock(x: CGFloat, w: CGFloat, h: CGFloat) {
        let rock = SKShapeNode(rectOf: CGSize(width: w, height: h), cornerRadius: 10)
        rock.fillColor = SKColor(red: 0.50, green: 0.32, blue: 0.13, alpha: 1.0)
        rock.strokeColor = SKColor(red: 0.35, green: 0.22, blue: 0.08, alpha: 1.0)
        rock.lineWidth = 2
        rock.position = CGPoint(x: x, y: groundY + h/2)
        let hi = SKShapeNode(rectOf: CGSize(width: w-12, height: 8), cornerRadius: 3)
        hi.fillColor = SKColor(white: 1, alpha: 0.18); hi.strokeColor = .clear
        hi.position = CGPoint(x: 0, y: h/2 - 8)
        rock.addChild(hi)
        let rb = SKPhysicsBody(rectangleOf: CGSize(width: w, height: h))
        rb.isDynamic = false
        rb.categoryBitMask = PhysicsCategory.obstacle
        rb.collisionBitMask = PhysicsCategory.dog
        rb.contactTestBitMask = PhysicsCategory.dog
        rock.physicsBody = rb
        addChild(rock)
    }

    private func addPuddle(x: CGFloat, width: CGFloat) {
        let puddle = SKShapeNode(rectOf: CGSize(width: width, height: 12), cornerRadius: 6)
        puddle.fillColor = SKColor(red: 0.30, green: 0.65, blue: 0.95, alpha: 0.75)
        puddle.strokeColor = SKColor(red: 0.20, green: 0.50, blue: 0.85, alpha: 1.0)
        puddle.lineWidth = 1.5
        puddle.position = CGPoint(x: x, y: groundY + 1)
        let ripple = SKAction.sequence([SKAction.fadeAlpha(to: 0.5, duration: 0.8),
                                        SKAction.fadeAlpha(to: 0.75, duration: 0.8)])
        puddle.run(SKAction.repeatForever(ripple))
        for wx in [-28, -8, 12, 32] as [Int] {
            let wave = SKShapeNode(); let p = CGMutablePath()
            p.move(to: CGPoint(x: -4, y: 0))
            p.addQuadCurve(to: CGPoint(x: 4, y: 0), control: CGPoint(x: 0, y: 4))
            wave.path = p; wave.strokeColor = SKColor(white: 1, alpha: 0.55)
            wave.lineWidth = 1.5; wave.lineCap = .round
            wave.position = CGPoint(x: CGFloat(wx), y: 3)
            puddle.addChild(wave)
        }
        let pb = SKPhysicsBody(rectangleOf: CGSize(width: width, height: 12))
        pb.isDynamic = false
        pb.categoryBitMask = PhysicsCategory.water
        pb.collisionBitMask = PhysicsCategory.none
        pb.contactTestBitMask = PhysicsCategory.dog
        puddle.physicsBody = pb
        addChild(puddle)
    }

    private func setupFinishLine(at x: CGFloat) {
        let flag = buildCheckerFlag()
        flag.position = CGPoint(x: x, y: groundY + 120)
        addChild(flag)

        let post = SKShapeNode(rectOf: CGSize(width: 8, height: 200), cornerRadius: 4)
        post.fillColor = .white; post.strokeColor = SKColor(white: 0.7, alpha: 1)
        post.position = CGPoint(x: x, y: groundY + 100)
        addChild(post)

        let bannerBG = SKShapeNode(rectOf: CGSize(width: 110, height: 32), cornerRadius: 8)
        bannerBG.fillColor = SKColor(red: 0.20, green: 0.65, blue: 0.25, alpha: 1.0)
        bannerBG.strokeColor = .clear
        bannerBG.position = CGPoint(x: x, y: groundY + 218)
        addChild(bannerBG)

        let banner = SKLabelNode(text: "FINISH!")
        banner.fontSize = 18; banner.fontName = UIFont.boldSystemFont(ofSize: 1).fontName
        banner.fontColor = .white
        banner.verticalAlignmentMode = .center; banner.horizontalAlignmentMode = .center
        banner.position = CGPoint(x: x, y: groundY + 218)
        addChild(banner)

        let trigger = SKNode()
        trigger.position = CGPoint(x: x, y: groundY + 100)
        let tb = SKPhysicsBody(rectangleOf: CGSize(width: 30, height: 220))
        tb.isDynamic = false; tb.affectedByGravity = false
        tb.categoryBitMask = PhysicsCategory.finishLine
        tb.collisionBitMask = PhysicsCategory.none
        tb.contactTestBitMask = PhysicsCategory.dog
        trigger.physicsBody = tb
        addChild(trigger)
    }

    private func buildCheckerFlag() -> SKNode {
        let flag = SKNode()
        let cols = 4, rows = 3, cell: CGFloat = 12
        for r in 0..<rows {
            for c in 0..<cols {
                let sq = SKShapeNode(rectOf: CGSize(width: cell, height: cell))
                sq.fillColor = (r + c) % 2 == 0 ? .black : .white; sq.strokeColor = .clear
                sq.position = CGPoint(x: CGFloat(c)*cell - CGFloat(cols)*cell/2 + cell/2,
                                      y: CGFloat(r)*cell - CGFloat(rows)*cell/2 + cell/2)
                flag.addChild(sq)
            }
        }
        return flag
    }

    // MARK: - Dog

    private func setupDog() {
        dogNode = DogNode(breed: breed)
        dogNode.position = CGPoint(x: 60, y: groundY + 50)
        dogNode.onGotWet = { [weak self] in self?.gotWet = true }
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
        setupBoneTray()
        setupSwipeHint()
        // DEBUG: pre-place a bone and auto-start
        let t = TreatNode(); t.position = CGPoint(x: 400, y: groundY + 22); addChild(t); treats.append(t)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in self?.startGame() }
    }

    // ── Bone tray at top ──────────────────────────────────────────────────────

    private func setupBoneTray() {
        let trayW: CGFloat = 280, trayH: CGFloat = 56
        let trayBG = SKShapeNode(rectOf: CGSize(width: trayW, height: trayH), cornerRadius: 16)
        trayBG.fillColor = SKColor(white: 0, alpha: 0.45)
        trayBG.strokeColor = SKColor(white: 1, alpha: 0.20)
        trayBG.lineWidth = 1.5
        trayBG.position = CGPoint(x: 0, y: size.height/2 - 90)
        trayBG.name = "trayBG"
        gameCamera.addChild(trayBG)

        let label = SKLabelNode(text: "Drag a bone to start!")
        label.fontSize = 11
        label.fontName = UIFont.systemFont(ofSize: 1, weight: .medium).fontName
        label.fontColor = SKColor(white: 0.85, alpha: 1)
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = CGPoint(x: 0, y: -trayH/2 + 10)
        label.name = "trayLabel"
        trayBG.addChild(label)

        for i in 0..<GameScene.totalTrayBones {
            let bone = makeTrayBone(slotIndex: i)
            bone.position = slotPosition(for: i, in: trayBG.frame)
            trayBG.addChild(bone)
        }
    }

    private func slotPosition(for i: Int, in frame: CGRect) -> CGPoint {
        let spacing: CGFloat = 48
        let totalW = CGFloat(GameScene.totalTrayBones - 1) * spacing
        return CGPoint(x: CGFloat(i) * spacing - totalW/2, y: 10)
    }

    private func makeTrayBone(slotIndex: Int) -> SKNode {
        let node = SKNode()
        node.name = "trayBone_\(slotIndex)"
        node.addChild(boneShape(scale: 0.7))
        return node
    }

    // ── Bone shape (reusable) ─────────────────────────────────────────────────

    private func boneShape(scale: CGFloat = 1.0) -> SKShapeNode {
        let path = CGMutablePath()
        let shaftW: CGFloat = 28 * scale, shaftH: CGFloat = 8 * scale
        let knobR: CGFloat  = 7 * scale
        // Shaft
        path.addRoundedRect(in: CGRect(x: -shaftW/2, y: -shaftH/2, width: shaftW, height: shaftH),
                            cornerWidth: 3*scale, cornerHeight: 3*scale)
        // Four knobs
        for (kx, ky): (CGFloat, CGFloat) in [(-shaftW/2, shaftH/2), (-shaftW/2, -shaftH/2),
                                              ( shaftW/2, shaftH/2), ( shaftW/2, -shaftH/2)] {
            path.addEllipse(in: CGRect(x: kx-knobR, y: ky-knobR, width: knobR*2, height: knobR*2))
        }
        let shape = SKShapeNode(path: path)
        shape.fillColor  = SKColor(white: 0.95, alpha: 1.0)
        shape.strokeColor = SKColor(white: 0.65, alpha: 1.0)
        shape.lineWidth   = 1.2 * scale
        return shape
    }

    private func swipeHintNode() -> SKNode {
        let bg = SKShapeNode(rectOf: CGSize(width: 260, height: 34), cornerRadius: 17)
        bg.fillColor = SKColor(white: 0, alpha: 0.40)
        bg.strokeColor = .clear
        let lbl = SKLabelNode(text: "Hit JUMP button to leap over rocks!")
        lbl.fontSize = 13
        lbl.fontName = UIFont.systemFont(ofSize: 1, weight: .medium).fontName
        lbl.fontColor = .white
        lbl.verticalAlignmentMode = .center
        lbl.horizontalAlignmentMode = .center
        bg.addChild(lbl)
        return bg
    }

    private func setupSwipeHint() {
        // Shown only after game starts
    }

    // ── Start button ──────────────────────────────────────────────────────────

    private func showJumpButton() {
        guard gameCamera.childNode(withName: "jumpBtn") == nil else { return }

        let size: CGFloat = 72
        let circle = SKShapeNode(circleOfRadius: size / 2)
        circle.fillColor   = SKColor(red: 0.20, green: 0.45, blue: 0.95, alpha: 0.90)
        circle.strokeColor = SKColor(white: 1.0, alpha: 0.35)
        circle.lineWidth   = 2.5
        circle.name        = "jumpBtn"
        // Bottom-right corner
        circle.position    = CGPoint(x: self.size.width / 2 - 60, y: -self.size.height / 2 + 80)
        circle.zPosition   = 20

        let arrow = SKShapeNode()
        let p = CGMutablePath()
        p.move(to:    CGPoint(x:  0, y:  18))
        p.addLine(to: CGPoint(x:  16, y: -10))
        p.addLine(to: CGPoint(x:  0, y:  -3))
        p.addLine(to: CGPoint(x: -16, y: -10))
        p.closeSubpath()
        arrow.path        = p
        arrow.fillColor   = .white
        arrow.strokeColor = .clear
        circle.addChild(arrow)

        let lbl = SKLabelNode(text: "JUMP")
        lbl.fontSize = 11
        lbl.fontName = UIFont.boldSystemFont(ofSize: 1).fontName
        lbl.fontColor = SKColor(white: 1, alpha: 0.85)
        lbl.verticalAlignmentMode   = .center
        lbl.horizontalAlignmentMode = .center
        lbl.position = CGPoint(x: 0, y: -28)
        circle.addChild(lbl)

        circle.alpha = 0
        gameCamera.addChild(circle)
        circle.run(SKAction.fadeIn(withDuration: 0.3))
    }

    private func showStartButton() {
        guard gameCamera.childNode(withName: "startBtn") == nil else { return }

        let bg = SKShapeNode(rectOf: CGSize(width: 140, height: 50), cornerRadius: 16)
        bg.fillColor = SKColor(red: 0.20, green: 0.72, blue: 0.28, alpha: 1.0)
        bg.strokeColor = SKColor(red: 0.12, green: 0.55, blue: 0.18, alpha: 1.0)
        bg.lineWidth = 2
        bg.name = "startBtn"
        bg.position = CGPoint(x: 0, y: -size.height/2 + 80)

        let label = SKLabelNode(text: "START!")
        label.fontSize = 22; label.fontName = UIFont.boldSystemFont(ofSize: 1).fontName
        label.fontColor = .white
        label.verticalAlignmentMode = .center; label.horizontalAlignmentMode = .center
        bg.addChild(label)
        gameCamera.addChild(bg)

        // Pulse animation
        bg.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.scale(to: 1.06, duration: 0.5),
            SKAction.scale(to: 1.0,  duration: 0.5)
        ])))
    }

    private func startGame() {
        guard !gameStarted else { return }
        gameStarted = true

        // Remove tray instruction label now that game is running
        gameCamera.childNode(withName: "trayBG")?.childNode(withName: "trayLabel")?.removeFromParent()
        showJumpButton()

        // Update tray label to show placed count
        updateBoneCounterHUD()

        // Show jump hint
        let hint = swipeHintNode()
        hint.name = "jumpHint"
        hint.position = CGPoint(x: 0, y: size.height/2 - 90)
        hint.alpha = 0
        gameCamera.addChild(hint)
        hint.run(SKAction.sequence([
            SKAction.fadeIn(withDuration: 0.4),
            SKAction.wait(forDuration: 3.0),
            SKAction.fadeOut(withDuration: 0.8),
            SKAction.removeFromParent()
        ]))

        seekNearestTreat()
    }

    // MARK: - Bone counter HUD (shown after game starts)

    private func updateBoneCounterHUD() {
        gameCamera.childNode(withName: "boneCounter")?.removeFromParent()
        guard gameStarted else { return }

        let total = GameScene.totalTrayBones
        let container = SKNode(); container.name = "boneCounter"

        let bg = SKShapeNode(rectOf: CGSize(width: 140, height: 30), cornerRadius: 10)
        bg.fillColor = SKColor(white: 0, alpha: 0.45); bg.strokeColor = .clear
        bg.position = CGPoint(x: size.width/2 - 90, y: size.height/2 - 70)
        container.addChild(bg)

        let label = SKLabelNode(text: "Bones: \(bonesCollected)/\(total)")
        label.fontSize = 14; label.fontName = UIFont.boldSystemFont(ofSize: 1).fontName
        label.fontColor = .white
        label.verticalAlignmentMode = .center; label.horizontalAlignmentMode = .center
        bg.addChild(label)

        // Pip row
        let pipC = SKNode()
        pipC.position = CGPoint(x: size.width/2 - 90, y: size.height/2 - 96)
        for i in 0..<total {
            let pip = SKShapeNode(circleOfRadius: 6)
            pip.fillColor = i < bonesCollected
                ? SKColor(red: 0.85, green: 0.60, blue: 0.15, alpha: 1.0)
                : SKColor(white: 1.0, alpha: 0.30)
            pip.strokeColor = SKColor(white: 1, alpha: 0.60); pip.lineWidth = 1.5
            pip.position = CGPoint(x: CGFloat(i-2)*18, y: 0)
            pipC.addChild(pip)
        }
        container.addChild(pipC)
        gameCamera.addChild(container)
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let camLoc   = touch.location(in: gameCamera)
        let worldLoc = touch.location(in: self)

        // Check JUMP button (only during active game)
        if gameStarted && !isCourseComplete,
           let jumpBtn = gameCamera.childNode(withName: "jumpBtn"),
           jumpBtn.contains(camLoc) {
            dogNode.jump()
            // Flash the button
            jumpBtn.run(SKAction.sequence([
                SKAction.scale(to: 0.88, duration: 0.06),
                SKAction.scale(to: 1.0,  duration: 0.10)
            ]))
            return
        }

        // Check tray bones (available throughout the game)
        if let trayBG = gameCamera.childNode(withName: "trayBG") {
            let trayLoc = touch.location(in: trayBG)
            for i in 0..<GameScene.totalTrayBones {
                guard !traySlotUsed[i] else { continue }
                if let slot = trayBG.childNode(withName: "trayBone_\(i)"),
                   slot.contains(trayLoc) {
                    // Pick up this bone
                    // picked up from tray
                    draggedSlotIndex = i
                    traySlotUsed[i] = true
                    slot.removeFromParent()  // remove from tray

                    // Create a draggable visual in scene space
                    let drag = boneShape(scale: 1.0)
                    drag.name = "dragBone"
                    drag.position = worldLoc
                    drag.zPosition = 10
                    addChild(drag)
                    draggedBoneNode = drag
                    return
                }
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let drag = draggedBoneNode else { return }
        drag.position = touch.location(in: self)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let camLoc   = touch.location(in: gameCamera)
        let worldLoc = touch.location(in: self)

        // Finish dragging a bone
        if let drag = draggedBoneNode {
            draggedBoneNode = nil
            drag.removeFromParent()

            // Place bone if dropped below the tray area (in the course)
            if worldLoc.y < groundY + 100 {
                let treat = TreatNode()
                treat.position = CGPoint(x: worldLoc.x, y: groundY + 22)
                addChild(treat)
                treats.append(treat)
                showPlacementMarker(at: treat.position)
                if gameStarted {
                    seekNearestTreat()  // redirect dog to new bone immediately
                } else {
                    startGame()         // first bone placed — go!
                }
            } else {
                // Dropped back in tray area — return slot
                traySlotUsed[draggedSlotIndex] = false
                if let trayBG = gameCamera.childNode(withName: "trayBG") {
                    let bone = makeTrayBone(slotIndex: draggedSlotIndex)
                    bone.position = slotPosition(for: draggedSlotIndex, in: trayBG.frame)
                    trayBG.addChild(bone)
                }
            }
            draggedSlotIndex = -1
            return
        }

        // During active game: tap the course area to instantly drop a bone
        if gameStarted && !isCourseComplete && draggedBoneNode == nil {
            // Only if touch is in the course area (below tray, not on jump button)
            let jumpBtnFrame = gameCamera.childNode(withName: "jumpBtn")?.frame ?? .zero
            let onJumpBtn = gameCamera.childNode(withName: "jumpBtn")?.contains(camLoc) ?? false
            let inTrayArea = camLoc.y > size.height / 2 - 130
            if !onJumpBtn && !inTrayArea {
                if let slotIdx = traySlotUsed.firstIndex(of: false) {
                    traySlotUsed[slotIdx] = true
                    removeTrayBoneVisual(slotIndex: slotIdx)
                    let treat = TreatNode()
                    treat.position = CGPoint(x: worldLoc.x, y: groundY + 22)
                    addChild(treat)
                    treats.append(treat)
                    showPlacementMarker(at: treat.position)
                    seekNearestTreat()
                }
            }
        }
    }

    // MARK: - Placement marker

    private func removeTrayBoneVisual(slotIndex: Int) {
        if let trayBG = gameCamera.childNode(withName: "trayBG") {
            trayBG.childNode(withName: "trayBone_\(slotIndex)")?.removeFromParent()
        }
    }

    private func refillTraySlot() {
        // Return the first used slot to the tray
        guard let slotIdx = traySlotUsed.firstIndex(of: true) else { return }
        traySlotUsed[slotIdx] = false
        if let trayBG = gameCamera.childNode(withName: "trayBG") {
            let bone = makeTrayBone(slotIndex: slotIdx)
            bone.position = slotPosition(for: slotIdx, in: trayBG.frame)
            bone.setScale(0.1)
            trayBG.addChild(bone)
            bone.run(SKAction.scale(to: 1.0, duration: 0.2))
        }
    }

    private func showPlacementMarker(at pos: CGPoint) {
        // Small glowing ring to show where the bone landed
        let ring = SKShapeNode(circleOfRadius: 18)
        ring.fillColor = .clear
        ring.strokeColor = SKColor(red: 0.98, green: 0.82, blue: 0.12, alpha: 0.8)
        ring.lineWidth = 2.5
        ring.position = pos
        addChild(ring)
        ring.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 1.8, duration: 0.4),
                SKAction.fadeOut(withDuration: 0.4)
            ]),
            SKAction.removeFromParent()
        ]))
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

        guard gameStarted else { return }
        dogNode.updateMovement(deltaTime: dt)

        for treat in treats where !treat.isCollected {
            let dist = hypot(treat.position.x - dogNode.position.x,
                             treat.position.y - dogNode.position.y)
            if dist < 48 {
                treat.collect()
                bonesCollected += 1
                updateBoneCounterHUD()
                showCollectStar()
                refillTraySlot()   // bone collected → slot returns to tray
                seekNearestTreat()
            }
        }

        let smoothX = gameCamera.position.x + (dogNode.position.x - gameCamera.position.x) * 0.12
        gameCamera.position = CGPoint(x: smoothX, y: 0)
    }

    private func showCollectStar() {
        let star = makeStarShape(filled: true, radius: 14)
        star.position = CGPoint(x: dogNode.position.x, y: dogNode.position.y + 50)
        addChild(star)
        star.run(SKAction.sequence([
            SKAction.group([SKAction.moveBy(x: 0, y: 40, duration: 0.6),
                            SKAction.fadeOut(withDuration: 0.6)]),
            SKAction.removeFromParent()
        ]))
    }

    private func makeStarShape(filled: Bool, radius: CGFloat) -> SKShapeNode {
        let path = CGMutablePath()
        let inner = radius * 0.42
        for i in 0..<10 {
            let a = CGFloat(i) * .pi / 5 - .pi / 2
            let r = i % 2 == 0 ? radius : inner
            let pt = CGPoint(x: cos(a)*r, y: sin(a)*r)
            if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
        }
        path.closeSubpath()
        let n = SKShapeNode(path: path)
        n.fillColor  = filled ? SKColor(red: 0.98, green: 0.82, blue: 0.12, alpha: 1) : SKColor(white: 0.5, alpha: 0.4)
        n.strokeColor = filled ? SKColor(red: 0.80, green: 0.60, blue: 0.05, alpha: 1) : SKColor(white: 0.8, alpha: 0.5)
        n.lineWidth = 1.5
        return n
    }

    // MARK: - Physics Contact

    func didBegin(_ contact: SKPhysicsContact) {
        let a = contact.bodyA.categoryBitMask, b = contact.bodyB.categoryBitMask
        let dogFinish = (a == PhysicsCategory.dog && b == PhysicsCategory.finishLine) ||
                        (b == PhysicsCategory.dog && a == PhysicsCategory.finishLine)
        let dogWater  = (a == PhysicsCategory.dog && b == PhysicsCategory.water) ||
                        (b == PhysicsCategory.dog && a == PhysicsCategory.water)
        let dogRock   = (a == PhysicsCategory.dog && b == PhysicsCategory.obstacle) ||
                        (b == PhysicsCategory.dog && a == PhysicsCategory.obstacle)
        let dogGround = (a == PhysicsCategory.dog && b == PhysicsCategory.ground) ||
                        (b == PhysicsCategory.dog && a == PhysicsCategory.ground)
        if dogFinish { handleCourseComplete() }
        if dogWater  { handleWater() }
        if dogRock   { handleRockHit() }
        if dogGround { dogNode.didLand() }
    }

    private func handleWater() {
        if breed == .lincoln { dogNode.getWet() } else { dogNode.deerHop() }
    }

    private func handleRockHit() {
        hitObstacleCount += 1
        let shake = SKAction.sequence([
            SKAction.moveBy(x: -8, y: 0, duration: 0.05), SKAction.moveBy(x: 8, y: 0, duration: 0.05),
            SKAction.moveBy(x: -6, y: 0, duration: 0.05), SKAction.moveBy(x: 6, y: 0, duration: 0.05)
        ])
        gameCamera.run(shake)
    }

    // MARK: - Course Complete

    private func handleCourseComplete() {
        guard !isCourseComplete else { return }
        isCourseComplete = true
        dogNode.stopMoving()

        let result = GameResult(breed: breed, bonesCollected: bonesCollected,
                                totalBones: treats.count, gotWet: gotWet,
                                hitObstacles: hitObstacleCount)
        showStarOverlay(stars: result.stars)

        run(SKAction.sequence([
            SKAction.wait(forDuration: 2.5),
            SKAction.run { [weak self] in
                DispatchQueue.main.async { self?.onCourseComplete?(result) }
            }
        ]))
    }

    private func showStarOverlay(stars: Int) {
        let bg = SKShapeNode(rectOf: CGSize(width: 300, height: 140), cornerRadius: 20)
        bg.fillColor = SKColor(white: 0, alpha: 0.75); bg.strokeColor = .clear
        bg.position = CGPoint(x: 0, y: 20)
        gameCamera.addChild(bg)

        let title = SKLabelNode(text: "Course Complete!")
        title.fontSize = 22; title.fontName = UIFont.boldSystemFont(ofSize: 1).fontName
        title.fontColor = .white; title.verticalAlignmentMode = .center
        title.horizontalAlignmentMode = .center; title.position = CGPoint(x: 0, y: 40)
        bg.addChild(title)

        let starRow = SKNode(); starRow.position = CGPoint(x: 0, y: -10)
        for i in 0..<3 {
            let s = makeStarShape(filled: i < stars, radius: 18)
            s.position = CGPoint(x: CGFloat(i-1)*44, y: 0)
            starRow.addChild(s)
        }
        bg.addChild(starRow)

        let sub = SKLabelNode(text: "Grooming time!")
        sub.fontSize = 16; sub.fontColor = SKColor(white: 0.85, alpha: 1)
        sub.fontName = UIFont.systemFont(ofSize: 1, weight: .medium).fontName
        sub.verticalAlignmentMode = .center; sub.horizontalAlignmentMode = .center
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
