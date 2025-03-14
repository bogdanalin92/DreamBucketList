import Foundation
import GoogleMobileAds

/// A native ad factory for list tile style ads
class ListTileNativeAdFactory: NSObject, FLTNativeAdFactory {
    func createNativeAd(_ nativeAd: GADNativeAd,
                        customOptions: [AnyHashable : Any]? = nil) -> GADNativeAdView? {
        // Load the nib that contains the native ad view
        let nibView = Bundle.main.loadNibNamed("ListTileNativeAdView", owner: nil, options: nil)?.first
        guard let nativeAdView = nibView as? GADNativeAdView else {
            return nil
        }
        
        // Set the headlineView
        (nativeAdView.headlineView as? UILabel)?.text = nativeAd.headline
        
        // Set the bodyView
        if let body = nativeAd.body {
            (nativeAdView.bodyView as? UILabel)?.text = body
            nativeAdView.bodyView?.isHidden = false
        } else {
            nativeAdView.bodyView?.isHidden = true
        }
        
        // Set the icon view
        if let icon = nativeAd.icon?.image {
            (nativeAdView.iconView as? UIImageView)?.image = icon
            nativeAdView.iconView?.isHidden = false
        } else {
            nativeAdView.iconView?.isHidden = true
        }
        
        // Set call to action
        (nativeAdView.callToActionView as? UIButton)?.setTitle(nativeAd.callToAction, for: .normal)
        nativeAdView.callToActionView?.isUserInteractionEnabled = false
        
        // Set up the price
        if let price = nativeAd.price {
            (nativeAdView.priceView as? UILabel)?.text = price
            nativeAdView.priceView?.isHidden = false
        } else {
            nativeAdView.priceView?.isHidden = true
        }
        
        // Set up the advertiser
        if let advertiser = nativeAd.advertiser {
            (nativeAdView.advertiserView as? UILabel)?.text = advertiser
            nativeAdView.advertiserView?.isHidden = false
        } else {
            nativeAdView.advertiserView?.isHidden = true
        }
        
        // Set up star rating if available
        if let starRating = nativeAd.starRating {
            (nativeAdView.starRatingView as? UIImageView)?.image = self.starRatingImage(for: starRating.doubleValue)
            nativeAdView.starRatingView?.isHidden = false
        } else {
            nativeAdView.starRatingView?.isHidden = true
        }
        
        // Set the mediaView
        if let mediaView = nativeAdView.mediaView {
            mediaView.mediaContent = nativeAd.mediaContent
        }
        
        // Register the native ad view with the native ad
        nativeAdView.nativeAd = nativeAd
        
        return nativeAdView
    }
    
    // Helper method to convert star rating to an image
    private func starRatingImage(for rating: Double) -> UIImage? {
        let starFilledImage = UIImage(named: "star_filled")
        let starEmptyImage = UIImage(named: "star_empty")
        
        // Implement custom star rating UI logic here if needed
        // This is a simplified implementation
        return rating >= 4.5 ? starFilledImage : starEmptyImage
    }
}