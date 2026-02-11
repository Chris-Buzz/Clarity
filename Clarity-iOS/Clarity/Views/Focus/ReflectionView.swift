import SwiftUI
import SwiftData

/// Post-session reflection screen — ratings, mood, notes, XP summary, badge unlocks.
struct ReflectionView: View {

    @Environment(AppState.self) private var appState
    @Environment(SessionManager.self) private var sessionManager
    @Environment(GamificationManager.self) private var gamification
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var users: [UserProfile]
    @Query(sort: \FocusSession.startTime, order: .reverse) private var allSessions: [FocusSession]

    @State private var rating: Int = 0
    @State private var note: String = ""
    @State private var moodValence: Double? = nil
    @State private var showBadgePopup = false
    @State private var newBadgeName: String = ""
    @State private var newBadgeDesc: String = ""
    @State private var badgeScale: CGFloat = 0.3

    private var session: FocusSession? { sessionManager.currentSession }
    private var user: UserProfile? { users.first }

    var body: some View {
        ZStack {
            ClarityColors.background.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: ClaritySpacing.xl) {
                    Spacer().frame(height: ClaritySpacing.xxl)

                    // MARK: - Header

                    VStack(spacing: ClaritySpacing.sm) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(ClarityColors.success)

                        Text("Session Complete")
                            .font(ClarityFonts.serif(size: 32))
                            .foregroundStyle(ClarityColors.textPrimary)
                    }

                    // MARK: - Stat Pills

                    HStack(spacing: ClaritySpacing.sm) {
                        statPill(
                            icon: "clock.fill",
                            value: "\(session?.actualDuration ?? 0)m",
                            tint: Color.blue
                        )
                        statPill(
                            icon: "star.fill",
                            value: "+\(session?.xpEarned ?? 0) XP",
                            tint: ClarityColors.primary
                        )
                        statPill(
                            icon: "shield.fill",
                            value: "\(session?.urgesResisted ?? 0)",
                            tint: ClarityColors.success
                        )
                    }

                    // MARK: - Mood Check-In

                    MoodCheckIn { valence, _ in
                        moodValence = valence
                    }

                    // MARK: - Star Rating

                    VStack(spacing: ClaritySpacing.sm) {
                        Text("Rate this session")
                            .font(ClarityFonts.sansMedium(size: 16))
                            .foregroundStyle(ClarityColors.textPrimary)

                        HStack(spacing: ClaritySpacing.md) {
                            ForEach(1...5, id: \.self) { star in
                                starButton(star)
                            }
                        }
                    }

                    // MARK: - Note Input

                    VStack(alignment: .leading, spacing: ClaritySpacing.sm) {
                        Text("How did it feel?")
                            .font(ClarityFonts.sansMedium(size: 16))
                            .foregroundStyle(ClarityColors.textPrimary)

                        TextField("", text: $note, prompt: Text("Jot down your thoughts...")
                            .foregroundStyle(ClarityColors.textMuted),
                            axis: .vertical
                        )
                        .font(ClarityFonts.sans(size: 15))
                        .foregroundStyle(ClarityColors.textPrimary)
                        .lineLimit(3...6)
                        .padding(ClaritySpacing.md)
                        .background(ClarityColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: ClarityRadius.lg))
                        .overlay(
                            RoundedRectangle(cornerRadius: ClarityRadius.lg)
                                .stroke(ClarityColors.border, lineWidth: 1)
                        )
                    }

                    // MARK: - Seal Button

                    ClarityButton("Seal This Session", variant: .primary, size: .lg, fullWidth: true) {
                        sealSession()
                    }
                    .shadow(color: ClarityColors.primaryGlow, radius: 12, y: 4)

                    Spacer().frame(height: ClaritySpacing.xl)
                }
                .padding(.horizontal, ClaritySpacing.lg)
            }

            // MARK: - Badge Popup Overlay

            if showBadgePopup {
                badgePopupView
            }
        }
    }

    // MARK: - Stat Pill

    private func statPill(icon: String, value: String, tint: Color) -> some View {
        HStack(spacing: ClaritySpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 12))
            Text(value)
                .font(ClarityFonts.sansSemiBold(size: 13))
        }
        .foregroundStyle(tint)
        .padding(.horizontal, ClaritySpacing.md)
        .padding(.vertical, ClaritySpacing.sm)
        .background(tint.opacity(0.12))
        .clipShape(Capsule())
    }

    // MARK: - Star Button

    private func starButton(_ star: Int) -> some View {
        let isFilled = star <= rating

        return Button {
            HapticManager.light()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                rating = star
            }
        } label: {
            Image(systemName: isFilled ? "star.fill" : "star")
                .font(.system(size: 28))
                .foregroundStyle(isFilled ? ClarityColors.primary : ClarityColors.textMuted)
                .scaleEffect(isFilled ? 1.0 : 0.9)
                .animation(.spring(response: 0.3, dampingFraction: 0.5), value: rating)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Badge Popup

    private var badgePopupView: some View {
        ZStack {
            ClarityColors.overlay.ignoresSafeArea()
                .onTapGesture {
                    withAnimation { showBadgePopup = false }
                }

            VStack(spacing: ClaritySpacing.md) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(ClarityColors.primary)

                Text(newBadgeName)
                    .font(ClarityFonts.serif(size: 24))
                    .foregroundStyle(ClarityColors.textPrimary)

                Text(newBadgeDesc)
                    .font(ClarityFonts.sans(size: 14))
                    .foregroundStyle(ClarityColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(ClaritySpacing.xl)
            .background(ClarityColors.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: ClarityRadius.xl))
            .overlay(
                RoundedRectangle(cornerRadius: ClarityRadius.xl)
                    .stroke(ClarityColors.borderAccent, lineWidth: 1)
            )
            .scaleEffect(badgeScale)
            .padding(.horizontal, ClaritySpacing.xxl)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                badgeScale = 1.0
            }
        }
    }

    // MARK: - Actions

    private func sealSession() {
        guard let session = session, let user = user else {
            closeReflection()
            return
        }

        // Save reflection data
        session.rating = rating > 0 ? rating : nil
        session.note = note.isEmpty ? nil : note
        session.moodAfter = moodValence

        // Award XP
        gamification.awardXP(amount: session.xpEarned, user: user, context: modelContext)

        // Update streak
        gamification.updateStreak(user: user)

        // Check badge unlocks
        let previousBadges = Set(user.unlockedBadges)
        gamification.checkBadgeUnlocks(user: user, sessions: allSessions, context: modelContext)

        // Detect newly unlocked badge
        let newBadges = Set(user.unlockedBadges).subtracting(previousBadges)
        if let firstNew = newBadges.first,
           let def = GamificationManager.badgeDefinitions.first(where: { $0.id == firstNew }) {
            newBadgeName = def.name
            newBadgeDesc = "Badge unlocked!"
            HapticManager.success()

            withAnimation {
                showBadgePopup = true
            }

            // Auto-dismiss badge after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation { showBadgePopup = false }
                closeReflection()
            }
            return
        }

        HapticManager.success()
        try? modelContext.save()
        closeReflection()
    }

    private func closeReflection() {
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            appState.isShowingReflection = false
        }
    }
}

#Preview {
    ReflectionView()
        .environment(AppState())
        .environment(SessionManager())
        .environment(GamificationManager())
        .modelContainer(for: [UserProfile.self, FocusSession.self], inMemory: true)
}
