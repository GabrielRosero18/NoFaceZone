import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:nofacezone/src/Custom/AppColors.dart';
import 'package:nofacezone/src/Custom/AppLocalizations.dart';
import 'package:nofacezone/src/Custom/AuthTheme.dart';
import 'package:nofacezone/src/Custom/AuthWidgets.dart';
import 'package:nofacezone/src/Custom/Library.dart';
import 'package:nofacezone/src/Custom/ProAnimations.dart';
import 'package:nofacezone/src/Custom/TimeLimitSlider.dart';
import 'package:nofacezone/src/Providers/AppProvider.dart';
import 'package:nofacezone/src/Providers/UserProvider.dart';
import 'package:nofacezone/src/Services/PreferencesService.dart';

/// Primera vez tras crear cuenta o iniciar sesión en un dispositivo nuevo (por auth user id).
class FirstTimeSetupScreen extends StatefulWidget {
  const FirstTimeSetupScreen({super.key});

  @override
  State<FirstTimeSetupScreen> createState() => _FirstTimeSetupScreenState();
}

class _FirstTimeSetupScreenState extends State<FirstTimeSetupScreen> {
  bool _ready = false;
  bool _saving = false;
  late double _dailyTenMinBlocks;
  late int _weeklyHours;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrapFromProvider());
  }

  void _bootstrapFromProvider() {
    final app = Provider.of<AppProvider>(context, listen: false);
    final daily = app.dailyUsageLimit;
    final blocks = (daily / 10.0).round().clamp(1, 144).toDouble();
    setState(() {
      _dailyTenMinBlocks = blocks;
      _weeklyHours = app.weeklyGoal.clamp(1, 168);
      _ready = true;
    });
  }

  String _formatDailyPreview(AppLocalizations loc, double tenMinBlocks) {
    final totalMinutes = (tenMinBlocks * 10).round();
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours == 0) {
      return '$minutes ${loc.minutesShort}';
    }
    if (minutes == 0) {
      return '$hours ${loc.hoursShort}';
    }
    return '$hours ${loc.hoursShort} ${loc.timeConnector} $minutes ${loc.minutesShort}';
  }

  Future<void> _submit() async {
    if (_saving) return;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final authId = userProvider.token;
    if (authId == null || authId.isEmpty) {
      if (mounted) Navigator.of(context).maybePop();
      return;
    }

    setState(() => _saving = true);
    HapticFeedback.mediumImpact();

    try {
      final app = Provider.of<AppProvider>(context, listen: false);
      final dailyMinutes = (_dailyTenMinBlocks * 10).round();
      await app.setDailyUsageLimit(dailyMinutes);
      await app.setWeeklyGoal(_weeklyHours);
      await PreferencesService.setInitialSetupCompletedForAuthUser(authId);
      await app.refreshUsageLimits();
      if (!mounted) return;
      navigate(context, CustomScreen.home, finishCurrent: true);
    } catch (e, st) {
      debugPrint('FirstTimeSetupScreen._submit: $e\n$st');
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    AppColors.setTheme(appProvider.colorTheme);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: AuthTheme.backgroundDecoration(),
        child: Stack(
          children: [
            ...AuthTheme.buildBackgroundOrbs(),
            SafeArea(
              child: !_ready
                  ? const Center(child: CircularProgressIndicator())
                  : ProEntrance(
                      delayMs: 80,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AuthHeaderChip(
                              icon: Icons.flag_rounded,
                              text: loc.firstSetupTitle,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              loc.firstSetupTitle,
                              style: const TextStyle(
                                color: AppColors.textLight,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              loc.firstSetupSubtitle,
                              style: TextStyle(
                                color: AppColors.textLight.withValues(alpha: 0.82),
                                fontSize: 15,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 28),
                            AuthGlassCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    loc.firstSetupDailyHeading,
                                    style: const TextStyle(
                                      color: AppColors.textLight,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${loc.dailyLimitTitle}: ${_formatDailyPreview(loc, _dailyTenMinBlocks)}',
                                    style: TextStyle(
                                      color: AppColors.textLight.withValues(alpha: 0.88),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  TimeLimitSlider(
                                    value: _dailyTenMinBlocks,
                                    minValue: 1,
                                    maxValue: 144,
                                    divisions: 143,
                                    leftLabel: loc.workLimitLabel,
                                    rightLabel: loc.personalLimitLabel,
                                    onChanged: (v) {
                                      setState(() {
                                        _dailyTenMinBlocks = v.roundToDouble();
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                            AuthGlassCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    loc.firstSetupWeeklyHeading,
                                    style: const TextStyle(
                                      color: AppColors.textLight,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${loc.weeklyGoalTitle}: $_weeklyHours ${loc.hoursShort}',
                                    style: TextStyle(
                                      color: AppColors.textLight.withValues(alpha: 0.88),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  TimeLimitSlider(
                                    value: _weeklyHours.toDouble(),
                                    minValue: 1,
                                    maxValue: 168,
                                    divisions: 167,
                                    leftLabel: loc.workLimitLabel,
                                    rightLabel: loc.personalLimitLabel,
                                    onChanged: (v) {
                                      setState(() {
                                        _weeklyHours = v.round();
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 28),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: _saving ? null : _submit,
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  backgroundColor: AppColors.accentBlue,
                                  foregroundColor: AppColors.textLight,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: Text(
                                  _saving ? loc.firstSetupSaving : loc.firstSetupContinue,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
