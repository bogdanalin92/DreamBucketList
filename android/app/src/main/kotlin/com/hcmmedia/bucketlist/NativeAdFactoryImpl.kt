package com.hcmmedia.bucketlist

import android.content.Context
import android.view.LayoutInflater
import android.view.View
import android.widget.Button
import android.widget.ImageView
import android.widget.TextView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin.NativeAdFactory
import java.util.concurrent.atomic.AtomicReference

class NativeAdFactoryImpl(
    private val context: Context,
    private val factoryId: String
) : NativeAdFactory {
    private val nativeAd = AtomicReference<NativeAd?>()

    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: MutableMap<String, Any>?
    ): NativeAdView {
        val layoutId = when (factoryId) {
            "listTile" -> context.resources.getIdentifier(
                "list_tile_native_ad", "layout", context.packageName
            )
            "mediumRectangle" -> context.resources.getIdentifier(
                "medium_rectangle_native_ad", "layout", context.packageName
            )
            else -> throw IllegalArgumentException("Unknown factory id: $factoryId")
        }

        val nativeAdView = LayoutInflater.from(context)
            .inflate(layoutId, null) as NativeAdView

        // Set the media view
        nativeAdView.mediaView = nativeAdView.findViewById(
            context.resources.getIdentifier("ad_media", "id", context.packageName)
        )

        // Set other ad assets
        nativeAdView.headlineView = nativeAdView.findViewById(
            context.resources.getIdentifier("ad_headline", "id", context.packageName)
        )
        nativeAdView.bodyView = nativeAdView.findViewById(
            context.resources.getIdentifier("ad_body", "id", context.packageName)
        )
        nativeAdView.callToActionView = nativeAdView.findViewById(
            context.resources.getIdentifier("ad_call_to_action", "id", context.packageName)
        )
        nativeAdView.iconView = nativeAdView.findViewById(
            context.resources.getIdentifier("ad_icon", "id", context.packageName)
        )
        nativeAdView.advertiserView = nativeAdView.findViewById(
            context.resources.getIdentifier("ad_advertiser", "id", context.packageName)
        )
        
        // Transfer the data from the native ad to the views
        (nativeAdView.headlineView as TextView).text = nativeAd.headline
        nativeAdView.mediaView?.mediaContent = nativeAd.mediaContent

        if (nativeAd.body != null) {
            (nativeAdView.bodyView as TextView).text = nativeAd.body
            nativeAdView.bodyView?.visibility = View.VISIBLE
        } else {
            nativeAdView.bodyView?.visibility = View.INVISIBLE
        }

        if (nativeAd.callToAction != null) {
            (nativeAdView.callToActionView as Button).text = nativeAd.callToAction
            nativeAdView.callToActionView?.visibility = View.VISIBLE
        } else {
            nativeAdView.callToActionView?.visibility = View.INVISIBLE
        }

        if (nativeAd.icon != null) {
            (nativeAdView.iconView as ImageView).setImageDrawable(nativeAd.icon?.drawable)
            nativeAdView.iconView?.visibility = View.VISIBLE
        } else {
            nativeAdView.iconView?.visibility = View.GONE
        }

        if (nativeAd.advertiser != null) {
            (nativeAdView.advertiserView as TextView).text = nativeAd.advertiser
            nativeAdView.advertiserView?.visibility = View.VISIBLE
        } else {
            nativeAdView.advertiserView?.visibility = View.INVISIBLE
        }

        // Associate the native ad with the native ad view
        nativeAdView.setNativeAd(nativeAd)

        return nativeAdView
    }
}