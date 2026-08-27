package com.example.offline_network_app

import android.Manifest
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.net.wifi.WpsInfo
import android.net.wifi.p2p.WifiP2pConfig
import android.net.wifi.p2p.WifiP2pDevice
import android.net.wifi.p2p.WifiP2pInfo
import android.net.wifi.p2p.WifiP2pManager
import android.os.Build
import android.os.Handler
import android.os.Looper

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL_NAME = "wifi_direct_channel"
        private const val DISCOVERY_TIMEOUT = 10000L
    }

    private lateinit var wifiP2pManager: WifiP2pManager
    private lateinit var wifiP2pChannel: WifiP2pManager.Channel

    private val mainHandler = Handler(Looper.getMainLooper())

    private var receiverRegistered = false

    /*
     * Stores the Flutter result while Android is scanning.
     *
     * discoverPeers() only starts discovery. The actual peer list
     * is received later through WIFI_P2P_PEERS_CHANGED_ACTION.
     */
    private var pendingDiscoveryResult: MethodChannel.Result? = null

    private val intentFilter = IntentFilter().apply {
        addAction(WifiP2pManager.WIFI_P2P_STATE_CHANGED_ACTION)
        addAction(WifiP2pManager.WIFI_P2P_PEERS_CHANGED_ACTION)
        addAction(WifiP2pManager.WIFI_P2P_CONNECTION_CHANGED_ACTION)
        addAction(WifiP2pManager.WIFI_P2P_THIS_DEVICE_CHANGED_ACTION)
    }

    private val discoveryTimeoutRunnable = Runnable {
        /*
         * Some phones may not send the peer-change broadcast quickly.
         * Therefore, request the current peer list after the timeout.
         */
        if (pendingDiscoveryResult != null) {
            requestCurrentPeers()
        }
    }

    private val wifiP2pReceiver = object : BroadcastReceiver() {

        override fun onReceive(
            context: Context?,
            intent: Intent?,
        ) {
            when (intent?.action) {

                WifiP2pManager.WIFI_P2P_PEERS_CHANGED_ACTION -> {
                    /*
                     * Android informs us that the peer list changed.
                     * Now it is safe to request the updated list.
                     */
                    requestCurrentPeers()
                }

                WifiP2pManager.WIFI_P2P_CONNECTION_CHANGED_ACTION -> {
                    /*
                     * Connection state changed.
                     *
                     * The Flutter side can call getConnectionInfo()
                     * to check whether a group has been formed.
                     */
                }

                WifiP2pManager.WIFI_P2P_STATE_CHANGED_ACTION -> {
                    /*
                     * Wi-Fi Direct was enabled or disabled.
                     * This can be exposed to Flutter later.
                     */
                }

                WifiP2pManager.WIFI_P2P_THIS_DEVICE_CHANGED_ACTION -> {
                    /*
                     * Information about this phone changed.
                     */
                }
            }
        }
    }

    override fun configureFlutterEngine(
        flutterEngine: FlutterEngine,
    ) {
        super.configureFlutterEngine(flutterEngine)

        wifiP2pManager =
            getSystemService(Context.WIFI_P2P_SERVICE)
                    as WifiP2pManager

        wifiP2pChannel = wifiP2pManager.initialize(
            this,
            mainLooper,
        ) {
            /*
             * Wi-Fi P2P framework channel was disconnected.
             * A new channel could be initialized here when required.
             */
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL_NAME,
        ).setMethodCallHandler { call, result ->

            when (call.method) {

                "discoverPeers" -> {
                    discoverPeers(result)
                }

                "connectToPeer" -> {
                    val deviceAddress =
                        call.argument<String>("deviceAddress")

                    if (deviceAddress.isNullOrBlank()) {
                        result.error(
                            "INVALID_ADDRESS",
                            "Wi-Fi Direct device address is missing.",
                            null,
                        )
                    } else {
                        connectToPeer(
                            deviceAddress = deviceAddress,
                            result = result,
                        )
                    }
                }

                "getConnectionInfo" -> {
                    getConnectionInfo(result)
                }

                "removeGroup" -> {
                    removeCurrentGroup(result)
                }

                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onStart() {
        super.onStart()

        if (!receiverRegistered) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                registerReceiver(
                    wifiP2pReceiver,
                    intentFilter,
                    Context.RECEIVER_EXPORTED,
                )
            } else {
                @Suppress("DEPRECATION")
                registerReceiver(
                    wifiP2pReceiver,
                    intentFilter,
                )
            }

            receiverRegistered = true
        }
    }

    override fun onStop() {
        if (receiverRegistered) {
            unregisterReceiver(wifiP2pReceiver)
            receiverRegistered = false
        }

        super.onStop()
    }

    private fun hasWifiDirectPermission(): Boolean {
        return if (
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU
        ) {
            checkSelfPermission(
                Manifest.permission.NEARBY_WIFI_DEVICES,
            ) == PackageManager.PERMISSION_GRANTED
        } else {
            checkSelfPermission(
                Manifest.permission.ACCESS_FINE_LOCATION,
            ) == PackageManager.PERMISSION_GRANTED
        }
    }

    /*
     * Starts Wi-Fi Direct discovery.
     *
     * It does not immediately return peers. The result is completed
     * after WIFI_P2P_PEERS_CHANGED_ACTION is received.
     */
    private fun discoverPeers(
        result: MethodChannel.Result,
    ) {
        if (!hasWifiDirectPermission()) {
            result.error(
                "PERMISSION_DENIED",
                "Nearby Wi-Fi or location permission is not granted.",
                null,
            )
            return
        }

        if (pendingDiscoveryResult != null) {
            result.error(
                "DISCOVERY_RUNNING",
                "Wi-Fi Direct discovery is already running.",
                null,
            )
            return
        }

        pendingDiscoveryResult = result

        try {
            wifiP2pManager.discoverPeers(
                wifiP2pChannel,
                object : WifiP2pManager.ActionListener {

                    override fun onSuccess() {
                        /*
                         * Discovery has started.
                         *
                         * Do not return the peer list here because scanning
                         * has not necessarily completed.
                         */
                        mainHandler.postDelayed(
                            discoveryTimeoutRunnable,
                            DISCOVERY_TIMEOUT,
                        )
                    }

                    override fun onFailure(reason: Int) {
                        mainHandler.removeCallbacks(
                            discoveryTimeoutRunnable,
                        )

                        if (pendingDiscoveryResult === result) {
                            pendingDiscoveryResult = null

                            result.error(
                                "DISCOVERY_FAILED",
                                getFailureMessage(reason),
                                reason,
                            )
                        }
                    }
                },
            )
        } catch (exception: SecurityException) {
            pendingDiscoveryResult = null

            result.error(
                "PERMISSION_DENIED",
                exception.message,
                null,
            )
        }
    }

    /*
     * Requests the updated peer list and returns complete peer data
     * to Flutter.
     */
    private fun requestCurrentPeers() {
        val flutterResult =
            pendingDiscoveryResult ?: return

        pendingDiscoveryResult = null

        mainHandler.removeCallbacks(
            discoveryTimeoutRunnable,
        )

        if (!hasWifiDirectPermission()) {
            flutterResult.error(
                "PERMISSION_DENIED",
                "Nearby Wi-Fi or location permission is not granted.",
                null,
            )
            return
        }

        try {
            wifiP2pManager.requestPeers(
                wifiP2pChannel,
            ) { peerList ->

                val peers =
                    peerList.deviceList.map { device ->

                        hashMapOf<String, Any>(
                            "deviceName" to (
                                device.deviceName
                                    .takeIf { it.isNotBlank() }
                                    ?: "Unknown device"
                            ),
                            "deviceAddress" to device.deviceAddress,
                            "status" to device.status,
                            "statusText" to getDeviceStatusText(
                                device.status,
                            ),
                        )
                    }

                flutterResult.success(peers)
            }
        } catch (exception: SecurityException) {
            flutterResult.error(
                "PERMISSION_DENIED",
                exception.message,
                null,
            )
        }
    }

    /*
     * Sends a Wi-Fi Direct connection request.
     *
     * onSuccess means the request was started. It does not mean the
     * other phone accepted the request or that the group is formed.
     */
    private fun connectToPeer(
        deviceAddress: String,
        result: MethodChannel.Result,
    ) {
        if (!hasWifiDirectPermission()) {
            result.error(
                "PERMISSION_DENIED",
                "Nearby Wi-Fi or location permission is not granted.",
                null,
            )
            return
        }

        val config = WifiP2pConfig().apply {
            this.deviceAddress = deviceAddress
            wps.setup = WpsInfo.PBC
        }

        try {
            wifiP2pManager.connect(
                wifiP2pChannel,
                config,
                object : WifiP2pManager.ActionListener {

                    override fun onSuccess() {
                        result.success(
                            "Connection request sent",
                        )
                    }

                    override fun onFailure(reason: Int) {
                        result.error(
                            "CONNECTION_FAILED",
                            getFailureMessage(reason),
                            reason,
                        )
                    }
                },
            )
        } catch (exception: SecurityException) {
            result.error(
                "PERMISSION_DENIED",
                exception.message,
                null,
            )
        }
    }

    /*
     * Returns the current Wi-Fi Direct connection information.
     */
    private fun getConnectionInfo(
        result: MethodChannel.Result,
    ) {
        if (!hasWifiDirectPermission()) {
            result.error(
                "PERMISSION_DENIED",
                "Nearby Wi-Fi or location permission is not granted.",
                null,
            )
            return
        }

        try {
            wifiP2pManager.requestConnectionInfo(
                wifiP2pChannel,
            ) { info: WifiP2pInfo ->

                val connectionData =
                    hashMapOf<String, Any>(
                        "groupFormed" to info.groupFormed,
                        "isGroupOwner" to info.isGroupOwner,
                        "groupOwnerAddress" to (
                            info.groupOwnerAddress
                                ?.hostAddress
                                ?: ""
                        ),
                    )

                result.success(connectionData)
            }
        } catch (exception: SecurityException) {
            result.error(
                "PERMISSION_DENIED",
                exception.message,
                null,
            )
        }
    }

    private fun removeCurrentGroup(
        result: MethodChannel.Result,
    ) {
        try {
            wifiP2pManager.removeGroup(
                wifiP2pChannel,
                object : WifiP2pManager.ActionListener {

                    override fun onSuccess() {
                        result.success(true)
                    }

                    override fun onFailure(reason: Int) {
                        result.error(
                            "REMOVE_GROUP_FAILED",
                            getFailureMessage(reason),
                            reason,
                        )
                    }
                },
            )
        } catch (exception: SecurityException) {
            result.error(
                "PERMISSION_DENIED",
                exception.message,
                null,
            )
        }
    }

    private fun getDeviceStatusText(
        status: Int,
    ): String {
        return when (status) {
            WifiP2pDevice.CONNECTED -> "Connected"
            WifiP2pDevice.INVITED -> "Invited"
            WifiP2pDevice.FAILED -> "Failed"
            WifiP2pDevice.AVAILABLE -> "Available"
            WifiP2pDevice.UNAVAILABLE -> "Unavailable"
            else -> "Unknown"
        }
    }

    private fun getFailureMessage(
        reason: Int,
    ): String {
        return when (reason) {
            WifiP2pManager.P2P_UNSUPPORTED ->
                "Wi-Fi Direct is not supported on this phone."

            WifiP2pManager.BUSY ->
                "Wi-Fi Direct is busy. Wait and try again."

            WifiP2pManager.ERROR ->
                "An internal Wi-Fi Direct error occurred."

            else ->
                "Wi-Fi Direct operation failed. Reason: $reason"
        }
    }
}