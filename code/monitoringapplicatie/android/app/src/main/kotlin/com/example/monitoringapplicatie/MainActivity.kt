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
import com.xsens.dot.android.sdk.interfaces.DotDeviceCallback
import com.xsens.dot.android.sdk.events.DotData
import com.xsens.dot.android.sdk.models.*

import android.bluetooth.BluetoothDevice
import android.bluetooth.le.ScanSettings
import android.content.pm.PackageManager
import android.Manifest
import android.os.Build
import androidx.core.app.ActivityCompat

//Voorlopige status:
//2 knoppen op scherm om het bluetooth scanning aan en uit te zetten.
//Wanneer hij aan het scannen is en hij een movella dot sensor vindt
//gaat hij automatisch mee connecteren
//Daarna heb ik 2 knoppen toegevoegd voor het starten en stoppen van de Real Time Measurement
//De measurement is momenteel PAYLOAD_TYPE_HIGH_FIDELITY_WITH_MAG (zie docs bij apendix)

//Wat ik graag nog wil doen
//Code opschonen
//Lijst op frontend(flutter) met alle gevonden devices dat je dan kunt kiezen welke je wilt connecteren
//Juiste data selecteren uit sensoren en kijken hoe we dit in database gaan gooien (met csv of zonder, ...)

class MainActivity: FlutterActivity(), DotScannerCallback, DotDeviceCallback{
  private val CHANNEL = "samples.flutter.dev/battery"

  private var mXsScanner: DotScanner? = null

  // A variable for scanning flag
  private var mIsScanning = false

  // A list contains scanned Bluetooth device
  private val mScannedSensorList = ArrayList<HashMap<String, Any>>()

  private var xsDevice: DotDevice? = null

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
          "movella_init" -> {
            val status = initMovellaDotSdk()
            initXsScanner()
            result.success(status)
          }
          "movella_BLEscan" -> {
            //check if permissions are granted
            if(checkPermissions()){
              mIsScanning = if (mXsScanner == null) false else mXsScanner!!.startScan()
            }
            result.success("$mIsScanning")
          }
          "movella_stop" -> {
            mIsScanning = !mXsScanner!!.stopScan()
            Log.i(TAG, "$mScannedSensorList")
            result.success("$mIsScanning, $mScannedSensorList")
            
          }
          "movella_measurementStart" -> {
            xsDevice?.setMeasurementMode(DotPayload.PAYLOAD_TYPE_HIGH_FIDELITY_WITH_MAG); 
            xsDevice?.startMeasuring();
            result.success("started")
            
          }
          "movella_measurementStop" -> {
            xsDevice?.stopMeasuring();
            result.success("stopped")
            
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

private fun checkPermissions(): Boolean {
  //This permission is only required in Android S or higher
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
        (ActivityCompat.checkSelfPermission(
            this@MainActivity,
            Manifest.permission.BLUETOOTH_SCAN
        ) != PackageManager.PERMISSION_GRANTED ||
                ActivityCompat.checkSelfPermission(
                    this@MainActivity,
                    Manifest.permission.BLUETOOTH_CONNECT
                ) != PackageManager.PERMISSION_GRANTED ||
                ActivityCompat.checkSelfPermission(
                    this@MainActivity,
                    Manifest.permission.ACCESS_FINE_LOCATION
                ) != PackageManager.PERMISSION_GRANTED)
    ) {
        ActivityCompat.requestPermissions(
            this@MainActivity,
            arrayOf(
                Manifest.permission.BLUETOOTH_SCAN,
                Manifest.permission.BLUETOOTH_CONNECT,
                Manifest.permission.ACCESS_FINE_LOCATION
            ),
            1000
        )
    }
    else{
      return true
    }
    return false
  }


override fun onDotScanned(device: BluetoothDevice, rssi: Int) {
  Log.i(TAG, "onDotScanned() - Name: ${device.name}, Address: ${device.address}")
  xsDevice = DotDevice(applicationContext, device, this@MainActivity)
  xsDevice?.connect();
  // Your logic for handling the scanned device
  // For example, add the device to a list or perform some other action

  // Use the mac address as UID to filter the same scan result.
  
  var isExist = false
  for (map in mScannedSensorList) {
      if ((map["device"] as BluetoothDevice?)?.address == device.address) {
          isExist = true
          break
      }
  }

  if (!isExist) {
      // The original connection state is Disconnected.
      // Also set tag, battery state, battery percentage to default value.
      //kan dit zo? want dan kan ik het decoden als json aan flutter kant
      //"$map["device"]"" : "$device"
      val map = HashMap<String, Any>()
      map["device"] = device
      map["connectionState"] = DotDevice.CONN_STATE_DISCONNECTED
      map["tag"] = ""
      map["batteryState"] = -1
      map["batteryPercentage"] = -1

      mScannedSensorList.add(map)
      // Notify your application or perform the necessary UI update
  }
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


  override fun onDotConnectionChanged(address: String, state: Int) {
        Log.i(TAG, "onXsensDotConnectionChanged() - address = $address, state = $state")
        // val xsDevice = getSensor(address)
        // if (xsDevice != null) connectionChangedDevice.postValue(xsDevice)
        // when (state) {
        //     DotDevice.CONN_STATE_DISCONNECTED -> synchronized(this) { removeDevice(address) }
        //     DotDevice.CONN_STATE_CONNECTING -> {}
        //     DotDevice.CONN_STATE_CONNECTED -> {}
        //     DotDevice.CONN_STATE_RECONNECTING -> {}
        // }
    }

override fun onDotServicesDiscovered(address: String, status: Int) {
        Log.i(TAG, "onXsensDotServicesDiscovered() - address = $address, status = $status")
    }

override fun onDotFirmwareVersionRead(address: String, version: String) {
        Log.i(TAG, "onXsensDotFirmwareVersionRead() - address = $address, version = $version")
    }

override fun onDotTagChanged(address: String, tag: String) {
        // This callback function will be triggered in the connection precess.
        Log.i(TAG, "onXsensDotTagChanged() - address = $address, tag = $tag")

        // // The default value of tag is an empty string.
        // if (tag != "") {
        //     val device = getSensor(address)
        //     if (device != null) tagChangedDevice.postValue(device)
        // }
    }

override fun onDotDataChanged(address: String, data: DotData) {
        Log.i(TAG, "onXsensDotDataChanged() - address = $address")

        // Don't use LiveData variable to transfer data to activity/fragment.
        // The main (UI) thread isn't fast enough to store data by 60Hz.
        // if (mDataChangeInterface != null) mDataChangeInterface!!.onDataChanged(address, data)
    }

override fun onDotBatteryChanged(address: String, status: Int, percentage: Int) {
        // This callback function will be triggered in the connection precess.
        Log.i(TAG, "onXsensDotBatteryChanged() - address = $address, status = $status, percentage = $percentage")

        // The default value of status and percentage is -1.
        // if (status != -1 && percentage != -1) {
        //     // Use callback function instead of LiveData to notify the battery information.
        //     // Because when user removes the USB cable from housing, this function will be triggered 5 times.
        //     // Use LiveData will lose some notification.
        //     if (mBatteryChangeInterface != null) mBatteryChangeInterface!!.onBatteryChanged(address, status, percentage)
        // }
    }

override fun onDotInitDone(address: String) {
    Log.i(TAG, "onXsensDotInitDone() - address = $address")
}

override fun onDotButtonClicked(address: String, timestamp: Long) {
    Log.i(TAG, "onXsensDotButtonClicked() - address = $address, timestamp = $timestamp")
}

override fun onDotPowerSavingTriggered(address: String) {
    Log.i(TAG, "onXsensDotPowerSavingTriggered() - address = $address")
}

override fun onReadRemoteRssi(address: String, rssi: Int) {
    Log.i(TAG, "onReadRemoteRssi() - address = $address, rssi = $rssi")
}

override fun onDotOutputRateUpdate(address: String, outputRate: Int) {
    Log.i(TAG, "onXsensDotOutputRateUpdate() - address = $address, outputRate = $outputRate")
}

override fun onDotFilterProfileUpdate(address: String, filterProfileIndex: Int) {
    Log.i(TAG, "onXsensDotFilterProfileUpdate() - address = $address, filterProfileIndex = $filterProfileIndex")
}

override fun onDotGetFilterProfileInfo(address: String, filterProfileInfoList: ArrayList<FilterProfileInfo>) {
    Log.i(TAG, "onXsensDotGetFilterProfileInfo() - address = " + address + ", size = " + filterProfileInfoList.size)
}

override fun onSyncStatusUpdate(address: String, isSynced: Boolean) {
    Log.i(TAG, "onSyncStatusUpdate() - address = $address, isSynced = $isSynced")
}



  companion object {
      private val TAG = MainActivity::class.java.simpleName
  }
}

