import SwiftUI

/// Locale japonesa nos elementos japoneses, sem alterar o idioma das telas.
/// A seleção de voz pelo VoiceOver deve ser validada no dispositivo com detecção de idiomas.
extension View {
    func japaneseText() -> some View { environment(\.locale, Locale(identifier: "ja_JP")) }
}
