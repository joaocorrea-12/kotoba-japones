import SwiftUI

enum KotobaTheme {
    static let accent = Color(red: 0.27, green: 0.40, blue: 0.34)
    static let warm = Color(red: 0.67, green: 0.35, blue: 0.25)
    static let canvas = Color(uiColor: .systemGroupedBackground)
    static let surface = Color(uiColor: .secondarySystemGroupedBackground)
}

struct Surface<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content.padding(24).frame(maxWidth: .infinity, alignment: .leading)
            .background(KotobaTheme.surface, in: RoundedRectangle(cornerRadius: 26))
    }
}

func intervalTitle(_ minutes: Int) -> String {
    if minutes < 60 { return "\(minutes) min" }
    if minutes % 60 == 0 { return "\(minutes / 60) h" }
    return "\(minutes / 60) h \(minutes % 60) min"
}
