import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class KeyboardHandler extends StatefulWidget {
  final Widget child;
  final bool autoScroll;
  final EdgeInsets padding;
  final Duration animationDuration;

  const KeyboardHandler({
    super.key,
    required this.child,
    this.autoScroll = true,
    this.padding = const EdgeInsets.all(16.0),
    this.animationDuration = const Duration(milliseconds: 300),
  });

  @override
  State<KeyboardHandler> createState() => _KeyboardHandlerState();
}

class _KeyboardHandlerState extends State<KeyboardHandler>
    with WidgetsBindingObserver {
  final FocusNode _focusNode = FocusNode();
  double _keyboardHeight = 0.0;
  bool _keyboardVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    final bottomInset = WidgetsBinding.instance.window.viewInsets.bottom;
    final newKeyboardHeight = bottomInset / WidgetsBinding.instance.window.devicePixelRatio;

    if (mounted) {
      setState(() {
        _keyboardHeight = newKeyboardHeight;
        _keyboardVisible = newKeyboardHeight > 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping outside
        FocusScope.of(context).unfocus();
      },
      child: AnimatedPadding(
        duration: widget.animationDuration,
        padding: EdgeInsets.only(bottom: _keyboardHeight),
        child: SingleChildScrollView(
          physics: widget.autoScroll ? const ClampingScrollPhysics() : null,
          child: Padding(
            padding: widget.padding,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class SmartTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final bool autofocus;
  final FocusNode? focusNode;
  final bool autoNextFocus;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;

  const SmartTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.keyboardType,
    this.inputFormatters,
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.validator,
    this.autofocus = false,
    this.focusNode,
    this.autoNextFocus = true,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction,
  });

  @override
  State<SmartTextField> createState() => _SmartTextFieldState();
}

class _SmartTextFieldState extends State<SmartTextField> {
  late FocusNode _focusNode;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _hasFocus = _focusNode.hasFocus;
    });
  }

  void _onSubmitted(String value) {
    if (widget.autoNextFocus) {
      _moveToNextField();
    }
    widget.onSubmitted?.call(value);
  }

  void _moveToNextField() {
    final currentNode = FocusScope.of(context);
    currentNode.nextFocus();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: EdgeInsets.only(bottom: _hasFocus ? 8.0 : 0.0),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        decoration: InputDecoration(
          labelText: widget.labelText,
          hintText: widget.hintText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(
              color: _hasFocus ? Theme.of(context).primaryColor : Colors.grey,
              width: _hasFocus ? 2.0 : 1.0,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(
              color: Theme.of(context).primaryColor,
              width: 2.0,
            ),
          ),
          filled: true,
          fillColor: _hasFocus
              ? Theme.of(context).primaryColor.withOpacity(0.05)
              : Colors.grey.withOpacity(0.05),
        ),
        keyboardType: widget.keyboardType,
        inputFormatters: widget.inputFormatters,
        obscureText: widget.obscureText,
        maxLines: widget.maxLines,
        minLines: widget.minLines,
        maxLength: widget.maxLength,
        onChanged: widget.onChanged,
        onEditingComplete: widget.onEditingComplete,
        onFieldSubmitted: _onSubmitted,
        validator: widget.validator,
        autofocus: widget.autofocus,
        textCapitalization: widget.textCapitalization,
        textInputAction: widget.textInputAction ?? (widget.autoNextFocus ? TextInputAction.next : TextInputAction.done),
      ),
    );
  }
}

class NumericInputFormatter extends TextInputFormatter {
  final int? maxIntegerDigits;
  final int? maxDecimalDigits;
  final bool allowNegative;

  NumericInputFormatter({
    this.maxIntegerDigits,
    this.maxDecimalDigits,
    this.allowNegative = true,
  });

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Allow negative sign at the beginning
    if (allowNegative && newValue.text == '-') {
      return newValue;
    }

    // Parse the number
    final number = double.tryParse(newValue.text);
    if (number == null) {
      return oldValue;
    }

    // Check integer digits limit
    if (maxIntegerDigits != null) {
      final integerPart = number.truncate().abs().toString().length;
      if (integerPart > maxIntegerDigits!) {
        return oldValue;
      }
    }

    // Check decimal digits limit
    if (maxDecimalDigits != null && newValue.text.contains('.')) {
      final decimalPart = newValue.text.split('.')[1];
      if (decimalPart.length > maxDecimalDigits!) {
        return oldValue;
      }
    }

    return newValue;
  }
}

class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'[^\d+]'), '');

    // Basic phone number formatting (adjust based on your needs)
    String formatted = text;
    if (text.length >= 10) {
      formatted = '${text.substring(0, 3)} ${text.substring(3, 6)} ${text.substring(6)}';
    } else if (text.length >= 6) {
      formatted = '${text.substring(0, 3)} ${text.substring(3)}';
    } else if (text.length >= 3) {
      formatted = '${text.substring(0, 3)}';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class KeyboardVisibilityBuilder extends StatefulWidget {
  final Widget Function(BuildContext context, bool isKeyboardVisible, double keyboardHeight) builder;

  const KeyboardVisibilityBuilder({super.key, required this.builder});

  @override
  State<KeyboardVisibilityBuilder> createState() => _KeyboardVisibilityBuilderState();
}

class _KeyboardVisibilityBuilderState extends State<KeyboardVisibilityBuilder>
    with WidgetsBindingObserver {
  double _keyboardHeight = 0.0;
  bool _isKeyboardVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    final bottomInset = WidgetsBinding.instance.window.viewInsets.bottom;
    final newKeyboardHeight = bottomInset / WidgetsBinding.instance.window.devicePixelRatio;

    if (mounted) {
      setState(() {
        _keyboardHeight = newKeyboardHeight;
        _isKeyboardVisible = newKeyboardHeight > 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _isKeyboardVisible, _keyboardHeight);
  }
}