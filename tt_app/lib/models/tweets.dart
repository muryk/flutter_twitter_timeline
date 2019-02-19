import 'package:tt_app/helpers/helpers.dart';
import './tweet.dart';

// A collection of Tweets.
// Keeps tweets uniqueness (by identifier, automatically sorted by identifier)
class Tweets {
    List<Tweet> _items;
    var _itemMap = Map<String, Tweet>();

    Tweets(Iterable<Tweet> items) {
        _addItems(items);
        _validate();
    }

    void _addItems(Iterable<Tweet> items) {
        if (items != null) {
            for (Tweet item in items) {
                _itemMap[item.identifier] = item;
            }
        }
    }

    void _validate() {
        _items = _itemMap.values.toList();
        _items.sort((a, b) {
            String id2 = a.identifier;
            String id1 = b.identifier;
            if (id1.length == id2.length) {
                return id1.compareTo(id2);
            }
            return id1.length < id2.length ? -1 : 1;
        });

        int index = 0;
        for (Tweet item in _items) {
            item.index = index++;
        }
    }

    int get count => _items.length;
    bool get isEmpty => _items.isEmpty;
    operator [](int index) => _items[index];

    String get earliestIdentifier => _items.isEmpty ? null : _items.last.identifier;
    String get latestIdentifier => _items.isEmpty ? null : _items.first.identifier;

    Tweets operator +(Tweets other) {

        Tweets result = Tweets(null);
        result._addItems(_items);
        result._addItems(other._items);
        result._validate();
        return result;
    }

    @override
    int get hashCode => _items.hashCode;

    @override
    bool operator ==(Object other) {
        return identical(this, other) || ( other is Tweets && other._items == _items);
    }

    @override
    String toString() {
        final result = ToStringBuilder(this);
        result.add('count', count);
        result.add('earliest', earliestIdentifier);
        result.add('latest', latestIdentifier);
        return result();
    }
}
