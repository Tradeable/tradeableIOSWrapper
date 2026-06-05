import SwiftUI
import Flutter

/// Public API for consumers to embed Flutter views
public struct TradeableFlutterView: View {
    public enum DisplayMode {
        case direct
        case cardFlip
        case fullscreen
    }
    
    let mode: DisplayMode
    let width: CGFloat
    let height: CGFloat
    let data: [String: Any]
    let topicId: Int?
    
    @State private var isCardFlipped = false
    @State private var showFullscreen = false
    
    public init(
        mode: DisplayMode = .direct,
        width: CGFloat = 320,
        height: CGFloat = 220,
        data: [String: Any] = [:],
        topicId: Int? = nil
    ) {
        self.mode = mode
        self.width = width
        self.height = height
        self.data = data
        self.topicId = topicId
    }
    
    public var body: some View {
        switch mode {
        case .direct:
            directView
        case .cardFlip:
            cardFlipView
        case .fullscreen:
            fullscreenButtonView
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
    private var fullscreenButtonView: some View {
        VStack {
            Button(action: {
                showFullscreen = true
            }) {
                HStack {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                    Text("Open Flutter Fullscreen")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .fullScreenCover(isPresented: $showFullscreen) {
            FlutterFullscreenView(
                isPresented: $showFullscreen,
                data: prepareData(mode: "fullscreen")
            )
        }
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
        return finalData
    }
}

// MARK: - Internal Flutter Container
struct FlutterContainer: UIViewControllerRepresentable {
    let initialData: [String: Any]
    var onClose: (() -> Void)? = nil
    
    func makeUIViewController(context: Context) -> FlutterViewController {
        let controller = FlutterEngineHolder.shared.makeController()
        controller.view.backgroundColor = .clear
        
        let channel = FlutterMethodChannel(
            name: "embedded_flutter",
            binaryMessenger: controller.binaryMessenger
        )
        
        channel.setMethodCallHandler { call, _ in
            if call.method == "closeCard" {
                FlutterEngineHolder.shared.detachController()
                onClose?()
            }
        }
        
        channel.invokeMethod("setData", arguments: initialData)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: FlutterViewController, context: Context) {}
}

// MARK: - Internal Fullscreen View
struct FlutterFullscreenView: View {
    @Binding var isPresented: Bool
    let data: [String: Any]
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            FlutterFullscreenContainer(
                initialData: data,
                onClose: {
                    isPresented = false
                }
            )
            
            Button(action: {
                isPresented = false
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.white)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
            }
            .padding()
        }
    }
}

struct FlutterFullscreenContainer: UIViewControllerRepresentable {
    let initialData: [String: Any]
    let onClose: () -> Void
    
    func makeUIViewController(context: Context) -> FlutterViewController {
        let controller = FlutterEngineHolder.shared.makeController()
        
        let channel = FlutterMethodChannel(
            name: "embedded_flutter",
            binaryMessenger: controller.binaryMessenger
        )
        
        channel.setMethodCallHandler { call, _ in
            if call.method == "closeFullscreen" || call.method == "closeCard" {
                FlutterEngineHolder.shared.detachController()
                onClose()
            }
        }
        
        channel.invokeMethod("setData", arguments: initialData)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: FlutterViewController, context: Context) {}
}
