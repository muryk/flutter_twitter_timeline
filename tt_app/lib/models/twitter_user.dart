import 'package:tt_app/helpers/helpers.dart';

class TwitterUser {

    final String description;
    final String identifier;
    final String location;
    final String screenName;
    final String name;
    final String urlString;
    final String iconUrlString;

    TwitterUser.fromJson(dynamic json):
        description = json['description'],
        identifier = json['id_str'],
        location = json['location'],
        name = json['name'],
        screenName = json['screen_name'],
        urlString = json['url'],
        iconUrlString = json['profile_image_url'];

    @override
    int get hashCode =>
        description.hashCode ^
        identifier.hashCode ^
        location.hashCode ^
        screenName.hashCode ^
        name.hashCode ^
        urlString.hashCode ^
        iconUrlString.hashCode;

    @override
    bool operator ==(Object other) {
        return identical(this, other) || ( other is TwitterUser &&
            other.description == description &&
            other.identifier == identifier &&
            other.location == location &&
            other.screenName == screenName &&
            other.name == name &&
            other.urlString == urlString &&
            other.iconUrlString == iconUrlString
        );
    }

    @override
    String toString() {
        final result = ToStringBuilder(this);
        result.add('id', identifier);
        result.addValue(screenName);
        result.addValue(name);
        return result();
    }
}
