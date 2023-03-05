import 'dart:convert';
import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:splash_view/splash_view.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'dart:developer' as dev;
import 'package:http/http.dart' as http;
import 'firebase_options.dart';

void main() async {
  // 앱 초기화
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    name: 'apptoaster-demo',
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 포그라운드 알림 수신
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    FlutterLocalNotificationsPlugin flip = FlutterLocalNotificationsPlugin();
    var android = const AndroidInitializationSettings('@mipmap/ic_launcher');
    var ios = const DarwinInitializationSettings();

    var settings = InitializationSettings(android: android, iOS: ios);
    flip.initialize(settings);
    var androidPlatformChannelSpacifics = const AndroidNotificationDetails(
        "AppToasterChannelId", "AppToasterChannelName",
        importance: Importance.max, priority: Priority.high);
    var iOSPlatformChannelSpecifics = const DarwinNotificationDetails();

    var platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpacifics,
        iOS: iOSPlatformChannelSpecifics);

    await flip.show(0, message.notification!.title, message.notification!.body,
        platformChannelSpecifics,
        payload: 'Default_Sound');
  });

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashView(
        backgroundColor: Colors.black,
        backgroundImageDecoration: const BackgroundImageDecoration(
          image: AssetImage(
            "assets/images/splash_background.jpg",
          ),
          opacity: 0.75,
        ),
        logo: const Image(
          image: AssetImage(
            "assets/images/logo.png",
          ),
          width: 250,
        ),
        loadingIndicator: Padding(
          padding: const EdgeInsets.only(bottom: 60.0),
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
        duration: const Duration(
          seconds: 5,
        ),
        bottomLoading: true,
        done: Done(
          MyApp(),
          animationDuration: const Duration(
            milliseconds: 10,
          ),
        ),
      ),
      title: '앱 토스터',
      theme: ThemeData(
        fontFamily: 'my_font',
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '낚시광장',
      home: ScaffoldMessenger(
        child: App(),
      ),
    );
  }
}

class App extends StatefulWidget {
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  final GlobalKey inAppWebViewKey = GlobalKey();
  late final InAppWebViewController webViewController;
  late final PullToRefreshController pullToRefreshController;
  late String userAgent;
  DateTime? currentBackPressTime;
  bool isPushAllow = false;
  bool isAdPushAllow = false;
  late String? token;
  final String key = 'TESTKEY';
  late Map<String, dynamic> targetMap;
  String errorMessage = '';
  bool isRefreshError = false;
  bool inicisErrorShowen = false;

  // 상태 초기화
  @override
  void initState() {
    super.initState();

    FirebaseMessaging.instance.requestPermission();

    // 현재 플랫폼을 판별하여 User-Agent를 설정합니다.
    userAgent = Platform.isIOS
        ? "Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36 [FB_IAB/FB4A;FBAV/294.0.0.39.118;] ios_mobile_app"
        : "Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36 [FB_IAB/FB4A;FBAV/294.0.0.39.118;] android_mobile_app";

    // User-Agent 모바일 버전으로 설정
    pullToRefreshController = PullToRefreshController(
      options: PullToRefreshOptions(color: Colors.blue),
      onRefresh: () async {
        Uri? currentUrl = await webViewController.getUrl();
        webViewController.loadUrl(
          urlRequest: URLRequest(url: currentUrl!),
        );
        pullToRefreshController.endRefreshing();
      },
    );

    initTarget();
  }

  void setErrorMessage(String message) {
    setState(() {
      errorMessage = message;
    });
  }

  // 타겟 초기화
  void initTarget() async {
    late var response;
    try {
      token = await FirebaseMessaging.instance.getToken();
      response = await http.get(Uri.parse(
          "https://apptoaster.co.kr/api/target/id/$key?token=$token"));
      targetMap = json.decode(response.body);
      dev.log('status: ${targetMap["status"]}');
      dev.log('target: ${targetMap["target"]}');
      if (targetMap['status'] == 'new') {
        showDialog();
      }
      isPushAllow = targetMap['target']['isPushAllow'] == 'true' ? true : false;
      isAdPushAllow = targetMap['target']['isAdAllow'] == 'true' ? true : false;
    } catch (e) {
      dev.log(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('앱 인증에 실패하였습니다. 데모 앱이거나 인증이 만료된 앱입니다.(404)'),
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  // 타겟 업데이트
  void updateTarget() async {
    try {
      if (isPushAllow && !isAdPushAllow) {
        DateTime now = DateTime.now();
        String timestamp = '${now.year}년 ${now.month}월 ${now.day}일';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$timestamp 푸시알림 수신에 동의하셨습니다.'),
            duration: Duration(seconds: 1),
          ),
        );
      } else if (isPushAllow && isAdPushAllow) {
        DateTime now = DateTime.now();
        String timestamp = '${now.year}년 ${now.month}월 ${now.day}일';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$timestamp 광고성 푸시알림 수신에 동의하셨습니다.'),
            duration: Duration(seconds: 1),
          ),
        );
      }
      await http.patch(Uri.parse(
          "https://apptoaster.co.kr/api/target/id/$key?token=$token&isPushAllow=$isPushAllow&isAdAllow=$isAdPushAllow"));
    } catch (e) {
      dev.log(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('앱 인증에 실패하였습니다. 데모 앱이거나 인증이 만료된 앱입니다.(404)'),
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  // 뒤로가기 실행
  Future<bool> goBack() async {
    var canGoBack = await webViewController.canGoBack();
    if (canGoBack) {
      webViewController.goBack();
      return false;
    } else {
      DateTime now = DateTime.now();
      if (currentBackPressTime == null ||
          now.difference(currentBackPressTime!) > Duration(seconds: 3)) {
        currentBackPressTime = now;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('뒤로가기 버튼을 한번 더 누르시면 종료됩니다.'),
            duration: Duration(seconds: 1),
          ),
        );
        return Future.value(false);
      }
      SystemNavigator.pop();
      return Future.value(true);
    }
  }

  Future<bool> isAppInstalled(String packageName) async {
    try {
      final bool isInstalled =
          await MethodChannel('plugins.flutter.io/package_info')
              .invokeMethod('isAppInstalled', packageName);
      return isInstalled;
    } on PlatformException {
      return false;
    }
  }

  // 앞으로 가기 실행
  Future<void> goForeward() async {
    var canGoForward = await webViewController.canGoForward();
    if (canGoForward) {
      webViewController.goForward();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('앞으로 갈 수 있는 페이지가 없습니다.'),
          duration: Duration(seconds: 1),
        ),
      );
    }
    return;
  }

  void handleIntent(String url) {
    /*
    try {
      final intent = AndroidIntent(
        action: 'android.intent.action.VIEW',
        data: url,
      );
      intent.launch();

      intent.launch().catchError((e) {
        final packageName = url
            .split('package=')[1]
            .split('&')[0]
            .replaceAll('end', '')
            .replaceAll(';', '');
        final storeUrl =
            'https://play.google.com/store/apps/details?id=$packageName';
        launchUrlString(
          storeUrl,
          mode: LaunchMode.externalApplication,
        );
      });
    } on Exception catch (e) {
      dev.log(e.toString());
    }
    */
  }

  void showDialog() {
    // AwesomeDialog 생성
    AwesomeDialog(
      context: context,
      dialogType: DialogType.NO_HEADER,
      dismissOnTouchOutside: false,
      // StatefulBuilder를 사용하여 Dialog의 상태 관리
      body: StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dialog 내용 작성
              Row(
                children: [
                  Text(
                    '   푸시 알림 설정 ',
                    style: TextStyle(fontSize: 20),
                  ),
                  Icon(
                    Icons.notifications,
                  ),
                ],
              ),

              SizedBox(height: 20),
              CheckboxListTile(
                title: Text('푸시 알림 수신'),
                value: isPushAllow,
                onChanged: (value) {
                  setState(() {
                    isPushAllow = value!;
                  });
                },
              ),
              CheckboxListTile(
                title: Text('광고성 푸시 알림 수신'),
                value: isAdPushAllow,
                onChanged: (value) {
                  setState(() {
                    isAdPushAllow = value!;
                  });
                },
              ),

              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        // Dialog 닫기
                        Navigator.of(context).pop();
                        updateTarget();
                      },
                      child: Text(
                        '닫기',
                        style:
                            TextStyle(color: Color.fromARGB(255, 90, 90, 90)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    )..show();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => goBack(),
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 0,
          backgroundColor: Colors.black,
          // 상태표시줄이 영향을 미치지 않도록 하기 위해서 SafeArea 위젯을 추가합니다.
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(0),
            child: SafeArea(
              child: SizedBox(),
              bottom: false,
            ),
          ),
        ),
        body: Stack(
          children: [
            InAppWebView(
              key: inAppWebViewKey,
              // InAppWebViewController 객체를 전달합니다.
              onWebViewCreated: (controller) {
                webViewController = controller;
              },
              onLoadError: (controller, url, code, message) {
                controller.stopLoading();
                setErrorMessage(message);

                dev.log('url: ${url.toString()}');
                dev.log('message: $errorMessage');
              },
              onLoadStart: (controller, url) async {
                dev.log('onLoadStart: ${url.toString()}');
                setErrorMessage('');
                if (url.toString().contains('https://mobile.inicis.com/smart') &
                    !inicisErrorShowen &
                    Platform.isAndroid) {
                  inicisErrorShowen = true;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          '안드로이드에서 이니시스 결제 시 오류가 발생하고 있어요. 네이버페이, 카카오페이, 페이코, 토스 등 결제 앱을 사용해주세요.'),
                      duration: Duration(seconds: 5),
                    ),
                  );
                }
                const externalLinkPool = [
                  'tel:',
                  'https://bizmessage.kakao.com/chat',
                  'https://www.instagram.com',
                  'https://online-pay.kakao.com',
                  'https://bill.payco.com/m/apppayment/loaderBridge',
                  'https://pay.toss.im/payfront',
                  // 아래 이니시스 결제 사용 불가
                  'https://mobile.inicis.com/smart',
                ];
                for (String link in externalLinkPool) {
                  if (url.toString().startsWith(link)) {
                    launchUrlString(
                      url.toString(),
                      mode: LaunchMode.externalApplication,
                    );
                    await controller.stopLoading();
                    controller.goBack();
                  }
                }
                if (url.toString().startsWith('intent:')) {
                  // intent 처리 추가 필요
                  await controller.stopLoading();
                  controller.goBack();
                }
              },
              // WebView를 로드합니다.
              initialUrlRequest: URLRequest(
                url: Uri.parse('https://convenii.com/'),
              ),
              // WebView 옵션을 설정합니다.
              initialOptions: InAppWebViewGroupOptions(
                crossPlatform: InAppWebViewOptions(
                  javaScriptEnabled: true,
                  userAgent: userAgent,
                ),
              ),
              // pull-to-refresh 기능을 설정합니다.
              pullToRefreshController: pullToRefreshController,
            ),
            errorMessage != ''
                ? Stack(
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage('assets/images/error.jpg'),
                              fit: BoxFit.cover,
                              colorFilter: ColorFilter.mode(
                                  Colors.black.withOpacity(0.75),
                                  BlendMode.darken),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          verticalDirection: VerticalDirection.down,
                          children: [
                            SizedBox(
                              height: 40.0,
                            ),
                            Row(
                              children: [
                                Text(
                                  "오류가 발생한것같네요..",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Text(
                                  "$errorMessage",
                                  softWrap: true,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Row(
                              children: [
                                Text(
                                  "인터넷 연결이나.. 잘못된 페이지를 여신건 아닌지 확인해보세요.\n만약 앱을 사용하시다가 계속 이 페이지가 반복되어 나온다면,\n개발자에게 연락해주세요.",
                                  softWrap: true,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: 20,
                            ),
                            Row(
                              children: [
                                ElevatedButton(
                                  onPressed: () async {
                                    setState(() {
                                      isRefreshError = true;
                                    });

                                    var canGoBack =
                                        await webViewController.canGoBack();
                                    if (canGoBack) {
                                      await webViewController.goBack();
                                    }
                                    await webViewController.reload();
                                    setState(() {
                                      isRefreshError = false;
                                    });
                                  },
                                  child: Text(
                                    '새로고침',
                                    style: TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Color.fromARGB(255, 97, 86, 105),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          verticalDirection: VerticalDirection.up,
                          children: [
                            SizedBox(
                              height: 40,
                            ),
                            isRefreshError
                                ? Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                  )
                                : SizedBox(),
                          ],
                        ),
                      ),
                    ],
                  )
                : SizedBox(),
          ],
        ),
        bottomNavigationBar: Container(
          height: 36,
          padding: const EdgeInsets.all(0.0),
          margin: EdgeInsets.zero,
          decoration: const BoxDecoration(
            color: Colors.black,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  goBack();
                },
                child: Icon(
                  Icons.chevron_left,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              GestureDetector(
                onTap: () {
                  goForeward();
                },
                child: Icon(
                  Icons.chevron_right,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(),
              const SizedBox(),
              const SizedBox(),
              const SizedBox(),
              GestureDetector(
                onTap: () {
                  // showDialog 함수 호출
                  showDialog();
                },
                child: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Icon(
                    Icons.settings,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // end of build
}
