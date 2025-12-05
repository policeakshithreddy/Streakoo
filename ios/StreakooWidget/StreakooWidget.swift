import WidgetKit
import SwiftUI

struct StreakooWidgetEntry: TimelineEntry {
    let date: Date
    let completedHabits: Int
    let totalHabits: Int
    let currentStreak: Int
    let motivation: String
}

struct StreakooDataProvider: TimelineProvider {
    let userDefaults = UserDefaults(suiteName: "group.com.streakoo.app")
    
    func placeholder(in context: Context) -> StreakooWidgetEntry {
        StreakooWidgetEntry(
            date: Date(),
            completedHabits: 3,
            totalHabits: 5,
            currentStreak: 7,
            motivation: "Keep going! 🔥"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (StreakooWidgetEntry) -> ()) {
        let entry = getEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StreakooWidgetEntry>) -> ()) {
        let entry = getEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func getEntry() -> StreakooWidgetEntry {
        let completed = userDefaults?.integer(forKey: "completed_habits") ?? 0
        let total = userDefaults?.integer(forKey: "total_habits") ?? 0
        let streak = userDefaults?.integer(forKey: "current_streak") ?? 0
        let motivation = userDefaults?.string(forKey: "motivation") ?? "Let's go! 🚀"
        
        return StreakooWidgetEntry(
            date: Date(),
            completedHabits: completed,
            totalHabits: total,
            currentStreak: streak,
            motivation: motivation
        )
    }
}

// MARK: - Small Widget View (1x1)
struct StreakooWidgetSmallView: View {
    var entry: StreakooWidgetEntry
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "1A1B2E"), Color(hex: "252742")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 4) {
                Text("🔥")
                    .font(.system(size: 28))
                Text("\(entry.currentStreak)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
        }
    }
}

// MARK: - Medium Widget View (2x2)
struct StreakooWidgetMediumView: View {
    var entry: StreakooWidgetEntry
    
    var progressValue: Double {
        guard entry.totalHabits > 0 else { return 0 }
        return Double(entry.completedHabits) / Double(entry.totalHabits)
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "1A1B2E"), Color(hex: "252742")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(alignment: .leading, spacing: 8) {
                // Header
                HStack {
                    Text("✨ Streakoo")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                    HStack(spacing: 4) {
                        Text(entry.currentStreak >= 7 ? "🔥" : "✨")
                        Text("\(entry.currentStreak)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color(hex: "FF6B35"), Color(hex: "F7931E")]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                
                Spacer()
                
                // Big count
                Text(entry.totalHabits == 0 ? "✨" : "\(entry.completedHabits)/\(entry.totalHabits)")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("habits today")
                    .font(.system(size: 12))
                    .foregroundColor(Color.white.opacity(0.6))
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.2))
                            .frame(height: 6)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color(hex: "58CC02"), Color(hex: "88E219")]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * CGFloat(progressValue), height: 6)
                    }
                }
                .frame(height: 6)
                
                Spacer()
                
                // Motivation
                Text(entry.motivation)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: "88E219"))
            }
            .padding(16)
        }
    }
}

// MARK: - Large Widget View (4x2)
struct StreakooWidgetLargeView: View {
    var entry: StreakooWidgetEntry
    
    var progressValue: Double {
        guard entry.totalHabits > 0 else { return 0 }
        return Double(entry.completedHabits) / Double(entry.totalHabits)
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "1A1B2E"), Color(hex: "252742")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            HStack(spacing: 16) {
                // Left: Stats
                VStack(alignment: .leading, spacing: 4) {
                    Text("✨ Streakoo")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(entry.totalHabits == 0 ? "✨" : "\(entry.completedHabits)/\(entry.totalHabits)")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("habits completed")
                        .font(.system(size: 11))
                        .foregroundColor(Color.white.opacity(0.6))
                    
                    Spacer()
                    
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.white.opacity(0.2))
                                .frame(height: 5)
                            
                            RoundedRectangle(cornerRadius: 3)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color(hex: "58CC02"), Color(hex: "88E219")]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * CGFloat(progressValue), height: 5)
                        }
                    }
                    .frame(height: 5)
                }
                
                Spacer()
                
                // Right: Streak & Motivation
                VStack(alignment: .trailing, spacing: 8) {
                    HStack(spacing: 4) {
                        Text(entry.currentStreak >= 7 ? "🔥" : "✨")
                        Text("\(entry.currentStreak)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color(hex: "FF6B35"), Color(hex: "F7931E")]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(14)
                    
                    Spacer()
                    
                    Text(entry.motivation)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(hex: "88E219"))
                        .multilineTextAlignment(.trailing)
                }
            }
            .padding(16)
        }
    }
}

// MARK: - Widget Configuration
struct StreakooWidget: Widget {
    let kind: String = "StreakooWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StreakooDataProvider()) { entry in
            if #available(iOS 17.0, *) {
                StreakooWidgetMediumView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                StreakooWidgetMediumView(entry: entry)
            }
        }
        .configurationDisplayName("Streakoo")
        .description("Track your daily habits progress")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct StreakooWidgetLarge: Widget {
    let kind: String = "StreakooWidgetLarge"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StreakooDataProvider()) { entry in
            if #available(iOS 17.0, *) {
                StreakooWidgetLargeView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                StreakooWidgetLargeView(entry: entry)
            }
        }
        .configurationDisplayName("Streakoo Stats")
        .description("Full habit stats and progress")
        .supportedFamilies([.systemLarge])
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Widget Bundle
@main
struct StreakooWidgetBundle: WidgetBundle {
    var body: some Widget {
        StreakooWidget()
        StreakooWidgetLarge()
    }
}
