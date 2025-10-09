import 'package:flutter/material.dart';
import 'package:video_gen_app/Utils/app_colors.dart';

class RoundButton extends StatefulWidget {
  final String title;
  final bool loading;
  final VoidCallback onPress;
  final Color? bgColor;
  final Color? titleColor;
  final Color? leadingIconColor;
  final Color foregroundColor;
  final FocusNode? focusNode;
  final String? fontFamily;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double? fontSize;
  final IconData? leadingIcon;

  const RoundButton({
    super.key,
    required this.title,
    required this.onPress,
    this.loading = false,
    this.foregroundColor = AppColors.whiteColor,
    this.titleColor,
    this.bgColor,
    this.focusNode,
    this.fontFamily,
    this.borderRadius = 10.0,
    this.fontSize,
    this.padding = const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
    this.leadingIcon,
    this.leadingIconColor,
  });

  @override
  State<RoundButton> createState() => _RoundButtonState();
}

class _RoundButtonState extends State<RoundButton> {
  @override
  Widget build(BuildContext context) {
    return widget.loading
        ? const Center(
            child: CircularProgressIndicator(color: AppColors.whiteColor),
          )
        : Container(
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(widget.borderRadius),
              color: widget.bgColor ?? AppColors.purpleColor,
            ),
            child: ElevatedButton(
              focusNode: widget.focusNode,
              onPressed: widget.onPress,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                ),
              ),
              child: Padding(
                padding: widget.padding,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.leadingIcon != null) ...[
                      Icon(
                        widget.leadingIcon,
                        size: 26,
                        color: widget.leadingIconColor ?? AppColors.purpleColor,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        widget.title,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: widget.fontSize ?? 25,
                          color: widget.titleColor ?? AppColors.whiteColor,
                          fontFamily: widget.fontFamily ?? "Eurostile",
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
  }
}
