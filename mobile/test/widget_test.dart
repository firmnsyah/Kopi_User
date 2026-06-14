import 'package:flutter_test/flutter_test.dart';
import 'package:kopi_user/data/mock_repository.dart';
import 'package:kopi_user/main.dart';
import 'package:kopi_user/state/session.dart';
import 'package:kopi_user/state/theme_controller.dart';

void main() {
  testWidgets('Login screen renders when no session', (tester) async {
    final session = AppSession(supabaseMode: false);
    await tester.pumpWidget(KopiUserApp(
      repository: MockRepository(),
      session: session,
      themeController: ThemeController(),
    ));
    await tester.pumpAndSettle();

    // 'EMPLOYEE ID' muncul sebagai label sekaligus hint field.
    expect(find.text('EMPLOYEE ID'), findsWidgets);
    expect(find.text('Clock In'), findsOneWidget);
  });
}
