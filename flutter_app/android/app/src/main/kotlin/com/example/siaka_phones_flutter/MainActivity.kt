package com.example.siaka_phones_flutter

import android.Manifest
import android.annotation.SuppressLint
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val DIALER_CHANNEL = "com.siakaphones.app/dialer"
    private val NOTIFICATION_CHANNEL = "com.siakaphones.app/notifications"
    private val LOCATION_CHANNEL = "com.siakaphones.app/location"
    private val ANDROID_CHANNEL_ID = "siaka_phones_alerts_channel_v2"
    private val PERMISSION_VISUAL_USER_SELECTED = "android.permission.READ_MEDIA_VISUAL_USER_SELECTED"

    private var pendingAllPermissionsResult: MethodChannel.Result? = null
    private var permissionRequestStartMs: Long = 0L
    private var pendingLocationResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        createNotificationChannel()

        // Dialer Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DIALER_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "openDialer") {
                val number = call.argument<String>("number") ?: ""
                try {
                    val intent = Intent(Intent.ACTION_DIAL).apply {
                        data = Uri.parse("tel:$number")
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    }
                    startActivity(intent)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("UNAVAILABLE", e.localizedMessage, null)
                }
            } else {
                result.notImplemented()
            }
        }

        // System Notifications & App Permissions Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NOTIFICATION_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "showNotification" -> {
                    val title = call.argument<String>("title") ?: "Siaka Phones"
                    val body = call.argument<String>("body") ?: ""
                    val id = call.argument<Int>("id") ?: System.currentTimeMillis().toInt()
                    showSystemNotification(title, body, id)
                    result.success(true)
                }
                "requestPermission" -> {
                    requestNotificationPermission()
                    result.success(true)
                }
                "requestAllPermissions" -> {
                    requestAllPermissions(result)
                }
                "hasAllPermissions" -> {
                    result.success(areAllRequiredPermissionsGranted())
                }
                "openAppPermissionSettings" -> {
                    openAppPermissionSettings()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // Live GPS Location Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LOCATION_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getCurrentLocation" -> handleGetCurrentLocation(result)
                "openGoogleMaps" -> handleOpenGoogleMaps(call, result)
                else -> result.notImplemented()
            }
        }
    }

    private fun isGranted(permission: String): Boolean {
        return checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED
    }

    private fun hasLocationPermission(): Boolean {
        return isGranted(Manifest.permission.ACCESS_FINE_LOCATION) ||
            isGranted(Manifest.permission.ACCESS_COARSE_LOCATION)
    }

    private fun hasVisualMediaPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= 34) {
            (isGranted(Manifest.permission.READ_MEDIA_IMAGES) && isGranted(Manifest.permission.READ_MEDIA_VIDEO)) ||
                isGranted(PERMISSION_VISUAL_USER_SELECTED)
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            isGranted(Manifest.permission.READ_MEDIA_IMAGES) && isGranted(Manifest.permission.READ_MEDIA_VIDEO)
        } else {
            isGranted(Manifest.permission.READ_EXTERNAL_STORAGE)
        }
    }

    private fun collectMissingRuntimePermissions(): List<String> {
        val missing = mutableListOf<String>()

        // 1. Push Notifications (Android 13+)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (!isGranted(Manifest.permission.POST_NOTIFICATIONS)) {
                missing.add(Manifest.permission.POST_NOTIFICATIONS)
            }
        }

        // 2. Precise & Approximate Device Location
        if (!isGranted(Manifest.permission.ACCESS_FINE_LOCATION)) {
            missing.add(Manifest.permission.ACCESS_FINE_LOCATION)
        }
        if (!isGranted(Manifest.permission.ACCESS_COARSE_LOCATION)) {
            missing.add(Manifest.permission.ACCESS_COARSE_LOCATION)
        }

        // 3. Camera
        if (!isGranted(Manifest.permission.CAMERA)) {
            missing.add(Manifest.permission.CAMERA)
        }

        // 4. Photos, Videos, Music/Audio & Storage
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (!hasVisualMediaPermission()) {
                missing.add(Manifest.permission.READ_MEDIA_IMAGES)
                missing.add(Manifest.permission.READ_MEDIA_VIDEO)
                if (Build.VERSION.SDK_INT >= 34) {
                    missing.add(PERMISSION_VISUAL_USER_SELECTED)
                }
            }
            if (!isGranted(Manifest.permission.READ_MEDIA_AUDIO)) {
                missing.add(Manifest.permission.READ_MEDIA_AUDIO)
            }
        } else {
            if (!isGranted(Manifest.permission.READ_EXTERNAL_STORAGE)) {
                missing.add(Manifest.permission.READ_EXTERNAL_STORAGE)
            }
            if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.Q &&
                !isGranted(Manifest.permission.WRITE_EXTERNAL_STORAGE)
            ) {
                missing.add(Manifest.permission.WRITE_EXTERNAL_STORAGE)
            }
        }

        // 5. Microphone & Audio Recording
        if (!isGranted(Manifest.permission.RECORD_AUDIO)) {
            missing.add(Manifest.permission.RECORD_AUDIO)
        }

        // 6. Phone & Direct Calls
        if (!isGranted(Manifest.permission.CALL_PHONE)) {
            missing.add(Manifest.permission.CALL_PHONE)
        }
        if (!isGranted(Manifest.permission.READ_PHONE_STATE)) {
            missing.add(Manifest.permission.READ_PHONE_STATE)
        }

        // 7. Contacts
        if (!isGranted(Manifest.permission.READ_CONTACTS)) {
            missing.add(Manifest.permission.READ_CONTACTS)
        }

        // 8. Calendar & Reminders
        if (!isGranted(Manifest.permission.READ_CALENDAR)) {
            missing.add(Manifest.permission.READ_CALENDAR)
        }
        if (!isGranted(Manifest.permission.WRITE_CALENDAR)) {
            missing.add(Manifest.permission.WRITE_CALENDAR)
        }

        // 9. Nearby Devices & Bluetooth (Android 12+)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (!isGranted(Manifest.permission.BLUETOOTH_CONNECT)) {
                missing.add(Manifest.permission.BLUETOOTH_CONNECT)
            }
            if (!isGranted(Manifest.permission.BLUETOOTH_SCAN)) {
                missing.add(Manifest.permission.BLUETOOTH_SCAN)
            }
        }

        return missing.distinct()
    }

    private fun areAllRequiredPermissionsGranted(): Boolean {
        return collectMissingRuntimePermissions().isEmpty()
    }

    private fun buildPermissionStatusMap(): Map<String, Boolean> {
        return mapOf(
            "notifications" to (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) isGranted(Manifest.permission.POST_NOTIFICATIONS) else true),
            "location" to hasLocationPermission(),
            "camera" to isGranted(Manifest.permission.CAMERA),
            "photosAndVideos" to hasVisualMediaPermission(),
            "audioMedia" to (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) isGranted(Manifest.permission.READ_MEDIA_AUDIO) else isGranted(Manifest.permission.READ_EXTERNAL_STORAGE)),
            "microphone" to isGranted(Manifest.permission.RECORD_AUDIO),
            "phone" to (isGranted(Manifest.permission.CALL_PHONE) && isGranted(Manifest.permission.READ_PHONE_STATE)),
            "contacts" to isGranted(Manifest.permission.READ_CONTACTS),
            "calendar" to (isGranted(Manifest.permission.READ_CALENDAR) && isGranted(Manifest.permission.WRITE_CALENDAR)),
            "nearbyDevices" to (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) (isGranted(Manifest.permission.BLUETOOTH_CONNECT) && isGranted(Manifest.permission.BLUETOOTH_SCAN)) else true),
            "biometrics" to true
        )
    }

    private fun openAppPermissionSettings() {
        try {
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.fromParts("package", packageName, null)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            startActivity(intent)
        } catch (_: Exception) {}
    }

    private fun requestAllPermissions(result: MethodChannel.Result) {
        val permissionsToRequest = collectMissingRuntimePermissions()
        if (permissionsToRequest.isEmpty()) {
            result.success(buildPermissionStatusMap())
            return
        }

        pendingAllPermissionsResult?.success(buildPermissionStatusMap())
        pendingAllPermissionsResult = result
        permissionRequestStartMs = System.currentTimeMillis()
        requestPermissions(permissionsToRequest.toTypedArray(), 1002)
    }

    private fun handleGetCurrentLocation(result: MethodChannel.Result) {
        if (!hasLocationPermission()) {
            pendingLocationResult = result
            requestPermissions(
                arrayOf(
                    Manifest.permission.ACCESS_FINE_LOCATION,
                    Manifest.permission.ACCESS_COARSE_LOCATION
                ),
                1003
            )
            return
        }
        fetchLiveLocation(result)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        when (requestCode) {
            1002 -> {
                val elapsed = System.currentTimeMillis() - permissionRequestStartMs
                val pending = pendingAllPermissionsResult
                pendingAllPermissionsResult = null

                // If Android suppressed the prompt because permissions were permanently blocked earlier,
                // open the App Settings screen so the user can toggle them on directly.
                if (grantResults.isNotEmpty() &&
                    grantResults.all { it != PackageManager.PERMISSION_GRANTED } &&
                    elapsed < 300L &&
                    permissions.none { shouldShowRequestPermissionRationale(it) }
                ) {
                    openAppPermissionSettings()
                }

                pending?.success(buildPermissionStatusMap())
            }
            1003 -> {
                val pending = pendingLocationResult
                pendingLocationResult = null
                if (pending != null) {
                    if (hasLocationPermission()) {
                        fetchLiveLocation(pending)
                    } else {
                        pending.error("PERMISSION_DENIED", "Location permission is required to get your live GPS code.", null)
                    }
                }
            }
        }
    }

    @SuppressLint("MissingPermission")
    private fun fetchLiveLocation(result: MethodChannel.Result) {
        val locationManager = getSystemService(Context.LOCATION_SERVICE) as? LocationManager
        if (locationManager == null) {
            result.error("UNAVAILABLE", "Location service unavailable.", null)
            return
        }

        var completed = false
        val isGhanaCoordinate: (Location) -> Boolean = { loc ->
            loc.latitude in 4.65..11.35 && loc.longitude in -3.40..1.35
        }
        val finishWithLocation: (Location?) -> Unit = { loc ->
            if (!completed) {
                completed = true
                if (loc != null && isGhanaCoordinate(loc)) {
                    result.success(
                        mapOf(
                            "latitude" to loc.latitude,
                            "longitude" to loc.longitude,
                            "accuracy" to loc.accuracy.toDouble()
                        )
                    )
                } else if (loc != null) {
                    result.error("LOCATION_OUTSIDE_GHANA", "Device location is outside Ghana (${loc.latitude}, ${loc.longitude}).", null)
                } else {
                    result.error("LOCATION_UNAVAILABLE", "Could not acquire GPS signal.", null)
                }
            }
        }

        val providers = listOf(
            LocationManager.GPS_PROVIDER,
            LocationManager.NETWORK_PROVIDER,
            LocationManager.PASSIVE_PROVIDER
        )

        var bestLastKnown: Location? = null
        val now = System.currentTimeMillis()
        for (p in providers) {
            try {
                if (locationManager.isProviderEnabled(p) || p == LocationManager.PASSIVE_PROVIDER) {
                    val last = locationManager.getLastKnownLocation(p)
                    if (last != null) {
                        if (bestLastKnown == null || last.time > bestLastKnown.time) {
                            bestLastKnown = last
                        }
                    }
                }
            } catch (_: Exception) {}
        }

        // If we have a very fresh fix (< 90 seconds old) inside Ghana, return immediately for snappy UX
        if (bestLastKnown != null && (now - bestLastKnown.time) < 90_000L && isGhanaCoordinate(bestLastKnown)) {
            finishWithLocation(bestLastKnown)
            return
        }

        val activeProviders = listOf(LocationManager.GPS_PROVIDER, LocationManager.NETWORK_PROVIDER)
            .filter {
                try {
                    locationManager.isProviderEnabled(it)
                } catch (_: Exception) {
                    false
                }
            }

        if (activeProviders.isEmpty()) {
            finishWithLocation(bestLastKnown)
            return
        }

        val handler = Handler(Looper.getMainLooper())
        val listener = object : LocationListener {
            override fun onLocationChanged(location: Location) {
                try {
                    locationManager.removeUpdates(this)
                } catch (_: Exception) {}
                handler.removeCallbacksAndMessages(null)
                finishWithLocation(location)
            }

            @Deprecated("Deprecated in Java")
            override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {}
            override fun onProviderEnabled(provider: String) {}
            override fun onProviderDisabled(provider: String) {}
        }

        try {
            for (provider in activeProviders) {
                locationManager.requestLocationUpdates(provider, 0L, 0f, listener, Looper.getMainLooper())
            }
            handler.postDelayed({
                try {
                    locationManager.removeUpdates(listener)
                } catch (_: Exception) {}
                finishWithLocation(bestLastKnown)
            }, 3500L)
        } catch (_: Exception) {
            finishWithLocation(bestLastKnown)
        }
    }

    private fun handleOpenGoogleMaps(call: io.flutter.plugin.common.MethodCall, result: MethodChannel.Result) {
        val query = call.argument<String>("query") ?: ""
        val lat = call.argument<Double>("latitude")
        val lng = call.argument<Double>("longitude")
        try {
            val geoUri = when {
                lat != null && lng != null -> {
                    val label = if (query.isNotEmpty()) "($query)" else ""
                    Uri.parse("geo:$lat,$lng?q=$lat,$lng$label")
                }
                query.isNotEmpty() -> Uri.parse("geo:0,0?q=" + Uri.encode(query))
                else -> Uri.parse("geo:5.5560,-0.1969?q=Accra,Ghana")
            }
            val intent = Intent(Intent.ACTION_VIEW, geoUri).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            startActivity(intent)
            result.success(true)
        } catch (e: Exception) {
            try {
                val webUrl = when {
                    lat != null && lng != null -> "https://www.google.com/maps/search/?api=1&query=$lat,$lng"
                    query.isNotEmpty() -> "https://www.google.com/maps/search/?api=1&query=" + Uri.encode(query)
                    else -> "https://www.google.com/maps"
                }
                val webIntent = Intent(Intent.ACTION_VIEW, Uri.parse(webUrl)).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                startActivity(webIntent)
                result.success(true)
            } catch (err: Exception) {
                result.error("MAPS_UNAVAILABLE", err.localizedMessage, null)
            }
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "Siaka Phones Alerts"
            val descriptionText = "Notifications for customer orders, store updates, and manager messages"
            val importance = NotificationManager.IMPORTANCE_HIGH
            val soundUri = Uri.parse("android.resource://" + packageName + "/" + R.raw.siaka_sound)
            val audioAttributes = AudioAttributes.Builder()
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                .build()

            val channel = NotificationChannel(ANDROID_CHANNEL_ID, name, importance).apply {
                description = descriptionText
                enableVibration(true)
                setSound(soundUri, audioAttributes)
            }
            val notificationManager: NotificationManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun requestNotificationPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (!isGranted(Manifest.permission.POST_NOTIFICATIONS)) {
                requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 1001)
            }
        }
    }

    private fun showSystemNotification(title: String, body: String, notificationId: Int) {
        try {
            val intent = Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
            }
            val flags = PendingIntent.FLAG_UPDATE_CURRENT or (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
            val pendingIntent = PendingIntent.getActivity(this, notificationId, intent, flags)

            val soundUri = Uri.parse("android.resource://" + packageName + "/" + R.raw.siaka_sound)

            val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                Notification.Builder(this, ANDROID_CHANNEL_ID)
            } else {
                @Suppress("DEPRECATION")
                Notification.Builder(this)
            }

            builder.setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle(title)
                .setContentText(body)
                .setStyle(Notification.BigTextStyle().bigText(body))
                .setContentIntent(pendingIntent)
                .setAutoCancel(true)

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                builder.setPriority(Notification.PRIORITY_HIGH)
            }

            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
                @Suppress("DEPRECATION")
                builder.setSound(soundUri)
            }

            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.notify(notificationId, builder.build())
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
