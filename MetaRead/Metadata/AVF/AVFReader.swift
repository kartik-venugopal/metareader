import AVFoundation

class AVFReader {
    
    static let instance: AVFReader = AVFReader()
    
    let commonParser: CommonParser = CommonParser()
    let id3Parser: ID3Parser = ID3Parser()
    let iTunesParser: ITunesParser = ITunesParser()
    
    let parsersMap: [AVMetadataKeySpace: AVAssetParser]
    
    let avfFormatDescriptions: [FourCharCode: String] = [
        
        kAudioFormatLinearPCM: "Linear PCM",
        kAudioFormatAC3: "AC-3",
        kAudioFormatEnhancedAC3: "Enhanced AC-3",
        kAudioFormat60958AC3: "IEC 60958 compliant AC-3",
        
        kAudioFormatAppleIMA4: "Apple IMA 4:1 ADPCM",
        
        kAudioFormatMPEG4AAC: "MPEG-4 AAC",
        kAudioFormatMPEG4AAC_HE: "MPEG-4 HE AAC",
        kAudioFormatMPEG4AAC_HE_V2: "MPEG-4 HE AAC Version 2",
        kAudioFormatMPEG4AAC_LD: "MPEG-4 LD AAC",
        kAudioFormatMPEG4AAC_ELD: "MPEG-4 ELD AAC",
        kAudioFormatMPEG4AAC_ELD_SBR: "MPEG-4 ELD AAC w/ SBR extension",
        kAudioFormatMPEG4AAC_ELD_V2: "MPEG-4 ELD AAC Version 2",
        kAudioFormatMPEG4AAC_Spatial: "MPEG-4 Spatial AAC",
        
        kAudioFormatMPEG4CELP: "MPEG-4 CELP",
        kAudioFormatMPEG4HVXC: "MPEG-4 HVXC",
        kAudioFormatMPEG4TwinVQ: "MPEG-4 TwinVQ",
        
        kAudioFormatMACE3: "MACE 3:1",
        kAudioFormatMACE6: "MACE 6:1",
        
        kAudioFormatULaw: "µLaw 2:1",
        kAudioFormatALaw: "aLaw 2:1",
        
        kAudioFormatQDesign: "QDesign music",
        kAudioFormatQDesign2: "QDesign2 music",
        
        kAudioFormatQUALCOMM: "QUALCOMM PureVoice",
        
        kAudioFormatMPEGLayer1: "MPEG-1/2, Layer 1",
        kAudioFormatMPEGLayer2: "MPEG-1/2, Layer 2",
        kAudioFormatMPEGLayer3: "MPEG-1/2, Layer 3",

        kAudioFormatTimeCode: "IO Audio",
        
        kAudioFormatMIDIStream: "MIDI",
        
        kAudioFormatParameterValueStream: "Audio Unit Parameter Value Stream",
        
        kAudioFormatAppleLossless: "Apple Lossless",
        
        kAudioFormatMPEGD_USAC: "MPEG-D USAC",
        
        kAudioFormatAMR: "AMR Narrow Band",
        kAudioFormatAMR_WB: "AMR Wide Band",
        
        kAudioFormatAudible: "Audible",
        
        kAudioFormatiLBC: "iLBC",
        
        kAudioFormatDVIIntelIMA: "DVI/Intel IMA ADPCM",
        
        kAudioFormatMicrosoftGSM: "Microsoft GSM 6.10",
        
        kAudioFormatAES3: "AES3-2003",
        
        kAudioFormatFLAC: "FLAC",
        
        kAudioFormatOpus: "Opus"
    ]
    
    init() {
        parsersMap = [.common: commonParser, .id3: id3Parser, .iTunes: iTunesParser]
    }
    
    // File extension -> Kind of file description string
    static var kindOfFileCache: [String: String] = [:]
    
    static func kindOfFile(path: String, fileExt: String) -> String? {
        
        if let cachedValue = kindOfFileCache[fileExt] {
            return cachedValue
        }
        
        if let mditem = MDItemCreate(nil, path as CFString),
            let mdnames = MDItemCopyAttributeNames(mditem),
            let mdattrs = MDItemCopyAttributes(mditem, mdnames) as? [String: Any],
            let value = mdattrs[kMDItemKind as String] as? String {
            
            kindOfFileCache[fileExt] = value
            return value
        }
        
        return nil
    }
    
    private func cleanUp(_ string: String?) -> String? {
        
        if let theTrimmedString = string?.trim() {
            return theTrimmedString.isEmpty ? nil : theTrimmedString
        }
        
        return nil
    }
    
    func loadEssentialMetadata(for track: Track) {
        
        if let kindOfFile = Self.kindOfFile(path: track.file.path, fileExt: track.fileExt) {
            track.fileType = kindOfFile
        }
        
        let meta = AVFMetadata(file: track.file)
        
        if let assetTrack = meta.asset.tracks.first(where: {$0.mediaType == .audio}) {
            track.audioFormat = avfFormatDescriptions[assetTrack.format] ?? assetTrack.format4CharString
            track.hasAudioStream = true
        }
        
        if meta.asset.tracks.first(where: {$0.mediaType == .video}) != nil {
            track.hasVideo = true
        }
        
        let parsers = meta.keySpaces.compactMap {parsersMap[$0]}

        track.title = cleanUp(parsers.firstNonNilMappedValue {$0.getTitle(meta)})
        track.artist = cleanUp(parsers.firstNonNilMappedValue {$0.getArtist(meta)})
        track.albumArtist = cleanUp(parsers.firstNonNilMappedValue {$0.getAlbumArtist(meta)})
        track.album = cleanUp(parsers.firstNonNilMappedValue {$0.getAlbum(meta)})
        track.genre = cleanUp(parsers.firstNonNilMappedValue {$0.getGenre(meta)})
        
        track.composer = cleanUp(parsers.firstNonNilMappedValue {$0.getComposer(meta)})
        track.conductor = cleanUp(parsers.firstNonNilMappedValue {$0.getConductor(meta)})
        track.performer = cleanUp(parsers.firstNonNilMappedValue{$0.getPerformer(meta)})
        track.lyricist = cleanUp(parsers.firstNonNilMappedValue {$0.getLyricist(meta)})
        
        track.year = parsers.firstNonNilMappedValue {$0.getYear(meta)}
        track.bpm = parsers.firstNonNilMappedValue {$0.getBPM(meta)}
        
        let trackNum: (number: Int?, total: Int?)? = parsers.firstNonNilMappedValue {$0.getTrackNumber(meta)}
        track.trackNumber = trackNum?.number
        track.totalTracks = trackNum?.total
        
        let discNum: (number: Int?, total: Int?)? = parsers.firstNonNilMappedValue {$0.getDiscNumber(meta)}
        track.discNumber = discNum?.number
        track.totalDiscs = discNum?.total
        
        track.duration = meta.asset.duration.seconds
        track.durationIsAccurate = false
        
        track.art = parsers.firstNonNilMappedValue {$0.getArt(meta)}
        
        // TODO: Check if duration is 0 ... if so, look in metadata.
        if track.fileExt == "aac" {
            
            // Use brute force to compute duration
            DispatchQueue.global(qos: .userInitiated).async {
                
                do {
                    
                    let afile = try AVAudioFile(forReading: track.file)
                    track.duration = Double(afile.length) / afile.processingFormat.sampleRate
                    
                    var notif = Notification(name: Notification.Name("trackUpdated"))
                    notif.userInfo = ["track": track]
                    
                    NotificationCenter.default.post(notif)
                    
                } catch {
                    NSLog("\nProblem: \(error)")
                }
            }
        }
    }
    
    func computeDuration(for track: Track) {
        
//        var time: Double = 0
        
        do {
            
//            let st = CFAbsoluteTimeGetCurrent()
            
            let file = track.file
            let audioFile = try AVAudioFile(forReading: file)
            
            let audioFormat = audioFile.processingFormat
            let sampleRate = audioFormat.sampleRate
            
            let frameCount = audioFile.length
            let computedDuration = Double(frameCount) / sampleRate
            
            track.duration = computedDuration
            
//            let end = CFAbsoluteTimeGetCurrent()
//            time = (end - st) * 1000
            
//            print("\nPrecise duration for \(track.defaultDisplayName) is \(computedDuration), frameCount = \(frameCount)")
            
        } catch {
            
        }
        
//        print("\nTime to compute duration for \(track.defaultDisplayName): \(time) msec")
    }
    
//     init(for file: URL) throws {
//
//            self.file = file
//            self.audioFile = try AVAudioFile(forReading: file)
//
//            self.audioFormat = audioFile.processingFormat
//            self.sampleRate = audioFormat.sampleRate
//            self.frameCount = audioFile.length
//            self.computedDuration = Double(frameCount) / sampleRate
//        }
//
//        init(for file: URL) throws {
//
//            self.file = file
//            self.audioFile = try AVAudioFile(forReading: file)
//
//            self.audioFormat = audioFile.processingFormat
//            self.sampleRate = audioFormat.sampleRate
//
//            let asset = AVURLAsset(url: file, options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
//            self.computedDuration = asset.duration.seconds
//            self.frameCount = AVAudioFramePosition(computedDuration * sampleRate)
//        }
    
    // Chapters
    func loadPlaybackMetadata(for track: Track) {
        
        
    }
    
    // Lyrics + generic KV pairs
    func loadSecondaryMetadata(for track: Track) {
        
        let meta = AVFMetadata(file: track.file)
        let parsers = meta.keySpaces.compactMap {parsersMap[$0]}
        
        if let lyrics = meta.asset.lyrics {
            track.lyrics = lyrics
        } else {
            track.lyrics = parsers.firstNonNilMappedValue {$0.getLyrics(meta)}
        }
        
//        for parser in parsers {
//            
//            let map = parser.getGenericMetadata(meta)
//            for (key, value) in map {
//                track.genericMetadata[key] = value
//            }
//        }
    }
}

extension AVAssetTrack {
    
    var formatDescription: CMFormatDescription {
        self.formatDescriptions.first as! CMFormatDescription
    }
    
    var format: FourCharCode {
        CMFormatDescriptionGetMediaSubType(formatDescription)
    }
    
    var format4CharString: String {
        format.toString()
    }
}

extension FourCharCode {
    
    // Create a String representation of a FourCC
    func toString() -> String {
        
        let bytes: [CChar] = [
            CChar((self >> 24) & 0xff),
            CChar((self >> 16) & 0xff),
            CChar((self >> 8) & 0xff),
            CChar(self & 0xff),
            0
        ]
        let result = String(cString: bytes)
        let characterSet = CharacterSet.whitespaces
        return result.trimmingCharacters(in: characterSet)
    }
}

infix operator <> : DefaultPrecedence
extension AudioFormatFlags {
    
    static func <> (left: AudioFormatFlags, right: AudioFormatFlags) -> Bool {
        (left & right) != 0
    }
}

extension AudioStreamBasicDescription {
    
    var pcmFormatDescription: String {
        
        var formatStr: String = "PCM "
        
        let bitDepth: UInt32 = mBitsPerChannel
        let isFloat: Bool = mFormatFlags <> kAudioFormatFlagIsFloat
        let isSignedInt: Bool = mFormatFlags <> kAudioFormatFlagIsSignedInteger
        let isBigEndian: Bool = mFormatFlags <> kAudioFormatFlagIsBigEndian
        
        formatStr += isFloat ? "\(bitDepth)-bit float " : (isSignedInt ? "signed \(bitDepth)-bit " : "unsigned \(bitDepth)-bit ")
        
        formatStr += isBigEndian ? "(big-endian)" : "(little-endian)"
        
        return formatStr
    }
}

extension Array {
    
    func firstNonNilMappedValue<R>(_ mapFunc: (Element) -> R?) ->R? {

        for elm in self {

            if let result = mapFunc(elm) {
                return result
            }
        }

        return nil
    }
}
