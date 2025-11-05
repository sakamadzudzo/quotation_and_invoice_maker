import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OrientationSupport extends StatefulWidget {
  final Widget child;
  final List<DeviceOrientation> supportedOrientations;
  final bool allowRotation;

  const OrientationSupport({
    super.key,
    required this.child,
    this.supportedOrientations = const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ],
    this.allowRotation = false,
  });

  @override
  State<OrientationSupport> createState() => _OrientationSupportState();
}

class _OrientationSupportState extends State<OrientationSupport>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setOrientation();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _setOrientation();
  }

  void _setOrientation() {
    if (widget.allowRotation) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setPreferredOrientations(widget.supportedOrientations);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            size: orientation == Orientation.landscape
                ? Size(
                    MediaQuery.of(context).size.height,
                    MediaQuery.of(context).size.width,
                  )
                : MediaQuery.of(context).size,
          ),
          child: widget.child,
        );
      },
    );
  }
}

class ResponsiveLayout extends StatelessWidget {
  final Widget mobileLayout;
  final Widget? tabletLayout;
  final Widget? desktopLayout;
  final double mobileBreakpoint;
  final double tabletBreakpoint;

  const ResponsiveLayout({
    super.key,
    required this.mobileLayout,
    this.tabletLayout,
    this.desktopLayout,
    this.mobileBreakpoint = 600,
    this.tabletBreakpoint = 1200,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        if (width >= tabletBreakpoint && desktopLayout != null) {
          return desktopLayout!;
        } else if (width >= mobileBreakpoint && tabletLayout != null) {
          return tabletLayout!;
        } else {
          return mobileLayout;
        }
      },
    );
  }
}

class AdaptiveScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget? body;
  final Widget? drawer;
  final Widget? endDrawer;
  final Widget? bottomNavigationBar;
  final Widget? bottomSheet;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final List<Widget>? persistentFooterButtons;
  final bool extendBody;
  final bool extendBodyBehindAppBar;
  final Color? backgroundColor;
  final bool? resizeToAvoidBottomInset;
  final bool primary;
  final dynamic drawerDragStartBehavior;
  final double? drawerEdgeDragWidth;
  final bool drawerEnableOpenDragGesture;
  final bool endDrawerEnableOpenDragGesture;
  final String? restorationId;

  const AdaptiveScaffold({
    super.key,
    this.appBar,
    this.body,
    this.drawer,
    this.endDrawer,
    this.bottomNavigationBar,
    this.bottomSheet,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.persistentFooterButtons,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.backgroundColor,
    this.resizeToAvoidBottomInset,
    this.primary = true,
    this.drawerDragStartBehavior,
    this.drawerEdgeDragWidth,
    this.drawerEnableOpenDragGesture = true,
    this.endDrawerEnableOpenDragGesture = true,
    this.restorationId,
  });

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final size = MediaQuery.of(context).size;

    // Adjust layout based on orientation and screen size
    final isLandscape = orientation == Orientation.landscape;
    final isLargeScreen = size.width > 600;

    return Scaffold(
      appBar: appBar,
      body: SafeArea(
        child: isLandscape && isLargeScreen
            ? Row(
                children: [
                  if (drawer != null) ...[
                    SizedBox(
                      width: 280,
                      child: drawer,
                    ),
                    const VerticalDivider(width: 1),
                  ],
                  Expanded(child: body ?? const SizedBox.shrink()),
                ],
              )
            : body ?? const SizedBox.shrink(),
      ),
      drawer: isLandscape && isLargeScreen ? null : drawer,
      endDrawer: endDrawer,
      bottomNavigationBar: bottomNavigationBar,
      bottomSheet: bottomSheet,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      persistentFooterButtons: persistentFooterButtons,
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      primary: primary,
      drawerDragStartBehavior: drawerDragStartBehavior,
      drawerEdgeDragWidth: drawerEdgeDragWidth,
      drawerEnableOpenDragGesture: drawerEnableOpenDragGesture,
      endDrawerEnableOpenDragGesture: endDrawerEnableOpenDragGesture,
      restorationId: restorationId,
    );
  }
}

class OrientationAwareWidget extends StatelessWidget {
  final Widget portraitWidget;
  final Widget? landscapeWidget;

  const OrientationAwareWidget({
    super.key,
    required this.portraitWidget,
    this.landscapeWidget,
  });

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;

    if (orientation == Orientation.landscape && landscapeWidget != null) {
      return landscapeWidget!;
    }

    return portraitWidget;
  }
}

class ScreenSizeAwareWidget extends StatelessWidget {
  final Widget smallWidget;
  final Widget? mediumWidget;
  final Widget? largeWidget;
  final double smallBreakpoint;
  final double mediumBreakpoint;

  const ScreenSizeAwareWidget({
    super.key,
    required this.smallWidget,
    this.mediumWidget,
    this.largeWidget,
    this.smallBreakpoint = 360,
    this.mediumBreakpoint = 600,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width >= mediumBreakpoint && largeWidget != null) {
      return largeWidget!;
    } else if (width >= smallBreakpoint && mediumWidget != null) {
      return mediumWidget!;
    } else {
      return smallWidget;
    }
  }
}