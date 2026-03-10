import SpriteKit

// MARK: - TreatNode
// A bone treat dropped by the player. Stays in place (isDynamic = false)
// and plays a collect animation when the dog reaches it.
@MainActor
final class TreatNode: SKNode {

    // MARK: Public State
    private(set) var isCollected: Bool = false

    // MARK: Private
    private let label: SKLabelNode

    // MARK: - Init

    override init() {
        label = SKLabelNode(text: "🦴")
        label.fontSize = 36
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        super.init()
        addChild(label)
        setupPhysics()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Physics Setup

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

    /// Plays a scale-down + fade-out animation then removes the node.
    func collect() {
        guard !isCollected else { return }
        isCollected = true

        let scaleDown = SKAction.scale(to: 0.1, duration: 0.25)
        let fadeOut   = SKAction.fadeAlpha(to: 0, duration: 0.25)
        let shrinkFade = SKAction.group([scaleDown, fadeOut])
        let remove     = SKAction.removeFromParent()
        run(SKAction.sequence([shrinkFade, remove]))
    }
}
