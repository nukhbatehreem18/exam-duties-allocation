import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:exam_duties_allocation/core/app_router.dart';
import 'package:exam_duties_allocation/features/auth/auth_controller.dart';
import 'package:exam_duties_allocation/models/user_role.dart';

void main() {
  test('nobody is logged in at the start', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(authProvider), isNull);
  });

  test('coordinator login succeeds and sets the coordinator role', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final ok = container
        .read(authProvider.notifier)
        .login('coordinator@bahria.edu.pk', '123456');

    expect(ok, true);
    expect(container.read(authProvider)!.role, UserRole.coordinator);
  });

  test('staff login succeeds and sets the staff role', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container
        .read(authProvider.notifier)
        .login('staff@bahria.edu.pk', '123456');

    expect(container.read(authProvider)!.role, UserRole.staff);
  });

  test('wrong password is rejected', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final ok = container
        .read(authProvider.notifier)
        .login('staff@bahria.edu.pk', 'wrong');

    expect(ok, false);
    expect(container.read(authProvider), isNull);
  });

  test('logout clears the user', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final auth = container.read(authProvider.notifier);
    auth.login('staff@bahria.edu.pk', '123456');
    auth.logout();

    expect(container.read(authProvider), isNull);
  });

  testWidgets('staff cannot open coordinator pages (router guard)',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container
        .read(authProvider.notifier)
        .login('staff@bahria.edu.pk', '123456');
    final router = container.read(routerProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    // Staff tries to open a coordinator page.
    router.go('/coordinator/staff');
    await tester.pumpAndSettle();

    // The guard sends the staff user back to the staff home screen.
    expect(find.text('My Duties'), findsOneWidget);
    expect(find.text('Manage Staff'), findsNothing);
  });
}