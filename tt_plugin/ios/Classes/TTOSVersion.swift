import Flutter

/// This is an original sample from project template. Left here for testing/referencing purposes
public class TTOSVersionRequestHandler: NSObject, FlutterPlugin {
    
    required override init() {
        super.init()
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        do {
            let channel = FlutterMethodChannel(name: TT.mainChannel, binaryMessenger: registrar.messenger())
            let instance = self.init()
            registrar.addMethodCallDelegate(instance, channel: channel)
        }
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        result("iOS " + UIDevice.current.systemVersion)
    }
}
