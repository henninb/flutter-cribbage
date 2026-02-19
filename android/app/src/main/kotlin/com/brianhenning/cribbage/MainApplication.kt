package com.brianhenning.cribbage

import android.app.Application

class MainApplication : Application() {

    override fun onCreate() {
        super.onCreate()
        HumanManager.start(this)
    }
}
