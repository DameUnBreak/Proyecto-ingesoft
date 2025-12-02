import 'package:flutter/material.dart';
import 'mis_listas_page.dart';
import 'crear_lista_page.dart';
import 'login_page.dart';
import 'perfil_page.dart';
import '../theme_notifier.dart';

import '../user_provider.dart';

class HomePage extends StatelessWidget {
  final String correo;
  final int userId;

  const HomePage({super.key, required this.correo, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartCar - Inicio'),
        actions: [
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeNotifier,
            builder: (context, currentMode, child) {
              return IconButton(
                icon: Icon(
                  currentMode == ThemeMode.dark
                      ? Icons.dark_mode
                      : Icons.light_mode,
                ),
                onPressed: () {
                  themeNotifier.value =
                      currentMode == ThemeMode.dark
                          ? ThemeMode.light
                          : ThemeMode.dark;
                },
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration:
                  BoxDecoration(color: Theme.of(context).primaryColor),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 32,
                    child: Icon(Icons.person, size: 40),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    correo,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Inicio'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.list),
              title: const Text('Mis Listas'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MisListasPage(usuarioId: userId),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Configuración'),
              onTap: () {
                // TODO: Implement settings
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar Sesión'),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hola, $correo',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Administra tus listas de compras y mantén tu presupuesto bajo control.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _DashboardCard(
                    icon: Icons.list_alt,
                    title: 'Mis Listas',
                    color: Colors.blueAccent,
                    delay: 0,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              MisListasPage(usuarioId: userId),
                        ),
                      );
                    },
                  ),
                  _DashboardCard(
                    icon: Icons.add_shopping_cart,
                    title: 'Nueva Lista',
                    color: Colors.greenAccent,
                    delay: 100,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              CrearListaPage(usuarioId: userId),
                        ),
                      );
                    },
                  ),
                  _DashboardCard(
                    icon: Icons.history,
                    title: 'Historial',
                    color: Colors.orangeAccent,
                    delay: 200,
                    onTap: () {
                      // Placeholder
                    },
                  ),
                  _DashboardCard(
                    icon: Icons.person,
                    title: 'Perfil',
                    color: Colors.purpleAccent,
                    delay: 300,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PerfilPage(correo: correo),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final int delay;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.delay,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + delay),
      curve: Curves.easeOut,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 40, color: color),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
