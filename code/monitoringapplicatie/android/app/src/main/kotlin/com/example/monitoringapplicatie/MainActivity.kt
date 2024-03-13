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
//Aan de flutter kant gaan we de data handellen en de status displayen

//Voorlopige status:
//knop op scherm om het bluetooth scanning aan en uit te zetten.
//knop voor data te meten en te stoppen
//De measurement is momenteel DotPayload.PAYLOAD_TYPE_CUSTOM_MODE_4 (zie docs bij apendix)
//Een functie gemaakt die de list met devices convert naar json zodat ik die aan de flutter kant kan uitlezen en displayen
//Aan flutter dat tijdens het searchen de list met gevonden devices automatisch update. 
//Knop connecteren aan flutter kant dat hij met de juiste device connect
//Data in DB
//Tijdens het connecteren wordt de data opgevraagd om te kijken of hij geconnecteerd geraakt + extra data dan opvragen zoals battery
//meerdere sensoren loggen naar DB (probleem onze db writes van firestore zijn snel op)

//Wat ik graag nog wil doen
//Tijdens meten een loading symbool bij de devices die data aan het zenden zijn
//Voor op te slagen naar firestore error proberen te catchen want er kunnen 2 errors zijn: "Write stream exhausted maximum allowed queued writes" en geen internet

class MainActivity: FlutterActivity(), DotScannerCallback, DotDeviceCallback{
  private val CHANNEL = "samples.flutter.dev/battery"

  //BLE scanner of the sdk
  private var mXsScanner: DotScanner? = null

  // A variable for scanning flag
  private var mIsScanning = false

  // A variable for measuring flag
  private var mIsMeasuring = false

  // A list contains scanned Bluetooth devices -> so you can easily get data in the frontend (because Flutter doesn't know "DotDevice")
  private val mScannedSensorList = ArrayList<HashMap<String, Any>>()

  // A list contains connected XsensDotDevices
  private val mSensorList = MutableLiveData<ArrayList<DotDevice>?>()

  //json met alle data van de sensor tijdens het meten. Deze wordt naar flutter gestuurd en daar wordt het in de database opgeslagen
  private val dotDataJSON = JSONObject()

  //Dit is de method channel die voor de communicatie naar flutter zorgt.
  //"movella_init" is de functie naam en wat erachter staat {} voert hij uit als je "movella_init" aanspreekt aan de flutter kant.
  //Result.success is wat hij stuurt naar flutter. Ook kun je error's maken en die gaan via result.error naar flutter.
  override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
        // This method is invoked on the main thread.
        call, result ->
        when (call.method) {
          //Deze is om de battery level van het android device op te halen. Ik gebruik dit om te kijken of de communicatie met flutter en android/ios nog werkt.
          "getBatteryLevel" -> {
            val batteryLevel = getBatteryLevel()

            if (batteryLevel != -1) {
              result.success(batteryLevel)
            } else {
            result.error("UNAVAILABLE", "Battery level not available.", null)
            }
          }
          //Voor we de SDK kunnen gebruiken moeten we hem initialiseren (initMovellaDotSdk)
          //Ook moeten we de bluetooth scanner van de SDK initialiseren (initXsScanner)
          "movella_init" -> {
            val status = initMovellaDotSdk()
            initXsScanner()
            result.success(status)
          }
          //Deze functie is om het bluetooth scannen te starten en te stoppen.
          //Als hij aan het scannen is en je voert deze functie uit gaat hij stoppen en vice versa.
          "movella_start_stop_BLEscan" -> {
            if(!mIsScanning){
              val mBluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
              //Kijken of bluetooth op het android apparaat is ingeschakeld
              if (mBluetoothAdapter == null || !mBluetoothAdapter.isEnabled()) {
                result.success(listOf("$mIsScanning", "Error: Please Enable Bluetooth"))
              } else {
                // Bluetooth is enabled 
                //check if permissions are granted
                if(checkPermissions()){
                  //Als ze opnieuw gaan scannen naar de sensoren gaan we eerst degenen die niet geconnect zijn verwijderen uit de lijst van gevonden devices
                  val iterator = mScannedSensorList.iterator()
                  while (iterator.hasNext()) {
                      val map = iterator.next()
                      if (map["connectionState"] == 0) {
                          iterator.remove()
                      }
                  }
                  //start bluetooth scan
                  mIsScanning = if (mXsScanner == null) false else mXsScanner!!.startScan()
                  result.success(listOf("$mIsScanning", "Scan started"))
                }
              }
            }
            else{
              //stop bluetooth scan
              mIsScanning = !mXsScanner!!.stopScan()
              result.success(listOf("$mIsScanning", "Scan stopped"))
            }
          }
          //simpele functie die gewoon alle gevonden sensoren van de bluetooth scan stuurt naar flutter
          "movella_getScannedDevices" -> {
            //We sturen de mScannedSensorList naar flutter en de mSensorList is om in de kotlin kant makkelijk de functies van de sensoren aan te spreken
            result.success(convertMapToJson(mScannedSensorList))
          }
          //We krijgen een macaddress van de flutter frontend en gaan dan connecteren met de sensor
          "connectSensor" -> {
            //Data from Flutter
              val data = call.argument<String>("MacAddress")
              connectToDevice("${data}")
              result.success("connected")
          }
          //We krijgen een macaddress van de flutter frontend en gaan dan de sensor disconnecten
          "disconnectSensor" -> {
            //Data from Flutter
              val data = call.argument<String>("MacAddress")
              disconnectSensor("${data}")
              result.success("connected")
          }
          //Deze functie laat aan flutter weten of hij aan het meten is of niet
          "movella_measurementStatus" -> {
            result.success(mIsMeasuring.toString())
          }
          //Deze functie is om het meten van de data van de sensoren te starten.
          "movella_measurementStart" -> {
            val devices = mSensorList.value
            if (devices != null) {
                for (device in devices) {
                  //Dit is een bepaalde measurement mode dit we gebruiken. Verschillende modes geven andere data(zie documentatie movella: programming guide)
                    device.setMeasurementMode(DotPayload.PAYLOAD_TYPE_ORIENTATION_QUATERNION)
                    device.startMeasuring()
                    mIsMeasuring = true
                }
                result.success(mIsMeasuring.toString())
            } else{
              result.error("ERROR", "No devices found.", null)
            }
          }
          //Deze functie is om het meten van de data van de sensoren te stoppen.
          "movella_measurementStop" -> {
            val devices = mSensorList.value
            if (devices != null) {
                for (device in devices) {
                    device.stopMeasuring()
                }
            }
            mIsMeasuring = false
            //json met alle data van de sensor tijdens het meten. Deze wordt naar flutter gestuurd en daar wordt het in de database opgeslagen
            result.success(dotDataJSON.toString())
          }
        else -> {
          result.notImplemented()
        }
      } 
    }
  }

//Functie om batterij percentage van de android telefoon op te halen.
//Is eigenlijk niet meer nodig maar ik gebruik het om de communicatie van flutter met ios/android te testen
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

//Kijken of de permissies bluetooth_scan, bluetooth_connect en locatie toegestaan zijn op android telefoon
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

//Tijdens het bluetooth scannen als hij een Movella Dot Sensor vind wordt deze functie automatisch uitgevoerd
//Daarna gaan we kijken of we deze al in onze scannedList staat, zoniet voegen we hem toe.
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
      // Also set name, battery state, battery percentage to default value.
      val map = HashMap<String, Any>()
      map["device"] = device
      map["connectionState"] = DotDevice.CONN_STATE_DISCONNECTED
      map["name"] = device.getName()
      map["batteryState"] = -1
      map["batteryPercentage"] = -1

      mScannedSensorList.add(map)
  }
}

//Functie om de device data in json te steken om daarna naar flutter te sturen zodat we deze in de frontend kunnen implementeren
private fun convertMapToJson(list: ArrayList<HashMap<String, Any>>): String {
    val jsonList = mutableListOf<JSONObject>()
    val globalObject = JSONObject()

    for (map in list) {
        val deviceObject = JSONObject()

        deviceObject.put("device", (map["device"] as BluetoothDevice?)?.address)
        deviceObject.put("connectionState", map["connectionState"])
        deviceObject.put("name", map["name"])
        deviceObject.put("batteryState", map["batteryState"])
        deviceObject.put("batteryPercentage", map["batteryPercentage"])

        jsonList.add(deviceObject)
    }
    globalObject.put("devices", jsonList)
    return globalObject.toString()
}

//Functie om de sensor te connecteren
//Wanneer hij geconnecteerd is voegen we hem toe als een DotDevice in mSensorList zodat we daarna makkelijk  de functies van de sensor kunnen aanspreken
private fun connectToDevice(address: String){
  val devices = mScannedSensorList
  if (devices != null) {
        for (device in devices) {
            // Check if the device is a DotDevice and its address matches
            if (((device["device"] as BluetoothDevice?)?.address) == address) {
                val _xsDevice = DotDevice(applicationContext, (device["device"]as BluetoothDevice), this@MainActivity)
                //_xsDevice.setOutputRate(30)
                addDevice(_xsDevice) //add in list with connected sensors
                _xsDevice.connect();
                //Log.i(TAG,_xsDevice.getCurrentOutputRate()) //connect sensor
            }
        }
    }
}

//Ik heb deze functie ooit geschreven om de data van de sensoren in de scannedSensorList te updaten voor de frontend.
//Voorlopig is het niet nodig maar kan handig zijn voor de toekomst?

// //update the data of the scanned bluetooth devices
// private fun updateDataScannedDevices() {
//   //loop door scannedDevices
//   //loop door connectedDevices
//   //if mac address = same dan update de data
//   val devices = mSensorList.value

//   if (devices != null) {
//     for (connectedDevice in devices!!) {

//       for (scannedDevice in mScannedSensorList){

//         if(connectedDevice.address == (scannedDevice["device"] as BluetoothDevice?)?.address){
//           // println(connectedDevice.connectionState)
//           scannedDevice["connectionState"] = connectedDevice.connectionState
//           scannedDevice["name"] = connectedDevice.name
//           scannedDevice["batteryState"] = connectedDevice.batteryState
//           scannedDevice["batteryPercentage"] = connectedDevice.batteryPercentage
//         }
//       }
//     }
//   }
// }

//disconnect functie
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

//Alle geconnecteerde sensoren disconnecten. 
//Gebruik ik momenteel niet dus nog niet getest(komt uit example code movella)
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

//Op basis van macaddress de juiste sensor zoeken in de lijst met geconnecteerde sensoren.
//Deze returned een DotDevice dus dat wilt zeggen dat je dan makkelijk de functies van de sensor kunt aanspreken nadien
fun getSensor(address: String): DotDevice? {
    val devices = mSensorList.value
    if (devices != null) {
        for (device in devices) {
            if (device.address == address) return device
        }
    }
    return null
}

//Voeg sensor toe in lijst met geconnecteerde sensoren
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

//Verwijder sensor uit lijst met geconnecteerde sensoren
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

//Alle geconnecteerde sensoren verwijderen uit de lijst.
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

//SDK bluetooth scanner initialiseren
private fun initXsScanner() {
  // Check Bluetooth permissions at runtime
    if (mXsScanner == null) {
        mXsScanner = DotScanner(context, this)
        //Er zijn verschillende modes voor het bluetooth scannen(zie documentatie movella: programming guide)
        mXsScanner!!.setScanMode(ScanSettings.SCAN_MODE_BALANCED)
    }
}

//Deze functie voert automatisch uit wanneer de connectie veranderd van een sensor
override fun onDotConnectionChanged(address: String, state: Int) {
      Log.i(TAG, "onXsensDotConnectionChanged() - address = $address, state = $state")
      //Hier updaten we de connectie status van de sensor in de scannedSensorList voor de frontent
      for (scannedDevice in mScannedSensorList){
        if((scannedDevice["device"] as BluetoothDevice?)?.address == address){
          scannedDevice["connectionState"] = state
        }
      }
      //Bij een bepaalde state wordt de code in {} uitgevoerd.
      //Als we een sensor disconnecten verwijderen we hem uit de lijst van geconnecteerde sensoren
      when (state) {
          DotDevice.CONN_STATE_DISCONNECTED -> synchronized(this) { removeDevice(address) }
          DotDevice.CONN_STATE_CONNECTING -> {Log.i(TAG, "onXsensDotConnectionChanged() - address = $address, connecting")}
          DotDevice.CONN_STATE_CONNECTED -> {Log.i(TAG, "onXsensDotConnectionChanged() - address = $address, connected")}
          DotDevice.CONN_STATE_RECONNECTING -> {Log.i(TAG, "onXsensDotConnectionChanged() - address = $address, reconnecting")}
      }
  }

//Hieronder staan verschillende functies die ik MOEST overriden die dus ook automatisch worden uitgevoed bij een verandering van ...
//Momenteel voer ik enkel een console log uit in deze functies

override fun onDotServicesDiscovered(address: String, status: Int) {
        Log.i(TAG, "onXsensDotServicesDiscovered() - address = $address, status = $status")
    }

override fun onDotFirmwareVersionRead(address: String, version: String) {
        Log.i(TAG, "onXsensDotFirmwareVersionRead() - address = $address, version = $version")
    }

override fun onDotTagChanged(address: String, tag: String) {
        // This callback function will be triggered in the connection precess.
        Log.i(TAG, "onXsensDotTagChanged() - address = $address, tag = $tag")
    }

//Deze functie wordt automatsich uitgevoerd wanneer de data van de sensor wijzigd tijdens het meten
override fun onDotDataChanged(address: String, data: DotData) {
    Log.i(TAG, "onXsensDotDataChanged() - address = $address")

    //Data wordt opgehaald en in variabellen gezet
    val quat: FloatArray = data.quat
    val sampleTimeFine: Long = data.sampleTimeFine
    val packetCounter: Int = data.packetCounter

    
    val tempJSON = JSONObject()
    //data wordt in een json gezet
    tempJSON.put("quat", quat.contentToString())
    tempJSON.put("sampleTimeFine", sampleTimeFine.toString())
    tempJSON.put("packetCounter", packetCounter.toString())

    val jsonList = mutableListOf<JSONObject>()
    jsonList.add(tempJSON)

    //Als het macaddress van de sensor waarvoor we de data aan het wegschrijven zijn al in de json staat, voegen we gewoon data toe aan de json. 
    //Anders inplaats van data toe te voegen gaan we rechtstreeks de data in de json schrijven
    //het formaat van de json:
      //"D4:22:CD:00:92:26" : {
      //   "acc" : "[2.3443, 4.23223, 5.233]",
      //   "gyr" : "[2.3443, 4.23223, 5.233]",
      //   ...
      // }
    if (dotDataJSON.has(address)) {
        val tempList = dotDataJSON.get(address) as MutableList<JSONObject>
        tempList.addAll(jsonList)
        dotDataJSON.put(address, tempList)
    } else {
        dotDataJSON.put(address, jsonList)
    }
}

//Deze functie voert automatisch uit wanneer de batterij percentage veranderd van een sensor
override fun onDotBatteryChanged(address: String, status: Int, percentage: Int) {
    // This callback function will be triggered in the connection precess.
    Log.i(TAG, "onXsensDotBatteryChanged() - address = $address, status = $status, percentage = $percentage")
    //Hier updaten we de batterij percentage van de sensor in de scannedSensorList voor de frontent
    for (scannedDevice in mScannedSensorList){
      if((scannedDevice["device"] as BluetoothDevice?)?.address == address){
        scannedDevice["batteryPercentage"] = percentage
      }
    }
}


//Hieronder staan verschillende functies die ik MOEST overriden die dus ook automatisch worden uitgevoed bij een verandering van ...
//Momenteel voer ik enkel een console log uit in deze functies
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

