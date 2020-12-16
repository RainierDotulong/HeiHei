#Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'broilerfarm' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for broilerfarm

pod 'SwiftyJSON'
pod 'Alamofire'
pod 'TextFieldEffects'
pod 'SVProgressHUD'
pod 'JGProgressHUD'
pod 'UIEmptyState'
pod 'EmptyStateKit'
pod 'SwiftSpreadsheet'
pod 'Charts'
pod 'FirebaseFirestoreSwift'
pod 'FirebaseCore'
pod 'Firebase/Auth'
pod 'Firebase/Database'
pod 'Firebase/Firestore'
pod 'Firebase/Messaging'
pod 'Firebase/Storage'
pod 'Fusuma'
pod 'FileBrowser'
pod 'ReachabilitySwift'
pod 'NotificationBannerSwift'
pod 'GSImageViewerController'
pod 'GoogleMaps'
pod 'GooglePlaces'
pod 'SideMenu'

post_install do |pi|
    pi.pods_project.targets.each do |t|
      t.build_configurations.each do |config|
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
      end
    end
end

end
