import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import 'package:tt_app/widgets/tweet_widget.dart';
import 'package:tt_app/blocs/home_bloc.dart';
import 'package:tt_app/blocs/twitter_timeline/twitter_timeline.dart';
import 'package:tt_app/data_providers/twitter_data_provider+plugin.dart';
import 'package:tt_app/pages/user_picker.dart';
import 'package:tt_plugin/tt_plugin.dart';

class HomePage extends StatefulWidget {

    final String title;
    final String initialUserName;

    HomePage({ Key key, @required String title, String userName }) :
        this.title = title,
        initialUserName = userName,
        super(key: key);

    @override createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

    final _scrollController = ScrollController();
    final _pageBloc = HomePageBloc();
    final _timelineBloc = TwitterTimelineBloc(dataProvider: TTPluginBasedTwitterDataProvider());
    Completer<void> _refreshCompleter = Completer<void>();

    _HomePageState();

    @override
    void initState() {
        super.initState();

        OrientationNotifier().addListener(_onOrientationChange);
        _scrollController.addListener(_onScroll);
        
        final configuration = TwitterTimelineConfiguration(userName: "elonmusk");
        final event = TwitterTimelineSetConfigEvent(configuration);
        _timelineBloc.dispatch(event);
    }

    void _onOrientationChange(Orientation orientation) {
        switch(orientation) {
            case Orientation.portrait:
                _pageBloc.dispatch(HomePageEvent.setPortrait);
                break;
            case Orientation.landscape:
                _pageBloc.dispatch(HomePageEvent.setLandscape);
                break;
        }
    }

    void _onScroll() {
        final maxScroll = _scrollController.position.maxScrollExtent;
        if (maxScroll > 0) {
            final currentScroll = _scrollController.position.pixels;
            final limits = max(200, _scrollController.position.viewportDimension / 3);
            if (maxScroll - currentScroll <= limits) {
                _timelineBloc.dispatch(TwitterTimelineFetchEvent());
            }
        }
    }

    @override
    Widget build(BuildContext context) {

        // Actually we don't need block providers here because these blocs are local one. Left for consistence
        return BlocProvider<TwitterTimelineBloc>(
            bloc: _timelineBloc,
            child: BlocProvider<HomePageBloc>(
                bloc: _pageBloc,
                child: Scaffold(
                    resizeToAvoidBottomPadding: false,
                    appBar: _buildAppBar(context),
                    body: SafeArea(child: _buildMainUI(context))
                )
            )
        );
    }

    // --------------------------------------------------------------------------------
    //  AppBar
    // --------------------------------------------------------------------------------

    AppBar _buildAppBar(BuildContext context) {
        return AppBar(
            title: Text(widget.title),
            actions: [
                IconButton(
                    icon: Icon(Icons.account_circle),
                    onPressed: () async {
                        final currentUserName = _timelineBloc.currentState.configuration?.userName;
                        final newUserName = await Navigator.push(context,
                            MaterialPageRoute(builder: (context) => UserPickerPage(userName: currentUserName)),
                        );
                        if (newUserName != null) {
                            final configuration = _timelineBloc.currentState.configuration.copyWith(userName: newUserName);
                            final event = TwitterTimelineSetConfigEvent(configuration);
                            _timelineBloc.dispatch(event);
                        }
                    }
                )
            ]
        );
    }

    // --------------------------------------------------------------------------------
    // Scaffold body
    // --------------------------------------------------------------------------------

    Widget _buildMainUI(BuildContext context) {
        final homeBloc = _pageBloc; // BlocProvider.of<HomePageBloc>(context);
        final timelineBloc  = _timelineBloc;  // BlocProvider.of<TwitterTimelineBloc>(context);

        return BlocBuilder<HomePageEvent, HomePageBlocState>(
            bloc: homeBloc,
            builder: (context, homePageState) {
                return BlocBuilder<TwitterTimelineEvent, TwitterTimelineState>(
                    bloc: timelineBloc,
                    builder: (context, state) {
                        return _buildMainUIWithStates(context, homePageState, state);
                    }
                );
            }
        );
    }

    Widget _buildMainUIWithStates(BuildContext context, HomePageBlocState homePageState, TwitterTimelineState timelineState) {

        switch (timelineState.type) {

            // empty screen for uninitialized state
            case TTStateType.Uninitialized:
                break;

            // error
            case TTStateType.Error:
                final errState = timelineState as TwitterTimelineError;
                return _buildAlert(context, errState.message, "Retry", TwitterTimelineFetchEvent());

            // loading
            case TTStateType.Loading:
                final loadingState = timelineState as TwitterTimelineLoading;

                // For initial upload or for empty list will show only progress indicator at the page center
                if (loadingState.data == null || loadingState.data.tweets.isEmpty) {
                    return Center(
                        child: CircularProgressIndicator(),
                    );
                }
                return _buildMainUIInLoadedState(context, homePageState, timelineState);

            case TTStateType.Loaded:
                // For empty list we will show special dialog
                if ((timelineState as TwitterTimelineLoaded).data.tweets.isEmpty) {
                    return _buildNoTweetsPage(context, timelineState);
                } else {
                    return _buildMainUIInLoadedState(context, homePageState, timelineState);
                }
        }

        return Container();
    }

    Widget _buildMainUIInLoadedState(BuildContext context, HomePageBlocState homePageState, TwitterTimelineState timelineState) {
        return Column(children: [
            _buildToolbarUsingState(context, homePageState),
            Expanded(child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.0),
                child: _buildGridUsingStates(context, homePageState, timelineState)
            ))
        ]);
    }

    // --------------------------------------------------------------------------------
    // Toolbar
    // --------------------------------------------------------------------------------

    Widget _buildToolbarButton(bool isSelected, String title, HomePageEvent event, ThemeData theme) {

        return Padding(
            padding: EdgeInsets.all(4.0),
            child:
            FlatButton(
                color: isSelected ? theme.toggleableActiveColor : theme.unselectedWidgetColor,
                onPressed: () {
                    _pageBloc.dispatch(event);
                },
                child: Text(title, style: theme.accentTextTheme.button)
            )
        );
    }

    Widget _buildToolbarUsingState(BuildContext context, HomePageBlocState state) {

        final theme = Theme.of(context);

        return Padding(
            padding: EdgeInsets.symmetric(vertical: 0.0),
            child: Container(
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                        _buildToolbarButton(state.isGrid, "Grid", HomePageEvent.switchToGrid, theme),
                        _buildToolbarButton(state.isList, "List", HomePageEvent.switchToList, theme)
                    ],
                ),
            ),
        );
    }

    // --------------------------------------------------------------------------------
    //  Grid
    // --------------------------------------------------------------------------------

    Widget _buildNoTweetsPage(BuildContext context, TwitterTimelineState timelineState) {
        return _buildAlert( context,
            "User ${timelineState.configuration.userName} has no tweets yet :(",
            "Check again?",
            TwitterTimelineRefreshEvent()
        );
    }

    Widget _buildGridUsingStates(BuildContext context, HomePageBlocState homePageState, TwitterTimelineState timelineState) {

        // Loaded state
        if (timelineState is TwitterTimelineLoaded) {
            return _buildGridUsingTimelineData(context, homePageState, timelineState.data);
        }

        // Loading state
        if (timelineState is TwitterTimelineLoading) {
            return _buildGridUsingTimelineData(context, homePageState, timelineState.data);
        }
        // What is going on?
        assert(false);
        return Center(
            child: Text("Unhandled state $timelineState"),
        );
    }

    Widget _buildGridUsingTimelineData(BuildContext context, HomePageBlocState homePageState, TwitterTimelineData data) {

        assert(data != null);
        final tweets = data.tweets;
        final columnCount = homePageState.columnCount;
        assert(columnCount > 0);
        final compactTweetWidgetView = columnCount > 1;

        // as of now (Feb-17-2019) the SliverStaggeredGrid widget has a bug in RenderSliverStaggeredGrid
        // (does not clean up RenderSliverStaggeredGrid._pageSizeToViewportOffsets on cross axis count changing
        // so we just relayout the grid on column changing
        final gridKey = ValueKey(columnCount);

        _refreshCompleter?.complete();
        _refreshCompleter = Completer();

        return RefreshIndicator(
           onRefresh: (){
               _timelineBloc.dispatch(TwitterTimelineRefreshEvent());
               return _refreshCompleter.future;
           },
           child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                primary: false,
                slivers: <Widget>[
                    SliverStaggeredGrid.countBuilder(
                        key: gridKey,
                        crossAxisCount: columnCount,
                        mainAxisSpacing: 0.0,
                        crossAxisSpacing: 0.0,
                        itemCount: tweets.count,
                        itemBuilder: (context, index) {
                            if (index < tweets.count) {
                                return TweetWidget(
                                            tweet: tweets[index],
                                            isCompactView: compactTweetWidgetView
                                       );
                            }
                            assert(false);
                            return null;
                        },
                        staggeredTileBuilder: (index) => StaggeredTile.fit(1)
                    ),
                ]
            )
        );
    }

    // --------------------------------------------------------------------------------
    //  Dialogs
    // --------------------------------------------------------------------------------

    Widget _buildAlert(BuildContext context, String text, String buttonText, TwitterTimelineEvent buttonEvent) {
        final theme = Theme.of(context);

        return Center(child:
            Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                    Icon(Icons.error, size: 75.0, color: theme.accentColor),
                    SizedBox(height: 16),
                    Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Text(text, style: theme.textTheme.title, textAlign: TextAlign.center)
                    ),
                    SizedBox(height: 16),
                    FlatButton(
                        color: theme.accentColor,
                        onPressed: () {
                            _timelineBloc.dispatch(buttonEvent);
                        },
                        child: Text(buttonText, style: theme.accentTextTheme.button)
                    )
                ]
            )
        );
    }

    // --------------------------------------------------------------------------------
    //
    // --------------------------------------------------------------------------------

    @override
    void dispose() {
        OrientationNotifier().removeListener(_onOrientationChange);
        _scrollController.removeListener(_onScroll);
        _pageBloc.dispose();
        _timelineBloc.dispose();
        super.dispose();
    }
}
