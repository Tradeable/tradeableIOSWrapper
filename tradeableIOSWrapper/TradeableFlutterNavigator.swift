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
        binaryMessenger: FlutterEngineHolder.shared.embeddedEngine.binaryMessenger
    )

    private lazy var fullscreenMethodChannel = FlutterMethodChannel(
        name: "embedded_flutter/navigation",
        binaryMessenger: FlutterEngineHolder.shared.fullscreenEngine.binaryMessenger
    )
    
    private lazy var authChannel = FlutterMethodChannel(
        name: "embedded_flutter/auth",
        binaryMessenger: FlutterEngineHolder.shared.embeddedEngine.binaryMessenger
    )

    private lazy var fullscreenAuthChannel = FlutterMethodChannel(
        name: "embedded_flutter/auth",
        binaryMessenger: FlutterEngineHolder.shared.fullscreenEngine.binaryMessenger
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

        let channels: [(String, FlutterMethodChannel)] = [
            ("embedded", authChannel),
            ("fullscreen", fullscreenAuthChannel)
        ]

        var successCount = 0
        var finished = false

        for (label, channel) in channels {
            retryInvoke(
                channelLabel: label,
                channel: channel,
                method: "initializeTFS",
                arguments: params
            ) {
                DispatchQueue.main.async {
                    guard !finished else { return }
                    successCount += 1
                    if successCount == channels.count {
                        finished = true
                        print("[TFS] ✅ initializeTFS succeeded")
                        completion(true, nil)
                    }
                }
            } onFailure: { error in
                DispatchQueue.main.async {
                    guard !finished else { return }
                    finished = true
                    print("[TFS] ❌ initializeTFS failed: \(error)")
                    completion(false, error)
                }
            }
        }
    }

    private func retryInvoke(
        channelLabel: String,
        channel: FlutterMethodChannel,
        method: String,
        arguments: Any?,
        maxAttempts: Int = 20,
        retryDelay: TimeInterval = 0.5,
        watchdog: TimeInterval = 1.0,
        onSuccess: @escaping () -> Void,
        onFailure: @escaping (String) -> Void
    ) {
        var attempt = 0
        var completed = false

        func nextAttempt() {
            guard !completed, attempt < maxAttempts else {
                if !completed {
                    completed = true
                    onFailure("Timed out after \(attempt) attempts on \(channelLabel) channel")
                }
                return
            }

            attempt += 1
            let currentAttempt = attempt
            var replyReceived = false

            print("[TFS] \(channelLabel) attempt \(currentAttempt)/\(maxAttempts)")

            channel.invokeMethod(method, arguments: arguments) { result in
                DispatchQueue.main.async {
                    replyReceived = true
                    guard !completed, currentAttempt == attempt else { return }

                    if let error = result as? FlutterError {
                        print("[TFS] \(channelLabel) ❌ attempt \(currentAttempt): \(error.message ?? "Unknown error")")
                        DispatchQueue.main.asyncAfter(deadline: .now() + retryDelay) {
                            nextAttempt()
                        }
                    } else if let success = result as? Bool, success {
                        print("[TFS] \(channelLabel) ✅ succeeded on attempt \(currentAttempt)")
                        completed = true
                        onSuccess()
                    } else {
                        print("[TFS] \(channelLabel) ⚠️ attempt \(currentAttempt) unexpected result: \(String(describing: result))")
                        DispatchQueue.main.asyncAfter(deadline: .now() + retryDelay) {
                            nextAttempt()
                        }
                    }
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + watchdog) {
                guard !completed, currentAttempt == attempt, !replyReceived else { return }
                print("[TFS] \(channelLabel) ⏳ attempt \(currentAttempt) got no reply (Dart still booting?) — retrying")
                nextAttempt()
            }
        }

        nextAttempt()
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

    /// Open the Tradeable side drawer for a given page id.
    /// - Parameters:
    ///   - pageId: The page or topic tag id to render in the drawer.
    ///   - arguments: Optional extra data to forward to Flutter.
    public func openTradeableSideDrawer(pageId: Int, arguments: [String: Any]? = nil) {
        print("[TFS] openTradeableSideDrawer: \(pageId)")
        var params: [String: Any] = arguments ?? [:]
        params["pageId"] = pageId
        methodChannel.invokeMethod("openTradeableSideDrawer", arguments: params) { result in
            print("[TFS] openTradeableSideDrawer completed for pageId: \(pageId)")
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
        let channels = [methodChannel, fullscreenMethodChannel]

        for channel in channels {
            channel.setMethodCallHandler { call, result in
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
}
