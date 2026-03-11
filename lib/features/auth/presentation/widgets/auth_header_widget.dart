import 'package:flutter/material.dart';
import 'package:yurt_yoklama/core/widgets/wave_painter.dart';

class AuthHeaderWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData? icon;

  const AuthHeaderWidget({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headerColor = theme.colorScheme.surfaceContainerLow;

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenHeight = constraints.maxHeight;
        final isShortScreen = screenHeight < 200;
        final iconSize = isShortScreen ? 24.0 : 40.0;
        final iconPadding = isShortScreen ? 8.0 : 12.0;

        return Stack(
          fit: StackFit.expand,
          children: [
            // Arka Plan Rengi
            Container(color: headerColor),

            // Dalga Efekti
            Positioned(
              bottom: -1,
              left: 0,
              right: 0,
              child: SizedBox(
                height: isShortScreen ? 30 : 60,
                child: CustomPaint(
                  painter: ConstantWavePainter(
                    color: theme.colorScheme.surface,
                  ),
                ),
              ),
            ),

            // İçerik (İkon ve Yazılar)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (icon != null && screenHeight > 100) ...[
                      Container(
                        padding: EdgeInsets.all(iconPadding),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(icon, size: iconSize, color: Colors.white),
                      ),
                      if (!isShortScreen) const SizedBox(height: 16),
                    ] else if (icon != null) ...[
                      const SizedBox(height: 10),
                    ],
                    Text(
                      title,
                      style:
                          (isShortScreen
                                  ? theme.textTheme.titleLarge
                                  : theme.textTheme.headlineMedium)
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                    ),
                    if (!isShortScreen) ...[
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
