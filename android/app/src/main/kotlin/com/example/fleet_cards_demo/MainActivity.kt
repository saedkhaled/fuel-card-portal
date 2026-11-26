package com.example.fleet_cards_demo

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.ClipData
import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private data class PendingSave(
        val mime: String,
        val bytes: ByteArray,
        val result: MethodChannel.Result,
    )

    private var pendingSave: PendingSave? = null
    private val stationLocation = ForegroundStationLocation(this)

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        stationLocation.register(flutterEngine.dartExecutor.binaryMessenger)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.example.fleet_cards_demo/exports")
            .setMethodCallHandler { call, result ->
                if (call.method == "appVersion") {
                    result.success(packageManager.getPackageInfo(packageName, 0).versionName)
                    return@setMethodCallHandler
                }
                if (call.method != "save" && call.method != "share") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val name = call.argument<String>("name")
                val mime = call.argument<String>("mime")
                val bytes = call.argument<ByteArray>("bytes")
                if (name == null || mime == null || bytes == null || name != File(name).name) {
                    result.error("invalid_file", "Missing or invalid file data", null)
                    return@setMethodCallHandler
                }
                if (pendingSave != null) {
                    result.error("busy", "A save request is already open", null)
                    return@setMethodCallHandler
                }
                try {
                    if (call.method == "save") {
                        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                            addCategory(Intent.CATEGORY_OPENABLE)
                            type = mime
                            putExtra(Intent.EXTRA_TITLE, name)
                        }
                        pendingSave = PendingSave(mime, bytes, result)
                        startActivityForResult(intent, saveRequestCode)
                    } else {
                        share(name, mime, bytes)
                        result.success(true)
                    }
                } catch (_: Exception) {
                    pendingSave = null
                    result.error("file_action_failed", "Could not open Android file action", null)
                }
            }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        stationLocation.onPermissionResult(requestCode)
    }

    override fun onDestroy() {
        stationLocation.close()
        super.onDestroy()
    }

    private fun openSavedDocument(uri: Uri, mime: String) {
        val view = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, mime)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        try {
            startActivity(view)
        } catch (_: ActivityNotFoundException) {
            // The document is saved even when the device has no app for this type.
        } catch (_: SecurityException) {
            // A document provider may allow saving without delegating read access.
        }
    }

    private fun share(name: String, mime: String, bytes: ByteArray) {
        val exports = File(cacheDir, "exports")
        check(exports.isDirectory || exports.mkdirs())
        exports.listFiles()?.filter {
            System.currentTimeMillis() - it.lastModified() > 24 * 60 * 60 * 1000L
        }?.forEach { it.deleteRecursively() }

        val directory = File(exports, java.util.UUID.randomUUID().toString())
        check(directory.mkdir())
        val file = File(directory, name).apply { writeBytes(bytes) }
        val uri = FileProvider.getUriForFile(this, "$packageName.exports", file)
        val send = Intent(Intent.ACTION_SEND).apply {
            type = mime
            putExtra(Intent.EXTRA_STREAM, uri)
            clipData = ClipData.newUri(contentResolver, name, uri)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        startActivity(Intent.createChooser(send, null))
    }

    @Deprecated("FlutterActivity delivers the Storage Access Framework result through this callback.")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != saveRequestCode) return
        val pending = pendingSave ?: return
        val uri: Uri? = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            pendingSave = null
            pending.result.success(false)
            return
        }
        Thread {
            try {
                val output = checkNotNull(contentResolver.openOutputStream(uri, "w"))
                output.use { it.write(pending.bytes) }
            } catch (_: Exception) {
                runOnUiThread {
                    pendingSave = null
                    pending.result.error("write_failed", "Could not save document", null)
                }
                return@Thread
            }
            runOnUiThread {
                pendingSave = null
                openSavedDocument(uri, pending.mime)
                pending.result.success(true)
            }
        }.start()
    }

    companion object {
        private const val saveRequestCode = 4310
    }
}
