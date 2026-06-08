import SwiftUI
import Flutter

final class FlutterHostChannelDispatcher {
    static let shared = FlutterHostChannelDispatcher()

    private var channel: FlutterMethodChannel?
    private var isInstalled = false

    private var closeCardHandler: (() -> Void)?
    private var closeFullscreenHandler: (() -> Void)?
    private var closeSideDrawerHandler: (() -> Void)?

    private init() {}

    func install(binaryMessenger: FlutterBinaryMessenger) {
        guard !isInstalled else { return }
        let methodChannel = FlutterMethodChannel(
            name: "embedded_flutter",
            binaryMessenger: binaryMessenger
        )
        methodChannel.setMethodCallHandler { [weak self] call, _ in
            self?.handle(call: call)
        }
        channel = methodChannel
        isInstalled = true
    }

    func updateHandlers(
        onCloseCard: (() -> Void)? = nil,
        onCloseFullscreen: (() -> Void)? = nil,
        onCloseSideDrawer: (() -> Void)? = nil
    ) {
        if let onCloseCard {
            closeCardHandler = onCloseCard
        }
        if let onCloseFullscreen {
            closeFullscreenHandler = onCloseFullscreen
        }
        if let onCloseSideDrawer {
            closeSideDrawerHandler = onCloseSideDrawer
        }
    }

    func sendSetData(arguments: [String: Any]) {
        channel?.invokeMethod("setData", arguments: arguments)
    }

    private func handle(call: FlutterMethodCall) {
        switch call.method {
        case "closeCard":
            DispatchQueue.main.async {
                FlutterEngineHolder.shared.detachController()
                if let closeCardHandler = self.closeCardHandler {
                    closeCardHandler()
                } else {
                    self.closeFullscreenHandler?()
                }
            }
        case "closeFullscreen":
            DispatchQueue.main.async {
                FlutterEngineHolder.shared.detachController()
                self.closeFullscreenHandler?()
            }
        case "closeSideDrawer":
            DispatchQueue.main.async {
                self.closeSideDrawerHandler?()
            }
        default:
            break
        }
    }
}

/// Public API for consumers to embed Flutter views
public struct TradeableFlutterView: View {
    public enum DisplayMode {
        case direct
        case cardFlip
        case fullscreen
        case fullscreenContent
        case dashboardContent
        case sideDrawer
    }
    
    let mode: DisplayMode
    let width: CGFloat
    let height: CGFloat
    let data: [String: Any]
    let topicId: Int?
    let pageId: Int?
    let onCloseSideDrawer: (() -> Void)?
    let onCloseFullscreen: (() -> Void)?
    
    @State private var isCardFlipped = false
    @State private var showFullscreen = false
    
    public init(
        mode: DisplayMode = .direct,
        width: CGFloat = 320,
        height: CGFloat = 220,
        data: [String: Any] = [:],
        topicId: Int? = nil,
        pageId: Int? = nil,
        onCloseSideDrawer: (() -> Void)? = nil,
        onCloseFullscreen: (() -> Void)? = nil
    ) {
        self.mode = mode
        self.width = width
        self.height = height
        self.data = data
        self.topicId = topicId
        self.pageId = pageId
        self.onCloseSideDrawer = onCloseSideDrawer
        self.onCloseFullscreen = onCloseFullscreen
    }
    
    public var body: some View {
        switch mode {
        case .direct:
            directView
        case .cardFlip:
            cardFlipView
        case .fullscreen:
            fullscreenButtonView
        case .fullscreenContent:
            fullscreenContentView
        case .dashboardContent:
            dashboardContentView
        case .sideDrawer:
            sideDrawerContentView
        }
    }
    
    // MARK: - Direct Display
    private var directView: some View {
        FlutterContainer(
            initialData: prepareData(mode: "direct")
        )
        .frame(width: width, height: height)
    }
    
    // MARK: - Card Flip Display
    private var cardFlipView: some View {
        ZStack {
            if isCardFlipped {
                FlutterContainer(
                    initialData: prepareData(mode: "card"),
                    onClose: {
                        isCardFlipped = false
                    }
                )
                .frame(width: width, height: height)
            } else {
                cardFrontView
            }
        }
        .frame(width: width, height: height)
    }
    
    private var cardFrontView: some View {
        Button(action: {
            isCardFlipped = true
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                VStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                    Text("Tap to Flip")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
        }
        .frame(width: width, height: height)
        .shadow(radius: 4)
    }
    
    // MARK: - Fullscreen Button
    private var fullscreenButtonTitle: String {
        (data["text"] as? String) ?? "Open Flutter Fullscreen"
    }

    private var fullscreenTriggerButton: some View {
        Button(action: {
            showFullscreen = true
        }) {
            HStack {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                Text(fullscreenButtonTitle)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
    }

    @ViewBuilder
    private var fullscreenButtonView: some View {
        if #available(iOS 14.0, *) {
            fullscreenTriggerButton
            .fullScreenCover(isPresented: $showFullscreen) {
                FlutterFullscreenView(
                    isPresented: $showFullscreen,
                    data: prepareData(mode: "fullscreen")
                )
            }
        } else {
            fullscreenTriggerButton
            .background(
                FullscreenPresenter(
                    isPresented: $showFullscreen,
                    data: prepareData(mode: "fullscreen")
                )
            )
        }
    }

    private var sideDrawerContentView: some View {
        FlutterContainer(
            initialData: prepareData(mode: "nativeSideDrawer"),
            onCloseSideDrawer: onCloseSideDrawer
        )
        .frame(width: width, height: height)
    }

    private var fullscreenContentView: some View {
        FlutterFullscreenContainer(
            initialData: prepareData(mode: "fullscreen"),
            onClose: {
                onCloseFullscreen?()
            }
        )
        .frame(width: width, height: height)
    }

    private var dashboardContentView: some View {
        FlutterFullscreenContainer(
            initialData: prepareData(mode: "dashboard"),
            onClose: {
                onCloseFullscreen?()
            }
        )
        .frame(width: width, height: height)
    }
    
    // MARK: - Helper
    private func prepareData(mode: String) -> [String: Any] {
        var finalData = data
        finalData["width"] = width
        finalData["height"] = height
        finalData["mode"] = mode
        if let topicId = topicId {
            finalData["topicId"] = topicId
        }
        if let pageId = pageId {
            finalData["pageId"] = pageId
        }
        return finalData
    }
}

// MARK: - Internal Flutter Container
struct FlutterContainer: UIViewControllerRepresentable {
    let initialData: [String: Any]
    var onClose: (() -> Void)? = nil
    var onCloseSideDrawer: (() -> Void)? = nil
    
    func makeUIViewController(context: Context) -> FlutterViewController {
        let controller = FlutterEngineHolder.shared.makeController()
        controller.view.backgroundColor = .clear

        let dispatcher = FlutterHostChannelDispatcher.shared
        dispatcher.install(binaryMessenger: controller.binaryMessenger)
        dispatcher.updateHandlers(
            onCloseCard: onClose,
            onCloseSideDrawer: onCloseSideDrawer
        )
        dispatcher.sendSetData(arguments: initialData)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: FlutterViewController, context: Context) {}
}

// MARK: - Internal Fullscreen View
struct FlutterFullscreenView: View {
    @Binding var isPresented: Bool
    let data: [String: Any]
    
    var body: some View {
        FlutterFullscreenContainer(
            initialData: data,
            onClose: {
                isPresented = false
            }
        )
    }
}

struct FlutterFullscreenContainer: UIViewControllerRepresentable {
    let initialData: [String: Any]
    let onClose: () -> Void
    
    func makeUIViewController(context: Context) -> FlutterViewController {
        let controller = FlutterEngineHolder.shared.makeController()

        let dispatcher = FlutterHostChannelDispatcher.shared
        dispatcher.install(binaryMessenger: controller.binaryMessenger)
        dispatcher.updateHandlers(onCloseFullscreen: onClose)
        dispatcher.sendSetData(arguments: initialData)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: FlutterViewController, context: Context) {}
}

struct FullscreenPresenter: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let data: [String: Any]

    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if isPresented {
            guard uiViewController.presentedViewController == nil else { return }

            let hostedView = FlutterFullscreenView(
                isPresented: $isPresented,
                data: data
            )
            let controller = UIHostingController(rootView: hostedView)
            controller.modalPresentationStyle = .fullScreen
            uiViewController.present(controller, animated: true)
        } else if uiViewController.presentedViewController != nil {
            uiViewController.dismiss(animated: true)
        }
    }
}
