import SpriteKit

class Spectrogram2D: SKView, VisualizerViewProtocol {
    
    var data: FrequencyData!
    let magnitudeRange: ClosedRange<Float> = 0...1
    
    func update(with data: FrequencyData) {
        
        self.data = data
        data.magnitudes = data.magnitudes.map {(mag: Float) -> Float in mag.clamp(to: magnitudeRange)}
        
        DispatchQueue.main.async {
            self.update()
        }
    }
    
    var bars: [Spectrogram2DBar] = []
    
    override func awakeFromNib() {
        
        AppDelegate.play = true
        
        let scene = SKScene(size: self.bounds.size)
        scene.anchorPoint = CGPoint(x: 0, y: 0)
        scene.backgroundColor = NSColor.black
        
        for i in 0..<10 {
        
            let bar = Spectrogram2DBar(position: NSPoint(x: i * 40 + 25, y: 20))
            bars.append(bar)
            scene.addChild(bar)
        }
        
        presentScene(scene)
    }
    
    // TODO
    func setColors(startColor: NSColor, endColor: NSColor) {
        
        Spectrogram2DBar.setColors(startColor: startColor, endColor: endColor)
        bars.forEach {$0.colorsUpdated()}
    }
    
    // TODO: Test this with random mags (with a button to trigger an iteration)
    
    func update() {
        
        for i in 0..<10 {
            bars[i].magnitude = CGFloat(data.magnitudes[i])
        }
    }
}

class Spectrogram2DBar: SKSpriteNode {
    
    static var startColor: NSColor = .green
    static var endColor: NSColor = .red
    
    private static var gradientImage: NSImage = NSImage(named: "Sp-Gradient-Narrow")!
    private static var gradientTexture = SKTexture(image: gradientImage)
    
    var magnitude: CGFloat {
        
        didSet {

            let partialTexture = SKTexture(rect: NSRect(x: 0, y: 0, width: 1, height: max(0.001, magnitude)), in: Self.gradientTexture)
            run(SKAction.setTexture(partialTexture, resize: true))
        }
    }
    
    init(position: NSPoint, magnitude: CGFloat = 0) {
        
        self.magnitude = magnitude
        super.init(texture: Self.gradientTexture, color: Self.startColor, size: Self.gradientImage.size)
        
        self.anchorPoint = NSPoint.zero
        self.position = position
        
        self.color = Self.startColor
        self.blendMode = .replace
        
        self.size = Self.gradientImage.size
        self.yScale = 1
        
        let partialTexture = SKTexture(rect: NSRect(x: 0, y: 0, width: 1, height: max(0.001, magnitude)), in: Self.gradientTexture)
        run(SKAction.setTexture(partialTexture, resize: true))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func colorsUpdated() {
        self.color = Self.startColor
    }
    
    static func setColors(startColor: NSColor, endColor: NSColor) {
        
        Self.startColor = startColor
        Self.endColor = endColor

        // Compute a new gradient image
        gradientImage = NSImage(gradientColors: [startColor, endColor], imageSize: gradientImage.size)
        gradientTexture = SKTexture(image: gradientImage)
    }
}
