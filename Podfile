platform :ios, '13.0'

source 'https://github.com/CocoaPods/Specs.git'

target 'tradeableIOSWrapper' do
  use_frameworks!
  
  # Fetch Flutter from GitHub (main branch)
  flutter_module_path = 'flutter_module'
  
  # Clone Flutter module if not present
  unless File.exist?(flutter_module_path)
    system("git clone https://github.com/deepakgrandhi/tradeable_flutter_sdk_module.git #{flutter_module_path}")
  end
  
  # Pull latest from main
  system("cd #{flutter_module_path} && git pull origin sidedrawer_task")
  
  # Initialize Flutter module dependencies only (without building frameworks)
  system("cd #{flutter_module_path} && flutter pub get")
  
  # Load Flutter pods if available
  flutter_podhelper = File.join(flutter_module_path, '.ios', 'Flutter', 'podhelper.rb')
  if File.exist?(flutter_podhelper)
    load flutter_podhelper
    install_all_flutter_pods(flutter_module_path)
  end
end

# post_install do |installer|
#   flutter_post_install(installer) if defined?(flutter_post_install)
  
#   # Fix sandbox issues with Flutter
#   installer.pods_project.targets.each do |target|
#     flutter_additional_ios_build_settings(target)
#     target.build_configurations.each do |config|
#       config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
#         '$(inherited)',
#         'FLUTTER_ROOT=\$(SRCROOT)/flutter_module',
#       ]
#     end
#   end
# end

post_install do |installer|
  flutter_post_install(installer)
end
