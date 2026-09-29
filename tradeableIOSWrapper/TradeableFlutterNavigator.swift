//
//  TradeableFlutterNavigator.swift
//  tradeableIOSWrapper
//
//  Created by Deepak Grandhi on 12/01/26.
//

import Foundation
import Flutter
import os

private let tfsLogger = Logger(subsystem: "tradeableIOSWrapper", category: "TFS")

/// Logs to the unified log so entries survive the app being killed
/// and can be read later with `log show --predicate 'subsystem == "tradeableIOSWrapper"'`.
func tfsLog(_ message: String) {
    tfsLogger.notice("\(message, privacy: .public)")
}

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
        tfsLog("TradeableFlutterNavigator initialized")
    }
    
    public func initializeTFS(
        baseUrl: String,
        authToken: String,
        portalToken: String,
        appId: String,
        clientId: String,
        publicKey: String,
        progress: ((String) -> Void)? = nil,
        completion: @escaping (Bool, String?) -> Void
    ) {
        tfsLog("initializeTFS called")
        tfsLog("baseUrl: \(baseUrl)")
        tfsLog("appId: \(appId)")
        tfsLog("clientId: \(clientId)")

        let params: [String: Any] = [
            "baseUrl": baseUrl,
            "authToken": authToken,
            "portalToken": portalToken,
            "appId": appId,
            "clientId": clientId,
            "publicKey": publicKey
        ]

        var finished = false

        func finish(_ success: Bool, _ error: String?) {
            DispatchQueue.main.async {
                guard !finished else { return }
                finished = true
                if success {
                    tfsLog("✅ initializeTFS succeeded")
                    completion(true, nil)
                } else {
                    tfsLog("❌ initializeTFS failed: \(error ?? "Unknown error")")
                    completion(false, error)
                }
            }
        }

        retryInvoke(
            channelLabel: "embedded",
            channel: authChannel,
            method: "initializeTFS",
            arguments: params,
            onProgress: progress
        ) {
            finish(true, nil)
        } onFailure: { error in
            finish(false, error)
        }

        retryInvoke(
            channelLabel: "fullscreen",
            channel: fullscreenAuthChannel,
            method: "initializeTFS",
            arguments: params,
            onProgress: progress
        ) {
            tfsLog("⚙️ fullscreen engine also initialized (background)")
        } onFailure: { error in
            tfsLog("⚠️ fullscreen engine not responding (non-fatal): \(error)")
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
        onProgress: ((String) -> Void)? = nil,
        onSuccess: @escaping () -> Void,
        onFailure: @escaping (String) -> Void
    ) {
        var attempt = 0
        var completed = false

        func report(_ message: String) {
            onProgress?(message)
        }

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

            tfsLog("\(channelLabel) attempt \(currentAttempt)/\(maxAttempts)")
            report("\(channelLabel): attempt \(currentAttempt)/\(maxAttempts)…")

            channel.invokeMethod(method, arguments: arguments) { result in
                DispatchQueue.main.async {
                    replyReceived = true
                    guard !completed, currentAttempt == attempt else { return }

                    if let error = result as? FlutterError {
                        tfsLog("\(channelLabel) ❌ attempt \(currentAttempt): \(error.message ?? "Unknown error")")
                        report("\(channelLabel): attempt \(currentAttempt) error → \(error.message ?? "Unknown error")")
                        DispatchQueue.main.asyncAfter(deadline: .now() + retryDelay) {
                            nextAttempt()
                        }
                    } else if let success = result as? Bool, success {
                        tfsLog("\(channelLabel) ✅ succeeded on attempt \(currentAttempt)")
                        report("\(channelLabel): ✅ ok on attempt \(currentAttempt)")
                        completed = true
                        onSuccess()
                    } else {
                        tfsLog("\(channelLabel) ⚠️ attempt \(currentAttempt) unexpected result: \(String(describing: result))")
                        report("\(channelLabel): attempt \(currentAttempt) unexpected result")
                        DispatchQueue.main.asyncAfter(deadline: .now() + retryDelay) {
                            nextAttempt()
                        }
                    }
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + watchdog) {
                guard !completed, currentAttempt == attempt, !replyReceived else { return }
                tfsLog("\(channelLabel) ⏳ attempt \(currentAttempt) got no reply (Dart still booting?) — retrying")
                report("\(channelLabel): no reply to attempt \(currentAttempt) → retrying")
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
        tfsLog("navigateTo: \(route)")
        if let args = arguments {
            tfsLog("with arguments: \(args)")
        }
        let params: [String: Any] = [
            "route": route,
            "arguments": arguments ?? [:]
        ]
        methodChannel.invokeMethod("navigateTo", arguments: params) { result in
            tfsLog("navigateTo completed for route: \(route)")
        }
    }
    
    /// Go back to the previous route
    public func goBack() {
        tfsLog("goBack called")
        methodChannel.invokeMethod("goBack", arguments: nil) { result in
            tfsLog("goBack completed")
        }
    }

    /// Open the Tradeable side drawer for a given page id.
    /// - Parameters:
    ///   - pageId: The page or topic tag id to render in the drawer.
    ///   - arguments: Optional extra data to forward to Flutter.
    public func openTradeableSideDrawer(pageId: Int, arguments: [String: Any]? = nil) {
        tfsLog("openTradeableSideDrawer: \(pageId)")
        var params: [String: Any] = arguments ?? [:]
        params["pageId"] = pageId
        methodChannel.invokeMethod("openTradeableSideDrawer", arguments: params) { result in
            tfsLog("openTradeableSideDrawer completed for pageId: \(pageId)")
        }
    }
    
    /// Replace current route with a new one
    /// - Parameters:
    ///   - route: The route name to navigate to
    ///   - arguments: Optional data to pass to the route
    public func replace(_ route: String, arguments: [String: Any]? = nil) {
        tfsLog("replace route: \(route)")
        if let args = arguments {
            tfsLog("with arguments: \(args)")
        }
        let params: [String: Any] = [
            "route": route,
            "arguments": arguments ?? [:]
        ]
        methodChannel.invokeMethod("replaceRoute", arguments: params) { result in
            tfsLog("replace completed for route: \(route)")
        }
    }
    
    /// Clear all routes and navigate to a new one
    /// - Parameters:
    ///   - route: The route name to navigate to
    ///   - arguments: Optional data to pass to the route
    public func popToRoot(_ route: String = "/", arguments: [String: Any]? = nil) {
        tfsLog("popToRoot: \(route)")
        if let args = arguments {
            tfsLog("with arguments: \(args)")
        }
        let params: [String: Any] = [
            "route": route,
            "arguments": arguments ?? [:]
        ]
        methodChannel.invokeMethod("popToRoot", arguments: params) { result in
            tfsLog("popToRoot completed for route: \(route)")
        }
    }
    
    /// Send data to the current Flutter view
    /// - Parameters:
    ///   - data: Dictionary of data to send
    public func sendData(_ data: [String: Any]) {
        tfsLog("sendData: \(data)")
        methodChannel.invokeMethod("receiveData", arguments: data) { result in
            tfsLog("sendData completed")
        }
    }
    
    /// Register a handler for receiving data from Flutter
    /// - Parameter handler: Closure called when Flutter sends data
    public func registerDataHandler(_ handler: @escaping ([String: Any]) -> Void) {
        tfsLog("registerDataHandler called")
        let channels = [methodChannel, fullscreenMethodChannel]

        for channel in channels {
            channel.setMethodCallHandler { call, result in
                if call.method == "sendData" {
                    tfsLog("Received data from Flutter: \(call.arguments ?? [:])")
                    if let arguments = call.arguments as? [String: Any] {
                        handler(arguments)
                    }
                }
                result(nil)
            }
        }
    }
}
