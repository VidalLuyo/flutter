import 'package:flutter/material.dart';
import '../../models/employee.dart';
import '../../services/employee_service.dart';

class EmployeeFormScreen extends StatefulWidget {
  // Puede recibir un empleado existente si es modo edición
  final Employee? existing;

  const EmployeeFormScreen({super.key, this.existing});

  @override
  State<EmployeeFormScreen> createState() => _EmployeeFormScreenState();
}

class _EmployeeFormScreenState extends State<EmployeeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final EmployeeService _service = EmployeeService();

  late Employee _employee; // El empleado actual (nuevo o a editar)
  bool isEditMode = false;

  @override
  void initState() {
    super.initState();
    // Si recibe un empleado, es modo edición; si no, crea uno nuevo
    _employee = widget.existing ??
        Employee(
          documentType: '',
          documentNumber: '',
          firstName: '',
          lastName: '',
          birthDate: '',
          email: '',
          phone: '',
          address: '',
          role: '',
          status: 'A',
        );
    isEditMode = widget.existing != null;
  }

  // Validar si el empleado tiene más de 18 años
  bool isAdult(String date) {
    final birth = DateTime.parse(date);
    final today = DateTime.now();
    final age = today.year - birth.year - ((today.month < birth.month || (today.month == birth.month && today.day < birth.day)) ? 1 : 0);
    return age >= 18;
  }

  // Validar correo con formato y dominio permitido
  bool validateEmail(String? email) {
    final format = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    final allowedDomains = RegExp(r'@(vallegrande\.edu\.pe|gmail\.com|hotmail\.com|outlook\.com)$');
    return format.hasMatch(email ?? '') && allowedDomains.hasMatch(email ?? '');
  }

  // Validar número de celular que empiece con 9
  bool validatePhone(String? phone) {
    return RegExp(r'^9\d{8}$').hasMatch(phone ?? '');
  }

  // Guardar el formulario
  void saveForm() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    try {
      if (isEditMode) {
        await _service.update(_employee.employeeId!, _employee);
      } else {
        await _service.create(_employee);
      }
      if (mounted) Navigator.pop(context); // Volver atrás si todo salió bien
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al guardar')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 21, 51, 97), // Fondo azul
      appBar: AppBar(
        title: Text(isEditMode ? 'Editar Empleado' : 'Registrar Empleado'),
        backgroundColor: const Color.fromARGB(255, 185, 161, 79), // Amarillo encabezado
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white, // Fondo blanco del formulario
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
            ),
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Text(
                    'Información del Empleado',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.amber),
                  ),
                  const SizedBox(height: 20),

                  // Nombre
                  TextFormField(
                    initialValue: _employee.firstName,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                    validator: (val) => val!.isEmpty ? 'Campo obligatorio' : null,
                    onSaved: (val) => _employee = _employee.copyWith(firstName: val),
                  ),

                  // Apellido
                  TextFormField(
                    initialValue: _employee.lastName,
                    decoration: const InputDecoration(labelText: 'Apellido'),
                    validator: (val) => val!.isEmpty ? 'Campo obligatorio' : null,
                    onSaved: (val) => _employee = _employee.copyWith(lastName: val),
                  ),

                  // Tipo de documento
                  DropdownButtonFormField<String>(
                    value: _employee.documentType.isNotEmpty ? _employee.documentType : null,
                    decoration: const InputDecoration(labelText: 'Tipo Documento'),
                    items: const [
                      DropdownMenuItem(value: 'DNI', child: Text('DNI')),
                      DropdownMenuItem(value: 'CNE', child: Text('CNE')),
                    ],
                    onChanged: (val) => setState(() => _employee = _employee.copyWith(documentType: val)),
                    validator: (val) => val == null || val.isEmpty ? 'Seleccione un tipo' : null,
                  ),

                  // Número de documento
                  TextFormField(
                    initialValue: _employee.documentNumber,
                    decoration: const InputDecoration(labelText: 'N° Documento'),
                    validator: (val) {
                      if (_employee.documentType == 'DNI' && !RegExp(r'^\d{8}$').hasMatch(val ?? '')) {
                        return 'DNI debe tener 8 dígitos';
                      }
                      if (_employee.documentType == 'CNE' && !RegExp(r'^\d{9,20}$').hasMatch(val ?? '')) {
                        return 'CNE debe tener entre 9 y 20 dígitos';
                      }
                      return null;
                    },
                    onSaved: (val) => _employee = _employee.copyWith(documentNumber: val),
                  ),

                  // Fecha de nacimiento
                  TextFormField(
                    initialValue: _employee.birthDate,
                    decoration: const InputDecoration(labelText: 'Fecha de Nacimiento (YYYY-MM-DD)'),
                    validator: (val) => val != null && isAdult(val) ? null : 'Debe ser mayor de edad',
                    onSaved: (val) => _employee = _employee.copyWith(birthDate: val),
                  ),

                  // Email
                  TextFormField(
                    initialValue: _employee.email,
                    decoration: const InputDecoration(labelText: 'Correo Electrónico'),
                    validator: (val) => validateEmail(val) ? null : 'Correo inválido o dominio no permitido',
                    onSaved: (val) => _employee = _employee.copyWith(email: val),
                  ),

                  // Teléfono
                  TextFormField(
                    initialValue: _employee.phone,
                    decoration: const InputDecoration(labelText: 'Teléfono'),
                    validator: (val) => validatePhone(val) ? null : 'Debe comenzar con 9 y tener 9 dígitos',
                    onSaved: (val) => _employee = _employee.copyWith(phone: val),
                  ),

                  // Dirección
                  TextFormField(
                    initialValue: _employee.address,
                    decoration: const InputDecoration(labelText: 'Dirección'),
                    onSaved: (val) => _employee = _employee.copyWith(address: val),
                  ),

                  // Rol
                  TextFormField(
                    initialValue: _employee.role,
                    decoration: const InputDecoration(labelText: 'Rol'),
                    validator: (val) => val!.isEmpty ? 'Campo obligatorio' : null,
                    onSaved: (val) => _employee = _employee.copyWith(role: val),
                  ),

                  const SizedBox(height: 20),

                  // Botones de acción
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: saveForm,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        child: Text(isEditMode ? 'Actualizar' : 'Registrar'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('Cancelar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
