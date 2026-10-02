import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpl_warzone/features/auth/forgot_page.dart';
import 'package:fpl_warzone/features/transfers/transfers_page.dart';

void main() {
  Widget host(Widget w) => MaterialApp(home: Scaffold(body: Center(child: SizedBox(width: 400, child: w))));

  testWidgets('slide to confirm fires only when dragged to the end', (t) async {
    var fired = 0;
    await t.pumpWidget(host(SlideToConfirm(label: 'Slide to confirm transfers', onConfirmed: () => fired++)));
    final thumb = find.byIcon(Icons.double_arrow_rounded);

    await t.drag(thumb, const Offset(150, 0));   // released early → springs back, nothing sent
    await t.pump();
    expect(fired, 0);

    await t.drag(thumb, const Offset(500, 0));   // dragged to the end → confirmed once
    await t.pump();
    expect(fired, 1);

    await t.drag(thumb, const Offset(500, 0), warnIfMissed: false);   // already confirmed → cannot fire twice
    await t.pump();
    expect(fired, 1);
  });

  testWidgets('slide to confirm is locked while busy', (t) async {
    var fired = 0;
    await t.pumpWidget(host(SlideToConfirm(label: 'x', busy: true, onConfirmed: () => fired++)));
    await t.drag(find.byType(CircularProgressIndicator), const Offset(500, 0), warnIfMissed: false);
    await t.pump();
    expect(fired, 0);
  });

  test('reset email is masked', () {
    expect(ForgotPageMask.mask('sohel.khan@example.com'), 's********n@example.com');
    expect(ForgotPageMask.mask('ab@x.io'), 'a*@x.io');
    expect(ForgotPageMask.mask('not-an-email'), 'not-an-email');
  });
}
