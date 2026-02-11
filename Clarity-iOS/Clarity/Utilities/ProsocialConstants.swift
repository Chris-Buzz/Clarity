import Foundation

// MARK: - XP Values

enum ProsocialXP {
    static let textSent = 15
    static let callCompleted = 25
    static let callAttempted = 10
    static let facetimeCompleted = 30
    static let longCall5min = 50
    static let autoVerifiedBonus = 5
}

// MARK: - Data Retention

enum DataRetention {
    static let sessionDays = 30
    static let challengeDays = 30
    static let connectionLogDays = 30
    static let snapshotDays = 90
}

// MARK: - Limits

enum ProsocialLimits {
    static let maxImportantContacts = 5
    static let maxTrustedNetworks = 3
    static let autoVerifyThreshold = 3
    static let callMinSeconds = 10
    static let textMinSeconds = 30
    static let callWatchTimeout = 120
}

// MARK: - Personality Responses

/// The "voice" of Clarity. Playful, warm, not preachy.
/// A friend who calls you out with a smirk, not a parent who lectures.
enum ProsocialResponses {

    static let verified = [
        "Nice! Connection made",
        "That's what your phone is actually for",
        "Real humans > reels",
        "See? That felt better than scrolling",
        "Your mom says hi back (probably)",
        "5 minutes with a real person beats 5 hours of scrolling",
    ]

    static let failed = [
        "...nice try",
        "That was suspiciously fast. Say more than 'hey'?",
        "We're watching. Actually do it!",
        "Your phone literally told us you didn't",
        "C'mon, they'd love to hear from you. For real this time.",
    ]

    static let failedCall = [
        "That wasn't long enough to be a real call",
        "Ring ring... hang up? That doesn't count",
        "Try letting it ring more than once",
    ]

    static let callAttempted = [
        "They didn't pick up, but you tried! That counts",
        "Voicemail counts — leave them something nice",
    ]

    static let alreadyConnected = [
        "You've been a great communicator today. Go ahead",
        "3+ real conversations? You're a social butterfly",
        "You've earned your scroll. Enjoy it guilt-free.",
    ]

    static let skipped = [
        "Okay. But the scroll hits different when you haven't talked to anyone all day.",
        "Skipped for now. We'll ask again later",
    ]

    static let textPrompts = [
        "Send {name} a quick text",
        "Tell {name} you're thinking of them",
        "Check in on {name} — it's been a while",
        "Ask {name} how their day's going",
    ]

    static let callPrompts = [
        "Call {name} — even just for a minute",
        "Give {name} a ring instead of scrolling",
        "A quick call to {name} beats an hour of reels",
    ]

    static func prompt(for type: String, contactName: String?) -> String {
        let name = contactName ?? "someone you care about"
        let templates: [String]
        switch type {
        case "callSomeone": templates = callPrompts
        default: templates = textPrompts
        }
        return (templates.randomElement() ?? "Connect with {name}").replacingOccurrences(of: "{name}", with: name)
    }
}

// MARK: - Prosocial Friction Descriptions

enum ProsocialFrictionDescriptions {
    static func title(for layer: Int, contactName: String?) -> String {
        let name = contactName ?? "someone"
        switch layer {
        case 1: return "\(name) would love to hear from you"
        case 2: return "Text \(name) instead"
        case 3: return "What are you looking for?"
        case 4: return "Call \(name) — for real"
        case 5: return "0 texts today. 58 min scrolling."
        default: return "Take a breath"
        }
    }

    static func subtitle(for layer: Int) -> String {
        switch layer {
        case 1: return "You've been on this app for 5 minutes"
        case 2: return "A real connection beats any feed"
        case 3: return "Or call someone instead of scrolling"
        case 4: return "Have a real conversation"
        case 5: return "Type 'I choose to keep scrolling' to continue. Or connect with someone."
        default: return "Be intentional"
        }
    }
}
