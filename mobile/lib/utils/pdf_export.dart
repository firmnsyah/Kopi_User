import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../data/repository.dart';
import '../models/transaction.dart';
import 'formatters.dart';

class PdfExport {
  PdfExport._();

  static String _filterLabel(HistoryFilter f) => switch (f) {
        HistoryFilter.today => 'Hari Ini',
        HistoryFilter.month => 'Bulan Ini',
        HistoryFilter.all => 'Keseluruhan',
        HistoryFilter.custom => 'Custom',
      };

  static Future<void> shareHistoryAsPdf({
    required HistoryFilter filter,
    required List<Transaction> transactions,
    DateTime? customStart,
    DateTime? customEnd,
  }) async {
    final fontRegular = await PdfGoogleFonts.openSansRegular();
    final fontBold = await PdfGoogleFonts.openSansBold();

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: fontRegular,
        bold: fontBold,
      ),
    );
    final now = DateTime.now();

    int totalIncome = 0, totalExpense = 0;
    for (final t in transactions) {
      if (t.type == TxType.income) {
        totalIncome += t.amount;
      } else {
        totalExpense += t.amount;
      }
    }
    final profit = totalIncome - totalExpense;

    String periodeText = _filterLabel(filter);
    if (filter == HistoryFilter.custom &&
        customStart != null &&
        customEnd != null) {
      periodeText =
          '${formatDateDMY(customStart)} – ${formatDateDMY(customEnd)}';
    } else if (filter == HistoryFilter.today) {
      periodeText = 'Hari Ini (${formatDateDMY(now)})';
    } else if (filter == HistoryFilter.month) {
      periodeText = 'Bulan ${monthNames[now.month - 1]} ${now.year}';
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (ctx) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 12),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom:
                  pw.BorderSide(color: PdfColor.fromInt(0xFF223628), width: 2),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Kopi User',
                      style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: const PdfColor.fromInt(0xFF223628))),
                  pw.Text('Laporan Riwayat Transaksi',
                      style: const pw.TextStyle(
                          fontSize: 11, color: PdfColor.fromInt(0xFF3D3733))),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Periode: $periodeText',
                      style: pw.TextStyle(
                          fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Dicetak: ${formatDateDMY(now)} ${formatTimeHM(now)}',
                      style: const pw.TextStyle(
                          fontSize: 9, color: PdfColor.fromInt(0xFF666666))),
                ],
              ),
            ],
          ),
        ),
        footer: (ctx) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 12),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Kopi User POS',
                  style: const pw.TextStyle(
                      fontSize: 9, color: PdfColor.fromInt(0xFF888888))),
              pw.Text('Halaman ${ctx.pageNumber} / ${ctx.pagesCount}',
                  style: const pw.TextStyle(
                      fontSize: 9, color: PdfColor.fromInt(0xFF888888))),
            ],
          ),
        ),
        build: (ctx) => [
          pw.SizedBox(height: 16),
          _summaryCards(totalIncome, totalExpense, profit, transactions.length),
          pw.SizedBox(height: 20),
          _txTable(transactions),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename:
          'kopi_user_riwayat_${filter.name}_${now.millisecondsSinceEpoch}.pdf',
    );
  }

  static pw.Widget _summaryCards(int income, int expense, int profit, int n) {
    pw.Widget card(String label, String value, PdfColor color) {
      return pw.Expanded(
        child: pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: color,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(label,
                  style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white)),
              pw.SizedBox(height: 4),
              pw.Text(value,
                  style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white)),
            ],
          ),
        ),
      );
    }

    return pw.Row(
      children: [
        card('PEMASUKAN', formatRupiah(income),
            const PdfColor.fromInt(0xFF2D6A3E)),
        pw.SizedBox(width: 8),
        card('PENGELUARAN', formatRupiah(expense),
            const PdfColor.fromInt(0xFF8B6F3F)),
        pw.SizedBox(width: 8),
        card(
            profit < 0 ? 'RUGI' : 'PROFIT',
            formatRupiah(profit.abs()),
            profit < 0
                ? const PdfColor.fromInt(0xFFB23A3A)
                : const PdfColor.fromInt(0xFF1A5276)),
        pw.SizedBox(width: 8),
        card('TRANSAKSI', '$n', const PdfColor.fromInt(0xFF3D3733)),
      ],
    );
  }

  static pw.Widget _txTable(List<Transaction> txs) {
    final headers = [
      'ID',
      'Tanggal',
      'Waktu',
      'Tipe',
      'Kategori',
      'Metode',
      'Nominal',
    ];
    final data = txs.map((t) {
      final sign = t.type == TxType.income ? '+' : '-';
      return [
        t.id,
        formatDateDMY(t.createdAt),
        formatTimeHM(t.createdAt),
        t.tipeLabel,
        t.category.isEmpty ? '-' : t.category,
        t.method,
        '$sign${formatRupiah(t.amount)}',
      ];
    }).toList();

    if (data.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(20),
        alignment: pw.Alignment.center,
        child: pw.Text('Tidak ada transaksi pada periode ini.',
            style: const pw.TextStyle(
                fontSize: 11, color: PdfColor.fromInt(0xFF888888))),
      );
    }

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      cellAlignment: pw.Alignment.centerLeft,
      cellAlignments: {
        6: pw.Alignment.centerRight,
      },
      headerStyle: pw.TextStyle(
          fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(
        color: PdfColor.fromInt(0xFF223628),
      ),
      cellStyle: const pw.TextStyle(fontSize: 9),
      oddCellStyle: const pw.TextStyle(
        fontSize: 9,
        color: PdfColor.fromInt(0xFF1E1B17),
      ),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      columnWidths: {
        0: const pw.IntrinsicColumnWidth(),
        1: const pw.IntrinsicColumnWidth(),
        2: const pw.IntrinsicColumnWidth(),
        3: const pw.IntrinsicColumnWidth(),
        4: const pw.FlexColumnWidth(),
        5: const pw.IntrinsicColumnWidth(),
        6: const pw.IntrinsicColumnWidth(),
      },
      border: pw.TableBorder.all(
          color: const PdfColor.fromInt(0xFFDDDDDD), width: 0.5),
    );
  }
}
