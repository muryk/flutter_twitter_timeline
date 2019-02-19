import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';

typedef OrientationChangeCallback = void Function(Orientation orientation);

/// See all explanations at [ChangeNotifier].
class OrientationNotifier {
    ObserverList<OrientationChangeCallback> _listeners = ObserverList<OrientationChangeCallback>();
    EventChannel _eventChannel = const EventChannel('tt_plugin/interface_orientation');
    StreamSubscription _subscription;

    // will use singleton
    static final _shared = new OrientationNotifier._internal();
    factory OrientationNotifier() {
        return _shared;
    }
    OrientationNotifier._internal() {
       _subscription = _eventChannel.receiveBroadcastStream().listen(_onEvent);
    }

    Orientation orientation = Orientation.portrait;

    void _onEvent(dynamic arg) {
        orientation = (arg as int) == 1 ? Orientation.landscape : Orientation.portrait;
        notifyListeners(orientation);
    }

    bool _debugAssertNotDisposed() {
        assert(() {
            if (_listeners == null) {
                throw FlutterError(
                    'A $runtimeType was used after being disposed.\n'
                    'Once you have called dispose() on a $runtimeType, it can no longer be used.'
                );
            }
            return true;
        }());
        return true;
    }

    void addListener(OrientationChangeCallback listener) {
        assert(_debugAssertNotDisposed());
        _listeners.add(listener);
    }

    void removeListener(OrientationChangeCallback listener) {
        assert(_debugAssertNotDisposed());
        _listeners.remove(listener);
    }

    @mustCallSuper
    void dispose() {
        assert(_debugAssertNotDisposed());
        _listeners = null;
        _subscription?.cancel();
        _subscription = null;
    }

    void notifyListeners(Orientation orientation) {
        assert(_debugAssertNotDisposed());
        if (_listeners != null) {
            final List<OrientationChangeCallback> localListeners = List<OrientationChangeCallback>.from(_listeners);
            for (OrientationChangeCallback listener in localListeners) {
                try {
                    if (_listeners.contains(listener)) {
                        listener(orientation);
                    }
                } catch (exception, stack) {
                    FlutterError.reportError(FlutterErrorDetails(
                            exception: exception,
                            stack: stack,
                            library: 'foundation library',
                            context: 'while dispatching notifications for $runtimeType',
                            informationCollector: (StringBuffer information) {
                                information.writeln('The $runtimeType sending notification was:');
                                information.write('  $this');
                            }
                    ));
                }
            }
        }
    }
}
