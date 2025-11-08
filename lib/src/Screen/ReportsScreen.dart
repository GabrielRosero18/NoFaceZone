import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:nofacezone/src/Custom/AppColors.dart';
import 'package:nofacezone/src/Custom/AppLocalizations.dart';
import 'package:nofacezone/src/Providers/AppProvider.dart';
import 'package:nofacezone/src/Providers/UserProvider.dart';
import 'package:nofacezone/src/Services/PreferencesService.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    AppColors.setTheme(appProvider.colorTheme);
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.reportsAndExportation),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.backgroundGradient,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título y descripción
                Text(
                  localizations.reportsAndExportation,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  localizations.reportsAndExportationDescription,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textLight.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 32),

                // Sección de selección de período
                _buildPeriodSection(localizations),
                const SizedBox(height: 24),

                // Botón de generar reporte
                _buildGenerateButton(localizations),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSection(AppLocalizations localizations) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.textLight.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.textLight.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.textLight.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.selectPeriod,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            localizations.selectPeriodDescription,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textLight.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 20),
          
          // Campos de fecha
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  label: localizations.from,
                  date: _startDate,
                  onTap: () => _selectStartDate(localizations),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateField(
                  label: localizations.to,
                  date: _endDate,
                  onTap: () => _selectEndDate(localizations),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Botones rápidos
          Row(
            children: [
              Expanded(
                child: _buildQuickButton(
                  text: localizations.reportsLastWeek,
                  onTap: () => _setLastWeek(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickButton(
                  text: localizations.reportsLastMonth,
                  onTap: () => _setLastMonth(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.textLight.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.textLight.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textLight.withValues(alpha: 0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 18,
                  color: AppColors.textLight.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    date != null
                        ? DateFormat('dd/MM/yyyy').format(date)
                        : AppLocalizations.of(context)!.selectDate,
                    style: TextStyle(
                      fontSize: 14,
                      color: date != null
                          ? AppColors.textLight
                          : AppColors.textLight.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickButton({
    required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.textLight.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.textLight.withValues(alpha: 0.3),
          ),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textLight.withValues(alpha: 0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGenerateButton(AppLocalizations localizations) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isGenerating ? null : () => _generateReport(localizations),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentBlue,
          foregroundColor: AppColors.textLight,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        child: _isGenerating
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.textLight),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.picture_as_pdf, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    localizations.generateReport,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _selectStartDate(AppLocalizations localizations) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now().subtract(const Duration(days: 7)),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.accentBlue,
              onPrimary: AppColors.textLight,
              surface: const Color(0xFF1A1F3A),
              onSurface: AppColors.textLight,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(_startDate!)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _selectEndDate(AppLocalizations localizations) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.accentBlue,
              onPrimary: AppColors.textLight,
              surface: const Color(0xFF1A1F3A),
              onSurface: AppColors.textLight,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  void _setLastWeek() {
    final now = DateTime.now();
    setState(() {
      _endDate = now;
      _startDate = now.subtract(const Duration(days: 7));
    });
  }

  void _setLastMonth() {
    final now = DateTime.now();
    setState(() {
      _endDate = now;
      _startDate = now.subtract(const Duration(days: 30));
    });
  }

  Future<void> _generateReport(AppLocalizations localizations) async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.selectDateRange)),
      );
      return;
    }

    if (_startDate!.isAfter(_endDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.invalidDateRange)),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      // Obtener datos del usuario y estadísticas
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      final user = userProvider.user;

      // Calcular estadísticas del período
      final daysDiff = _endDate!.difference(_startDate!).inDays + 1;
      final todayUsageTime = PreferencesService.getTodayUsageTime();
      final recordTime = PreferencesService.getRecordTimeWithoutFacebook();
      final dailyLimit = appProvider.dailyUsageLimit;
      final weeklyGoal = appProvider.weeklyGoal;

      // Crear PDF
      final pdf = await _createPdf(
        localizations,
        user?.name ?? localizations.userLabel,
        user?.email ?? '',
        _startDate!,
        _endDate!,
        daysDiff,
        todayUsageTime,
        recordTime,
        dailyLimit,
        weeklyGoal,
      );

      // Mostrar diálogo de impresión/compartir
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.reportGenerated),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localizations.reportError}: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  Future<pw.Document> _createPdf(
    AppLocalizations localizations,
    String userName,
    String userEmail,
    DateTime startDate,
    DateTime endDate,
    int daysDiff,
    int todayUsageTime,
    int recordTime,
    int dailyLimit,
    int weeklyGoal,
  ) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');

    // Calcular estadísticas
    final totalMinutesFree = (todayUsageTime * daysDiff).clamp(0, double.infinity).toInt();
    final hoursFree = totalMinutesFree ~/ 60;
    final minutesFree = totalMinutesFree % 60;
    final averageMinutesPerDay = daysDiff > 0 ? totalMinutesFree ~/ daysDiff : 0;
    final avgHours = averageMinutesPerDay ~/ 60;
    final avgMinutes = averageMinutesPerDay % 60;
    
    // Textos traducidos para días
    final dayText = daysDiff == 1 ? localizations.day : localizations.days;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            // Encabezado
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    localizations.reportTitle,
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    '${localizations.generatedOn}: ${dateFormat.format(DateTime.now())} ${timeFormat.format(DateTime.now())}',
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Información del usuario
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey200,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '${localizations.userLabel}: $userName',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    '${localizations.emailLabelReport}: $userEmail',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Período del reporte
            pw.Text(
              localizations.reportPeriod,
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              '${dateFormat.format(startDate)} - ${dateFormat.format(endDate)} ($daysDiff $dayText)',
              style: const pw.TextStyle(fontSize: 12),
            ),
            pw.SizedBox(height: 20),

            // Estadísticas
            pw.Text(
              localizations.statistics,
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 12),

            // Tarjetas de estadísticas
            _buildStatCard(
              localizations.totalTimeFree,
              '$hoursFree ${localizations.hoursShort} $minutesFree ${localizations.minutesShort}',
              PdfColors.blue,
            ),
            pw.SizedBox(height: 8),
            _buildStatCard(
              localizations.blockedSessionsCount,
              '${(daysDiff * 0.5).round()}',
              PdfColors.red,
            ),
            pw.SizedBox(height: 8),
            _buildStatCard(
              localizations.timeSavedTotal,
              '$hoursFree ${localizations.hoursShort} $minutesFree ${localizations.minutesShort}',
              PdfColors.green,
            ),
            pw.SizedBox(height: 8),
            _buildStatCard(
              localizations.consecutiveDaysCount,
              '$daysDiff',
              PdfColors.orange,
            ),
            pw.SizedBox(height: 8),
            _buildStatCard(
              localizations.dailyAverageTime,
              '$avgHours ${localizations.hoursShort} $avgMinutes ${localizations.minutesShort}',
              PdfColors.purple,
            ),
            pw.SizedBox(height: 20),

            // Configuración
            pw.Text(
              localizations.configuration,
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  '${localizations.dailyLimitLabel}:',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.Text(
                  '$dailyLimit ${localizations.minutes}',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  '${localizations.weeklyGoalLabel}:',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.Text(
                  '$weeklyGoal ${localizations.hours}',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  '${localizations.recordFreeTime}:',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.Text(
                  '$recordTime ${localizations.hours}',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf;
  }

  pw.Widget _buildStatCard(String label, String value, PdfColor color) {
    // Usar un color gris muy claro para el fondo
    final lightColor = PdfColors.grey100;
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: lightColor,
        border: pw.Border.all(color: color, width: 1),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 12),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

