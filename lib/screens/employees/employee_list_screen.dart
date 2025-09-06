import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/employee.dart';
import '../../services/employee_service.dart';

class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({super.key});

  

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  final EmployeeService _service = EmployeeService(); // Servicio para API
  List<Employee> _employees = [];    // Lista completa
  List<Employee> _filtered = [];     // Lista filtrada
  bool showInactives = false;        // Alternar activos/inactivos
  String filterRole = '';            // Filtro por rol
  String filterLastName = '';        // Filtro por apellido

  @override
  void initState() {
    super.initState();
    loadEmployees(); // Cargar empleados al iniciar
  }

  // Cargar empleados desde el servicio
  void loadEmployees() async {
    try {
      final result = await _service.getEmployees(active: !showInactives);
      setState(() {
        _employees = result;
        applyFilters();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al cargar empleados')),
      );
    }
  }

  // Aplicar filtros a la lista
  void applyFilters() {
    setState(() {
      _filtered = _employees.where((e) {
        final matchRole = filterRole.isEmpty ||
            e.role.toLowerCase().contains(filterRole.toLowerCase());
        final matchLast = filterLastName.isEmpty ||
            e.lastName.toLowerCase().contains(filterLastName.toLowerCase());
        return matchRole && matchLast;
      }).toList();
    });
  }

  // Alternar entre activos e inactivos
  void toggleStatus() {
    setState(() {
      showInactives = !showInactives;
    });
    loadEmployees();
  }

  // Eliminar lógicamente
  Future<void> delete(int id) async {
    await _service.deleteLogical(id);
    loadEmployees();
  }

  // Restaurar empleado
  Future<void> restore(int id) async {
    await _service.restore(id);
    loadEmployees();
  }

  // Formatear fecha de nacimiento
  String formatDate(String iso) {
    final date = DateTime.parse(iso);
    return DateFormat('dd/MM/yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 21, 51, 97), // Fondo azul
      appBar: AppBar(
        title: const Text('Listado de Empleados'),
        backgroundColor: const Color.fromARGB(255, 185, 161, 79), // Barra amarilla
        actions: [
          TextButton(
            onPressed: toggleStatus,
            child: Text(
              showInactives ? 'Ver Activos' : 'Ver Inactivos',
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          // Filtros
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.amber[100],
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(hintText: 'Filtrar por rol'),
                    onChanged: (val) {
                      filterRole = val;
                      applyFilters();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(hintText: 'Filtrar por apellido'),
                    onChanged: (val) {
                      filterLastName = val;
                      applyFilters();
                    },
                  ),
                )
              ],
            ),
          ),

          // Lista de empleados
          Expanded(
            child: ListView.builder(
              itemCount: _filtered.length,
              itemBuilder: (context, index) {
                final emp = _filtered[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                  child: ListTile(
                    title: Text('${emp.firstName} ${emp.lastName}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Rol: ${emp.role}'),
                        Text('Documento: ${emp.documentType} ${emp.documentNumber}'),
                        Text('Nacimiento: ${formatDate(emp.birthDate)}'),
                      ],
                    ),
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        // Botón editar
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.orange),
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/employee-form',
                              arguments: emp, // ← Se pasa el empleado
                            );
                          },
                        ),
                        // Botón eliminar o restaurar
                        if (!showInactives)
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => delete(emp.employeeId!),
                          ),
                        if (showInactives)
                          IconButton(
                            icon: const Icon(Icons.restore, color: Colors.green),
                            onPressed: () => restore(emp.employeeId!),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
      // Botón para registrar nuevo empleado
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(255, 58, 146, 187),
        onPressed: () => Navigator.pushNamed(context, '/employee-form'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
