package org.kotoba.android.data

import org.json.JSONArray
import org.json.JSONObject
import org.kotoba.android.domain.*
import java.time.Instant

object StateCodec {
    private fun time(value: String) = Instant.parse(value)
    private fun strings(array: JSONArray) = (0 until array.length()).map { array.getString(it) }
    fun words(json: String): List<Word> {
        val array = JSONArray(json)
        return (0 until array.length()).map { i -> array.getJSONObject(i).run {
            Word(getString("id"), getString("japanese"), getString("kana"), getString("romaji"), getString("meaning"),
                getString("partOfSpeech"), getInt("jlpt"), getString("example"), getString("exampleMeaning"), getString("note"))
        } }
    }
    fun encode(state: AppState): String {
        val s = state.schedule
        val p = s.settings
        val settings = JSONObject().put("rotationMinutes", p.rotationMinutes).put("notificationMinutes", p.notificationMinutes)
            .put("notifications", p.notifications).put("quiet", p.quiet).put("quietStart", p.quietStart).put("quietEnd", p.quietEnd)
            .put("weekdays", JSONArray(p.weekdays.sorted())).put("zone", p.zone).put("level", p.level).put("random", p.random)
            .put("showKanji", p.showKanji).put("showKana", p.showKana).put("showRomaji", p.showRomaji).put("showMeaning", p.showMeaning)
            .put("speechRate", p.speechRate).put("goal", p.goal).put("theme", p.theme)
        val schedule = JSONObject().put("anchor", s.anchor.toString()).put("ids", JSONArray(s.ids)).put("settings", settings)
            .put("seed", s.seed).put("pausedAt", s.pausedAt?.toString() ?: JSONObject.NULL).put("pausedSeconds", s.pausedSeconds)
            .put("notificationAnchor", s.notificationAnchor.toString())
        val records = JSONArray(state.records.values.map { r -> JSONObject().put("wordID", r.wordID).put("favorite", r.favorite)
            .put("firstSeen", r.firstSeen.toString()).put("lastSeen", r.lastSeen.toString()).put("reviews", r.reviews)
            .put("due", r.review.due.toString()).put("interval", r.review.interval).put("ease", r.review.ease)
            .put("successes", r.review.successes).put("lapses", r.review.lapses) })
        val activities = JSONArray(state.activities.map { JSONObject().put("wordID", it.wordID).put("at", it.at.toString()).put("kind", it.kind) })
        return JSONObject().put("version", 1).put("schedule", schedule).put("records", records).put("activities", activities).toString()
    }
    fun decode(json: String): AppState {
        val root = JSONObject(json)
        require(root.getInt("version") == 1) { "O formato salvo não é compatível. Seus dados não foram substituídos." }
        val s = root.getJSONObject("schedule")
        val p = s.getJSONObject("settings")
        val days = p.getJSONArray("weekdays")
        val settings = Settings(p.getInt("rotationMinutes"), p.getInt("notificationMinutes"), p.getBoolean("notifications"),
            p.getBoolean("quiet"), p.getInt("quietStart"), p.getInt("quietEnd"), (0 until days.length()).map { days.getInt(it) }.toSet(),
            p.getString("zone"), p.getInt("level"), p.getBoolean("random"), p.getBoolean("showKanji"), p.getBoolean("showKana"),
            p.getBoolean("showRomaji"), p.getBoolean("showMeaning"), p.getDouble("speechRate").toFloat(), p.getInt("goal"), p.getString("theme"))
        val schedule = Schedule(time(s.getString("anchor")), strings(s.getJSONArray("ids")), settings, s.getLong("seed"),
            if (s.isNull("pausedAt")) null else time(s.getString("pausedAt")), s.getDouble("pausedSeconds"), time(s.getString("notificationAnchor")))
        schedule.validate()
        val rows = root.getJSONArray("records")
        val records = (0 until rows.length()).map { i -> rows.getJSONObject(i).run {
            Record(getString("wordID"), getBoolean("favorite"), time(getString("firstSeen")), time(getString("lastSeen")),
                Review(time(getString("due")), getDouble("interval"), getDouble("ease"), getInt("successes"), getInt("lapses")), getInt("reviews"))
        } }.associateBy { it.wordID }
        val history = root.getJSONArray("activities")
        val activities = (0 until history.length()).map { i -> history.getJSONObject(i).run { Activity(getString("wordID"), time(getString("at")), getString("kind")) } }
        return AppState(schedule, records, activities)
    }
}
