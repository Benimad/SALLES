import { jsPDF } from "jspdf";
import "jspdf-autotable";

export const generateAdminReport = (demandes) => {
  const doc = new jsPDF();

  // Header
  doc.setFillColor(26, 58, 92); // Navy
  doc.rect(0, 0, 210, 40, "F");
  
  doc.setTextColor(255, 255, 255);
  doc.setFontSize(22);
  doc.text("AL OMRANE - RAPPORT DE GESTION", 20, 25);
  
  doc.setFontSize(10);
  doc.text(`Généré le : ${new Date().toLocaleString()}`, 150, 32);

  // Stats
  const stats = {
    total: demandes.length,
    approved: demandes.filter(d => d.statut === 'approuvee').length,
    pending: demandes.filter(d => d.statut === 'en_attente').length
  };

  doc.setTextColor(0, 0, 0);
  doc.setFontSize(14);
  doc.text("Résumé de l'activité", 20, 55);
  
  doc.setFontSize(10);
  doc.text(`Total des demandes : ${stats.total}`, 20, 65);
  doc.text(`Demandes approuvées : ${stats.approved}`, 20, 72);
  doc.text(`Demandes en attente : ${stats.pending}`, 20, 79);

  // Table
  const tableData = demandes.map(d => [
    d.salle_name || "Salle",
    d.user_name || "N/A",
    `${d.date_debut} (${d.heure_debut}-${d.heure_fin})`,
    d.statut.toUpperCase().replace('_', ' ')
  ]);

  doc.autoTable({
    startY: 90,
    head: [['Salle', 'Demandeur', 'Date & Heure', 'Statut']],
    body: tableData,
    headStyles: { fillColor: [186, 0, 19] }, // Red
    theme: 'grid'
  });

  doc.save(`Rapport_AlOmrane_${new Date().getTime()}.pdf`);
};
