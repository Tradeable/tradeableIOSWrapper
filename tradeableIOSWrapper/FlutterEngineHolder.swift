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
