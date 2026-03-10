import SpriteKit
import UIKit

// MARK: - DogNode
// Drawn entirely with SKShapeNode so it renders on every device & simulator.
// Supports multiple breeds via DogBreed, with breed-specific special moves.
@MainActor
final class DogNode: SKNode {

    // MARK: Public State
    private(set) var isMoving: Bool = false
    private(set) var isStubborn: Bool = false
    private(set) var isWet: Bool = false
    private(set) var isInAir: Bool = false
    var targetPosition: CGPoint?
    let breed: DogBreed

    // MARK: Private
    private let bodyNode: SKNode   // container — flip xScale to change direction
    private var specialMoveTimer: TimeInterval = 0
    private var specialMoveInterval: TimeInterval

    // Callbacks
    var onGotWet: (() -> Void)?

    // MARK: - Init

    init(breed: DogBreed = .memphis) {
        self.breed = breed
        bodyNode = SKNode()
        // Memphis hops every 3-4s; Lincoln stops every 4-6s
        specialMoveInterval = breed == .memphis
            ? TimeInterval.random(in: 2.5...4.0)
            : TimeInterval.random(in: 3.5...6.0)
        super.init()
        addChild(bodyNode)
        drawDog()
        setupPhysics()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Drawing

    private func drawDog() {
        let bodyColor   = breed.bodyColor
        let strokeColor = breed.strokeColor
        let earColor    = breed.earColor
        let snoutColor  = breed.snoutColor
        let noseColor   = UIColor(red: 0.10, green: 0.06, blue: 0.02, alpha: 1.0)

        // Shadow under body
        let shadow = SKShapeNode(ellipseOf: CGSize(width: 48, height: 10))
        shadow.fillColor = UIColor(white: 0, alpha: 0.18)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 0, y: -20)
        bodyNode.addChild(shadow)

        // Body
        let body = SKShapeNode(ellipseOf: CGSize(width: 52, height: 36))
        body.fillColor = bodyColor
        body.strokeColor = strokeColor
        body.lineWidth = 2
        bodyNode.addChild(body)

        // Head
        let head = SKShapeNode(circleOfRadius: 18)
        head.fillColor = bodyColor
        head.strokeColor = strokeColor
        head.lineWidth = 2
        head.position = CGPoint(x: 28, y: 10)
        bodyNode.addChild(head)

        // Snout
        let snout = SKShapeNode(ellipseOf: CGSize(width: 16, height: 10))
        snout.fillColor = snoutColor
        snout.strokeColor = strokeColor
        snout.lineWidth = 1.5
        snout.position = CGPoint(x: 40, y: 6)
        bodyNode.addChild(snout)

        // Nose
        let nose = SKShapeNode(ellipseOf: CGSize(width: 7, height: 5))
        nose.fillColor = noseColor
        nose.strokeColor = .clear
        nose.position = CGPoint(x: 48, y: 8)
        bodyNode.addChild(nose)

        // Floppy ear
        let earPath = CGMutablePath()
        earPath.addEllipse(in: CGRect(x: -6, y: -14, width: 12, height: 20))
        let ear = SKShapeNode(path: earPath)
        ear.fillColor = earColor
        ear.strokeColor = strokeColor
        ear.lineWidth = 1.5
        ear.position = CGPoint(x: 22, y: 22)
        ear.zRotation = 0.3
        bodyNode.addChild(ear)

        // Tail
        let tailPath = CGMutablePath()
        tailPath.move(to: CGPoint(x: -26, y: 4))
        tailPath.addQuadCurve(to: CGPoint(x: -38, y: 22),
                              control: CGPoint(x: -40, y: 4))
        let tail = SKShapeNode(path: tailPath)
        tail.fillColor = .clear
        tail.strokeColor = bodyColor
        tail.lineWidth = 6
        tail.lineCap = .round
        bodyNode.addChild(tail)

        // Legs (4)
        for (lx, ly): (CGFloat, CGFloat) in [(-14, -18), (-4, -18), (10, -18), (20, -18)] {
            let leg = SKShapeNode(rectOf: CGSize(width: 8, height: 18), cornerRadius: 3)
            leg.fillColor = bodyColor
            leg.strokeColor = strokeColor
            leg.lineWidth = 1.5
            leg.position = CGPoint(x: lx, y: ly)
            bodyNode.addChild(leg)
        }

        // Eye
        let eye = SKShapeNode(circleOfRadius: 3.5)
        eye.fillColor = noseColor
        eye.strokeColor = .clear
        eye.position = CGPoint(x: 36, y: 15)
        bodyNode.addChild(eye)

        // Eye shine
        let shine = SKShapeNode(circleOfRadius: 1.2)
        shine.fillColor = .white
        shine.strokeColor = .clear
        shine.position = CGPoint(x: 37.5, y: 16.5)
        bodyNode.addChild(shine)

        // Idle bounce animation
        let up   = SKAction.moveBy(x: 0, y: 3, duration: 0.5)
        let down = SKAction.moveBy(x: 0, y: -3, duration: 0.5)
        bodyNode.run(SKAction.repeatForever(SKAction.sequence([up, down])))
    }

    // MARK: - Physics

    private func setupPhysics() {
        let body = SKPhysicsBody(circleOfRadius: 26)
        body.allowsRotation = false
        body.restitution = 0.0
        body.friction = 0.9
        body.linearDamping = 0.4
        body.mass = 1.0
        body.categoryBitMask    = PhysicsCategory.dog
        body.contactTestBitMask = PhysicsCategory.finishLine | PhysicsCategory.water | PhysicsCategory.ground
        body.collisionBitMask   = PhysicsCategory.ground | PhysicsCategory.obstacle
        physicsBody = body
    }

    /// Called by GameScene when the dog lands on the ground (resets jump state).
    func didLand() {
        isInAir = false
    }

    // MARK: - Direction

    func faceDirection(goingRight: Bool) {
        bodyNode.xScale = goingRight ? 1 : -1
    }

    // MARK: - Movement (physics-driven, for GameScene)

    func moveTo(position: CGPoint) {
        guard !isStubborn else { return }
        targetPosition = position
        isMoving = true
        faceDirection(goingRight: position.x >= self.position.x)
    }

    func stopMoving() {
        targetPosition = nil
        isMoving = false
        physicsBody?.velocity.dx = 0
    }

    func updateMovement(deltaTime: TimeInterval) {
        guard !isStubborn else { return }

        if let target = targetPosition {
            let dx = target.x - position.x
            if abs(dx) < 25 {
                stopMoving()
            } else {
                let speed: CGFloat = isWet ? 110 : 190
                physicsBody?.velocity.dx = dx > 0 ? speed : -speed
            }
        } else {
            if let vx = physicsBody?.velocity.dx, abs(vx) > 1 {
                physicsBody?.velocity.dx = vx * 0.8
            }
        }

        // Trigger breed special moves while moving
        if isMoving && targetPosition != nil {
            specialMoveTimer += deltaTime
            if specialMoveTimer >= specialMoveInterval {
                specialMoveTimer = 0
                specialMoveInterval = breed == .memphis
                    ? TimeInterval.random(in: 2.5...4.0)
                    : TimeInterval.random(in: 3.5...6.0)
                triggerSpecialMove()
            }
        }
    }

    // MARK: - Special Moves

    private func triggerSpecialMove() {
        switch breed {
        case .memphis: deerHop()
        case .lincoln: goStubborn()
        }
    }

    /// Player-triggered jump (swipe up). Works for both breeds.
    func jump() {
        guard !isInAir, let body = physicsBody else { return }
        isInAir = true
        body.velocity.dy = 500
        // Ears-back jump animation
        let squeeze = SKAction.sequence([
            SKAction.scaleY(to: 0.85, duration: 0.06),
            SKAction.scaleY(to: 1.15, duration: 0.10),
            SKAction.scaleY(to: 1.0, duration: 0.12)
        ])
        bodyNode.run(squeeze)
        showSpeechBubble(breed == .memphis ? "Woof!" : "Hmph!")
    }

    /// Memphis: leap upward with a happy bounce
    func deerHop() {
        guard let body = physicsBody else { return }
        body.velocity.dy = 420  // big upward kick
        // Wag tail during hop
        let wag = SKAction.sequence([
            SKAction.rotate(byAngle: 0.4, duration: 0.1),
            SKAction.rotate(byAngle: -0.4, duration: 0.1)
        ])
        bodyNode.run(SKAction.repeat(wag, count: 4))
        showSpeechBubble("Wheee!")
    }

    /// Lincoln: plant his feet and refuse to move for a moment
    func goStubborn() {
        guard !isStubborn else { return }
        isStubborn = true
        stopMoving()
        showSpeechBubble("Nope.")
        // Resume after 2-3 seconds
        let wait = TimeInterval.random(in: 2.0...3.5)
        run(SKAction.sequence([
            SKAction.wait(forDuration: wait),
            SKAction.run { [weak self] in
                self?.isStubborn = false
                // Resume toward old target
                if let t = self?.targetPosition {
                    self?.moveTo(position: t)
                }
            }
        ]))
    }

    /// Called when Lincoln hits a water puddle
    func getWet() {
        guard !isWet else { return }
        isWet = true
        onGotWet?()
        showSpeechBubble("Nooooo!!")
        // Shake the dog
        let shake = SKAction.sequence([
            SKAction.moveBy(x: -6, y: 0, duration: 0.05),
            SKAction.moveBy(x: 6, y: 0, duration: 0.05)
        ])
        run(SKAction.repeat(shake, count: 6))
        // Show water droplets
        for i in 0..<5 {
            let drop = SKShapeNode(circleOfRadius: 4)
            drop.fillColor = SKColor(red: 0.30, green: 0.65, blue: 0.95, alpha: 0.85)
            drop.strokeColor = .clear
            let angle = CGFloat(i) / 5.0 * .pi * 2
            drop.position = CGPoint(x: cos(angle) * 20, y: sin(angle) * 20 + 10)
            addChild(drop)
            drop.run(SKAction.sequence([
                SKAction.group([
                    SKAction.moveBy(x: cos(angle) * 30, y: sin(angle) * 30, duration: 0.6),
                    SKAction.fadeOut(withDuration: 0.6)
                ]),
                SKAction.removeFromParent()
            ]))
        }
    }

    // MARK: - Speech Bubble

    private func showSpeechBubble(_ text: String) {
        // Remove existing bubble
        childNode(withName: "speechBubble")?.removeFromParent()

        let label = SKLabelNode(text: text)
        label.fontSize = 14
        label.fontColor = SKColor(red: 0.25, green: 0.12, blue: 0.02, alpha: 1.0)
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center

        let bubble = SKShapeNode(rectOf: CGSize(width: label.frame.width + 20, height: 28), cornerRadius: 10)
        bubble.fillColor = .white
        bubble.strokeColor = SKColor(white: 0.8, alpha: 1)
        bubble.lineWidth = 1.5
        bubble.position = CGPoint(x: 10, y: 52)
        bubble.name = "speechBubble"
        bubble.addChild(label)
        addChild(bubble)

        bubble.run(SKAction.sequence([
            SKAction.wait(forDuration: 1.8),
            SKAction.fadeOut(withDuration: 0.4),
            SKAction.removeFromParent()
        ]))
    }
}
