import AppIntents

enum WidgetPalette: String, AppEnum {
    case paper, forest
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Aparência"
    static var caseDisplayRepresentations: [WidgetPalette: DisplayRepresentation] = [
        .paper: "Papel", .forest: "Jardim"
    ]
}

struct KotobaWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Uma palavra no seu dia"
    static var description = IntentDescription("Usa o mesmo cronograma do app Kotoba. O iOS controla o momento da atualização visual.")
    @Parameter(title: "Mostrar tradução", default: true) var showTranslation: Bool
    @Parameter(title: "Aparência", default: .paper) var palette: WidgetPalette
}
