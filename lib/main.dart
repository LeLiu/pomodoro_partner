import 'package:flutter/foundation.dart';

import 'package:provider/provider.dart';
import 'package:system_theme/system_theme.dart';
import 'package:fluent_ui/fluent_ui.dart'; // hide Page
import 'package:flutter_acrylic/flutter_acrylic.dart'
    as flutter_acrylic; // TODO remove arcylic.
import 'package:go_router/go_router.dart';
import 'package:window_manager/window_manager.dart';

import './app/theme.dart';
import './screens/settings.dart';
import './screens/list.dart';
import './screens/focus.dart';

import './utils/logger.dart';
import './features/list.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppLogger.initialize(level: Level.all);
  TaskListManager.initialize();

  // if it's not on the web, windows or android, load the accent color
  if (!kIsWeb &&
      [
        TargetPlatform.windows,
        TargetPlatform.android,
      ].contains(defaultTargetPlatform)) {
    SystemTheme.accentColor.load();
  }

  if (isDesktop) {
    await flutter_acrylic.Window.initialize();
    if (defaultTargetPlatform == TargetPlatform.windows) {
      await flutter_acrylic.Window.hideWindowControls();
    }
    await WindowManager.instance.ensureInitialized();
    windowManager.waitUntilReadyToShow().then((_) async {
      await windowManager.setTitleBarStyle(
        TitleBarStyle.hidden,
        windowButtonVisibility: false,
      );
      await windowManager.setMinimumSize(const Size(500, 600));
      await windowManager.show();
      await windowManager.setPreventClose(true);
      await windowManager.setSkipTaskbar(false);
    });
  }
  runApp(const PomodoroPartnerApp());

  // Future.wait([
  //   DeferredWidget.preload(popups.loadLibrary),
  //   DeferredWidget.preload(forms.loadLibrary),
  //   DeferredWidget.preload(inputs.loadLibrary),
  //   DeferredWidget.preload(navigation.loadLibrary),
  //   DeferredWidget.preload(surfaces.loadLibrary),
  //   DeferredWidget.preload(theming.loadLibrary),
  // ]);
}

bool get isDesktop {
  if (kIsWeb) return false;
  return [
    TargetPlatform.windows,
    TargetPlatform.linux,
    TargetPlatform.macOS,
  ].contains(defaultTargetPlatform);
}

const appTitle = '番茄拍档';
final _appTheme = AppTheme();

class PomodoroPartnerApp extends StatelessWidget {
  const PomodoroPartnerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _appTheme,
      builder: (context, child) {
        final appTheme = context.watch<AppTheme>();
        return FluentApp.router(
          title: appTitle,
          themeMode: appTheme.mode,
          debugShowCheckedModeBanner: false,
          color: appTheme.color,
          darkTheme: FluentThemeData(
            brightness: Brightness.dark,
            accentColor: appTheme.color,
            visualDensity: VisualDensity.standard,
            focusTheme: FocusThemeData(
              glowFactor: is10footScreen(context) ? 2.0 : 0.0,
            ),
          ),
          theme: FluentThemeData(
            accentColor: appTheme.color,
            visualDensity: VisualDensity.standard,
            focusTheme: FocusThemeData(
              glowFactor: is10footScreen(context) ? 2.0 : 0.0,
            ),
          ),
          locale: appTheme.locale,
          builder: (context, child) {
            return Directionality(
              textDirection: appTheme.textDirection,
              child: NavigationPaneTheme(
                data: NavigationPaneThemeData(
                  backgroundColor:
                      appTheme.windowEffect !=
                          flutter_acrylic.WindowEffect.disabled
                      ? Colors.transparent
                      : null,
                ),
                child: child!,
              ),
            );
          },
          routeInformationParser: router.routeInformationParser,
          routerDelegate: router.routerDelegate,
          routeInformationProvider: router.routeInformationProvider,
        );
      },
    );
  }
}

class AppHomePage extends StatefulWidget {
  const AppHomePage({
    super.key,
    required this.child,
    required this.shellContext,
  });

  final Widget child;
  final BuildContext? shellContext;

  @override
  State<AppHomePage> createState() => _AppHomePageState();
}

final _navigationViewKey = GlobalKey(debugLabel: 'Navigation View Key');

class _AppHomePageState extends State<AppHomePage> with WindowListener {
  late final naviItems =
      <NavigationPaneItem>[
        PaneItem(
          key: const ValueKey('/list'),
          icon: const Icon(FluentIcons.task_list),
          title: const Text('清单'),
          body: const SizedBox.shrink(),
        ),
        PaneItem(
          key: const ValueKey('/focus'),
          icon: const Icon(FluentIcons.timer),
          title: const Text('专注'),
          body: const SizedBox.shrink(),
        ),
        PaneItem(
          key: const ValueKey('/statistics'),
          icon: const Icon(FluentIcons.summary_chart),
          title: const Text('统计'),
          body: const SizedBox.shrink(),
        ),
      ].map<NavigationPaneItem>((item) {
        item as PaneItem;
        return PaneItem(
          key: item.key,
          icon: item.icon,
          title: item.title,
          body: item.body,
          onTap: () {
            final path = (item.key as ValueKey).value;
            if (GoRouterState.of(context).uri.toString() != path) {
              context.go(path);
            }
            item.onTap?.call();
          },
        );
      }).toList();

  late final footerItems = <NavigationPaneItem>[
    PaneItemSeparator(),
    PaneItem(
      key: const ValueKey('/settings'),
      icon: const Icon(FluentIcons.settings),
      title: const Text('Settings'),
      body: const SizedBox.shrink(),
      onTap: () {
        if (GoRouterState.of(context).uri.toString() != '/settings') {
          context.go('/settings');
        }
      },
    ),
  ];

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final localizations = FluentLocalizations.of(context);

    final appTheme = context.watch<AppTheme>();
    final theme = FluentTheme.of(context);
    if (widget.shellContext != null) {
      if (router.canPop() == false) {
        setState(() {});
      }
    }

    return NavigationView(
      key: _navigationViewKey,
      appBar: NavigationAppBar(
        automaticallyImplyLeading: false,
        height: 30,
        //leading: _buidAppTitle(context),
        title: _buidAppTitle(context),
        actions: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(end: 8.0),
                child: ToggleSwitch(
                  content: const Text('Dark Mode'),
                  checked: FluentTheme.of(context).brightness.isDark,
                  onChanged: (v) {
                    if (v) {
                      appTheme.mode = ThemeMode.dark;
                    } else {
                      appTheme.mode = ThemeMode.light;
                    }
                  },
                ),
              ),
            ),
            if (!kIsWeb) const WindowButtons(),
          ],
        ),
      ),
      paneBodyBuilder: (item, child) {
        final name = item?.key is ValueKey
            ? (item!.key as ValueKey).value
            : null;
        return FocusTraversalGroup(
          key: ValueKey('body$name'),
          child: widget.child,
        );
      },
      pane: NavigationPane(
        selected: _calculateSelectedIndex(context),
        size: const NavigationPaneSize(openWidth: 200.0),
        // header: SizedBox(
        //   //height: kOneLineTileHeight,
        //   height: 50,
        //   child: ShaderMask(
        //     shaderCallback: (rect) {
        //       final color = appTheme.color.defaultBrushFor(theme.brightness);
        //       return LinearGradient(colors: [color, color]).createShader(rect);
        //     },
        //     child: const FlutterLogo(
        //       style: FlutterLogoStyle.horizontal,
        //       size: 100.0,
        //       textColor: Colors.white,
        //       duration: Duration.zero,
        //     ),
        //   ),
        // ),
        displayMode: appTheme.displayMode,
        indicator: () {
          switch (appTheme.indicator) {
            case NavigationIndicators.end:
              return const EndNavigationIndicator();
            case NavigationIndicators.sticky:
              return const StickyNavigationIndicator();
          }
        }(),
        items: naviItems,
        footerItems: footerItems,
      ),
    );
  }

  @override
  void onWindowClose() async {
    bool isPreventClose = await windowManager.isPreventClose();
    if (isPreventClose && mounted) {
      showDialog(
        context: context,
        builder: (_) {
          return ContentDialog(
            title: const Text('退出确认'),
            content: const Text('您确定要关闭窗口并退出应用程序?'),
            actions: [
              FilledButton(
                child: const Text('确认'),
                onPressed: () {
                  Navigator.pop(context);
                  windowManager.destroy();
                },
              ),
              Button(
                child: const Text('取消'),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          );
        },
      );
    }
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    int indexNavi = naviItems
        .where((item) => item.key != null)
        .toList()
        .indexWhere((item) => item.key == Key(location));

    if (indexNavi == -1) {
      int indexFooter = footerItems
          .where((element) => element.key != null)
          .toList()
          .indexWhere((element) => element.key == Key(location));
      if (indexFooter == -1) {
        return 0;
      }
      return naviItems.where((element) => element.key != null).toList().length +
          indexFooter;
    } else {
      return indexNavi;
    }
  }

  Widget _buidAppTitle(BuildContext context) {
    final title = Align(
      alignment: AlignmentDirectional.centerStart,
      child: Row(children: [Image.asset('assets/logo.png', width: 20, height: 20), SizedBox(width: 8.0), Text(appTitle, style: TextStyle(fontSize: 14))]),
    );
    if (kIsWeb) {
      return title;
    }
    return DragToMoveArea(child: title);
  }
}

class WindowButtons extends StatelessWidget {
  const WindowButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final FluentThemeData theme = FluentTheme.of(context);

    return SizedBox(
      width: 138,
      height: 30,
      child: WindowCaption(
        brightness: theme.brightness,
        backgroundColor: Colors.transparent,
      ),
    );
  }
}

final rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();
final router = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/list',
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return AppHomePage(
          shellContext: _shellNavigatorKey.currentContext,
          child: child,
        );
      },
      routes: <GoRoute>[
        GoRoute(
          path: '/list',
          builder: (context, state) => const ListScreen(),
        ),
        GoRoute(
          path: '/focus',
          builder: (context, state) => const FocusScreen(),
        ),
        GoRoute(
          path: '/statistics',
          builder: (context, state) => const SettingsScreen(),
        ),

        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
  ],
);
