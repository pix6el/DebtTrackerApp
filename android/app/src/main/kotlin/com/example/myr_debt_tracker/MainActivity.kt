package com.example.myr_debt_tracker

import android.app.Activity
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val BACKUP_CHANNEL = "com.example.myr_debt_tracker/backup"
        private const val REQUEST_CREATE_BACKUP = 9001
        private const val REQUEST_OPEN_BACKUP = 9002
    }

    private var pendingResult: MethodChannel.Result? = null
    private var pendingContent: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            BACKUP_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "saveJsonFile" -> {
                    if (pendingResult != null) {
                        result.error("BUSY", "Another file operation is in progress", null)
                        return@setMethodCallHandler
                    }
                    val fileName = call.argument<String>("fileName") ?: "myr_debt_backup.json"
                    val content = call.argument<String>("content")
                    if (content == null) {
                        result.error("INVALID_ARGS", "Backup content is missing", null)
                        return@setMethodCallHandler
                    }
                    pendingResult = result
                    pendingContent = content

                    val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                        addCategory(Intent.CATEGORY_OPENABLE)
                        type = "application/json"
                        putExtra(Intent.EXTRA_TITLE, fileName)
                    }
                    try {
                        @Suppress("DEPRECATION")
                        startActivityForResult(intent, REQUEST_CREATE_BACKUP)
                    } catch (e: Exception) {
                        pendingResult = null
                        pendingContent = null
                        result.error("UNAVAILABLE", e.message ?: "Unable to open file saver", null)
                    }
                }

                "pickJsonFile" -> {
                    if (pendingResult != null) {
                        result.error("BUSY", "Another file operation is in progress", null)
                        return@setMethodCallHandler
                    }
                    pendingResult = result

                    val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                        addCategory(Intent.CATEGORY_OPENABLE)
                        type = "*/*"
                        putExtra(
                            Intent.EXTRA_MIME_TYPES,
                            arrayOf("application/json", "text/plain", "application/octet-stream")
                        )
                    }
                    try {
                        @Suppress("DEPRECATION")
                        startActivityForResult(intent, REQUEST_OPEN_BACKUP)
                    } catch (e: Exception) {
                        pendingResult = null
                        result.error("UNAVAILABLE", e.message ?: "Unable to open file picker", null)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    @Suppress("DEPRECATION")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        when (requestCode) {
            REQUEST_CREATE_BACKUP -> {
                val res = pendingResult
                val content = pendingContent
                pendingResult = null
                pendingContent = null

                if (resultCode == Activity.RESULT_OK && data?.data != null && content != null) {
                    try {
                        val uri = data.data!!
                        contentResolver.openOutputStream(uri, "wt")?.use { out ->
                            out.write(content.toByteArray(Charsets.UTF_8))
                            out.flush()
                        } ?: throw IllegalStateException("Unable to open output stream")
                        res?.success(true)
                    } catch (e: Exception) {
                        res?.error("SAVE_FAILED", e.message ?: "Failed to save backup file", null)
                    }
                } else {
                    res?.success(false)
                }
            }

            REQUEST_OPEN_BACKUP -> {
                val res = pendingResult
                pendingResult = null

                if (resultCode == Activity.RESULT_OK && data?.data != null) {
                    try {
                        val uri = data.data!!
                        val text = contentResolver.openInputStream(uri)
                            ?.bufferedReader(Charsets.UTF_8)
                            ?.use { it.readText() }
                            ?: throw IllegalStateException("Unable to open input stream")
                        res?.success(text)
                    } catch (e: Exception) {
                        res?.error("READ_FAILED", e.message ?: "Failed to read backup file", null)
                    }
                } else {
                    res?.success(null)
                }
            }
        }
    }
}
