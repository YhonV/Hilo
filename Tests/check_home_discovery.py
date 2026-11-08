"""Exercise the actual ranking code without network or app credentials."""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
source = (root / 'Hilo/Features/Home/HomeDiscoveryViewModel.swift').read_text()
ranking = source.split('@MainActor')[0].replace('import SwiftUI', 'import Foundation')
stubs = '''
enum BookGenre: String, Hashable { case fantasy, mystery, horror }
struct Book { let externalId: String; let title: String; let cover: String }
'''
checks = '''
let library = [
    DiscoveryLibraryEntry(workID: "/works/OL1W", title: "El libro", genres: [.fantasy, .fantasy]),
    DiscoveryLibraryEntry(workID: "OL2W", title: "Otro", genres: [.mystery, .fantasy])
]
assert(HomeDiscoveryRanking.favoriteGenres(in: library) == [.fantasy, .mystery])
let books = [
    Book(externalId: "OL1W", title: "Different edition", cover: "cover"),
    Book(externalId: "OL3W", title: "EL LÍBRO", cover: "cover"),
    Book(externalId: "OL4W", title: "New", cover: "cover"),
    Book(externalId: "OL5W", title: "Missing", cover: "")
]
let result = HomeDiscoveryRanking.suggestions(from: [(.fantasy, books, false), (.horror, books, true)], excluding: library)
assert(result.count == 1 && result[0].book.externalId == "OL4W")
assert(HomeDiscoveryRanking.suggestions(from: [], excluding: []).isEmpty)
print("PASS: genre frequency, saved work/title exclusion, duplicate and missing-cover filtering")
'''
with tempfile.TemporaryDirectory(prefix='hilo-discovery-tests-') as folder:
    file = Path(folder) / 'main.swift'
    file.write_text(stubs + ranking + checks)
    subprocess.run(['xcrun', 'swift', '-module-cache-path', folder + '/cache', str(file)], check=True)
