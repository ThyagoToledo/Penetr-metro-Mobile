import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../measurement/domain/entities/measurement.dart';
import '../../measurement/domain/entities/penetrometer_type.dart';

/// Gera o PDF de uma medição, reproduzindo o relatório do desktop
/// (cabeçalho institucional, dados, barra de resistência, diagnóstico,
/// interpretação e rodapé) — com barra vetorial no lugar do ASCII.
abstract final class PdfReportGenerator {
  static final _dateFmt = DateFormat('dd/MM/yyyy HH:mm');

  static Future<Uint8List> build(Measurement m) async {
    final doc = pw.Document();
    final isImpact = m.type == PenetrometerType.impact;
    final maxValue = isImpact ? 100.0 : 50.0;
    final color = _diagColor(m.coefficient);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _header(m, isImpact),
          pw.SizedBox(height: 16),
          _sectionTitle('INFORMAÇÕES DO COLETOR'),
          _kvTable({
            'Nome do Coletor': m.nameCollector ?? 'Não informado',
            'Local da Medição': m.place ?? 'Não informado',
            'Data da Medição':
                m.meteringDate != null ? _dateFmt.format(m.meteringDate!) : '-',
            'Coordenadas GPS':
                'Lat: ${m.latitude.toStringAsFixed(6)}, Long: ${m.longitude.toStringAsFixed(6)}',
          }),
          pw.SizedBox(height: 12),
          _sectionTitle('DADOS DA MEDIÇÃO'),
          _kvTable(
            isImpact
                ? {
                    'Número de Impactos': '${m.impactsQuantity} impactos',
                    'Profundidade': '${m.deep.toStringAsFixed(2)} cm',
                    'Coeficiente (R)':
                        '${m.coefficient.toStringAsFixed(4)} kgf/cm²',
                    'Fórmula Utilizada': 'R = 5.6 + 6.89 × N (Equação de Stolf)',
                  }
                : {
                    'Profundidade': '${m.deep.toStringAsFixed(2)} cm',
                    'Leitura': '${m.effectivePressureMpa.toStringAsFixed(2)} MPa',
                    'Coeficiente': '${m.coefficient.toStringAsFixed(4)} kgf/cm²',
                    'Conversão': '1 MPa = 10.1972 kgf/cm²',
                  },
          ),
          pw.SizedBox(height: 12),
          _sectionTitle('VISUALIZAÇÃO GRÁFICA'),
          _bar(m.coefficient, maxValue, color),
          pw.SizedBox(height: 12),
          _sectionTitle('DIAGNÓSTICO DO SOLO'),
          _diagnosisBox(m.floorResistance, color),
          pw.SizedBox(height: 8),
          pw.RichText(
            text: pw.TextSpan(
              children: [
                pw.TextSpan(
                  text: 'Interpretação: ',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.TextSpan(text: m.interpretation),
              ],
            ),
          ),
          pw.SizedBox(height: 24),
          _footer(),
        ],
      ),
    );

    return doc.save();
  }

  static pw.Widget _header(Measurement m, bool isImpact) {
    final subtitle = isImpact
        ? 'Penetrômetro de Impacto - Equação de Stolf'
        : 'Penetrômetro de Pressão - Conversão MPa para kgf/cm²';
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          'RELATÓRIO DE MEDIÇÃO',
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: const PdfColor.fromInt(0xFF2E7D32),
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(subtitle, style: const pw.TextStyle(fontSize: 12)),
        pw.SizedBox(height: 4),
        pw.Text(
          'Medição #${m.id ?? '-'} | Gerado em: ${_dateFmt.format(DateTime.now())}',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
        pw.Divider(color: PdfColors.grey400),
      ],
    );
  }

  static pw.Widget _sectionTitle(String title) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
            color: const PdfColor.fromInt(0xFF2E7D32),
          ),
        ),
      );

  static pw.Widget _kvTable(Map<String, String> data) {
    return pw.Table(
      columnWidths: const {
        0: pw.FlexColumnWidth(1),
        1: pw.FlexColumnWidth(2),
      },
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      children: data.entries.map((e) {
        return pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                e.key,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(e.value),
            ),
          ],
        );
      }).toList(),
    );
  }

  static pw.Widget _bar(double coefficient, double maxValue, PdfColor color) {
    final fraction = (coefficient / maxValue).clamp(0.0, 1.0);
    final filled = (fraction * 100).round().clamp(1, 100);
    final empty = 100 - filled;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          height: 18,
          child: pw.Row(
            children: [
              pw.Expanded(
                flex: filled,
                child: pw.Container(color: color),
              ),
              if (empty > 0)
                pw.Expanded(
                  flex: empty,
                  child: pw.Container(color: PdfColors.grey300),
                ),
            ],
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          '${coefficient.toStringAsFixed(2)} kgf/cm²  (escala 0 a ${maxValue.toStringAsFixed(0)})',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),
      ],
    );
  }

  static pw.Widget _diagnosisBox(String diagnosis, PdfColor color) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color, width: 1.5),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Center(
        child: pw.Text(
          diagnosis,
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
      ),
    );
  }

  static pw.Widget _footer() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Divider(color: PdfColors.grey400),
        pw.Text(
          'Gerado por: Sistema de Penetrometria - IF Goiano',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Documento gerado automaticamente. Os dados devem ser interpretados '
          'por profissionais qualificados.',
          textAlign: pw.TextAlign.center,
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
        ),
      ],
    );
  }

  static PdfColor _diagColor(double c) {
    if (c < 10) return const PdfColor.fromInt(0xFF2E7D32);
    if (c <= 20) return const PdfColor.fromInt(0xFF689F38);
    if (c <= 30) return const PdfColor.fromInt(0xFFF59E0B);
    if (c <= 40) return const PdfColor.fromInt(0xFFEF6C00);
    return const PdfColor.fromInt(0xFFD32F2F);
  }
}
