import 'package:flutter_test/flutter_test.dart';
import 'package:tt_app/data_providers/twitter_data_provider.dart';
import 'package:tt_app/models/models.dart';
import 'package:tt_app/blocs/twitter_timeline/twitter_timeline.dart';

class TestTwitterDataProvider extends TwitterDataProvider {

    Future<String> startTask() async {
        return "Task1";
    }

    Future<String> cancelTask(String taskIdentifier) async {
        return "OK";
    }

    Future<Tweets> getTimeline(String taskIdentifier, String userName, int limitTweetCount,
            String maxTweetIdentifier, String sinceTweetIdentifier) async {
        return Tweets([]);
    }
}

void main() async {

    TwitterTimelineBloc bloc;
    TestTwitterDataProvider dataProvider;
    TwitterTimelineConfiguration goodConfig = TwitterTimelineConfiguration(userName: "some_user");
    TwitterTimelineConfiguration badConfig = TwitterTimelineConfiguration(userName: null);

    setUp(() {
        print("*** Instantiating new bloc ***");
        dataProvider = TestTwitterDataProvider();
        bloc = new TwitterTimelineBloc(dataProvider: dataProvider);
    });

    test('Initial state checking', () {
        expect(bloc.initialState, isInstanceOf<TwitterTimelineUninitialized>());
        expect(bloc.currentState, isInstanceOf<TwitterTimelineUninitialized>());
    });

    test('dispose does not emit new states', () {
        expectLater(
            bloc.state,
            emitsInOrder([]),
        ).then((_) {
            // ...
        });
        bloc.dispose();
    });

    group('Timeline bloc testing', () {
        test('Test 1', () async {
            print("---------------");
            expectLater(
                bloc.state,
                emitsInOrder([
                    isInstanceOf<TwitterTimelineUninitialized>(), // Refresh
                    isInstanceOf<TwitterTimelineError>(), // Fetch
                    isInstanceOf<TwitterTimelineError>(), // Set bad config
                    isInstanceOf<TwitterTimelineLoading>(), // Set good config => self-dispatch StartFetchingEvent
                    isInstanceOf<TwitterTimelineLoaded>(), // StartFetchingEvent
                ]),
            ).then((v) {
                // ...
            });
            bloc.dispatch(TwitterTimelineRefreshEvent());
            bloc.dispatch(TwitterTimelineFetchEvent());
            bloc.dispatch(TwitterTimelineSetConfigEvent(badConfig));
            bloc.dispatch(TwitterTimelineSetConfigEvent(goodConfig));
            // bloc.dispatch(TwitterTimelineRefreshEvent());
        });

        test('Test 2', () async {
            print("---------------");
            print(bloc.currentState);
        });
    });
}