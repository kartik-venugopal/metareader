import Cocoa
import AVFoundation

protocol VisualizerViewProtocol {
    
    func update()
    
    func setColors(startColor: NSColor, endColor: NSColor)
    
    func presentView()
    
    func dismissView()
}

class Visualizer: NSObject, PlayerOutputRenderObserver, NSMenuDelegate {
    
    @IBOutlet weak var spectrogram2D: Spectrogram2D!
    @IBOutlet weak var spectrogram3D: Spectrogram3D!
    @IBOutlet weak var supernova: Supernova!
    @IBOutlet weak var discoBall: DiscoBall!
    
    @IBOutlet weak var typeMenu: NSMenu!
    @IBOutlet weak var spectrogram2DMenuItem: NSMenuItem!
    @IBOutlet weak var spectrogram3DMenuItem: NSMenuItem!
    @IBOutlet weak var supernovaMenuItem: NSMenuItem!
    @IBOutlet weak var discoBallMenuItem: NSMenuItem!
    
    @IBOutlet weak var startColorPicker: NSColorWell!
    @IBOutlet weak var endColorPicker: NSColorWell!
    
    var vizView: VisualizerViewProtocol!
    private let fft = FFT.instance
    
    override func awakeFromNib() {
        
        AppDelegate.play = true
        
        spectrogram2DMenuItem.representedObject = VisualizationType.spectrogram2D
        spectrogram3DMenuItem.representedObject = VisualizationType.spectrogram3D
        supernovaMenuItem.representedObject = VisualizationType.supernova
        discoBallMenuItem.representedObject = VisualizationType.discoBall
    }
    
    @IBAction func changeTypeAction(_ sender: NSPopUpButton) {
        
        if let vizType = sender.selectedItem?.representedObject as? VisualizationType {
            
            switch vizType {
                
            case .spectrogram2D:
                
                vizView = spectrogram2D
                spectrogram2D.presentView()
                
                spectrogram3D.dismissView()
                supernova.dismissView()
                discoBall.dismissView()
                
            case .spectrogram3D:
                
                vizView = spectrogram3D
                spectrogram3D.presentView()
                
                spectrogram2D.dismissView()
                supernova.dismissView()
                discoBall.dismissView()
                
            case .supernova:
                
                vizView = supernova
                supernova.presentView()
                
                spectrogram2D.dismissView()
                spectrogram3D.dismissView()
                discoBall.dismissView()
                
            case .discoBall:
                
                vizView = discoBall
                discoBall.presentView()
                
                spectrogram2D.dismissView()
                spectrogram3D.dismissView()
                supernova.dismissView()
            }
        }
    }
    
    @IBAction func changeNumberOfBandsAction(_ sender: NSPopUpButton) {
        
        let numBands = sender.selectedTag()
        
        if numBands > 0 {
            
            FrequencyData.numBands = numBands
            spectrogram2D.numberOfBands = numBands
            spectrogram3D.numberOfBands = numBands
        }
    }
    
    func performRender(inTimeStamp: AudioTimeStamp, inNumberFrames: UInt32, audioBuffer: AudioBufferList) {
            
        fft.analyze(audioBuffer)
        
//        if FrequencyData.numBands != 10 {
//            NSLog("Bands: \(FrequencyData.bands.map {$0.maxVal})")
//        }

        DispatchQueue.main.async {
            self.vizView?.update()
        }
    }
    
    @IBAction func setColorsAction(_ sender: NSColorWell) {
        
        vizView.setColors(startColor: self.startColorPicker.color, endColor: self.endColorPicker.color)
        
        [spectrogram2D, spectrogram3D, supernova, discoBall].forEach {
            
            if $0 !== (vizView as! NSView) {
                ($0 as? VisualizerViewProtocol)?.setColors(startColor: self.startColorPicker.color, endColor: self.endColorPicker.color)
            }
        }
    }
}

enum VisualizationType {
    
    case spectrogram2D, spectrogram3D, supernova, discoBall
}
