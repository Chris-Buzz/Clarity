import ManagedSettingsUI
import ManagedSettings
import UIKit

class ClarityShieldConfiguration: ShieldConfigurationDataSource {
    let sharedDefaults = UserDefaults(suiteName: "group.com.clarity-focus")

    private let bgColor = UIColor(red: 3/255, green: 3/255, blue: 3/255, alpha: 1)
    private let orangeColor = UIColor(red: 249/255, green: 115/255, blue: 22/255, alpha: 1)
    private let redColor = UIColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 1)

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        let budgetLocked = sharedDefaults?.bool(forKey: "budgetLocked") ?? false
        let focusActive = sharedDefaults?.bool(forKey: "focusSessionActive") ?? false

        if budgetLocked {
            return budgetLockedConfig()
        } else if focusActive {
            return focusSessionConfig()
        } else {
            return frictionConfig()
        }
    }

    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        configuration(shielding: application)
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        configuration(shielding: Application())
    }

    // MARK: - Budget Locked Shield

    /// Hard block — no functional secondary button
    private func budgetLockedConfig() -> ShieldConfiguration {
        ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterialDark,
            backgroundColor: bgColor,
            icon: nil,
            title: ShieldConfiguration.Label(
                text: "Daily Budget Reached",
                color: redColor
            ),
            subtitle: ShieldConfiguration.Label(
                text: "You've hit your limit. Take a real break.",
                color: UIColor.white.withAlphaComponent(0.6)
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Open Clarity",
                color: .white
            ),
            primaryButtonBackgroundColor: redColor,
            secondaryButtonLabel: ShieldConfiguration.Label(
                text: "Locked",
                color: UIColor.white.withAlphaComponent(0.2)
            )
        )
    }

    // MARK: - Focus Session Shield

    /// Hard block during voluntary focus sessions
    private func focusSessionConfig() -> ShieldConfiguration {
        ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterialDark,
            backgroundColor: bgColor,
            icon: nil,
            title: ShieldConfiguration.Label(
                text: "Focus Session Active",
                color: orangeColor
            ),
            subtitle: ShieldConfiguration.Label(
                text: "Stay the course. You've got this.",
                color: UIColor.white.withAlphaComponent(0.6)
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Open Clarity",
                color: .white
            ),
            primaryButtonBackgroundColor: orangeColor,
            secondaryButtonLabel: ShieldConfiguration.Label(
                text: "In Session",
                color: UIColor.white.withAlphaComponent(0.2)
            )
        )
    }

    // MARK: - Progressive Friction Shield

    /// Patience-based friction shield with functional "I Choose to Continue".
    /// Reads adaptive friction state to escalate messaging and color when
    /// the user has been bypassing repeatedly or doomscrolling.
    private func frictionConfig() -> ShieldConfiguration {
        let level = sharedDefaults?.integer(forKey: "currentFrictionLevel") ?? 1
        let intensityRaw = sharedDefaults?.integer(forKey: "adaptiveFriction.intensityRaw") ?? 0
        let bypassCount = sharedDefaults?.integer(forKey: "adaptiveFriction.dailyBypassCount") ?? 0
        let isEscalated = intensityRaw >= 2 // high or extreme

        let titleColor = isEscalated ? redColor : orangeColor
        let buttonBgColor = isEscalated ? redColor : orangeColor

        let subtitle = isEscalated
            ? escalatedSubtitle(level: level, bypasses: bypassCount)
            : subtitleForLevel(level)

        let secondaryText = bypassCount > 0
            ? "Continue (\(bypassCount) bypass\(bypassCount == 1 ? "" : "es") today)"
            : "I Choose to Continue"

        return ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterialDark,
            backgroundColor: bgColor,
            icon: nil,
            title: ShieldConfiguration.Label(
                text: titleForLevel(level),
                color: titleColor
            ),
            subtitle: ShieldConfiguration.Label(
                text: subtitle,
                color: UIColor.white.withAlphaComponent(0.6)
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Open Clarity",
                color: .white
            ),
            primaryButtonBackgroundColor: buttonBgColor,
            secondaryButtonLabel: ShieldConfiguration.Label(
                text: secondaryText,
                color: UIColor.white.withAlphaComponent(0.4)
            )
        )
    }

    /// More assertive subtitle when friction intensity is high or extreme
    private func escalatedSubtitle(level: Int, bypasses: Int) -> String {
        if bypasses >= 3 {
            return "You've bypassed friction \(bypasses) times today. Is this really what you want?"
        }
        switch level {
        case 1: return "You keep coming back. Is this intentional?"
        case 2: return "Rapid pickups detected. Breathe before continuing."
        case 3: return "Thresholds shortened because of your pattern."
        case 4: return "This is bypass #\(bypasses). Your patience is being tested."
        case 5: return "Friction is at maximum. Think carefully."
        default: return "Your usage pattern triggered heightened friction."
        }
    }

    private func titleForLevel(_ level: Int) -> String {
        switch level {
        case 1: return "Take a breath"
        case 2: return "Breathing gate"
        case 3: return "What are you opening this for?"
        case 4: return "Wait for it..."
        case 5: return "Scroll with intention"
        default: return "Take a breath"
        }
    }

    private func subtitleForLevel(_ level: Int) -> String {
        let opensToday = sharedDefaults?.integer(forKey: "countdown.opensToday") ?? 0
        switch level {
        case 1: return "You've been scrolling for a while."
        case 2: return "Breathe before you continue."
        case 3: return "Declare your intent."
        case 4: return "Open #\(opensToday + 1) today. Your patience is growing."
        case 5: return "Slow down. Read through before continuing."
        default: return "Be intentional with your time."
        }
    }
}
