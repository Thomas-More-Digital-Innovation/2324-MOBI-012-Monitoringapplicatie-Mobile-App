package com.example.monitoringapplicatie

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

import android.content.Context
import android.content.ContextWrapper
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.Build.VERSION
import android.os.Build.VERSION_CODES

import android.util.Log
import com.xsens.dot.android.sdk.DotSdk
import com.xsens.dot.android.sdk.utils.DotScanner
import com.xsens.dot.android.sdk.interfaces.DotScannerCallback
import android.bluetooth.BluetoothDevice
import android.bluetooth.le.ScanSettings
import android.content.pm.PackageManager
import android.Manifest
import android.os.Build
import androidx.core.app.ActivityCompat



class MainActivity: FlutterActivity(), DotScannerCallback{
  private val CHANNEL = "samples.flutter.dev/battery"

  private var mXsScanner: DotScanner? = null

  // A variable for scanning flag
  private var mIsScanning = false


  override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
        // This method is invoked on the main thread.
        call, result ->
        when (call.method) {
             "getBatteryLevel" -> {
              val batteryLevel = getBatteryLevel()

              if (batteryLevel != -1) {
              result.success(batteryLevel)
              } else {
              result.error("UNAVAILABLE", "Battery level not available.", null)
              }}
              "movella" -> {
                  val status = initMovellaDotSdk()
                  initXsScanner()
                  //This permission is only required in Android S or higher
                  if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && ActivityCompat.checkSelfPermission(
                          this@MainActivity,
                          Manifest.permission.BLUETOOTH_SCAN
                      ) != PackageManager.PERMISSION_GRANTED
                  ) {
                      ActivityCompat.requestPermissions(this@MainActivity, arrayOf(Manifest.permission.BLUETOOTH_SCAN), 1000)
                  } else {
                      mIsScanning = if (mXsScanner == null) false else mXsScanner!!.startScan()
                  }
                  // mXsScanner!!.startScan()
                  result.success("$status, $mIsScanning")
              }
              "movella_stop" -> {
                  mIsScanning = !mXsScanner!!.stopScan()
                  result.success("$mIsScanning")
              }
        else -> {
            result.notImplemented()
        }
      } 
    }
  }

  private fun getBatteryLevel(): Int {
  val batteryLevel: Int
  if (VERSION.SDK_INT >= VERSION_CODES.LOLLIPOP) {
    val batteryManager = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
    batteryLevel = batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
  } else {
    val intent = ContextWrapper(applicationContext).registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
    batteryLevel = intent!!.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) * 100 / intent.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
  }

  return batteryLevel
}

    

    override fun onDotScanned(device: BluetoothDevice, rssi: Int) {
      Log.i(TAG, "onXsensDotScanned() - Name: " + device.getName() + ", Address: " + device.getAddress());
        // if (isAdded) {

        //     // Use the mac address as UID to filter the same scan result.
        //     var isExist = false
        //     for (map in mScannedSensorList) {
        //         if ((map[ScanAdapter.KEY_DEVICE] as BluetoothDevice?)!!.address == device.address) isExist = true
        //     }
        //     if (!isExist) {

        //         // The original connection state is Disconnected.
        //         // Also set tag, battery state, battery percentage to default value.
        //         val map = HashMap<String, Any>()
        //         map[ScanAdapter.KEY_DEVICE] = device
        //         map[ScanAdapter.KEY_CONNECTION_STATE] = DotDevice.CONN_STATE_DISCONNECTED
        //         map[ScanAdapter.KEY_TAG] = ""
        //         map[ScanAdapter.KEY_BATTERY_STATE] = -1
        //         map[ScanAdapter.KEY_BATTERY_PERCENTAGE] = -1
        //         mScannedSensorList.add(map)
        //         mScanAdapter!!.notifyItemInserted(mScannedSensorList.size - 1)
        //     }
        // }
    }

    /**
     * Setup for Movella DOT SDK.
     */
    private fun initMovellaDotSdk(): String {

        // Get the version name of SDK.
        val version = DotSdk.getSdkVersion()
        Log.i(TAG, "initMovellaDotSdk() - version: $version")

        // Enable this feature to monitor logs from SDK.
        DotSdk.setDebugEnabled(true)
        // Enable this feature then SDK will start reconnection when the connection is lost.
        DotSdk.setReconnectEnabled(true)

        return version
    }


    private fun initXsScanner() {
      // Check Bluetooth permissions at runtime
        if (mXsScanner == null) {
            mXsScanner = DotScanner(context, this)
            mXsScanner!!.setScanMode(ScanSettings.SCAN_MODE_BALANCED)
        }
    }


    companion object {
        private val TAG = MainActivity::class.java.simpleName
    }
}
