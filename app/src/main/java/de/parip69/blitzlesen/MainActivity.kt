package de.parip69.blitzlesen

import android.annotation.SuppressLint
import android.graphics.Bitmap
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.view.View
import android.webkit.ConsoleMessage
import android.webkit.ValueCallback
import android.webkit.WebChromeClient
import android.webkit.WebResourceRequest
import android.webkit.WebResourceResponse
import android.webkit.WebSettings
import android.webkit.WebView
import android.webkit.MimeTypeMap
import android.webkit.WebViewClient
import androidx.activity.OnBackPressedCallback
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import de.parip69.blitzlesen.databinding.ActivityMainBinding
import java.io.ByteArrayInputStream

class MainActivity : AppCompatActivity() {

    private lateinit var binding: ActivityMainBinding
    private var fileUploadCallback: ValueCallback<Array<Uri>>? = null

    private val fileChooserLauncher = registerForActivityResult(
        ActivityResultContracts.OpenDocument()
    ) { uri: Uri? ->
        fileUploadCallback?.onReceiveValue(
            if (uri != null) arrayOf(uri) else emptyArray()
        )
        fileUploadCallback = null
    }

    @SuppressLint("SetJavaScriptEnabled")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)

        window.decorView.systemUiVisibility = (
            View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                    or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
        )

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

    override fun onDestroy() {
        binding.webView.destroy()
        super.onDestroy()
    }
}
