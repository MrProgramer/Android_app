package com.bazargani.mycrm_mobile

import android.app.Activity
import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.bazargani.mycrm/native_file_picker"
    private var pendingResult: MethodChannel.Result? = null
    private val REQUEST_CODE = 4921

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "pickJsonFile") {
                pendingResult = result
                try {
                    val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                        addCategory(Intent.CATEGORY_OPENABLE)
                        type = "*/*"
                        val mimeTypes = arrayOf(
                            "application/json",
                            "text/plain",
                            "application/octet-stream",
                            "*/*"
                        )
                        putExtra(Intent.EXTRA_MIME_TYPES, mimeTypes)
                    }
                    startActivityForResult(intent, REQUEST_CODE)
                } catch (e: Exception) {
                    try {
                        val fallbackIntent = Intent(Intent.ACTION_GET_CONTENT).apply {
                            type = "*/*"
                        }
                        startActivityForResult(fallbackIntent, REQUEST_CODE)
                    } catch (e2: Exception) {
                        result.error("PICKER_ERROR", e2.message, null)
                        pendingResult = null
                    }
                }
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_CODE) {
            val res = pendingResult
            pendingResult = null
            if (resultCode == Activity.RESULT_OK && data?.data != null) {
                try {
                    val uri: Uri = data.data!!
                    val inputStream = contentResolver.openInputStream(uri)
                    if (inputStream != null) {
                        val content = inputStream.bufferedReader().use { it.readText() }
                        res?.success(content)
                    } else {
                        res?.error("NO_DATA", "Could not open file", null)
                    }
                } catch (e: Exception) {
                    res?.error("READ_FAIL", e.message, null)
                }
            } else {
                res?.success(null)
            }
        }
    }
}
