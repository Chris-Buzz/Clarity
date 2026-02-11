import SwiftUI
import StoreKit

/// Full-screen paywall for Clarity Pro subscription.
struct SubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var service = SubscriptionService.shared
    @State private var isPurchasing = false
    @State private var errorMessage: String?

    private var monthlyProduct: Product? {
        service.products.first { $0.id == SubscriptionService.monthlyProductId }
    }

    private var yearlyProduct: Product? {
        service.products.first { $0.id == SubscriptionService.yearlyProductId }
    }

    var body: some View {
        ZStack {
            ClarityColors.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: ClaritySpacing.xl) {
                    // Header
                    VStack(spacing: ClaritySpacing.md) {
                        Text("Unlock Clarity")
                            .font(ClarityFonts.serif(size: 36))
                            .foregroundStyle(ClarityColors.textPrimary)

                        Text("Take back your time")
                            .font(ClarityFonts.sans(size: 16))
                            .foregroundStyle(ClarityColors.textSecondary)
                    }
                    .padding(.top, ClaritySpacing.xxl)

                    // Feature list
                    VStack(alignment: .leading, spacing: ClaritySpacing.md) {
                        featureRow(icon: "shield.fill", text: "App shielding & progressive friction")
                        featureRow(icon: "person.2.fill", text: "Prosocial challenges with verification")
                        featureRow(icon: "wifi", text: "WiFi-gated unlocking")
                        featureRow(icon: "chart.bar.fill", text: "Insights & connection stats")
                        featureRow(icon: "lock.fill", text: "100% private — everything on your phone")
                    }
                    .padding(.horizontal, ClaritySpacing.md)

                    // Pricing cards
                    HStack(spacing: ClaritySpacing.md) {
                        pricingCard(
                            title: "Monthly",
                            price: monthlyProduct?.displayPrice ?? "$4.99",
                            period: "per month",
                            isRecommended: false
                        ) {
                            Task { await purchase(monthlyProduct) }
                        }

                        pricingCard(
                            title: "Yearly",
                            price: yearlyProduct?.displayPrice ?? "$39.99",
                            period: "per year",
                            isRecommended: true,
                            badge: "Save 33%"
                        ) {
                            Task { await purchase(yearlyProduct) }
                        }
                    }
                    .padding(.horizontal, ClaritySpacing.md)

                    if let error = errorMessage {
                        Text(error)
                            .font(ClarityFonts.sans(size: 14))
                            .foregroundStyle(ClarityColors.danger)
                    }

                    // Restore purchases
                    Button {
                        Task { await service.restorePurchases() }
                    } label: {
                        Text("Restore Purchases")
                            .font(ClarityFonts.sans(size: 14))
                            .foregroundStyle(ClarityColors.textMuted)
                    }

                    // Terms & Privacy
                    HStack(spacing: ClaritySpacing.md) {
                        Text("Terms")
                            .font(ClarityFonts.sans(size: 12))
                            .foregroundStyle(ClarityColors.textMuted)

                        Text("Privacy")
                            .font(ClarityFonts.sans(size: 12))
                            .foregroundStyle(ClarityColors.textMuted)
                    }
                    .padding(.bottom, ClaritySpacing.xl)
                }
            }

            // Close button
            VStack {
                HStack {
                    Spacer()
                    Button {
                        HapticManager.light()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(ClarityColors.textMuted)
                            .frame(width: 32, height: 32)
                            .background(ClarityColors.surface)
                            .clipShape(Circle())
                    }
                    .padding(ClaritySpacing.md)
                }
                Spacer()
            }
        }
    }

    // MARK: - Components

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: ClaritySpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(ClarityColors.primary)
                .frame(width: 24)

            Text(text)
                .font(ClarityFonts.sans(size: 15))
                .foregroundStyle(ClarityColors.textPrimary)
        }
    }

    private func pricingCard(
        title: String,
        price: String,
        period: String,
        isRecommended: Bool,
        badge: String? = nil,
        action: @escaping () -> Void
    ) -> some View {
        VStack(spacing: ClaritySpacing.md) {
            if let badge {
                Text(badge)
                    .font(ClarityFonts.mono(size: 10))
                    .tracking(1)
                    .foregroundStyle(ClarityColors.primary)
                    .padding(.horizontal, ClaritySpacing.sm)
                    .padding(.vertical, ClaritySpacing.xs)
                    .background(ClarityColors.primaryMuted)
                    .clipShape(Capsule())
            }

            Text(title)
                .font(ClarityFonts.sansMedium(size: 16))
                .foregroundStyle(ClarityColors.textPrimary)

            Text(price)
                .font(ClarityFonts.serif(size: 28))
                .foregroundStyle(ClarityColors.textPrimary)

            Text(period)
                .font(ClarityFonts.sans(size: 13))
                .foregroundStyle(ClarityColors.textMuted)

            ClarityButton("Subscribe", variant: isRecommended ? .primary : .secondary, size: .md, fullWidth: true) {
                action()
            }
        }
        .padding(ClaritySpacing.md)
        .frame(maxWidth: .infinity)
        .background(isRecommended ? ClarityColors.primaryMuted : ClarityColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: ClarityRadius.xl))
        .overlay(
            RoundedRectangle(cornerRadius: ClarityRadius.xl)
                .stroke(isRecommended ? ClarityColors.primary : ClarityColors.borderSubtle, lineWidth: 1)
        )
    }

    // MARK: - Purchase

    private func purchase(_ product: Product?) async {
        guard let product, !isPurchasing else { return }
        isPurchasing = true
        errorMessage = nil

        do {
            if let _ = try await service.purchase(product) {
                HapticManager.success()
                dismiss()
            }
        } catch {
            HapticManager.error()
            errorMessage = "Purchase failed. Please try again."
        }

        isPurchasing = false
    }
}
