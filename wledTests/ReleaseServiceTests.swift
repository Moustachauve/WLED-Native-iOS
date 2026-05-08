import Testing
import CoreData
@testable import WLED

// .serialized prevents the two test suite instances Xcode runs concurrently from
// interfering with each other via the shared in-memory Core Data store.
@Suite(.serialized)
@MainActor
struct ReleaseServiceTests {

    let context: NSManagedObjectContext
    let service: ReleaseService

    init() throws {
        // Use the shared in-memory store. @MainActor on the struct ensures all test
        // instances run serially on the main thread, so cleanup in init() is sufficient
        // to guarantee full isolation between tests.
        context = PersistenceController(inMemory: true).container.viewContext
        service = ReleaseService(context: context)

        // Clear any versions left by a previous test in this session.
        let fetchRequest = Version.fetchRequest()
        let existing = try context.fetch(fetchRequest)
        for version in existing {
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

    @Test func newerReleaseTagDetectsUpdateFromBetaToStable() throws {
        insertVersion(tagName: "0.16.0")
        try context.save()

        let result = service.getNewerReleaseTag(versionName: "0.16.0-b1", branch: .beta, ignoreVersion: "")
        #expect(result == "0.16.0")
    }
}
