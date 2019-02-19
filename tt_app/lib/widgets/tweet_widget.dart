import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:tt_app/models/models.dart';
import 'package:tt_app/helpers/helpers.dart';
import 'package:intl/intl.dart';

class TweetWidget extends StatelessWidget {

    final Tweet tweet;
    final bool isCompactView;

    TweetWidget({ this.tweet, this.isCompactView });

    @override
    Widget build(BuildContext context) {
        return Card(
            child: Padding(padding: EdgeInsets.fromLTRB(8, 12, 8, 8),
                child: isCompactView ? _buildCompactView(context) : _buildExpandedView(context)
            )
        );
    }

    Widget _buildCompactView(BuildContext context) {
        return Column(
            children: buildWidgetList([
                Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        _buildUserAvatar(),
                        SizedBox(width: 8),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: buildWidgetList([
                                    _buildUserTopLine(context)
                                ])
                            )
                        ),
                    ],
                ),
                SizedBox(height: 4),
                Text(tweet.text),
                _buildPictureIfAny(topGap: 8)
            ]),
        );
    }

    Widget _buildExpandedView(BuildContext context) {
        return Column(
            children: buildWidgetList([
                Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        _buildUserAvatar(),
                        SizedBox(width: 8),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: buildWidgetList([
                                    _buildUserTopLine(context),
                                    SizedBox(height: 4),
                                    Text(tweet.text),
                                    _buildPictureIfAny(topGap: 8)
                                ])
                            )
                        ),
                    ],
                )
            ]),
        );
    }

    Widget _buildUserAvatar() {
        return Container(
            width: 50,
            height: 56,
            padding: EdgeInsets.fromLTRB(0, 0, 0,10),
            // color: Colors.teal[50],
            child: Center(child:
                CircleAvatar(
                    backgroundColor: Colors.grey[200],
                    backgroundImage: NetworkImage(tweet.user.iconUrlString),
                    radius: 22
                )
            )
        );
    }

    Widget _buildUserTopLine(BuildContext context) {

        final theme = Theme.of(context);
        var grayedStyle =  theme.textTheme.body2;
        grayedStyle = grayedStyle.copyWith(color: grayedStyle.color.withAlpha(127), fontWeight: FontWeight.normal);

        // Move to helpers?
        String timeString;
        final difference = DateTime.now().difference(tweet.timestamp);
        do {
            if (difference.inSeconds < 60) {
                timeString = "now";
                break;
            }
            if (difference.inMinutes < 60) {
                timeString = "${difference.inMinutes}m";
                break;
            }
            if (difference.inHours < 24) {
                timeString = "${difference.inHours}h";
                break;
            }
            if (difference.inDays < 30) {
                timeString = "${difference.inDays}d";
                break;
            }
            timeString = DateFormat("d MMM y").format(tweet.timestamp);
        } while(false);

        // return Text(tweet.user.name);
        return RichText(
            text: TextSpan(
                text: tweet.user.name, // debug: "${tweet.index}: ${tweet.user.name}",
                style: theme.textTheme.subtitle,
                children: [
                    TextSpan(text: ' '),
                    TextSpan(text: '@${tweet.user.screenName} · $timeString', style: grayedStyle)
                ],
            ),
        );
    }

    List<Widget> _buildPictureIfAny({ double topGap }) {
        if (tweet.mainPhotoURL != null && tweet.mainPhotoURL.isNotEmpty) {
            return [
                SizedBox(height: topGap),
                Container(
                    height: 100,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        image: DecorationImage(
                            fit: BoxFit.cover,
                            image: NetworkImage(tweet.mainPhotoURL),
                        )
                    ),
                )
            ];
        }
        return null;
    }
}
