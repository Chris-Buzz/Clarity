import SwiftUI
import PhotosUI

/// Camera-based challenge that uses AI verification to confirm the user
/// completed a physical action (going outside, drinking water, standing up).
struct AIVerifiedChallenge: View {

    enum VerificationType: String {
        case proveOutside  = "prove_outside"
        case proveWater    = "prove_water"
        case proveStanding = "prove_standing"

        var icon: String {
            switch self {
            case .proveOutside:  return "sun.max.fill"
            case .proveWater:    return "drop.fill"
            case .proveStanding: return "figure.stand"
            }
        }

        var iconColor: Color {
            switch self {
            case .proveOutside:  return .yellow
            case .proveWater:    return .blue
            case .proveStanding: return ClarityColors.success
            }
        }

        var title: String {
            switch self {
            case .proveOutside:  return "Prove you're outside"
            case .proveWater:    return "Show your water"
            case .proveStanding: return "Prove you're standing"
            }
        }

        var prompt: String {
            switch self {
            case .proveOutside:  return "Take a photo of your surroundings outside."
            case .proveWater:    return "Take a photo of your glass of water."
            case .proveStanding: return "Take a photo showing you are standing up."
            }
        }
    }

    let type: VerificationType
    let onComplete: () -> Void
    let onCancel: () -> Void

    /// AI verification service call. Replace with real implementation.
    var verifyPhoto: ((UIImage) async -> Bool)? = nil

    @State private var capturedImage: UIImage?
    @State private var verificationState: VerificationState = .idle
    @State private var showCamera = false

    private enum VerificationState {
        case idle
        case verifying
        case success
        case failure
    }

    var body: some View {
        switch verificationState {
        case .success:
            ChallengeSuccess(successMessage, onDone: onComplete)

        default:
            ChallengeTemplate(
                icon: type.icon,
                iconColor: type.iconColor,
                category: "AI Verified",
                title: type.title,
                onCancel: onCancel
            ) {
                Text(type.prompt)
                    .font(ClarityFonts.sans(size: 15))
                    .foregroundStyle(ClarityColors.textSecondary)
                    .multilineTextAlignment(.center)

                // Photo preview
                if let image = capturedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 160)
                        .clipShape(RoundedRectangle(cornerRadius: ClarityRadius.lg))
                        .overlay(
                            RoundedRectangle(cornerRadius: ClarityRadius.lg)
                                .stroke(ClarityColors.border, lineWidth: 1)
                        )
                }

                // State-dependent UI
                switch verificationState {
                case .idle:
                    ClarityButton("Open Camera", variant: .primary, fullWidth: true) {
                        showCamera = true
                    }

                case .verifying:
                    HStack(spacing: ClaritySpacing.sm) {
                        ProgressView()
                            .tint(ClarityColors.primary)
                        Text("Verifying with AI...")
                            .font(ClarityFonts.sans(size: 15))
                            .foregroundStyle(ClarityColors.textSecondary)
                    }

                case .failure:
                    VStack(spacing: ClaritySpacing.sm) {
                        Text("Verification failed. Try again.")
                            .font(ClarityFonts.sans(size: 14))
                            .foregroundStyle(ClarityColors.danger)

                        ClarityButton("Retake Photo", variant: .primary, fullWidth: true) {
                            showCamera = true
                        }
                    }

                case .success:
                    EmptyView() // Handled above
                }
            }
            .sheet(isPresented: $showCamera) {
                CameraPickerView { image in
                    capturedImage = image
                    verify(image: image)
                }
            }
        }
    }

    private var successMessage: String {
        switch type {
        case .proveOutside:  return "Fresh air confirmed"
        case .proveWater:    return "Hydration confirmed"
        case .proveStanding: return "On your feet"
        }
    }

    // MARK: - Verification

    private func verify(image: UIImage) {
        verificationState = .verifying

        Task {
            // Use injected verifier or auto-pass
            let passed: Bool
            if let verifyPhoto {
                passed = await verifyPhoto(image)
            } else {
                // Fallback: auto-pass after brief delay (no AI key configured)
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                passed = true
            }

            await MainActor.run {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    verificationState = passed ? .success : .failure
                }
                if passed {
                    HapticManager.success()
                } else {
                    HapticManager.error()
                }
            }
        }
    }
}

// MARK: - Camera Picker (UIImagePickerController wrapper)

/// Minimal camera picker. Uses the camera if available, otherwise falls back to photo library.
struct CameraPickerView: UIViewControllerRepresentable {

    let onCapture: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onCapture: onCapture) }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onCapture: (UIImage) -> Void

        init(onCapture: @escaping (UIImage) -> Void) {
            self.onCapture = onCapture
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                onCapture(image)
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

#Preview {
    ZStack {
        ClarityColors.background.ignoresSafeArea()
        AIVerifiedChallenge(type: .proveOutside, onComplete: {}, onCancel: {})
            .padding()
    }
}
