import 'package:flutter/foundation.dart';
import 'package:tt_app/helpers/helpers.dart';
import 'package:tt_app/models/models.dart';
import './configuration.dart';
import './data.dart';

// to get rid of chains of 'if(event is <Type>){}' an enumeration is used. Hopefully Dart 3.X will have Swift'ed associated values for enums
enum TTStateType {
    Uninitialized,
    Error,
    Loading,
    Loaded
}

// --------------------------------------------------------------------------------
// TwitterTimelineState
// --------------------------------------------------------------------------------

abstract class TwitterTimelineState {

    final TwitterTimelineConfiguration configuration;

    TwitterTimelineState(this.configuration);

    void configureToStringBuilder(ToStringBuilder builder) {
        builder.add('userName', configuration?.userName);
    }

    bool isEqualTo(covariant TwitterTimelineState otherState) {
        return configuration == otherState.configuration && type == otherState.type;
    }

    TTStateType get type;

    @override
    int get hashCode => (configuration?.hashCode ?? 0) ^ type.hashCode;

    @override
    bool operator == (Object other) {
        return identical(this, other) || (other.runtimeType == runtimeType && isEqualTo(other));
    }

    @override
    String toString() {
        final result = ToStringBuilder(this);
        configureToStringBuilder(result);
        return result();
    }
}

// --------------------------------------------------------------------------------
//  TwitterTimelineUninitialized
// --------------------------------------------------------------------------------

class TwitterTimelineUninitialized extends TwitterTimelineState {

    // Please note that configuration is always null here
    TwitterTimelineUninitialized(): super(null);

    get type => TTStateType.Uninitialized;
}

// --------------------------------------------------------------------------------
//  TwitterTimelineError
// --------------------------------------------------------------------------------

class TwitterTimelineError extends TwitterTimelineState {

    final dynamic error;

    // Please note: configuration is allowed to be null here
    TwitterTimelineError(this.error, {TwitterTimelineConfiguration configuration} ) :
        assert(error != null),
        super(configuration);

    get message => messageFromError(error);
    get type => TTStateType.Error;

    @override
    // ignore: hash_and_equals
    int get hashCode => super.hashCode ^ error.hashCode;

    @override
    bool isEqualTo(TwitterTimelineError other) => super.isEqualTo(other) && other.error == error;

    @override
    void configureToStringBuilder(ToStringBuilder builder) {
        super.configureToStringBuilder(builder);
        builder.addValue(message);
    }
}

// --------------------------------------------------------------------------------
//  TwitterTimelineLoaded
// --------------------------------------------------------------------------------

class TwitterTimelineLoaded extends TwitterTimelineState {

    final TwitterTimelineData data;

    TwitterTimelineLoaded({
        @required TwitterTimelineConfiguration configuration,
        @required TwitterTimelineData data
    }):
        this.data = data,
        assert(data != null),
        assert(configuration != null),
        super(configuration);

    TwitterTimelineLoaded copyWith({ TwitterTimelineConfiguration configuration, Tweets tweets, bool oldestReached }) {
        return TwitterTimelineLoaded(
            configuration: configuration ?? this.configuration,
            data: tweets ?? this.data
        );
    }

    get type => TTStateType.Loaded;

    @override
    // ignore: hash_and_equals
    int get hashCode => super.hashCode ^ data.hashCode;

    @override
    bool isEqualTo(TwitterTimelineLoaded other) => super.isEqualTo(other) && other.data == data;

    @override
    void configureToStringBuilder(ToStringBuilder builder) {
        super.configureToStringBuilder(builder);
        builder.add("tweets", data.tweets);
        builder.add("oldestReached", data.oldestReached);
    }
}

// --------------------------------------------------------------------------------
//  TwitterTimelineLoading.
// --------------------------------------------------------------------------------
// Similar to TwitterTimelineLoaded but
//   1) there is some fetching is in progress
//   2) previous data might be null

class TwitterTimelineLoading extends TwitterTimelineState {

    final TwitterTimelineData data;

    TwitterTimelineLoading({
        @required TwitterTimelineConfiguration configuration,
        TwitterTimelineData data
    }): this.data = data,
        assert(configuration != null),
        super(configuration);

    get type => TTStateType.Loading;

    @override
    // ignore: hash_and_equals
    int get hashCode => super.hashCode ^ (data?.hashCode ?? 0);

    @override
    bool isEqualTo(TwitterTimelineLoading other) => super.isEqualTo(other) && other.data == data;

    @override
    void configureToStringBuilder(ToStringBuilder builder) {
        super.configureToStringBuilder(builder);
        builder.add("tweets", data?.tweets);
        builder.add("oldestReached", data?.oldestReached);
    }
}
