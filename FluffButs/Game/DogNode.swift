import SpriteKit

// MARK: - DogNode
// The player's dog character. Uses physics velocity for movement so gravity
// and ground collision work correctly alongside the action system.
final class DogNode: SKNode {

    // MARK: Public State
    private(set) var isMoving: Bool = false
    var targetPosition: CGPoint?

    // MARK: Private
    private let label: SKLabelNode

    // MARK: - Init

    override init() {
        label = SKLabelNode(text: "🐕")
        label.fontSize = 50
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
        let body = SKPhysicsBody(circleOfRadius: 28)
        body.allowsRotation = false
        body.restitution = 0.0
        body.friction = 0.9
        body.linearDamping = 0.4
        body.mass = 1.0
        body.categoryBitMask = PhysicsCategory.dog
        body.contactTestBitMask = PhysicsCategory.finishLine
        body.collisionBitMask = PhysicsCategory.ground
        physicsBody = body
    }

    // MARK: - Movement

    /// Tell the dog to head toward a world-space position.
    /// Actual velocity is applied each frame via updateMovement().
    func moveTo(position: CGPoint) {
        targetPosition = position
        isMoving = true
        // Flip emoji to face the direction of travel
        label.xScale = position.x < self.position.x ? -1 : 1
    }

    /// Stop all movement immediately.
    func stopMoving() {
        targetPosition = nil
        isMoving = false
        physicsBody?.velocity.dx = 0
    }

    /// Called every frame from GameScene.update().
    /// Drives the dog toward targetPosition using physics velocity so that
    /// gravity and ground collision continue to work naturally.
    func updateMovement() {
        guard let target = targetPosition else {
            // No target — bleed off horizontal speed
            if let vx = physicsBody?.velocity.dx, abs(vx) > 1 {
                physicsBody?.velocity.dx = vx * 0.8
            }
            return
        }

        let dx = target.x - position.x
        if abs(dx) < 25 {
            stopMoving()
        } else {
            let speed: CGFloat = 190.0
            physicsBody?.velocity.dx = dx > 0 ? speed : -speed
        }
    }
}
