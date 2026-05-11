import 'package:flutter_test/flutter_test.dart';
import 'package:kopi_user/data/mock_repository.dart';
import 'package:kopi_user/main.dart';
import 'package:kopi_user/state/session.dart';

void main() {
  testWidgets('Login screen renders when no session', (tester) async {
    final session = Session();
    await tester.pumpWidget(KopiUserApp(
      repository: MockRepository(),
      session: session,
    ));
    await tester.pumpAndSettle();

    expect(find.text('Kopi User'), findsOneWidget);
    expect(find.text('Clock In'), findsOneWidget);
  });
}
