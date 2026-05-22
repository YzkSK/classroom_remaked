import WidgetKit
import SwiftUI
import Foundation

// MARK: - Data Model

struct WidgetAssignment: Identifiable {
    let id: String
    let title: String
    let courseName: String
    let dueDateMillis: Int64
    let isToday: Bool

    var dueDate: Date {
        Date(timeIntervalSince1970: Double(dueDateMillis) / 1000)
    }

    var dueLabel: String {
        let cal = Calendar.current
        let date = dueDate
        let timeFmt = DateFormatter()
        timeFmt.dateFormat = "HH:mm"
        if cal.isDateInToday(date) {
            return "今日 \(timeFmt.string(from: date))"
        }
        if cal.isDateInTomorrow(date) {
            return "明日 \(timeFmt.string(from: date))"
        }
        let dateFmt = DateFormatter()
        dateFmt.dateFormat = "M/d(E)"
        dateFmt.locale = Locale(identifier: "ja_JP")
        return dateFmt.string(from: date)
    }

    var dueColor: Color {
        let cal = Calendar.current
        if cal.isDateInToday(dueDate) { return .red }
        if cal.isDateInTomorrow(dueDate) { return Color.orange }
        return .secondary
    }
}

struct WidgetEntry: TimelineEntry {
    let date: Date
    let assignments: [WidgetAssignment]
}

// MARK: - TimelineProvider

struct AssignmentTimelineProvider: TimelineProvider {
    private let appGroupId = "group.com.classroomremaked.classroomRemaked"
    private let dataKey = "widget_assignments"

    func placeholder(in context: Context) -> WidgetEntry {
        WidgetEntry(date: Date(), assignments: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (WidgetEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetEntry>) -> Void) {
        let entry = loadEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func loadEntry() -> WidgetEntry {
        guard
            let defaults = UserDefaults(suiteName: appGroupId),
            let json = defaults.string(forKey: dataKey),
            let data = json.data(using: .utf8),
            let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let arr = obj["assignments"] as? [[String: Any]]
        else {
            return WidgetEntry(date: Date(), assignments: [])
        }

        let assignments: [WidgetAssignment] = arr.compactMap { dict in
            guard
                let id = dict["id"] as? String,
                let title = dict["title"] as? String,
                let courseName = dict["course_name"] as? String,
                let isToday = dict["is_today"] as? Bool
            else { return nil }
            let dueDateMillis = (dict["due_millis"] as? NSNumber)?.int64Value ?? 0
            return WidgetAssignment(
                id: id,
                title: title,
                courseName: courseName,
                dueDateMillis: dueDateMillis,
                isToday: isToday
            )
        }

        return WidgetEntry(date: Date(), assignments: assignments)
    }
}

// MARK: - Views

struct AssignmentRowView: View {
    let assignment: WidgetAssignment

    var body: some View {
        HStack(alignment: .center, spacing: 6) {
            VStack(alignment: .leading, spacing: 2) {
                Text(assignment.title)
                    .font(.system(size: 13, weight: assignment.isToday ? .semibold : .regular))
                    .lineLimit(1)
                    .foregroundColor(.primary)
                Text(assignment.courseName)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            Text(assignment.dueLabel)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(assignment.dueColor)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(assignment.dueColor.opacity(0.12))
                .cornerRadius(5)
        }
    }
}

struct AssignmentWidgetView: View {
    var entry: WidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("未提出の課題")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)

            if entry.assignments.isEmpty {
                Spacer()
                Text("課題なし")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                Spacer()
            } else {
                ForEach(entry.assignments) { a in
                    let url = URL(string: "classroomremaked://assignment?id=\(a.id)&homeWidget=true")!
                    Link(destination: url) {
                        AssignmentRowView(assignment: a)
                            .padding(.vertical, 3)
                    }
                    if a.id != entry.assignments.last?.id {
                        Divider()
                    }
                }
                Spacer()
            }
        }
        .padding(12)
        .widgetURL(
            entry.assignments.first.flatMap {
                URL(string: "classroomremaked://assignment?id=\($0.id)&homeWidget=true")
            } ?? URL(string: "classroomremaked://assignments?homeWidget=true")!
        )
    }
}

// MARK: - Widget

struct AssignmentWidget: Widget {
    let kind = "AssignmentWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AssignmentTimelineProvider()) { entry in
            if #available(iOS 17.0, *) {
                AssignmentWidgetView(entry: entry)
                    .containerBackground(.background, for: .widget)
            } else {
                AssignmentWidgetView(entry: entry)
            }
        }
        .configurationDisplayName("未提出の課題")
        .description("未提出・当日締切の課題を表示します")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
