class TransactionFilter {
  const TransactionFilter({this.search, this.from, this.to, this.itemId});

  final String? search;
  final String? from;
  final String? to;
  final int? itemId;

  bool get isEmpty =>
      search == null && from == null && to == null && itemId == null;

  int get activeCount => [
    search != null,
    from != null || to != null,
    itemId != null,
  ].where((active) => active).length;

  TransactionFilter copyWith({
    String? search,
    String? from,
    String? to,
    int? itemId,
    bool clearSearch = false,
    bool clearFrom = false,
    bool clearTo = false,
    bool clearItemId = false,
  }) {
    return TransactionFilter(
      search: clearSearch ? null : (search ?? this.search),
      from: clearFrom ? null : (from ?? this.from),
      to: clearTo ? null : (to ?? this.to),
      itemId: clearItemId ? null : (itemId ?? this.itemId),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TransactionFilter &&
        other.search == search &&
        other.from == from &&
        other.to == to &&
        other.itemId == itemId;
  }

  @override
  int get hashCode => Object.hash(search, from, to, itemId);
}
