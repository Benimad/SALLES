import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../models/demande.dart';

class PdfService {
  Future<void> generateDemandePdf(Demande demande) async {
    final pdf = pw.Document();
    final logo = await imageFromAssetBundle('assets/images/logo.png');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header with Logo
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'GROUPE AL OMRANE',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromInt(0xFFE31E24),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Département Logistique et Moyens Généraux',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.Text(
                        'Système de Gestion des Salles',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                  pw.Container(
                    height: 60,
                    width: 60,
                    child: pw.Image(logo),
                  ),
                ],
              ),
              
              pw.SizedBox(height: 40),
              pw.Divider(thickness: 2, color: PdfColor.fromInt(0xFF006B3F)),
              pw.SizedBox(height: 20),
              
              pw.Center(
                child: pw.Text(
                  'CONFIRMATION DE RÉSERVATION',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    decoration: pw.TextDecoration.underline,
                  ),
                ),
              ),
              
              pw.SizedBox(height: 40),
              
              // Demand Details
              _buildSectionTitle('Informations Générales'),
              _buildDetailRow('N° de Demande', demande.id),
              _buildDetailRow('Statut', _getStatusText(demande.statut).toUpperCase()),
              _buildDetailRow('Date de Génération', DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.now())),
              
              pw.SizedBox(height: 24),
              
              _buildSectionTitle('Détails de la Réservation'),
              _buildDetailRow('Salle demandée', demande.salleName ?? 'N/A'),
              _buildDetailRow('Demandeur', demande.userName ?? 'N/A'),
              _buildDetailRow('Date', _formatDate(demande.dateDebut)),
              _buildDetailRow('Créneau Horaire', '${demande.heureDebut} - ${demande.heureFin}'),
              _buildDetailRow('Nombre de Participants', demande.participantsExternes.toString()),
              
              pw.SizedBox(height: 24),
              
              _buildSectionTitle('Objet de la Réunion'),
              pw.Padding(
                padding: const pw.EdgeInsets.only(left: 10, top: 8),
                child: pw.Text(
                  demande.motif,
                  style: pw.TextStyle(fontSize: 12, lineSpacing: 4),
                ),
              ),
              
              if (demande.description != null && demande.description!.isNotEmpty) ...[
                pw.SizedBox(height: 16),
                _buildSectionTitle('Observations'),
                pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 10, top: 8),
                  child: pw.Text(
                    demande.description!,
                    style: pw.TextStyle(fontSize: 11, fontStyle: pw.FontStyle.italic),
                  ),
                ),
              ],
              
              pw.Spacer(),
              
              // Footer
              pw.Divider(thickness: 0.5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Groupe Al Omrane - www.alomrane.gov.ma',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
                  ),
                  pw.Text(
                    'Page 1/1',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Reservation_${demande.id}.pdf',
    );
  }

  pw.Widget _buildSectionTitle(String title) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: const pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFF1F5F9),
      ),
      child: pw.Text(
        title.toUpperCase(),
        style: pw.TextStyle(
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
          color: PdfColor.fromInt(0xFF006B3F),
        ),
      ),
    );
  }

  pw.Widget _buildDetailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 150,
            child: pw.Text(
              '$label :',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMMM yyyy', 'fr_FR').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String _getStatusText(String statut) {
    switch (statut) {
      case 'approuvee':
        return 'Approuvée';
      case 'rejetee':
        return 'Rejetée';
      default:
        return 'En attente';
    }
  }

  Future<void> generateDemandesListPdf(List<Demande> demandes) async {
    final pdf = pw.Document();
    final logo = await imageFromAssetBundle('assets/images/logo.png');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (pw.Context context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('LISTE DES RÉSERVATIONS - AL OMRANE', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            pw.Container(height: 30, width: 30, child: pw.Image(logo)),
          ],
        ),
        build: (pw.Context context) => [
          pw.SizedBox(height: 20),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(1),
              1: const pw.FlexColumnWidth(3),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(2),
              4: const pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF006B3F)),
                children: ['ID', 'Salle', 'Date', 'Heure', 'Statut']
                    .map((h) => pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(h, style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10)),
                        ))
                    .toList(),
              ),
              ...demandes.map((d) => pw.TableRow(
                    children: [
                      d.id.length > 5 ? d.id.substring(0, 5) : d.id,
                      d.salleName ?? 'N/A',
                      d.dateDebut,
                      '${d.heureDebut}-${d.heureFin}',
                      _getStatusText(d.statut),
                    ]
                        .map((cell) => pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(cell, style: const pw.TextStyle(fontSize: 9)),
                            ))
                        .toList(),
                  )),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }
}
