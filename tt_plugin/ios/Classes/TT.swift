import Foundation

public struct TT {
    
    public static let mainChannel = "tt_plugin"
    public static let interfaceOrientationChannel = "tt_plugin/interface_orientation"
    public static let twitterChannel = "tt_plugin/twitter"
    
    struct Twitter {
        
        static let getTimelineMethod = "getTimeline"
        static let startTaskMethod = "startTask"
        static let cancelTaskMethod = "cancelTask"

        struct Auth {
            
            /*
                Plugin does not contain any OAuth authorization.
                Please use 3rd-party tools to get all secrets.
                You must have your own Twitter app consumer key and consumer secret (or use Google to find ones :)
             
                There is one handy tool for this: twurl (https://github.com/twitter/twurl) Steps are:
             
                1. Install twurl
                2. run twurl to authorize yourself.
                3. go to your desktop home folder and copy/paste saved auth token and secret keys from  ~/.twurlrc file here.
             
            */
            static let consumerKey = "TWAPP_CONSUMER_KEY"
            static let consumerSecret = "TWAPP_CONSUMER_SECRET"
            static let authToken = "OAUTH_TOKEN"
            static let authTokenSecret = "OAUTH_TOKEN_SECRET"
        }
    }
}
