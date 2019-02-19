import 'package:tt_app/models/models.dart';

abstract class TwitterDataProvider {

    Future<String> startTask();
    Future<String> cancelTask(String taskIdentifier);
    Future<Tweets> getTimeline(String taskIdentifier, String userName, int limitTweetCount,
                               String maxTweetIdentifier, String sinceTweetIdentifier);
}