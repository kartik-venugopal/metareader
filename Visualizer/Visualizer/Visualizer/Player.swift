/*
Wrapper around AVAudioEngine. Handles all audio-related operations ... playback, effects (DSP), etc. Receives calls from AppDelegate to modify settings and perform playback.
*/

import Foundation
import AVFoundation
import CoreAudioKit

typealias PlayerOutputRenderCallbackFilter = (UnsafeMutableRawPointer,
UnsafeMutablePointer<AudioUnitRenderActionFlags>,
UnsafePointer<AudioTimeStamp>,
UInt32,
UInt32,
UnsafeMutablePointer<AudioBufferList>?) -> Bool

protocol PlayerOutputRenderObserver: AURenderCallbackDelegate {}

@objc protocol AURenderCallbackDelegate {
func performRender(inTimeStamp: AudioTimeStamp,
    inNumberFrames: UInt32,
    audioBuffer: AudioBufferList)
}

func renderCallback(inRefCon: UnsafeMutableRawPointer,
ioActionFlags: UnsafeMutablePointer<AudioUnitRenderActionFlags>,
inTimeStamp: UnsafePointer<AudioTimeStamp>,
inBusNumber: UInt32,
inNumberFrames: UInt32,
ioData: UnsafeMutablePointer<AudioBufferList>?) -> OSStatus {
    
    let delegate = unsafeBitCast(inRefCon, to: AURenderCallbackDelegate.self)
    
    if ioActionFlags.pointee == .unitRenderAction_PostRender, let bufferList = ioData?.pointee {
        
        delegate.performRender(inTimeStamp: inTimeStamp.pointee,
                               inNumberFrames: inNumberFrames,
                               audioBuffer: bufferList)
    }
    
    return noErr
}

class Player: NSObject, AURenderCallbackDelegate {
    
    let playerNode: AVAudioPlayerNode = AVAudioPlayerNode()
    let audioEngine = AVAudioEngine()
    let mainMixer: AVAudioMixerNode
    
    var file: URL?
    var avFile: AVAudioFile?
    var duration: Double?
    
    var segmentFrames:AVAudioFrameCount?
    
    var startFrame: Double?
    var startSecs: Double?
    
    var outputRenderObserver: PlayerOutputRenderObserver?
    
    override init() {
        
        mainMixer = audioEngine.mainMixerNode
        super.init()
        setUp()
    }
    
    var bufferSize: Int = 512
    
    func setUp() {
        
        audioEngine.attach(playerNode)
        audioEngine.connect(playerNode, to: audioEngine.outputNode, format: nil)
        
        let au = audioEngine.outputNode.audioUnit!
        AudioUnitAddRenderNotify(au, renderCallback, Unmanaged.passUnretained(self).toOpaque())
        
        var sampleRate: Double = 0
        var sizeOfProp: UInt32 = UInt32(MemoryLayout<Double>.size)
        var error = AudioUnitGetProperty(au, kAudioDevicePropertyActualSampleRate, kAudioUnitScope_Global, 0, &sampleRate, &sizeOfProp)
        if error == noErr {
//            FFT.instance.sampleRate = Float(sampleRate)
        }
        
        var newBufferSize: UInt32 = 2048
        error = AudioUnitSetProperty(au, kAudioDevicePropertyBufferFrameSize, kAudioUnitScope_Global, 0, &newBufferSize, UInt32(MemoryLayout<UInt32>.size))
        if error == noErr {
            
            self.bufferSize = Int(newBufferSize)
            FFT.instance.setUp(sampleRate: Float(sampleRate), bufferSize: self.bufferSize)
        }
        
        playerNode.volume = 1
        audioEngine.mainMixerNode.volume = 1
        playerNode.pan = 0
    }
    
    // Prepares the player to play a given track
    func initPlayer(file: URL) {
        
        do {
            
            self.file = file
            avFile = try AVAudioFile(forReading: file)

            audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: avFile?.processingFormat)
            audioEngine.connect(audioEngine.mainMixerNode, to: audioEngine.outputNode, format: avFile?.processingFormat)
            
            audioEngine.prepare()
            
        } catch let error as NSError {
            print("Error reading track: " + file.path + ", error=" + error.description)
        }
    }
    
    func performRender(inTimeStamp: AudioTimeStamp, inNumberFrames: UInt32, audioBuffer: AudioBufferList) {
        
        DispatchQueue.global(qos: .userInteractive).async {
            self.outputRenderObserver?.performRender(inTimeStamp: inTimeStamp, inNumberFrames: inNumberFrames, audioBuffer: audioBuffer)
        }
    }
    
    // Resumes playback
    func play() {
        
        playerNode.scheduleFile(avFile!, at: nil, completionHandler: nil)
        
        do {
            try audioEngine.start()
        } catch let error as NSError {
            print(error.description)
        }
        
        playerNode.play()
    }
    
    // Starts playback for a given track
    func play(file: URL) {
        
        initPlayer(file: file)
        play()
    }
    
    func pause() {
        playerNode.pause()
    }
    
    func seekToTime(seconds: Double) {

        //        printVal("seekSEconds", value: seconds)
        
        duration = 392
        
//        let nodetime: AVAudioTime  = playerNode.lastRenderTime!
//        let playerTime: AVAudioTime = playerNode.playerTime(forNodeTime: nodetime)!
//        let sampleRate2 = playerTime.sampleRate
        
        let sampleRate = avFile!.processingFormat.sampleRate
        
        let startSample = AVAudioFramePosition(sampleRate * seconds)
        
        let lengthSeconds = Int(Float(duration!) - Float(seconds))
//        let lengthSeconds2 = Float(Int(duration!)) - Float(seconds)
        let lengthSeconds3 = Float(duration!) - Float(seconds)
        
        let lengthFrames = AVAudioFrameCount(Float(sampleRate) * Float(lengthSeconds))
//        let lengthFrames2 = AVAudioFrameCount(Float(sampleRate) * lengthSeconds2)
        let lengthFrames3 = AVAudioFrameCount(Float(sampleRate) * lengthSeconds3)
        
        let lengthFrames4 = lengthFrames3 - 5000
        
//        printVal("\nls1", value: String(lengthSeconds))
//        printVal("ls2", value: String(lengthSeconds2))
//        printVal("ls3", value: String(lengthSeconds3))
//
//        printVal("\nlf1", value: String(lengthFrames))
//        printVal("lf2", value: String(lengthFrames2))
//        printVal("lf3", value: String(lengthFrames3))
//        printVal("lf4", value: String(lengthFrames4))
        
        playerNode.stop()
        
        if lengthFrames > 100 {
            
//            playerNode.scheduleSegment(avFile!, startingFrame: startSample, frameCount: lengthFrames4, atTime: nil,completionHandler: {print("Done"); playerNode.stop()})
            playerNode.scheduleSegment(avFile!, startingFrame: startSample, frameCount: lengthFrames4, at: nil, completionHandler: {self.playerNode.stop()})
            
            startSecs = seconds
            startFrame = Double(startSample)
            
//            printVal("startFrame", value: String(startSample))
        }
        
        playerNode.play()
    }
    
    // Resets state at the end of playback
    func reset() {
        
        playerNode.stop()
        file = nil
        avFile = nil
    }
    
    // Checks if the last frame of the segment/file has been reached
    func eofReached() -> Bool {
        let lf = getLastFrame(false)
        return lf! >= Double(segmentFrames!)
    }
    
    // Computes the last frame played by the player
    func getLastFrame(_ pr: Bool) -> Double? {
        
        let nodeTime: AVAudioTime? = playerNode.lastRenderTime;
        
        if (nodeTime != nil) {
            
            let playerTime: AVAudioTime? = playerNode.playerTime(forNodeTime: nodeTime!)
            if (playerTime != nil ) {
                //                print("playerSampleRate=" + String(playerTime!.sampleRate))
//                let t1 = playerNode.lastRenderTime!.sampleTime
                let t2 = Double((playerTime?.sampleTime)!)
//                let s = Int(t2 / (playerTime?.sampleRate)!)
                
                return Double(t2)
            }
        }
        
        return nil
    }
    
    func printStats() {
        _ = getLastFrame(true)
    }
    
//    func printVal(_ key: String, value: AnyObject) {
//        print(key + "=" + String(value))
//    }
    
    func isPlaying() -> Bool {
        return playerNode.isPlaying
    }
    
    func remain() {
        
        let nodeTime: AVAudioTime  = playerNode.lastRenderTime!
//        let playerTime: AVAudioTime = playerNode.playerTime(forNodeTime: nodeTime)!
        let sampleRate = avFile!.processingFormat.sampleRate
//        let sr2 = playerTime.sampleRate
        
        let lengthFrames = Double(AVAudioFrameCount(avFile!.length - nodeTime.sampleTime)) - startFrame!
//        let lengthFrames = Double(avFile!.length) - startFrame!
        var rsecs = (Double(lengthFrames) / sampleRate)
        rsecs = round(rsecs)
        
        print("rF=" + String(lengthFrames) + ", rS=" + String(rsecs))
//                        print("sr=" + String(sampleRate))
//                print("sr2=" + String(sr2))
    }
}
