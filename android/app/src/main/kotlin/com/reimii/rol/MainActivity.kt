package com.reimii.rol

import android.content.ClipData
import android.content.Intent
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val exportChannel = "asteria_rol/export_share"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, exportChannel)
            .setMethodCallHandler { call, result ->
                if (call.method != "shareFile") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }

                try {
                    val path = call.argument<String>("path")
                        ?: throw IllegalArgumentException("Missing export path")
                    val file = File(path).canonicalFile
                    val allowedDirectory = filesDir.canonicalFile
                    if (!file.isFile || !file.toPath().startsWith(allowedDirectory.toPath())) {
                        throw IllegalArgumentException("Export file is not in the app's files directory")
                    }
                    val uri = FileProvider.getUriForFile(
                        this,
                        "${applicationContext.packageName}.export_provider",
                        file,
                    )
                    val intent = Intent(Intent.ACTION_SEND).apply {
                        type = "application/octet-stream"
                        putExtra(Intent.EXTRA_STREAM, uri)
                        putExtra(Intent.EXTRA_SUBJECT, call.argument<String>("subject"))
                        putExtra(Intent.EXTRA_TEXT, call.argument<String>("text"))
                        clipData = ClipData.newRawUri(file.name, uri)
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    }
                    startActivity(Intent.createChooser(intent, "Compartir archivo de Asteria"))
                    result.success(null)
                } catch (error: Exception) {
                    result.error("SHARE_EXPORT_FAILED", error.message, null)
                }
            }
    }
}
