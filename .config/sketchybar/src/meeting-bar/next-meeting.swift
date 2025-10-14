#!/usr/bin/swift

import Foundation
import EventKit

// Function to format a date into a readable time string
func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "h:mm a"
    return formatter.string(from: date)
}

// Function to get the current time and date
func getCurrentDate() -> Date {
    return Date()
}

// Function to check if a meeting is happening now
func isMeetingNow(event: EKEvent, currentDate: Date) -> Bool {
    return currentDate >= event.startDate && currentDate <= event.endDate
}

// Main function to get the next meeting
func getNextMeeting() -> String {
    let eventStore = EKEventStore()
    let status = EKEventStore.authorizationStatus(for: .event)

    switch status {
    case .authorized:
        return fetchNextMeeting(eventStore: eventStore)
    case .denied, .restricted:
        return "📅 No access to calendar"
    case .notDetermined:
        var result = "📅 Requesting access..."
        if #available(macOS 14.0, *) {
            eventStore.requestFullAccessToEvents { granted, error in
                if granted {
                    result = fetchNextMeeting(eventStore: eventStore)
                } else {
                    result = "📅 Access denied"
                }
            }
        } else {
            // For older macOS versions
            // Swift doesn't support #pragma directly, using @available attribute instead
            @available(*, deprecated)
            func requestAccessLegacy() {
                eventStore.requestAccess(to: .event) { granted, error in
                    if granted {
                        result = fetchNextMeeting(eventStore: eventStore)
                    } else {
                        result = "📅 Access denied"
                    }
                }
            }
            requestAccessLegacy()
        }
        return result
    case .fullAccess:
        return fetchNextMeeting(eventStore: eventStore)
    case .writeOnly:
        return fetchNextMeeting(eventStore: eventStore)
    @unknown default:
        return "📅 Unknown status"
    }
}

// Function to fetch the next meeting from the calendar
func fetchNextMeeting(eventStore: EKEventStore) -> String {
    let currentDate = getCurrentDate()

    // Get all calendars and filter for alpha.chen@gusto.com
    let allCalendars = eventStore.calendars(for: .event)
    let personalCalendars = allCalendars.filter { calendar in
        return calendar.title.contains("alpha.chen@gusto.com") ||
               calendar.calendarIdentifier.contains("alpha.chen@gusto.com")
    }

    // Use filtered calendars or return early if none found
    guard !personalCalendars.isEmpty else {
        return "📅 No alpha.chen@gusto.com calendar found"
    }

    let calendars = personalCalendars

    // Create a predicate for events starting from now until the end of the day
    let startDate = currentDate

    // Create a date for the end of tomorrow
    let calendar = Calendar.current
    guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: currentDate),
          let endOfTomorrow = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: tomorrow) else {
        return "📅 Error calculating date"
    }

    let endDate = endOfTomorrow

    let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: calendars)
    let events = eventStore.events(matching: predicate).filter { !$0.isAllDay }

    // Find current meeting
    if let currentMeeting = events.first(where: { isMeetingNow(event: $0, currentDate: currentDate) }) {
        return "📅 Now: \(currentMeeting.title ?? "Untitled Event")"
    }

    // Find next meeting
    if let nextMeeting = events.first(where: { $0.startDate > currentDate }) {
        let timeStr = formatDate(nextMeeting.startDate)
        return "📅 Next: \(nextMeeting.title ?? "Untitled Event") at \(timeStr)"
    }

    return "📅 No more meetings today"
}

// Set this to true for debug mode, false for normal operation
let debugMode = false

if debugMode {
    // Debug output to show all calendars
    let eventStore = EKEventStore()
    let calendars = eventStore.calendars(for: .event)
    print("All calendars:")
    for calendar in calendars {
        print("- \(calendar.title) [\(calendar.calendarIdentifier)]")
    }

    // Also list filtered calendars
    let filteredCalendars = calendars.filter { calendar in
        return calendar.title.contains("alpha.chen@gusto.com") ||
               calendar.calendarIdentifier.contains("alpha.chen@gusto.com")
    }
    print("\nFiltered calendars:")
    for calendar in filteredCalendars {
        print("- \(calendar.title) [\(calendar.calendarIdentifier)]")
    }
    print("\n")
}

// Output the next meeting information
print(getNextMeeting())