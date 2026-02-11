import DeviceActivity
import SwiftUI

@available(iOS 16.0, *)
struct ClarityDeviceActivityReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .init(rawValue: "ClarityReport")

    let content: (String) -> ClarityReportView

    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> String {
        // Aggregate screen time data
        var totalMinutes = 0
        // Process data...
        let hours = totalMinutes / 60
        let mins = totalMinutes % 60
        return "\(hours)h \(mins)m"
    }
}

struct ClarityReportView: View {
    let totalTime: String

    init(_ totalTime: String) {
        self.totalTime = totalTime
    }

    var body: some View {
        VStack(spacing: 8) {
            Text("TODAY'S SCREEN TIME")
                .font(.custom("SpaceMono-Regular", size: 10))
                .tracking(3)
                .foregroundColor(.white.opacity(0.35))
            Text(totalTime)
                .font(.custom("PlayfairDisplay-Regular", size: 36))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(red: 20/255, green: 20/255, blue: 20/255))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
