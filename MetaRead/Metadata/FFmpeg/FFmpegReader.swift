import Cocoa

class FFMpegReader {
    
    static let instance: FFMpegReader = FFMpegReader()
    
    private var allParsers: [FFMpegMetadataParser] = []
    
    private let genericMetadata_ignoreKeys: [String] = ["title", "artist", "duration", "disc", "track", "album", "genre"]
    
    let commonFFMpegParser = CommonFFMpegMetadataParser()
    let id3Parser = ID3FFmpegParser.instance
    let wmParser = WMParser()
    let vorbisParser = VorbisCommentParser()
    let apeParser = ApeV2Parser()
    let defaultParser = DefaultFFMpegMetadataParser()
    
    private var wmFileParsers: [FFMpegMetadataParser] = []
    private var vorbisFileParsers: [FFMpegMetadataParser] = []
    private var apeFileParsers: [FFMpegMetadataParser] = []
    
    private var parsersByExt: [String: [FFMpegMetadataParser]] = [:]
    
    init() {
        
        allParsers = [commonFFMpegParser, id3Parser, vorbisParser, apeParser, wmParser, defaultParser]
        wmFileParsers = [commonFFMpegParser, wmParser, id3Parser, vorbisParser, apeParser, defaultParser]
        vorbisFileParsers = [commonFFMpegParser, vorbisParser, apeParser, id3Parser, wmParser, defaultParser]
        apeFileParsers = [commonFFMpegParser, apeParser, vorbisParser, id3Parser, wmParser, defaultParser]
        
        parsersByExt =
        [
            "wma": wmFileParsers,
            "flac": vorbisFileParsers,
            "dsf": vorbisFileParsers,
            "ogg": vorbisFileParsers,
            "opus": vorbisFileParsers,
            "ape": apeFileParsers,
            "mpc": apeFileParsers
        ]
    }
    
    private func cleanUp(_ string: String?) -> String? {
        
        if let theTrimmedString = string?.trim() {
            return theTrimmedString.isEmpty ? nil : theTrimmedString
        }
        
        return nil
    }
    
    func loadEssentialMetadata(for track: Track) {
        
        do {
            
            let fctx = try FFmpegFileContext(for: track.file)
            
            track.fileType = fctx.formatLongName.capitalizingFirstLetter()
            
            if let audioStream = fctx.bestAudioStream {
                track.audioFormat = audioStream.codecLongName
                track.hasAudioStream = true
            }
            
            if let vid = fctx.bestImageStream, !vid.hasPic {
                track.hasVideo = true
            } else if fctx.countStreams(ofType: AVMEDIA_TYPE_VIDEO) > 1 {
                track.hasVideo = true
            }
            
            let meta = FFmpegMappedMetadata(for: fctx)
            let allParsers = parsersByExt[meta.fileType] ?? self.allParsers
            allParsers.forEach {$0.mapTrack(meta)}
            
            let relevantParsers = allParsers.filter {$0.hasMetadataForTrack(meta)}
            
            track.title = cleanUp(relevantParsers.firstNonNilMappedValue {$0.getTitle(meta)})
            track.artist = cleanUp(relevantParsers.firstNonNilMappedValue {$0.getArtist(meta)})
            track.albumArtist = cleanUp(relevantParsers.firstNonNilMappedValue {$0.getAlbumArtist(meta)})
            track.album = cleanUp(relevantParsers.firstNonNilMappedValue {$0.getAlbum(meta)})
            track.genre = cleanUp(relevantParsers.firstNonNilMappedValue {$0.getGenre(meta)})
            track.year = relevantParsers.firstNonNilMappedValue {$0.getYear(meta)}
            track.bpm = relevantParsers.firstNonNilMappedValue {$0.getBPM(meta)}
            track.composer = cleanUp(relevantParsers.firstNonNilMappedValue {$0.getComposer(meta)})
            track.conductor = cleanUp(relevantParsers.firstNonNilMappedValue {$0.getConductor(meta)})
            track.performer = cleanUp(relevantParsers.firstNonNilMappedValue {$0.getPerformer(meta)})
            track.lyricist = cleanUp(relevantParsers.firstNonNilMappedValue {$0.getLyricist(meta)})
            
            track.isDRMProtected = relevantParsers.firstNonNilMappedValue {$0.isDRMProtected(meta)} ?? false
            
            var trackNumberAndTotal = relevantParsers.firstNonNilMappedValue {$0.getTrackNumber(meta)}
            if let trackNum = trackNumberAndTotal?.number, trackNumberAndTotal?.total == nil,
                let totalTracks = relevantParsers.firstNonNilMappedValue({$0.getTotalTracks(meta)}) {
                
                trackNumberAndTotal = (trackNum, totalTracks)
            }
            
            track.trackNumber = trackNumberAndTotal?.number
            track.totalTracks = trackNumberAndTotal?.total
            
            var discNumberAndTotal = relevantParsers.firstNonNilMappedValue {$0.getDiscNumber(meta)}
            if let discNum = discNumberAndTotal?.number, discNumberAndTotal?.total == nil,
                let totalDiscs = relevantParsers.firstNonNilMappedValue({$0.getTotalDiscs(meta)}) {
                
                discNumberAndTotal = (discNum, totalDiscs)
            }
            
            track.discNumber = discNumberAndTotal?.number
            track.totalDiscs = discNumberAndTotal?.total
            
            track.duration = meta.fileCtx.duration
            
            let accurate: Bool = track.duration > 0 && meta.fileCtx.estimatedDurationIsAccurate
//            print("\nEst. duration for \(track.defaultDisplayName) \(accurate ? "is" : "is not") accurate")
            track.durationIsAccurate = accurate
            
            if let imageStream = meta.imageStream,
                let imageData = imageStream.attachedPic.data,
                let image = NSImage(data: imageData) {
                
                track.art = image
            }
            
            if track.duration == 0 || meta.fileCtx.isRawAudioFile {
              
                if let durationFromMetadata = relevantParsers.firstNonNilMappedValue({$0.getDuration(meta)}), durationFromMetadata > 0 {
                    
                    track.duration = durationFromMetadata
                    track.durationIsAccurate = false
                    
                } else {
                    
                    // Use brute force to compute duration
                    DispatchQueue.global(qos: .userInitiated).async {
                        
                        if let duration = meta.fileCtx.bruteForceDuration {
                            
                            track.duration = duration
                            track.durationIsAccurate = true
                            
                            var notif = Notification(name: Notification.Name("trackUpdated"))
                            notif.userInfo = ["track": track]
                            
                            NotificationCenter.default.post(notif)
                        }
                    }
                }
            }
            
        } catch let err as FormatContextInitializationError {
            NSLog("Track.init(): Couldn't init FFmpeg file context for '\(track.file.lastPathComponent)': \(err.description)")
        } catch {
            NSLog("Track.init(): Couldn't init FFmpeg file context for '\(track.file.lastPathComponent)': \(error)")
        }
    }
    
    func computeDuration(for track: Track) {
        
//        var time: Double = 0
        
        do {
            
//            let st = CFAbsoluteTimeGetCurrent()
            
            let computedDuration = try FFmpegFileContext.computePreciseDuration(for: track.file)
            if computedDuration > 0 {
                
//                let oldDuration = track.duration
                track.duration = computedDuration
                
//                let end = CFAbsoluteTimeGetCurrent()
//                time = (end - st) * 1000
                
//                print("\nPrecise duration for \(track.file.lastPathComponent) is \(computedDuration) VS \(oldDuration)")
            }
            
        } catch {
        }
        
//        print("\nFFMPEG - Time to compute duration for \(track.defaultDisplayName): \(time) msec")
    }
    
    func loadPlaybackMetadata(for track: Track) {
        
        
    }
    
    func loadSecondaryMetadata(for track: Track) {
        
        
    }
}
