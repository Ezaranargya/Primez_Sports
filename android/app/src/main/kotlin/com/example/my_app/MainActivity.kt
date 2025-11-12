package com.example.my_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import android.content.Intent
import android.os.Bundle
import android.util.Log

class MainActivity: FlutterActivity() {
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }
    
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        Log.d("MainActivity", "🔗 onNewIntent called with: ${intent.data}")
        setIntent(intent)
        handleIntent(intent)
        
        // PENTING: Notify Flutter tentang intent baru
        flutterEngine?.let { engine ->
            engine.platformViewsController
            Log.d("MainActivity", "🔗 Flutter engine notified about new intent")
        }
    }
    
    private fun handleIntent(intent: Intent?) {
        val action: String? = intent?.action
        val data = intent?.data
        
        Log.d("MainActivity", "🔗 handleIntent called")
        Log.d("MainActivity", "   Action: $action")
        Log.d("MainActivity", "   Data: $data")
        
        if (Intent.ACTION_VIEW == action && data != null) {
            Log.d("MainActivity", "✅ Deep Link detected in MainActivity: $data")
            // Intent akan otomatis di-handle oleh app_links plugin
        } else {
            Log.d("MainActivity", "⚠️ No deep link data in intent")
        }
    }
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        Log.d("MainActivity", "🔗 Flutter Engine configured")
    }
}