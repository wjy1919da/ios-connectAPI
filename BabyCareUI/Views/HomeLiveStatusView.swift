import SwiftUI

struct HomeLiveStatusView: View {
    private let activities: [TimelineActivity] = [
        TimelineActivity(icon: "bottle.fill", title: "Feeding", time: "5 mins ago", color: .feedingGreen),
        TimelineActivity(icon: "moon.stars.fill", title: "Sleeping", time: "30 mins ago", color: .sleepBlue),
        TimelineActivity(icon: "exclamationmark.bubble.fill", title: "Crying", time: "45 mins ago", color: .cryRed)
    ]

    var body: some View {
        ZStack {
            HomeBackground()
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 22) {
                    HomeTopBar()

                    StatusInsightCard()
                        .padding(.horizontal, 20)

                    RecentActivitySection(activities: activities)
                        .padding(.horizontal, 20)

                    Spacer(minLength: 16)
                }
                .padding(.top, 6)
            }
        }
    }
}

private struct HomeTopBar: View {
    var body: some View {
        HStack {
            Image(systemName: "house.fill")
                .foregroundColor(.softGray)
                .font(.title2)

            Spacer()

            Text("Home - Live Status")
                .font(.titleSerif)
                .foregroundColor(.primary)

            Spacer()

            Image(systemName: "gearshape.fill")
                .foregroundColor(.softGray)
                .font(.title2)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 6)
    }
}

private struct StatusInsightCard: View {
    var body: some View {
        VStack(spacing: 16) {
            BabyIllustration()

            Text("80% Likely hungry")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            HStack(spacing: 8) {
                HStack(spacing: 6) {
                    ForEach(0..<3) { _ in
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 10, height: 10)
                    }
                }

                Text("Medium Confidence")
                    .font(.bodyRounded)
                    .foregroundColor(.softGray)
            }

            Divider()
                .background(Color.dividerGray)

            Text("This is an AI-inferred belief, not a confirmed cause.")
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(.softGray)
                .multilineTextAlignment(.center)
        }
        .padding(22)
        .cardStyle()
    }
}

private struct BabyIllustration: View {
    var body: some View {
        Image("BabyIllustration")
            .resizable()
            .scaledToFit()
            .frame(width: 240, height: 140)
    }
}

private struct RecentActivitySection: View {
    let activities: [TimelineActivity]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.sectionTitle)
                .foregroundColor(.primary)

            Rectangle()
                .fill(Color.dividerGray)
                .frame(height: 1)

            VStack(spacing: 18) {
                ForEach(Array(activities.enumerated()), id: \.offset) { index, item in
                    TimelineRow(activity: item, isLast: index == activities.count - 1)
                }
            }
        }
    }
}

private struct TimelineRow: View {
    let activity: TimelineActivity
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 0) {
                Circle()
                    .fill(Color.dividerGray)
                    .frame(width: 10, height: 10)
                    .padding(.top, 4)

                Rectangle()
                    .fill(Color.dividerGray)
                    .frame(width: 2, height: isLast ? 0 : 44)
            }
            .frame(width: 12)

            HStack(spacing: 12) {
                IconBubble(systemName: activity.icon, color: activity.color)

                HStack(spacing: 6) {
                    Text(activity.title)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    Text(activity.time)
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundColor(.softGray)
                }
            }
        }
    }
}

private struct IconBubble: View {
    let systemName: String
    let color: Color

    var body: some View {
        Circle()
            .fill(color.opacity(0.18))
            .frame(width: 38, height: 38)
            .overlay(
                Image(systemName: systemName)
                    .foregroundColor(color)
            )
    }
}

private struct HomeBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.96, green: 0.98, blue: 1.0),
                    Color(red: 0.94, green: 0.97, blue: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            WaveShape(yOffset: 0.78, curve: 0.08)
                .fill(Color(red: 0.98, green: 0.95, blue: 0.92))
                .opacity(0.8)
                .ignoresSafeArea()

            WaveShape(yOffset: 0.86, curve: 0.06)
                .fill(Color(red: 0.90, green: 0.96, blue: 0.98))
                .opacity(0.9)
                .ignoresSafeArea()
        }
    }
}

private struct WaveShape: Shape {
    let yOffset: CGFloat
    let curve: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let startY = rect.height * yOffset
        let controlOffset = rect.height * curve

        path.move(to: CGPoint(x: 0, y: startY))
        path.addCurve(
            to: CGPoint(x: rect.width, y: startY),
            control1: CGPoint(x: rect.width * 0.25, y: startY - controlOffset),
            control2: CGPoint(x: rect.width * 0.75, y: startY + controlOffset)
        )
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        return path
    }
}

private struct TimelineActivity {
    let icon: String
    let title: String
    let time: String
    let color: Color
}

#Preview {
    HomeLiveStatusView()
}
