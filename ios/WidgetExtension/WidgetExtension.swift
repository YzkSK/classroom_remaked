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

    var dueLabel: String {
        let date = Date(timeIntervalSince1970: Double(dueDateMillis) / 1000)
        if Calendar.current.isDateInToday(date) {
            let fmt = DateFormatter()
            fmt.dateFormat = "HH:mm"
            return "今日 \(fmt.string(from: date))"
        } else {
            let fmt = DateFormatter()
            fmt.dateFormat = "M/d"
            return fmt.string(from: date)
        }
    }
}

struct WidgetEntry: TimelineEntry {
    let date: Date
    let assignments: [WidgetAssignment]
}

// MARK: - TimelineProvider

struct AssignmentTimelineProvider: TimelineProvider {
    private let appGroupId = "group.com.classroomremaked.classroomRemaked"
    private let dataKey = "flutter.widget_assignments"

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
            // JSON numbers arrive as NSNumber; cast via Int64 via NSNumber
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
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text(assignment.title)
                    .font(.system(size: 13, weight: assignment.isToday ? .semibold : .regular))
                    .lineLimit(1)
                    .foregroundColor(assignment.isToday ? .red : .primary)
                Text(assignment.courseName)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            Text(assignment.dueLabel)
                .font(.system(size: 11))
                .foregroundColor(assignment.isToday ? .red : .secondary)
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
                    AssignmentRowView(assignment: a)
                    if a.id != entry.assignments.last?.id {
                        Divider()
                    }
                }
                Spacer()
            }
        }
        .padding(12)
        .widgetURL(URL(string: "classroomremaked://assignments"))
    }
}

// MARK: - Widget

@main
struct AssignmentWidget: Widget {
    let kind = "AssignmentWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AssignmentTimelineProvider()) { entry in
            AssignmentWidgetView(entry: entry)
        }
        .configurationDisplayName("未提出の課題")
        .description("未提出・当日締切の課題を表示します")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}
