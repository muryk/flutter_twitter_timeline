import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

abstract class TwitterApiResponse { }

class TwitterApiError extends TwitterApiResponse {

    final String message;

    TwitterApiError(this.message);

    @override
    String toString() {
        return "<$runtimeType: '$message'>";
    }
}

class TwitterApiJSONResponse extends TwitterApiResponse {
    final dynamic json;

    TwitterApiJSONResponse(this.json) {
        assert(this.json != null);
    }

    @override
    String toString() {
        return "<$runtimeType: ${json.runtimeType}>";
    }

    String get asString {
        return json as String;
    }
}

class TwitterApiStringResponse extends TwitterApiResponse {
    final String string;

    TwitterApiStringResponse(this.string) {
        assert(this.string != null);
    }

    @override
    String toString() {
        return "<$runtimeType: '$string'>";
    }
}

class TwitterApiClient {

    static const MethodChannel _channel = const MethodChannel('tt_plugin/twitter');

    static log(String string) {
        debugPrint("TTPlugin: $string");
    }

    static Future<TwitterApiResponse> getTimeline({
        @required String taskIdentifier,
        @required String userName,
        int count,
        String maxIdentifier,
        String sinceIdentifier
    }) async {
        assert(taskIdentifier != null);
        assert(userName != null);

        log("=> getTimeline($taskIdentifier, $userName, $count, $maxIdentifier, $sinceIdentifier)");
        final Map<dynamic, dynamic> rawResponse = await _channel.invokeMethod('getTimeline', {
            "taskIdentifier" : taskIdentifier,
            "userName" : userName,
            "count": count ?? 20,
            "maxIdentifier": maxIdentifier,
            "sinceIdentifier": sinceIdentifier
        });

        final result = await _parseRawResponse(rawResponse);
        log("<= getTimeline(): $result");
        return result;
    }

    static Future<TwitterApiResponse> startTask() async {
        log("=> startTask()");
        final Map<dynamic, dynamic> rawResponse = await _channel.invokeMethod('startTask');

        final result = await _parseRawResponse(rawResponse);
        log("<= startTask(): $result");
        return result;
    }

    static Future<TwitterApiResponse> cancelTask(String taskIdentifier) async {
        assert(taskIdentifier != null);

        log("=> cancelTask()");
        final Map<dynamic, dynamic> rawResponse = await _channel.invokeMethod('cancelTask', {
            "taskIdentifier" : taskIdentifier
        });

        final result = await _parseRawResponse(rawResponse);
        log("<= cancelTask(): $result");
        return result;
    }

    static Future<TwitterApiResponse> _parseRawResponse(Map<dynamic, dynamic> rawResponse) async {
        final errorString = rawResponse["error"];
        if (errorString is String) {
            return TwitterApiError(errorString);
        }

        final jsonString = rawResponse["json"];
        if (jsonString is String) {
            try {
                final parsedJSON = json.decode(jsonString);
                return TwitterApiJSONResponse(parsedJSON);
            } catch (e) {
                return TwitterApiError("JSON parsing failed: $e");
            }
        }

        final simpleString = rawResponse["string"];
        if (simpleString is String) {
            return TwitterApiStringResponse(simpleString);
        }
        return TwitterApiError("Malformed result returned: 'json', 'string' or 'error' keys are expected");
    }
}
