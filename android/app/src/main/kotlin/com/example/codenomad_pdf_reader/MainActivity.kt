package com.example.codenomad_pdf_reader

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.OpenableColumns
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "pdf_reader_channel"
    private var pendingPdfPath: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        pendingPdfPath = handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        pendingPdfPath = handleIntent(intent)

        // Notifica o Flutter sobre o novo arquivo
        flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
            MethodChannel(messenger, CHANNEL).invokeMethod("onPdfReceived", pendingPdfPath)
        }
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getPdfPathAndroid" -> {
                    result.success(pendingPdfPath)
                    pendingPdfPath = null // Limpa após consumir
                }
                "openDefaultAppSettings" -> {
                    openDefaultAppSettings()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun openDefaultAppSettings() {
        try {
            // Para Android 7.0+ (API 24+)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                val intent = Intent(Settings.ACTION_MANAGE_DEFAULT_APPS_SETTINGS)
                startActivity(intent)
            } else {
                // Para versões anteriores, abre as configurações gerais do app
                val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                intent.data = Uri.parse("package:$packageName")
                startActivity(intent)
            }
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "Erro ao abrir configurações: ${e.message}")
        }
    }

    private fun handleIntent(intent: Intent?): String? {
        return when (intent?.action) {
            Intent.ACTION_VIEW -> {
                intent.data?.let { uri -> getUriPath(uri) }
            }
            Intent.ACTION_SEND -> {
                intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)?.let { uri ->
                    getUriPath(uri)
                }
            }
            else -> null
        }
    }

    private fun getUriPath(uri: Uri): String? {
        return try {
            // Para URIs de conteúdo, retorna a URI completa
            if (uri.scheme == "content" || uri.scheme == "file") {
                uri.toString()
            } else {
                uri.path
            }
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "Erro ao processar URI: ${e.message}")
            null
        }
    }
}
