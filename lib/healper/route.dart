import 'package:avislap/views/auth/splash_screen.dart';
import 'package:avislap/views/auth/login_screen.dart';
import 'package:avislap/views/forms/LAV%20Safety%20Observation/LAVSafety.dart';
import 'package:avislap/views/forms/LAV%20Safety%20Observation/LavSafetyObservationScreen.dart';
import 'package:get/get.dart';

import '../views/auth/FlightAnimation.dart';
import '../views/dashboard/dashboard_screen.dart';
import '../views/forms/Cabin Quality Audit/CabinAudit.dart';
import '../views/forms/cabin security search/cabin_secuirity.dart';

class RouteHelper {
  static const String splash = '/';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String cabinAudit = '/cabin-audit';
  // static const String lavSafety = '/lav-safety';
  static const String lavSafety = '/LAVSafety';
  static const String cabinSecurityTraining = '/cabin_secuirity';

  static List<GetPage> routes = [
    GetPage(
      name: splash,
      // page: () => FlightAnimation(),
      page: () => SplashScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: login,
      page: () => const LoginScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: dashboard,
      page: () => const DashboardScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: cabinAudit,
      page: () => CabinAuditScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: lavSafety,
      page: () => LavSafetyObservationScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: cabinSecurityTraining,
      page: () => const CabinQualityAuditScreenN(),
      transition: Transition.rightToLeft,
    ),
  ];
}