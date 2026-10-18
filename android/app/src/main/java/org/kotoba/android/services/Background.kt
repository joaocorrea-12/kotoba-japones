package org.kotoba.android.services

import android.content.*
import android.util.Log
import androidx.work.*
import kotlinx.coroutines.*
import org.kotoba.android.KotobaApplication
import org.kotoba.android.widget.WordWidget
import java.time.ZoneId
import java.util.concurrent.TimeUnit

class ScheduleReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val pending = goAsync()
        CoroutineScope(SupervisorJob() + Dispatchers.IO).launch {
            try {
                val repository = (context.applicationContext as KotobaApplication).repository
                val state = repository.initialize()
                if (intent.action == Intent.ACTION_TIMEZONE_CHANGED && state.schedule.settings.zone != ZoneId.systemDefault().id)
                    repository.settings(state.schedule.settings.copy(zone = ZoneId.systemDefault().id))
                if (intent.action == Notifications.ACTION) Notifications.deliverAndRenew(context)
                else Notifications.reschedule(context)
                Background.ensure(context)
                WordWidget.update(context)
            } catch (error: Exception) { Log.e("Kotoba", "Não foi possível renovar o cronograma local.", error) }
            finally { pending.finish() }
        }
    }
}

object Background {
    fun ensure(context: Context) {
        val work = PeriodicWorkRequestBuilder<WidgetWorker>(15, TimeUnit.MINUTES).build()
        WorkManager.getInstance(context).enqueueUniquePeriodicWork("kotoba.widgets", ExistingPeriodicWorkPolicy.KEEP, work)
    }
}

class WidgetWorker(context: Context, parameters: WorkerParameters) : CoroutineWorker(context, parameters) {
    override suspend fun doWork(): Result = try {
        (applicationContext as KotobaApplication).repository.initialize()
        WordWidget.update(applicationContext)
        Result.success()
    } catch (_: Exception) { Result.retry() }
}
