import 'package:flutter_test/flutter_test.dart';
import 'package:clipia/app.dart';

void main() {
  testWidgets('exibe a nova tela inicial do ClipIA', (tester) async {
    await tester.pumpWidget(const ClipIaApp());

    expect(find.text('ClipIA'), findsOneWidget);
    expect(find.text('SEU ESTÚDIO DE CORTES'), findsOneWidget);
    expect(find.text('Transforme vídeos longos em conteúdo que prende atenção.'), findsOneWidget);
    expect(find.text('Selecionar vídeo do aparelho'), findsOneWidget);
    expect(find.text('Colar link do YouTube'), findsOneWidget);
    expect(find.text('Meus projetos'), findsOneWidget);
  });
}
