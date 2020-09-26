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

class Spectrogram: AuralSKView, VisualizerViewProtocol {
    
    var data: FrequencyData!
    
    var bars: [SpectrogramBar] = []
    
    var xMargin: CGFloat = 25
    var yMargin: CGFloat = 20
    
    var spacing: CGFloat = 10
    
    var numberOfBands: Int = 10 {
        
        didSet {
            
            SpectrogramBar.numberOfBands = numberOfBands
            spacing = numberOfBands == 10 ? 10 : 2
            
            self.isPaused = true
            
            bars.removeAll()
            scene?.removeAllChildren()
            
            for i in 0..<numberOfBands {
            
                let bar = SpectrogramBar(position: NSPoint(x: (CGFloat(i) * (SpectrogramBar.barWidth + spacing)) + xMargin, y: yMargin))
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

        scene?.alpha = 0
        scene?.run(SKAction.fadeIn(withDuration: 1))
        
        scene?.isPaused = false
        scene?.isHidden = false
        show()
    }
    
    func dismissView() {

        scene?.isPaused = true
        scene?.isHidden = true
        hide()
    }
    
    func setColors(startColor: NSColor, endColor: NSColor) {
        SpectrogramBar.setColors(startColor: startColor, endColor: endColor)
    }
    
    // TODO: Test this with random mags (with a button to trigger an iteration)
    
    func update() {
        
        for i in 0..<numberOfBands {
            bars[i].magnitude = CGFloat(FrequencyData.bands[i].maxVal.clamp(to: fftMagnitudeRange))
        }
    }
}

class SpectrogramBar: SKSpriteNode {
    
    static var startColor: NSColor = .blue
    static var endColor: NSColor = .red
    
    static var barWidth: CGFloat = barWidth_10Band
    static let barWidth_10Band: CGFloat = 30
    static let barWidth_31Band: CGFloat = 13
    
    static let minHeight: CGFloat = 0.01
    
    static var numberOfBands: Int = 10 {
        
        didSet {
            
            gradientImage = numberOfBands == 10 ? gradientImage_10Band : gradientImage_31Band
            barWidth = numberOfBands == 10 ? barWidth_10Band : barWidth_31Band
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
            
            let partialTexture = SKTexture(rect: NSRect(x: 0, y: 0, width: 1, height: max(Self.minHeight, magnitude)), in: Self.gradientTexture)
            run(SKAction.setTexture(partialTexture, resize: true))
        }
    }
    
    init(position: NSPoint, magnitude: CGFloat = 0) {
        
        self.magnitude = magnitude
        
        super.init(texture: Self.gradientTexture, color: Self.startColor, size: Self.gradientImage.size)
        
        self.yScale = 1

        self.anchorPoint = NSPoint.zero
        self.position = position
        
        self.blendMode = .replace
        
        let partialTexture = SKTexture(rect: NSRect(x: 0, y: 0, width: 1, height: max(Self.minHeight, magnitude)), in: Self.gradientTexture)
        run(SKAction.setTexture(partialTexture, resize: true))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
