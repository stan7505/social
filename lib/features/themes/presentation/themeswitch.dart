import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/theme_cubit.dart';

class Themeswitch extends StatefulWidget {
  const Themeswitch({super.key});

  @override
  State<Themeswitch> createState() => _ThemeswitchState();
}

class _ThemeswitchState extends State<Themeswitch> with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setInitialTheme();
  }

  @override
  void didChangePlatformBrightness() {
    final brightness = WidgetsBinding.instance.window.platformBrightness;
    context.read<ThemeCubit>().setThemeBasedOnSystemBrightness(brightness);
    setState(() {}); // Rebuild the widget to apply the new theme
  }

  @override
  void _setInitialTheme() {
    final brightness = WidgetsBinding.instance.window.platformBrightness;
    context.read<ThemeCubit>().setThemeBasedOnSystemBrightness(brightness);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeData>(
      builder: (context, theme) {
        return CupertinoSwitch(
          value: theme.brightness == Brightness.dark,
          onChanged: (value) {
            context.read<ThemeCubit>().toggleTheme();
          },
        );
      },
    );
  }
}
