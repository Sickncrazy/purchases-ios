//
//  Localization.swift
//
//
//  Created by Nacho Soto on 7/20/23.
//

import Foundation
import RevenueCat

enum Localization {

    /// - Returns: an appropriately short abbreviation for the given `unit`.
    static func abbreviatedUnitLocalizedString(
        for unit: NSCalendar.Unit,
        locale: Locale = .current
    ) -> String {
        let (full, abbreviated) = self.unitLocalizedString(for: unit, locale: locale)

        if full.count <= Self.unitAbbreviationMaximumLength {
            return full
        } else {
            return abbreviated
        }
    }

    static func localizedDuration(
        for subscriptionPeriod: SubscriptionPeriod,
        locale: Locale = .current
    ) -> String {
        let formatter = DateComponentsFormatter()
        formatter.calendar?.locale = locale
        formatter.allowedUnits = [subscriptionPeriod.unit.calendarUnit]
        formatter.unitsStyle = .full
        formatter.includesApproximationPhrase = false
        formatter.includesTimeRemainingPhrase = false
        formatter.maximumUnitCount = 1

        return formatter.string(from: subscriptionPeriod.components) ?? ""
    }

    /// - Returns: the `Bundle` associated with the given locale if found
    /// Defaults to `Bundle.module`.
    ///
    /// `SwiftUI.Text` uses `EnvironmentValues.locale` and therefore
    /// can be mocked in tests.
    /// However, for views that load strings, this allows specifying a custom `Locale`.
    /// Example:
    /// ```swift
    /// let text = Localization
    ///    .localizedBundle(locale)
    ///    .localizedString(
    ///        forKey: "string",
    ///        value: nil,
    ///        table: nil
    ///    )
    /// ```
    static func localizedBundle(_ locale: Locale) -> Bundle {
        let containerBundle: Bundle = .module

        let preferredLocale = Bundle.preferredLocalizations(
            from: containerBundle.localizations,
            forPreferences: [locale.identifier]
        ).first

        let path = preferredLocale.flatMap { containerBundle.path(forResource: $0, ofType: "lproj") }
        return path.flatMap(Bundle.init(path:)) ?? containerBundle
    }

}

// MARK: - Private

private extension Localization {

    static func unitLocalizedString(
        for unit: NSCalendar.Unit,
        locale: Locale = .current
    ) -> (full: String, abbreviated: String) {
        var calendar: Calendar = .current
        calendar.locale = locale

        let date = Date()
        let value = 1
        let component = unit.component

        guard let sinceUnits = calendar.date(byAdding: component,
                                             value: value,
                                             to: date) else { return ("", "") }

        let formatter = DateComponentsFormatter()
        formatter.calendar = calendar
        formatter.allowedUnits = [unit]

        func result(for style: DateComponentsFormatter.UnitsStyle) -> String {
            formatter.unitsStyle = style
            guard let string = formatter.string(from: date, to: sinceUnits) else { return "" }

            return string
                .replacingOccurrences(of: String(value), with: "")
                .trimmingCharacters(in: .whitespaces)
        }

        return (full: result(for: .full),
                abbreviated: result(for: .abbreviated))
    }

    static let unitAbbreviationMaximumLength = 3

}

// MARK: - Extensions

private extension NSCalendar.Unit {

    var component: Calendar.Component {
        switch self {
        case .era: return .era
        case .year: return .year
        case .month: return .month
        case .day: return .day
        case .hour: return .hour
        case .minute: return .minute
        case .second: return .second
        case .weekday: return .weekday
        case .weekdayOrdinal: return .weekdayOrdinal
        case .quarter: return .quarter
        case .weekOfMonth: return .weekOfMonth
        case .weekOfYear: return .weekOfYear
        case .yearForWeekOfYear: return .yearForWeekOfYear
        case .nanosecond: return .nanosecond
        case .calendar: return .calendar
        case .timeZone: return .timeZone
        default: return .calendar
        }
    }
}

private extension SubscriptionPeriod.Unit {

    var calendarUnit: NSCalendar.Unit {
        switch self {
        case .day: return .day
        case .week: return .weekOfMonth
        case .month: return .month
        case .year: return .year
        }
    }

}

private extension SubscriptionPeriod {

    var components: DateComponents {
        switch self.unit {
        case .day:
            return DateComponents(day: self.value)
        case .week:
            return DateComponents(weekOfMonth: self.value)
        case .month:
            return DateComponents(month: self.value)
        case .year:
            return DateComponents(year: self.value)
        @unknown default:
            return .init()
        }
    }

}
