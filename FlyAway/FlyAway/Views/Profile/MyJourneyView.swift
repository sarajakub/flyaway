import SwiftUI
import Charts

struct MyJourneyView: View {
    @EnvironmentObject var thoughtManager: ThoughtManager
    @EnvironmentObject var milestoneManager: MilestoneManager
    @State private var selectedPeriod: TimePeriod = .week
    
    enum TimePeriod: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
        case allTime = "All Time"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 50))
                        .foregroundColor(.purple)
                    
                    Text("My Journey")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Track your healing progress over time")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                // Time Period Picker
                Picker("Period", selection: $selectedPeriod) {
                    ForEach(TimePeriod.allCases, id: \.self) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Total Thoughts Created (All Time)
                VStack(spacing: 12) {
                    Text("Total Thoughts Created")
                        .font(.headline)
                    
                    Text("\(totalThoughtsCreated)")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(.purple)
                    
                    Text("Since \(firstActivityDate)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.purple.opacity(0.1))
                .cornerRadius(16)
                .padding(.horizontal)
                
                // Period Statistics
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    PeriodStatCard(
                        icon: "plus.circle.fill",
                        value: "\(thoughtsInPeriod)",
                        label: "Created",
                        color: .green
                    )
                    
                    PeriodStatCard(
                        icon: "trash.circle.fill",
                        value: "\(deletedInPeriod)",
                        label: "Deleted",
                        color: .red
                    )
                    
                    PeriodStatCard(
                        icon: "paperplane.circle.fill",
                        value: "\(etherInPeriod)",
                        label: "To Ether",
                        color: .orange
                    )
                    
                    PeriodStatCard(
                        icon: "doc.text.fill",
                        value: "\(thoughtManager.thoughts.count)",
                        label: "Active Now",
                        color: .blue
                    )
                }
                .padding(.horizontal)
                
                // Activity Line Chart
                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Thoughts Written")
                            .font(.headline)
                        Text("Each thought shared, released, or sent to ether")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)

                    Chart(dailyActivityData, id: \.date) { item in
                        AreaMark(
                            x: .value("Date", item.date),
                            y: .value("Thoughts", item.count)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.purple.opacity(0.35), Color.purple.opacity(0.0)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)

                        LineMark(
                            x: .value("Date", item.date),
                            y: .value("Thoughts", item.count)
                        )
                        .foregroundStyle(Color.purple)
                        .lineStyle(StrokeStyle(lineWidth: 2.5))
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Date", item.date),
                            y: .value("Thoughts", item.count)
                        )
                        .foregroundStyle(Color.purple)
                        .symbolSize(item.count > 0 ? 40 : 0)
                    }
                    .chartXAxis {
                        AxisMarks(values: xAxisValues) { value in
                            AxisGridLine()
                            AxisValueLabel(format: xAxisFormat)
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            AxisGridLine()
                            AxisValueLabel()
                        }
                    }
                    .frame(height: 180)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                // Category Donut Chart
                if !categoryBreakdown.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Categories (All Time)")
                            .font(.headline)
                            .padding(.horizontal)

                        HStack(alignment: .center, spacing: 16) {
                            // Donut chart
                            Chart(categoryBreakdown, id: \.category) { item in
                                SectorMark(
                                    angle: .value("Count", item.count),
                                    innerRadius: .ratio(0.52),
                                    angularInset: 1.5
                                )
                                .foregroundStyle(categoryColor(item.category))
                                .cornerRadius(4)
                            }
                            .frame(width: 140, height: 140)

                            // Legend
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(categoryBreakdown, id: \.category) { item in
                                    HStack(spacing: 8) {
                                        Circle()
                                            .fill(categoryColor(item.category))
                                            .frame(width: 10, height: 10)
                                        Text(item.category.emoji + " " + item.category.rawValue)
                                            .font(.caption)
                                            .lineLimit(1)
                                        Spacer()
                                        Text("\(item.percentage)%")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                }
                
                // Milestones Summary
                if !milestoneManager.milestones.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Milestones")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            ForEach(milestoneManager.milestones.prefix(3)) { milestone in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(milestone.title)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        
                                        Text(milestone.eventDate, style: .date)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Text(milestone.timeSinceText)
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.purple)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("My Journey")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await thoughtManager.fetchUserThoughts()
            await thoughtManager.fetchSavedThoughts()
            await thoughtManager.fetchThoughtActivities()
            await milestoneManager.fetchMilestones()
        }
        .refreshable {
            await thoughtManager.fetchThoughtActivities()
            await thoughtManager.fetchUserThoughts()
        }
    }
    
    // MARK: - Computed Properties
    
    var totalThoughtsCreated: Int {
        thoughtManager.thoughtActivities.filter { $0.activityType == .created }.count
    }
    
    var firstActivityDate: String {
        guard let firstActivity = thoughtManager.thoughtActivities.last else {
            return "today"
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: firstActivity.createdAt)
    }
    
    var periodStartDate: Date {
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedPeriod {
        case .week:
            return calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .month:
            return calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .year:
            return calendar.date(byAdding: .year, value: -1, to: now) ?? now
        case .allTime:
            return Date.distantPast
        }
    }
    
    var activitiesInPeriod: [ThoughtActivity] {
        thoughtManager.thoughtActivities.filter { $0.createdAt >= periodStartDate }
    }
    
    var thoughtsInPeriod: Int {
        activitiesInPeriod.filter { $0.activityType == .created }.count
    }
    
    var deletedInPeriod: Int {
        activitiesInPeriod.filter { $0.activityType == .deleted }.count
    }
    
    var etherInPeriod: Int {
        activitiesInPeriod.filter { $0.activityType == .created && $0.sentToEther }.count
    }
    
    var dailyActivityData: [(date: Date, count: Int)] {
        let calendar = Calendar.current
        var dateCounts: [Date: Int] = [:]
        
        let daysToShow: Int
        switch selectedPeriod {
        case .week: daysToShow = 7
        case .month: daysToShow = 30
        case .year: daysToShow = 12 // Show by month
        case .allTime: daysToShow = 30
        }
        
        // Group activities by day
        for activity in activitiesInPeriod {
            if activity.activityType == .created {
                let startOfDay = calendar.startOfDay(for: activity.createdAt)
                dateCounts[startOfDay, default: 0] += 1
            }
        }
        
        // Create data for each day
        var data: [(date: Date, count: Int)] = []
        let now = Date()
        
        if selectedPeriod == .year {
            // Show monthly data for year view
            for monthOffset in (0..<12).reversed() {
                if let monthStart = calendar.date(byAdding: .month, value: -monthOffset, to: now) {
                    let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) ?? monthStart
                    let monthCount = activitiesInPeriod.filter {
                        $0.activityType == .created &&
                        $0.createdAt >= monthStart &&
                        $0.createdAt < monthEnd
                    }.count
                    data.append((date: monthStart, count: monthCount))
                }
            }
        } else {
            for dayOffset in (0..<daysToShow).reversed() {
                if let day = calendar.date(byAdding: .day, value: -dayOffset, to: now) {
                    let startOfDay = calendar.startOfDay(for: day)
                    let count = dateCounts[startOfDay] ?? 0
                    data.append((date: startOfDay, count: count))
                }
            }
        }
        
        return data
    }
    
    // Category chart helpers
    func categoryColor(_ category: Thought.ThoughtCategory) -> Color {
        let colors: [Color] = [.purple, .blue, .teal, .green, .orange, .pink, .indigo, .cyan]
        let index = (Thought.ThoughtCategory.allCases.firstIndex(of: category) ?? 0) % colors.count
        return colors[index]
    }

    var xAxisValues: [Date] {
        switch selectedPeriod {
        case .week:    return Array(stride(from: 0, through: 6, by: 1).compactMap { Calendar.current.date(byAdding: .day, value: -$0, to: Date()) }.reversed())
        case .month:   return Array(stride(from: 0, through: 29, by: 6).compactMap { Calendar.current.date(byAdding: .day, value: -$0, to: Date()) }.reversed())
        case .year:    return Array(stride(from: 0, through: 11, by: 2).compactMap { Calendar.current.date(byAdding: .month, value: -$0, to: Date()) }.reversed())
        case .allTime: return dailyActivityData.map(\.date)
        }
    }

    var xAxisFormat: Date.FormatStyle {
        switch selectedPeriod {
        case .week:    return .dateTime.weekday(.abbreviated)
        case .month:   return .dateTime.month(.abbreviated).day()
        case .year:    return .dateTime.month(.abbreviated)
        case .allTime: return .dateTime.month(.abbreviated).year(.twoDigits)
        }
    }

    var categoryBreakdown: [(category: Thought.ThoughtCategory, count: Int, percentage: Int)] {
        let allCreated = thoughtManager.thoughtActivities.filter { $0.activityType == .created }
        guard !allCreated.isEmpty else { return [] }
        
        var categoryCounts: [Thought.ThoughtCategory: Int] = [:]
        for activity in allCreated {
            categoryCounts[activity.category, default: 0] += 1
        }
        
        return categoryCounts.map { (category, count) in
            let percentage = Int((Double(count) / Double(allCreated.count)) * 100)
            return (category, count, percentage)
        }
        .sorted { $0.count > $1.count }
    }
}

struct PeriodStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

#Preview {
    NavigationView {
        MyJourneyView()
            .environmentObject(ThoughtManager())
            .environmentObject(MilestoneManager())
    }
}
