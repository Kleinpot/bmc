import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/main.dart';

void main() {
  test('parses products with numeric legacy id and tint fields', () {
    final perfume = Perfume.fromRow({
      'id': 7,
      'name': 'Test fragrance',
      'house': 'Test house',
      'price': 1200,
      'family': 'Woody',
      'image': 'test-image',
      'tint': 4293259703,
      'description': 'A test fragrance.',
      'notes': ['Cedar', 7],
      'longevity': '8 hours',
      'label': null,
    });

    expect(perfume.id, '7');
    expect(perfume.tint.toARGB32(), 4293259703);
    expect(perfume.notes, ['Cedar', '7']);
  });
}
