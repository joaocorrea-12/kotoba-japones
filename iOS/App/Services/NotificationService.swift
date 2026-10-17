import Foundation
import UserNotifications
import KotobaCore

struct NotificationReport {
    var count = 0
    var lastDate: Date?
    var permissionDenied = false
}

@MainActor final class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    var onOpenWord: ((String) -> Void)?
    private let center = UNUserNotificationCenter.current()
    private let prefix = "kotoba.word."
    override init() {
        super.init()
        center.delegate = self
    }

    func requestPermission() async throws -> Bool {
        try await center.requestAuthorization(options: [.alert, .sound])
    }

    func schedule(_ schedule: WordSchedule, words: [Word], now: Date = Date()) async throws -> NotificationReport {
        let pending = await center.pendingNotificationRequests()
        let owned = pending.filter { $0.identifier.hasPrefix(prefix) }
        let others = pending.count - owned.count
        center.removePendingNotificationRequests(withIdentifiers: owned.map(\.identifier))
        guard schedule.settings.notificationsEnabled, schedule.pausedAt == nil else { return NotificationReport() }
        let status = await center.notificationSettings().authorizationStatus
        guard status == .authorized || status == .provisional || status == .ephemeral else {
            return NotificationReport(permissionDenied: true)
        }
        let plans = NotificationPlanner.plan(schedule: schedule, after: now, capacity: max(0, 60 - others))
        let lookup = Dictionary(uniqueKeysWithValues: words.map { ($0.id, $0) })
        var report = NotificationReport()
        for plan in plans {
            guard let word = lookup[plan.wordID] else { continue }
            let content = UNMutableNotificationContent()
            let settings = schedule.settings
            content.title = settings.showKanji ? word.japanese : word.kana
            var lines: [String] = []
            if settings.showKana { lines.append(word.kana) }
            if settings.showRomaji { lines.append(word.romaji) }
            if settings.showMeaning { lines.append(word.meaning) }
            content.body = lines.isEmpty ? "Um pequeno encontro com o japonês. Toque para estudar." : lines.joined(separator: " · ")
            content.sound = .default
            content.userInfo = ["wordID": word.id]
            // UTC fixa cada instante e evita ambiguidade nos horários de verão.
            var utc = Calendar(identifier: .gregorian)
            utc.timeZone = TimeZone(secondsFromGMT: 0)!
            var components = utc.dateComponents([.year, .month, .day, .hour, .minute, .second], from: plan.date)
            components.timeZone = utc.timeZone
            components.calendar = utc
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: prefix + String(Int(plan.date.timeIntervalSince1970)), content: content, trigger: trigger)
            try await center.add(request)
            report.count += 1
            report.lastDate = plan.date
        }
        return report
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
        willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if let id = response.notification.request.content.userInfo["wordID"] as? String {
            Task { @MainActor in
                self.onOpenWord?(id)
            }
        }
        completionHandler()
    }
}

