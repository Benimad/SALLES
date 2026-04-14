import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/demande.dart';

class PdfService {
  Future<void> generateDemandePdf(Demande demande) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Confirmation de Réservation',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Groupe Al Omrane',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.Divider(),
              pw.SizedBox(height: 20),
              _buildInfoRow('Numéro de demande', '#${demande.id}'),
              _buildInfoRow('Salle', demande.salleName ?? 'Salle #${demande.salleId}'),
              _buildInfoRow('Demandeur', demande.userName ?? 'Utilisateur #${demande.userId}'),
              pw.SizedBox(height: 10),
              _buildInfoRow(
                'Date de début',
                DateFormat('dd/MM/yyyy').format(DateTime.parse(demande.dateDebut)),
              ),
              _buildInfoRow(
                'Date de fin',
                DateFormat('dd/MM/yyyy').format(DateTime.parse(demande.dateFin)),
              ),
              _buildInfoRow('Heure de début', demande.heureDebut),
              _buildInfoRow('Heure de fin', demande.heureFin),
              pw.SizedBox(height: 10),
              _buildInfoRow('Motif', demande.motif),
              pw.SizedBox(height: 10),
              _buildInfoRow('Statut', _getStatusText(demande.statut)),
              pw.SizedBox(height: 40),
              pw.Text(
                'Ce document confirme votre réservation de salle.',
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Généré le ${DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.now())}',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 150,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value),
          ),
        ],
      ),
    );
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

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text(
                'Liste des Demandes de Réservation',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              headers: ['ID', 'Salle', 'Date', 'Statut'],
              data: demandes.map((d) => [
                d.id.toString(),
                d.salleName ?? 'Salle #${d.salleId}',
                DateFormat('dd/MM/yyyy').format(DateTime.parse(d.dateDebut)),
                _getStatusText(d.statut),
              ]).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignment: pw.Alignment.centerLeft,
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Total: ${demandes.length} demande(s)',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              'Généré le ${DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.now())}',
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}
