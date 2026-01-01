import 'package:flutter/material.dart';
import '../../../../app/theme.dart';
import '../../../../core/config/app_config.dart';

/// Attribute display card
class AttributeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isWarning;
  final bool isError;
  final VoidCallback? onTap;

  const AttributeCard({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
    this.isWarning = false,
    this.isError = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color iconColor = AuraTheme.primaryPurple;
    Color? backgroundColor;
    Color? borderColor;

    if (isError) {
      iconColor = AuraTheme.errorRed;
      backgroundColor = AuraTheme.errorRedLight.withOpacity(0.1);
      borderColor = AuraTheme.errorRed;
    } else if (isWarning) {
      iconColor = AuraTheme.warningOrange;
      backgroundColor = AuraTheme.warningOrangeLight.withOpacity(0.1);
      borderColor = AuraTheme.warningOrange;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isWarning || isError ? 2 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConfig.borderRadiusDefault),
        side: borderColor != null
            ? BorderSide(color: borderColor, width: 1)
            : BorderSide.none,
      ),
      color: backgroundColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConfig.borderRadiusDefault),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConfig.borderRadiusSmall),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 24,
                ),
              ),

              const SizedBox(width: 16),

              // Label and Value
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AuraTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),

              // Trailing icon for warnings/errors
              if (isWarning || isError)
                Icon(
                  isError ? Icons.error : Icons.warning,
                  color: iconColor,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Expandable attribute card for detailed information
class ExpandableAttributeCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final String value;
  final List<Widget> details;

  const ExpandableAttributeCard({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
    required this.details,
  }) : super(key: key);

  @override
  State<ExpandableAttributeCard> createState() => _ExpandableAttributeCardState();
}

class _ExpandableAttributeCardState extends State<ExpandableAttributeCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConfig.borderRadiusDefault),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(AppConfig.borderRadiusDefault),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AuraTheme.primaryPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppConfig.borderRadiusSmall),
                    ),
                    child: Icon(
                      widget.icon,
                      color: AuraTheme.primaryPurple,
                      size: 24,
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Label and Value
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.label,
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: AuraTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.value,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  ),

                  // Expand/collapse icon
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AuraTheme.textSecondary,
                  ),
                ],
              ),
            ),
          ),

          // Expandable details
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: 16,
              ),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AuraTheme.backgroundLight,
                  borderRadius: BorderRadius.circular(AppConfig.borderRadiusSmall),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: widget.details,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Simple key-value pair display
class AttributeDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const AttributeDetailRow({
    Key? key,
    required this.label,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
