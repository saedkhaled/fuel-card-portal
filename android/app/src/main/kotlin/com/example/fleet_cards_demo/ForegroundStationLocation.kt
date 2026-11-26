package com.example.fleet_cards_demo

import android.Manifest
import android.annotation.SuppressLint
import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationManager
import android.net.Uri
import android.os.Build
import android.os.CancellationSignal
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.location.LocationManagerCompat
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

internal class ForegroundStationLocation(private val activity: Activity) {
    private val handler = Handler(Looper.getMainLooper())
    private var channel: MethodChannel? = null
    private var pending: MethodChannel.Result? = null
    private val signals = mutableMapOf<String, CancellationSignal>()
    private var bestFix: Location? = null
    private val timeout = Runnable { finish(bestFix) }

    fun register(messenger: BinaryMessenger) {
        channel = MethodChannel(messenger, "com.example.fleet_cards_demo/station_location")
        channel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "currentLocation" -> request(result)
                "openSettings" -> {
                    val permission = call.argument<Boolean>("permission") == true
                    val intent = if (permission) {
                        Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.fromParts("package", activity.packageName, null))
                    } else {
                        Intent(Settings.ACTION_LOCATION_SOURCE_SETTINGS)
                    }
                    try {
                        activity.startActivity(intent)
                        result.success(true)
                    } catch (_: ActivityNotFoundException) {
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun granted(permission: String): Boolean =
        ContextCompat.checkSelfPermission(activity, permission) == PackageManager.PERMISSION_GRANTED

    private fun hasLocationPermission() =
        granted(Manifest.permission.ACCESS_FINE_LOCATION) ||
            granted(Manifest.permission.ACCESS_COARSE_LOCATION)

    private fun request(result: MethodChannel.Result) {
        if (pending != null) {
            result.error("location_busy", "A location request is already active", null)
            return
        }
        pending = result
        if (hasLocationPermission()) {
            locate()
        } else {
            ActivityCompat.requestPermissions(
                activity,
                arrayOf(Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION),
                permissionRequest,
            )
        }
    }

    fun onPermissionResult(requestCode: Int) {
        if (requestCode != permissionRequest || pending == null) return
        if (hasLocationPermission()) {
            locate()
        } else {
            finish(null, error = "permission_denied")
        }
    }

    @SuppressLint("MissingPermission")
    private fun locate() {
        val manager = activity.getSystemService(LocationManager::class.java)
        if (manager == null || !LocationManagerCompat.isLocationEnabled(manager)) {
            finish(null, error = "services_disabled")
            return
        }

        val precise = granted(Manifest.permission.ACCESS_FINE_LOCATION)
        val providers = buildList {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) add(LocationManager.FUSED_PROVIDER)
            if (precise) add(LocationManager.GPS_PROVIDER)
            add(LocationManager.NETWORK_PROVIDER)
        }.filter(manager::isProviderEnabled)
        if (providers.isEmpty()) {
            finish(null)
            return
        }

        bestFix = providers.mapNotNull { provider ->
            try {
                manager.getLastKnownLocation(provider)?.takeIf(::isUsable)
            } catch (_: SecurityException) {
                null
            } catch (_: IllegalArgumentException) {
                null
            }
        }.minByOrNull { it.accuracy }
        val cached = bestFix
        if (cached != null && cached.accuracy <= 100f && ageMillis(cached) <= 20_000) {
            finish(cached)
            return
        }

        val requests = providers.associateWith { CancellationSignal() }
        signals.putAll(requests)
        handler.postDelayed(timeout, 15_000)
        val executor = ContextCompat.getMainExecutor(activity)
        for ((provider, signal) in requests) {
            if (pending == null) break
            try {
                LocationManagerCompat.getCurrentLocation(manager, provider, signal, executor) { location ->
                    if (signals[provider] === signal) candidate(provider, location, precise)
                }
            } catch (_: SecurityException) {
                candidate(provider, null, precise)
            } catch (_: IllegalArgumentException) {
                candidate(provider, null, precise)
            }
        }
    }

    private fun candidate(provider: String, location: Location?, precise: Boolean) {
        signals.remove(provider)
        if (location != null && isUsable(location)) {
            if (location.accuracy < (bestFix?.accuracy ?: Float.MAX_VALUE)) bestFix = location
            if (!precise || location.accuracy <= 100f) {
                finish(location)
                return
            }
        }
        if (signals.isEmpty()) finish(bestFix)
    }

    private fun ageMillis(location: Location): Long =
        (SystemClock.elapsedRealtimeNanos() - location.elapsedRealtimeNanos) / 1_000_000

    private fun isUsable(location: Location): Boolean =
        location.hasAccuracy() && location.accuracy <= 5_000f && ageMillis(location) in 0L..90_000L

    private fun finish(location: Location?, error: String? = null) {
        val result = pending
        pending = null
        val activeSignals = signals.values.toList()
        signals.clear()
        bestFix = null
        handler.removeCallbacks(timeout)
        activeSignals.forEach { it.cancel() }
        if (error != null) {
            result?.error(error, null, null)
        } else {
            result?.success(location?.let { mapOf("latitude" to it.latitude, "longitude" to it.longitude) })
        }
    }

    fun close() {
        finish(null)
        channel?.setMethodCallHandler(null)
        channel = null
    }

    private companion object {
        const val permissionRequest = 4311
    }
}
