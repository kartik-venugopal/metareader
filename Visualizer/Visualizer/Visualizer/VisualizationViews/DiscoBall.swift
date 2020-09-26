import Foundation
import SceneKit

class DiscoBall: SCNView, VisualizerViewProtocol {
    
    let type: VisualizationType = .discoBall
    
    var camera: SCNCamera!
    var cameraNode: SCNNode!
    
    var ball: SCNSphere!
    var node: SCNNode!
    
    var floorNode: SCNNode!
    var floor: SCNFloor!
    
    let textureImage: NSImage = NSImage(named: "DiscoBall")!
    
    func presentView() {
        
        if self.scene == nil {
            
            self.scene = SCNScene()
            scene?.background.contents = NSColor.black
            
            camera = SCNCamera()
            cameraNode = SCNNode()
            cameraNode.camera = camera

            cameraNode.position = SCNVector3(1, 4.25, 3.5)
            cameraNode.eulerAngles = SCNVector3Make(-(piOver180 * 45), 0, 0)

            scene!.rootNode.addChildNode(cameraNode)
            
            ball = SCNSphere(radius: 1)
            node = SCNNode(geometry: ball)
            node.opacity = 0
            
            node.position = SCNVector3(1, 2, 1)
            ball.firstMaterial?.diffuse.contents = textureImage.tinting(startColor)
            ball.firstMaterial?.diffuse.wrapS = .clamp
            ball.firstMaterial?.diffuse.wrapT = .clamp
            
            scene!.rootNode.addChildNode(node)
            
            floor = SCNFloor()
            floor.firstMaterial?.diffuse.contents = NSColor.black
            floor.firstMaterial?.lightingModel = .physicallyBased

            floorNode = SCNNode(geometry: floor)
            scene!.rootNode.addChildNode(floorNode)
            
            antialiasingMode = .multisampling4X
            isJitteringEnabled = true
            allowsCameraControl = true
            autoenablesDefaultLighting = false
            showsStatistics = false
            
            for level in 0...10 {
                textureCache.append(textureImage.tinting(startColor.interpolate(endColor, CGFloat(level) * 0.1)))
            }
        }
        
        scene?.isPaused = false
        show()
    }
    
    func dismissView() {
        scene?.isPaused = true
        hide()
    }
    
    func updateTextureCache() {
        
        for level in 0...10 {
            textureCache[level] = textureImage.tinting(startColor.interpolate(endColor, CGFloat(level) * 0.1))
        }
    }
    
    override func viewDidUnhide() {
        node.runAction(SCNAction.fadeIn(duration: 1))
    }
    
    var startColor: NSColor = .blue
    var endColor: NSColor = .red
    var rotation: CGFloat = 0
    
    // 11 images (11 levels of interpolation)
    var textureCache: [NSImage] = []
    
    func update() {
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.05
        
        let mag = CGFloat(FrequencyData.peakBassMagnitude.clamp(to: fftMagnitudeRange))
        
        ball.radius = 1 + (mag / 4.0)
        node.position = SCNVector3(1, 2, 1)
        
        let interpolationLevel: Int = min(Int(round(mag * 10.0)), 10)
        ball.firstMaterial?.diffuse.contents = textureCache[interpolationLevel]
        
        if mag > 0.3 {
            rotation += mag * 5
            node.rotation = SCNVector4Make(0, 1, 0, rotation * piOver180)
        }
        
        SCNTransaction.commit()
    }
    
    func setColors(startColor: NSColor, endColor: NSColor) {
        
        self.startColor = startColor
        self.endColor = endColor
        
        if !self.isHidden {
            updateTextureCache()
        }
    }
}
