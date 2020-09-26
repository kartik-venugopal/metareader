import Cocoa
import AVFoundation

protocol VisualizerViewProtocol {
    
    var type: VisualizationType {get}
    
    func update()
    
    func setColors(startColor: NSColor, endColor: NSColor)
    
    func presentView()
    
    func dismissView()
}

class Visualizer: NSObject, PlayerOutputRenderObserver, NSMenuDelegate {
    
    @IBOutlet weak var containerBox: VisualizerContainer!
    
    @IBOutlet weak var spectrogram: Spectrogram!
    @IBOutlet weak var supernova: Supernova!
    @IBOutlet weak var discoBall: DiscoBall!
    
    @IBOutlet weak var typeMenu: NSMenu!
    @IBOutlet weak var spectrogramMenuItem: NSMenuItem!
    @IBOutlet weak var supernovaMenuItem: NSMenuItem!
    @IBOutlet weak var discoBallMenuItem: NSMenuItem!

    @IBOutlet weak var optionsBox: NSBox!
    @IBOutlet weak var startColorPicker: NSColorWell!
    @IBOutlet weak var endColorPicker: NSColorWell!
    
    var vizView: VisualizerViewProtocol!
    private let fft = FFT.instance
    
    override func awakeFromNib() {
        
        containerBox.startTracking()
        
        [spectrogram, supernova, discoBall].forEach {$0?.anchorToView(containerBox)}
        
        AppDelegate.play = true
        
        changeType(.spectrogram)
        
        FrequencyData.numBands = 27
        spectrogram.numberOfBands = 27
        
        spectrogramMenuItem.representedObject = VisualizationType.spectrogram
        supernovaMenuItem.representedObject = VisualizationType.supernova
        discoBallMenuItem.representedObject = VisualizationType.discoBall
        
        NotificationCenter.default.addObserver(forName: Notification.Name("showOptions"), object: nil, queue: nil, using: {_ in
            self.optionsBox.show()
        })
        
        NotificationCenter.default.addObserver(forName: Notification.Name("hideOptions"), object: nil, queue: nil, using: {_ in
            self.optionsBox.hide()
        })
    }
    
    @IBAction func changeTypeAction(_ sender: NSPopUpButton) {
        
        if let vizType = sender.selectedItem?.representedObject as? VisualizationType {
            changeType(vizType)
        }
    }
    
    func changeType(_ type: VisualizationType) {
        
        if let theVizView = vizView, theVizView.type == type {return}
        
        switch type {
            
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

class VisualizerContainer: NSBox {
    
    override func viewDidEndLiveResize() {
        
        super.viewDidEndLiveResize()
        
        self.removeAllTrackingAreas()
        self.updateTrackingAreas()
        
        NotificationCenter.default.post(name: Notification.Name("hideOptions"), object: nil)
    }
    
    // Signals the view to start tracking mouse movements.
    func startTracking() {
        
        self.removeAllTrackingAreas()
        self.updateTrackingAreas()
    }
    
    // Signals the view to stop tracking mouse movements.
    func stopTracking() {
        self.removeAllTrackingAreas()
    }
    
    override func updateTrackingAreas() {
        
        // Create a tracking area that covers the bounds of the view. It should respond whenever the mouse enters or exits.
        addTrackingArea(NSTrackingArea(rect: self.bounds, options: [NSTrackingArea.Options.activeAlways, NSTrackingArea.Options.mouseEnteredAndExited], owner: self, userInfo: nil))
        
        super.updateTrackingAreas()
    }
    
    override func mouseEntered(with event: NSEvent) {
        NotificationCenter.default.post(name: Notification.Name("showOptions"), object: nil)
    }
    
    override func mouseExited(with event: NSEvent) {
        NotificationCenter.default.post(name: Notification.Name("hideOptions"), object: nil)
    }
}
