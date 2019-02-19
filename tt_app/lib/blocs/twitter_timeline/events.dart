import 'package:tt_app/helpers/helpers.dart';
import './configuration.dart';

// to get rid of chains of 'if(event is <Type>){}' an enumeration is used. Hopefully Dart 3.X will have Swift'ed associated values for enums
enum TTEventType {
    Fetch, // get older tweets (pagination)
    Refresh, // get news tweets (pull to refresh)
    SetConfig, // set new user
    StartFetching, // internal event, not for external using
    StartRefreshing, // internal event, not for external using
}

abstract class TwitterTimelineEvent {
    @override
    String toString() => ToStringBuilder(this)();
    TTEventType get type;
}

class TwitterTimelineFetchEvent extends TwitterTimelineEvent {
    get type => TTEventType.Fetch;
}

class TwitterTimelineRefreshEvent extends TwitterTimelineEvent {
    get type => TTEventType.Refresh;
}

class TwitterTimelineSetConfigEvent extends TwitterTimelineEvent {
    TwitterTimelineConfiguration configuration;
    TwitterTimelineSetConfigEvent(this.configuration): assert(configuration != null);
    get type => TTEventType.SetConfig;
}

class TwitterTimelineStartFetchingEvent extends TwitterTimelineEvent {
    get type => TTEventType.StartFetching;
}

class TwitterTimelineStartRefreshingEvent extends TwitterTimelineEvent {
    final String identifier;
    TwitterTimelineStartRefreshingEvent.since(this.identifier) { assert(this.identifier != null); }
    get type => TTEventType.StartRefreshing;
}
