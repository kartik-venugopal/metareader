import Foundation

class Playlist {
    
    static let instance: Playlist = Playlist()
    
    var tracks: [Track] = []
    var sema: DispatchSemaphore = DispatchSemaphore(value: 1)
    
    // MARK: Accessor functions
    
    var size: Int {tracks.count}
    
    var duration: Double {
        tracks.reduce(0.0, {(totalSoFar: Double, track: Track) -> Double in totalSoFar + track.duration})
    }
    
    func trackAtIndex(_ index: Int) -> Track? {
        return tracks.item(at: index)
    }
    
    func indexOfTrack(_ track: Track) -> Int?  {
        return tracks.firstIndex(of: track)
    }
    
    var summary: (size: Int, totalDuration: Double) {(size, duration)}
    
    // MARK: Mutator functions ------------------------------------------------------------------------
    
    func enqueue(_ tracks: [Track]) -> ClosedRange<Int> {
        return self.tracks.addItems(tracks)
    }
    
    func clear() {
        tracks.removeAll()
    }
    
    var batch: [URL] = []
    var addedTracks: [Track] = []
    
    let trackAddQueue: OperationQueue = {
        
        let trackAddQueue = OperationQueue()
        trackAddQueue.maxConcurrentOperationCount = 12
        trackAddQueue.underlyingQueue = DispatchQueue.global(qos: .userInteractive)
        trackAddQueue.qualityOfService = .userInteractive
        
        return trackAddQueue
    }()
    
    func addFiles(_ files: [URL]) {
        
        DispatchQueue.global(qos: .userInteractive).async {
            
            self.addedTracks.removeAll()
            NSLog("Started adding ...\n")
            self.doAddFiles(files)
            
            if !self.batch.isEmpty {
                self.flushBatch()
            }
            
            NotificationCenter.default.post(name: Notification.Name("tracksAdded"), object: self)
            NSLog("Finished adding \(self.tracks.count) tracks ...\n")

            self.trackAddQueue.addOperations(self.addedTracks.compactMap {track in
                
                track.durationIsAccurate ? nil :
                
                BlockOperation {
                    track.isNativelySupported ? AVFReader.instance.computeDuration(for: track) : FFMpegReader.instance.computeDuration(for: track)
                }
                
            }, waitUntilFinished: true)
            
            NSLog("Finished computing duration for \(self.tracks.count) tracks ...\n")
        }
    }
    
    func doAddFiles(_ files: [URL]) {
        
        for file in files {
            
            if file.hasDirectoryPath {
                
                doAddFiles(expandDir(file))
                
            } else {
                
                let fileExt = file.pathExtension.lowercased()
                if allAudioExtensions.contains(fileExt) {
                    
                    batch.append(file)
                    
                    if batch.count == trackAddQueue.maxConcurrentOperationCount {
                        flushBatch()
                    }
                }
            }
        }
    }
    
    var addCount: Int = 0
    
    private func flushBatch() {
        
        let trks = batch.map {file in Track(file)}
        self.tracks.append(contentsOf: trks)
        self.addedTracks.append(contentsOf: trks)
        addCount += trks.count
        
        self.trackAddQueue.addOperations(trks.map {track in
            
            BlockOperation {
                
                track.isNativelySupported ? AVFReader.instance.loadEssentialMetadata(for: track) : FFMpegReader.instance.loadEssentialMetadata(for: track)
            }
            
        }, waitUntilFinished: true)
        
        if addCount >= 50 {
            
            NotificationCenter.default.post(name: Notification.Name("tracksAdded"), object: self)
            addCount = 0
        }
        
        batch.removeAll()
    }
    
    private func expandDir(_ dir: URL) -> [URL] {
        
        do {
            // Retrieve all files/subfolders within this folder
            return try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: [], options: FileManager.DirectoryEnumerationOptions())
            
        } catch let error as NSError {
            
            NSLog("Error retrieving contents of directory '%@': %@", dir.path, error.description)
            return []
        }
    }
}

func measureTime(_ task: () -> Void) -> Double {
    
    let startTime = CFAbsoluteTimeGetCurrent()
    task()
    return CFAbsoluteTimeGetCurrent() - startTime
}
