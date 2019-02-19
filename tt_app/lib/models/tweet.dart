import 'package:tt_app/helpers/helpers.dart';
import 'twitter_user.dart';

class Tweet {

    final String text;
    final String identifier;
    final DateTime timestamp;
    final TwitterUser user;
    final String mainPhotoURL;

    int index; // index in the Tweets list (and assigned by Tweets itself) - for debugging purposes only.

    Tweet(this.identifier, this.text, this.timestamp, this.user, this.mainPhotoURL);

    Tweet.fromJson(dynamic json):
        text = json['text'],
        identifier = json['id_str'],
        timestamp = parseTwitterTimestamp(json['created_at']),
        user = _getUser(json),
        mainPhotoURL = _getMainPhotoURL(json);

    static TwitterUser _getUser(dynamic json) {
        dynamic userJson;
        if (json["retweeted_status"] != null) {
            userJson = json["retweeted_status"]["user"];
        } else {
            userJson = json["user"];
        }
        return TwitterUser.fromJson(userJson);
    }

    static String _getMainPhotoURL(dynamic json) {

        final entities = json["entities"];
        if (entities != null) {
            final media = entities["media"];
            if (media != null) {
                for (dynamic mediaItem in media) {
                    if (mediaItem["type"] == "photo") {
                         return mediaItem["media_url"];
                    }
                }
            }
        }
        return null;
    }

    @override
    int get hashCode =>
        identifier.hashCode ^
        text.hashCode ^
        timestamp.hashCode ^
        user.hashCode ^
        mainPhotoURL.hashCode;

    @override
    bool operator ==(Object other) {
        return identical(this, other) || ( other is Tweet &&
            other.identifier == identifier &&
            other.text == text &&
            other.timestamp == timestamp &&
            other.user == user &&
            other.mainPhotoURL == mainPhotoURL
        );
    }

    @override
    String toString() {
        final result = ToStringBuilder(this);
        result.add('id', identifier);
        result.add('user', user.screenName);
        result.add('time', timestamp);
        result.addValue(text);
        return result();
    }
}
