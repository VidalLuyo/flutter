import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:myapp/screens/products/product_inactive_list_screen.dart';
import 'package:myapp/screens/products/product_list_screen.dart';
import 'package:myapp/screens/login/register_screen.dart';
import 'package:myapp/screens/sales/SalesListMobileScreen.dart';
import 'package:myapp/screens/sales/sale_form.dart';
import 'screens/login/login_screen.dart';
import 'screens/dashboard_screen.dart';

//  Importaciones de empleados
import 'package:myapp/screens/employees/employee_list_screen.dart';
import 'package:myapp/screens/employees/employee_form_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema de Ventas',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', ''), // Español
      ],
      routes: {
        '/': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/register': (context) => const RegisterScreen(),
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/productos': (context) => const ProductListScreen(),
        '/productosInactivos': (context) => const ProductInactiveListScreen(),
        '/sales': (context) => const SalesListMobileScreen(),
        '/sale-form': (context) => const SaleFormScreen(),
        // RUTAS DE EMPLEADOS
        '/employee-list': (context) => const EmployeeListScreen(),
        '/employee-form': (context) => const EmployeeFormScreen(),
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: const Center(child: Text('Bienvenido al sistema de ventas')),
    );
  }
}
