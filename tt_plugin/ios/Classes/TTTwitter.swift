import Flutter
import TwitterKit

// --------------------------------------------------------------------------------
// MARK: - Helpers
// --------------------------------------------------------------------------------

func TTTwitterLog(_ s: String, isError: Bool = false) {
#if DEBUG
    NSLog("\(isError ? "‼️ " : "")TTPluginTwitter: \(s)")
#endif
}

// --------------------------------------------------------------------------------
// MARK: - TTTwitterError, TTTwitterResult
// --------------------------------------------------------------------------------

enum TTTwitterResult {
    case error(String)
    case rawJson(Data)
    case string(String)

    func encoded() -> NSObject {
        let result = NSMutableDictionary()

        switch self {
        case let .error(message):
            result["error"] = message
            
        case let .rawJson(data):
            result["json"] = String(data: data, encoding: .utf8) ?? ""
            
        case let .string(string):
            result["string"] = string
        }
        
        return result
    }
}

enum TTTwitterError: Error {
    case simple(String)
}

// --------------------------------------------------------------------------------
// MARK: - TTwitterTask
// --------------------------------------------------------------------------------

class TTwitterTask: CustomStringConvertible {

    typealias Completion = (TTwitterTask, TTTwitterResult) -> Void
    
    static private var _intTaskCounter = 0;
    static func acquireNewTaskIdentifier() -> String {
        _intTaskCounter += 1;
        return "Task\(_intTaskCounter)";
    }
    
    var checkpoint: String?;
    let identifier: String;
    private let completion: Completion;
    private var isCancelled = false;
    
    init(identifier: String, completion: @escaping TTwitterTask.Completion) {
        self.identifier = identifier;
        self.completion = completion;
    }
    
    func completeWithResult(_ result: TTTwitterResult) {
        if (!isCancelled) {
            self.completion(self, result);
        }
    }
    
    func completeWithError(_ string: String) {
        completeWithResult(.error(string))
    }
    
    func cancel() {
        if !isCancelled {
            completeWithError("The task has been cancelled");
            isCancelled = true;
        }
    }
    
    var description: String {
        var s = [String]()
        s.append("'\(identifier)'")
        if isCancelled {
            s.append("CANCELLED")
        }
        if let checkpoint = checkpoint {
            s.append(checkpoint)
        }
        return "Task(\(s.joined(separator: ", ")))";
    }
    
    deinit {
        TTTwitterLog("\(self) deinit")
    }
}

// --------------------------------------------------------------------------------
// MARK: - TTTwitterRequestHandler: NSObject, FlutterPlugin
// --------------------------------------------------------------------------------

/*
    https://developer.twitter.com/en/docs/tweets/timelines/api-reference/get-statuses-user_timeline.html
*/

public class TTTwitterRequestHandler: NSObject, FlutterPlugin {
    
    private let client: TWTRAPIClient;
    private var tasks = [String: TTwitterTask]();

    required override init() {
        client = TWTRAPIClient()
        super.init()
    }
    
    // ----------------------------------------------------------------------------
    // MARK: - FlutterPlugin
    // ----------------------------------------------------------------------------
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        do {
            _ = runOnce
            let channel = FlutterMethodChannel(name: TT.twitterChannel, binaryMessenger: registrar.messenger())
            let instance = self.init()
            registrar.addMethodCallDelegate(instance, channel: channel)
        }
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        do {
            switch call.method {
                
            case TT.Twitter.getTimelineMethod:
                let task = try registerTask(call.arguments) { [weak self] task, r in
                    result(r.encoded())
                    self?.removeTaskWithIdentifier(task.identifier);
                }
                getTimeline(call.arguments, task);
                
            case TT.Twitter.startTaskMethod:
                result(TTTwitterResult.string(TTwitterTask.acquireNewTaskIdentifier()).encoded())
                
            case TT.Twitter.cancelTaskMethod:
                let (identifier, success) = try cancelTask(call.arguments);
                if (success) {
                    result(TTTwitterResult.string("The task '\(identifier)' has been cancelled").encoded());
                } else {
                    result(TTTwitterResult.string("The task '\(identifier)' has NOT been cancelled: not found in the task pool").encoded());
                }
                
            default:
                throw TTTwitterError.simple("Unsupported method \(call.method)")
            }
            
        } catch TTTwitterError.simple(let s) {
            TTTwitterLog("\(s)", isError: true)
            result(TTTwitterResult.error(s).encoded())
        } catch {
            TTTwitterLog("\(error)", isError: true)
            result(TTTwitterResult.error("\(error)").encoded())
        }
    }
    
    // --------------------------------------------------------------------------------
    // MARK: - Twitter API low-level calls
    // --------------------------------------------------------------------------------
    
    private static var runOnce: () = {
        TTTwitterLog("Opening session...")
        
        TWTRTwitter.sharedInstance().start(withConsumerKey: TT.Twitter.Auth.consumerKey,
                                           consumerSecret: TT.Twitter.Auth.consumerSecret)
        
        let store = TWTRTwitter.sharedInstance().sessionStore
        store.saveSession(withAuthToken: TT.Twitter.Auth.authToken,
                          authTokenSecret: TT.Twitter.Auth.authTokenSecret) { (session, error) in
                            if let error = error {
                                TTTwitterLog("Failed to open session: \(error)", isError: true)
                            } else {
                                TTTwitterLog("Session opened")
                            }
        }
    }()
    
    private func performTwitterApiCall(_ task: TTwitterTask, _ apiPath: String, _ params: [String: Any]) {

        // Start fetching. From this point all interconnectiona go via task
        TTTwitterLog("\(task): Fetching...")
        
        let urlString = "https://api.twitter.com/1.1\(apiPath).json"

        var clientError : NSError? = nil
        let request = client.urlRequest(withMethod: "GET", urlString: urlString, parameters: params, error: &clientError)
        if let clientError = clientError {
            task.completeWithError("Unable to create request: \(clientError)")
            return;
        }
        
        client.sendTwitterRequest(request) { response, data, error in
            if let error = error {
                let s: String
                if let lfd = (error as NSError).localizedFailureReason, !lfd.isEmpty  {
                    s = lfd
                } else {
                    let lfd = (error as NSError).localizedDescription
                    if !lfd.isEmpty  {
                        s = lfd
                    } else {
                        s = "Failed to perform request: \(error)"
                    }
                }
                task.completeWithError(s)
                return
            }
            
            guard let data = data else {
                task.completeWithError("Failed to perform request: no data returned")
                return;
            }

            TTTwitterLog("\(task): Completed, \(data.count) bytes fetched")
            task.completeWithResult(.rawJson(data))
        }
    }
    
    // ----------------------------------------------------------------------------
    // MARK: - Helpers
    // ----------------------------------------------------------------------------
    
    private func removeTaskWithIdentifier(_ taskIdentifier: String) {
        if (tasks[taskIdentifier] != nil) {
            TTTwitterLog("Removing task '\(taskIdentifier)'...")
            tasks.removeValue(forKey: taskIdentifier);
        } else {
            TTTwitterLog("Failed to remove task '\(taskIdentifier)': not found in the task pool")
        }
    }
    
    private func registerTask(_ args: Any?, _ completion: @escaping TTwitterTask.Completion) throws -> TTwitterTask {
        guard let dict = args as? [String: Any] else {
            throw TTTwitterError.simple("Bad arguments: not a dictionary")
        }
        guard let taskID = dict["taskIdentifier"] as? String else {
            throw TTTwitterError.simple("Task identifier is required. Register a new task using '\(TT.Twitter.startTaskMethod)' method first.")
        }
        
        TTTwitterLog("Registering task \(taskID)...")

        // Placing task to the list - this can be don only once
        if (tasks[taskID] != nil) {
            throw TTTwitterError.simple("The task '\(taskID)' has already been started")
        }
        let task = TTwitterTask(identifier: taskID, completion: completion);
        tasks[taskID] = task;
        return task;
    }
    
    private func cancelTask(_ args: Any?) throws -> (String, Bool) {
        guard let dict = args as? [String: Any] else {
            throw TTTwitterError.simple("Bad arguments: not a dictionary")
        }
        guard let taskID = dict["taskIdentifier"] as? String else {
            throw TTTwitterError.simple("Task identifier is required")
        }
        if let task = tasks[taskID] {
            task.cancel();
            return (taskID, true)
        } else {
            return (taskID, false)
        }
    }
    
    // ----------------------------------------------------------------------------
    // MARK: - Plugin methods implementation
    // ----------------------------------------------------------------------------
    
    private func getTimeline(_ args: Any?, _ task: TTwitterTask) {
        
        task.checkpoint = "getTimeline()";
        
        guard let dict = args as? [String: Any] else {
            task.completeWithError("Not a dictionary")
            return;
        }
        guard let userName = (dict["userName"] as? String)?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines), !userName.isEmpty else {
            task.completeWithError("No user name spceified or user name is empty")
            return;
        }
        if (userName.contains(" ")) {
            task.completeWithError("No spaces are allowed for the user name")
            return;
        }
        
        var params: [String: Any] = [
            "screen_name": userName
        ];
        
        if let maxIdentifier = dict["maxIdentifier"] as? String {
            params["max_id"] = maxIdentifier;
        }
        if let sinceIdentifier = dict["sinceIdentifier"] as? String {
            params["since_id"] = sinceIdentifier;
        }
        if let maxIdentifier = dict["count"] as? String {
            params["count"] = maxIdentifier;
        }

        task.checkpoint = "getTimeline(\(params.map({"\($0): \($1)"}).joined(separator: ", ")))";
        performTwitterApiCall(task, "/statuses/user_timeline", params)
    }
}
