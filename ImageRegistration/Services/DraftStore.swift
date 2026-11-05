import Foundation
import Observation

/// Holds the application being edited and persists it as a draft on device,
/// so the user can leave the app and come back without losing their work.
@Observable
final class DraftStore {

    var application: ImageRegistrationApplication {
        didSet { save() }
    }

    private let fileURL: URL

    init(fileURL: URL = DraftStore.defaultURL) {
        self.fileURL = fileURL
        if let data = try? Data(contentsOf: fileURL),
           let saved = try? JSONDecoder().decode(ImageRegistrationApplication.self, from: data) {
            application = saved
        } else {
            application = ImageRegistrationApplication()
        }
    }

    func reset() {
        application = ImageRegistrationApplication()
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(application)
            try data.write(to: fileURL, options: [.atomic, .completeFileProtection])
        } catch {
            print("Failed to save draft: \(error)")
        }
    }

    static var defaultURL: URL {
        URL.documentsDirectory.appending(path: "image-registration-draft.json")
    }
}
