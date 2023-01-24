# Uncomment the next line to define a global platform for your project
# platform :ios, '15.4'

target 'Portal' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!
  use_modular_headers!

  # ignore all warnings from all pods
  inhibit_all_warnings!

  # Pods for Portal
  pod 'EthereumKit-Universal'
  pod 'Erc20Kit-Universal'
  #ToolKits
  pod 'Hodler-Universal.swift'

end


post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['DEBUG_INFORMATION_FORMAT'] = 'dwarf'
      config.build_settings['ENABLE_BITCODE'] = 'NO'
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.4'
    end

    if target.respond_to?(:product_type) and target.product_type == "com.apple.product-type.bundle"
      target.build_configurations.each do |config|
        config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
      end
    end
  end
end
