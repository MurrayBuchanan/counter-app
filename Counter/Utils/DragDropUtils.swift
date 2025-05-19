import SwiftUI
import SwiftData

struct DragDropUtils {
    static func createItemProvider(for counter: Counter) -> NSItemProvider {
        let provider = NSItemProvider()
        provider.registerDataRepresentation(forTypeIdentifier: "public.text", visibility: .all) { completion in
            let idString = String(describing: counter.persistentModelID)
            let data = idString.data(using: .utf8)
            completion(data, nil)
            return nil
        }
        return provider
    }
    
    static func fetchCounter(from id: String, context: ModelContext) -> Counter? {
        let descriptor = FetchDescriptor<Counter>()
        return try? context.fetch(descriptor).first { String(describing: $0.persistentModelID) == id }
    }
} 