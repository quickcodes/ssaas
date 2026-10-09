# SSAAS Coding Standards, Entity Design & Testing Rules

These guidelines are mandatory for code structure, error handling, entity creation, and testing in SSAAS (`Constants.appName`).

## 1. Naming Conventions & File Organization

- **File Naming**: Lowercase with underscores (`snake_case.dart`), e.g. `start_session_dialog.dart`, `table_session.dart`.
- **Class Naming**: `PascalCase`, e.g. `TableSession`, `CheckoutSessionDialog`, `FloorMatrixBloc`.
- **Variable & Method Naming**: `camelCase`, e.g. `playedSeconds`, `computeGrandTotalAt`.
- **File Placement**:
  - Pure domain entities -> `lib/domain/entities/`
  - Data sources & storage -> `lib/data/datasources/`
  - BLoCs & events -> `lib/presentation/blocs/<feature>/`
  - Views & screens -> `lib/presentation/views/<feature>/`
  - Reusable widgets -> `lib/presentation/widgets/`
  - Core utilities & theme -> `lib/core/`

## 2. Domain Entity Design & Immutability

Domain entities in `lib/domain/entities/` MUST follow these standards:

1. **Immutability**: All fields must be `final`.
2. **Value Equality**: Extend `Equatable` and implement `props`:
   ```dart
   class ClubTable extends Equatable {
     final String id;
     final String name;
     ...
     @override
     List<Object?> get props => [id, name, ...];
   }
   ```
3. **Copying State**: Every entity must provide a `copyWith()` method for clean immutable updates.
4. **Serialization**: Provide `toMap()` and `factory Entity.fromMap(String id, Map<String, dynamic> map)` for Firestore object mapping. Handle missing or null fields gracefully with sensible fallback defaults.

## 3. Error Handling & User Notifications

- **Datasource Layer Exception Formatting**: Catch low-level Firebase and network exceptions in `FirestoreService` / BLoCs and format them using `AppErrorHandler.format(e)` (`lib/core/utils/error_handler.dart`).
- **User Feedback**: Present error messages using `AppErrorHandler.showErrorSnackBar(context, error)` or via BLoC state `errorMessage`.
- **Production Logging**: Use `debugPrint()` for debug logs. Do NOT use standard `print()`.

## 4. FVM Tooling Rules

All terminal commands performed on this repository MUST be prefixed with `fvm`:

- `fvm flutter pub get`
- `fvm flutter analyze`
- `fvm flutter test`
- `fvm flutter build apk --release`
- `fvm flutter build web`
- `fvm dart run build_runner build`

Never execute global `flutter` or `dart` commands directly.

## 5. Testing & Code Quality Expectations

- **Static Analysis**: `fvm flutter analyze` must run cleanly without warnings or errors.
- **Unit Tests**: Place unit tests in `test/`. Use `flutter_test`.
- **Natural Sorting**: When sorting tables or list views by name, use `AppFormatters.naturalCompare(a.name, b.name)` (`lib/core/utils/formatters.dart`) to ensure "Table 2" comes before "Table 10".
