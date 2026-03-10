import SpriteKit
import UIKit

// MARK: - TreatNode
// A bone treat dropped by the player. Drawn as a proper bone shape using SKShapeNode.
@MainActor
final class TreatNode: SKNode {

    // MARK: Public State
    private(set) var isCollected: Bool = false

    // MARK: - Init

    override init() {
        super.init()
        setupVisuals()
        setupPhysics()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Visuals

    private func setupVisuals() {
        // Shaft
        let shaft = SKShapeNode(rectOf: CGSize(width: 28, height: 10), cornerRadius: 4)
        shaft.fillColor = UIColor(white: 0.94, alpha: 1.0)
        shaft.strokeColor = UIColor(white: 0.75, alpha: 1.0)
        shaft.lineWidth = 1
        addChild(shaft)

        // Four knobs at ends (classic bone look)
        let knobPositions: [(CGFloat, CGFloat)] = [(-16, 6), (-16, -6), (16, 6), (16, -6)]
        for (kx, ky) in knobPositions {
            let knob = SKShapeNode(circleOfRadius: 7)
            knob.fillColor = UIColor(white: 0.96, alpha: 1.0)
            knob.strokeColor = UIColor(white: 0.75, alpha: 1.0)
            knob.lineWidth = 1
            knob.position = CGPoint(x: kx, y: ky)
            addChild(knob)
        }

        // Small drop shadow under bone
        let shadow = SKShapeNode(ellipseOf: CGSize(width: 38, height: 8))
        shadow.fillColor = UIColor(white: 0, alpha: 0.12)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 0, y: -12)
        shadow.zPosition = -1
        addChild(shadow)
    }

    // MARK: - Physics

    private func setupPhysics() {
        let body = SKPhysicsBody(circleOfRadius: 18)
        body.isDynamic = false
        body.affectedByGravity = false
        body.categoryBitMask = PhysicsCategory.treat
        body.contactTestBitMask = PhysicsCategory.none
        body.collisionBitMask = PhysicsCategory.none
        physicsBody = body
    }

    // MARK: - Collection

    func collect() {
        guard !isCollected else { return }
        isCollected = true
        let scaleDown = SKAction.scale(to: 0.1, duration: 0.25)
        let fadeOut   = SKAction.fadeAlpha(to: 0, duration: 0.25)
        let shrinkFade = SKAction.group([scaleDown, fadeOut])
        run(SKAction.sequence([shrinkFade, SKAction.removeFromParent()]))
    }
}
