import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app.dart';
import 'package:mobile/services/supabase_auth_service.dart';

void main() {
  test('phone numbers are normalized to E.164', () {
    expect(normalizePhoneNumber('+996 555 123 456'), '+996555123456');
    expect(normalizePhoneNumber('555 123 456'), '+996555123456');
    expect(normalizePhoneNumber('996555123456'), '+996555123456');
  });

  void setPhoneSize(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets(
    'splash automatically opens the food catalog without registration',
    (tester) async {
      setPhoneSize(tester);
      await tester.pumpWidget(const SaveMealApp());

      expect(find.byType(SplashScreen), findsOneWidget);
      expect(
        find.text('Спасаем еду. Помогаем людям. Снижаем пищевые отходы.'),
        findsNothing,
      );
      await tester.pump(const Duration(milliseconds: 2600));

      expect(find.byType(SplashScreen), findsNothing);
      expect(find.text('Курица с рисом'), findsOneWidget);
      expect(find.text('Демо-меню'), findsNothing);
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(ChoiceChip), findsNothing);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.text('0'), findsAtLeastNWidgets(1));
      expect(find.text('Войти'), findsNothing);
    },
  );

  testWidgets('catalog fits common phone screen sizes', (tester) async {
    for (final size in [
      const Size(320, 640),
      const Size(360, 800),
      const Size(390, 844),
      const Size(430, 932),
    ]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(const SaveMealApp());
      await tester.pump(const Duration(milliseconds: 2600));

      expect(find.text('Курица с рисом'), findsOneWidget);
      final layoutError = tester.takeException();
      expect(layoutError, isNull, reason: 'Phone size: $size');

      await tester.pumpWidget(const SizedBox.shrink());
    }

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });

  testWidgets('catalog buy submits every selected listing together', (
    tester,
  ) async {
    setPhoneSize(tester);
    await tester.pumpWidget(const SaveMealApp());
    await tester.pump(const Duration(milliseconds: 2600));

    expect(find.byKey(const ValueKey('catalog-buy-panel')), findsNothing);

    final chickenPlus = find.byKey(
      const ValueKey('quantity-plus-preview-chicken-rice'),
    );
    await tester.scrollUntilVisible(
      chickenPlus,
      80,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(chickenPlus);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey('quantity-value-preview-chicken-rice')),
          )
          .data,
      '1',
    );

    final burgerPlus = find.byKey(
      const ValueKey('quantity-plus-preview-burger'),
    );
    await tester.scrollUntilVisible(
      burgerPlus,
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(burgerPlus);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('catalog-buy')), findsOneWidget);
    expect(find.text('2 порции'), findsOneWidget);
    expect(find.text('520 сом'), findsOneWidget);
    expect(
      find.ancestor(
        of: find.byKey(const ValueKey('catalog-buy')),
        matching: find.byKey(const ValueKey('catalog-buy-panel')),
      ),
      findsOneWidget,
    );

    final panelBeforeScroll = tester.getTopLeft(
      find.byKey(const ValueKey('catalog-buy-panel')),
    );
    await tester.drag(
      find.byType(CustomScrollView).first,
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('catalog-buy-panel'))),
      panelBeforeScroll,
    );
    await tester.tap(find.byKey(const ValueKey('catalog-buy')));
    await tester.pumpAndSettle();

    expect(find.text('Оформим заказ'), findsOneWidget);
    expect(find.text('Курица с рисом × 1'), findsOneWidget);
    expect(find.text('Бургер с говядиной × 1'), findsOneWidget);
    expect(find.text('520 сом'), findsOneWidget);
    expect(find.text('Как получите заказ?'), findsOneWidget);
    expect(find.text('Выберите способ получения заказа'), findsNothing);
    await tester.tap(find.text('Самовывоз'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Демонстрационный адрес'), findsOneWidget);
    expect(find.textContaining('ул. Киевская, 114'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(3));
  });

  testWidgets('delivery address is required on combined checkout screen', (
    tester,
  ) async {
    setPhoneSize(tester);
    await tester.pumpWidget(const SaveMealApp());
    await tester.pump(const Duration(milliseconds: 2600));

    final plus = find.byKey(
      const ValueKey('quantity-plus-preview-chicken-rice'),
    );
    await tester.scrollUntilVisible(
      plus,
      80,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(plus);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey('quantity-value-preview-chicken-rice')),
          )
          .data,
      '1',
    );
    await tester.tap(find.byKey(const ValueKey('catalog-buy')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Доставка'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('delivery-address')), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(4));

    final submit = find.text('Создать аккаунт и продолжить');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(find.text('Укажите адрес доставки'), findsOneWidget);
    expect(find.text('Введите корректный номер телефона'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('delivery-address')),
      'ул. Киевская, 10, кв. 5',
    );
    await tester.enterText(
      find.byKey(const ValueKey('registration-name')),
      'Айжан Тест',
    );
    await tester.enterText(
      find.byKey(const ValueKey('registration-phone')),
      '+996 555 123 456',
    );
    await tester.enterText(
      find.byKey(const ValueKey('registration-password')),
      'securepass123',
    );
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(find.text('Укажите адрес доставки'), findsNothing);
    expect(find.text('Введите корректный номер телефона'), findsNothing);
    expect(find.text('Оформим заказ'), findsOneWidget);
  });

  testWidgets('valid pickup registration asks for Supabase configuration', (
    tester,
  ) async {
    setPhoneSize(tester);
    await tester.pumpWidget(const SaveMealApp());
    await tester.pump(const Duration(milliseconds: 2600));

    final plus = find.byKey(
      const ValueKey('quantity-plus-preview-chicken-rice'),
    );
    await tester.scrollUntilVisible(
      plus,
      80,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(plus);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('catalog-buy')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Самовывоз'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('registration-name')),
      'Айжан Тест',
    );
    await tester.enterText(
      find.byKey(const ValueKey('registration-phone')),
      '+996 555 123 456',
    );
    await tester.enterText(
      find.byKey(const ValueKey('registration-password')),
      'securepass123',
    );
    final submit = find.text('Создать аккаунт и продолжить');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Укажите SUPABASE_URL и SUPABASE_ANON_KEY'),
      findsNWidgets(2),
    );
    expect(find.text('Оформим заказ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
