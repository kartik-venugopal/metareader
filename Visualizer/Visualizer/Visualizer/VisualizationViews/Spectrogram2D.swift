import SpriteKit

class AuralSKView: SKView {
    
    override func draw(_ dirtyRect: NSRect) {
        
        if self.scene == nil {
            
            NSColor.black.setFill()
            dirtyRect.fill()
            
        } else {
            super.draw(dirtyRect)
        }
    }
}

class Spectrogram2D: AuralSKView, VisualizerViewProtocol {
    
    var data: FrequencyData!
    let magnitudeRange: ClosedRange<CGFloat> = 0...1
    
    var bars: [Spectrogram2DBar] = []
    
    var xMargin: CGFloat = 25
    var yMargin: CGFloat = 20
    
    var spacing: CGFloat = 10
    
    var numberOfBands: Int = 10 {
        
        didSet {
            
            Spectrogram2DBar.numberOfBands = numberOfBands
            spacing = numberOfBands == 10 ? 10 : 2
            
            self.isPaused = true
            
            bars.removeAll()
            scene?.removeAllChildren()
            
            for i in 0..<numberOfBands {
            
                let bar = Spectrogram2DBar(position: NSPoint(x: (CGFloat(i) * (Spectrogram2DBar.barWidth + spacing)) + xMargin, y: yMargin))
                bars.append(bar)
                scene?.addChild(bar)
            }
            
            self.isPaused = false
        }
    }
    
    func presentView() {
        
        if self.scene == nil {
            
            let scene = SKScene(size: self.bounds.size)
            scene.anchorPoint = CGPoint.zero
            scene.backgroundColor = NSColor.black
            presentScene(scene)
            
            numberOfBands = 10
        }
        
        scene?.isPaused = false
        scene?.isHidden = false
        show()
    }
    
    func dismissView() {

        scene?.isPaused = true
        scene?.isHidden = true
        hide()
    }
    
    override func awakeFromNib() {
        
        print("\nCurrent Spec 2D scene: \(self.scene)")
    }
    
    func setColors(startColor: NSColor, endColor: NSColor) {
        
        Spectrogram2DBar.setColors(startColor: startColor, endColor: endColor)
        bars.forEach {$0.colorsUpdated()}
    }
    
    // TODO: Test this with random mags (with a button to trigger an iteration)
    
    func update() {
        
        for i in 0..<numberOfBands {
            bars[i].magnitude = CGFloat(FrequencyData.bands[i].maxVal).clamp(to: magnitudeRange)
        }
    }
}

class Spectrogram2DBar: SKSpriteNode {
    
    static var startColor: NSColor = .green
    static var endColor: NSColor = .red
    
    static var barWidth: CGFloat = 30
    static let minHeight: CGFloat = 0.01
    
    static var numberOfBands: Int = 10 {
        
        didSet {
            
            gradientImage = numberOfBands == 10 ? gradientImage_10Band : gradientImage_31Band
            barWidth = numberOfBands == 10 ? 30 : 10
        }
    }
    
    private static var gradientImage_10Band: NSImage = NSImage(named: "Sp-Gradient-10Band")!
    private static var gradientImage_31Band: NSImage = NSImage(named: "Sp-Gradient-31Band")!
    
    private static var gradientImage: NSImage = gradientImage_10Band {
        
        didSet {
            gradientTexture = SKTexture(image: gradientImage)
        }
    }
    
    private static var gradientTexture = SKTexture(image: gradientImage)
    
    var magnitude: CGFloat {
        
        didSet {
            
//            self.yScale = max(magnitude, 0.01)
//            run(SKAction.colorize(with: Self.startColor.interpolate(Self.endColor, magnitude),
//                              colorBlendFactor: 1, duration: 0))
            let partialTexture = SKTexture(rect: NSRect(x: 0, y: 0, width: 1, height: max(Self.minHeight, magnitude)), in: Self.gradientTexture)
            run(SKAction.setTexture(partialTexture, resize: true))
        }
    }
    
    init(position: NSPoint, magnitude: CGFloat = 0) {
        
        self.magnitude = magnitude
//        let colorForMagnitude = Self.startColor.interpolate(Self.endColor, magnitude)
        
        super.init(texture: Self.gradientTexture, color: Self.startColor, size: Self.gradientImage.size)
//        super.init(texture: nil, color: colorForMagnitude, size: NSSize(width: 30, height: 240))
        
        self.yScale = 1
        self.alpha = 0

        self.anchorPoint = NSPoint.zero
        self.position = position
        
        self.blendMode = .replace
        
        let partialTexture = SKTexture(rect: NSRect(x: 0, y: 0, width: 1, height: max(Self.minHeight, magnitude)), in: Self.gradientTexture)
        let textureAction = SKAction.setTexture(partialTexture, resize: true)
        let fadeInAction = SKAction.fadeIn(withDuration: 1)
        
        run(SKAction.sequence([textureAction, fadeInAction]))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func colorsUpdated() {
        
        self.color = Self.startColor
//        self.color = Self.startColor.interpolate(Self.endColor, magnitude)
    }
    
    static func setColors(startColor: NSColor, endColor: NSColor) {
        
        Self.startColor = startColor
        Self.endColor = endColor
        
        // Compute a new gradient image
        gradientImage_10Band = NSImage(gradientColors: [startColor, endColor], imageSize: gradientImage_10Band.size)
        gradientImage_31Band = NSImage(gradientColors: [startColor, endColor], imageSize: gradientImage_31Band.size)
        
        gradientImage = numberOfBands == 10 ? gradientImage_10Band : gradientImage_31Band
        gradientTexture = SKTexture(image: gradientImage)
    }
}
