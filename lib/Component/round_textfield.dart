import 'package:flutter/material.dart';
import 'package:video_gen_app/Utils/app_colors.dart';

class RoundTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextInputType inputType;
  final FocusNode? focusNode;
  final IconData? prefixIcon;
  final void Function(String)? onFieldSubmitted;
  final bool? isPasswordField;
  final TextEditingController textEditingController;
  final String? validatorValue;
  final Function(String)? onChange;
  final double? borderRadius;
  final Color? bgColor;
  final Color? errorBorderColor;
  final Color? focusedBorderColor;
  final Color? enabledBorderColor;

  const RoundTextField({
    super.key,
    required this.label,
    this.hint,
    required this.inputType,
    this.prefixIcon,
    required this.textEditingController,
    this.isPasswordField,
    this.onFieldSubmitted,
    this.focusNode,
    this.validatorValue,
    this.onChange,
    this.borderRadius,
    this.bgColor,
    this.errorBorderColor,
    this.focusedBorderColor,
    this.enabledBorderColor,
  });

  @override
  State<RoundTextField> createState() => _RoundTextFieldState();
}

class _RoundTextFieldState extends State<RoundTextField> {
  ValueNotifier<bool> passwordVisiblity = ValueNotifier<bool>(true);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ValueListenableBuilder(
        valueListenable: passwordVisiblity,
        builder: (context, value, child) {
          return TextFormField(
            onChanged: widget.onChange,
            validator: (value) {
              if (value!.isEmpty) {
                return widget.validatorValue;
              }
              return null;
            },
            onFieldSubmitted: widget.onFieldSubmitted,
            controller: widget.textEditingController,
            keyboardType: widget.inputType,
            focusNode: widget.focusNode,
            obscureText:
                widget.isPasswordField == true && passwordVisiblity.value,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: widget.bgColor ?? AppColors.whiteColor,
              floatingLabelBehavior: FloatingLabelBehavior.always,
              hintText: widget.hint,
              hintStyle: const TextStyle(color: Color(0xff8eaa8e)),
              prefixIcon: widget.prefixIcon != null
                  ? Icon(widget.prefixIcon)
                  : null,
              suffixIcon: widget.isPasswordField == true
                  ? IconButton(
                      onPressed: () {
                        passwordVisiblity.value = !passwordVisiblity.value;
                      },
                      icon: Icon(
                        passwordVisiblity.value
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                    )
                  : null,
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: widget.enabledBorderColor ?? Colors.grey,
                  width: 1,
                ),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: widget.focusedBorderColor ?? AppColors.whiteColor,
                  width: 1,
                ),
              ),
              errorBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: widget.errorBorderColor ?? Colors.redAccent,
                  width: 1,
                ),
              ),
              focusedErrorBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: widget.errorBorderColor ?? Colors.redAccent,
                  width: 1,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
