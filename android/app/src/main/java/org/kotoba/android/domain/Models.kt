package org.kotoba.android.domain

import java.time.*

data class Word(val id: String, val japanese: String, val kana: String, val romaji: String,
                val meaning: String, val partOfSpeech: String, val jlpt: Int,
                val example: String, val exampleMeaning: String, val note: String)

data class Settings(
    val rotationMinutes: Int = 60, val notificationMinutes: Int = 60,
    val notifications: Boolean = false, val quiet: Boolean = true,
    val quietStart: Int = 22 * 60, val quietEnd: Int = 8 * 60,
    val weekdays: Set<Int> = (1..7).toSet(), // ISO: segunda = 1, domingo = 7
    val zone: String = ZoneId.systemDefault().id, val level: Int = 5, val random: Boolean = false,
    val showKanji: Boolean = true, val showKana: Boolean = true,
    val showRomaji: Boolean = false, val showMeaning: Boolean = true,
    val speechRate: Float = 0.8f, val goal: Int = 5, val theme: String = "system"
) {
    fun validate() {
        require(rotationMinutes in 1..10080 && notificationMinutes in 1..10080) { "Escolha intervalos entre 1 minuto e 7 dias." }
        require(weekdays.isNotEmpty() && weekdays.all { it in 1..7 }) { "Selecione pelo menos um dia de estudo." }
        require(level in 1..5 && goal in 1..100 && speechRate in 0.4f..1.2f && theme in setOf("system", "light", "dark")) { "Confira os ajustes informados." }
        require(quietStart in 0..1439 && quietEnd in 0..1439 && (!quiet || quietStart != quietEnd)) { "O início e o fim do silêncio devem ser diferentes." }
        ZoneId.of(zone)
    }
    fun allowsNotification(at: Instant): Boolean {
        val date = at.atZone(ZoneId.of(zone))
        if (date.dayOfWeek.value !in weekdays) return false
        if (!quiet) return true
        val minute = date.hour * 60 + date.minute
        return if (quietStart < quietEnd) minute !in quietStart until quietEnd else minute in quietEnd until quietStart
    }
    companion object { val presets = listOf(10,20,30,40,50,60,120,180,240,360,480,720,1440) }
}

data class Schedule(
    val anchor: Instant, val ids: List<String>, val settings: Settings = Settings(),
    val seed: Long = 1, val pausedAt: Instant? = null, val pausedSeconds: Double = 0.0,
    val notificationAnchor: Instant = anchor
) {
    fun validate() {
        settings.validate()
        require(ids.isNotEmpty() && ids.distinct().size == ids.size && pausedSeconds.isFinite() && pausedSeconds >= 0)
        require(pausedAt == null || pausedAt >= anchor)
    }
    fun activeSeconds(from: Instant, to: Instant): Double {
        val zone = ZoneId.of(settings.zone)
        var cursor = from
        var total = 0.0
        while (cursor < to) {
            val local = cursor.atZone(zone)
            val end = minOf(local.toLocalDate().plusDays(1).atStartOfDay(zone).toInstant(), to)
            if (local.dayOfWeek.value in settings.weekdays) total += Duration.between(cursor, end).toNanos() / 1e9
            cursor = end
        }
        return total
    }
    fun advance(from: Instant, seconds: Double): Instant {
        require(settings.weekdays.isNotEmpty())
        val zone = ZoneId.of(settings.zone)
        var cursor = from
        var remaining = maxOf(0.0, seconds)
        while (true) {
            val local = cursor.atZone(zone)
            val end = local.toLocalDate().plusDays(1).atStartOfDay(zone).toInstant()
            if (local.dayOfWeek.value in settings.weekdays) {
                val available = Duration.between(cursor, end).toNanos() / 1e9
                if (remaining < available) return cursor.plusNanos((remaining * 1e9).toLong())
                remaining -= available
            }
            cursor = end
        }
    }
    fun slot(at: Instant): Long {
        val effective = pausedAt ?: at
        var elapsed = maxOf(0.0, activeSeconds(anchor, effective) - pausedSeconds)
        if (effective.atZone(ZoneId.of(settings.zone)).dayOfWeek.value !in settings.weekdays && elapsed > 0) elapsed -= 0.000001
        return kotlin.math.floor(elapsed / (settings.rotationMinutes * 60.0)).toLong()
    }
    fun wordID(at: Instant): String = ids[((slot(at) % ids.size).toInt())]
    fun nextChange(after: Instant): Instant? {
        if (pausedAt != null) return null
        val elapsed = maxOf(0.0, activeSeconds(anchor, after) - pausedSeconds)
        return advance(maxOf(after, anchor), maxOf(0.0, (slot(after) + 1) * settings.rotationMinutes * 60.0 - elapsed))
    }
    fun pause(at: Instant) = if (pausedAt == null) copy(pausedAt = maxOf(anchor, at)) else this
    fun resume(at: Instant) = pausedAt?.let { copy(pausedAt = null, pausedSeconds = pausedSeconds + activeSeconds(it, maxOf(at, it))) } ?: this
    /** Um único alarme inexato pendente; o receptor programa o próximo e não acumula avisos perdidos. */
    fun nextNotification(after: Instant): Instant? {
        if (!settings.notifications || pausedAt != null) return null
        val step = settings.notificationMinutes * 60L
        val elapsed = maxOf(0L, Duration.between(notificationAnchor, after).seconds)
        var candidate = notificationAnchor.plusSeconds((elapsed / step + 1) * step)
        val horizon = after.plusSeconds(30 * 86400L)
        while (candidate <= horizon) {
            if (settings.allowsNotification(candidate)) return candidate
            candidate = candidate.plusSeconds(step)
        }
        return null
    }
    fun recent(at: Instant, count: Int = 30): List<String> {
        val current = slot(at)
        return (0 until minOf(count.toLong(), current + 1).toInt()).map { ids[((current - it) % ids.size).toInt()] }.distinct()
    }
}

enum class Rating(val title: String) { AGAIN("Novamente"), HARD("Difícil"), GOOD("Bom"), EASY("Fácil") }
data class Review(val due: Instant, val interval: Double = 0.0, val ease: Double = 2.5, val successes: Int = 0, val lapses: Int = 0) {
    val mastered get() = successes >= 5 && interval >= 21
    fun rate(rating: Rating, at: Instant): Review {
        if (rating == Rating.AGAIN) return copy(due = at.plusSeconds(600), interval = 0.0, ease = maxOf(1.3, ease - .2), successes = 0, lapses = lapses + 1)
        val nextEase = when (rating) { Rating.HARD -> maxOf(1.3, ease - .15); Rating.EASY -> minOf(3.0, ease + .15); else -> ease }
        val wins = successes + if (rating == Rating.HARD) 0 else 1
        val days = minOf(365.0, when (rating) {
            Rating.HARD -> maxOf(1.0, interval * 1.2)
            Rating.EASY -> if (interval == 0.0) 4.0 else interval * nextEase * 1.3
            else -> if (interval == 0.0) 1.0 else if (wins == 2) 3.0 else interval * nextEase
        })
        return copy(due = at.plusMillis((days * 86400000).toLong()), interval = days, ease = nextEase, successes = wins)
    }
}
data class Record(val wordID: String, val favorite: Boolean, val firstSeen: Instant, val lastSeen: Instant, val review: Review, val reviews: Int = 0)
data class Activity(val wordID: String, val at: Instant, val kind: String)
data class AppState(val schedule: Schedule, val records: Map<String, Record> = emptyMap(), val activities: List<Activity> = emptyList())

object Deck {
    fun hash(value: String): ULong = value.toByteArray(Charsets.UTF_8).fold(14695981039346656037uL) { h, b -> (h xor b.toUByte().toULong()) * 1099511628211uL }
    fun ids(words: List<Word>, settings: Settings, mastered: Set<String>, seed: Long): List<String> {
        val eligible = words.filter { it.jlpt >= settings.level }
        val learning = eligible.filter { it.id !in mastered }.ifEmpty { eligible }
        return if (!settings.random) learning.map { it.id } else learning.sortedWith(compareBy<Word> { hash("$seed:${it.id}") }.thenBy { it.id }).map { it.id }
    }
}
