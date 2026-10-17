import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:awan/core/l10n/l10n.dart';
import 'package:awan/l10n/app_localizations.dart';

/// Honest placeholder for a feature the roadmap has not built yet.
///
/// The elderly dashboard offers a "Read the Quran" card because that is what an
/// older user reaches for first — but the Quran reader is a later step. Rather
/// than hide the card or, worse, navigate to a screen that silently shows
/// nothing, this screen states plainly that the feature arrives later.
class QuranPlaceholderScreen extends StatelessWidget {
  const QuranPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.quran)),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.menu_book_outlined,
                  size: 64.sp, color: theme.colorScheme.primary),
              SizedBox(height: 16.h),
              Text(l10n.quran, style: theme.textTheme.headlineSmall),
              SizedBox(height: 8.h),
              Text(
                l10n.moreFeatures,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
