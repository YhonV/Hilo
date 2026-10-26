"""Regression checks against LibraryViewModel with a service double."""
from pathlib import Path
import subprocess
import tempfile
root = Path(__file__).resolve().parents[1]
source = '''import SwiftUI
struct LibraryStatus { let name: String }
struct UserLibraryBook {
    let userBookId: UUID
    var statusId = 1
    var status = LibraryStatus(name: "reading")
    var currentPage: Int? = 0
    var startedAt: String? = nil
    var finishedAt: String? = nil
}
@MainActor final class LibraryService {
    static var fails = false
    static var rows: [UserLibraryBook] = []
    func getUsersBook(userId: UUID) async throws -> [UserLibraryBook] { Self.rows }
    func updateBookProgress(userBookId: UUID, currentPage: Int) async throws {
        if Self.fails { throw URLError(.notConnectedToInternet) }
    }
    func restartReading(userBookId: UUID) async throws -> UserLibraryBook {
        try await updateBookProgress(userBookId: userBookId, currentPage: 0)
        return UserLibraryBook(userBookId: userBookId)
    }
    func finishReading(userBookId: UUID) async throws -> UserLibraryBook {
        try await updateBookProgress(userBookId: userBookId, currentPage: 100)
        return UserLibraryBook(userBookId: userBookId, statusId: 2, currentPage: 100)
    }
    func getUserBook(userBookId: UUID) async throws -> UserLibraryBook { UserLibraryBook(userBookId: userBookId) }
    func removeBookFromLibrary(userBookId: UUID) async throws {}
}
'''
source += (root / 'Hilo/Features/Library/ViewModels/LibraryViewModel.swift').read_text()
source += '''
@main struct Checks {
    @MainActor static func main() async throws {
        let a = UserLibraryBook(userBookId: UUID())
        let b = UserLibraryBook(userBookId: UUID())
        let c = UserLibraryBook(userBookId: UUID())
        let vm = LibraryViewModel()
        vm.userBooks = [a, b, c]
        try await vm.updateBookProgres(userBookId: c.userBookId, currentPage: 50)
        assert(vm.userBooks.map(\\.userBookId) == [c.userBookId, a.userBookId, b.userBookId])
        assert(vm.userBooks.first?.currentPage == 50)
        try await vm.restartReading(userBookId: b.userBookId)
        assert(vm.userBooks.first?.userBookId == b.userBookId)
        try await vm.finishReading(userBookId: a.userBookId)
        assert(vm.userBooks.first?.userBookId == a.userBookId)
        assert(vm.userBooks.first?.status.name == "read")
        let order = vm.userBooks.map(\\.userBookId)
        LibraryService.fails = true
        do { try await vm.updateBookProgres(userBookId: c.userBookId, currentPage: 80); assertionFailure() } catch {}
        assert(vm.userBooks.map(\\.userBookId) == order)
        assert(vm.userBooks.last?.currentPage == 50)
        LibraryService.rows = vm.userBooks
        try await vm.getUserBooks(userId: UUID())
        assert(vm.userBooks.map(\\.userBookId) == order)
        print("PASS: progress/restart/finish move to front, preserve remaining order, failed writes do not reorder")
    }
}
'''
with tempfile.TemporaryDirectory(prefix='hilo-recency-') as tmp:
    path = Path(tmp)
    (path/'Checks.swift').write_text(source)
    subprocess.run(['xcrun','swiftc','-parse-as-library','-module-cache-path',str(path/'cache'),str(path/'Checks.swift'),'-o',str(path/'checks')],check=True)
    subprocess.run([str(path/'checks')],check=True)
