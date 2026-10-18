package org.kotoba.android.widget

import android.app.PendingIntent
import android.appwidget.*
import android.content.*
import android.view.View
import android.widget.RemoteViews
import kotlinx.coroutines.*
import org.kotoba.android.*
import org.kotoba.android.services.Background
import java.time.Instant

class WordWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) = refresh(context)
    override fun onAppWidgetOptionsChanged(context: Context, manager: AppWidgetManager, id: Int, options: android.os.Bundle) = refresh(context)
    override fun onEnabled(context: Context) { Background.ensure(context) }
    private fun refresh(context: Context) {
        val pending = goAsync()
        CoroutineScope(SupervisorJob() + Dispatchers.IO).launch {
            try { update(context) }
            catch (error: Exception) { android.util.Log.e("Kotoba", "Não foi possível atualizar o widget local.", error) }
            finally { pending.finish() }
        }
    }
    companion object {
        suspend fun update(context: Context) {
            val repository = (context.applicationContext as KotobaApplication).repository
            val state = repository.initialize()
            val word = repository.words.first { it.id == state.schedule.wordID(Instant.now()) }
            val p = state.schedule.settings
            val manager = AppWidgetManager.getInstance(context)
            manager.getAppWidgetIds(ComponentName(context, WordWidget::class.java)).forEach { id ->
                val options = manager.getAppWidgetOptions(id)
                val height = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 150)
                val views = RemoteViews(context.packageName, R.layout.word_widget)
                views.setTextViewText(R.id.widget_word, if (p.showKanji) word.japanese else word.kana)
                views.setTextViewText(R.id.widget_kana, word.kana)
                views.setTextViewText(R.id.widget_romaji, word.romaji)
                views.setTextViewText(R.id.widget_meaning, word.meaning)
                views.setTextViewText(R.id.widget_level, "JLPT N${word.jlpt}")
                views.setTextViewText(R.id.widget_example, word.example + if (p.showMeaning) "\n" + word.exampleMeaning else "")
                views.setViewVisibility(R.id.widget_kana, if (p.showKana) View.VISIBLE else View.GONE)
                views.setViewVisibility(R.id.widget_romaji, if (p.showRomaji && height >= 160) View.VISIBLE else View.GONE)
                views.setViewVisibility(R.id.widget_meaning, if (p.showMeaning) View.VISIBLE else View.GONE)
                views.setViewVisibility(R.id.widget_example, if (height >= 220) View.VISIBLE else View.GONE)
                val open = PendingIntent.getActivity(context, id, Intent(context, MainActivity::class.java).putExtra("wordID", word.id)
                    .addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP), PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
                views.setOnClickPendingIntent(R.id.widget_root, open)
                manager.updateAppWidget(id, views)
            }
        }
    }
}
