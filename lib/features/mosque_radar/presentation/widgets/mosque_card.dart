import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:awan/core/constants/app_colors.dart';
import 'package:awan/core/utils/maps_launcher.dart';
import 'package:awan/features/mosque_radar/domain/entities/mosque_entity.dart';
import 'package:awan/l10n/app_localizations.dart';

/// One mosque, as a card the user can act on.
///
/// Shows the three things that decide whether they walk there: **how far**, **how
/// long on foot**, and **which way** (the "open in Maps" action hands the pin to
/// the phone's own maps app, which knows the roads — this app deliberately does
/// not try to route anyone itself).
///
/// `compact` is the Elderly Mode variant: bigger type, a full-width button, no
/// secondary metadata.
class MosqueCard extends StatelessWidget {
  const MosqueCard({
    super.key,
    required this.mosque,
    this.compact = false,
    this.onTap,
  });

  final MosqueEntity mosque;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final TextTheme text = Theme.of(context).textTheme;

    final String distance = mosque.distanceMeters >= 1000
        ? '${(mosque.distanceMeters / 1000).toStringAsFixed(1)} ${l10n.km}'
        : '${mosque.distanceMeters.round()} ${l10n.metersShort}';
    final String walk = l10n.walkingTime('${mosque.walkingMinutes} ${l10n.minutesShort}');

    return Card(
      margin: EdgeInsets.only(bottom: 10.h),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          child: Row(
            children: <Widget>[
              Container(
                width: compact ? 46.w : 38.w,
                height: compact ? 46.w : 38.w,
                decoration: BoxDecoration(
                  color: AppColors.radar.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.mosque,
                  color: AppColors.radar,
                  size: compact ? 26.sp : 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      mosque.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: (compact ? text.titleMedium : text.titleSmall)
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '$distance • $walk',
                      style: text.bodySmall,
                    ),
                    if (!compact && (mosque.address?.isNotEmpty ?? false)) ...<Widget>[
                      SizedBox(height: 2.h),
                      Text(
                        mosque.address!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withOpacity(0.8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              TextButton.icon(
                onPressed: () => MapsLauncher.navigate(
                  latitude: mosque.latitude,
                  longitude: mosque.longitude,
                  label: mosque.name,
                ),
                icon: Icon(Icons.directions_walk, size: 18.sp),
                label: Text(compact ? l10n.openInMaps : l10n.navigateShort),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
