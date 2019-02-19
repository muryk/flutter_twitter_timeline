import 'package:flutter_test/flutter_test.dart';
import 'package:tt_app/helpers/helpers.dart';

void main() {
    group('Helpers method testing', () {
        test('Twitter timestamps', () {

            final d = parseTwitterTimestamp("Thu Feb 04 14:58:12 +0000 2019");
            expect(d.year, 2019);
            expect(d.month, 2);
            expect(d.day, 4);
            expect(d.hour, 14);
            expect(d.minute, 58);
            expect(d.second, 12);
        });
    });
}
