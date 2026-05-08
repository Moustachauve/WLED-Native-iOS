import Testing
import CoreData
@testable import WLED

@MainActor
struct ReleaseServiceTests {

    let context: NSManagedObjectContext
    let service: ReleaseService

    init() throws {
        let bundle = Bundle(for: Version.self)
        guard let modelURL = bundle.url(forResource: "wled_native_data", withExtension: "momd"),
              let model = NSManagedObjectModel(contentsOf: modelURL) else {
            preconditionFailure("Failed to load Core Data model from bundle")
        }

        let container = NSPersistentContainer(name: UUID().uuidString, managedObjectModel: model)
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]

        var loadError: Error?
        container.loadPersistentStores { _, error in
            loadError = error
        }
        precondition(loadError == nil, "Failed to load in-memory store: \(loadError!)")
        
        context = container.viewContext
        service = ReleaseService(context: context)

        // Deletes all Version entities to ensure test isolation
        let fetchRequest = Version.fetchRequest()
        let versions = try context.fetch(fetchRequest)
        for version in versions {
            context.delete(version)
        }
        try context.save()
    }

    /// Inserts a Version entity into the context.
    @discardableResult
    private func insertVersion(
        tagName: String,
        isPrerelease: Bool = false,
        publishedDate: Date = Date()
    ) -> Version {
        let version = Version(context: context)
        version.tagName = tagName
        version.name = "v\(tagName)"
        version.versionDescription = ""
        version.isPrerelease = isPrerelease
        version.publishedDate = publishedDate
        return version
    }

    // MARK: - getLatestVersion tests

    @Test func latestVersionUsesSemVerNotPublishedDate() throws {
        // v0.15.5 has a MORE RECENT publishedDate, but v0.16.0 is a higher semver
        insertVersion(tagName: "0.15.5", publishedDate: Date(timeIntervalSince1970: 2_000_000))
        insertVersion(tagName: "0.16.0", publishedDate: Date(timeIntervalSince1970: 1_000_000))

        try context.save()

        let latest = service.getLatestVersion(branch: .beta)
        #expect(latest?.tagName == "0.16.0")
    }

    @Test func latestStableVersionExcludesPrereleases() throws {
        insertVersion(tagName: "0.15.0")
        insertVersion(tagName: "0.16.0-b1", isPrerelease: true)

        try context.save()

        let latest = service.getLatestVersion(branch: .stable)
        #expect(latest?.tagName == "0.15.0")
    }

    @Test func latestBetaVersionIncludesPrereleases() throws {
        insertVersion(tagName: "0.15.0")
        insertVersion(tagName: "0.16.0-b1", isPrerelease: true)

        try context.save()

        let latest = service.getLatestVersion(branch: .beta)
        #expect(latest?.tagName == "0.16.0-b1")
    }

    @Test func latestVersionExcludesNightlyTag() throws {
        insertVersion(tagName: "nightly", publishedDate: Date(timeIntervalSince1970: 9_999_999))
        insertVersion(tagName: "0.15.0")

        try context.save()

        let latest = service.getLatestVersion(branch: .beta)
        #expect(latest?.tagName == "0.15.0")
    }

    @Test func latestVersionWithMultipleVersions() throws {
        // Insert versions with intentionally misleading published dates
        insertVersion(tagName: "0.14.0", publishedDate: Date(timeIntervalSince1970: 3_000_000))
        insertVersion(tagName: "0.15.5", publishedDate: Date(timeIntervalSince1970: 4_000_000))
        insertVersion(tagName: "0.16.0", publishedDate: Date(timeIntervalSince1970: 1_000_000))
        insertVersion(tagName: "0.14.1", publishedDate: Date(timeIntervalSince1970: 5_000_000))

        try context.save()

        let latest = service.getLatestVersion(branch: .beta)
        #expect(latest?.tagName == "0.16.0")
    }

    @Test func latestVersionReturnsNilWhenEmpty() throws {
        let latest = service.getLatestVersion(branch: .beta)
        #expect(latest == nil)
    }

    // MARK: - getNewerReleaseTag tests

    @Test func newerReleaseTagReturnsLatestWhenNewer() throws {
        insertVersion(tagName: "0.16.0")
        try context.save()

        let result = service.getNewerReleaseTag(versionName: "0.15.0", branch: .stable, ignoreVersion: "")
        #expect(result == "0.16.0")
    }

    @Test func newerReleaseTagReturnsEmptyWhenAlreadyLatest() throws {
        insertVersion(tagName: "0.15.0")
        try context.save()

        let result = service.getNewerReleaseTag(versionName: "0.15.0", branch: .stable, ignoreVersion: "")
        #expect(result == "")
    }

    @Test func newerReleaseTagRespectsIgnoreVersion() throws {
        insertVersion(tagName: "0.16.0")
        try context.save()

        let result = service.getNewerReleaseTag(versionName: "0.15.0", branch: .stable, ignoreVersion: "0.16.0")
        #expect(result == "")
    }
}
