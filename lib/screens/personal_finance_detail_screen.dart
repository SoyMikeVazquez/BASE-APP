import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:supabase_flutter/supabase_flutter.dart';

class PersonalFinanceDetailScreen extends StatefulWidget {
  final Map<String, dynamic> staff;
  final DateTime startDate;
  final DateTime endDate;
  final List<Map<String, dynamic>> finanzasRecords;
  final List<Map<String, dynamic>> ordenesRecords;
  final double totalServicios;

  const PersonalFinanceDetailScreen({
    super.key,
    required this.staff,
    required this.startDate,
    required this.endDate,
    required this.finanzasRecords,
    required this.ordenesRecords,
    required this.totalServicios,
  });

  @override
  State<PersonalFinanceDetailScreen> createState() =>
      _PersonalFinanceDetailScreenState();
}

class _PersonalFinanceDetailScreenState
    extends State<PersonalFinanceDetailScreen> {
  late List<Map<String, dynamic>> _finanzasRecords;
  late List<Map<String, dynamic>> _ordenesRecords;
  late DateTime _currentStartDate;
  late DateTime _currentEndDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentStartDate = widget.startDate;
    _currentEndDate = widget.endDate;
    _finanzasRecords = widget.finanzasRecords.map((e) => {...e, '_type': 'servicio'}).toList();
    _ordenesRecords = widget.ordenesRecords.map((e) => {...e, '_type': 'producto'}).toList();
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _currentStartDate, end: _currentEndDate),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.black,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _currentStartDate = picked.start;
        _currentEndDate = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
      });
      _fetchData();
    }
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final staffId = widget.staff['userID'];
    final startStr = _currentStartDate.toIso8601String();
    final endStr = _currentEndDate.toIso8601String();
    
    try {
      final res = await Future.wait([
        Supabase.instance.client
            .from('FinanzasPersonal')
            .select()
            .eq('personalID', staffId)
            .gte('fecha', startStr)
            .lte('fecha', endStr),
        Supabase.instance.client
            .from('OrdenesProductos')
            .select()
            .eq('personal_id', staffId)
            .gte('fecha', startStr)
            .lte('fecha', endStr),
      ]);
      
      final fin = List<Map<String, dynamic>>.from(res[0]);
      final ord = List<Map<String, dynamic>>.from(res[1]);
      
      if (mounted) {
        setState(() {
          _finanzasRecords = fin.map((e) => {...e, '_type': 'servicio'}).toList();
          _ordenesRecords = ord.map((e) => {...e, '_type': 'producto'}).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final name = widget.staff['nombre'] ?? 'Personal';
    final hasPhoto =
        widget.staff['foto_perfil'] != null &&
        widget.staff['foto_perfil'].toString().isNotEmpty;
    final mostrarFoto = widget.staff['mostrar_foto'] ?? true;

    final recordsToShow = [..._finanzasRecords, ..._ordenesRecords];
    recordsToShow.sort((a, b) {
      final aDate = a['fecha'] != null ? DateTime.parse(a['fecha']) : DateTime(1970);
      final bDate = b['fecha'] != null ? DateTime.parse(b['fecha']) : DateTime(1970);
      return bDate.compareTo(aDate);
    });

    double calculatedTotal = 0;
    for (var r in _finanzasRecords) {
      calculatedTotal += double.tryParse((r['total'] ?? 0).toString()) ?? 0.0;
    }
    for (var r in _ordenesRecords) {
      calculatedTotal += double.tryParse((r['suma_productos'] ?? 0).toString()) ?? 0.0;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1A1A1A), Color(0xFF2C2C2E)],
                ),
              ),
              padding: EdgeInsets.only(
                top: mq.padding.top + 8,
                bottom: 20,
                left: 20,
                right: 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 36,
                          height: 36,
                          color: Colors.white24,
                          child: (hasPhoto && mostrarFoto)
                              ? Image.network(
                                  widget.staff['foto_perfil'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.person,
                                    color: Colors.white54,
                                    size: 20,
                                  ),
                                )
                              : const Icon(
                                  Icons.person,
                                  color: Colors.white54,
                                  size: 20,
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            GestureDetector(
                              onTap: _selectDateRange,
                              child: Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.calendar_today, color: Colors.white70, size: 12),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${intl.DateFormat('d/MM').format(_currentStartDate)} - ${intl.DateFormat('d/MM').format(_currentEndDate)}',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.9),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Total período',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${calculatedTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1,
                    ),
                  ),
                  // Tabs were here
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Registros',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '${recordsToShow.length} total',
                    style: const TextStyle(fontSize: 13, color: Colors.black38),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 10)),

          if (_isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: Colors.black),
              ),
            )
          else if (recordsToShow.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 40,
                  horizontal: 20,
                ),
                child: Center(
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.bar_chart_rounded,
                          color: Colors.black12,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Sin registros',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 5,
                  ),
                  child: GestureDetector(
                    onTap: () => _showRecordDetails(context, recordsToShow[i]),
                    child: _buildRecordCard(recordsToShow[i]),
                  ),
                ),
                childCount: recordsToShow.length,
              ),
            ),

          SliverToBoxAdapter(child: SizedBox(height: mq.padding.bottom + 24)),
        ],
      ),
    );
  }

  Widget _buildRecordCard(Map<String, dynamic> r) {
    final fecha = r['fecha'] != null ? DateTime.parse(r['fecha']) : null;
    final isService = r['_type'] == 'servicio';
    final isGasto =
        isService &&
        r['Gasto'] != null &&
        r['Gasto'].toString().trim().isNotEmpty;
    final total = isGasto
        ? (double.tryParse(r['Gasto'].toString()) ?? 0.0)
        : (isService
              ? (double.tryParse((r['total'] ?? 0).toString()) ?? 0.0)
              : (double.tryParse((r['suma_productos'] ?? 0).toString()) ??
                    0.0));
    final formaPago = r['formadepago'] as String? ?? '';
    final sucursal = r['sucursal'] as String? ?? '';

    final itemsCount = isService
        ? (r['servicios_detalle'] as List? ?? []).length
        : (r['productos_detalle'] as List? ?? []).length;
        
    final typeStr = isGasto ? 'Gasto' : (isService ? 'Servicio' : 'Producto');
    final detailsStr = isGasto ? '' : ' ($itemsCount item${itemsCount != 1 ? 's' : ''})';

    IconData paymentIcon;
    switch (formaPago.toLowerCase()) {
      case 'tarjeta':
        paymentIcon = Icons.credit_card_rounded;
        break;
      case 'transferencia':
        paymentIcon = Icons.swap_horiz_rounded;
        break;
      default:
        paymentIcon = Icons.payments_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isGasto
                  ? const Color(0xFFFBF2F2)
                  : const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isGasto
                  ? Icons.arrow_outward_rounded
                  : (isService ? paymentIcon : Icons.shopping_bag_outlined),
              size: 20,
              color: isGasto ? Colors.red : Colors.black87,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fecha != null
                      ? intl.DateFormat('dd/MM · HH:mm').format(fecha)
                      : 'Sin fecha',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    if (sucursal.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F2F7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          sucursal,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: typeStr,
                            style: TextStyle(
                              fontSize: 11,
                              color: isGasto ? Colors.red : Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: detailsStr,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                isGasto
                    ? '-\$${total.toStringAsFixed(2)}'
                    : '\$${total.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isGasto ? Colors.red : Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                formaPago,
                style: const TextStyle(fontSize: 11, color: Colors.black38),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showRecordDetails(BuildContext context, Map<String, dynamic> r) {
    final mq = MediaQuery.of(context);
    final fecha = r['fecha'] != null ? DateTime.parse(r['fecha']) : null;
    final isService = r['_type'] == 'servicio';
    final isGasto = isService && r['Gasto'] != null && r['Gasto'].toString().trim().isNotEmpty;
    
    final total = isGasto
        ? (double.tryParse(r['Gasto'].toString()) ?? 0.0)
        : (isService
              ? (double.tryParse((r['total'] ?? 0).toString()) ?? 0.0)
              : (double.tryParse((r['suma_productos'] ?? 0).toString()) ?? 0.0));
              
    final serviciosAmount = isService ? (double.tryParse((r['suma_servicios'] ?? 0).toString()) ?? 0.0) : 0.0;
    final montosExtras = isService ? (double.tryParse((r['montos_extras'] ?? 0).toString()) ?? 0.0) : 0.0;
    final productosAmount = !isService ? (double.tryParse((r['suma_productos'] ?? 0).toString()) ?? 0.0) : 0.0;
    
    final formaPago = r['formadepago'] as String? ?? 'Desconocida';
    final sucursal = r['sucursal'] as String? ?? 'Sin sucursal';
    final registradoPor = r['QuienRegistro'] as String? ?? widget.staff['nombre'] ?? 'Desconocido';
        
    IconData paymentIcon = Icons.payments_rounded;
    if (isGasto) paymentIcon = Icons.arrow_outward_rounded;
    else if (!isService) paymentIcon = Icons.shopping_bag_outlined;
    else if (formaPago.toLowerCase() == 'tarjeta') paymentIcon = Icons.credit_card_rounded;
    else if (formaPago.toLowerCase() == 'transferencia') paymentIcon = Icons.swap_horiz_rounded;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: mq.padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Header Row
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(paymentIcon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fecha != null
                              ? intl.DateFormat('EEEE dd \'de\' MMMM · HH:mm', 'es').format(fecha)
                              : 'Sin fecha',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          sucursal,
                          style: const TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    isGasto ? '-\$${total.toStringAsFixed(2)}' : '\$${total.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold,
                      color: isGasto ? Colors.red : Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(height: 1, color: Colors.black12),
              const SizedBox(height: 24),
              
              // Details
              if (isService && !isGasto) ...[
                _buildDetailRow('Servicios', '\$${serviciosAmount.toStringAsFixed(2)}'),
                const SizedBox(height: 16),
                _buildDetailRow('Montos extras', '\$${montosExtras.toStringAsFixed(2)}'),
                const SizedBox(height: 16),
              ],
              if (!isService) ...[
                _buildDetailRow('Productos', '\$${productosAmount.toStringAsFixed(2)}'),
                const SizedBox(height: 16),
              ],
              if (isGasto) ...[
                _buildDetailRow('Gasto', '\$${total.toStringAsFixed(2)}'),
                const SizedBox(height: 16),
              ],
              
              _buildDetailRow('Forma de pago', formaPago),
              const SizedBox(height: 16),
              _buildDetailRow('Registrado por', registradoPor),
              const SizedBox(height: 24),
              const Divider(height: 1, color: Colors.black12),
              const SizedBox(height: 24),
              
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Función de edición en construcción')),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: Colors.black26),
                      ),
                      icon: const Icon(Icons.edit, color: Colors.black),
                      label: const Text('Editar', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _deleteRecord(context, r);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF44336),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.delete_outline, color: Colors.white),
                      label: const Text('Eliminar', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.black54)),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black)),
      ],
    );
  }

  Future<void> _deleteRecord(BuildContext context, Map<String, dynamic> r) async {
    final id = r['id'];
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: Registro sin ID')));
      return;
    }
    
    final isService = r['_type'] == 'servicio';
    final table = isService ? 'FinanzasPersonal' : 'OrdenesProductos';
    
    try {
      await Supabase.instance.client.from(table).delete().eq('id', id);
      setState(() {
        if (isService) {
          _finanzasRecords.removeWhere((record) => record['id'] == id);
        } else {
          _ordenesRecords.removeWhere((record) => record['id'] == id);
        }
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registro eliminado')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
      }
    }
  }
}
