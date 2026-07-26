//
//  Generated file. Do not edit.
//

import FlutterMacOS
import Foundation

import multi_window_manager
import package_info_plus
import screen_retriever_macos
import shared_preferences_foundation
import tray_manager
import url_launcher_macos

func RegisterGeneratedPlugins(registry: FlutterPluginRegistry) {
  MultiWindowManagerPlugin.register(with: registry.registrar(forPlugin: "MultiWindowManagerPlugin"))
  FPPPackageInfoPlusPlugin.register(with: registry.registrar(forPlugin: "FPPPackageInfoPlusPlugin"))
  ScreenRetrieverMacosPlugin.register(with: registry.registrar(forPlugin: "ScreenRetrieverMacosPlugin"))
  SharedPreferencesPlugin.register(with: registry.registrar(forPlugin: "SharedPreferencesPlugin"))
  TrayManagerPlugin.register(with: registry.registrar(forPlugin: "TrayManagerPlugin"))
  UrlLauncherPlugin.register(with: registry.registrar(forPlugin: "UrlLauncherPlugin"))
}
