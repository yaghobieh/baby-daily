# Coding Standards & Guidelines

## Flutter & Dart
1. **State Management**:
   - Use `Provider` (`ChangeNotifierProvider`, `MultiProvider`).
   - Extract UI state into distinct models and separate UI from network calls.
   - Guard asynchronous gaps with `mounted` or `context.mounted`.

2. **Localization (i18n & l10n)**:
   - All user-facing strings must pass through `AppStrings` / `LocaleState`.
   - Never hardcode English or Hebrew strings in widgets.
   - Text direction must respect RTL when Hebrew is active.

3. **Design System & Theming**:
   - Use `AppTheme.primary`, `AppTheme.mint`, `AppTheme.lavender`, `AppTheme.sun`, `AppTheme.sky`.
   - Card border radius should be 18-24px with subtle 1px border.
   - Buttons must use `ElevatedButton` or `OutlinedButton` with 16px border radius.

## Backend (Fastify + TypeScript)
1. **Validation**:
   - Every input payload must be strictly validated with `zod`.
   - Reject unexpected fields or type mismatches early with a 400 bad request.

2. **Error Responses**:
   - All error responses must adhere to the shape:
     ```json
     {
       "error": "snake_case_error_code",
       "message": "Human readable description"
     }
     ```
   - Client relies on `error` code for localized user feedback.

3. **Time & Dates**:
   - Dates stored in Neon PostgreSQL are always UTC.
   - Client sends its local offset to calculate timezone-aware quiet hours and daily summaries.
