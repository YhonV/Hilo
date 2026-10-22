"""Check quote decoding for joined profile data and plain insert/update responses."""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
source = (root / 'Hilo/Models/Quote.swift').read_text()
source += r'''
@main struct Checks {
    static func main() throws {
        let base: [String: Any] = [
            "id": UUID().uuidString, "user_book_id": UUID().uuidString,
            "content": "Quote", "page_number": 12, "source_type": "manual",
            "created_at": "2026-10-22T12:00:00Z", "updated_at": "2026-10-22T12:00:00Z"
        ]
        func decode(_ object: [String: Any]) throws -> Quote {
            try JSONDecoder().decode(Quote.self, from: JSONSerialization.data(withJSONObject: object))
        }
        assert(try decode(base).bookContext == nil)
        var joined = base
        joined["user_book"] = ["books": ["title": "Book title"],
                               "book_editions": ["cover_url": "https://example.com/cover.jpg", "number_of_pages": 250]]
        let quote = try decode(joined)
        assert(quote.bookContext?.book?.title == "Book title")
        assert(quote.bookContext?.edition?.numberOfPages == 250)
        assert(quote.pageNumber == 12)
        joined["user_book"] = ["books": ["title": "Book without cover"], "book_editions": NSNull()]
        let noCover = try decode(joined)
        assert(noCover.bookContext?.book?.title == "Book without cover")
        assert(noCover.bookContext?.edition == nil)
        joined["user_book"] = NSNull()
        let missing = try decode(joined)
        assert(missing.bookContext == nil)
        print("PASS: plain quotes, joined book/edition, missing cover and unavailable book relation")
    }
}
'''
source = source.replace('assert(try decode(base).bookContext == nil)', 'let plain = try decode(base)\n        assert(plain.bookContext == nil)')
with tempfile.TemporaryDirectory(prefix='hilo-quotes-') as tmp:
    path = Path(tmp)
    (path / 'Checks.swift').write_text(source)
    subprocess.run(['xcrun', 'swiftc', '-parse-as-library', '-module-cache-path', str(path / 'cache'), str(path / 'Checks.swift'), '-o', str(path / 'checks')], check=True)
    subprocess.run([str(path / 'checks')], check=True)
