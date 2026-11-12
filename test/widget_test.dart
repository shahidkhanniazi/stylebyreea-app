import 'package:flutter_test/flutter_test.dart';
import 'package:stylebyreea/models.dart';

void main() {
  test('money formats minor units', () {
    expect(const Money(200).toString(), '£2.00');
  });
  test('sizes are ordered', () {
    expect(sizeRank('s') < sizeRank('xl'), true);
    expect(sizeRank('8') < sizeRank('12'), true);
  });
}
