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
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            let headSize = min(width, height) * 0.55

            ZStack {
                Capsule()
                    .fill(Color(red: 0.98, green: 0.92, blue: 0.88))
                    .frame(width: width * 0.9, height: height * 0.65)
                    .offset(y: height * 0.08)

                Circle()
                    .fill(Color(red: 0.98, green: 0.80, blue: 0.67))
                    .frame(width: headSize, height: headSize)
                    .overlay(
                        Circle()
                            .stroke(Color(red: 0.83, green: 0.62, blue: 0.52), lineWidth: 2)
                    )
                    .offset(x: -width * 0.06, y: -height * 0.05)

                Circle()
                    .fill(Color(red: 0.95, green: 0.73, blue: 0.60))
                    .frame(width: headSize * 0.28, height: headSize * 0.28)
                    .offset(x: -width * 0.2, y: -height * 0.02)

                Circle()
                    .fill(Color(red: 0.88, green: 0.50, blue: 0.36).opacity(0.35))
                    .frame(width: headSize * 0.22, height: headSize * 0.22)
                    .offset(x: -width * 0.15, y: height * 0.08)

                Circle()
                    .fill(Color(red: 0.88, green: 0.50, blue: 0.36).opacity(0.35))
                    .frame(width: headSize * 0.22, height: headSize * 0.22)
                    .offset(x: width * 0.05, y: height * 0.08)

                HStack(spacing: headSize * 0.18) {
                    Circle()
                        .fill(Color(red: 0.33, green: 0.24, blue: 0.22))
                        .frame(width: headSize * 0.08, height: headSize * 0.08)
                    Circle()
                        .fill(Color(red: 0.33, green: 0.24, blue: 0.22))
                        .frame(width: headSize * 0.08, height: headSize * 0.08)
                }
                .offset(x: -width * 0.04, y: -height * 0.03)

                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(red: 0.78, green: 0.35, blue: 0.32))
                    .frame(width: headSize * 0.14, height: headSize * 0.1)
                    .offset(x: -width * 0.02, y: height * 0.08)

                Path { path in
                    let center = CGPoint(x: width * 0.45, y: height * 0.15)
                    path.move(to: CGPoint(x: center.x - headSize * 0.12, y: center.y))
                    path.addQuadCurve(
                        to: CGPoint(x: center.x + headSize * 0.06, y: center.y + headSize * 0.04),
                        control: CGPoint(x: center.x - headSize * 0.02, y: center.y - headSize * 0.06)
                    )
                }
                .stroke(Color(red: 0.68, green: 0.47, blue: 0.40), lineWidth: 2.4)

                Path { path in
                    let center = CGPoint(x: width * 0.47, y: height * 0.07)
                    path.move(to: CGPoint(x: center.x - headSize * 0.02, y: center.y))
                    path.addQuadCurve(
                        to: CGPoint(x: center.x + headSize * 0.04, y: center.y + headSize * 0.05),
                        control: CGPoint(x: center.x + headSize * 0.04, y: center.y - headSize * 0.04)
                    )
                }
                .stroke(Color(red: 0.68, green: 0.47, blue: 0.40), lineWidth: 2.4)

                Path { path in
                    let center = CGPoint(x: width * 0.43, y: height * 0.08)
                    path.move(to: CGPoint(x: center.x - headSize * 0.04, y: center.y))
                    path.addQuadCurve(
                        to: CGPoint(x: center.x + headSize * 0.02, y: center.y + headSize * 0.05),
                        control: CGPoint(x: center.x + headSize * 0.02, y: center.y - headSize * 0.05)
                    )
                }
                .stroke(Color(red: 0.68, green: 0.47, blue: 0.40), lineWidth: 2.4)

                RoundedRectangle(cornerRadius: headSize * 0.18)
                    .fill(Color(red: 0.98, green: 0.80, blue: 0.67))
                    .frame(width: headSize * 0.45, height: headSize * 0.26)
                    .rotationEffect(.degrees(-18))
                    .offset(x: -width * 0.05, y: height * 0.2)

                Capsule()
                    .fill(Color(red: 0.99, green: 0.97, blue: 0.94))
                    .frame(width: headSize * 0.34, height: headSize * 0.46)
                    .overlay(
                        Capsule()
                            .stroke(Color(red: 0.73, green: 0.48, blue: 0.40), lineWidth: 2)
                    )
                    .offset(x: width * 0.2, y: height * 0.12)

                RoundedRectangle(cornerRadius: headSize * 0.08)
                    .fill(Color(red: 0.91, green: 0.46, blue: 0.40))
                    .frame(width: headSize * 0.28, height: headSize * 0.14)
                    .offset(x: width * 0.2, y: height * 0.0)

                Circle()
                    .fill(Color(red: 0.96, green: 0.76, blue: 0.70))
                    .frame(width: headSize * 0.16, height: headSize * 0.16)
                    .offset(x: width * 0.2, y: -height * 0.06)

                RoundedRectangle(cornerRadius: headSize * 0.04)
                    .fill(Color(red: 0.98, green: 0.92, blue: 0.80))
                    .frame(width: headSize * 0.22, height: headSize * 0.1)
                    .offset(x: width * 0.2, y: height * 0.13)

                QuestionBubble()
                    .frame(width: headSize * 0.4, height: headSize * 0.3)
                    .offset(x: width * 0.28, y: -height * 0.16)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 220, height: 130)
    }
}

private struct QuestionBubble: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.92, green: 0.48, blue: 0.42))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.7), lineWidth: 2)
                )

            Text("?")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            Triangle()
                .fill(Color(red: 0.92, green: 0.48, blue: 0.42))
                .frame(width: 16, height: 12)
                .offset(x: -18, y: 18)
        )
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
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
