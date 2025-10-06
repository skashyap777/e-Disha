import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppInput extends StatelessWidget {
  final String hintText;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final FocusNode? focusNode;
  final String? labelText;
  final String? label;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final void Function(String)? onChanged;

  const AppInput({
    super.key,
    required this.hintText,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.focusNode,
    this.labelText,
    this.label,
    this.maxLength,
    this.inputFormatters,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        labelText: labelText ?? label,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        counterText: maxLength != null ? '' : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
    );
  }
}
