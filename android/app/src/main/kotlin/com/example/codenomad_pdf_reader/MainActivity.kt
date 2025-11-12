package com.example.codenomad_pdf_reader

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.provider.OpenableColumns
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
                else -> result.notImplemented()
            }
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
