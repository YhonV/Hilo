"""Exercise the actual avatar state machine with deterministic downloads, no network."""
from pathlib import Path
import subprocess
import tempfile
root = Path(__file__).resolve().parents[1]
source = '''import Foundation
import Observation
final class UIImage {
    let value: Int
    init(_ value: Int) { self.value = value }
    init?(data: Data) { self.value = 0 }
}
struct StorageService {
    func getAvatarURL(userId: UUID) throws -> URL { URL(string: "https://example.test/avatar.jpg")! }
}
'''
source += (root / 'Hilo/Features/Profile/ViewModels/ProfileAvatar.swift').read_text().replace('import SwiftUI', '')
source += '''
@main struct Checks {
    @MainActor static func main() async throws {
        let user = UUID(), other = UUID(), revision = UUID()
        var fails = true
        var calls = 0
        let avatar = ProfileAvatar { _ in
            calls += 1
            if fails { throw URLError(.notConnectedToInternet) }
            return UIImage(calls)
        }
        await avatar.load(userID: user, revision: revision)
        assert(avatar.image == nil && !avatar.isLoading)
        fails = false
        await avatar.load(userID: user, revision: revision)
        assert(avatar.image?.value == 2)
        await avatar.load(userID: user, revision: revision)
        assert(calls == 2, "Successful image should be cached")
        let replacement = UUID()
        fails = true
        await avatar.load(userID: user, revision: replacement)
        assert(avatar.image?.value == 2, "Failed refresh keeps last good image")
        fails = false
        await avatar.load(userID: user, revision: replacement)
        assert(avatar.image?.value == 4, "Failed refresh must be immediately retryable")
        fails = true
        await avatar.load(userID: other, revision: replacement)
        assert(avatar.image == nil, "Never show previous account's image")

        var pending: [CheckedContinuation<UIImage, Error>] = []
        let racing = ProfileAvatar { _ in
            try await withCheckedThrowingContinuation { pending.append($0) }
        }
        let first = Task { await racing.load(userID: user, revision: revision) }
        while pending.count < 1 { await Task.yield() }
        let second = Task { await racing.load(userID: other, revision: replacement) }
        while pending.count < 2 { await Task.yield() }
        pending[1].resume(returning: UIImage(20))
        await second.value
        pending[0].resume(returning: UIImage(10))
        await first.value
        assert(racing.image?.value == 20, "Late response cannot replace the latest account")

        let cancelled = Task { await racing.load(userID: other, revision: UUID()) }
        while pending.count < 3 { await Task.yield() }
        cancelled.cancel()
        pending[2].resume(returning: UIImage(30))
        await cancelled.value
        assert(racing.image?.value == 20 && !racing.isLoading)
        print("PASS: failure retry, success cache, upload invalidation, refresh failure, account isolation, stale response and cancellation")
    }
}
'''
with tempfile.TemporaryDirectory(prefix='hilo-avatar-') as directory:
    path = Path(directory)
    (path / 'Checks.swift').write_text(source)
    subprocess.run(['xcrun','swiftc','-parse-as-library','-module-cache-path',str(path/'cache'),str(path/'Checks.swift'),'-o',str(path/'checks')],check=True)
    subprocess.run([str(path/'checks')],check=True)
