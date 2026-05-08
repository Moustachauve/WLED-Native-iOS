import Testing
import CoreData
@testable import WLED

// .serialized prevents the two test suite instances Xcode runs concurrently from
// interfering with each other via the shared in-memory Core Data store.
@Suite(.serialized)
@MainActor
struct ReleaseServiceTests {

    // Hold a strong reference to prevent the container (and its in-memory store) from
    // being deallocated while a test is running.
    let container: NSPersistentContainer
    let context: NSManagedObjectContext
    let service: ReleaseService

    init() throws {
        // Build a fresh in-memory store using NSInMemoryStoreType so that:
        // 1. No on-disk store or migration is attempted (avoids CI environment issues).
        // 2. Each test suite instance gets a completely isolated store.
        let model = Self.makeModel()
        let newContainer = NSPersistentContainer(name: UUID().uuidString, managedObjectModel: model)
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        newContainer.persistentStoreDescriptions = [description]

        var loadError: Error?
        newContainer.loadPersistentStores { _, error in
            loadError = error
        }
        precondition(loadError == nil, "Failed to load in-memory store: \(String(describing: loadError))")

        container = newContainer
        context = newContainer.viewContext
        service = ReleaseService(context: context)
    }

    /// Builds a minimal NSManagedObjectModel containing only the Version entity,
    /// which is all ReleaseService needs. This avoids loading from disk entirely.
    private static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        let versionEntity = NSEntityDescription()
        versionEntity.name = "Version"
        versionEntity.managedObjectClassName = NSStringFromClass(Version.self)

        let tagNameAttr = NSAttributeDescription()
        tagNameAttr.name = "tagName"
        tagNameAttr.attributeType = .stringAttributeType

        let nameAttr = NSAttributeDescription()
        nameAttr.name = "name"
        nameAttr.attributeType = .stringAttributeType
        nameAttr.isOptional = true

        let descAttr = NSAttributeDescription()
        descAttr.name = "versionDescription"
        descAttr.attributeType = .stringAttributeType
        descAttr.isOptional = true

        let isPrereleaseAttr = NSAttributeDescription()
        isPrereleaseAttr.name = "isPrerelease"
        isPrereleaseAttr.attributeType = .booleanAttributeType
        isPrereleaseAttr.defaultValue = false

        let publishedDateAttr = NSAttributeDescription()
        publishedDateAttr.name = "publishedDate"
        publishedDateAttr.attributeType = .dateAttributeType
        publishedDateAttr.isOptional = true

        let htmlUrlAttr = NSAttributeDescription()
        htmlUrlAttr.name = "htmlUrl"
        htmlUrlAttr.attributeType = .stringAttributeType
        htmlUrlAttr.isOptional = true

        versionEntity.properties = [tagNameAttr, nameAttr, descAttr, isPrereleaseAttr, publishedDateAttr, htmlUrlAttr]
        model.entities = [versionEntity]

        return model
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

    @Test func newerReleaseTagDetectsUpdateFromBetaToStable() throws {
        insertVersion(tagName: "0.16.0")
        try context.save()

        let result = service.getNewerReleaseTag(versionName: "0.16.0-b1", branch: .beta, ignoreVersion: "")
        #expect(result == "0.16.0")
    }
}
