import Flutter

/// Internal engine manager - not exposed to consumers
class FlutterEngineHolder {
  enum PresentationKind {
    case embedded
    case fullscreen
  }

  static let shared = FlutterEngineHolder()
  let embeddedEngine: FlutterEngine
  let fullscreenEngine: FlutterEngine
  private(set) var embeddedController: FlutterViewController?
  private(set) var fullscreenController: FlutterViewController?

  private init() {
    embeddedEngine = FlutterEngine(name: "embedded_engine")
    fullscreenEngine = FlutterEngine(name: "fullscreen_engine")

    embeddedEngine.run()
    fullscreenEngine.run()

    registerPlugins(for: embeddedEngine, label: "embedded")
    registerPlugins(for: fullscreenEngine, label: "fullscreen")
  }

  private func registerPlugins(for engine: FlutterEngine, label: String) {
    guard let registrantClass: AnyClass = NSClassFromString("GeneratedPluginRegistrant") else {
      tfsLog("⚠️ GeneratedPluginRegistrant not found — plugins (webview, url_launcher) unavailable on \(label) engine")
      return
    }
    let selector = NSSelectorFromString("registerWithRegistry:")
    guard let method = class_getClassMethod(registrantClass, selector) else {
      tfsLog("⚠️ GeneratedPluginRegistrant has no registerWithRegistry: — plugins unavailable on \(label) engine")
      return
    }
    typealias RegisterFn = @convention(c) (AnyClass, Selector, FlutterEngine) -> Void
    let register = unsafeBitCast(method_getImplementation(method), to: RegisterFn.self)
    register(registrantClass, selector, engine)
    tfsLog("🔌 plugins registered on \(label) engine")
  }

  func engine(for kind: PresentationKind) -> FlutterEngine {
    switch kind {
    case .embedded:
      return embeddedEngine
    case .fullscreen:
      return fullscreenEngine
    }
  }

  func makeController(for kind: PresentationKind) -> FlutterViewController {
    detachController(for: kind)

    let engine = engine(for: kind)

    let vc = FlutterViewController(
      engine: engine,
      nibName: nil,
      bundle: nil
    )

    switch kind {
    case .embedded:
      embeddedController = vc
    case .fullscreen:
      fullscreenController = vc
    }

    return vc
  }

  func detachController(for kind: PresentationKind) {
    let engine = engine(for: kind)
    engine.viewController = nil

    switch kind {
    case .embedded:
      embeddedController = nil
    case .fullscreen:
      fullscreenController = nil
    }
  }

  deinit {
    embeddedEngine.viewController = nil
    fullscreenEngine.viewController = nil
    embeddedController = nil
    fullscreenController = nil
  }
}
