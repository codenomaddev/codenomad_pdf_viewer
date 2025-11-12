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
        android.util.Log.d("MainActivity", "onCreate chamado")
        pendingPdfPath = handleIntent(intent)
        if (pendingPdfPath != null) {
            android.util.Log.d("MainActivity", "PDF path no onCreate: $pendingPdfPath")
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        android.util.Log.d("MainActivity", "onNewIntent chamado")
        setIntent(intent)
        pendingPdfPath = handleIntent(intent)

        if (pendingPdfPath != null) {
            android.util.Log.d("MainActivity", "PDF path no onNewIntent: $pendingPdfPath")
        }

        // Notifica o Flutter sobre o novo arquivo
        flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
            MethodChannel(messenger, CHANNEL).invokeMethod("onPdfReceived", pendingPdfPath)
            android.util.Log.d("MainActivity", "Notificação enviada ao Flutter")
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
            // Tenta abrir as configurações específicas do app primeiro
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
            intent.data = Uri.parse("package:$packageName")
            startActivity(intent)

            android.util.Log.d("MainActivity", "Abrindo configurações do app para definir como padrão")
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "Erro ao abrir configurações: ${e.message}")

            // Fallback: tenta abrir configurações gerais de apps
            try {
                val fallbackIntent = Intent(Settings.ACTION_SETTINGS)
                startActivity(fallbackIntent)
            } catch (e2: Exception) {
                android.util.Log.e("MainActivity", "Erro no fallback: ${e2.message}")
            }
        }
    }

    private fun handleIntent(intent: Intent?): String? {
        android.util.Log.d("MainActivity", "handleIntent chamado com action: ${intent?.action}")

        return when (intent?.action) {
            Intent.ACTION_VIEW -> {
                android.util.Log.d("MainActivity", "ACTION_VIEW detectado")
                intent.data?.let { uri ->
                    android.util.Log.d("MainActivity", "URI: $uri")
                    getUriPath(uri)
                }
            }
            Intent.ACTION_SEND -> {
                android.util.Log.d("MainActivity", "ACTION_SEND detectado")
                intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)?.let { uri ->
                    android.util.Log.d("MainActivity", "URI do EXTRA_STREAM: $uri")
                    getUriPath(uri)
                }
            }
            else -> {
                android.util.Log.d("MainActivity", "Nenhuma action reconhecida")
                null
            }
        }
    }

    private fun getUriPath(uri: Uri): String? {
        return try {
            android.util.Log.d("MainActivity", "getUriPath - scheme: ${uri.scheme}, uri: $uri")

            // Para URIs de conteúdo, retorna a URI completa
            val path = if (uri.scheme == "content" || uri.scheme == "file") {
                uri.toString()
            } else {
                uri.path
            }

            android.util.Log.d("MainActivity", "Path retornado: $path")
            path
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "Erro ao processar URI: ${e.message}", e)
            null
        }
    }
}
