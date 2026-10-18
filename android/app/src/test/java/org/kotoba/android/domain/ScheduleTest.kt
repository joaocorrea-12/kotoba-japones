package org.kotoba.android.domain

import org.junit.Assert.*
import org.junit.Test
import java.time.Instant

class ScheduleTest {
    private val anchor = Instant.parse("2026-10-16T12:00:00Z")
    private fun schedule(minutes: Int = 10) = Schedule(anchor, listOf("a", "b", "c"), Settings(rotationMinutes = minutes, zone = "UTC"))
    @Test fun boundariesAndWrap() {
        val s = schedule()
        assertEquals("a", s.wordID(anchor.plusSeconds(599)))
        assertEquals("b", s.wordID(anchor.plusSeconds(600)))
        assertEquals("a", s.wordID(anchor.plusSeconds(1800)))
        assertEquals("a", s.wordID(anchor.minusSeconds(1)))
    }
    @Test fun allPresetsAndCustom() {
        (Settings.presets + listOf(1,73,10080)).forEach { minutes ->
            val s = schedule(minutes); s.validate()
            assertEquals("b", s.wordID(anchor.plusSeconds(minutes * 60L)))
            assertEquals(anchor.plusSeconds(minutes * 60L), s.nextChange(anchor))
        }
    }
    @Test fun longAbsenceNeedsNoBackgroundExecution() {
        val s = schedule()
        val now = anchor.plusSeconds(99 * 86400L + 1234)
        assertEquals(s.wordID(now), s.copy().wordID(now))
    }
    @Test fun pausePreservesPartialInterval() {
        var s = schedule().pause(anchor.plusSeconds(300))
        assertNull(s.nextChange(anchor.plusSeconds(9000)))
        assertEquals("a", s.wordID(anchor.plusSeconds(9000)))
        s = s.resume(anchor.plusSeconds(3900))
        assertEquals(anchor.plusSeconds(4200), s.nextChange(anchor.plusSeconds(3900)))
    }
    @Test fun weekendDefersBoundaryToMonday() {
        val s = schedule(60).copy(settings = Settings(rotationMinutes = 60, weekdays = (1..5).toSet(), zone = "UTC"))
        val saturday = Instant.parse("2026-10-17T00:00:00Z")
        val monday = Instant.parse("2026-10-19T00:00:00Z")
        assertEquals(11L, s.slot(saturday))
        assertEquals(monday, s.nextChange(saturday))
        assertEquals(12L, s.slot(monday))
    }
    @Test fun pauseAcrossRestDays() {
        var s = schedule(60).copy(settings = Settings(rotationMinutes = 60, weekdays = (1..5).toSet(), zone = "UTC"))
        s = s.pause(Instant.parse("2026-10-16T23:30:00Z")).resume(Instant.parse("2026-10-19T00:30:00Z"))
        assertEquals(Instant.parse("2026-10-19T01:00:00Z"), s.nextChange(Instant.parse("2026-10-19T00:30:00Z")))
    }
    @Test fun springAndFallDaylightSaving() {
        val s = schedule().copy(settings = Settings(zone = "America/New_York"))
        assertEquals(23 * 3600.0, s.activeSeconds(Instant.parse("2026-03-08T05:00:00Z"), Instant.parse("2026-03-09T04:00:00Z")), .001)
        assertEquals(25 * 3600.0, s.activeSeconds(Instant.parse("2026-11-01T04:00:00Z"), Instant.parse("2026-11-02T05:00:00Z")), .001)
    }
    @Test fun notificationsAreIndependent() {
        val s = schedule().copy(settings = Settings(rotationMinutes = 10, notificationMinutes = 60, notifications = true, quiet = false, zone = "UTC"))
        assertEquals(anchor.plusSeconds(3600), s.nextNotification(anchor))
        assertEquals(6L, s.slot(anchor.plusSeconds(3600)))
    }
    @Test fun notificationSilenceAndWeekdays() {
        val s = schedule().copy(settings = Settings(notifications = true, weekdays = (1..5).toSet(), zone = "UTC"))
        assertEquals(Instant.parse("2026-10-19T08:00:00Z"), s.nextNotification(Instant.parse("2026-10-16T21:00:00Z")))
    }
    @Test fun daytimeQuietBoundaries() {
        val p = Settings(zone = "UTC", quietStart = 720, quietEnd = 840)
        assertFalse(p.allowsNotification(anchor))
        assertTrue(p.allowsNotification(anchor.plusSeconds(7200)))
    }
    @Test fun disabledAndPausedHaveNoAlarm() {
        assertNull(schedule().nextNotification(anchor))
        val s = schedule().copy(settings = Settings(notifications = true, zone = "UTC"))
        assertNull(s.pause(anchor).nextNotification(anchor))
    }
    @Test fun invalidValuesRejected() {
        listOf(Settings(rotationMinutes = 0), Settings(notificationMinutes = 10081), Settings(weekdays = emptySet()), Settings(quietStart = 1, quietEnd = 1)).forEach {
            assertThrows(IllegalArgumentException::class.java) { it.validate() }
        }
        assertThrows(IllegalArgumentException::class.java) { schedule().copy(ids = emptyList()).validate() }
    }
    @Test fun stableHashMatchesSwiftAndJavaScript() { assertEquals(9766424910215455371uL, Deck.hash("kotoba")) }
    @Test fun historicalIDsDoNotCountAsStudy() {
        val state = AppState(schedule())
        assertEquals(listOf("c", "b", "a"), state.schedule.recent(anchor.plusSeconds(1200)))
        assertTrue(state.records.isEmpty())
    }
    @Test fun reviewGoodAndLapse() {
        var r = Review(anchor).rate(Rating.GOOD, anchor)
        assertEquals(1.0, r.interval, .0001)
        r = r.rate(Rating.GOOD, r.due)
        assertEquals(3.0, r.interval, .0001)
        repeat(4) { r = r.rate(Rating.GOOD, r.due) }
        assertTrue(r.mastered)
        r = r.rate(Rating.AGAIN, anchor)
        assertEquals(anchor.plusSeconds(600), r.due)
        assertFalse(r.mastered)
        assertEquals(1, r.lapses)
    }
    @Test fun reviewEaseAndIntervalCaps() {
        var r = Review(anchor)
        repeat(50) { r = r.rate(Rating.HARD, anchor) }
        assertEquals(1.3, r.ease, .0001)
        repeat(50) { r = r.rate(Rating.EASY, anchor) }
        assertEquals(365.0, r.interval, .0001)
        assertEquals(3.0, r.ease, .0001)
    }
}
