package com.DuetTalkMNG.DuetTalk

import android.content.Context
import android.view.inputmethod.InputMethodManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "duettalk/keyboard")
            .setMethodCallHandler { call, result ->
                if (call.method == "showPicker") {
                    val imm = getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager
                    imm.showInputMethodPicker()
                    result.success(true)
                } else {
                    result.notImplemented()
                }
            }
    }
}
