import Flutter

public  class TTInterfaceOrientationRequestHandler: NSObject, FlutterPlugin, FlutterStreamHandler {

    private var flutterEventSink: FlutterEventSink?
    private var isListening = false
    
    required override init() {
        super.init()
        
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(onStatusBarOrientationChange(_:)),
                       name: .UIApplicationDidChangeStatusBarOrientation, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // ----------------------------------------------------------------------------
    // MARK: -
    // ----------------------------------------------------------------------------
    
    @objc private func onStatusBarOrientationChange(_ notification: Notification) {
        reportDeviceOrientation()
    }
    
    private func reportDeviceOrientation() {
        if isListening, let sink = flutterEventSink {
            let orientation = UIApplication.shared.statusBarOrientation;
            sink(NSNumber(integerLiteral: orientation.isPortrait ? 0 : 1));
        }
    }

    // ----------------------------------------------------------------------------
    // MARK: - FlutterPlugin
    // ----------------------------------------------------------------------------
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterEventChannel(name: TT.interfaceOrientationChannel, binaryMessenger: registrar.messenger())
        let instance = self.init()
        channel.setStreamHandler(instance)
    }
    
    // ----------------------------------------------------------------------------
    // MARK: - FlutterStreamHandler
    // ----------------------------------------------------------------------------
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        
        self.flutterEventSink = events
        self.isListening = true
        reportDeviceOrientation()
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.isListening = false
        return nil
    }
}
