import Foundation
import Accelerate
import AVFoundation

class FFT {
    
    static let instance: FFT = FFT()
    
    private init() {}
    
    private var fftSetup: FFTSetup!
    
    private var log2n: UInt = 9
    
    private var bufferSizePOT: Int = 512
    private var bufferSizePOT_Float: Float = 512
    
    private var halfBufferSize: Int = 256
    private var halfBufferSize_Int32: Int32 = 256
    private var halfBufferSize_UInt: UInt = 256
    private var halfBufferSize_Float: Float = 256
    
    private let vsMulScalar: [Float] = [Float(1.0) / Float(150.0)]
    
    private var realp: [Float] = []
    private var imagp: [Float] = []
    private var output: DSPSplitComplex!
    
    private var transferBuffer: UnsafeMutablePointer<Float> = UnsafeMutablePointer<Float>.allocate(capacity: 0)
    private var window: [Float] = []
    private var windowSize: Int = 512
    private var windowSize_vDSPLength: vDSP_Length = 512
    
    private let fftRadix: Int32 = Int32(kFFTRadix2)
    private let vDSP_HANN_NORM_Int32: Int32 = Int32(vDSP_HANN_NORM)
    private let fftDirection: FFTDirection = FFTDirection(FFT_FORWARD)
    private var zeroDBReference: Float = 1
    
    private var magnitudes: [Float] = []
    private var normalizedMagnitudes: UnsafeMutablePointer<Float> = UnsafeMutablePointer<Float>.allocate(capacity: 0)
    
    private(set) var bufferSize: Int = 512 {
        
        didSet {
            
            log2n = UInt(round(log2(Double(bufferSize))))
            
            bufferSizePOT = Int(1 << log2n)
            bufferSizePOT_Float = Float(bufferSizePOT)
            
            halfBufferSize = bufferSizePOT / 2
            halfBufferSize_Int32 = Int32(halfBufferSize)
            halfBufferSize_UInt = UInt(halfBufferSize)
            halfBufferSize_Float = Float(halfBufferSize)
            
            fftSetup = vDSP_create_fftsetup(log2n, fftRadix)!
            
            realp = [Float](repeating: 0, count: halfBufferSize)
            imagp = [Float](repeating: 0, count: halfBufferSize)
            output = DSPSplitComplex(realp: &realp, imagp: &imagp)
            
            windowSize = bufferSizePOT
            windowSize_vDSPLength = vDSP_Length(windowSize)
            
            transferBuffer = UnsafeMutablePointer<Float>.allocate(capacity: windowSize)
            window = [Float](repeating: 0, count: windowSize)
            
            magnitudes = [Float](repeating: 0, count: halfBufferSize)
            normalizedMagnitudes = UnsafeMutablePointer<Float>.allocate(capacity: halfBufferSize)
        }
    }
    
    func setUp(sampleRate: Float, bufferSize: Int, numBands: Int? = nil) {
        
        self.bufferSize = bufferSize
        FrequencyData.setUp(sampleRate: sampleRate, bufferSize: bufferSize, numBands: numBands)
    }
    
    func analyze(_ buffer: AudioBufferList) {
        
        let bufferPtr: UnsafePointer<Float> = UnsafePointer(buffer.mBuffers.mData!.assumingMemoryBound(to: Float.self))
        
        // Hann windowing to reduce the frequency leakage
        vDSP_hann_window(&window, windowSize_vDSPLength, vDSP_HANN_NORM_Int32)
        vDSP_vmul(bufferPtr, 1, window, 1, transferBuffer, 1, windowSize_vDSPLength)
        
        transferBuffer.withMemoryRebound(to: DSPComplex.self, capacity: windowSize) {dspComplexStream in
            vDSP_ctoz(dspComplexStream, 2, &output, 1, halfBufferSize_UInt)
        }
        
        // Perform the FFT
        vDSP_fft_zrip(fftSetup, &output, 1, log2n, fftDirection)
        
        // Convert FFT output to magnitudes
        vDSP_zvmags(&output, 1, &magnitudes, 1, halfBufferSize_UInt)
        
        // Convert to dB and scale.
        vDSP_vdbcon(&magnitudes, 1, &zeroDBReference, normalizedMagnitudes, 1, halfBufferSize_UInt, 1)
        vDSP_vsmul(normalizedMagnitudes, 1, vsMulScalar, normalizedMagnitudes, 1, halfBufferSize_UInt)
        
        for band in FrequencyData.bands {
            vDSP_maxv(normalizedMagnitudes.advanced(by: band.minIndex), 1, &band.maxVal, band.indexCount)
        }

        // Bass bands peak
        vDSP_maxv(FrequencyData.bassBands.map {$0.maxVal}, 1, &FrequencyData.peakBassMagnitude, 2)
    }
    
    deinit {
        
        if fftSetup != nil {
            vDSP_destroy_fftsetup(fftSetup)
        }
        
        transferBuffer.deallocate()
        normalizedMagnitudes.deallocate()
    }
}

extension Array where Element: FloatingPoint {
    
    func fastMin() -> Float {
        
        let floats = self as! [Float]
        var min: Float = 0
        vDSP_minv(floats, 1, &min, UInt(count))
        return min
    }
    
    func fastMax() -> Float {
        
        let floats = self as! [Float]
        var max: Float = 0
        vDSP_maxv(floats, 1, &max, UInt(count))
        return max
    }
    
    func avg() -> Float {
        
        let floats = self as! [Float]
        var mean: Float = 0
        vDSP_meanv(floats, 1, &mean, UInt(count))
        return mean
    }
}
