import SwiftUI
import Charts

struct EmotionTrackingView: View {
    @EnvironmentObject var moodManager: MoodManager
    @State private var selectedPeriod: TimePeriod = .week
    
    enum TimePeriod: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case threeMonths = "3 Months"
        case year = "Year"
        
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .threeMonths: return 90
            case .year: return 365
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Emotion Tracking")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Your emotional journey over time")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                
                // Period Selector
                Picker("Period", selection: $selectedPeriod) {
                    ForEach(TimePeriod.allCases, id: \.self) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // Current Mood Summary
                if let latestMood = moodManager.moodEntries.last {
                    VStack(spacing: 12) {
                        Text("Current Mood")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack(spacing: 16) {
                            Text(latestMood.moodEmoji)
                                .font(.system(size: 60))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(latestMood.moodLabel)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                
                                Text(latestMood.createdAt, style: .relative)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                if let note = latestMood.note, !note.isEmpty {
                                    Text("\"\(note)\"")
                                        .font(.subheadline)
                                        .italic()
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                }
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(16)
                    }
                    .padding(.horizontal)
                }
                
                // Mood Trend Chart
                if !periodMoodData.isEmpty {
                    VStack(spacing: 12) {
                        Text("Mood Trend")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Chart {
                            ForEach(periodMoodData, id: \.date) { data in
                                LineMark(
                                    x: .value("Date", data.date),
                                    y: .value("Mood", data.mood)
                                )
                                .foregroundStyle(Color.purple.gradient)
                                .interpolationMethod(.catmullRom)
                                
                                PointMark(
                                    x: .value("Date", data.date),
                                    y: .value("Mood", data.mood)
                                )
                                .foregroundStyle(Color.purple)
                                .symbolSize(50)
                            }
                        }
                        .frame(height: 200)
                        .chartYScale(domain: 0...6)
                        .chartYAxis {
                            AxisMarks(values: [1, 2, 3, 4, 5]) { value in
                                AxisGridLine()
                                AxisValueLabel {
                                    if let mood = value.as(Int.self) {
                                        Text(moodLabel(for: mood))
                                            .font(.caption2)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    .padding(.horizontal)
                }
                
                // Average Mood
                if !periodMoodData.isEmpty {
                    VStack(spacing: 12) {
                        Text("Period Summary")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack(spacing: 20) {
                            VStack(spacing: 4) {
                                Text(averageMoodEmoji)
                                    .font(.system(size: 40))
                                Text("Average")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(averageMoodLabel)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            
                            Divider()
                                .frame(height: 60)
                            
                            VStack(spacing: 4) {
                                Text("\(periodMoodData.count)")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(.purple)
                                Text("Check-ins")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            
                            Divider()
                                .frame(height: 60)
                            
                            VStack(spacing: 4) {
                                Text(trendEmoji)
                                    .font(.system(size: 30))
                                Text("Trend")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(trendLabel)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                    }
                    .padding(.horizontal)
                }
                
                // Mood History List
                VStack(spacing: 12) {
                    Text("Recent Check-ins")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    ForEach(periodMoodData.reversed().prefix(10), id: \.date) { data in
                        if let entry = moodManager.moodEntries.first(where: { Calendar.current.isDate($0.createdAt, inSameDayAs: data.date) }) {
                            HStack(spacing: 12) {
                                Text(entry.moodEmoji)
                                    .font(.title)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(entry.moodLabel)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    
                                    Text(entry.createdAt, style: .date)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    if let note = entry.note, !note.isEmpty {
                                        Text(note)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .lineLimit(2)
                                    }
                                }
                                
                                Spacer()
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
            .padding(.top)
        }
        .navigationTitle("Emotion Tracking")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await moodManager.fetchMoodEntries(days: selectedPeriod.days)
        }
        .onChange(of: selectedPeriod) { _, _ in
            Task {
                await moodManager.fetchMoodEntries(days: selectedPeriod.days)
            }
        }
    }
    
    var periodMoodData: [(date: Date, mood: Int)] {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -selectedPeriod.days, to: Date()) ?? Date()
        
        return moodManager.moodEntries
            .filter { $0.createdAt >= startDate }
            .map { (date: $0.createdAt, mood: $0.mood) }
    }
    
    var averageMood: Double {
        guard !periodMoodData.isEmpty else { return 0 }
        let sum = periodMoodData.reduce(0) { $0 + $1.mood }
        return Double(sum) / Double(periodMoodData.count)
    }
    
    var averageMoodEmoji: String {
        let rounded = Int(round(averageMood))
        return MoodEntry(userId: "", mood: rounded, note: nil, createdAt: Date()).moodEmoji
    }
    
    var averageMoodLabel: String {
        let rounded = Int(round(averageMood))
        return MoodEntry(userId: "", mood: rounded, note: nil, createdAt: Date()).moodLabel
    }
    
    var trendEmoji: String {
        guard periodMoodData.count >= 2 else { return "➡️" }
        
        let firstHalf = periodMoodData.prefix(periodMoodData.count / 2).map { $0.mood }
        let secondHalf = periodMoodData.suffix(periodMoodData.count / 2).map { $0.mood }
        
        let firstAvg = Double(firstHalf.reduce(0, +)) / Double(firstHalf.count)
        let secondAvg = Double(secondHalf.reduce(0, +)) / Double(secondHalf.count)
        
        if secondAvg > firstAvg + 0.3 {
            return "📈"
        } else if secondAvg < firstAvg - 0.3 {
            return "📉"
        } else {
            return "➡️"
        }
    }
    
    var trendLabel: String {
        guard periodMoodData.count >= 2 else { return "Stable" }
        
        let firstHalf = periodMoodData.prefix(periodMoodData.count / 2).map { $0.mood }
        let secondHalf = periodMoodData.suffix(periodMoodData.count / 2).map { $0.mood }
        
        let firstAvg = Double(firstHalf.reduce(0, +)) / Double(firstHalf.count)
        let secondAvg = Double(secondHalf.reduce(0, +)) / Double(secondHalf.count)
        
        if secondAvg > firstAvg + 0.3 {
            return "Improving"
        } else if secondAvg < firstAvg - 0.3 {
            return "Declining"
        } else {
            return "Stable"
        }
    }
    
    func moodLabel(for mood: Int) -> String {
        switch mood {
        case 1: return "😢"
        case 2: return "😔"
        case 3: return "😐"
        case 4: return "🙂"
        case 5: return "😊"
        default: return ""
        }
    }
}

#Preview {
    NavigationView {
        EmotionTrackingView()
            .environmentObject(MoodManager())
    }
}
