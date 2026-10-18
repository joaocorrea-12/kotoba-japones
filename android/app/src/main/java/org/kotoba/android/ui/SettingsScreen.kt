package org.kotoba.android.ui

import android.Manifest
import android.app.TimePickerDialog
import android.content.Intent
import android.os.Build
import android.provider.Settings as AndroidSettings
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import org.kotoba.android.domain.Settings
import org.kotoba.android.services.Notifications

@Composable fun SettingsScreen(settings: Settings, paused: Boolean, model: KotobaViewModel) {
    var draft by remember(settings) { mutableStateOf(settings) }
    var rotation by remember(settings) { mutableStateOf(if (settings.rotationMinutes in Settings.presets) settings.rotationMinutes else 0) }
    var amount by remember(settings) { mutableStateOf(settings.rotationMinutes.toString()) }
    var unit by remember { mutableIntStateOf(1) }
    var notification by remember(settings) { mutableStateOf(settings.notificationMinutes.toString()) }
    val context = LocalContext.current
    val request = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
        model.pendingSettings?.let { model.save(it.copy(notifications = granted), permissionDenied = !granted) }
        model.pendingSettings = null
    }
    Column(Modifier.verticalScroll(rememberScrollState()).padding(20.dp), verticalArrangement = Arrangement.spacedBy(20.dp)) {
        Text("NO SEU TEMPO", style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.primary)
        Text("Encontre o seu ritmo.", style = MaterialTheme.typography.headlineLarge)
        SettingsCard("Uma palavra de cada vez") {
            Choice("Trocar palavra", rotation, Settings.presets.map { it to "A cada ${interval(it)}" } + (0 to "Personalizado")) { rotation = it }
            if (rotation == 0) {
                OutlinedTextField(value = amount, onValueChange = { amount = it }, label = { Text("Quantidade") }, keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number), singleLine = true, modifier = Modifier.fillMaxWidth())
                Choice("Unidade", unit, listOf(1 to "Minutos", 60 to "Horas")) { unit = it }
            }
            Text("De 1 minuto a 7 dias. Widgets são atualizados em oportunidades do sistema, normalmente a partir de 15 minutos e com possíveis atrasos.", style = MaterialTheme.typography.bodySmall)
            SettingToggle("Ordem aleatória", draft.random) { draft = draft.copy(random = it) }
            Choice("Nível", draft.level, (5 downTo 1).map { it to "JLPT N$it" }) { draft = draft.copy(level = it) }
            Text("A base inicial tem 121 palavras N5 estimadas. Níveis superiores incluem essa base; conteúdos avançados virão em outra fase.", style = MaterialTheme.typography.bodySmall)
            OutlinedButton(onClick = { model.pause() }) { Text(if (!paused) "Pausar trocas e avisos" else "Retomar trocas e avisos") }
        }
        SettingsCard("Dias de estudo") {
            listOf("Segunda-feira", "Terça-feira", "Quarta-feira", "Quinta-feira", "Sexta-feira", "Sábado", "Domingo").forEachIndexed { i, day ->
                SettingToggle(day, i + 1 in draft.weekdays) { active -> draft = draft.copy(weekdays = if (active) draft.weekdays + (i + 1) else draft.weekdays - (i + 1)) }
            }
            Text("As trocas ficam congeladas nos dias desmarcados. A sequência conta dias corridos com estudo real.", style = MaterialTheme.typography.bodySmall)
        }
        SettingsCard("Um lembrete gentil") {
            SettingToggle("Receber notificações", draft.notifications) { draft = draft.copy(notifications = it) }
            OutlinedTextField(value = notification, onValueChange = { notification = it }, label = { Text("Avisar a cada quantos minutos?") }, keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number), singleLine = true, modifier = Modifier.fillMaxWidth())
            Choice("Intervalos comuns de aviso", draft.notificationMinutes, Settings.presets.map { it to interval(it) } + if (draft.notificationMinutes !in Settings.presets) listOf(draft.notificationMinutes to interval(draft.notificationMinutes)) else emptyList()) {
                draft = draft.copy(notificationMinutes = it); notification = it.toString()
            }
            SettingToggle("Horário de silêncio", draft.quiet) { draft = draft.copy(quiet = it) }
            if (draft.quiet) {
                TimeChoice("Silêncio a partir de", draft.quietStart) { draft = draft.copy(quietStart = it) }
                TimeChoice("Voltar a avisar às", draft.quietEnd) { draft = draft.copy(quietEnd = it) }
            }
            Text("O intervalo de avisos é independente das palavras. O Android pode atrasar avisos por economia de bateria. Quando um aviso atrasar, ele traz a palavra vigente na entrega e não acumula os que passaram.", style = MaterialTheme.typography.bodySmall)
            TextButton(onClick = {
                context.startActivity(Intent(AndroidSettings.ACTION_APP_NOTIFICATION_SETTINGS).putExtra(AndroidSettings.EXTRA_APP_PACKAGE, context.packageName))
            }) { Text("Abrir ajustes de notificações") }
        }
        SettingsCard("Leitura e aparência") {
            SettingToggle("Exibir kanji", draft.showKanji) { draft = draft.copy(showKanji = it) }
            SettingToggle("Exibir hiragana", draft.showKana) { draft = draft.copy(showKana = it) }
            SettingToggle("Exibir romaji", draft.showRomaji) { draft = draft.copy(showRomaji = it) }
            SettingToggle("Exibir traduções", draft.showMeaning) { draft = draft.copy(showMeaning = it) }
            Choice("Tema", draft.theme, listOf("system" to "Automático", "light" to "Claro", "dark" to "Escuro")) { draft = draft.copy(theme = it) }
            Text("O widget acompanha o tema do sistema e as preferências de leitura. As traduções dos flashcards aparecem ao revelar a resposta.", style = MaterialTheme.typography.bodySmall)
        }
        SettingsCard("Pronúncia e meta") {
            Text("Velocidade da pronúncia")
            Slider(value = draft.speechRate, onValueChange = { draft = draft.copy(speechRate = it) }, valueRange = .4f..1.2f)
            OutlinedButton(onClick = { model.words.firstOrNull()?.let { model.speak(it, draft.speechRate) } }) { Text("Experimentar pronúncia") }
            TextButton(onClick = {
                try { context.startActivity(Intent("com.android.settings.TTS_SETTINGS")) }
                catch (_: android.content.ActivityNotFoundException) { context.startActivity(Intent(AndroidSettings.ACTION_ACCESSIBILITY_SETTINGS)) }
            }) { Text("Configurar voz japonesa offline") }
            Choice("Meta diária", draft.goal, listOf(1,3,5,10,15,20,30,50,100).map { it to "$it palavras" }) { draft = draft.copy(goal = it) }
        }
        SettingsCard("Sobre o Kotoba") {
            Text("Gratuito, sem conta, anúncios ou assinatura. O vocabulário e seu progresso ficam neste aparelho. Não há sincronização nesta versão.")
            Text("Texto ampliado e TalkBack usam os controles nativos. Widgets da tela bloqueada dependem do Android e do fabricante; esta versão oferece o widget de tela inicial redimensionável.", style = MaterialTheme.typography.bodySmall)
            Text("Fuso: ${draft.zone}", style = MaterialTheme.typography.bodySmall)
        }
        Button(enabled = !model.saving, onClick = {
            val minutes = if (rotation == 0) amount.toLongOrNull()?.takeIf { it in 1..10080 }?.times(unit)?.takeIf { it <= 10080 }?.toInt() ?: 0 else rotation
            val updated = draft.copy(rotationMinutes = minutes, notificationMinutes = notification.toIntOrNull() ?: 0)
            try { updated.validate() } catch (error: IllegalArgumentException) { model.message = error.message; return@Button }
            if (updated.notifications && !Notifications.allowed(context) && Build.VERSION.SDK_INT >= 33) {
                model.pendingSettings = updated
                request.launch(Manifest.permission.POST_NOTIFICATIONS)
            } else model.save(updated)
        }, modifier = Modifier.fillMaxWidth()) { Text(if (model.saving) "Salvando…" else "Salvar meu ritmo") }
        Spacer(Modifier.height(12.dp))
    }
}
@Composable private fun SettingsCard(title: String, content: @Composable ColumnScope.() -> Unit) {
    Card { Column(Modifier.fillMaxWidth().padding(22.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
        Text(title, style = MaterialTheme.typography.titleLarge)
        content()
    } }
}
@Composable private fun SettingToggle(label: String, value: Boolean, onChange: (Boolean) -> Unit) {
    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp), verticalAlignment = androidx.compose.ui.Alignment.CenterVertically) {
        Text(label, modifier = Modifier.weight(1f)); Switch(checked = value, onCheckedChange = onChange)
    }
}
@Composable private fun <T> Choice(label: String, value: T, options: List<Pair<T, String>>, onSelect: (T) -> Unit) {
    var expanded by remember { mutableStateOf(false) }
    Column {
        Text(label, style = MaterialTheme.typography.labelMedium)
        Box {
            TextButton(onClick = { expanded = true }) { Text(options.find { it.first == value }?.second ?: value.toString()) }
            DropdownMenu(expanded = expanded, onDismissRequest = { expanded = false }) {
                options.forEach { (key, text) -> DropdownMenuItem(text = { Text(text) }, onClick = { onSelect(key); expanded = false }) }
            }
        }
    }
}
@Composable private fun TimeChoice(label: String, minute: Int, change: (Int) -> Unit) {
    val context = LocalContext.current
    TextButton(onClick = { TimePickerDialog(context, { _, hour, min -> change(hour * 60 + min) }, minute / 60, minute % 60, true).show() }) {
        Text("$label: %02d:%02d".format(minute / 60, minute % 60))
    }
}
