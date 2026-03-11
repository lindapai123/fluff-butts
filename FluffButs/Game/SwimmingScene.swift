import SpriteKit

// MARK: - SwimmingScene
final class SwimmingScene: SKScene, @preconcurrency SKPhysicsContactDelegate {

    // MARK: Nodes
    private var dogNode: DogNode!
    private var treats: [TreatNode] = []
    private var gameCamera: SKCameraNode!

    // MARK: State
    private let breed: DogBreed
    private var isCourseComplete = false
    private var gameStarted = false
    private var bonesCollected = 0
    private var seaweedHitCount = 0
    private var lastUpdateTime: TimeInterval = 0
    private var speechTimer: TimeInterval = 0
    private var stuckTimer: TimeInterval = 0
    private var lastDogX: CGFloat = 0

    // MARK: Layout
    private let seaFloorY: CGFloat = -200
    private let surfaceY:  CGFloat =  280

    // MARK: Tray
    private static let totalTrayBones = 5
    private var traySlotUsed: [Bool] = Array(repeating: false, count: totalTrayBones)
    private var draggedBoneNode: SKShapeNode?
    private var draggedSlotIndex: Int = -1

    // MARK: Callback
    var onCourseComplete: ((GameResult) -> Void)?

    // MARK: - Init
    init(size: CGSize, breed: DogBreed = .memphis) {
        self.breed = breed
        super.init(size: size)
    }
    required init?(coder: NSCoder) { self.breed = .memphis; super.init(coder: coder) }

    // MARK: - Lifecycle
    override func didMove(to view: SKView) {
        physicsWorld.gravity = CGVector(dx: 0, dy: -3.5)
        physicsWorld.contactDelegate = self
        setupBackground()
        setupSeaFloor()
        setupCourse()
        setupDog()
        setupCamera()
        setupBoneTray()
    }

    // MARK: - Background
    private func setupBackground() {
        // Ocean gradient layers
        let colors: [(SKColor, CGFloat)] = [
            (SKColor(red: 0.05, green: 0.10, blue: 0.35, alpha: 1), -400),
            (SKColor(red: 0.08, green: 0.25, blue: 0.55, alpha: 1),    0),
            (SKColor(red: 0.15, green: 0.45, blue: 0.70, alpha: 1),  280)
        ]
        for (i, (color, y)) in colors.enumerated() {
            let band = SKShapeNode(rectOf: CGSize(width: 6000, height: 340))
            band.fillColor = color; band.strokeColor = .clear
            band.position = CGPoint(x: 3000, y: y); band.zPosition = -5
            _ = i
            addChild(band)
        }
        // Light rays
        for rx in stride(from: 100, through: 1800, by: 280) {
            addLightRay(at: CGFloat(rx))
        }
        // Bubbles
        for _ in 0..<40 { addBubble() }
    }

    private func addLightRay(at x: CGFloat) {
        let ray = SKShapeNode()
        let p = CGMutablePath()
        p.move(to: CGPoint(x: -18, y: surfaceY))
        p.addLine(to: CGPoint(x: 18, y: surfaceY))
        p.addLine(to: CGPoint(x: 40, y: seaFloorY))
        p.addLine(to: CGPoint(x: -40, y: seaFloorY))
        p.closeSubpath()
        ray.path = p
        ray.fillColor = SKColor(white: 1.0, alpha: 0.04)
        ray.strokeColor = .clear
        ray.position = CGPoint(x: x, y: 0)
        ray.zPosition = -4
        addChild(ray)
        ray.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.08, duration: 2.0),
            SKAction.fadeAlpha(to: 0.02, duration: 2.0)
        ])))
    }

    private func addBubble() {
        let r = CGFloat.random(in: 3...8)
        let bubble = SKShapeNode(circleOfRadius: r)
        bubble.fillColor = SKColor(white: 1.0, alpha: 0.35)
        bubble.strokeColor = SKColor(white: 1.0, alpha: 0.55)
        bubble.lineWidth = 1
        let startX = CGFloat.random(in: 0...1800)
        let startY = seaFloorY + CGFloat.random(in: 0...80)
        bubble.position = CGPoint(x: startX, y: startY)
        bubble.zPosition = -2
        addChild(bubble)
        let rise = CGFloat.random(in: 300...520)
        let dur = TimeInterval.random(in: 3.5...7.0)
        bubble.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.group([
                SKAction.moveBy(x: CGFloat.random(in: -20...20), y: rise, duration: dur),
                SKAction.sequence([SKAction.fadeIn(withDuration: 0.3),
                                   SKAction.wait(forDuration: dur - 0.6),
                                   SKAction.fadeOut(withDuration: 0.3)])
            ]),
            SKAction.run { bubble.position = CGPoint(x: CGFloat.random(in: 0...1800), y: self.seaFloorY + CGFloat.random(in: 0...40)) }
        ])))
    }

    // MARK: - Sea Floor
    private func setupSeaFloor() {
        // Sand
        let sand = SKShapeNode(rectOf: CGSize(width: 6000, height: 60))
        sand.fillColor = SKColor(red: 0.76, green: 0.70, blue: 0.48, alpha: 1)
        sand.strokeColor = .clear
        sand.position = CGPoint(x: 3000, y: seaFloorY - 30)
        sand.zPosition = -1
        let sb = SKPhysicsBody(rectangleOf: CGSize(width: 6000, height: 60))
        sb.isDynamic = false
        sb.categoryBitMask    = PhysicsCategory.ground
        sb.collisionBitMask   = PhysicsCategory.dog
        sb.contactTestBitMask = PhysicsCategory.dog
        sand.physicsBody = sb
        addChild(sand)

        // Coral decorations
        let coralColors: [SKColor] = [
            SKColor(red: 0.95, green: 0.35, blue: 0.35, alpha: 1),
            SKColor(red: 0.98, green: 0.65, blue: 0.20, alpha: 1),
            SKColor(red: 0.85, green: 0.25, blue: 0.65, alpha: 1)
        ]
        for cx in stride(from: 80, through: 1700, by: 120) {
            let h = CGFloat.random(in: 18...38)
            let coral = SKShapeNode(rectOf: CGSize(width: 10, height: h), cornerRadius: 5)
            coral.fillColor = coralColors.randomElement()!
            coral.strokeColor = .clear
            coral.position = CGPoint(x: CGFloat(cx) + CGFloat.random(in: -30...30), y: seaFloorY + h/2)
            coral.zPosition = 0
            // Branch
            let branch = SKShapeNode(rectOf: CGSize(width: 8, height: h * 0.55), cornerRadius: 4)
            branch.fillColor = coral.fillColor
            branch.strokeColor = .clear
            branch.position = CGPoint(x: 7, y: h * 0.25)
            branch.zRotation = 0.5
            coral.addChild(branch)
            addChild(coral)
        }
    }

    // MARK: - Course
    private func setupCourse() {
        for (x, h): (CGFloat, CGFloat) in [(350, 180), (750, 160), (1150, 195)] {
            addSeaweed(x: x, height: h)
        }
        // Pre-place floating bones
        for (x, y): (CGFloat, CGFloat) in [(180,-80),(420,-20),(680,-100),(950,0),(1200,-60)] {
            addFloatingBone(at: CGPoint(x: x, y: y))
        }
        setupFinishLine(at: 1650)
        // Fish decorations
        for _ in 0..<6 { addFish() }
    }

    private func addSeaweed(x: CGFloat, height: CGFloat) {
        let weed = SKShapeNode(rectOf: CGSize(width: 28, height: height), cornerRadius: 8)
        weed.fillColor = SKColor(red: 0.15, green: 0.62, blue: 0.28, alpha: 1)
        weed.strokeColor = SKColor(red: 0.08, green: 0.45, blue: 0.18, alpha: 1)
        weed.lineWidth = 1.5
        weed.position = CGPoint(x: x, y: seaFloorY + height / 2)
        weed.zPosition = 1
        let sway = SKAction.sequence([
            SKAction.rotate(toAngle:  0.12, duration: 1.2),
            SKAction.rotate(toAngle: -0.12, duration: 1.2)
        ])
        weed.run(SKAction.repeatForever(sway))
        let wb = SKPhysicsBody(rectangleOf: CGSize(width: 28, height: height))
        wb.isDynamic = false; wb.friction = 0
        wb.categoryBitMask    = PhysicsCategory.obstacle
        wb.collisionBitMask   = PhysicsCategory.dog
        wb.contactTestBitMask = PhysicsCategory.dog
        weed.physicsBody = wb
        addChild(weed)
    }

    private func addFloatingBone(at pos: CGPoint) {
        let treat = TreatNode()
        treat.position = pos
        treat.physicsBody = nil          // float in place
        addChild(treat)
        treats.append(treat)
        // Gentle bob animation
        treat.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.moveBy(x: 0, y: 8, duration: 1.2),
            SKAction.moveBy(x: 0, y: -8, duration: 1.2)
        ])))
    }

    private func addFish() {
        let fish = SKNode()
        let body = SKShapeNode(ellipseOf: CGSize(width: 30, height: 14))
        body.fillColor = SKColor(red: 0.90, green: 0.55, blue: 0.15, alpha: 0.85)
        body.strokeColor = .clear
        fish.addChild(body)
        let tail = SKShapeNode()
        let tp = CGMutablePath()
        tp.move(to: CGPoint(x: -15, y: 0))
        tp.addLine(to: CGPoint(x: -26, y:  9))
        tp.addLine(to: CGPoint(x: -26, y: -9))
        tp.closeSubpath()
        let tailShape = SKShapeNode(path: tp)
        tailShape.fillColor = SKColor(red: 0.80, green: 0.40, blue: 0.10, alpha: 0.85)
        tailShape.strokeColor = .clear
        fish.addChild(tailShape)
        _ = tail
        let startX: CGFloat = CGFloat.random(in: -50 ... -10)
        let y = CGFloat.random(in: seaFloorY + 30 ... surfaceY - 30)
        fish.position = CGPoint(x: startX, y: y)
        fish.zPosition = -1
        addChild(fish)
        let dist = CGFloat.random(in: 1800...2400)
        let dur  = TimeInterval.random(in: 8...16)
        fish.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.moveBy(x: dist, y: CGFloat.random(in: -40...40), duration: dur),
            SKAction.run { fish.position = CGPoint(x: -60, y: CGFloat.random(in: self.seaFloorY+30...self.surfaceY-30)) }
        ])))
    }

    private func setupFinishLine(at x: CGFloat) {
        let pole = SKShapeNode(rectOf: CGSize(width: 8, height: surfaceY - seaFloorY), cornerRadius: 4)
        pole.fillColor = .white; pole.strokeColor = SKColor(white: 0.7, alpha: 1)
        pole.position = CGPoint(x: x, y: (surfaceY + seaFloorY) / 2)
        addChild(pole)

        let bg = SKShapeNode(rectOf: CGSize(width: 110, height: 32), cornerRadius: 8)
        bg.fillColor = SKColor(red: 0.15, green: 0.55, blue: 0.90, alpha: 1)
        bg.strokeColor = .clear
        bg.position = CGPoint(x: x, y: surfaceY - 30)
        addChild(bg)

        let lbl = SKLabelNode(text: "FINISH!")
        lbl.fontSize = 18; lbl.fontName = UIFont.boldSystemFont(ofSize: 1).fontName
        lbl.fontColor = .white
        lbl.verticalAlignmentMode = .center; lbl.horizontalAlignmentMode = .center
        lbl.position = CGPoint(x: x, y: surfaceY - 30)
        addChild(lbl)

        let trigger = SKNode()
        trigger.position = CGPoint(x: x, y: (surfaceY + seaFloorY) / 2)
        let tb = SKPhysicsBody(rectangleOf: CGSize(width: 24, height: surfaceY - seaFloorY))
        tb.isDynamic = false; tb.affectedByGravity = false
        tb.categoryBitMask    = PhysicsCategory.finishLine
        tb.collisionBitMask   = PhysicsCategory.none
        tb.contactTestBitMask = PhysicsCategory.dog
        trigger.physicsBody = tb
        addChild(trigger)
    }

    // MARK: - Dog
    private func setupDog() {
        dogNode = DogNode(breed: breed)
        dogNode.position = CGPoint(x: 60, y: seaFloorY + 80)
        dogNode.onGotWet = { }
        addChild(dogNode)
        // Water physics override
        dogNode.physicsBody?.linearDamping = 2.8
        dogNode.physicsBody?.density       = 0.6
        dogNode.physicsBody?.allowsRotation = false
    }

    // MARK: - Camera
    private func setupCamera() {
        gameCamera = SKCameraNode()
        camera = gameCamera
        addChild(gameCamera)
        gameCamera.position = CGPoint(x: dogNode.position.x, y: 0)
    }

    // MARK: - Bone Tray
    private func setupBoneTray() {
        let trayW: CGFloat = 240, trayH: CGFloat = 72
        let trayBG = SKShapeNode(rectOf: CGSize(width: trayW, height: trayH), cornerRadius: 16)
        trayBG.fillColor = SKColor(white: 0, alpha: 0.50)
        trayBG.strokeColor = SKColor(white: 1, alpha: 0.20)
        trayBG.lineWidth = 1.5
        trayBG.position = CGPoint(x: -(size.width / 2 - trayW / 2 - 16), y: -size.height / 2 + 80)
        trayBG.name = "trayBG"
        gameCamera.addChild(trayBG)

        let label = SKLabelNode(text: "Drag a bone to start!")
        label.fontSize = 11
        label.fontName = UIFont.systemFont(ofSize: 1, weight: .medium).fontName
        label.fontColor = SKColor(white: 0.9, alpha: 1)
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = CGPoint(x: 0, y: -trayH / 2 + 12)
        label.name = "trayLabel"
        trayBG.addChild(label)

        for i in 0..<SwimmingScene.totalTrayBones {
            let bone = makeTrayBone(slotIndex: i)
            bone.position = slotPosition(for: i)
            trayBG.addChild(bone)
        }
    }

    private func slotPosition(for i: Int) -> CGPoint {
        let spacing: CGFloat = 44
        let total = CGFloat(SwimmingScene.totalTrayBones - 1)
        return CGPoint(x: CGFloat(i) * spacing - total * spacing / 2, y: 10)
    }

    private func makeTrayBone(slotIndex: Int) -> SKNode {
        let node = SKNode(); node.name = "trayBone_\(slotIndex)"
        node.addChild(boneShape(scale: 0.7)); return node
    }

    private func boneShape(scale: CGFloat = 1.0) -> SKShapeNode {
        let path = CGMutablePath()
        let sw: CGFloat = 28*scale, sh: CGFloat = 8*scale, kr: CGFloat = 7*scale
        path.addRoundedRect(in: CGRect(x: -sw/2, y: -sh/2, width: sw, height: sh),
                            cornerWidth: 3*scale, cornerHeight: 3*scale)
        for (kx,ky): (CGFloat,CGFloat) in [(-sw/2,sh/2),(-sw/2,-sh/2),(sw/2,sh/2),(sw/2,-sh/2)] {
            path.addEllipse(in: CGRect(x: kx-kr, y: ky-kr, width: kr*2, height: kr*2))
        }
        let s = SKShapeNode(path: path)
        s.fillColor = SKColor(white: 0.95, alpha: 1); s.strokeColor = SKColor(white: 0.65, alpha: 1)
        s.lineWidth = 1.2*scale; return s
    }

    private func removeTrayBoneVisual(slotIndex: Int) {
        gameCamera.childNode(withName: "trayBG")?.childNode(withName: "trayBone_\(slotIndex)")?.removeFromParent()
    }

    private func refillTraySlot() {
        guard let idx = traySlotUsed.firstIndex(of: true) else { return }
        traySlotUsed[idx] = false
        if let trayBG = gameCamera.childNode(withName: "trayBG") {
            let bone = makeTrayBone(slotIndex: idx)
            bone.position = slotPosition(for: idx)
            bone.setScale(0.1); trayBG.addChild(bone)
            bone.run(SKAction.scale(to: 1.0, duration: 0.2))
        }
    }

    // MARK: - Start / Paddle Button
    private func startGame() {
        guard !gameStarted else { return }
        gameStarted = true
        gameCamera.childNode(withName: "trayBG")?.childNode(withName: "trayLabel")?.removeFromParent()
        showPaddleButton()
        updateBoneCounterHUD()
        seekNearestTreat()
    }

    private func showPaddleButton() {
        guard gameCamera.childNode(withName: "paddleBtn") == nil else { return }
        let circle = SKShapeNode(circleOfRadius: 36)
        circle.fillColor   = SKColor(red: 0.10, green: 0.45, blue: 0.85, alpha: 0.92)
        circle.strokeColor = SKColor(white: 1, alpha: 0.35)
        circle.lineWidth = 2.5; circle.name = "paddleBtn"
        circle.position = CGPoint(x: size.width/2 - 60, y: -size.height/2 + 80)
        circle.zPosition = 20
        let arrow = SKShapeNode()
        let p = CGMutablePath()
        p.move(to: CGPoint(x: 0, y: 18)); p.addLine(to: CGPoint(x: 16, y: -10))
        p.addLine(to: CGPoint(x: 0, y: -3)); p.addLine(to: CGPoint(x: -16, y: -10))
        p.closeSubpath()
        let arrowShape = SKShapeNode(path: p)
        arrowShape.fillColor = .white; arrowShape.strokeColor = .clear
        circle.addChild(arrowShape)
        let lbl = SKLabelNode(text: "PADDLE")
        lbl.fontSize = 10; lbl.fontName = UIFont.boldSystemFont(ofSize: 1).fontName
        lbl.fontColor = SKColor(white: 1, alpha: 0.85)
        lbl.verticalAlignmentMode = .center; lbl.horizontalAlignmentMode = .center
        lbl.position = CGPoint(x: 0, y: -28)
        circle.addChild(lbl)
        circle.alpha = 0; gameCamera.addChild(circle)
        circle.run(SKAction.fadeIn(withDuration: 0.3))
    }

    // MARK: - Bone Counter HUD
    private func updateBoneCounterHUD() {
        gameCamera.childNode(withName: "boneCounter")?.removeFromParent()
        guard gameStarted else { return }
        let total = SwimmingScene.totalTrayBones
        let bg = SKShapeNode(rectOf: CGSize(width: 140, height: 30), cornerRadius: 10)
        bg.fillColor = SKColor(white: 0, alpha: 0.45); bg.strokeColor = .clear
        bg.name = "boneCounter"
        bg.position = CGPoint(x: size.width/2 - 90, y: size.height/2 - 70)
        let lbl = SKLabelNode(text: "Bones: \(bonesCollected)/\(total)")
        lbl.fontSize = 14; lbl.fontName = UIFont.boldSystemFont(ofSize: 1).fontName
        lbl.fontColor = .white; lbl.verticalAlignmentMode = .center; lbl.horizontalAlignmentMode = .center
        bg.addChild(lbl); gameCamera.addChild(bg)
    }

    // MARK: - Touch
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let camLoc   = touch.location(in: gameCamera)
        let worldLoc = touch.location(in: self)

        // Paddle button
        if gameStarted, !isCourseComplete,
           let btn = gameCamera.childNode(withName: "paddleBtn"), btn.contains(camLoc) {
            dogNode.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 420))
            btn.run(SKAction.sequence([SKAction.scale(to: 0.88, duration: 0.06),
                                       SKAction.scale(to: 1.0, duration: 0.10)]))
            return
        }

        // Tray bone drag
        if let trayBG = gameCamera.childNode(withName: "trayBG") {
            let trayLoc = touch.location(in: trayBG)
            for i in 0..<SwimmingScene.totalTrayBones {
                guard !traySlotUsed[i] else { continue }
                if let slot = trayBG.childNode(withName: "trayBone_\(i)"), slot.contains(trayLoc) {
                    traySlotUsed[i] = true; slot.removeFromParent()
                    draggedSlotIndex = i
                    let drag = boneShape(scale: 1.0); drag.name = "dragBone"
                    drag.position = worldLoc; drag.zPosition = 10
                    addChild(drag); draggedBoneNode = drag; return
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

        if let drag = draggedBoneNode {
            draggedBoneNode = nil; drag.removeFromParent()
            let inTray = gameCamera.childNode(withName: "trayBG")?.contains(camLoc) ?? false
            if !inTray {
                placeBone(at: worldLoc)
            } else {
                traySlotUsed[draggedSlotIndex] = false
                if let trayBG = gameCamera.childNode(withName: "trayBG") {
                    let bone = makeTrayBone(slotIndex: draggedSlotIndex)
                    bone.position = slotPosition(for: draggedSlotIndex)
                    trayBG.addChild(bone)
                }
            }
            draggedSlotIndex = -1; return
        }

        // Tap course to place bone mid-game
        if gameStarted && !isCourseComplete {
            let inTray    = gameCamera.childNode(withName: "trayBG")?.contains(camLoc)   ?? false
            let onPaddle  = gameCamera.childNode(withName: "paddleBtn")?.contains(camLoc) ?? false
            if !inTray && !onPaddle {
                if let idx = traySlotUsed.firstIndex(of: false) {
                    traySlotUsed[idx] = true
                    removeTrayBoneVisual(slotIndex: idx)
                    placeBone(at: worldLoc)
                }
            }
        }
    }

    private func placeBone(at worldLoc: CGPoint) {
        let clampedY = min(max(worldLoc.y, seaFloorY + 20), surfaceY - 20)
        let treat = TreatNode()
        treat.position = CGPoint(x: worldLoc.x, y: clampedY)
        treat.physicsBody = nil
        addChild(treat)
        treats.append(treat)
        showPlacementMarker(at: treat.position)
        if gameStarted { seekNearestTreat() } else { startGame() }
    }

    private func showPlacementMarker(at pos: CGPoint) {
        let ring = SKShapeNode(circleOfRadius: 18)
        ring.fillColor = .clear
        ring.strokeColor = SKColor(red: 0.98, green: 0.82, blue: 0.12, alpha: 0.8)
        ring.lineWidth = 2.5; ring.position = pos; addChild(ring)
        ring.run(SKAction.sequence([
            SKAction.group([SKAction.scale(to: 1.8, duration: 0.4),
                            SKAction.fadeOut(withDuration: 0.4)]),
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
        if let t = nearest { dogNode.moveTo(position: t.position) }
    }

    // MARK: - Update
    override func update(_ currentTime: TimeInterval) {
        let dt = lastUpdateTime == 0 ? 0 : currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        guard gameStarted else { return }

        dogNode.updateMovement(deltaTime: dt)

        // Clamp to water column
        if let body = dogNode.physicsBody {
            if dogNode.position.y > surfaceY - 20 && body.velocity.dy > 0 {
                body.velocity = CGVector(dx: body.velocity.dx, dy: 0)
            }
        }

        // Bone collection
        for treat in treats where !treat.isCollected {
            let dist = hypot(treat.position.x - dogNode.position.x,
                             treat.position.y - dogNode.position.y)
            if dist < 60 {
                treat.collect()
                bonesCollected += 1
                updateBoneCounterHUD()
                showCollectStar()
                refillTraySlot()
                seekNearestTreat()
            }
        }

        // Anti-stuck
        let movedX = abs(dogNode.position.x - lastDogX)
        if movedX < 2 && !treats.filter({ !$0.isCollected }).isEmpty {
            stuckTimer += dt
            if stuckTimer > 0.5 { dogNode.physicsBody?.applyImpulse(CGVector(dx: 200, dy: 80)); stuckTimer = 0 }
        } else { stuckTimer = 0 }
        lastDogX = dogNode.position.x

        // Breed speech
        speechTimer += dt
        let speechInterval: TimeInterval = breed == .memphis ? 5.0 : 4.0
        if speechTimer > speechInterval {
            speechTimer = 0
            if breed == .lincoln { dogNode.showWaterSpeech() } else { dogNode.showSwimSpeech() }
        }

        // Camera follow
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
        n.lineWidth = 1.5; return n
    }

    // MARK: - Physics Contact
    func didBegin(_ contact: SKPhysicsContact) {
        let a = contact.bodyA.categoryBitMask, b = contact.bodyB.categoryBitMask
        let dogFinish = (a == PhysicsCategory.dog && b == PhysicsCategory.finishLine) ||
                        (b == PhysicsCategory.dog && a == PhysicsCategory.finishLine)
        let dogRock   = (a == PhysicsCategory.dog && b == PhysicsCategory.obstacle) ||
                        (b == PhysicsCategory.dog && a == PhysicsCategory.obstacle)
        let dogGround = (a == PhysicsCategory.dog && b == PhysicsCategory.ground) ||
                        (b == PhysicsCategory.dog && a == PhysicsCategory.ground)
        if dogFinish { handleCourseComplete() }
        if dogRock   { handleSeaweedHit() }
        if dogGround { dogNode.didLand() }
    }

    private func handleSeaweedHit() {
        seaweedHitCount += 1
        let currentTarget = dogNode.targetPosition
        dogNode.bounceBack(resumeTarget: currentTarget)
        let shake = SKAction.sequence([
            SKAction.moveBy(x: -6, y: 0, duration: 0.05), SKAction.moveBy(x: 6, y: 0, duration: 0.05),
            SKAction.moveBy(x: -4, y: 0, duration: 0.05), SKAction.moveBy(x: 4, y: 0, duration: 0.05)
        ])
        gameCamera.run(shake)
        run(SKAction.sequence([SKAction.wait(forDuration: 1.7),
                               SKAction.run { [weak self] in self?.seekNearestTreat() }]))
    }

    // MARK: - Course Complete
    private func handleCourseComplete() {
        guard !isCourseComplete else { return }
        isCourseComplete = true
        dogNode.stopMoving()
        // Always gotWet = true in swimming course
        let result = GameResult(breed: breed, bonesCollected: bonesCollected,
                                totalBones: treats.count, gotWet: true,
                                hitObstacles: seaweedHitCount)
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
        bg.position = CGPoint(x: 0, y: 20); gameCamera.addChild(bg)
        let title = SKLabelNode(text: "Course Complete!")
        title.fontSize = 22; title.fontName = UIFont.boldSystemFont(ofSize: 1).fontName
        title.fontColor = .white; title.verticalAlignmentMode = .center
        title.horizontalAlignmentMode = .center; title.position = CGPoint(x: 0, y: 40)
        bg.addChild(title)
        let starRow = SKNode(); starRow.position = CGPoint(x: 0, y: -10)
        for i in 0..<3 {
            let s = makeStarShape(filled: i < stars, radius: 18)
            s.position = CGPoint(x: CGFloat(i-1)*44, y: 0); starRow.addChild(s)
        }
        bg.addChild(starRow)
        let sub = SKLabelNode(text: "Bath time!")
        sub.fontSize = 16; sub.fontColor = SKColor(white: 0.85, alpha: 1)
        sub.fontName = UIFont.systemFont(ofSize: 1, weight: .medium).fontName
        sub.verticalAlignmentMode = .center; sub.horizontalAlignmentMode = .center
        sub.position = CGPoint(x: 0, y: -52); bg.addChild(sub)
        bg.setScale(0.1)
        bg.run(SKAction.sequence([SKAction.scale(to: 1.0, duration: 0.3),
                                   SKAction.wait(forDuration: 1.8),
                                   SKAction.fadeOut(withDuration: 0.4)]))
    }
}
