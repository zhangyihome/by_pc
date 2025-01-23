import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  // 设置窗口标题
  await windowManager.setTitle('');
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final controller = WebViewController();
  final urlController = TextEditingController();
  final url = "https://dawei.lenovo.com/chatPage";

  @override
  void initState() {
    super.initState();
    // 添加观察者以监听系统主题变化
    WidgetsBinding.instance.addObserver(this);

    controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    controller.setBackgroundColor(Colors.white);
    controller.setNavigationDelegate(NavigationDelegate(
      onNavigationRequest: (request) {
        if (request.url != '') {
          return NavigationDecision.navigate;
        } else {
          debugPrint("prevent user navigate out of google website!");
          return NavigationDecision.prevent;
        }
      },
      onPageStarted: (url) {
        urlController.text = url;
        debugPrint("onPageStarted: $url");
      },
      onPageFinished: (url) => print("onPageFinished: $url"),
      onWebResourceError: (error) =>
          debugPrint("onWebResourceError: ${error.description}"),
    ));
    controller.addJavaScriptChannel("Flutter", onMessageReceived: (message) {
      debugPrint("js -> dart : ${message.message}");
    });
    controller.loadRequest(Uri.parse(url));
  }

  @override
  void dispose() {
    // 移除观察者
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    // 系统主题变化时更新背景颜色
    Future.delayed(const Duration(milliseconds: 200), () {
      setState(() {
        debugPrint("Flutter 系统主题：${MediaQuery.of(context).platformBrightness}");
        controller.setBackgroundColor(
            MediaQuery.of(context).platformBrightness == Brightness.dark
                ? Colors.black
                : Colors.white);
      });
    });
  }

  void testJavascript() {
    controller.runJavaScript("Flutter.postMessage('中文')");
  }

  @override
  Widget build(BuildContext context) {
    Widget urlBox = TextField(
      controller: urlController,
      onSubmitted: (url) {
        url = url.trim();
        if (!url.startsWith("http")) {
          url = "https://$url";
        }
        controller.loadRequest(Uri.parse(url));
      },
    );
    Widget buttonRow = Row(children: [
      MyCircleButton(icon: Icons.javascript, onTap: testJavascript),
      MyCircleButton(icon: Icons.arrow_back, onTap: controller.goBack),
      MyCircleButton(icon: Icons.arrow_forward, onTap: controller.goForward),
      MyCircleButton(icon: Icons.refresh, onTap: controller.reload),
      Expanded(child: urlBox),
    ]);

    Widget body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // buttonRow,
        Expanded(child: WebViewWidget(controller: controller)),
      ],
    );

    return MaterialApp(
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
      ),
      themeMode: ThemeMode.system,
      // 使用系统主题
      home: Scaffold(
        body: body,
      ),
    );
  }
}

class MyCircleButton extends StatelessWidget {
  final GestureTapCallback? onTap;
  final IconData icon;
  final double size;

  const MyCircleButton(
      {super.key, required this.onTap, required this.icon, this.size = 32});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Material(
        color: Colors.blue, // Button color
        child: InkWell(
          splashColor: Colors.red, // Splash color
          onTap: onTap,
          child: SizedBox(width: size, height: size, child: Icon(icon)),
        ),
      ),
    );
  }
}
