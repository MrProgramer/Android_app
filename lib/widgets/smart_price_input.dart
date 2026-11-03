import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/persian_number_formatter.dart';

class SmartPriceInput extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hintText;
  final String? helperText;
  final bool isRequired;
  final ValueChanged<double>? onChanged;

  const SmartPriceInput({
    super.key,
    required this.controller,
    required this.label,
    this.hintText,
    this.helperText,
    this.isRequired = false,
    this.onChanged,
  });

  @override
  State<SmartPriceInput> createState() => _SmartPriceInputState();
}

class _SmartPriceInputState extends State<SmartPriceInput> {
  String _words = '';

  @override
  void initState() {
    super.initState();
    _updateWords();
    widget.controller.addListener(_updateWords);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateWords);
    super.dispose();
  }

  void _updateWords() {
    final val = PersianFormatter.parseDouble(widget.controller.text);
    final wordsText = val > 0 ? PersianFormatter.numberToPersianWords(val) : '';
    if (wordsText != _words) {
      setState(() {
        _words = wordsText;
      });
      if (widget.onChanged != null) {
        widget.onChanged!(val);
      }
    }
  }

  void _addAmount(double delta) {
    final current = PersianFormatter.parseDouble(widget.controller.text);
    final next = (current + delta).clamp(0.0, 999999999999.0);
    widget.controller.text = PersianFormatter.formatPrice(next, includeUnit: false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: widget.isRequired ? '${widget.label} *' : widget.label,
            hintText: widget.hintText ?? 'مثلاً: ۴,۵۰۰',
            suffixText: 'تومان',
            suffixStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
          ),
          validator: widget.isRequired
              ? (v) => v == null || v.trim().isEmpty ? '${widget.label} الزامی است' : null
              : null,
        ),
        if (_words.isNotEmpty) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.primaryLight.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.record_voice_over_outlined, size: 13, color: AppColors.primaryDark),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _words,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        // Quick add buttons for commercial convenience
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildQuickButton('+۱۰۰ هزار', 100000),
              const SizedBox(width: 6),
              _buildQuickButton('+۵۰۰ هزار', 500000),
              const SizedBox(width: 6),
              _buildQuickButton('+۱ میلیون', 1000000),
              const SizedBox(width: 6),
              _buildQuickButton('+۵ میلیون', 5000000),
              const SizedBox(width: 6),
              _buildQuickButton('+۱۰ میلیون', 10000000),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickButton(String label, double delta) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () => _addAmount(delta),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDarkElevated : AppColors.borderLight.withOpacity(0.5),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          ),
        ),
      ),
    );
  }
}
