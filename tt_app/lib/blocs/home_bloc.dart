import 'package:flutter/foundation.dart';
import 'package:bloc/bloc.dart';
import 'package:tt_app/helpers/helpers.dart';

enum HomePageEvent {
    switchToGrid,
    switchToList,
    setPortrait,
    setLandscape
}

@immutable
class HomePageBlocState {

    final bool isGrid;
    final bool isPortrait;

    bool get isList {
        return !isGrid;
    }

    // not sure if it must be moved to Bloc or made persistent. Not much differences for this simple bloc as of now
    int get columnCount {
        if (isGrid) {
            return isPortrait ? 2 : 3;
        } else {
            return 1;
        }
    }

    HomePageBlocState({ @required bool isGrid, @required bool isPortrait }):
        this.isGrid = isGrid,
        this.isPortrait = isPortrait,
        assert(isGrid != null),
        assert(isPortrait != null);

    HomePageBlocState copyWith({ bool isGrid, bool isPortrait }) {
        return HomePageBlocState(
                isGrid: isGrid ?? this.isGrid,
                isPortrait: isPortrait ?? this.isPortrait
        );
    }

    @override
    int get hashCode => isGrid.hashCode ^ isPortrait.hashCode;

    @override
    bool operator ==(Object other) {
        return identical(this, other) || other is HomePageBlocState && other.isGrid == isGrid && other.isPortrait == isPortrait;
    }

    @override
    String toString() {
        final sb = ToStringBuilder(this);
        sb.addTrue("isGrid", isGrid);
        sb.addTrue("isPortrait", isPortrait);
        sb.addTrue("isList", isList);
        sb.addTrue("isLandscape", !isPortrait);
        sb.add("columnCount", columnCount);
        return sb();
    }
}

class HomePageBloc extends Bloc<HomePageEvent, HomePageBlocState> {

    @override
    HomePageBlocState get initialState {
        return HomePageBlocState(isGrid: true, isPortrait: true);
    }

    @override
    Stream<HomePageBlocState> mapEventToState(HomePageBlocState currentState, HomePageEvent event) async* {
        HomePageBlocState result;
        switch (event) {
            case HomePageEvent.switchToGrid:
                result = currentState.copyWith(isGrid: true);
                break;
            case HomePageEvent.switchToList:
                result = currentState.copyWith(isGrid: false);
                break;
            case HomePageEvent.setPortrait:
                result = currentState.copyWith(isPortrait: true);
                break;
            case HomePageEvent.setLandscape:
                result = currentState.copyWith(isPortrait: false);
                break;
        }
        assert(result != null);
        yield result;
    }

    @override
    void onTransition(Transition<HomePageEvent, HomePageBlocState> transition) {
        debugPrint("Transition to ${transition.nextState} using event ${transition.event}");
    }
}
