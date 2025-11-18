#!/usr/bin/swift

/* Usage:

In ~/.config/sketchybar/sketchybarrc:

    --add item meetingbar right \
    --set meetingbar \
          icon=􀉉 \
          icon.padding_right=8 \
          label.y_offset=2 \
          update_freq=120 \
          script="$PLUGIN_DIR/meetingbar.sh"

In ~/.config/sketchybar/plugins/meetingbar.sh:

    CALENDAR="alice@example.com"
    MEETING=$("$CONFIG_DIR/meetingbar.swift" "$CALENDAR")
    sketchybar --set "$NAME" label="$MEETING"

*/

import Foundation
import EventKit

struct MeetingBarError: Error {
    let message: String
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

    // Computed property to get the next meeting
    var nextMeeting: EKEvent? {
        get throws {
        let currentDate = Date()

        // Get all calendars and filter for the specified calendar title
        let calendars = eventStore.calendars(for: .event).filter { $0.title.contains(self.calendarTitle) }

        guard !calendars.isEmpty else {
            throw MeetingBarError(message: "No calendar found for '\(self.calendarTitle)'")
        }

        // Create a predicate for events starting from now until the end of the day
        let startDate = currentDate

        // Create a date for the end of tomorrow
        let calendar = Calendar.current
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: currentDate),
              let endOfTomorrow = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: tomorrow) else {
            throw MeetingBarError(message: "Failed to calculate date")
        }

        let endDate = endOfTomorrow

        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: calendars)
        let events = eventStore.events(matching: predicate).filter { !$0.isAllDay }

        let currentMeeting = events.first(where: { currentDate >= $0.startDate && currentDate <= $0.endDate })

        // Find all events starting after current time
        let upcomingEvents = events.filter { $0.startDate > currentDate }
        // If multiple events start at the same time, pick the shortest one
        let nextMeeting = upcomingEvents.min { first, second in
            if first.startDate == second.startDate {
                // Same start time, compare durations
                let firstDuration = first.endDate.timeIntervalSince(first.startDate)
                let secondDuration = second.endDate.timeIntervalSince(second.startDate)
                return firstDuration < secondDuration
            }
            // Different start times, pick the earlier one
            return first.startDate < second.startDate
        }

        // No current meeting, show next meeting if available
        guard let current = currentMeeting else {
            return nextMeeting
        }

        // No next meeting, show current meeting
        guard let next = nextMeeting else {
            return current
        }

        // Decide which meeting to show based on both meetings
        let duration = current.endDate.timeIntervalSince(current.startDate)
        let timeUntilNext = next.startDate.timeIntervalSince(currentDate)

        // The longer the current meeting, the more we prioritize showing the next one
        // Threshold increases with meeting duration: 5 min base + 10 min per hour of meeting
        let threshold = 5 * 60 + (duration / 3600) * 10 * 60

        if timeUntilNext < threshold {
            return next
        }

        return current
        }
    }
}

// Get calendar title from command line arguments
guard CommandLine.arguments.count > 1 else {
    print("Error: Calendar title argument is required")
    print("Usage: \(CommandLine.arguments[0]) <calendar-title>")
    exit(1)
}

let calendarTitle = CommandLine.arguments[1]

func extractZoomURL(from event: EKEvent) -> String? {
    // Check notes for Zoom URL
    if let notes = event.notes {
        if let url = extractZoomURL(from: notes) {
            return url
        }
    }

    // Check location for Zoom URL
    if let location = event.location {
        if let url = extractZoomURL(from: location) {
            return url
        }
    }

    // Check URL property
    if let url = event.url?.absoluteString {
        if url.contains("zoom.us") {
            return url
        }
    }

    return nil
}

func extractZoomURL(from text: String) -> String? {
    // Pattern to match Zoom URLs
    let pattern = "https://[a-zA-Z0-9.-]*\\.?zoom\\.us/[^\\s]+"

    guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
        return nil
    }

    let nsString = text as NSString
    let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))

    if let match = matches.first {
        return nsString.substring(with: match.range)
    }

    return nil
}

func formatTimeUntil(_ date: Date, from currentDate: Date) -> String {
    let minutes = Int(date.timeIntervalSince(currentDate) / 60)
    if minutes <= 0 {
        return "now"
    } else if minutes < 60 {
        if minutes == 1 {
            return "in 1 minute"
        } else {
            return "in \(minutes) minutes"
        }
    } else {
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        if remainingMinutes == 0 {
            return "in \(hours)h"
        } else {
            return "in \(hours)h\(remainingMinutes)m"
        }
    }
}

do {
    let manager = try MeetingBar(calendarTitle: calendarTitle)
    if let event = try manager.nextMeeting {
        let currentDate = Date()
        let isCurrentMeeting = currentDate >= event.startDate && currentDate <= event.endDate

        let displayText: String
        if isCurrentMeeting {
            let timeStr = formatTimeUntil(event.endDate, from: currentDate)
            displayText = "\(event.title ?? "Untitled Event") ends \(timeStr)"
        } else {
            let timeStr = formatTimeUntil(event.startDate, from: currentDate)
            displayText = "\(event.title ?? "Untitled Event") \(timeStr)"
        }

        // Output format: markdown link [DISPLAY_TEXT](URL) or just DISPLAY_TEXT if no URL
        if let zoomURL = extractZoomURL(from: event) {
            print("[\(displayText)](\(zoomURL))")
        } else {
            print(displayText)
        }
    } else {
        print("No meetings")
    }
} catch let error as MeetingBarError {
    print("Error: \(error.message)")
    exit(1)
} catch {
    print("Error: \(error)")
    exit(1)
}
