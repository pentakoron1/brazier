import 'package:material_ui/material_ui.dart';

class AppTheme {
  static const String funnelDisplayFont = 'Funnel Display';
  static const String ralewayFont = 'Raleway';

  /// Builds the application TextTheme using Funnel Display for big text and titles,
  /// and Raleway for all other text (body, labels, captions, buttons, etc.).
  static TextTheme createTextTheme(TextTheme baseTextTheme) {
    // 1. Raleway for base text theme (body, labels, etc.)
    final ralewayTheme = baseTextTheme.apply(
      fontFamily: ralewayFont,
    );

    // 2. Helper to apply Funnel Display font to title & big text styles
    TextStyle applyFunnelDisplay(TextStyle? original) {
      if (original == null) {
        return const TextStyle(
          fontFamily: funnelDisplayFont,
          fontFamilyFallback: [ralewayFont, 'sans-serif'],
        );
      }
      return original.copyWith(
        fontFamily: funnelDisplayFont,
        fontFamilyFallback: const [
          ralewayFont,
          'sans-serif',
        ],
      );
    }

    return ralewayTheme.copyWith(
      // Big text (Display & Headline)
      displayLarge: applyFunnelDisplay(ralewayTheme.displayLarge),
      displayMedium: applyFunnelDisplay(ralewayTheme.displayMedium),
      displaySmall: applyFunnelDisplay(ralewayTheme.displaySmall),
      headlineLarge: applyFunnelDisplay(ralewayTheme.headlineLarge),
      headlineMedium: applyFunnelDisplay(ralewayTheme.headlineMedium),
      headlineSmall: applyFunnelDisplay(ralewayTheme.headlineSmall),

      // Titles
      titleLarge: applyFunnelDisplay(ralewayTheme.titleLarge),
      titleMedium: applyFunnelDisplay(ralewayTheme.titleMedium),
      titleSmall: applyFunnelDisplay(ralewayTheme.titleSmall),
    );
  }

  /// Helper to generate Funnel Display style for big text / titles
  static TextStyle funnelDisplay({
    TextStyle? style,
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    double? letterSpacing,
  }) {
    final base = style ?? const TextStyle();
    return base.copyWith(
      fontFamily: funnelDisplayFont,
      fontFamilyFallback: const [ralewayFont, 'sans-serif'],
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
    );
  }

  /// Helper to generate Raleway style for general text
  static TextStyle raleway({
    TextStyle? style,
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    double? letterSpacing,
  }) {
    final base = style ?? const TextStyle();
    return base.copyWith(
      fontFamily: ralewayFont,
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
    );
  }
}

class AppColors {
  static const Color primaryOrange = Color(0xFF4F3BD1);
  static const Color fireOrange = Color(0xFFFF5226); // Single unified Fire Orange Accent

  // Yellow-to-Orange Flame Gradient Colors
  static const Color flameYellow = Color(0xFFFFB326);
  static const Color yellowOrange = Color(0xFFFF9A26);
  static const Color flameOrange = Color(0xFFFF5226);


  // Central Card & Background Colors (Easily customizable right here!)
  static const Color scaffoldBackground = Color(0xFF12151C); // Main screen background
  static const Color cardBackground = Color(0xFF1C222D);     // Item card & panel background
  static const Color cardBorder = Color(0xFF2B3342);         // Card border outline
  static const Color containerBackground = Color(0xFF242C3B); // Inner box container background
  static const Color darkSlateNotUsed = Color(0xFF252E3E);   // "Not Used" button & badge background
  static const Color unfilledTrack = Color(0xFF28303F);      // Progress bar unfilled track
}

class AppGradients {
  static const LinearGradient flameGradient = LinearGradient(
    colors: [
      AppColors.flameYellow,
      AppColors.flameOrange,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient orangeGradient = LinearGradient(
    colors: [
      AppColors.yellowOrange,
      AppColors.flameOrange,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}


/// Helper widget to render text with a Yellow-to-Orange gradient!
class GradientText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Gradient gradient;

  const GradientText(
    this.text, {
    super.key,
    this.style,
    this.gradient = AppGradients.flameGradient,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: Text(
        text,
        style: style,
      ),
    );
  }
}
