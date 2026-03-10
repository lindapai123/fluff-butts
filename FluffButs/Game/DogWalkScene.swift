import SpriteKit

// MARK: - DogWalkScene
// A simple SpriteKit scene used on the dog selection screen.
// The chosen dog walks around randomly until the player taps Play.
final class DogWalkScene: SKScene {

    private var dog: DogNode!
    private let breed: DogBreed
    private var walkTimer: TimeInterval = 0
    private var nextWalkInterval: TimeInterval = 1.5

    // MARK: - Init

    init(size: CGSize, breed: DogBreed) {
        self.breed = breed
        super.init(size: size)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = .clear
        physicsWorld.gravity = .zero   // No gravity — dog floats freely

        dog = DogNode(breed: breed)
        // Start in centre
        dog.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(dog)

        scheduleNextWalk()
    }

    // MARK: - Random Walk

    private func scheduleNextWalk() {
        let interval = TimeInterval.random(in: 1.0...2.8)
        let wait     = SKAction.wait(forDuration: interval)
        let walk     = SKAction.run { [weak self] in self?.pickNewTarget() }
        run(SKAction.sequence([wait, walk, SKAction.run { [weak self] in self?.scheduleNextWalk() }]))
    }

    private func pickNewTarget() {
        let margin: CGFloat = 60
        let tx = CGFloat.random(in: margin...(size.width  - margin))
        let ty = CGFloat.random(in: margin...(size.height - margin))
        let target = CGPoint(x: tx, y: ty)

        let dx       = target.x - dog.position.x
        let distance = hypot(dx, target.y - dog.position.y)
        let speed: CGFloat = 120
        let duration = Double(distance / speed)

        dog.run(SKAction.sequence([
            SKAction.run { [weak self] in
                // Flip dog to face direction of travel
                self?.dog.faceDirection(goingRight: dx > 0)
            },
            SKAction.move(to: target, duration: duration)
        ]))
    }

    // MARK: - Update breed live (called when user switches selection)

    func switchBreed(to newBreed: DogBreed) {
        dog.removeFromParent()
        let pos = dog.position
        dog = DogNode(breed: newBreed)
        dog.position = pos
        addChild(dog)
        dog.removeAllActions()
        scheduleNextWalk()
    }
}
