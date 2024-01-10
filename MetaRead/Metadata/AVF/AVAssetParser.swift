import Cocoa
import AVFoundation

protocol AVAssetParser {
    
    var keySpace: AVMetadataKeySpace {get}
    
    func getDuration(_ meta: AVFMetadata) -> Double?
    
    func getTitle(_ meta: AVFMetadata) -> String?
    
    func getArtist(_ meta: AVFMetadata) -> String?
    
    func getAlbumArtist(_ meta: AVFMetadata) -> String?
    
    func getAlbum(_ meta: AVFMetadata) -> String?
    
    func getComposer(_ meta: AVFMetadata) -> String?
    
    func getConductor(_ meta: AVFMetadata) -> String?
    
    func getPerformer(_ meta: AVFMetadata) -> String?
    
    func getLyricist(_ meta: AVFMetadata) -> String?
    
    func getGenre(_ meta: AVFMetadata) -> String?
    
    func getLyrics(_ meta: AVFMetadata) -> String?
    
    func getDiscNumber(_ meta: AVFMetadata) -> (number: Int?, total: Int?)?
    
    func getTrackNumber(_ meta: AVFMetadata) -> (number: Int?, total: Int?)?
    
    func getArt(_ meta: AVFMetadata) -> NSImage?
    
    func getYear(_ meta: AVFMetadata) -> Int?
    
    func getBPM(_ meta: AVFMetadata) -> Int?
    
//    func getGenericMetadata(_ meta: AVFMetadata) -> [String: String]
    
    // ----------- Chapter-related functions
    
//    func getChapterTitle(_ items: [AVMetadataItem]) -> String?
}

extension AVAssetParser {
    
    func getAlbumArtist(_ meta: AVFMetadata) -> String? {nil}
    
    func getDuration(_ meta: AVFMetadata) -> Double? {nil}
    
    func getDiscNumber(_ meta: AVFMetadata) -> (number: Int?, total: Int?)? {nil}
    
    func getTrackNumber(_ meta: AVFMetadata) -> (number: Int?, total: Int?)? {nil}
    
    func getLyrics(_ meta: AVFMetadata) -> String? {nil}
    
    func getComposer(_ meta: AVFMetadata) -> String? {nil}
    
    func getConductor(_ meta: AVFMetadata) -> String? {nil}
    
    func getPerformer(_ meta: AVFMetadata) -> String? {nil}
    
    func getLyricist(_ meta: AVFMetadata) -> String? {nil}
    
    func getYear(_ meta: AVFMetadata) -> Int? {nil}
    
    func getBPM(_ meta: AVFMetadata) -> Int? {nil}
}

class AVFMetadata {
    
    let file: URL
    let asset: AVURLAsset
    
    let items: [AVMetadataItem]
    
    var common: [String: AVMetadataItem] = [:]
    var id3: [String: AVMetadataItem] = [:]
    var iTunes: [String: AVMetadataItem] = [:]
    
    var keySpaces: [AVMetadataKeySpace] = []
    
    var genericMetadata: OrderedMetadataMap = OrderedMetadataMap()
    
    init(file: URL) {
        
        self.file = file
        self.asset = AVURLAsset(url: file, options: nil)
        self.items = asset.metadata
        
        for item in items {
            
            if let keySpace = item.keySpace, let key = item.keyAsString {
                
                switch keySpace {
                    
                case .id3:
                    
                    id3[key] = item
                    
                case .iTunes:
                    
                    iTunes[key] = item
                    
                case .common:
                    
                    common[key] = item
                    
                default:
                    
                    // iTunes long format
                    if keySpace.rawValue.lowercased() == ITunesSpec.longForm_keySpaceID {
                        iTunes[key] = item
                    }
                }
            }
        }
        
        if !common.isEmpty {
            keySpaces.append(.common)
        }
        
        let fileExt = file.pathExtension.lowercased()
        
        switch fileExt {
            
        case "m4a", "m4b", "aac", "alac":
            
            keySpaces.append(.iTunes)
            
            if !id3.isEmpty {
                keySpaces.append(.id3)
            }
            
        default:
            
            keySpaces.append(.id3)
            
            if !iTunes.isEmpty {
                keySpaces.append(.iTunes)
            }
        }
    }
}

extension AVMetadataItem {
    
    var commonKeyAsString: String? {
        return commonKey?.rawValue
    }
    
    var keyAsString: String? {
        
        if let key = self.key as? String {
            return key
        }
        
        if let id = self.identifier {
            
            // This is required for .iTunes keyspace items ("itsk").
            
            let tokens = id.rawValue.split(separator: "/")
            if tokens.count == 2 {
                
                let key = (tokens[1].replacingOccurrences(of: "%A9", with: "@").trim())
                return key.removingPercentEncoding ?? key
            }
        }
        
        return nil
    }
    
    var valueAsString: String? {

        if !StringUtils.isStringEmpty(self.stringValue) {
            return self.stringValue
        }
        
        if let number = self.numberValue {
            return String(describing: number)
        }
        
        if let data = self.dataValue {
            return String(data: data, encoding: .utf8)
        }
        
        if let date = self.dateValue {
            return String(describing: date)
        }
        
        return nil
    }
    
    var valueAsNumericalString: String {
        
        if !StringUtils.isStringEmpty(self.stringValue), let num = Int(self.stringValue!) {
            return String(describing: num)
        }
        
        if let number = self.numberValue {
            return String(describing: number)
        }
        
        if let data = self.dataValue, let num = Int(data.hexEncodedString(), radix: 16) {
            return String(describing: num)
        }
        
        return "0"
    }
}

extension Data {
    
    func hexEncodedString() -> String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
}
