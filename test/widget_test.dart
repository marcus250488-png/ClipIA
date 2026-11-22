import 'package:flutter_test/flutter_test.dart';
import 'package:clipia/app.dart';

void main() {
  testWidgets('exibe a tela inicial do ClipIA', (tester) async {
    await tester.pumpWidget(const ClipIaApp());

    expect(find.text('✨ ClipIA'), findsOneWidget);
    expect(find.text('Transforme vídeos longos em cortes curtos'), findsOneWidget);
  });
}
