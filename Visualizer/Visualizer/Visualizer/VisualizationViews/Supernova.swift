import SpriteKit

class Supernova: SKView, VisualizerViewProtocol {
    
    var ring: SKShapeNode!
    private var gradientImage: NSImage = NSImage(named: "BallTex")!
    private lazy var gradientTexture = SKTexture(image: gradientImage)
    
    override func awakeFromNib() {
        
        let scene = SKScene(size: self.bounds.size)
        scene.backgroundColor = NSColor.black
        scene.anchorPoint = CGPoint(x: 0, y: 0)
        
        self.ring = SKShapeNode(circleOfRadius: 100)
        ring.position = NSPoint(x: 220, y: 160)
        ring.fillColor = NSColor.black
        
        ring.strokeTexture = gradientTexture
        ring.strokeColor = startColor
        ring.lineWidth = 75
        ring.glowWidth = 50
        ring.alpha = 0

        ring.yScale = 1
        ring.blendMode = .replace
        ring.isAntialiased = true
        
        scene.addChild(ring)
        presentScene(scene)
        
        ring.run(SKAction.fadeIn(withDuration: 1))
    }
    
    var startColor: NSColor = .green
    var endColor: NSColor = .red
    
    func setColors(startColor: NSColor, endColor: NSColor) {
        
        self.startColor = startColor
        self.endColor = endColor
    }
    
    func update() {
        
        let peakMagnitude = CGFloat(FrequencyData.peakBassMagnitude.clamp(to: 0...1))
        ring.strokeColor = startColor.interpolate(endColor, peakMagnitude)
        ring.run(SKAction.scale(to: peakMagnitude, duration: 0.05))
    }
}
