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
import org.json.JSONObject
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.launch


import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothAdapter
import android.bluetooth.le.ScanSettings
import android.content.pm.PackageManager
import android.Manifest
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.lifecycle.MutableLiveData

//Het doel is dat aan de kotlin kant enkel bluetooth data wordt verstuurd en eventueel status of het gelukt is / waarom het niet gelukt is
//Aan de flutter kant gaan we de data handellen en de status afbeelden

//Voorlopige status:
//2 knoppen op scherm om het bluetooth scanning aan en uit te zetten.
//Daarna heb ik 2 knoppen toegevoegd voor het starten en stoppen van de Real Time Measurement
//De measurement is momenteel DotPayload.PAYLOAD_TYPE_CUSTOM_MODE_4 (zie docs bij apendix)
//Een functie gemaakt die de list met devices convert naar json zodat ik die aan de flutter kant kan uitlezen en displayen
//Aan flutter dat tijdens het searchen de list met gevonden devices automatisch update. Ook 1 knop van start en stop BLE scan
//Knop connecteren aan flutter kant dat hij met de juiste device connect
//Data in DB
//Connection state opvragen met refresh knop
//Tijdens het connecteren wordt de data opgevraagd om te kijken of hij geconnecteerd geraakt + extra data dan opvragen zoals battery

//Wat ik graag nog wil doen
//meerdere sensoren connecteren
//Tijdens meten een loading symbool bij de devices die data aan het zenden zijn
//code opruimen
//??disconnect functionaliteit fixen

//probleem
//De "DotDevice.disconnect()" werkt niet dus voorlopige fix is gewoon de sensor uitzetten en dan disconnect hij direct automatisch
//Ook "DotDevice.cancelReconnecting(); werkt niet daarom heb ik: DotSdk.setReconnectEnabled(false); gezet anders blijft hij constant reconnecten

class MainActivity: FlutterActivity(), DotScannerCallback, DotDeviceCallback{
  private val CHANNEL = "samples.flutter.dev/battery"

  private var mXsScanner: DotScanner? = null

  // A variable for scanning flag
  private var mIsScanning = false

  // A list contains scanned Bluetooth devices -> so you can easily get data in the frontend (because Flutter doesn't know "DotDevice")
  private val mScannedSensorList = ArrayList<HashMap<String, Any>>()

  // A list contains connected XsensDotDevices
  private val mSensorList = MutableLiveData<ArrayList<DotDevice>?>()

  private var xsDevice: DotDevice? = null

  private val dotDataJSON = JSONObject()

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
            }
          }
          "movella_init" -> {
            val status = initMovellaDotSdk()
            initXsScanner()
            result.success(status)
          }
          "movella_start_stop_BLEscan" -> {
            if(!mIsScanning){
              val mBluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
              if (mBluetoothAdapter == null || !mBluetoothAdapter.isEnabled()) {
                result.success(listOf("$mIsScanning", "Error: Please Enable Bluetooth"))
              } else {
                // Bluetooth is enabled 
                //check if permissions are granted
                if(checkPermissions()){
                  //remove all disconnected devices from list
                  val iterator = mScannedSensorList.iterator()
                  while (iterator.hasNext()) {
                      val map = iterator.next()
                      if (map["connectionState"] == 0) {
                          iterator.remove()
                      }
                  }
                  //start scan
                  mIsScanning = if (mXsScanner == null) false else mXsScanner!!.startScan()
                  result.success(listOf("$mIsScanning", "Scan started"))
                }
              }
            }
            else{
              //stop scan
              mIsScanning = !mXsScanner!!.stopScan()
              result.success(listOf("$mIsScanning", "Scan stopped"))
            }
          }
          "movella_getScannedDevices" -> {
            result.success(convertMapToJson(mScannedSensorList))
          }
          "connectSensor" -> {
              val data = call.argument<String>("MacAddress")
              connectToDevice("${data}")
              result.success("connected")

          }
          "movella_measurementStart" -> {
            xsDevice?.setMeasurementMode(DotPayload.PAYLOAD_TYPE_CUSTOM_MODE_4); 
            xsDevice?.startMeasuring();
            result.success("started")
          }
          "movella_measurementStop" -> {
            xsDevice?.stopMeasuring();
            result.success(listOf("stopped", dotDataJSON.toString()))
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
      val map = HashMap<String, Any>()
      map["device"] = device
      map["connectionState"] = DotDevice.CONN_STATE_DISCONNECTED
      map["tag"] = ""
      map["batteryState"] = -1
      map["batteryPercentage"] = -1

      mScannedSensorList.add(map)
  }
}


private fun convertMapToJson(list: ArrayList<HashMap<String, Any>>): String {
    val jsonList = mutableListOf<JSONObject>()
    val globalObject = JSONObject()

    for (map in list) {
        val deviceObject = JSONObject()

        deviceObject.put("device", (map["device"] as BluetoothDevice?)?.address)
        deviceObject.put("connectionState", map["connectionState"])
        deviceObject.put("tag", map["tag"])
        deviceObject.put("batteryState", map["batteryState"])
        deviceObject.put("batteryPercentage", map["batteryPercentage"])

        jsonList.add(deviceObject)
    }
    globalObject.put("devices", jsonList)
    return globalObject.toString()
}

private fun connectToDevice(address: String){
  val devices = mScannedSensorList
  if (devices != null) {
        for (device in devices) {
            // Check if the device is a DotDevice and its address matches
            if (((device["device"] as BluetoothDevice?)?.address) == address) {
                addDevice(DotDevice(applicationContext, device["device"] as BluetoothDevice?, this@MainActivity)) //add in list with connected sensors
                DotDevice(applicationContext, device["device"] as BluetoothDevice?, this@MainActivity)?.connect(); //connect sensor
                println(DotDevice(applicationContext, device["device"] as BluetoothDevice?, this@MainActivity)?.batteryPercentage)
            }
        }
    }
}

// //update the data of the scanned bluetooth devices
//  //Blijkt dat je manueel de data moet updaten van de DotDevice dus is dit niet meer nodig
// private fun updateDataScannedDevices() {
//   val devices = mSensorList.value

//   if (devices != null) {
//     for (connectedDevice in devices!!) {

//       for (scannedDevice in mScannedSensorList){

//         if(connectedDevice.address == (scannedDevice["device"] as BluetoothDevice?)?.address){
//           // println(connectedDevice.connectionState)
//           scannedDevice["connectionState"] = connectedDevice.connectionState
//           scannedDevice["tag"] = connectedDevice.tag
//           scannedDevice["batteryState"] = connectedDevice.batteryState
//           scannedDevice["batteryPercentage"] = connectedDevice.batteryPercentage
//         }
//       }
//     }
//   }
//   //loop door scannedDevices
//   //loop door connectedDevices
//   //if mac address = same dan update de data

// }

//.disconnect() werkt om 1 of andere reden niet
fun disconnectSensor(address: String) {
    if (mSensorList.value != null) {
        for (device in mSensorList.value!!) {
            if (device.address == address) {
                device.disconnect()
                println("disconnect")
                break
            }
        }
    }
}

fun disconnectAllSensors() {
    if (mSensorList.value != null) {
        synchronized(LOCKER) {
            val it: Iterator<DotDevice> = mSensorList.value!!.iterator()
            while (it.hasNext()) {

                // Use Iterator to make sure it's thread safety.
                val device = it.next()
                device.disconnect()
            }
            removeAllDevice()
        }
    }
}

fun getSensor(address: String): DotDevice? {
    val devices = mSensorList.value
    if (devices != null) {
        for (device in devices) {
            if (device.address == address) return device
        }
    }
    return null
}

private fun addDevice(xsDevice: DotDevice) {
    if (mSensorList.value == null) mSensorList.value = ArrayList()
    val devices = mSensorList.value
    var isExist = false
    for (_xsDevice in devices!!) {
        if (xsDevice.address == _xsDevice.address) {
            isExist = true
            break
        }
    }
    if (!isExist) devices.add(xsDevice)
}

fun removeDevice(address: String) {
    if (mSensorList.value == null) {
        mSensorList.value = ArrayList()
        return
    }
    synchronized(LOCKER) {
        val it = mSensorList.value!!.iterator()
        while (it.hasNext()) {

            // Use Iterator to make sure it's thread safety.
            val device = it.next()
            if (device.address == address) {
                it.remove()
                break
            }
        }
    }
}

fun removeAllDevice() {
    if (mSensorList.value != null) {
        synchronized(LOCKER) { mSensorList.value!!.clear() }
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
      DotSdk.setReconnectEnabled(false)

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

        for (scannedDevice in mScannedSensorList){
          if((scannedDevice["device"] as BluetoothDevice?)?.address == address){
            scannedDevice["connectionState"] = state
          }
        }
        
        when (state) {
            DotDevice.CONN_STATE_DISCONNECTED -> synchronized(this) { removeDevice(address) }
            DotDevice.CONN_STATE_CONNECTING -> {Log.i(TAG, "onXsensDotConnectionChanged() - address = $address, connecting")}
            DotDevice.CONN_STATE_CONNECTED -> {Log.i(TAG, "onXsensDotConnectionChanged() - address = $address, connected")}
            DotDevice.CONN_STATE_RECONNECTING -> {Log.i(TAG, "onXsensDotConnectionChanged() - address = $address, reconnecting")}
        }
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

    val acc: DoubleArray = data.acc
    val gyr: DoubleArray = data.gyr
    val dq: DoubleArray = data.dq
    val dv: DoubleArray = data.dv
    val mag: DoubleArray = data.mag
    val quat: FloatArray = data.quat
    val sampleTimeFine: Long = data.sampleTimeFine
    val packetCounter: Int = data.packetCounter

    
    val tempJSON = JSONObject()

    tempJSON.put("acc", acc.contentToString())
    tempJSON.put("gyr", gyr.contentToString())
    tempJSON.put("dq", dq.contentToString())
    tempJSON.put("dv", dv.contentToString())
    tempJSON.put("mag", mag.contentToString())
    tempJSON.put("quat", quat.contentToString())
    tempJSON.put("sampleTimeFine", sampleTimeFine.toString())
    tempJSON.put("packetCounter", packetCounter.toString())

    val jsonList = mutableListOf<JSONObject>()
    jsonList.add(tempJSON)

    if (dotDataJSON.has(address)) {
        val tempList = dotDataJSON.get(address) as MutableList<JSONObject>
        tempList.addAll(jsonList)
        dotDataJSON.put(address, tempList)
    } else {
        dotDataJSON.put(address, jsonList)
    }
}


override fun onDotBatteryChanged(address: String, status: Int, percentage: Int) {
        // This callback function will be triggered in the connection precess.
        Log.i(TAG, "onXsensDotBatteryChanged() - address = $address, status = $status, percentage = $percentage")
        for (scannedDevice in mScannedSensorList){
          if((scannedDevice["device"] as BluetoothDevice?)?.address == address){
            scannedDevice["batteryPercentage"] = percentage
          }
        }
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
      private val LOCKER = Any()
  }
}

