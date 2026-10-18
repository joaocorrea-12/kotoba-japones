package org.kotoba.android.ui

import android.app.Application
import androidx.compose.runtime.*
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.*
import org.kotoba.android.KotobaApplication
import org.kotoba.android.domain.*
import org.kotoba.android.services.*
import org.kotoba.android.widget.WordWidget
import java.time.*

class KotobaViewModel(application: Application) : AndroidViewModel(application) {
    private val app = application as KotobaApplication
    private val repository = app.repository
    val state = repository.state
    val words get() = repository.words
    var now by mutableStateOf(Instant.now()); private set
    var message by mutableStateOf<String?>(null)
    var startupError by mutableStateOf<String?>(null); private set
    var selected by mutableStateOf<String?>(null)
    var pendingSettings: Settings? = null
    var saving by mutableStateOf(false); private set
    private val speech = JapaneseSpeech(app) { text -> viewModelScope.launch { message = text } }

    private fun action(block: suspend () -> Unit) = viewModelScope.launch {
        try { block() } catch (error: Exception) {
            if (error is CancellationException) throw error
            message = error.localizedMessage ?: "Não foi possível concluir. Seus dados foram preservados."
        }
    }
    fun activate() = viewModelScope.launch {
        try {
            val value = repository.initialize()
            val zone = ZoneId.systemDefault().id
            if (value.schedule.settings.zone != zone) repository.settings(value.schedule.settings.copy(zone = zone))
            now = Instant.now()
            startupError = null
            refresh()
        } catch (error: Exception) {
            if (error is CancellationException) throw error
            startupError = error.localizedMessage ?: "Não foi possível abrir os dados locais."
        }
    }
    private suspend fun refresh() {
        Background.ensure(app)
        Notifications.reschedule(app)
        withContext(Dispatchers.IO) { WordWidget.update(app) }
    }
    fun tick() { now = Instant.now() }
    fun seen(id: String) = action { repository.seen(id) }
    fun favorite(id: String) = action { repository.favorite(id) }
    fun review(id: String, rating: Rating) = action { repository.review(id, rating); refresh() }
    fun pause() = action { repository.pause(); refresh() }
    fun open(id: String) = action {
        repository.initialize()
        if (words.any { it.id == id }) { selected = id; repository.seen(id) }
    }
    fun speak(word: Word, rate: Float? = null) { speech.speak(word.japanese, rate ?: state.value?.schedule?.settings?.speechRate ?: .8f) }
    fun save(settings: Settings, permissionDenied: Boolean = false) = action {
        saving = true
        try {
            repository.settings(settings)
            refresh()
            message = if (permissionDenied) "Ajustes salvos. Os avisos ficaram desligados porque a permissão não foi concedida." else "Seu ritmo foi salvo."
        } finally { saving = false }
    }
    override fun onCleared() { speech.close(); super.onCleared() }
}
