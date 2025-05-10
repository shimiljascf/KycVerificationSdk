//
//  CalendarManager.swift
//  KycVerificationSdk
//
//  Created by Renu Bisht on 22/04/25.
//

import EventKit

class CalendarManager {
    func addEvent(from jsonString: String, completion: @escaping (Bool, String) -> Void) {
        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            completion(false, "Invalid data")
            return
        }

        let eventStore = EKEventStore()
        eventStore.requestAccess(to: .event) { granted, _ in
            guard granted else {
                completion(false, "Permission denied")
                return
            }

            let event = EKEvent(eventStore: eventStore)
            event.title = json["title"] as? String ?? "KYC Appointment"
            event.notes = json["description"] as? String
            if let millis = json["dateInMillis"] as? Double {
                let start = Date(timeIntervalSince1970: millis / 1000)
                event.startDate = start
                event.endDate = start.addingTimeInterval(15 * 60)
            }
            event.calendar = eventStore.defaultCalendarForNewEvents

            do {
                try eventStore.save(event, span: .thisEvent)
                completion(true, "Event added")
            } catch {
                completion(false, "Failed to add event")
            }
        }
    }
}
