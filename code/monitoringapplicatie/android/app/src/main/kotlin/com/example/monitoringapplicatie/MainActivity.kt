package com.example.monitoringapplicatie

import androidx.appcompat.app.AppCompatActivity
import com.xsens.dot.android.sdk.DotSdk
import com.xsens.dot.android.sdk.interfaces.DotDeviceCallback
import com.xsens.dot.android.sdk.interfaces.DotScannerCallback
import io.flutter.embedding.android.FlutterActivity

abstract class MainActivity : AppCompatActivity() , DotDeviceCallback, DotScannerCallback {
    private fun initXsSdk() {
        // Get the SDK version
        val version: String = DotSdk.getSdkVersion()

        // Enable debug mode
        DotSdk.setDebugEnabled(true)

        // Enable reconnect feature
        DotSdk.setReconnectEnabled(true)
    }

}


