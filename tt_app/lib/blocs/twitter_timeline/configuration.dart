
// Twitter timeline properties. Curretnly the only needed stuff is name of twitter user
class TwitterTimelineConfiguration {
    final String userName;

    TwitterTimelineConfiguration( { this.userName });

    copyWith({ String userName }) {
        return TwitterTimelineConfiguration(userName: userName ?? this.userName);
    }

    @override
    int get hashCode => userName.hashCode;

    @override
    bool operator == (Object other) {
        return identical(this, other) || (other is TwitterTimelineConfiguration && userName == other.userName);
    }

    String get issues {
        if (userName == null || userName.isEmpty) {
            return "Username is not set or empty";
        }
        return null;
    }
}
