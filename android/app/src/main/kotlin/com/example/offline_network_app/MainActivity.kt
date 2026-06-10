package com.example.offline_network_app

import android.net.wifi.p2p.WifiP2pManager
import android.net.wifi.p2p.WifiP2pManager.Channel
import android.net.wifi.p2p.WifiP2pManager.PeerListListener
import android.net.wifi.p2p.WifiP2pConfig
import android.net.wifi.p2p.WifiP2pInfo

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "wifi_direct_channel"

    private lateinit var wifiP2pManager: WifiP2pManager

    private lateinit var channel: Channel

    override fun configureFlutterEngine(
        flutterEngine: FlutterEngine
    ) {

        super.configureFlutterEngine(flutterEngine)

        /// INITIALIZE WIFI DIRECT
        wifiP2pManager =
            getSystemService(WIFI_P2P_SERVICE)
                    as WifiP2pManager

        channel = wifiP2pManager.initialize(
            this,
            mainLooper,
            null
        )

        /// METHOD CHANNEL
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->

            when (call.method) {

                /// DISCOVER PEERS
                "discoverPeers" -> {

                    discoverPeers(result)
                }

                /// CONNECT TO PEER
                "connectToPeer" -> {

                    val deviceAddress =
                        call.argument<String>(
                            "deviceAddress"
                        )

                    if (deviceAddress != null) {

                        connectToPeer(
                            deviceAddress,
                            result
                        )

                    } else {

                        result.error(
                            "INVALID_ADDRESS",
                            "Device address missing",
                            null
                        )
                    }
                }

                /// GET CONNECTION INFO
                "getConnectionInfo" -> {

                    getConnectionInfo(result)
                }

                else -> {

                    result.notImplemented()
                }
            }
        }
    }

    /// DISCOVER NEARBY DEVICES
    private fun discoverPeers(
        result: MethodChannel.Result
    ) {

        wifiP2pManager.discoverPeers(
            channel,

            object : WifiP2pManager.ActionListener {

                override fun onSuccess() {

                    /// REQUEST PEER LIST
                    wifiP2pManager.requestPeers(
                        channel,

                        PeerListListener { peers ->

                            val peerNames =
                                mutableListOf<String>()

                            for (device in peers.deviceList) {

                                peerNames.add(
                                    device.deviceName
                                )
                            }

                            result.success(peerNames)
                        }
                    )
                }

                override fun onFailure(
                    reason: Int
                ) {

                    result.error(
                        "DISCOVERY_FAILED",
                        "Failed with reason $reason",
                        null
                    )
                }
            }
        )
    }

    /// CONNECT TO WIFI DIRECT PEER
    private fun connectToPeer(
        deviceAddress: String,
        result: MethodChannel.Result
    ) {

        val config = WifiP2pConfig()

        config.deviceAddress = deviceAddress

        wifiP2pManager.connect(
            channel,
            config,

            object : WifiP2pManager.ActionListener {

                override fun onSuccess() {

                    result.success(
                        "Connection Request Sent"
                    )
                }

                override fun onFailure(
                    reason: Int
                ) {

                    result.error(
                        "CONNECTION_FAILED",
                        "Failed: $reason",
                        null
                    )
                }
            }
        )
    }

    /// GET WIFI DIRECT CONNECTION INFO
    private fun getConnectionInfo(
        result: MethodChannel.Result
    ) {

        wifiP2pManager.requestConnectionInfo(
            channel
        ) { info: WifiP2pInfo ->

            val connectionData =
                HashMap<String, Any>()

            connectionData["groupFormed"] =
                info.groupFormed

            connectionData["isGroupOwner"] =
                info.isGroupOwner

            connectionData["groupOwnerAddress"] =
                info.groupOwnerAddress.hostAddress

            result.success(connectionData)
        }
    }
}