import Foundation

/// Recipe links are user-generated, become canonical + immutable, and are
/// then tapped by *other* users. `URL(string:)` happily accepts `tel:`,
/// `sms:`, `file:` and custom app schemes, so anything derived from user
/// input has to be scheme-checked before it's stored or opened.
enum SafeURL {
    static let maxLength = 2048

    /// A URL we're willing to open. Nil for anything that isn't plain http(s).
    static func openable(_ raw: String?) -> URL? {
        guard let raw, raw.count <= maxLength,
              let url = URL(string: raw.trimmingCharacters(in: .whitespacesAndNewlines)),
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              url.host?.isEmpty == false
        else { return nil }
        return url
    }

    /// Normalised for storage, or nil if it isn't a usable web link.
    /// Bare hosts ("tiktok.com/x") get https:// so honest typos still work.
    static func normalized(_ raw: String) -> String? {
        var s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty, s.count <= maxLength else { return nil }
        if !s.lowercased().hasPrefix("http://"), !s.lowercased().hasPrefix("https://") {
            // Only rescue things that actually look like a host, so "tel:+1"
            // and "javascript:…" stay rejected rather than becoming https:.
            guard s.range(of: #"^[\w-]+(\.[\w-]+)+(/.*)?$"#, options: .regularExpression) != nil
            else { return nil }
            s = "https://" + s
        }
        return openable(s)?.absoluteString
    }
}
