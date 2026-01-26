// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:colcatrufis/services/trufi_service.dart';
import 'package:colcatrufis/models/trufi.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  List<Trufi> _trufis = [];
  bool _loading = false;
  String _status = 'Presiona cargar para comenzar';

  Future<void> _loadTrufis() async {
    setState(() {
      _loading = true;
      _status = 'Cargando...';
    });
    
    try {
      final trufis = await TrufiService.getTrufis();
      setState(() {
        _trufis = trufis;
        _loading = false;
        _status = '${trufis.length} trufis cargados';
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _status = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Colcatrufis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTrufis,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tarjeta de estado
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Prueba de Conexión API',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(_status),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _loadTrufis,
                      child: const Text('Cargar Trufis'),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Lista de trufis
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _trufis.isEmpty
                      ? Center(
                          child: Text(
                            _status,
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.builder(
                          itemCount: _trufis.length,
                          itemBuilder: (context, index) {
                            final trufi = _trufis[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                leading: const Icon(Icons.directions_car),
                                title: Text(trufi.nomLinea),
                                subtitle: Text(
                                  'Costo: Bs. ${trufi.costo.toStringAsFixed(2)}',
                                ),
                                trailing: trufi.estado
                                    ? const Icon(Icons.check_circle, color: Colors.green)
                                    : const Icon(Icons.cancel, color: Colors.red),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Lista',
          ),
        ],
      ),
    );
  }
}