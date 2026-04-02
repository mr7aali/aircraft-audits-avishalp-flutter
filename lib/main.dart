import 'package:avislap/healper/route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'config/app_env.dart';
import 'services/app_api_service.dart';
import 'services/session_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppEnv.load();
  await GetStorage.init();

  final sessionService = await SessionService().init();
  Get.put<SessionService>(sessionService, permanent: true);
  Get.put<AppApiService>(
    AppApiService(sessionService: sessionService),
    permanent: true,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          initialRoute: RouteHelper.splash,
          getPages: RouteHelper.routes,
          theme: ThemeData(fontFamily: 'Regular'),
        );
      },
    );
  }
}
