# Tradeable iOS Wrapper

Native iOS framework that wraps the Tradeable Flutter SDK module so you can embed Flutter-powered trading widgets in SwiftUI apps.

## Features

- SwiftUI-first embedding API through `TradeableFlutterView`
- Display modes: `direct`, `cardFlip`, `fullscreen`, `sideDrawer`, `fullscreenContent`, `dashboardContent`
- Flutter navigation bridge via `TradeableFlutterNavigator`
- Authentication/bootstrap bridge using `initializeTFS(...)`
- Bidirectional data channel between iOS and Flutter
- Shared Flutter engine management for efficient view reuse

## Installation

Add the wrapper pod and Flutter podhelper setup to your app `Podfile`:

```ruby
platform :ios, '13.0'

flutter_module_path = 'flutter_module'

unless File.exist?(flutter_module_path)
  system("git clone https://github.com/deepakgrandhi/tradeable_flutter_sdk_module.git #{flutter_module_path}")
end

system("cd #{flutter_module_path} && git pull origin main && flutter pub get")

flutter_podhelper = File.join(flutter_module_path, '.ios', 'Flutter', 'podhelper.rb')
load flutter_podhelper if File.exist?(flutter_podhelper)

target 'YourApp' do
  use_frameworks!

  install_all_flutter_pods(flutter_module_path)
  pod 'tradeableIOSWrapper', :git => 'https://github.com/deepakgrandhi/tradeableIOSWrapper.git'
end

post_install do |installer|
  flutter_post_install(installer) if defined?(flutter_post_install)
end
```

Install pods:

```bash
pod install
```

## Quick Start

### 1. Initialize SDK bridge

```swift
import tradeableIOSWrapper

let navigator = TradeableFlutterNavigator.shared

navigator.initializeTFS(
    baseUrl: "https://your-api-base-url.com",
    authToken: "user_auth_token",
    portalToken: "portal_token",
    appId: "your_app_id",
    clientId: "your_client_id",
    publicKey: "your_public_key"
) { success, error in
    if success {
        print("TFS initialized successfully")
    } else {
        print("TFS initialization failed: \(error ?? "Unknown error")")
    }
}
```

### 2. Embed Flutter widgets

```swift
// Direct mode
TradeableFlutterView(
    mode: .direct,
    width: 320,
    height: 220,
    data: ["text": "Trading Widget"]
)

// Card flip mode
TradeableFlutterView(
    mode: .cardFlip,
    width: 320,
    height: 220,
    data: ["text": "Tap to Flip"]
)

// Fullscreen mode
TradeableFlutterView(
    mode: .fullscreen,
    data: ["text": "Open Fullscreen"],
    topicId: 6
)

// Side drawer mode (content hosted in native drawer)
TradeableFlutterView(
    mode: .sideDrawer,
    width: 360,
    height: 720,
    data: ["text": "Native Side Drawer"],
    pageId: 6,
    onCloseSideDrawer: {
        // close your native drawer state
    }
)

// Fullscreen content modes (opened by native host)
TradeableFlutterView(
    mode: .fullscreenContent,
    topicId: 6,
    onCloseFullscreen: {
        // dismiss native fullscreen host
    }
)

TradeableFlutterView(
    mode: .dashboardContent,
    onCloseFullscreen: {
        // dismiss native fullscreen host
    }
)
```

### 2a. Native Side Nav Implementation (SwiftUI)

```swift
@State private var showNativeDrawer = false
@State private var presentedScreen: PresentedTradeableScreen?

ZStack(alignment: .trailing) {
    // your screen content

    if showNativeDrawer {
        Color.black.opacity(0.25)
            .ignoresSafeArea()
            .onTapGesture { showNativeDrawer = false }

        TradeableFlutterView(
            mode: .sideDrawer,
            width: proxy.size.width - 32,
            height: proxy.size.height,
            pageId: 6,
            onCloseSideDrawer: { showNativeDrawer = false }
        )
        .background(Color.white)
        .frame(width: proxy.size.width - 32, height: proxy.size.height)
        .transition(.move(edge: .trailing))
    }
}
.fullScreenCover(item: $presentedScreen) { screen in
    switch screen {
    case .topic(let topicId):
        TradeableFlutterView(mode: .fullscreenContent, topicId: topicId)
    case .dashboard:
        TradeableFlutterView(mode: .dashboardContent)
    }
}
.onAppear {
    TradeableFlutterNavigator.shared.registerDataHandler { payload in
        guard let action = payload["action"] as? String else { return }
        showNativeDrawer = false

        switch action {
        case "openTopic":
            if let topicId = payload["topicId"] as? Int { presentedScreen = .topic(topicId) }
        case "openDashboard":
            presentedScreen = .dashboard
        default:
            break
        }
    }
}
```

### 3. Control navigation and data

```swift
let nav = TradeableFlutterNavigator.shared

nav.navigateTo("/course/details", arguments: ["courseId": "123"])
nav.replace("/dashboard")
nav.popToRoot("/")
nav.goBack()

nav.sendData(["key": "value"])

nav.registerDataHandler { payload in
    print("Received from Flutter: \(payload)")
}
```

### Method Channel Contract (for host apps)

Channels:

- `embedded_flutter`
- `embedded_flutter/auth`
- `embedded_flutter/navigation`

Host -> Flutter:

- `embedded_flutter.setData`
- `embedded_flutter/auth.initializeTFS`
- `embedded_flutter/navigation.openTradeableSideDrawer`
- `embedded_flutter/navigation.navigateTo`
- `embedded_flutter/navigation.replaceRoute`
- `embedded_flutter/navigation.popToRoot`
- `embedded_flutter/navigation.receiveData`

Flutter -> Host:

- `embedded_flutter.closeCard`
- `embedded_flutter.closeFullscreen`
- `embedded_flutter.closeSideDrawer`
- `embedded_flutter/navigation.sendData` (examples: `openTopic`, `openDashboard`)

## API Reference

### TradeableFlutterNavigator

| Method | Description |
|--------|-------------|
| `initializeTFS(baseUrl:authToken:portalToken:appId:clientId:publicKey:completion:)` | Sends auth/bootstrap config to Flutter |
| `navigateTo(_:arguments:)` | Push route in Flutter |
| `goBack()` | Navigate back in Flutter |
| `replace(_:arguments:)` | Replace current Flutter route |
| `popToRoot(_:arguments:)` | Clear stack and navigate to route |
| `sendData(_:)` | Send arbitrary payload to Flutter |
| `registerDataHandler(_:)` | Receive payload from Flutter |

### TradeableFlutterView

| Parameter | Type | Description |
|----------|------|-------------|
| `mode` | `DisplayMode` | `.direct`, `.cardFlip`, `.fullscreen`, `.sideDrawer`, `.fullscreenContent`, `.dashboardContent` |
| `width` | `CGFloat` | View width (used by direct/card modes) |
| `height` | `CGFloat` | View height (used by direct/card modes) |
| `data` | `[String: Any]` | Initial payload sent to Flutter |
| `topicId` | `Int?` | Optional topic identifier forwarded to Flutter |
| `pageId` | `Int?` | Optional page identifier for drawer content |
| `onCloseSideDrawer` | `(() -> Void)?` | Called when Flutter asks host to close drawer |
| `onCloseFullscreen` | `(() -> Void)?` | Called when Flutter asks host to close fullscreen |

## Requirements

- iOS 13.0+
- Swift 5.0+
- Xcode 14+
- Flutter SDK available on machine running `pod install`

## Project Structure

```text
tradeableIOSWrapper/
├── tradeableIOSWrapper/
│   ├── TradeableFlutterView.swift
│   ├── TradeableFlutterNavigator.swift
│   ├── FlutterEngineHolder.swift
│   └── tradeableIOSWrapper.h
├── flutter_module/
├── Podfile
└── tradeableIOSWrapper.podspec
```

## Troubleshooting

### Flutter UI not appearing

1. Confirm `install_all_flutter_pods(flutter_module_path)` is in your target.
2. Re-run `pod install` after Flutter module changes.
3. Verify `initializeTFS(...)` is called before showing widgets.

### Navigation or channel callbacks not firing

1. Ensure route/method names match Flutter-side handlers.
2. Check Xcode logs for `[TFS]` messages emitted by wrapper classes.

## License

MIT