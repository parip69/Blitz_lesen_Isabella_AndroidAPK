package de.parip69.blitzlesen

import android.annotation.SuppressLint
import android.content.ContentValues
import android.content.Intent
import android.content.pm.ActivityInfo
import android.graphics.Bitmap
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.provider.MediaStore
import android.webkit.ConsoleMessage
import android.webkit.JavascriptInterface
import android.webkit.MimeTypeMap
import android.webkit.ValueCallback
import android.webkit.WebChromeClient
import android.webkit.WebResourceRequest
import android.webkit.WebResourceResponse
import android.webkit.WebSettings
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.Toast
import androidx.activity.OnBackPressedCallback
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.FileProvider
import androidx.core.view.ViewCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import de.parip69.blitzlesen.databinding.ActivityMainBinding
import java.io.ByteArrayInputStream
import java.io.File
import org.json.JSONObject

class MainActivity : AppCompatActivity() {

    private lateinit var binding: ActivityMainBinding
    private var fileUploadCallback: ValueCallback<Array<Uri>>? = null
    private var latestBottomInsetPx: Int = 0
    private val androidInterface = AndroidInterface()

    private val fileChooserLauncher = registerForActivityResult(
        ActivityResultContracts.OpenDocument()
    ) { uri: Uri? ->
        fileUploadCallback?.onReceiveValue(
            if (uri != null) arrayOf(uri) else emptyArray()
        )
        fileUploadCallback = null
    }

    private fun resolveMimeTypeForFileName(
        fileName: String,
        fallbackMimeType: String = "text/plain"
    ): String {
        val extension = fileName.substringAfterLast('.', "").lowercase()
        if (extension.isEmpty()) return fallbackMimeType
        return when (extension) {
            "html", "htm" -> "text/html"
            "json" -> "application/json"
            else -> MimeTypeMap.getSingleton().getMimeTypeFromExtension(extension) ?: fallbackMimeType
        }
    }

    private fun saveBytesToDownloads(fileName: String, bytes: ByteArray, mimeType: String): Boolean {
        val safeFileName = fileName.trim().ifEmpty { "export.txt" }

        return try {
            val savedUri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val resolver = contentResolver
                val values = ContentValues().apply {
                    put(MediaStore.MediaColumns.DISPLAY_NAME, safeFileName)
                    put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
                    put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
                    put(MediaStore.MediaColumns.IS_PENDING, 1)
                }

                val collection = MediaStore.Downloads.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
                val itemUri = resolver.insert(collection, values)
                    ?: throw IllegalStateException("Datei konnte nicht im Download-Ordner angelegt werden.")

                resolver.openOutputStream(itemUri)?.use { output ->
                    output.write(bytes)
                } ?: throw IllegalStateException("Download-Datei konnte nicht geschrieben werden.")

                values.clear()
                values.put(MediaStore.MediaColumns.IS_PENDING, 0)
                resolver.update(itemUri, values, null, null)
                itemUri
            } else {
                writeLegacyDownloadFile(safeFileName, bytes)
            }

            runOnUiThread {
                Toast.makeText(
                    this,
                    "Datei gespeichert: $safeFileName",
                    Toast.LENGTH_LONG
                ).show()
            }

            true
        } catch (error: Exception) {
            runOnUiThread {
                Toast.makeText(
                    this,
                    "Fehler beim Speichern: ${error.message}",
                    Toast.LENGTH_LONG
                ).show()
            }
            false
        }
    }

    private fun writeLegacyDownloadFile(fileName: String, bytes: ByteArray): Uri {
        val publicDownloads = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
        return try {
            if (!publicDownloads.exists()) {
                publicDownloads.mkdirs()
            }
            val target = File(publicDownloads, fileName)
            target.writeBytes(bytes)
            Uri.fromFile(target)
        } catch (_: Exception) {
            val fallbackDir = getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS) ?: filesDir
            val target = File(fallbackDir, fileName)
            target.parentFile?.mkdirs()
            target.writeBytes(bytes)
            Uri.fromFile(target)
        }
    }

    private fun resolveAppDisplayName(): String {
        return applicationInfo.loadLabel(packageManager).toString()
    }

    private fun resolveAppVersionName(): String {
        return try {
            val packageInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                packageManager.getPackageInfo(
                    packageName,
                    android.content.pm.PackageManager.PackageInfoFlags.of(0)
                )
            } else {
                @Suppress("DEPRECATION")
                packageManager.getPackageInfo(packageName, 0)
            }
            packageInfo.versionName?.takeIf { it.isNotBlank() } ?: BuildConfig.VERSION_NAME
        } catch (_: Exception) {
            BuildConfig.VERSION_NAME
        }
    }

    private fun shareTextFileInternal(fileName: String, content: String) {
        val safeFileName = fileName.trim().ifEmpty { "export.txt" }
        try {
            val downloadDir = getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS) ?: filesDir
            val targetFile = File(downloadDir, safeFileName)
            targetFile.parentFile?.mkdirs()
            targetFile.writeText(content, Charsets.UTF_8)

            val contentUri = FileProvider.getUriForFile(
                this,
                "${packageName}.provider",
                targetFile
            )

            val shareIntent = Intent(Intent.ACTION_SEND).apply {
                type = resolveMimeTypeForFileName(safeFileName)
                putExtra(Intent.EXTRA_STREAM, contentUri)
                putExtra(Intent.EXTRA_SUBJECT, safeFileName)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }

            startActivity(Intent.createChooser(shareIntent, "Datei teilen"))
        } catch (error: Exception) {
            runOnUiThread {
                Toast.makeText(
                    this,
                    "Fehler beim Teilen: ${error.message}",
                    Toast.LENGTH_LONG
                ).show()
            }
        }
    }

    inner class AndroidInterface {
        @JavascriptInterface
        fun saveTextFile(fileName: String, content: String): Boolean {
            return saveBytesToDownloads(
                fileName,
                content.toByteArray(Charsets.UTF_8),
                resolveMimeTypeForFileName(fileName)
            )
        }

        @JavascriptInterface
        fun exportBundledIndexHtml(fileName: String): Boolean {
            return try {
                val htmlBytes = assets.open("index.html").use { it.readBytes() }
                saveBytesToDownloads(fileName, htmlBytes, "text/html")
            } catch (error: Exception) {
                runOnUiThread {
                    Toast.makeText(
                        this@MainActivity,
                        "Fehler beim HTML-Export: ${error.message}",
                        Toast.LENGTH_LONG
                    ).show()
                }
                false
            }
        }

        @JavascriptInterface
        fun getBundledIndexHtml(): String {
            return try {
                assets.open("index.html").bufferedReader(Charsets.UTF_8).use { it.readText() }
            } catch (_: Exception) {
                ""
            }
        }

        @JavascriptInterface
        fun getAppDisplayName(): String {
            return resolveAppDisplayName()
        }

        @JavascriptInterface
        fun getAppVersionName(): String {
            return resolveAppVersionName()
        }

        @JavascriptInterface
        fun shareTextFile(fileName: String, content: String) {
            runOnUiThread {
                shareTextFileInternal(fileName, content)
            }
        }
    }

    @SuppressLint("SetJavaScriptEnabled")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE
        WindowCompat.setDecorFitsSystemWindows(window, false)
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)
        hideSystemBars()

        ViewCompat.setOnApplyWindowInsetsListener(binding.root) { _, insets ->
            latestBottomInsetPx = insets.getInsets(WindowInsetsCompat.Type.systemBars()).bottom
            applyPageRuntimeState()
            insets
        }
        ViewCompat.requestApplyInsets(binding.root)

        configureWebView(binding.webView)
        binding.webView.loadUrl("file:///android_asset/index.html")

        binding.swipeRefresh.setOnRefreshListener {
            binding.webView.reload()
        }

        onBackPressedDispatcher.addCallback(this, object : OnBackPressedCallback(true) {
            override fun handleOnBackPressed() {
                if (binding.webView.canGoBack()) {
                    binding.webView.goBack()
                } else {
                    finish()
                }
            }
        })
    }

    override fun onResume() {
        super.onResume()
        hideSystemBars()
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) {
            hideSystemBars()
        }
    }

    @SuppressLint("SetJavaScriptEnabled")
    private fun configureWebView(webView: WebView) {
        val settings = webView.settings
        settings.javaScriptEnabled = true
        settings.domStorageEnabled = true
        settings.databaseEnabled = true
        settings.allowFileAccess = true
        settings.allowContentAccess = true
        settings.loadsImagesAutomatically = true
        settings.mediaPlaybackRequiresUserGesture = false
        settings.setSupportZoom(false)
        settings.builtInZoomControls = false
        settings.displayZoomControls = false
        settings.cacheMode = WebSettings.LOAD_DEFAULT
        settings.useWideViewPort = true
        settings.loadWithOverviewMode = true
        settings.mixedContentMode = WebSettings.MIXED_CONTENT_ALWAYS_ALLOW

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN) {
            settings.allowFileAccessFromFileURLs = true
            settings.allowUniversalAccessFromFileURLs = true
        }

        webView.addJavascriptInterface(androidInterface, "AndroidInterface")
        webView.isVerticalScrollBarEnabled = false
        webView.isHorizontalScrollBarEnabled = false
        webView.webChromeClient = object : WebChromeClient() {
            override fun onConsoleMessage(consoleMessage: ConsoleMessage): Boolean {
                return true
            }

            override fun onShowFileChooser(
                webView: WebView?,
                filePathCallback: ValueCallback<Array<Uri>>?,
                fileChooserParams: FileChooserParams?
            ): Boolean {
                fileUploadCallback?.onReceiveValue(emptyArray())
                fileUploadCallback = filePathCallback
                val acceptTypes = fileChooserParams?.acceptTypes ?: emptyArray()
                val mimeTypes = resolveMimeTypes(acceptTypes)
                try {
                    fileChooserLauncher.launch(mimeTypes)
                } catch (e: Exception) {
                    fileUploadCallback?.onReceiveValue(emptyArray())
                    fileUploadCallback = null
                    return false
                }
                return true
            }
        }

        webView.webViewClient = object : WebViewClient() {
            override fun shouldOverrideUrlLoading(view: WebView?, request: WebResourceRequest?): Boolean {
                return false
            }

            override fun onPageStarted(view: WebView?, url: String?, favicon: Bitmap?) {
                super.onPageStarted(view, url, favicon)
            }

            override fun onPageFinished(view: WebView?, url: String?) {
                super.onPageFinished(view, url)
                applyPageRuntimeState()
                binding.swipeRefresh.isRefreshing = false
            }

            override fun shouldInterceptRequest(view: WebView?, request: WebResourceRequest?): WebResourceResponse? {
                val url = request?.url?.toString() ?: return super.shouldInterceptRequest(view, request)
                return when {
                    url.endsWith("manifest.webmanifest") -> assetResponse("manifest.webmanifest", "application/manifest+json")
                    url.endsWith("sw.js") -> assetResponse("sw.js", "application/javascript")
                    url.contains("/icons/") -> {
                        val name = url.substringAfterLast('/')
                        assetResponse("icons/$name", "image/png")
                    }
                    else -> super.shouldInterceptRequest(view, request)
                }
            }
        }
    }

    private fun assetResponse(assetPath: String, mimeType: String): WebResourceResponse? {
        return try {
            val bytes = assets.open(assetPath).readBytes()
            WebResourceResponse(mimeType, "utf-8", ByteArrayInputStream(bytes))
        } catch (_: Exception) {
            null
        }
    }

    private fun resolveMimeTypes(acceptTypes: Array<String>): Array<String> {
        val mimeTypes = mutableSetOf<String>()
        for (type in acceptTypes) {
            val trimmed = type.trim().lowercase()
            if (trimmed.isEmpty()) continue
            if (trimmed.contains("/")) {
                mimeTypes.add(trimmed)
            } else {
                val ext = trimmed.removePrefix(".")
                val resolved = MimeTypeMap.getSingleton().getMimeTypeFromExtension(ext)
                if (resolved != null) mimeTypes.add(resolved)
                if (ext == "json") mimeTypes.add("text/plain")
            }
        }
        return if (mimeTypes.isEmpty()) arrayOf("*/*") else mimeTypes.toTypedArray()
    }

    private fun applyPageRuntimeState() {
        if (!::binding.isInitialized) return
        val runtimeScript = """
            (function() {
                var version = ${JSONObject.quote(resolveAppVersionName())};
                var footer = document.querySelector('.footer-note');
                if (footer) {
                    footer.setAttribute('data-app-version', version);
                }
                var root = document.documentElement;
                root.setAttribute('data-app-version', version);
                root.setAttribute('data-native-app', 'android');
                root.style.setProperty('--android-bottom-inset', '${latestBottomInsetPx}px');
                root.style.setProperty('--bottom-safe-space', '${latestBottomInsetPx}px');
                if (typeof window.__updateBlitzLayout === 'function') {
                    window.__updateBlitzLayout();
                }
                if (typeof window.__updateHtmlExportButton === 'function') {
                    window.__updateHtmlExportButton();
                }
            })();
        """.trimIndent()
        binding.webView.evaluateJavascript(runtimeScript, null)
    }

    private fun hideSystemBars() {
        if (!::binding.isInitialized) return
        val controller = WindowCompat.getInsetsController(window, binding.root)
        controller.systemBarsBehavior =
            WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
        controller.hide(WindowInsetsCompat.Type.systemBars())
    }

    override fun onDestroy() {
        binding.webView.destroy()
        super.onDestroy()
    }
}
