import 'package:flutter/foundation.dart';
import 'package:bloc/bloc.dart';

import 'package:tt_app/models/models.dart';
import 'package:tt_app/data_providers/twitter_data_provider.dart';

import './events.dart';
import './states.dart';
import './configuration.dart';
import './data.dart';

class TwitterTimelineBloc extends Bloc<TwitterTimelineEvent, TwitterTimelineState> {

    final TwitterDataProvider _dataProvider;
    String _currentDataProviderTaskIdentifier;

    TwitterTimelineBloc({ @required TwitterDataProvider dataProvider }):
        assert(dataProvider != null),
        this._dataProvider = dataProvider;

    //Wrong realization - because it eats internal events. Should be rwwritten with selective bouncing
    //@override
    //Stream<TwitterTimelineEvent> transform(Stream<TwitterTimelineEvent> events) {
    //    return (events as Observable<TwitterTimelineEvent>).debounce(Duration(milliseconds: 50));
    //}

    // In some circumstances current operations must be cancelled immediately
    @override
    void dispatch(TwitterTimelineEvent event) {

        // Configuration updating is a reason to restart all the stuff immediately
        if (event is TwitterTimelineSetConfigEvent) {
            _cancelCurrentTaskIfAny();
        }

        super.dispatch(event);
    }

    @override
    void onTransition(Transition<TwitterTimelineEvent, TwitterTimelineState> transition) {
        debugPrint("Transition to ${transition.nextState} using event ${transition.event}");
    }

    @override
    get initialState {
        return TwitterTimelineUninitialized();
    }

    @override
    Stream<TwitterTimelineState> mapEventToState(currentState, event) async* {
        debugPrint("<TwitterTimeline>: map event $event having current state $currentState");

        try {
            // Uninitialized
            if (currentState is TwitterTimelineUninitialized) {
                final result = await _handleUninitializedState(currentState, event);
                if (result != null) {
                    yield result;
                }
                return;
            }

            // Loaded
            if (currentState is TwitterTimelineLoaded) {
                final result = await _handleLoadedState(currentState, event);
                if (result != null) {
                    yield result;
                }
                return;
            }

            // Loading
            if (currentState is TwitterTimelineLoading) {
                final result = await _handleLoadingState(currentState, event);
                if (result != null) {
                    yield result;
                }
                return;
            }

            // Error
            if (currentState is TwitterTimelineError) {
                final result = await _handleErrorState(currentState, event);
                if (result != null) {
                    yield result;
                }
                return;
            }

            assert(false, "Unhandled event $event");

        } catch (e, s) {
            debugPrint("$s");
            // Last chance exception catching.
            // This considered as a fatal error so state will become Error and configuration will be
            // taken from current state. This is not the best approach for the exceptions thrown during
            // configuration updating. So do not forget to add local try..catch wherever it needed
            yield TwitterTimelineError(e, configuration: currentState.configuration);
        }
    }

    // --------------------------------------------------------------------------------
    // Helpers
    // --------------------------------------------------------------------------------

    Future<Tweets> _fetchTweets( TwitterTimelineConfiguration config, String taskIdentifier, {
            int limitTweetCount,
            String maxTweetIdentifier,
            String sinceTweetIdentifier
        }) async {

        assert(config != null);
        final result = await _dataProvider.getTimeline(
                taskIdentifier,
                config.userName,
                limitTweetCount,
                maxTweetIdentifier,
                sinceTweetIdentifier
        );

        // debugPrint("Tweets returned: $result");
        return result;
    }

    // Apply new configuration and (conditionally) start initial fetching
    Future<TwitterTimelineState>_applyConfiguration(
            TwitterTimelineState currentState,
            TwitterTimelineConfiguration newConfig,
            bool forced) async {

        // We do need a config to go further...
        if (newConfig == null) {
            return _makeSetupConfigErrorState();
        }

        // Nothing to do if nothing has been changed in configuration (excepting 'forced' cases)
        if (!forced && newConfig == currentState.configuration) {
            return null;
        }

        // Checking configuration quality
        final issues = newConfig.issues;
        if (issues != null) {
            return TwitterTimelineError("The timeline is not configured properly: $issues. Please fix and retry",
                                         configuration: newConfig);
        }

        // It is the time to schedule initial fetching - dispatch an event to bloc itself and switching to "I'm loading' state
        dispatch(TwitterTimelineStartFetchingEvent());
        return TwitterTimelineLoading(configuration: newConfig);
    }

    TwitterTimelineError _makeSetupConfigErrorState() => TwitterTimelineError("Please set up the configuration first");

    void _cancelCurrentTaskIfAny() {
        if ( _currentDataProviderTaskIdentifier != null) {
            debugPrint("Cancelling current task $_currentDataProviderTaskIdentifier...");
            _dataProvider.cancelTask(_currentDataProviderTaskIdentifier);
            _currentDataProviderTaskIdentifier = null;
        }
    }

    // --------------------------------------------------------------------------------
    //  Handle states and events
    // --------------------------------------------------------------------------------

    // Uninitialized state. From here we can transit with SetConfig event only
    Future<TwitterTimelineState>_handleUninitializedState(TwitterTimelineUninitialized currentState, TwitterTimelineEvent event) async {
        if (event is TwitterTimelineSetConfigEvent) {
            return await _applyConfiguration(currentState, event.configuration, true);
        } else {
            return _makeSetupConfigErrorState();
        }
    }

    // Loaded state. We can fetch/refresh more or apply a new configuration
    Future<TwitterTimelineState>_handleLoadedState(TwitterTimelineLoaded currentState, TwitterTimelineEvent event) async {

        switch (event.type) {
            case TTEventType.StartFetching:
            case TTEventType.StartRefreshing:
                assert(null, "$event is for TwitterTimelineLoading state only");
                break;

            case TTEventType.Refresh:
                final data = currentState.data;
                final sinceIdentifier = data.tweets.latestIdentifier;
                if (sinceIdentifier != null) {
                    dispatch(TwitterTimelineStartRefreshingEvent.since(sinceIdentifier));
                } else {
                    // we have no sinceIdentifier (user has not written a tweet) so refreshing == fetching in this case
                    dispatch(TwitterTimelineStartFetchingEvent());
                }
                return TwitterTimelineLoading(
                    configuration: currentState.configuration,
                    data: currentState.data
                );
                break;

            case TTEventType.Fetch:
                if (!currentState.data.oldestReached) {
                    dispatch(TwitterTimelineStartFetchingEvent());
                    return TwitterTimelineLoading(
                        configuration: currentState.configuration,
                        data: currentState.data
                    );
                }
                break;

            case TTEventType.SetConfig:
                return await _applyConfiguration(currentState, (event as TwitterTimelineSetConfigEvent).configuration, false);
        }
        return null;
    }

    // Loading state. Starts real loading process. Can be interrupted by new configuration applying
    Future<TwitterTimelineState>_handleLoadingState(TwitterTimelineLoading currentState, TwitterTimelineEvent event) async {

        switch (event.type) {
            // ignore fetching/reloading requests while loading the data
            case TTEventType.Refresh:
            case TTEventType.Fetch:
                break;

            // internal request to fetch data
            case TTEventType.StartFetching:
            case TTEventType.StartRefreshing:

                final data = currentState.data;
                final config = currentState.configuration;
                final currentTweets = data?.tweets ?? Tweets([]);
                bool oldestReached = data?.oldestReached ?? false;

                final taskIdentifier = await _dataProvider.startTask();
                _currentDataProviderTaskIdentifier = taskIdentifier;
                bool shouldIgnoreCall = false;

                dynamic tweets;
                try {
                    try {
                        if (event is TwitterTimelineStartRefreshingEvent) {
                            tweets = await _fetchTweets(config, taskIdentifier, sinceTweetIdentifier: event.identifier);
                        } else {
                            tweets = await _fetchTweets(config, taskIdentifier, limitTweetCount: 20, maxTweetIdentifier: currentTweets.earliestIdentifier);
                            oldestReached = currentTweets.earliestIdentifier == tweets.earliestIdentifier;
                        }
                    } finally {
                        shouldIgnoreCall = _currentDataProviderTaskIdentifier != taskIdentifier;
                    }
                    if (shouldIgnoreCall) {
                        return null;
                    }
                } catch (_) {
                    if (!shouldIgnoreCall) {
                        rethrow;
                    }
                } finally {
                    if (shouldIgnoreCall) {
                        debugPrint("️The result of $event processing is ignored");
                    } else {
                        _currentDataProviderTaskIdentifier = null;
                    }
                }

                return TwitterTimelineLoaded(
                    configuration: config,
                    data: TwitterTimelineData(tweets: currentTweets + tweets, oldestReached: oldestReached)
                );

            // Any configuration events will cancel current loading and start a new one
            case TTEventType.SetConfig:
                return await _applyConfiguration(currentState, (event as TwitterTimelineSetConfigEvent).configuration, true);
        }
        return null;
    }

    // Error state. For the simplicity, any error will NOT preserve previously loaded tweets
    // so we can start from scratch by reapplying current configuration (if any)
    Future<TwitterTimelineState>_handleErrorState(TwitterTimelineError currentError, TwitterTimelineEvent event) async {
        switch (event.type) {
            case TTEventType.StartFetching:
            case TTEventType.StartRefreshing:
                assert(null, "$event is for TwitterTimelineLoading state only");
                break;

            case TTEventType.Refresh:
            case TTEventType.Fetch:
                return _applyConfiguration(currentError, currentError.configuration, true);

            case TTEventType.SetConfig:
                return await _applyConfiguration(currentState, (event as TwitterTimelineSetConfigEvent).configuration, true);
        }
        return null;
    }
}

