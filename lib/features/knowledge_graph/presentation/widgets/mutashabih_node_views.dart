import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The two node skins of the Mutashabihat graph.
///
/// Colours are fixed rather than themed (olive for the ayah you opened, beige
/// for everything that resembles it) because the graph is a diagram: the colour
/// *is* the legend, and a themed node would change meaning with the app theme.
/// Both combinations are checked for contrast (olive/off-white ≈ 6.5:1,
/// beige/ink ≈ 9:1) so night mode keeps them readable.
const Color kMutashabihSourceColor = Color(0xFF4A5D23);
const Color kMutashabihTargetColor = Color(0xFFD4C8B1);
const Color kOnMutashabihSource = Color(0xFFF6F4EC);
const Color kOnMutashabihTarget = Color(0xFF2B2B24);

/// The ayah the graph was opened on: larger, olive, the anchor of the diagram.
class MutashabihSourceNodeView extends StatelessWidget {
  const MutashabihSourceNodeView({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final double diameter = 96.w;
    return Semantics(
      label: label,
      button: false,
      child: Container(
        width: diameter,
        height: diameter,
        padding: EdgeInsets.all(10.w),
        decoration: const BoxDecoration(
          color: kMutashabihSourceColor,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(
              color: kOnMutashabihSource,
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
        ),
      ),
    );
  }
}

/// One similar ayah: smaller, beige, tappable.
class MutashabihTargetNodeView extends StatelessWidget {
  const MutashabihTargetNodeView({
    super.key,
    required this.label,
    required this.onTap,
    this.diameter = 66,
    this.highlighted = false,
  });

  final String label;
  final VoidCallback onTap;

  /// Screen-relative diameter before screenutil scaling; the graph shrinks the
  /// nodes as the fan-out grows so a 30-target diagram can still separate.
  final double diameter;

  /// Set while the bottom sheet for this node is open, so the diagram shows
  /// which node the text below belongs to.
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final double scale = diameter.w;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Semantics(
        label: label,
        button: true,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: scale,
          height: scale,
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: kMutashabihTargetColor,
            shape: BoxShape.circle,
            border: highlighted
                ? Border.all(color: kMutashabihSourceColor, width: 2.5.w)
                : null,
          ),
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                color: kOnMutashabihTarget,
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
