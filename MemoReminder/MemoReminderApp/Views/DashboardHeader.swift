import SwiftUI

struct DashboardHeader: View {
    let activeCount: Int
    let todayCount: Int
    let overdueCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("把事情稳稳接住")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.primary)

                Text("写下要做的事，选好时间，剩下的交给提醒。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                SummaryMetric(title: "待提醒", value: activeCount, color: .teal, icon: "bell.fill")
                SummaryMetric(title: "今天", value: todayCount, color: .orange, icon: "calendar")
                SummaryMetric(title: "逾期", value: overdueCount, color: .red, icon: "exclamationmark.triangle.fill")
            }
        }
    }
}

private struct SummaryMetric: View {
    let title: String
    let value: Int
    let color: Color
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.callout.weight(.semibold))
                .foregroundStyle(color)

            Text("\(value)")
                .font(.title2.weight(.bold))
                .monospacedDigit()

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.white.opacity(0.7), lineWidth: 1)
        }
    }
}

#Preview {
    DashboardHeader(activeCount: 3, todayCount: 2, overdueCount: 1)
        .padding()
}

