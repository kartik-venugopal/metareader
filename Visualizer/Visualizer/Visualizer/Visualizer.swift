import Cocoa
import AVFoundation

protocol VisualizerViewProtocol {
    
    func update()
    
    func setColors(startColor: NSColor, endColor: NSColor)
    
    func presentView()
    
    func dismissView()
}

class Visualizer: NSObject, PlayerOutputRenderObserver, NSMenuDelegate {
    
    @IBOutlet weak var containerView: NSView!
    
    @IBOutlet weak var spectrogram: Spectrogram!
    @IBOutlet weak var supernova: Supernova!
    @IBOutlet weak var discoBall: DiscoBall!
    
    @IBOutlet weak var typeMenu: NSMenu!
    @IBOutlet weak var spectrogramMenuItem: NSMenuItem!
    @IBOutlet weak var supernovaMenuItem: NSMenuItem!
    @IBOutlet weak var discoBallMenuItem: NSMenuItem!
    
    @IBOutlet weak var startColorPicker: NSColorWell!
    @IBOutlet weak var endColorPicker: NSColorWell!
    
    var vizView: VisualizerViewProtocol!
    private let fft = FFT.instance
    
    override func awakeFromNib() {
        
        [spectrogram, supernova, discoBall].forEach {$0?.anchorToView(containerView)}
        
        AppDelegate.play = true
        
        vizView = spectrogram
        spectrogram.presentView()
        
        discoBall.dismissView()
        supernova.dismissView()
        
//        spectrogramMenuItem.representedObject = VisualizationType.spectrogram
//        supernovaMenuItem.representedObject = VisualizationType.supernova
//        discoBallMenuItem.representedObject = VisualizationType.discoBall
    }
    
    @IBAction func changeTypeAction(_ sender: NSPopUpButton) {
        
        if let vizType = sender.selectedItem?.representedObject as? VisualizationType {
            
            switch vizType {
                
            case .spectrogram:
                
                vizView = spectrogram
                spectrogram.presentView()
                
                supernova.dismissView()
                discoBall.dismissView()
                
            case .supernova:
                
                vizView = supernova
                supernova.presentView()
                
                spectrogram.dismissView()
                discoBall.dismissView()
                
            case .discoBall:
                
                vizView = discoBall
                discoBall.presentView()
                
                spectrogram.dismissView()
                supernova.dismissView()
            }
        }
    }
    
    @IBAction func changeNumberOfBandsAction(_ sender: NSPopUpButton) {
        
        let numBands = sender.selectedTag()
        
        if numBands > 0 {
            
            FrequencyData.numBands = numBands
            spectrogram.numberOfBands = numBands
        }
    }
    
    func performRender(inTimeStamp: AudioTimeStamp, inNumberFrames: UInt32, audioBuffer: AudioBufferList) {
            
        fft.analyze(audioBuffer)
        
//        if FrequencyData.numBands != 10 {
//            NSLog("Bands: \(FrequencyData.bands.map {$0.maxVal})")
//        }
        
        if let theVizView = vizView {
            
            DispatchQueue.main.async {
                theVizView.update()
            }
        }
    }
    
    @IBAction func setColorsAction(_ sender: NSColorWell) {
        
        vizView.setColors(startColor: self.startColorPicker.color, endColor: self.endColorPicker.color)
        
        [spectrogram, supernova, discoBall].forEach {
            
            if $0 !== (vizView as! NSView) {
                ($0 as? VisualizerViewProtocol)?.setColors(startColor: self.startColorPicker.color, endColor: self.endColorPicker.color)
            }
        }
    }
}

enum VisualizationType {
    
    case spectrogram, supernova, discoBall
}
