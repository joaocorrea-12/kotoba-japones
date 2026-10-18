package org.kotoba.android.ui

import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import org.kotoba.android.domain.*
import java.time.*
import java.time.format.DateTimeFormatter
import java.util.Locale

private val pt = Locale.forLanguageTag("pt-BR")
fun interval(minutes: Int) = if (minutes % 60 == 0) "${minutes / 60} h" else "$minutes min"
fun dateTime(at: Instant, zone: String) = DateTimeFormatter.ofPattern("dd/MM, HH:mm", pt).withZone(ZoneId.of(zone)).format(at)

@OptIn(ExperimentalMaterial3Api::class)
@Composable fun KotobaScreen(model: KotobaViewModel) {
    val value by model.state.collectAsStateWithLifecycle()
    val p = value?.schedule?.settings
    val dark = p?.theme == "dark" || (p?.theme != "light" && isSystemInDarkTheme())
    val colors = if (dark) darkColorScheme(primary = Color(0xFFA3C6A3), background = Color(0xFF181F1B), surface = Color(0xFF222D26), secondaryContainer = Color(0xFF304638))
        else lightColorScheme(primary = Color(0xFF3D604C), background = Color(0xFFF5F4EE), surface = Color(0xFFFFFEF9), secondaryContainer = Color(0xFFDFE6D6))
    MaterialTheme(colorScheme = colors) {
        val snackbar = remember { SnackbarHostState() }
        var tab by rememberSaveable { mutableIntStateOf(0) }
        val message = model.message
        LaunchedEffect(message) { if (message != null) { snackbar.showSnackbar(message); if (model.message == message) model.message = null } }
        Scaffold(containerColor = colors.background, snackbarHost = { SnackbarHost(snackbar) }, bottomBar = {
            NavigationBar {
                listOf("Hoje" to "◉", "Palavras" to "▤", "Revisar" to "▱", "Ajustes" to "☷").forEachIndexed { index, (name, icon) ->
                    NavigationBarItem(selected = tab == index, onClick = { tab = index }, icon = { Text(icon, fontSize = 23.sp) }, label = { Text(name) })
                }
            }
        }) { padding ->
            val state = value
            if (state == null) Box(Modifier.fillMaxSize().padding(padding), contentAlignment = Alignment.Center) {
                Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.padding(24.dp)) {
                    if (model.startupError != null) { Text(model.startupError!!); Button(onClick = { model.activate() }) { Text("Tentar novamente") } }
                    else { CircularProgressIndicator(); Text("Preparando suas palavras…", Modifier.padding(top = 16.dp)) }
                }
            } else {
                val currentID = state.schedule.wordID(model.now)
                LaunchedEffect(currentID, tab) { if (tab == 0) model.seen(currentID) }
                Box(Modifier.padding(padding)) {
                    when (tab) {
                        0 -> Home(state, model, onReview = { tab = 2 }, onSettings = { tab = 3 })
                        1 -> Library(state, model)
                        2 -> Reviews(state, model)
                        3 -> SettingsScreen(state.schedule.settings, state.schedule.pausedAt != null, model)
                    }
                }
                model.selected?.let { id -> model.words.find { it.id == id }?.let { word ->
                    ModalBottomSheet(onDismissRequest = { model.selected = null }) {
                        Column(Modifier.verticalScroll(rememberScrollState()).padding(20.dp)) { WordPanel(word, state, model); Spacer(Modifier.height(20.dp)) }
                    }
                } }
            }
        }
    }
}

@Composable private fun Heading(title: String, eyebrow: String = "ことば / KOTOBA") {
    Column(Modifier.fillMaxWidth().padding(top = 12.dp, bottom = 10.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Text(eyebrow, style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.primary, letterSpacing = 2.sp)
        Text(title, style = MaterialTheme.typography.headlineLarge, fontFamily = FontFamily.Serif)
    }
}
@Composable fun WordPanel(word: Word, state: AppState, model: KotobaViewModel) {
    val p = state.schedule.settings
    Card(shape = RoundedCornerShape(26.dp), colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)) {
        Column(Modifier.fillMaxWidth().padding(24.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                Text("PALAVRA DO MOMENTO", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.primary)
                Text("JLPT N${word.jlpt}", style = MaterialTheme.typography.labelSmall)
            }
            Text(if (p.showKanji) word.japanese else word.kana, fontSize = 52.sp, fontFamily = FontFamily.Serif, lineHeight = 64.sp)
            if (p.showKana) Text(word.kana, style = MaterialTheme.typography.titleLarge)
            if (p.showRomaji) Text(word.romaji, style = MaterialTheme.typography.bodyMedium)
            if (p.showMeaning) Text(word.meaning, style = MaterialTheme.typography.headlineSmall)
            Text(word.partOfSpeech, style = MaterialTheme.typography.labelSmall)
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                Button(onClick = { model.speak(word) }) { Text("Ouvir") }
                OutlinedButton(onClick = { model.favorite(word.id) }) { Text(if (state.records[word.id]?.favorite == true) "Salva" else "Salvar") }
            }
            HorizontalDivider(Modifier.padding(vertical = 6.dp))
            Text("NO DIA A DIA", style = MaterialTheme.typography.labelSmall, letterSpacing = 1.sp)
            Text(word.example, style = MaterialTheme.typography.titleMedium)
            if (p.showMeaning) Text(word.exampleMeaning, style = MaterialTheme.typography.bodyMedium)
            Text(word.note, style = MaterialTheme.typography.bodySmall)
        }
    }
}
@Composable private fun Home(state: AppState, model: KotobaViewModel, onReview: () -> Unit, onSettings: () -> Unit) {
    val p = state.schedule.settings
    val zone = ZoneId.of(p.zone)
    val today = model.now.atZone(zone).toLocalDate()
    val days = state.activities.map { it.at.atZone(zone).toLocalDate() }.toSet()
    var cursor = if (today in days) today else today.minusDays(1)
    var streak = 0
    while (cursor in days) { streak++; cursor = cursor.minusDays(1) }
    val count = state.activities.filter { it.at.atZone(zone).toLocalDate() == today }.map { it.wordID }.distinct().size
    val due = state.records.values.count { it.review.due <= model.now }
    LazyColumn(contentPadding = PaddingValues(20.dp), verticalArrangement = Arrangement.spacedBy(20.dp)) {
        item { Heading("Um pouco,\ntodos os dias."); Text("${today.format(DateTimeFormatter.ofPattern("EEEE, d 'de' MMMM", pt))} · $streak dias de constância", style = MaterialTheme.typography.bodySmall) }
        item { model.words.find { it.id == state.schedule.wordID(model.now) }?.let { WordPanel(it, state, model) } }
        item { Card {
            Column(Modifier.fillMaxWidth().padding(22.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Text(if (state.schedule.pausedAt == null) "Uma palavra a cada ${interval(p.rotationMinutes)}" else "Trocas pausadas", style = MaterialTheme.typography.titleMedium)
                state.schedule.nextChange(model.now)?.let { Text("Próxima troca: ${dateTime(it, p.zone)}", style = MaterialTheme.typography.bodySmall) }
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) { TextButton(onClick = { model.pause() }) { Text(if (state.schedule.pausedAt == null) "Pausar" else "Retomar") }; TextButton(onClick = onSettings) { Text("Ajustar ritmo") } }
                Text("Widgets e avisos podem atrasar por decisões de bateria do Android. Intervalos de 10 ou 20 minutos não garantem atualização visual exata.", style = MaterialTheme.typography.bodySmall)
            }
        } }
        item { Card {
            Column(Modifier.fillMaxWidth().padding(22.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Text("Seu pequeno progresso · $count/${p.goal}", style = MaterialTheme.typography.titleMedium)
                LinearProgressIndicator(progress = { minOf(count.toFloat() / p.goal, 1f) }, modifier = Modifier.fillMaxWidth())
                Text("${state.records.size} palavras vistas · ${state.records.values.count { it.review.mastered }} dominadas")
                TextButton(onClick = onReview) { Text("$due revisões para agora") }
            }
        } }
    }
}

@Composable private fun Library(state: AppState, model: KotobaViewModel) {
    var query by rememberSaveable { mutableStateOf("") }
    var filter by rememberSaveable { mutableIntStateOf(0) }
    val source = when (filter) {
        1 -> model.words.filter { state.records[it.id]?.favorite == true }
        2 -> state.records.values.sortedByDescending { it.lastSeen }.mapNotNull { r -> model.words.find { it.id == r.wordID } }
        3 -> state.schedule.recent(model.now).mapNotNull { id -> model.words.find { it.id == id } }
        else -> model.words
    }.filter { query.isBlank() || listOf(it.japanese, it.kana, it.romaji, it.meaning).any { text -> text.contains(query, ignoreCase = true) } }
    LazyColumn(contentPadding = PaddingValues(20.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        item { Heading("Palavras que ficam."); OutlinedTextField(value = query, onValueChange = { query = it }, label = { Text("Japonês, leitura ou português") }, modifier = Modifier.fillMaxWidth()) }
        item { Row(Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            listOf("Todas", "Salvas", "Vistas", "Anteriores").forEachIndexed { index, label -> FilterChip(selected = filter == index, onClick = { filter = index }, label = { Text(label) }) }
        } }
        if (filter == 3) item { Text("Anteriores reconstrói a programação. Só abrir ou revisar uma palavra conta como estudo.", style = MaterialTheme.typography.bodySmall) }
        if (source.isEmpty()) item { Text("Nenhuma palavra por aqui ainda.") }
        items(source, key = { it.id }) { word -> Card(onClick = { model.open(word.id) }) {
            Row(Modifier.fillMaxWidth().padding(18.dp), horizontalArrangement = Arrangement.spacedBy(18.dp), verticalAlignment = Alignment.CenterVertically) {
                Text(if (state.schedule.settings.showKanji) word.japanese else word.kana, fontSize = 26.sp, modifier = Modifier.weight(1f))
                Column(Modifier.weight(1.5f)) {
                    if (state.schedule.settings.showKana) Text(word.kana)
                    if (state.schedule.settings.showMeaning) Text(word.meaning, style = MaterialTheme.typography.bodySmall)
                }
                if (state.records[word.id]?.favorite == true) Text("▣")
            }
        } }
    }
}

@Composable private fun Reviews(state: AppState, model: KotobaViewModel) {
    val record = state.records.values.filter { it.review.due <= model.now }.minByOrNull { it.review.due }
    val word = record?.let { r -> model.words.find { it.id == r.wordID } }
    var revealed by remember(word?.id) { mutableStateOf(false) }
    Column(Modifier.verticalScroll(rememberScrollState()).padding(20.dp), verticalArrangement = Arrangement.spacedBy(20.dp)) {
        Heading("Lembrar é aprender.")
        if (word == null) { Text("Tudo em dia. Abra uma palavra para começar ou volte na data da próxima revisão."); return@Column }
        Text("Tente lembrar antes de revelar a resposta.")
        Card {
            Column(Modifier.fillMaxWidth().padding(24.dp), verticalArrangement = Arrangement.spacedBy(18.dp), horizontalAlignment = Alignment.CenterHorizontally) {
                Text(if (state.schedule.settings.showKanji) word.japanese else word.kana, fontSize = 52.sp, fontFamily = FontFamily.Serif)
                OutlinedButton(onClick = { model.speak(word) }) { Text("Ouvir") }
                if (revealed) {
                    Text(word.kana, style = MaterialTheme.typography.titleLarge)
                    if (state.schedule.settings.showRomaji) Text(word.romaji)
                    Text(word.meaning, style = MaterialTheme.typography.headlineSmall)
                    Text(word.note); Text(word.example); Text(word.exampleMeaning)
                } else Button(onClick = { revealed = true }) { Text("Revelar resposta") }
            }
        }
        if (revealed) {
            Text("Como foi lembrar?")
            Rating.entries.chunked(2).forEach { pair -> Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                pair.forEach { rating -> OutlinedButton(onClick = { model.review(word.id, rating); revealed = false }, modifier = Modifier.weight(1f)) { Text(rating.title) } }
            } }
        }
        Text("Os intervalos se ajustam ao seu desempenho. A resposta fica disponível ao revelar, mesmo com traduções ocultas nas outras telas.", style = MaterialTheme.typography.bodySmall)
    }
}
