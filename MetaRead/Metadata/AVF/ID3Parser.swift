import Cocoa
import AVFoundation

class ID3Parser: AVAssetParser {
    
    let keySpace: AVMetadataKeySpace = .id3
    
    private let keys_duration: [String] = [ID3_V24Spec.key_duration, ID3_V22Spec.key_duration]
    
    private let keys_title: [String] = [ID3_V24Spec.key_title, ID3_V22Spec.key_title, ID3_V1Spec.key_title]
    
    private let keys_artist: [String] = [ID3_V24Spec.key_artist, ID3_V22Spec.key_artist, ID3_V1Spec.key_artist, ID3_V24Spec.key_originalArtist, ID3_V22Spec.key_originalArtist]
    private let keys_albumArtist: [String] = [ID3_V24Spec.key_albumArtist, ID3_V22Spec.key_albumArtist]
    private let keys_album: [String] = [ID3_V24Spec.key_album, ID3_V22Spec.key_album, ID3_V1Spec.key_album, ID3_V24Spec.key_originalAlbum, ID3_V22Spec.key_originalAlbum]
    private let keys_genre: [String] = [ID3_V24Spec.key_genre, ID3_V22Spec.key_genre, ID3_V1Spec.key_genre]
    private let keys_composer: [String] = [ID3_V24Spec.key_composer, ID3_V22Spec.key_composer]
    private let keys_conductor: [String] = [ID3_V24Spec.key_conductor, ID3_V22Spec.key_conductor]
    private let keys_lyricist: [String] = [ID3_V24Spec.key_lyricist, ID3_V22Spec.key_lyricist, ID3_V24Spec.key_originalLyricist, ID3_V22Spec.key_originalLyricist]
    
    private let keys_discNumber: [String] = [ID3_V24Spec.key_discNumber, ID3_V22Spec.key_discNumber]
    private let keys_trackNumber: [String] = [ID3_V24Spec.key_trackNumber, ID3_V22Spec.key_trackNumber, ID3_V1Spec.key_trackNumber]
    
    private let keys_year: [String] = [ID3_V24Spec.key_year, ID3_V22Spec.key_year, ID3_V24Spec.key_originalReleaseYear, ID3_V22Spec.key_originalReleaseYear, ID3_V24Spec.key_date, ID3_V22Spec.key_date]
    
    private let keys_bpm: [String] = [ID3_V24Spec.key_bpm, ID3_V22Spec.key_bpm]
    
    private let keys_lyrics: [String] = [ID3_V24Spec.key_lyrics, ID3_V22Spec.key_lyrics, ID3_V24Spec.key_syncLyrics, ID3_V22Spec.key_syncLyrics]
    private let keys_art: [String] = [ID3_V24Spec.key_art, ID3_V22Spec.key_art]
    
//    private let essentialFieldKeys: Set<String> = {
//        Set<String>().union(ID3_V1Spec.essentialFieldKeys).union(ID3_V22Spec.essentialFieldKeys).union(ID3_V24Spec.essentialFieldKeys)
//    }()
    
    func getDuration(_ meta: AVFMetadata) -> Double? {
        
        if let item = keys_duration.firstNonNilMappedValue({meta.id3[$0]}),
            let durationStr = item.stringValue {
            
            return ParserUtils.parseDuration(durationStr)
        }
        
        return nil
    }
    
    func getTitle(_ meta: AVFMetadata) -> String? {
        (keys_title.firstNonNilMappedValue {meta.id3[$0]})?.stringValue
    }
    
    func getArtist(_ meta: AVFMetadata) -> String? {
        (keys_artist.firstNonNilMappedValue {meta.id3[$0]})?.stringValue
    }
    
    func getAlbumArtist(_ meta: AVFMetadata) -> String? {
        (keys_albumArtist.firstNonNilMappedValue {meta.id3[$0]})?.stringValue
    }
    
    func getAlbum(_ meta: AVFMetadata) -> String? {
        (keys_album.firstNonNilMappedValue {meta.id3[$0]})?.stringValue
    }
    
    func getComposer(_ meta: AVFMetadata) -> String? {
        (keys_composer.firstNonNilMappedValue {meta.id3[$0]})?.stringValue
    }
    
    func getConductor(_ meta: AVFMetadata) -> String? {
        (keys_conductor.firstNonNilMappedValue {meta.id3[$0]})?.stringValue
    }
    
    func getLyricist(_ meta: AVFMetadata) -> String? {
        (keys_lyricist.firstNonNilMappedValue {meta.id3[$0]})?.stringValue
    }
    
    func getGenre(_ meta: AVFMetadata) -> String? {
        
        if let genreItem = keys_genre.firstNonNilMappedValue({meta.id3[$0]}) {
            return ParserUtils.getID3Genre(genreItem)
        }
        
        return nil
    }
    
    func getDiscNumber(_ meta: AVFMetadata) -> (number: Int?, total: Int?)? {
        
        if let item = keys_discNumber.firstNonNilMappedValue({meta.id3[$0]}) {
            return ParserUtils.parseDiscOrTrackNumber(item)
        }
    
        return nil
    }
    
    func getTrackNumber(_ meta: AVFMetadata) -> (number: Int?, total: Int?)? {
        
        if let item = keys_trackNumber.firstNonNilMappedValue({meta.id3[$0]}) {
            return ParserUtils.parseDiscOrTrackNumber(item)
        }
        
        return nil
    }

    func getArt(_ meta: AVFMetadata) -> NSImage? {
        
        if let item = keys_art.firstNonNilMappedValue({meta.id3[$0]}),
            let imgData = item.dataValue, let image = NSImage(data: imgData) {
            
            return image
        }
        
        return nil
    }
    
    func getLyrics(_ meta: AVFMetadata) -> String? {
        (keys_lyrics.firstNonNilMappedValue {meta.id3[$0]})?.stringValue
    }
    
    func getYear(_ meta: AVFMetadata) -> Int? {
        
        if let item = keys_year.firstNonNilMappedValue({meta.id3[$0]}) {
            return ParserUtils.parseYear(item)
        }
        
        return nil
    }
    
    func getBPM(_ meta: AVFMetadata) -> Int? {
        
        if let item = keys_bpm.firstNonNilMappedValue({meta.id3[$0]}) {
            return ParserUtils.parseBPM(item)
        }
        
        return nil
    }
}
