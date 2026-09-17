import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_core_project/core/configs/app_config.dart';
import 'package:flutter_core_project/core/configs/theme/app_colors.dart';
import 'package:flutter_core_project/presentation/choose_mode/bloc/locale_cubit.dart';
import 'package:flutter_core_project/presentation/choose_mode/bloc/theme_cubit.dart';
import 'package:flutter_core_project/services/localization_service.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 12),
              sliver: SliverToBoxAdapter(
                child: Text(
                  context.tr('profile_title'),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),
            const SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 22),
              sliver: SliverToBoxAdapter(child: _ProfileHeader()),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 10),
              sliver: SliverToBoxAdapter(
                child: Text(
                  context.tr('preferences'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),
            const SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 22),
              sliver: SliverToBoxAdapter(child: _PreferencesCard()),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 10),
              sliver: SliverToBoxAdapter(
                child: Text(
                  context.tr('about'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),
            const SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 22),
              sliver: SliverToBoxAdapter(child: _AboutCard()),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 150)),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.linearShapeFor(context);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: AppColors.settingRowGradientFor(context),
      ),
      child: Row(
        children: [
          Container(
            width: 82,
            height: 82,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.13),
                  blurRadius: 18,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Image.asset('assets/images/app_logo.png'),
          ),
          const SizedBox(width: 17),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('profile_name'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 5),
                Text(
                  context.tr('profile_description'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        height: 1.45,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PreferencesCard extends StatelessWidget {
  const _PreferencesCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          _SettingRowSurface(
            child: BlocBuilder<ThemeCubit, ThemeMode>(
              builder: (context, mode) {
                final isDark = mode == ThemeMode.dark;
                return Material(
                  type: MaterialType.transparency,
                  child: SwitchListTile.adaptive(
                    key: const Key('themeSwitch'),
                    value: isDark,
                    onChanged: (_) => context.read<ThemeCubit>().toggleTheme(),
                    activeThumbColor: AppColors.linearShapeFor(context),
                    secondary: _SettingIcon(
                      icon: isDark
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                    ),
                    title: Text(context.tr('theme')),
                    subtitle: Text(
                      context.tr(isDark ? 'dark_mode' : 'light_mode'),
                    ),
                  ),
                );
              },
            ),
          ),
          Divider(height: 1, indent: 72, color: Theme.of(context).dividerColor),
          _SettingRowSurface(
            child: BlocBuilder<LocaleCubit, Locale>(
              builder: (context, locale) {
                final isVietnamese = locale.languageCode == 'vi';
                return Material(
                  type: MaterialType.transparency,
                  child: SwitchListTile.adaptive(
                    key: const Key('languageSwitch'),
                    value: isVietnamese,
                    onChanged: (_) =>
                        context.read<LocaleCubit>().toggleLanguage(),
                    activeThumbColor: AppColors.linearShapeFor(context),
                    secondary: const _SettingIcon(icon: Icons.language_rounded),
                    title: Text(context.tr('language')),
                    subtitle: Text(
                      context.tr(isVietnamese ? 'vietnamese' : 'english'),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingRowSurface extends StatelessWidget {
  const _SettingRowSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppColors.settingRowGradientFor(context),
      ),
      child: child,
    );
  }
}

class _SettingIcon extends StatelessWidget {
  const _SettingIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.linearShapeFor(context);
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, color: accent, size: 22),
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.settingRowGradientFor(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          const _SettingIcon(icon: Icons.info_outline_rounded),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppConfig.appTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${context.tr('version')} ${AppConfig.versionLabel}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
