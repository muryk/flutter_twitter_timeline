import 'package:flutter/widgets.dart';

// --------------------------------------------------------------------------------
// Widgets
// --------------------------------------------------------------------------------

// just remove possible nulls from widget list + expand list of lists
// this is very useful for conditional widget building

List<Widget>buildWidgetList(List<dynamic> items) {
    final result = List<Widget>();
    for (dynamic item in items) {
         if (item is Widget) {
             result.add(item);
             continue;
         }
         if (item == null) {
             continue;
         }
         if (item is List) {
             result.addAll(buildWidgetList(item));
             continue;
         }
         assert(false, "A widget expected: $item is not one");
    }
    return result;
}

// --------------------------------------------------------------------------------
// Twitter stuff
// --------------------------------------------------------------------------------

DateTime parseTwitterTimestamp(String s) {
    // Was unable to make 'intl' package parse timezones properly, did all the stuff myself
    // The idea is to rebuild incoming string to the format that DateTime.parse() accepts. Fast and dirty!
    // "Thu Feb 14 14:58:02 +0000 2019"

    final c = s.split(" ");
    assert(c.length == 6);
    const months = {
        "Jan": "01", // sorry for that. it works and it is fast
        "Feb": "02",
        "Mar": "03",
        "Apr": "04",
        "May": "05",
        'Jun': "06",
        'Jul': "07",
        'Aug': "08",
        'Sep': "09",
        'Oct': "10",
        'Nov': "11",
        'Dec': "12"
    };

    return DateTime.parse("${c[5]}-${months[c[1]]}-${c[2]}T${c[3]}${c[4]}");
}

// --------------------------------------------------------------------------------
// region: Exceptions
// --------------------------------------------------------------------------------

// Just do not want "Exception: " prefix. Did not found a good way to extract a message from an abstract Exception
String messageFromError(dynamic error) {
    String message = error.toString();
    if (message.startsWith("Exception: ")) {
        message = message.replaceFirst("Exception: ", "");
    }
    return message;
}

// --------------------------------------------------------------------------------
// region: ToStringBuilder - creating toString() stuff in unified way
// --------------------------------------------------------------------------------

class ToStringBuilder {

    final Object object;
    final List<_ToStringBuilderItem> items = [];

    ToStringBuilder(this.object): assert(object != null);

    void add(String name, dynamic value) {
        items.add(_ToStringBuilderItem(name, value, true));
    }

    void addTrue(String name, bool value) {
        if (value) {
            items.add(_ToStringBuilderItem(null, name, false));
        }
    }

    void addValue(dynamic value) {
        items.add(_ToStringBuilderItem(null, value, true));
    }

    @override
    String toString() {
        final params = items.map((item) => item.toString()).where((s) => s != null && s.isNotEmpty).join(", ");
        if (params.isNotEmpty) {
            return "<${object.runtimeType}, $params>";
        } else {
            return "<${object.runtimeType}>";
        }
    }

    String call() => toString();
}

class _ToStringBuilderItem {
    final String name;
    final dynamic value;
    final bool quoteStringValues;

    _ToStringBuilderItem(this.name, this.value, this.quoteStringValues);

    @override
    String toString() {
        if (value != null) {
            final valueString = quoteStringValues && value is String ? "'$value'" : "$value";
            if (name != null) {
                return "$name: $valueString";
            } else {
                return valueString;
            }
        }
        return null;
    }
}