import 'package:flutter/material.dart';

enum IconPosition { left, right }
enum AppButtonSize { small, medium, large, fullWidth }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final IconPosition iconPosition;
  final AppButtonSize size;
  final double? height;
  final String? semanticLabel;
  final String? tooltip;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.iconPosition = IconPosition.left,
    this.size = AppButtonSize.fullWidth,
    this.height,
    this.semanticLabel,
    this.tooltip,
  });

  double get _buttonWidth {
    switch (size) {
      case AppButtonSize.small:
        return 100;
      case AppButtonSize.medium:
        return 200;
      case AppButtonSize.large:
        return 300;
      case AppButtonSize.fullWidth:
        return double.infinity;
    }
  }

  @override
  Widget build(BuildContext context) {
    final button = SizedBox(
      width: _buttonWidth,
      height: height ?? 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
          foregroundColor: textColor ?? Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : icon != null
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: iconPosition == IconPosition.left
                        ? [
                            Icon(icon, color: textColor ?? Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              text,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ]
                        : [
                            Text(
                              text,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(icon, color: textColor ?? Colors.white),
                          ],
                  )
                : Text(
                    text,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip!,
        child: Semantics(
          label: semanticLabel ?? text,
          child: button,
        ),
      );
    }

    return Semantics(
      label: semanticLabel ?? text,
      child: button,
    );
  }
}