import Foundation
import CoreData

class ReleaseService {
    
    func refreshVersions(context: NSManagedObjectContext) async {
        let allReleases = await WLEDRepoApi().getAllReleases()
        
        guard !allReleases.isEmpty else {
            print("Did not find any releases")
            return
        }
        
        context.performAndWait {
            // Delete existing versions first
            let fetchRequest = Version.fetchRequest()
            let versions = try? context.fetch(fetchRequest)
            print("Deleting \(versions?.count ?? 0) versions")
            for version in versions ?? [] {
                context.delete(version)
            }
            
            // Create new versions
            for release in allReleases {
                let version = createVersion(release: release, context: context)
                let assets = createAssetsForVersion(version: version, release: release, context: context)
                print("Added version \(version.tagName ?? "[unknown]") with \(assets.count) assets")
                do {
                    try context.save()
                } catch {
                    let nsError = error as NSError
                    fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
                }
            }
        }
    }
    
   
    
    private func createVersion(release: Release, context: NSManagedObjectContext) -> Version {
        let version = Version(context: context)
        version.tagName = release.tagName
        version.name = release.name
        version.versionDescription = release.body
        version.isPrerelease = release.prerelease
        version.htmlUrl = release.htmlUrl
        
        let dateFormatter = ISO8601DateFormatter()
        version.publishedDate = dateFormatter.date(from: release.publishedAt)
        
        return version
    }
    
    private func createAssetsForVersion(version: Version, release: Release, context: NSManagedObjectContext) -> [Asset] {
        var assets = [Asset]()
        for releaseAsset in release.assets {
            let asset = Asset(context: context)
            asset.version = version
            asset.versionTagName = release.tagName
            asset.name = releaseAsset.name
            asset.size = releaseAsset.size
            asset.downloadUrl = releaseAsset.browserDownloadUrl
            asset.assetId = releaseAsset.id
            assets.append(asset)
        }
        return assets
    }
}
