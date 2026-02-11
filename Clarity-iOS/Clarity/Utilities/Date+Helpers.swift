import Foundation

extension Date {

    /// Human-readable relative string, e.g. "2h ago", "just now", "3d ago".
    var relativeString: String {
        let seconds = Int(Date().timeIntervalSince(self))

        if seconds < 60 { return "just now" }

        let minutes = seconds / 60
        if minutes < 60 { return "\(minutes)m ago" }

        let hours = minutes / 60
        if hours < 24 { return "\(hours)h ago" }

        let days = hours / 24
        if days < 30 { return "\(days)d ago" }

        let months = days / 30
        if months < 12 { return "\(months)mo ago" }

        return "\(months / 12)y ago"
    }

    /// ISO-style day string: "2026-02-01".
    var dayString: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: self)
    }

    /// Whether this date falls on the current calendar day.
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    /// 24-hour time string: "14:30".
    var timeString: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: self)
    }
}
