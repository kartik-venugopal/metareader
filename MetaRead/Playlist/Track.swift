import Cocoa
import AVFoundation

let nativeAudioExtensions: Set<String> = ["aac", "adts", "aif", "aiff", "aifc", "caf", "mp3", "m4a", "m4b", "m4r", "snd", "au", "sd2", "wav", "mp2"]

let nonNativeAudioExtensions: Set<String> = ["8svx", "paf", "flac", "oga", "opus", "wma", "dsf", "dsd", "dff", "mpc", "ape", "wv", "dts", "mka", "ogg", "ac3", "amr", "aa3", "spx", "str", "acm", "adp", "dtk", "ads", "ss2", "adx", "aea", "afc", "aix", "al", "mac", "aptx", "aptxhd"]

let allAudioExtensions: Set<String> = {nativeAudioExtensions.union(nonNativeAudioExtensions)}()

class Track: Hashable {
    
    let file: URL
    let fileExt: String
    
    let isNativelySupported: Bool
    
    var defaultDisplayName: String
    
    var duration: Double = 0
    var durationIsAccurate: Bool = false

    var title: String?
    var artist: String?
    
    var artistTitleString: String? {
        
        if let theArtist = artist, let theTitle = title {
            return "\(theArtist) - \(theTitle)"
        }
        
        return title
    }
    
    var fileType: String
    var audioFormat: String!
    
    var hasAudioStream: Bool = false
    var hasVideo: Bool = false
    
    var albumArtist: String?
    
    var album: String?
    var genre: String?
    
    var composer: String?
    var conductor: String?
    var performer: String?
    var lyricist: String?
    
    var art: NSImage?
    
    var trackNumber: Int?
    var totalTracks: Int?
    
    var isDRMProtected: Bool = false
    
    var displayedTrackNum: String? {
        
        let trackNum = self.trackNumber
        let trackTotal = self.totalTracks
        
        // If both the track number and total tracks tags are present, return a formatted string with both tags.
        if let theTrackNum = trackNum, let theTrackTotal = trackTotal {
            return "\(theTrackNum) / \(theTrackTotal)"
            
        } else {
            
            // No total tracks tag present, return the track number tag if present.
            return trackNum == nil ? nil : "\(trackNum!)"
        }
    }
    
    var discNumber: Int?
    var totalDiscs: Int?
    
    var displayedDiscNum: String? {
        
        let discNum = self.discNumber
        let discTotal = self.totalDiscs
        
        // If both the disc number and total discs tags are present, return a formatted string with both tags.
        if let theDiscNum = discNum, let theDiscTotal = discTotal {
            return "\(theDiscNum) / \(theDiscTotal)"
            
        } else {
            
            // No total discs tag present, return the disc number tag if present.
            return discNum == nil ? nil : "\(discNum!)"
        }
    }
    
    var year: Int?
    
    var bpm: Int?
    
    var lyrics: String?
    
    // Generic metadata
    var genericMetadata: OrderedMetadataMap = OrderedMetadataMap()
    
    init(_ file: URL) {
        
        self.file = file
        self.fileExt = file.pathExtension.lowercased()
        self.fileType = file.pathExtension.uppercased()
        
        self.defaultDisplayName = file.deletingPathExtension().lastPathComponent
        
        self.isNativelySupported = nativeAudioExtensions.contains(fileExt)
    }
    
    static func == (lhs: Track, rhs: Track) -> Bool {
        return lhs.file == rhs.file
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(file.path)
    }
}
