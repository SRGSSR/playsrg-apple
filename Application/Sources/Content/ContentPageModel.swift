import Foundation
import SRGDataProviderModel

class ContentPageModel: ObservableObject {
    enum Id {
        case video
        case audio(channel: RadioChannel)
        case live
        case topic(urn: String)
    }
    
    let id: Id
    
    init(id: Id) {
        self.id = id
    }
}
