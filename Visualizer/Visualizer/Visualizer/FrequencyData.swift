import Cocoa

struct BandFRange {
    
    let minF: Float
    let maxF: Float
    
    let minIndex: Int
    let maxIndex: Int
}

class FrequencyData {
    
    static func setUp(sampleRate: Float, bufferSize: Int, numBands: Int? = nil) {
        
        Self.bufferSize = bufferSize
        Self.sampleRate = sampleRate
        
        Self.numBands = numBands ?? 10
    }
    
    private(set) static var sampleRate: Float = 44100 {

        didSet {
            fftFrequencies = (0..<halfBufferSize).map {Float($0) * nyquistFrequency / halfBufferSize_Float}
        }
    }
    
    static var nyquistFrequency: Float {
        sampleRate / 2
    }
    
    private(set) static var bufferSize: Int = 512 {
        
        didSet {
            
            bufferSize_Float = Float(bufferSize)
            halfBufferSize = bufferSize / 2
        }
    }
    
    private(set) static var bufferSize_Float: Float = 512
    
    private(set) static var halfBufferSize: Int = 512 {
        
        didSet {
            halfBufferSize_Float = Float(halfBufferSize)
        }
    }
    
    private(set) static var halfBufferSize_Float: Float = 512
    
    private(set) static var fftFrequencies: [Float] = []
    
    static var numBands: Int = 10 {
        
        didSet {
            bands = numBands == 10 ? bands_10 : bands_31
        }
    }
    
    static var bassBands: [Band] {
        numBands == 10 ? [bands[0], bands[1], bands[2]] : [bands[0], bands[1], bands[2], bands[3], bands[4]]
    }
    
    private(set) static var bands: [Band] = []
    
    static var bands_10: [Band] {
        
        let arr: [Float] = [31, 63, 125, 250, 500, 1000, 2000, 4000, 8000, 16000]
        
        let tpb: Float = 2
        let firstFrequency: Float = fftFrequencies[1]
        
        var bands: [Band] = []
        
        for index in 0..<arr.count {
            
            let f = arr[index]
            let minF: Float = index > 0 ? bands[index - 1].maxF : sqrt((f * f) / tpb)
            let maxF: Float = sqrt((f * f) / tpb) * tpb
            
            let minIndex: Int = Int(round(minF / firstFrequency))
            let maxIndex: Int = Int(round(maxF / firstFrequency)) - 1
            
            bands.append(Band(minF: minF, maxF: maxF, minIndex: minIndex, maxIndex: maxIndex))
        }

        return bands
    }
    
    static var bands_31: [Band] {
        
        // 20/25/31.5/40/50/63/80/100/125/160/200/250/315/400/500/630/800/1K/1.25K/1.6K/ 2K/ 2.5K/3.15K/4K/5K/6.3K/8K/10K/12.5K/16K/20K
        
        let arr: [Float] = [20, 31.5, 63, 100, 125, 160, 200, 250, 315, 400, 500, 630, 800,
                            1000, 1250, 1600, 2000, 2500, 3150, 4000, 5000, 6300, 8000, 10000, 12500, 16000, 20000]

        var bands: [Band] = []
        let firstFrequency: Float = fftFrequencies[1]
        
        let tpb: Float = pow(2, 1.0/3.0)

        // NOTE: These bands assume a buffer size of 2048, i.e. 1024 FFT output data points.
        
        bands.append(Band(minF: sqrt((20 * 20) / tpb), maxF: sqrt((20 * 20) / tpb) * tpb, minIndex: 0, maxIndex: 0))
        bands.append(Band(minF: sqrt((31.5 * 31.5) / tpb), maxF: sqrt((31.5 * 31.5) / tpb) * tpb, minIndex: 1, maxIndex: 2))
        bands.append(Band(minF: bands[1].maxF, maxF: sqrt((63 * 63) / tpb) * tpb, minIndex: 3, maxIndex: 3))
        bands.append(Band(minF: bands[2].maxF, maxF: sqrt((100 * 100) / tpb) * tpb, minIndex: 4, maxIndex: 4))
        bands.append(Band(minF: bands[3].maxF, maxF: sqrt((125 * 125) / tpb) * tpb, minIndex: 5, maxIndex: 6))
        bands.append(Band(minF: bands[4].maxF, maxF: sqrt((160 * 160) / tpb) * tpb, minIndex: 7, maxIndex: 7))
        
        for index in 6..<arr.count {
            
            let f = arr[index]
            let minF: Float = bands[index - 1].maxF
            let maxF: Float = sqrt((f * f) / tpb) * tpb
            
            var minIndex: Int = Int(round(minF / firstFrequency))
            var maxIndex: Int = min(Int(round(maxF / firstFrequency)) - 1, halfBufferSize - 1)
            
            if maxIndex < minIndex {
                minIndex = 0
                maxIndex = 0
            }
            
            bands.append(Band(minF: minF, maxF: maxF, minIndex: minIndex, maxIndex: maxIndex))
        }
        
        return bands
    }
    
    static var peakBassMagnitude: Float = 0
}

class Band {
    
    let minF: Float
    let maxF: Float
    
    let minIndex: Int
    let maxIndex: Int
    let indexCount: UInt
    
    var avgVal: Float = 0
    var maxVal: Float = 0
    
    init(minF: Float, maxF: Float, minIndex: Int, maxIndex: Int) {
        
        self.minF = minF
        self.maxF = maxF
        
        self.minIndex = minIndex
        self.maxIndex = maxIndex
        self.indexCount = UInt(maxIndex - minIndex + 1)
    }
    
    func toString() -> String {
//        return "minF: \(minF), maxF: \(maxF), minIndex: \(minIndex), maxIndex: \(maxIndex), avg: \(avgVal), max: \(maxVal)"
        return "minF: \(minF), maxF: \(maxF), minIndex: \(minIndex), maxIndex: \(maxIndex)"
    }
}

