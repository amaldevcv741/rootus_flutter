# Rootus Project Rules

## Design & Styling
Always use the centralized design system for any UI changes or new screens:
- **Flutter**: NEVER use hardcoded hex colors or `Colors.xyz`. ALWAYS use the colors, typography, and button styles defined in `lib/core/theme/app_theme.dart` (e.g., `AppColors.primary`, `AppButtonStyles.primary`).
- **Typography**: ALWAYS use the 'Poppins' font (GoogleFonts.poppins) across all UI components, including forms, inputs, and buttons.
- Ensure new components conform to the "Rootus" branding (Primary: `#21AC7A`, Secondary: `#FFE700`).
