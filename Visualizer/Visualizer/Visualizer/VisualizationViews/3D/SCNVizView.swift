import SceneKit

class Spectrogram3D: SCNView, VisualizerViewProtocol {
    
    var data: FrequencyData!
    let magnitudeRange: ClosedRange<Float> = 0...1
    
    func update(with data: FrequencyData) {
        
        self.data = data
        data.magnitudes = data.magnitudes.map {(mag: Float) -> Float in mag.clamp(to: magnitudeRange)}
        
        DispatchQueue.main.async {
            self.update()
        }
    }
    
    var bars: [SpectrogramBar] = []
    
    var floorNode: SCNNode!
    var floor: SCNFloor!
    
    let piOver180: CGFloat = CGFloat.pi / 180
    
    let maxBarHt: CGFloat = 3.6
    let barThickness: CGFloat = 0.25
    
    var gradientImage: NSImage = NSImage(named: "Sp-Gradient")!
    
    private var startColor: NSColor = .green
    private var endColor: NSColor = .red
    
    override func awakeFromNib() {
        
        scene = SCNScene()
        scene?.background.contents = NSColor.black
        
        // MARK: Bar ---------------------------------------
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0
        
        for i in 0..<10 {
            
            let magnitude: CGFloat = CGFloat(i + 1) * 0.1
            
            let bar = SpectrogramBar(position: SCNVector3(CGFloat(i * 2) * barThickness, 0, 0),
                                     magnitude: magnitude,
                                     thickness: barThickness,
                                     gradientImage: gradientImage)
            
            bars.append(bar)
            scene!.rootNode.addChildNode(bar.node)
        }
        
        SCNTransaction.commit()
        
        // MARK: Floor ---------------------------------------
        
        floor = SCNFloor()
        floor.firstMaterial?.diffuse.contents = NSColor.black
        floor.firstMaterial?.lightingModel = .physicallyBased

        floorNode = SCNNode(geometry: floor)
        scene!.rootNode.addChildNode(floorNode)

        // MARK: Scene settings ---------------------------------------
        
        antialiasingMode = .multisampling4X
        isJitteringEnabled = true
        allowsCameraControl = true
        autoenablesDefaultLighting = false
        showsStatistics = false
    }
    
    func update() {
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0
        
        for i in 0..<10 {
            bars[i].magnitude = CGFloat(data.magnitudes[i])
        }
            
        SCNTransaction.commit()
    }
    
    func setColors(startColor: NSColor, endColor: NSColor) {
        
        self.startColor = startColor
        self.endColor = endColor
        
        SpectrogramBar.startColor = startColor
        SpectrogramBar.endColor = endColor
        
        gradientImage = NSImage(gradientColors: [startColor, endColor], imageSize: gradientImage.size)
        bars.forEach {$0.gradientImage = gradientImage}
    }
}
