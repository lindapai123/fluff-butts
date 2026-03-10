import SpriteKit
import UIKit

// MARK: - DogNode
// Drawn entirely with SKShapeNode so it renders on every device & simulator.
@MainActor
final class DogNode: SKNode {

    // MARK: Public State
    private(set) var isMoving: Bool = false
    var targetPosition: CGPoint?

    // MARK: Private
    private let bodyNode: SKNode   // container so we can flip xScale

    // MARK: - Init

    override init() {
        bodyNode = SKNode()
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
        let bodyColor   = UIColor(red: 0.82, green: 0.60, blue: 0.22, alpha: 1.0)  // golden
        let strokeColor = UIColor(red: 0.58, green: 0.38, blue: 0.08, alpha: 1.0)
        let noseColor   = UIColor(red: 0.20, green: 0.12, blue: 0.05, alpha: 1.0)

        // Body (large ellipse)
        let body = SKShapeNode(ellipseOf: CGSize(width: 52, height: 36))
        body.fillColor = bodyColor
        body.strokeColor = strokeColor
        body.lineWidth = 2
        body.position = CGPoint(x: 0, y: 0)
        bodyNode.addChild(body)

        // Head (circle)
        let head = SKShapeNode(circleOfRadius: 18)
        head.fillColor = bodyColor
        head.strokeColor = strokeColor
        head.lineWidth = 2
        head.position = CGPoint(x: 28, y: 10)
        bodyNode.addChild(head)

        // Snout
        let snout = SKShapeNode(ellipseOf: CGSize(width: 16, height: 10))
        snout.fillColor = UIColor(red: 0.90, green: 0.72, blue: 0.35, alpha: 1.0)
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
        ear.fillColor = UIColor(red: 0.70, green: 0.45, blue: 0.10, alpha: 1.0)
        ear.strokeColor = strokeColor
        ear.lineWidth = 1.5
        ear.position = CGPoint(x: 22, y: 22)
        ear.zRotation = 0.3
        bodyNode.addChild(ear)

        // Tail (curved upward)
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

        // Legs (4 rectangles)
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
        body.contactTestBitMask = PhysicsCategory.finishLine
        body.collisionBitMask   = PhysicsCategory.ground
        physicsBody = body
    }

    // MARK: - Movement

    func moveTo(position: CGPoint) {
        targetPosition = position
        isMoving = true
        bodyNode.xScale = position.x < self.position.x ? -1 : 1
    }

    func stopMoving() {
        targetPosition = nil
        isMoving = false
        physicsBody?.velocity.dx = 0
    }

    func updateMovement() {
        guard let target = targetPosition else {
            if let vx = physicsBody?.velocity.dx, abs(vx) > 1 {
                physicsBody?.velocity.dx = vx * 0.8
            }
            return
        }
        let dx = target.x - position.x
        if abs(dx) < 25 {
            stopMoving()
        } else {
            physicsBody?.velocity.dx = dx > 0 ? 190.0 : -190.0
        }
    }
}
