import ManagedSettingsUI
import ManagedSettings
import UIKit

class ClarityShieldConfiguration: ShieldConfigurationDataSource {
    let sharedDefaults = UserDefaults(suiteName: "group.com.clarity.focus")

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

    /// Standard friction shield with functional "I Choose to Continue"
    private func frictionConfig() -> ShieldConfiguration {
        let level = sharedDefaults?.integer(forKey: "currentFrictionLevel") ?? 1

        return ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterialDark,
            backgroundColor: bgColor,
            icon: nil,
            title: ShieldConfiguration.Label(
                text: titleForLevel(level),
                color: orangeColor
            ),
            subtitle: ShieldConfiguration.Label(
                text: subtitleForLevel(level),
                color: UIColor.white.withAlphaComponent(0.6)
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Open Clarity",
                color: .white
            ),
            primaryButtonBackgroundColor: orangeColor,
            secondaryButtonLabel: ShieldConfiguration.Label(
                text: "I Choose to Continue",
                color: UIColor.white.withAlphaComponent(0.4)
            )
        )
    }

    private func titleForLevel(_ level: Int) -> String {
        let prosocialEnabled = sharedDefaults?.bool(forKey: "prosocialEnabled") ?? true
        switch level {
        case 1: return "Take a breath"
        case 2: return prosocialEnabled ? "Someone would love to hear from you" : "Pause and breathe"
        case 3: return "What are you looking for?"
        case 4: return prosocialEnabled ? "Call someone who matters" : "Check in with yourself"
        case 5: return "Are you sure about this?"
        default: return "Take a breath"
        }
    }

    private func subtitleForLevel(_ level: Int) -> String {
        let prosocialEnabled = sharedDefaults?.bool(forKey: "prosocialEnabled") ?? true
        switch level {
        case 1: return "Is this intentional?"
        case 2: return prosocialEnabled ? "Send a quick text instead of scrolling" : "30 seconds of breathing can change your mind"
        case 3: return "Name what you're seeking — clarity starts here"
        case 4: return prosocialEnabled ? "A real conversation beats any feed" : "How are you really feeling right now?"
        case 5: return "You've spent significant time here today"
        default: return "Be intentional with your time"
        }
    }
}
