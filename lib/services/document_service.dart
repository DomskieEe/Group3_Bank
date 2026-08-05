import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/app_user.dart';
import '../models/transaction_model.dart';

class DocumentService {
  static Future<void> printReceipt(TransactionModel transaction) async {
    final document = pw.Document();
    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        build: (_) => pw.Padding(
          padding: const pw.EdgeInsets.all(28),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Snap Wallet', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.Text('Transaction receipt'),
              pw.Divider(),
              _row('Reference', transaction.id),
              _row('Date', transaction.date),
              _row('Description', transaction.description),
              _row('Category', transaction.category.toUpperCase()),
              _row('Amount', 'PHP ${transaction.amount.toStringAsFixed(2)}'),
              if (transaction.note.isNotEmpty) _row('Note', transaction.note),
              pw.Spacer(),
              pw.Text('This is a demo receipt.', style: const pw.TextStyle(fontSize: 9)),
            ],
          ),
        ),
      ),
    );
    await Printing.layoutPdf(onLayout: (_) => document.save());
  }

  static Future<void> printMonthlyStatement({
    required AppUser user,
    required List<TransactionModel> transactions,
    required DateTime month,
  }) async {
    final document = pw.Document();
    final debit = transactions.where((tx) => tx.type == 'debit').fold<double>(0, (sum, tx) => sum + tx.amount);
    final credit = transactions.where((tx) => tx.type == 'credit').fold<double>(0, (sum, tx) => sum + tx.amount);
    document.addPage(
      pw.MultiPage(
        build: (_) => [
          pw.Text('Snap Wallet', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          pw.Text('Monthly statement: ${month.year}-${month.month.toString().padLeft(2, '0')}'),
          pw.SizedBox(height: 12),
          _row('Account holder', user.fullName),
          _row('Savings balance', 'PHP ${user.savingsBalance.toStringAsFixed(2)}'),
          _row('Checking balance', 'PHP ${user.checkingBalance.toStringAsFixed(2)}'),
          _row('Money in', 'PHP ${credit.toStringAsFixed(2)}'),
          _row('Money out', 'PHP ${debit.toStringAsFixed(2)}'),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: const ['Date', 'Description', 'Type', 'Amount'],
            data: transactions.map((tx) => [tx.date, tx.description, tx.type, 'PHP ${tx.amount.toStringAsFixed(2)}']).toList(),
          ),
        ],
      ),
    );
    await Printing.layoutPdf(onLayout: (_) => document.save());
  }

  static pw.Widget _row(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 8),
        child: pw.Row(children: [pw.SizedBox(width: 110, child: pw.Text(label)), pw.Expanded(child: pw.Text(value))]),
      );
}
