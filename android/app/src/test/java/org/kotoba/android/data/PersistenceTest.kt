package org.kotoba.android.data

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.kotoba.android.domain.*
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import java.time.Instant

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class PersistenceTest {
    private val now = Instant.parse("2026-10-17T12:00:00Z")
    private fun state(): AppState {
        val s = Schedule(now, listOf("k001", "k002"), Settings(zone = "UTC"))
        val record = Record("k001", true, now, now, Review(now).rate(Rating.GOOD, now), 1)
        return AppState(s, mapOf(record.wordID to record), listOf(Activity("k001", now, "revisão")))
    }
    @Test fun snapshotRoundTripIncludesPreferencesFavoriteAndReview() {
        assertEquals(state(), StateCodec.decode(StateCodec.encode(state())))
    }
    @Test fun sqliteSurvivesClosingAndReopening() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        val name = "contract-test.db"
        context.deleteDatabase(name)
        KotobaDatabase(context, name).use { it.save(state()) }
        KotobaDatabase(context, name).use { assertEquals(state(), it.load()) }
        context.deleteDatabase(name)
    }
    @Test fun invalidSettingsDoNotOverwritePersistedData() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        val name = "invalid-test.db"
        context.deleteDatabase(name)
        KotobaDatabase(context, name).use { db ->
            db.save(state())
            val invalid = state().copy(schedule = state().schedule.copy(settings = Settings(weekdays = emptySet())))
            assertThrows(IllegalArgumentException::class.java) { db.save(invalid) }
            assertEquals(state(), db.load())
        }
        context.deleteDatabase(name)
    }
    @Test fun bundledVocabularyHasCompleteUniqueEntries() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        val words = context.assets.open("words.json").bufferedReader().use { StateCodec.words(it.readText()) }
        assertEquals(121, words.size)
        assertEquals(words.size, words.map { it.id }.distinct().size)
        assertTrue(words.all { it.kana.isNotBlank() && it.meaning.isNotBlank() && it.example.isNotBlank() && it.exampleMeaning.isNotBlank() })
    }
    @Test fun incompatibleVersionIsRejected() {
        assertThrows(IllegalArgumentException::class.java) { StateCodec.decode(StateCodec.encode(state()).replace("\"version\":1", "\"version\":999")) }
    }
}
