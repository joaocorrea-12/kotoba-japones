package org.kotoba.android.data

import android.content.Context
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import org.kotoba.android.domain.*
import java.time.*
import kotlin.random.Random

class Repository(private val context: Context) {
    private val database = KotobaDatabase(context)
    private val mutex = Mutex()
    private val mutableState = MutableStateFlow<AppState?>(null)
    val state = mutableState.asStateFlow()
    var words: List<Word> = emptyList(); private set

    suspend fun initialize(): AppState = withContext(Dispatchers.IO) { mutex.withLock {
        mutableState.value?.let { return@withLock it }
        words = context.assets.open("words.json").bufferedReader().use { StateCodec.words(it.readText()) }
        require(words.size >= 100 && words.map { it.id }.distinct().size == words.size) { "O vocabulário não pôde ser validado." }
        val loaded = database.load()
        val value = loaded ?: AppState(Schedule(Instant.now(), words.map { it.id }, seed = Random.nextLong(1, Long.MAX_VALUE)))
        value.schedule.validate()
        require(value.schedule.ids.all { id -> words.any { it.id == id } }) { "O cronograma contém palavras indisponíveis. Seus dados foram preservados." }
        if (loaded == null) database.save(value)
        mutableState.value = value
        value
    } }
    private suspend fun change(transform: (AppState) -> AppState) {
        initialize()
        withContext(Dispatchers.IO) { mutex.withLock {
            val next = transform(checkNotNull(mutableState.value))
            database.save(next) // Só publica à interface depois de salvar com sucesso.
            mutableState.value = next
        } }
    }
    private fun record(state: AppState, id: String, now: Instant) = state.records[id] ?: Record(id, false, now, now, Review(now))
    suspend fun seen(id: String, now: Instant = Instant.now()) = change { state ->
        val zone = ZoneId.of(state.schedule.settings.zone)
        val day = now.atZone(zone).toLocalDate()
        if (state.activities.any { it.wordID == id && it.at.atZone(zone).toLocalDate() == day }) state
        else state.copy(records = state.records + (id to record(state, id, now).copy(lastSeen = now)), activities = state.activities + Activity(id, now, "leitura"))
    }
    suspend fun favorite(id: String) = change { state ->
        val r = record(state, id, Instant.now())
        state.copy(records = state.records + (id to r.copy(favorite = !r.favorite)))
    }
    suspend fun review(id: String, rating: Rating, now: Instant = Instant.now()) = change { state ->
        val r = record(state, id, now)
        val review = r.review.rate(rating, now)
        val updated = state.copy(records = state.records + (id to r.copy(lastSeen = now, review = review, reviews = r.reviews + 1)), activities = state.activities + Activity(id, now, "revisão"))
        if (r.review.mastered != review.mastered) rebuild(updated, state.schedule.settings, now) else updated
    }
    suspend fun pause(now: Instant = Instant.now()) = change { state ->
        state.copy(schedule = if (state.schedule.pausedAt == null) state.schedule.pause(now) else state.schedule.resume(now))
    }
    suspend fun settings(settings: Settings, now: Instant = Instant.now()) {
        settings.validate()
        change { state ->
            val old = state.schedule.settings
            if (old.rotationMinutes != settings.rotationMinutes || old.weekdays != settings.weekdays || old.zone != settings.zone || old.level != settings.level || old.random != settings.random)
                rebuild(state, settings, now)
            else state.copy(schedule = state.schedule.copy(settings = settings,
                notificationAnchor = if (old.notificationMinutes != settings.notificationMinutes) now else state.schedule.notificationAnchor))
        }
    }
    private fun rebuild(state: AppState, settings: Settings, now: Instant): AppState {
        var ids = Deck.ids(words, settings, state.records.values.filter { it.review.mastered }.map { it.wordID }.toSet(), state.schedule.seed)
        val index = ids.indexOf(state.schedule.wordID(now))
        if (index >= 0) ids = ids.drop(index) + ids.take(index)
        var schedule = Schedule(now, ids, settings, seed = state.schedule.seed)
        if (state.schedule.pausedAt != null) schedule = schedule.pause(now)
        return state.copy(schedule = schedule)
    }
}
