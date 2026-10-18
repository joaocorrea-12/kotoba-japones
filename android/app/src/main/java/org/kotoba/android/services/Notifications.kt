package org.kotoba.android.services

import android.Manifest
import android.annotation.SuppressLint
import android.app.*
import android.content.*
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import org.kotoba.android.*
import java.time.Instant

object Notifications {
    const val ACTION = "org.kotoba.android.WORD_NOTIFICATION"
    private const val CHANNEL = "daily-vocabulary"
    private val mutex = Mutex()
    fun allowed(context: Context): Boolean =
        (Build.VERSION.SDK_INT < 33 || ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED) &&
            context.getSystemService(NotificationManager::class.java).areNotificationsEnabled()

    private fun channel(context: Context) {
        context.getSystemService(NotificationManager::class.java).createNotificationChannel(
            NotificationChannel(CHANNEL, "Encontros com o japonês", NotificationManager.IMPORTANCE_DEFAULT).apply {
                description = "Palavras nos dias e horários escolhidos por você."
                setShowBadge(false)
            })
    }
    private fun alarmIntent(context: Context) = PendingIntent.getBroadcast(context, 41,
        Intent(context, ScheduleReceiver::class.java).setAction(ACTION), PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)

    suspend fun reschedule(context: Context) = mutex.withLock { scheduleLocked(context) }
    private suspend fun scheduleLocked(context: Context) {
        val repository = (context.applicationContext as KotobaApplication).repository
        repository.initialize()
        val schedule = checkNotNull(repository.state.value).schedule
        val manager = context.getSystemService(AlarmManager::class.java)
        val intent = alarmIntent(context)
        manager.cancel(intent)
        if (!allowed(context)) return
        val next = schedule.nextNotification(Instant.now()) ?: return
        // Inexato por projeto: não pede acesso especial a alarmes exatos.
        manager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, next.toEpochMilli(), intent)
    }
    @SuppressLint("MissingPermission") // allowed() verifica a permissão; SecurityException cobre revogação concorrente.
    suspend fun deliverAndRenew(context: Context) = mutex.withLock {
        val repository = (context.applicationContext as KotobaApplication).repository
        repository.initialize()
        val schedule = checkNotNull(repository.state.value).schedule
        val now = Instant.now()
        if (allowed(context) && schedule.settings.notifications && schedule.pausedAt == null && schedule.settings.allowsNotification(now)) {
            val word = repository.words.first { it.id == schedule.wordID(now) }
            val p = schedule.settings
            val open = PendingIntent.getActivity(context, 42,
                Intent(context, MainActivity::class.java).putExtra("wordID", word.id).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            val description = buildList {
                if (p.showKana) add(word.kana)
                if (p.showRomaji) add(word.romaji)
                if (p.showMeaning) add(word.meaning)
            }.joinToString(" · ").ifBlank { "Toque para encontrar sua palavra." }
            channel(context)
            val notification = NotificationCompat.Builder(context, CHANNEL).setSmallIcon(R.drawable.ic_kotoba)
                .setContentTitle(if (p.showKanji) word.japanese else word.kana).setContentText(description)
                .setStyle(NotificationCompat.BigTextStyle().bigText(description)).setContentIntent(open)
                .setAutoCancel(true).setOnlyAlertOnce(false).build()
            // A checagem acima não impede revogação de permissão durante a operação.
            try { context.getSystemService(NotificationManager::class.java).notify(43, notification) }
            catch (_: SecurityException) { /* Revogada pelo usuário; o próximo agendamento também será suspenso. */ }
        }
        scheduleLocked(context)
    }
}
