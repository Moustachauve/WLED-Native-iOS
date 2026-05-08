import Testing
import CoreData
@testable import WLED

@MainActor
struct ReleaseServiceTests {

    /// Creates a fully isolated in-memory Core Data context for testing.
    private func makeInMemoryContext() -> NSManagedObjectContext {
        let container = PersistenceController(inMemory: true).container
        return container.viewContext
    }

    /// Inserts a Version entity into the given context.
    @discardableResult
    private func insertVersion(
        context: NSManagedObjectContext,
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

    /// Deletes all Version entities in the given context to ensure test isolation.
    private func deleteAllVersions(context: NSManagedObjectContext) throws {
        let fetchRequest = Version.fetchRequest()
        let versions = try context.fetch(fetchRequest)
        for version in versions {
            context.delete(version)
        }
        try context.save()
    }

    // MARK: - getLatestVersion tests

    @Test func latestVersionUsesSemVerNotPublishedDate() throws {
        let context = makeInMemoryContext()
        try deleteAllVersions(context: context)

        // v0.15.5 has a MORE RECENT publishedDate, but v0.16.0 is a higher semver
        insertVersion(context: context, tagName: "0.15.5",
                      publishedDate: Date(timeIntervalSince1970: 2_000_000))
        insertVersion(context: context, tagName: "0.16.0",
                      publishedDate: Date(timeIntervalSince1970: 1_000_000))

        try context.save()

        let service = ReleaseService(context: context)
        let latest = service.getLatestVersion(branch: .beta)

        #expect(latest?.tagName == "0.16.0")
    }

    @Test func latestStableVersionExcludesPrereleases() throws {
        let context = makeInMemoryContext()
        try deleteAllVersions(context: context)

        insertVersion(context: context, tagName: "0.15.0")
        insertVersion(context: context, tagName: "0.16.0-b1", isPrerelease: true)

        try context.save()

        let service = ReleaseService(context: context)
        let latest = service.getLatestVersion(branch: .stable)

        #expect(latest?.tagName == "0.15.0")
    }

    @Test func latestBetaVersionIncludesPrereleases() throws {
        let context = makeInMemoryContext()
        try deleteAllVersions(context: context)

        insertVersion(context: context, tagName: "0.15.0")
        insertVersion(context: context, tagName: "0.16.0-b1", isPrerelease: true)

        try context.save()

        let service = ReleaseService(context: context)
        let latest = service.getLatestVersion(branch: .beta)

        #expect(latest?.tagName == "0.16.0-b1")
    }

    @Test func latestVersionExcludesNightlyTag() throws {
        let context = makeInMemoryContext()
        try deleteAllVersions(context: context)

        insertVersion(context: context, tagName: "nightly",
                      publishedDate: Date(timeIntervalSince1970: 9_999_999))
        insertVersion(context: context, tagName: "0.15.0")

        try context.save()

        let service = ReleaseService(context: context)
        let latest = service.getLatestVersion(branch: .beta)

        #expect(latest?.tagName == "0.15.0")
    }

    @Test func latestVersionWithMultipleVersions() throws {
        let context = makeInMemoryContext()
        try deleteAllVersions(context: context)

        // Insert versions with intentionally misleading published dates
        insertVersion(context: context, tagName: "0.14.0",
                      publishedDate: Date(timeIntervalSince1970: 3_000_000))
        insertVersion(context: context, tagName: "0.15.5",
                      publishedDate: Date(timeIntervalSince1970: 4_000_000))
        insertVersion(context: context, tagName: "0.16.0",
                      publishedDate: Date(timeIntervalSince1970: 1_000_000))
        insertVersion(context: context, tagName: "0.14.1",
                      publishedDate: Date(timeIntervalSince1970: 5_000_000))

        try context.save()

        let service = ReleaseService(context: context)
        let latest = service.getLatestVersion(branch: .beta)

        #expect(latest?.tagName == "0.16.0")
    }

    @Test func latestVersionReturnsNilWhenEmpty() throws {
        let context = makeInMemoryContext()
        try deleteAllVersions(context: context)

        let service = ReleaseService(context: context)
        let latest = service.getLatestVersion(branch: .beta)

        #expect(latest == nil)
    }

    // MARK: - getNewerReleaseTag tests

    @Test func newerReleaseTagReturnsLatestWhenNewer() throws {
        let context = makeInMemoryContext()
        try deleteAllVersions(context: context)

        insertVersion(context: context, tagName: "0.16.0")

        try context.save()

        let service = ReleaseService(context: context)
        let result = service.getNewerReleaseTag(
            versionName: "0.15.0",
            branch: .stable,
            ignoreVersion: ""
        )

        #expect(result == "0.16.0")
    }

    @Test func newerReleaseTagReturnsEmptyWhenAlreadyLatest() throws {
        let context = makeInMemoryContext()
        try deleteAllVersions(context: context)

        insertVersion(context: context, tagName: "0.15.0")

        try context.save()

        let service = ReleaseService(context: context)
        let result = service.getNewerReleaseTag(
            versionName: "0.15.0",
            branch: .stable,
            ignoreVersion: ""
        )

        #expect(result == "")
    }

    @Test func newerReleaseTagRespectsIgnoreVersion() throws {
        let context = makeInMemoryContext()
        try deleteAllVersions(context: context)

        insertVersion(context: context, tagName: "0.16.0")

        try context.save()

        let service = ReleaseService(context: context)
        let result = service.getNewerReleaseTag(
            versionName: "0.15.0",
            branch: .stable,
            ignoreVersion: "0.16.0"
        )

        #expect(result == "")
    }
}
