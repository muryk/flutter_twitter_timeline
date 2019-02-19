import 'twitter_data_provider.dart';
import 'package:tt_app/models/models.dart';
import 'package:tt_plugin/tt_plugin.dart';

class TTPluginBasedTwitterDataProvider extends TwitterDataProvider {

    TwitterApiJSONResponse _getJSONResponse(TwitterApiResponse apiResponse) {
        if (apiResponse is TwitterApiJSONResponse) {
            return apiResponse;
        }

        if (apiResponse is TwitterApiError) {
            throw Exception(apiResponse.message);
        } else {
            throw Exception("Unexpected response from plugin request: $apiResponse");
        }
    }

    String _getStringResponse(TwitterApiResponse apiResponse) {
        if (apiResponse is TwitterApiStringResponse) {
            return apiResponse.string;
        }
        if (apiResponse is TwitterApiError) {
            throw Exception(apiResponse.message);
        } else {
            throw Exception("Unexpected response from plugin request: $apiResponse");
        }
    }

    Future<Tweets> getTimeline(String taskIdentifier, String userName, int limitTweetCount,
                               String maxTweetIdentifier, String sinceTweetIdentifier) async {
        TwitterApiJSONResponse response = _getJSONResponse(await TwitterApiClient.getTimeline(
                                                taskIdentifier: taskIdentifier,
                                                userName: userName,
                                                count: limitTweetCount,
                                                maxIdentifier: maxTweetIdentifier,
                                                sinceIdentifier: sinceTweetIdentifier
                                           ));

        // Standard twitter timeline response assumes a list oj JSON-encoded lists
        var tweets = List<Tweet>();
        try {
            for (dynamic tweetJson in response.json) {
                final tweet = Tweet.fromJson(tweetJson);
                tweets.add(tweet);
            }
        }
        catch (e) {
            throw Exception("Unable to parse plugin response: $e");
        }
        return Tweets(tweets);
    }

    Future<String> startTask() async {
        return _getStringResponse(await TwitterApiClient.startTask());
    }

    Future<String> cancelTask(String taskIdentifier) async {
        return _getStringResponse(await TwitterApiClient.cancelTask(taskIdentifier));
    }
}
