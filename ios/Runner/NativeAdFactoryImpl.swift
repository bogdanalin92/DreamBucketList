import GoogleMobileAds
import Flutter

class ListTileNativeAdFactory: FLTNativeAdFactory {
    
    func createNativeAd(_ nativeAd: GADNativeAd,
                        customOptions: [String: Any]? = nil) -> GADNativeAdView? {
        let nibView = Bundle.main.loadNibNamed("ListTileNativeAdView", owner: nil, options: nil)?.first
        guard let nativeAdView = nibView as? GADNativeAdView else {
            return nil
        }
        
        // Set the ad on the view
        (nativeAdView.headlineView as? UILabel)?.text = nativeAd.headline
        
        // Optional components
        (nativeAdView.bodyView as? UILabel)?.text = nativeAd.body
        (nativeAdView.bodyView as? UILabel)?.isHidden = nativeAd.body == nil
        
        (nativeAdView.iconView as? UIImageView)?.image = nativeAd.icon?.image
        nativeAdView.iconView?.isHidden = nativeAd.icon == nil
        
        (nativeAdView.starRatingView as? UIImageView)?.isHidden = nativeAd.starRating == nil
        
        (nativeAdView.advertiserView as? UILabel)?.text = nativeAd.advertiser
        nativeAdView.advertiserView?.isHidden = nativeAd.advertiser == nil
        
        (nativeAdView.priceView as? UILabel)?.text = nativeAd.price
        nativeAdView.priceView?.isHidden = nativeAd.price == nil
        
        (nativeAdView.callToActionView as? UIButton)?.setTitle(nativeAd.callToAction, for: .normal)
        nativeAdView.callToActionView?.isHidden = nativeAd.callToAction == nil
        
        // Media view might be hidden in this layout, it depends on design
        nativeAdView.mediaView?.isHidden = true
        
        // Set this native ad as the nativeAdView's ad
        nativeAdView.nativeAd = nativeAd
        
        return nativeAdView
    }
}

class MediumRectangleNativeAdFactory: FLTNativeAdFactory {
    
    func createNativeAd(_ nativeAd: GADNativeAd,
                        customOptions: [String: Any]? = nil) -> GADNativeAdView? {
        let nibView = Bundle.main.loadNibNamed("MediumRectangleNativeAdView", owner: nil, options: nil)?.first
        guard let nativeAdView = nibView as? GADNativeAdView else {
            return nil
        }
        
        // Set the ad on the view
        (nativeAdView.headlineView as? UILabel)?.text = nativeAd.headline
        
        // Optional components
        (nativeAdView.bodyView as? UILabel)?.text = nativeAd.body
        (nativeAdView.bodyView as? UILabel)?.isHidden = nativeAd.body == nil
        
        (nativeAdView.iconView as? UIImageView)?.image = nativeAd.icon?.image
        nativeAdView.iconView?.isHidden = nativeAd.icon == nil
        
        (nativeAdView.starRatingView as? UIImageView)?.isHidden = nativeAd.starRating == nil
        
        (nativeAdView.advertiserView as? UILabel)?.text = nativeAd.advertiser
        nativeAdView.advertiserView?.isHidden = nativeAd.advertiser == nil
        
        (nativeAdView.priceView as? UILabel)?.text = nativeAd.price
        nativeAdView.priceView?.isHidden = nativeAd.price == nil
        
        (nativeAdView.callToActionView as? UIButton)?.setTitle(nativeAd.callToAction, for: .normal)
        nativeAdView.callToActionView?.isHidden = nativeAd.callToAction == nil
        
        // In this layout, the media view should be visible
        nativeAdView.mediaView?.mediaContent = nativeAd.mediaContent
        
        // Set this native ad as the nativeAdView's ad
        nativeAdView.nativeAd = nativeAd
        
        return nativeAdView
    }
}