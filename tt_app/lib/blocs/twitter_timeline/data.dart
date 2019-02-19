import 'package:flutter/foundation.dart';
import 'package:tt_app/helpers/helpers.dart';
import 'package:tt_app/models/models.dart';

// This is what has been fetched from the network so far

class TwitterTimelineData {
    final Tweets tweets;
    final bool oldestReached;

    TwitterTimelineData({
        @required Tweets tweets,
        @required bool oldestReached
    }): this.tweets = tweets,
        this.oldestReached = oldestReached,
        assert(tweets != null),
        assert(oldestReached != null);

    TwitterTimelineData copyWith({ Tweets tweets, bool oldestReached }) {
        return TwitterTimelineData(
            tweets: tweets ?? this.tweets,
            oldestReached: oldestReached ?? this.oldestReached,
        );
    }

    @override
    int get hashCode => tweets.hashCode ^ oldestReached.hashCode;

    @override
    bool operator == (Object other) {
        return identical(this, other) || (other is TwitterTimelineData &&
            tweets == other.tweets &&
            oldestReached == other.oldestReached
        );
    }

    @override
    String toString() {
        final result = ToStringBuilder(this);
        result.add("tweets", tweets);
        result.add("oldestReached", oldestReached);
        return result();
    }
}
