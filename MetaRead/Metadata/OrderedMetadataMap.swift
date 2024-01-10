import Foundation

class OrderedMetadataMap {
    
    private var map: [String: String] = [:]
    private var array: [(String, String)] = []
    
    subscript(_ key: String) -> String? {
        
        get {map[key]}
        
        set {
            
            if let theValue = newValue {
                
                let valueExistsForKey: Bool = map[key] != nil
                
                map[key] = theValue
                
                if valueExistsForKey {
                    array.removeAll(where: {$0.0 == key})
                }
                
                array.append((key, theValue))
                
            } else {
                
                // newValue is nil, implying that any existing value should be removed for this key.
                _ = map.removeValue(forKey: key)
                array.removeAll(where: {$0.0 == key})
            }
        }
    }
    
    var keyValuePairs: [(key: String, value: String)] {
        array
    }
}
