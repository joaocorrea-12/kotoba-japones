package org.kotoba.android.services

import android.content.Context
import android.speech.tts.TextToSpeech
import java.util.Locale

class JapaneseSpeech(context: Context, private val error: (String) -> Unit) {
    private var ready = false
    private var engine: TextToSpeech? = null
    init {
        engine = TextToSpeech(context.applicationContext) { status -> ready = status == TextToSpeech.SUCCESS }
    }
    fun speak(text: String, rate: Float) {
        val tts = engine
        if (!ready || tts == null) { error("A voz ainda está sendo preparada. Tente novamente."); return }
        val voice = tts.voices?.filter { it.locale.language == Locale.JAPANESE.language && !it.isNetworkConnectionRequired }
            ?.sortedBy { it.name }?.firstOrNull()
        if (voice == null) { error("Instale uma voz japonesa offline nos ajustes de conversão de texto em voz do Android."); return }
        tts.voice = voice
        tts.setSpeechRate(rate)
        if (tts.speak(text, TextToSpeech.QUEUE_FLUSH, null, "kotoba-word") == TextToSpeech.ERROR)
            error("Não foi possível reproduzir a pronúncia. Confira o mecanismo de voz do Android.")
    }
    fun close() { engine?.stop(); engine?.shutdown(); ready = false; engine = null }
}
