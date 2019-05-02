import 'package:anchr_android/pages/about_page.dart';
import 'package:anchr_android/pages/add_link_page.dart';
import 'package:anchr_android/pages/collections_page.dart';
import 'package:anchr_android/pages/login_page.dart';
import 'package:anchr_android/pages/splash_page.dart';
import 'package:anchr_android/resources/strings.dart';
import 'package:anchr_android/state/anchr_actions.dart';
import 'package:anchr_android/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AnchrApp extends StatefulWidget {
  @override
  State<AnchrApp> createState() => _AnchrAppState(AppState.loading());
}

class _AnchrAppState extends AnchrState<AnchrApp> with AnchrActions {
  static const platform = const MethodChannel('app.channel.shared.data');

  Map<dynamic, dynamic> sharedData = Map();
  bool initialized = false;
  bool isLoggedIn = false;

  _AnchrAppState(AppState appState) : super(appState);

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() async {
    SystemChannels.lifecycle.setMessageHandler((msg) {
      if (msg.contains('resumed')) {
        _getSharedData().then((d) {
          if (d.isEmpty) return;
          Navigator.of(appState.currentContext).pushNamedAndRemoveUntil(
              AddLinkPage.routeName, (Route<dynamic> route) => route.settings.name != AddLinkPage.routeName,
              arguments: d);
        });
      }
    });

    onUnauthorizedCallback = _onUnauthorized;

    await initApp();
    var data = await _getSharedData();
    setState(() => sharedData = data);

    if (_isLoggedIn()) {
      try {
        await renewToken();
        setState(() => isLoggedIn = true);
      } catch (e) {
        setState(() => isLoggedIn = false);
      }
    }

    setState(() => initialized = true);
  }

  Future<Map> _getSharedData() async => await platform.invokeMethod('getSharedData');

  bool _isLoggedIn() {
    final userMail = preferences.getString(Strings.keyUserMailPref);
    final userToken = preferences.getString(Strings.keyUserTokenPref);
    return userMail != null && userToken != null;
  }

  _onUnauthorized() {
    logout();
    Navigator.of(appState.currentContext).pushNamedAndRemoveUntil(LoginPage.routeName, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    var linkData = Map.from(sharedData);

    final SplashPage defaultSplashPage = SplashPage();
    final AboutPage defaultAboutPage = AboutPage();
    final CollectionsPage defaultCollectionsPage = CollectionsPage(appState);
    final AddLinkPage defaultAddLinkPage = AddLinkPage(appState, linkData: linkData);
    final LoginPage defaultLoginPage = LoginPage(appState);

    Widget getPage() {
      Widget startingPage;
      if (initialized) {
        if (!isLoggedIn) {
          startingPage = defaultLoginPage;
        } else if (linkData != null && linkData.length > 0) {
          startingPage = defaultAddLinkPage;
          sharedData.clear();
        } else {
          startingPage = defaultCollectionsPage;
        }
      } else {
        startingPage = defaultSplashPage;
      }
      return startingPage;
    }

    return MaterialApp(
        title: Strings.title,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(primarySwatch: Colors.teal, accentColor: Color(0xFFDD5237)),
        home: getPage(),
        routes: <String, WidgetBuilder>{
          //5
          CollectionsPage.routeName: (BuildContext context) => defaultCollectionsPage,
          LoginPage.routeName: (BuildContext context) => defaultLoginPage,
          AboutPage.routeName: (BuildContext context) => defaultAboutPage
        },
        onGenerateRoute: (RouteSettings settings) {
          switch (settings.name) {
            case AddLinkPage.routeName:
              var linkData = (settings.arguments is Map) ? settings.arguments : null;
              return MaterialPageRoute(
                  settings: settings, builder: (context) => AddLinkPage(appState, linkData: linkData));
              break;
          }
        });
  }
}
