#!/usr/bin/swift

/*
Outputs JSON with the primary event (for bar label) and all remaining events today (for popup).

Output format:
{
  "primary": { "display": "Standup ends in 5 minutes", "url": "https://..." },
  "events": [
    { "time": "9:00 - 9:30 AM", "title": "Standup", "display": "Standup ends in 5 minutes", "url": "https://...", "current": true, "id": "ABC123" },
    { "time": "10:00 - 11:00 AM", "title": "Design Review", "display": "Design Review in 35 minutes", "url": null, "current": false, "id": "DEF456" }
  ]
}

When there are no meetings: { "primary": null, "events": [] }
*/

import Foundation
import EventKit

struct MeetingBarError: Error {
    let message: String
}

// Returns priority for participation status (lower = higher priority)
func participationPriority(for event: EKEvent) -> Int {
    guard let attendees = event.attendees else { return 100 }
    guard let me = attendees.first(where: { $0.isCurrentUser }) else { return 100 }

    switch me.participantStatus {
    case .accepted: return 0
    case .tentative: return 1
    case .pending: return 2
    case .unknown: return 3
    default: return 100
    }
}

class MeetingBar {
    let calendarTitle: String
    let eventStore: EKEventStore

    init(calendarTitle: String, eventStore: EKEventStore) {
        self.calendarTitle = calendarTitle
        self.eventStore = eventStore
    }

    convenience init(calendarTitle: String) throws {
        let eventStore = EKEventStore()
        let status = EKEventStore.authorizationStatus(for: .event)

        switch status {
        case .authorized, .fullAccess, .writeOnly:
            self.init(calendarTitle: calendarTitle, eventStore: eventStore)
        case .denied:
            throw MeetingBarError(message: "Calendar access denied")
        case .restricted:
            throw MeetingBarError(message: "Calendar access restricted")
        case .notDetermined:
            let semaphore = DispatchSemaphore(value: 0)
            var accessGranted = false

            eventStore.requestFullAccessToEvents { granted, error in
                accessGranted = granted
                semaphore.signal()
            }

            semaphore.wait()

            if accessGranted {
                self.init(calendarTitle: calendarTitle, eventStore: eventStore)
            } else {
                throw MeetingBarError(message: "Calendar access denied")
            }
        @unknown default:
            throw MeetingBarError(message: "Unknown authorization status")
        }
    }

    /// All non-all-day, non-declined events from now until end of day, sorted by start time.
    func remainingEventsToday() throws -> [EKEvent] {
        let currentDate = Date()
        let calendar = Calendar.current

        let calendars = eventStore.calendars(for: .event).filter { $0.title.contains(self.calendarTitle) }
        guard !calendars.isEmpty else {
            throw MeetingBarError(message: "No calendar found for '\(self.calendarTitle)'")
        }

        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: currentDate),
              let endOfDay = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: tomorrow) else {
            throw MeetingBarError(message: "Failed to calculate date")
        }

        let predicate = eventStore.predicateForEvents(withStart: currentDate, end: endOfDay, calendars: calendars)
        return eventStore.events(matching: predicate)
            .filter { event in
                guard !event.isAllDay else { return false }
                if let attendees = event.attendees,
                   let me = attendees.first(where: { $0.isCurrentUser }),
                   me.participantStatus == .declined {
                    return false
                }
                return true
            }
            .sorted { $0.startDate < $1.startDate }
    }

    /// Smart selection of which event to feature in the bar, using the full priority logic.
    func primaryEvent(from events: [EKEvent]) -> EKEvent? {
        let currentDate = Date()

        // Find current meetings, preferring accepted ones
        let currentMeetings = events.filter { currentDate >= $0.startDate && currentDate <= $0.endDate }
        let currentMeeting = currentMeetings.min { first, second in
            let firstPriority = participationPriority(for: first)
            let secondPriority = participationPriority(for: second)
            if firstPriority != secondPriority {
                return firstPriority < secondPriority
            }
            let firstDuration = first.endDate.timeIntervalSince(first.startDate)
            let secondDuration = second.endDate.timeIntervalSince(second.startDate)
            return firstDuration < secondDuration
        }

        // Find all events starting after current time
        let upcomingEvents = events.filter { $0.startDate > currentDate }
        let nextMeeting = upcomingEvents.min { first, second in
            if first.startDate != second.startDate {
                return first.startDate < second.startDate
            }
            let firstPriority = participationPriority(for: first)
            let secondPriority = participationPriority(for: second)
            if firstPriority != secondPriority {
                return firstPriority < secondPriority
            }
            let firstDuration = first.endDate.timeIntervalSince(first.startDate)
            let secondDuration = second.endDate.timeIntervalSince(second.startDate)
            return firstDuration < secondDuration
        }

        guard let current = currentMeeting else { return nextMeeting }
        guard let next = nextMeeting else { return current }

        let duration = current.endDate.timeIntervalSince(current.startDate)
        let timeUntilNext = next.startDate.timeIntervalSince(currentDate)
        let threshold = 5 * 60 + (duration / 3600) * 10 * 60

        if timeUntilNext < threshold {
            return next
        }

        return current
    }
}

// MARK: - Helpers

func extractMeetingURL(from event: EKEvent) -> String? {
    if let notes = event.notes, let url = extractMeetingURL(from: notes) {
        return url
    }
    if let location = event.location, let url = extractMeetingURL(from: location) {
        return url
    }
    if let url = event.url?.absoluteString {
        if url.contains("zoom.us") || url.contains("vimeo.com") {
            return url
        }
    }
    return nil
}

func extractMeetingURL(from text: String) -> String? {
    let patterns = [
        "https://[a-zA-Z0-9.-]*\\.?zoom\\.us/[^\\s]+",
        "https://(?:www\\.)?vimeo\\.com/[^\\s]+"
    ]

    for pattern in patterns {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { continue }
        let nsString = text as NSString
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
        if let match = matches.first {
            let url = nsString.substring(with: match.range)
            return url.trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
        }
    }
    return nil
}

func formatTimeUntil(_ date: Date, from currentDate: Date) -> String {
    let minutes = Int(date.timeIntervalSince(currentDate) / 60)
    if minutes <= 0 {
        return "now"
    } else if minutes < 60 {
        return minutes == 1 ? "in 1 minute" : "in \(minutes) minutes"
    } else {
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        return remainingMinutes == 0 ? "in \(hours)h" : "in \(hours)h\(remainingMinutes)m"
    }
}

func jsonString(_ s: String) -> String {
    // Escape backslashes, quotes, and control characters for JSON
    var result = s
    result = result.replacingOccurrences(of: "\\", with: "\\\\")
    result = result.replacingOccurrences(of: "\"", with: "\\\"")
    result = result.replacingOccurrences(of: "\n", with: "\\n")
    result = result.replacingOccurrences(of: "\r", with: "\\r")
    result = result.replacingOccurrences(of: "\t", with: "\\t")
    return "\"\(result)\""
}

func jsonStringOrNull(_ s: String?) -> String {
    guard let s = s else { return "null" }
    return jsonString(s)
}

// MARK: - Main

guard CommandLine.arguments.count > 1 else {
    print("Error: Calendar title argument is required")
    print("Usage: \(CommandLine.arguments[0]) <calendar-title>")
    exit(1)
}

let calendarTitle = CommandLine.arguments[1]

do {
    let manager = try MeetingBar(calendarTitle: calendarTitle)
    let events = try manager.remainingEventsToday()
    var primary = manager.primaryEvent(from: events)
    let currentDate = Date()

    // Check for pinned event override.
    let tmpDir = ProcessInfo.processInfo.environment["TMPDIR"] ?? NSTemporaryDirectory()
    let pinPath = tmpDir + "meetingbar_pin"

    if let pinnedID = try? String(contentsOfFile: pinPath, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines),
       !pinnedID.isEmpty {
        if let pinnedEvent = events.first(where: { $0.eventIdentifier == pinnedID }) {
            primary = pinnedEvent
        } else {
            try? FileManager.default.removeItem(atPath: pinPath)
        }
    }

    let timeFormatter = DateFormatter()
    timeFormatter.dateFormat = "h:mm a"

    // Build primary object
    let primaryJSON: String
    if let event = primary {
        let isCurrentMeeting = currentDate >= event.startDate && currentDate <= event.endDate
        let displayText: String
        if isCurrentMeeting {
            let timeStr = formatTimeUntil(event.endDate, from: currentDate)
            let title = (event.title ?? "Untitled Event").trimmingCharacters(in: .whitespaces)
            displayText = "\(title) ends \(timeStr)"
        } else {
            let timeStr = formatTimeUntil(event.startDate, from: currentDate)
            let title = (event.title ?? "Untitled Event").trimmingCharacters(in: .whitespaces)
            displayText = "\(title) \(timeStr)"
        }
        let url = extractMeetingURL(from: event)
        primaryJSON = "{ \"display\": \(jsonString(displayText)), \"url\": \(jsonStringOrNull(url)) }"
    } else {
        primaryJSON = "null"
    }

    // Build events array
    var eventJSONs: [String] = []
    for event in events {
        let start = timeFormatter.string(from: event.startDate)
        let end = timeFormatter.string(from: event.endDate)
        let time = "\(start) - \(end)"
        let title = (event.title ?? "Untitled Event").trimmingCharacters(in: .whitespaces)
        let url = extractMeetingURL(from: event)
        let isCurrent = currentDate >= event.startDate && currentDate <= event.endDate
        let display: String
        if isCurrent {
            display = "\(title) ends \(formatTimeUntil(event.endDate, from: currentDate))"
        } else {
            display = "\(title) \(formatTimeUntil(event.startDate, from: currentDate))"
        }
        eventJSONs.append("{ \"time\": \(jsonString(time)), \"title\": \(jsonString(title)), \"display\": \(jsonString(display)), \"url\": \(jsonStringOrNull(url)), \"current\": \(isCurrent), \"id\": \(jsonString(event.eventIdentifier)) }")
    }

    let eventsJSON = "[\(eventJSONs.joined(separator: ", "))]"
    print("{ \"primary\": \(primaryJSON), \"events\": \(eventsJSON) }")
} catch let error as MeetingBarError {
    fputs("Error: \(error.message)\n", stderr)
    exit(1)
} catch {
    fputs("Error: \(error)\n", stderr)
    exit(1)
}
