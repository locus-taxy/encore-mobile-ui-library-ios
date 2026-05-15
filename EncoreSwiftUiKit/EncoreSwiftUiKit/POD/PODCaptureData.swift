import CoreLocation
import Foundation

public struct PODCaptureData {
    public var itemId: String
    public var timestamp: Date
    public var location: CLLocationCoordinate2D?

    public init(itemId: String, timestamp: Date, location: CLLocationCoordinate2D? = nil) {
        self.itemId = itemId
        self.timestamp = timestamp
        self.location = location
    }
}
