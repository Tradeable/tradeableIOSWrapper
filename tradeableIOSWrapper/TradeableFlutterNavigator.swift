//
//  TradeableFlutterNavigator.swift
//  tradeableIOSWrapper
//
//  Created by Deepak Grandhi on 12/01/26.
//

import Foundation
import Flutter

/// Public API for managing Flutter navigation and authentication
public class TradeableFlutterNavigator {
    public static let shared = TradeableFlutterNavigator()
    
    private lazy var methodChannel = FlutterMethodChannel(
        name: "embedded_flutter/navigation",
        binaryMessenger: FlutterEngineHolder.shared.engine.binaryMessenger
    )
    
    private lazy var authChannel = FlutterMethodChannel(
        name: "embedded_flutter/auth",
        binaryMessenger: FlutterEngineHolder.shared.engine.binaryMessenger
    )
    
    private init() {
        print("[TFS] TradeableFlutterNavigator initialized")
    }
    
    public func initializeTFS(
        baseUrl: String,
        authToken: String,
        portalToken: String,
        appId: String,
        clientId: String,
        publicKey: String,
        completion: @escaping (Bool, String?) -> Void
    ) {
        print("[TFS] initializeTFS called")
        print("[TFS] baseUrl: \(baseUrl)")
        print("[TFS] appId: \(appId)")
        print("[TFS] clientId: \(clientId)")
        
        let params: [String: Any] = [
            "baseUrl": baseUrl,
            "authToken": authToken,
            "portalToken": portalToken,
            "appId": appId,
            "clientId": clientId,
            "publicKey": publicKey
        ]
        
        authChannel.invokeMethod("initializeTFS", arguments: params) { result in
            if let error = result as? FlutterError {
                print("[TFS] ❌ initializeTFS failed: \(error.message ?? "Unknown error")")
                completion(false, error.message)
            } else if let success = result as? Bool {
                print("[TFS] ✅ initializeTFS succeeded")
                completion(success, nil)
            } else {
                print("[TFS] ✅ initializeTFS completed")
                completion(true, nil)
            }
        }
    }
    
    // MARK: - Navigation
    
    /// Navigate to a specific route in Flutter
    /// - Parameters:
    ///   - route: The route name to navigate to
    ///   - arguments: Optional data to pass to the route
    public func navigateTo(_ route: String, arguments: [String: Any]? = nil) {
        print("[TFS] navigateTo: \(route)")
        if let args = arguments {
            print("[TFS] with arguments: \(args)")
        }
        let params: [String: Any] = [
            "route": route,
            "arguments": arguments ?? [:]
        ]
        methodChannel.invokeMethod("navigateTo", arguments: params) { result in
            print("[TFS] navigateTo completed for route: \(route)")
        }
    }
    
    /// Go back to the previous route
    public func goBack() {
        print("[TFS] goBack called")
        methodChannel.invokeMethod("goBack", arguments: nil) { result in
            print("[TFS] goBack completed")
        }
    }
    
    /// Replace current route with a new one
    /// - Parameters:
    ///   - route: The route name to navigate to
    ///   - arguments: Optional data to pass to the route
    public func replace(_ route: String, arguments: [String: Any]? = nil) {
        print("[TFS] replace route: \(route)")
        if let args = arguments {
            print("[TFS] with arguments: \(args)")
        }
        let params: [String: Any] = [
            "route": route,
            "arguments": arguments ?? [:]
        ]
        methodChannel.invokeMethod("replaceRoute", arguments: params) { result in
            print("[TFS] replace completed for route: \(route)")
        }
    }
    
    /// Clear all routes and navigate to a new one
    /// - Parameters:
    ///   - route: The route name to navigate to
    ///   - arguments: Optional data to pass to the route
    public func popToRoot(_ route: String = "/", arguments: [String: Any]? = nil) {
        print("[TFS] popToRoot: \(route)")
        if let args = arguments {
            print("[TFS] with arguments: \(args)")
        }
        let params: [String: Any] = [
            "route": route,
            "arguments": arguments ?? [:]
        ]
        methodChannel.invokeMethod("popToRoot", arguments: params) { result in
            print("[TFS] popToRoot completed for route: \(route)")
        }
    }
    
    /// Send data to the current Flutter view
    /// - Parameters:
    ///   - data: Dictionary of data to send
    public func sendData(_ data: [String: Any]) {
        print("[TFS] sendData: \(data)")
        methodChannel.invokeMethod("receiveData", arguments: data) { result in
            print("[TFS] sendData completed")
        }
    }
    
    /// Register a handler for receiving data from Flutter
    /// - Parameter handler: Closure called when Flutter sends data
    public func registerDataHandler(_ handler: @escaping ([String: Any]) -> Void) {
        print("[TFS] registerDataHandler called")
        methodChannel.setMethodCallHandler { call, result in
            if call.method == "sendData" {
                print("[TFS] Received data from Flutter: \(call.arguments ?? [:])")
                if let arguments = call.arguments as? [String: Any] {
                    handler(arguments)
                }
            }
            result(nil)
        }
    }
}
