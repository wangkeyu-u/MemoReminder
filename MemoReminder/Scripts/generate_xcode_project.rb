require "xcodeproj"
require "fileutils"

root = File.expand_path("..", __dir__)
project_path = File.join(root, "MemoReminder.xcodeproj")

FileUtils.rm_rf(project_path)

project = Xcodeproj::Project.new(project_path)

app_target = project.new_target(:application, "MemoReminder", :ios, "17.0")
widget_target = project.new_target(:app_extension, "MemoReminderWidgetsExtension", :ios, "17.0")

app_group = project.main_group.new_group("MemoReminderApp", "MemoReminderApp")
shared_group = project.main_group.new_group("Shared", "Shared")
widget_group = project.main_group.new_group("MemoReminderWidgets", "MemoReminderWidgets")

def add_sources(group, target, paths)
  paths.each do |path|
    ref = group.new_file(path)
    target.source_build_phase.add_file_reference(ref)
  end
end

def add_resource(group, target, path)
  ref = group.new_file(path)
  target.resources_build_phase.add_file_reference(ref)
end

app_sources = [
  "MemoReminderApp.swift",
  "Models/Reminder.swift",
  "Services/ReminderStore.swift",
  "Services/NotificationScheduler.swift",
  "Services/LiveActivityManager.swift",
  "Views/ContentView.swift",
  "Views/DashboardHeader.swift",
  "Views/PermissionBanner.swift",
  "Views/ReminderComposerCard.swift",
  "Views/SearchField.swift",
  "Views/ReminderRow.swift",
  "Views/ReminderSection.swift",
  "Views/ReminderEditorView.swift",
  "Views/ReminderDetailView.swift"
]

add_sources(app_group, app_target, app_sources)

shared_ref = shared_group.new_file("ReminderActivityAttributes.swift")
app_target.source_build_phase.add_file_reference(shared_ref)
widget_target.source_build_phase.add_file_reference(shared_ref)

widget_ref = widget_group.new_file("ReminderLiveActivityWidget.swift")
widget_target.source_build_phase.add_file_reference(widget_ref)

app_info = app_group.new_file("Info.plist")
widget_info = widget_group.new_file("Info.plist")
app_entitlements = app_group.new_file("MemoReminder.entitlements")
widget_entitlements = widget_group.new_file("MemoReminderWidgets.entitlements")

add_resource(app_group, app_target, "Assets.xcassets")
add_resource(app_group, app_target, "PrivacyInfo.xcprivacy")
add_resource(widget_group, widget_target, "PrivacyInfo.xcprivacy")

app_target.add_dependency(widget_target)
embed_phase = app_target.new_copy_files_build_phase("Embed App Extensions")
embed_phase.symbol_dst_subfolder_spec = :plug_ins
embedded_extension = embed_phase.add_file_reference(widget_target.product_reference)
embedded_extension.settings = { "ATTRIBUTES" => ["CodeSignOnCopy", "RemoveHeadersOnCopy"] }

project.targets.each do |target|
  target.build_configurations.each do |config|
    config.build_settings["CODE_SIGN_STYLE"] = "Automatic"
    config.build_settings["IPHONEOS_DEPLOYMENT_TARGET"] = "17.0"
    config.build_settings["SDKROOT"] = "iphoneos"
    config.build_settings["SUPPORTED_PLATFORMS"] = "iphoneos iphonesimulator"
    config.build_settings["SUPPORTS_MACCATALYST"] = "NO"
    config.build_settings["SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD"] = "NO"
    config.build_settings["SWIFT_VERSION"] = "5.0"
    config.build_settings["TARGETED_DEVICE_FAMILY"] = "1,2"
    config.build_settings["ENABLE_PREVIEWS"] = "YES"
    config.build_settings["CURRENT_PROJECT_VERSION"] = "1"
    config.build_settings["MARKETING_VERSION"] = "1.0"
    config.build_settings["DEVELOPMENT_LANGUAGE"] = "zh-Hans"
    config.build_settings["DEAD_CODE_STRIPPING"] = "YES"
  end
end

app_target.build_configurations.each do |config|
  config.build_settings["PRODUCT_BUNDLE_IDENTIFIER"] = "com.wangkeyu.memoreminder"
  config.build_settings["PRODUCT_NAME"] = "$(TARGET_NAME)"
  config.build_settings["INFOPLIST_FILE"] = "MemoReminderApp/Info.plist"
  config.build_settings["CODE_SIGN_ENTITLEMENTS"] = "MemoReminderApp/MemoReminder.entitlements"
  config.build_settings["ASSETCATALOG_COMPILER_APPICON_NAME"] = "AppIcon"
  config.build_settings["ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME"] = "AccentColor"
end

widget_target.build_configurations.each do |config|
  config.build_settings["PRODUCT_BUNDLE_IDENTIFIER"] = "com.wangkeyu.memoreminder.widgets"
  config.build_settings["PRODUCT_NAME"] = "$(TARGET_NAME)"
  config.build_settings["INFOPLIST_FILE"] = "MemoReminderWidgets/Info.plist"
  config.build_settings["CODE_SIGN_ENTITLEMENTS"] = "MemoReminderWidgets/MemoReminderWidgets.entitlements"
  config.build_settings["SKIP_INSTALL"] = "YES"
  config.build_settings["APPLICATION_EXTENSION_API_ONLY"] = "YES"
  config.build_settings["LD_RUNPATH_SEARCH_PATHS"] = "$(inherited) @executable_path/Frameworks @executable_path/../../Frameworks"
end

project.save

puts "Generated #{project_path}"
