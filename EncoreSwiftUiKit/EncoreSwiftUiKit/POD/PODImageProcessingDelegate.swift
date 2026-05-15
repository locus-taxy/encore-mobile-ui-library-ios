import Foundation

public protocol PODImageProcessingDelegate: AnyObject {
    func podPipeline(didCompleteWithURL url: URL, itemId: String)
    func podPipeline(didFailWithError error: Error, itemId: String)
}
