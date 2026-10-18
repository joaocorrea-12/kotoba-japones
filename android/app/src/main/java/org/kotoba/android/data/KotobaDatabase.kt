package org.kotoba.android.data

import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper
import org.kotoba.android.domain.AppState

/** Uma transação publica o estado completo. App, alarme e widget usam o mesmo repositório/processo. */
class KotobaDatabase(context: Context, name: String = "kotoba-v1.db") : SQLiteOpenHelper(context, name, null, 1) {
    override fun onCreate(db: SQLiteDatabase) { db.execSQL("CREATE TABLE app_state (id INTEGER PRIMARY KEY CHECK(id = 1), json TEXT NOT NULL)") }
    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) { error("Uma migração explícita é necessária; os dados não serão apagados.") }
    fun load(): AppState? = readableDatabase.rawQuery("SELECT json FROM app_state WHERE id = 1", null).use { cursor ->
        if (cursor.moveToFirst()) StateCodec.decode(cursor.getString(0)) else null
    }
    fun save(state: AppState) {
        state.schedule.validate()
        val json = StateCodec.encode(state)
        writableDatabase.apply {
            beginTransaction()
            try { execSQL("INSERT OR REPLACE INTO app_state (id,json) VALUES (1,?)", arrayOf(json)); setTransactionSuccessful() }
            finally { endTransaction() }
        }
    }
}
