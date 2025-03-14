import Flutter
import UIKit
import GoogleMobileAds

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Initialize the Google Mobile Ads SDK
    GADMobileAds.sharedInstance().start(completionHandler: nil)
    
    // Register native ad factories
    let listTileFactory = ListTileNativeAdFactory()
    FLTGoogleMobileAdsPlugin.registerNativeAdFactory(
        self,
        factoryId: "listTile",
        nativeAdFactory: listTileFactory)
    
    let mediumRectangleFactory = MediumRectangleNativeAdFactory()
    FLTGoogleMobileAdsPlugin.registerNativeAdFactory(
        self,
        factoryId: "mediumRectangle",
        nativeAdFactory: mediumRectangleFactory)
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  override func applicationWillTerminate(_ application: UIApplication) {
    // Unregister native ad factories when app terminates
    FLTGoogleMobileAdsPlugin.unregisterNativeAdFactory(self, factoryId: "listTile")
    FLTGoogleMobileAdsPlugin.unregisterNativeAdFactory(self, factoryId: "mediumRectangle")
  }
}
