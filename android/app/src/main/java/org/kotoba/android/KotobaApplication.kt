package org.kotoba.android

import android.app.Application
import org.kotoba.android.data.Repository

class KotobaApplication : Application() {
    val repository by lazy { Repository(this) }
}
