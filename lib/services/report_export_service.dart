import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ReportExportService {
  Future<ReportExportResult> exportBundlePdf(
    ReportExportBundleDocument document,
  ) async {
    final Uint8List bytes = await buildBundlePdf(document);
    final String baseName = document.exportFileBaseName;

    String? savedPath;
    try {
      savedPath = await FileSaver.instance.saveAs(
        name: baseName,
        bytes: bytes,
        fileExtension: 'pdf',
        mimeType: MimeType.pdf,
      );
    } catch (_) {
      savedPath = null;
    }

    savedPath ??= await FileSaver.instance.saveFile(
      name: baseName,
      bytes: bytes,
      fileExtension: 'pdf',
      mimeType: MimeType.pdf,
    );

    final String trimmedPath = savedPath.trim();
    if (trimmedPath.isEmpty ||
        trimmedPath.toLowerCase().contains('something went wrong')) {
      throw Exception('Unable to save the generated PDF.');
    }

    return ReportExportResult(
      fileName: '$baseName.pdf',
      savedPath: trimmedPath,
    );
  }

  Future<Uint8List> buildBundlePdf(ReportExportBundleDocument document) async {
    final pw.Document pdf = pw.Document(
      title: '${document.label} Report',
      author: 'AviSlap',
      subject: '${document.label} export report',
      creator: 'AviSlap Flutter App',
    );

    final pw.ThemeData theme = pw.ThemeData.withFont(
      base: pw.Font.helvetica(),
      bold: pw.Font.helveticaBold(),
      italic: pw.Font.helveticaOblique(),
      boldItalic: pw.Font.helveticaBoldOblique(),
    );

    final PdfColor accent = _pdfColor(document.accentColorValue);
    final PdfColor accentSoft = _softenedColor(document.accentColorValue, 0.90);
    final PdfColor accentMuted = _softenedColor(
      document.accentColorValue,
      0.96,
    );
    final PdfColor ink = PdfColor.fromInt(0xFF0F172A);
    final PdfColor muted = PdfColor.fromInt(0xFF64748B);
    final PdfColor border = PdfColor.fromInt(0xFFE2E8F0);
    final PdfColor surface = PdfColor.fromInt(0xFFF8FAFC);
    final PdfColor green = PdfColor.fromInt(0xFF16A34A);
    final PdfColor greenSoft = PdfColor.fromInt(0xFFDCFCE7);
    final PdfColor red = PdfColor.fromInt(0xFFDC2626);
    final PdfColor redSoft = PdfColor.fromInt(0xFFFEE2E2);

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          theme: theme,
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.fromLTRB(28, 28, 28, 30),
        ),
        footer: (pw.Context context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: <pw.Widget>[
            pw.Text(
              'Generated ${document.generatedAtLabel}',
              style: pw.TextStyle(fontSize: 9, color: muted),
            ),
            pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: pw.TextStyle(fontSize: 9, color: muted),
            ),
          ],
        ),
        build: (pw.Context context) => <pw.Widget>[
          pw.Container(
            padding: const pw.EdgeInsets.all(22),
            decoration: pw.BoxDecoration(
              color: accent,
              borderRadius: pw.BorderRadius.circular(20),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: <pw.Widget>[
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: <pw.Widget>[
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: <pw.Widget>[
                          pw.Text(
                            document.label,
                            style: pw.TextStyle(
                              fontSize: 22,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                            ),
                          ),
                          pw.SizedBox(height: 6),
                          pw.Text(
                            'Operational report export',
                            style: pw.TextStyle(
                              fontSize: 10.5,
                              color: PdfColors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        borderRadius: pw.BorderRadius.circular(999),
                      ),
                      child: pw.Text(
                        '${document.summary.passRate}% pass rate',
                        style: pw.TextStyle(
                          fontSize: 10.5,
                          fontWeight: pw.FontWeight.bold,
                          color: accent,
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 12),
                pw.Text(
                  document.subtitle,
                  style: pw.TextStyle(
                    fontSize: 11.3,
                    color: PdfColors.white,
                    lineSpacing: 2,
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <pw.Widget>[
                    _metaChip(
                      label: 'Coverage: ${document.dateRangeLabel}',
                      background: PdfColors.white,
                      foreground: accent,
                    ),
                    if (document.stationId?.trim().isNotEmpty == true)
                      _metaChip(
                        label: 'Station ${document.stationId!.trim()}',
                        background: PdfColors.white,
                        foreground: accent,
                      ),
                    _metaChip(
                      label: '${document.metrics.length} report sections',
                      background: PdfColors.white,
                      foreground: accent,
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 18),
          pw.Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <pw.Widget>[
              _metricSummaryCard(
                width: 236,
                title: 'Audits reviewed',
                value: document.auditCount.toString(),
                subtitle: 'Submitted audit records in this export',
                background: surface,
                valueColor: ink,
                border: border,
              ),
              _metricSummaryCard(
                width: 236,
                title: 'Passed checks',
                value:
                    '${document.summary.passCount} (${document.summary.passRate}%)',
                subtitle: 'Pass outcomes across the selected report',
                background: greenSoft,
                valueColor: green,
                border: greenSoft,
              ),
              _metricSummaryCard(
                width: 236,
                title: 'Failed checks',
                value:
                    '${document.summary.failCount} (${document.summary.failRate}%)',
                subtitle: 'Findings that need follow-up attention',
                background: redSoft,
                valueColor: red,
                border: redSoft,
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: surface,
              borderRadius: pw.BorderRadius.circular(16),
              border: pw.Border.all(color: border),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: <pw.Widget>[
                pw.Text(
                  'Focus note',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: muted,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  document.watchLabel,
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: ink,
                  ),
                ),
                pw.SizedBox(height: 10),
                _buildPassFailBar(
                  summary: document.summary,
                  passColor: green,
                  failColor: red,
                  background: border,
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 18),
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: accentMuted,
              borderRadius: pw.BorderRadius.circular(16),
              border: pw.Border.all(color: accentSoft),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: <pw.Widget>[
                pw.Text(
                  'Label guide',
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                    color: ink,
                  ),
                ),
                pw.SizedBox(height: 10),
                _guideRow(
                  label: 'Area',
                  description: document.areaMeaning,
                  ink: ink,
                  muted: muted,
                ),
                pw.SizedBox(height: 8),
                _guideRow(
                  label: 'Section',
                  description: document.sectionMeaning,
                  ink: ink,
                  muted: muted,
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 22),
          pw.Text(
            'Report breakdown',
            style: pw.TextStyle(
              fontSize: 17,
              fontWeight: pw.FontWeight.bold,
              color: ink,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Each section below summarizes the live backend data returned for this report bundle.',
            style: pw.TextStyle(fontSize: 10.8, color: muted, lineSpacing: 2),
          ),
          pw.SizedBox(height: 14),
          ...document.metrics.expand((ReportExportMetricSection metric) sync* {
            yield pw.NewPage(
              freeSpace: metric.items.isNotEmpty || metric.topItems.isNotEmpty
                  ? 180
                  : 120,
            );
            yield _metricHeader(
              metric: metric,
              ink: ink,
              muted: muted,
              border: border,
            );

            if (!metric.available) {
              yield pw.SizedBox(height: 10);
              yield _emptyMetricNotice(
                message: metric.note,
                border: border,
                surface: surface,
                muted: muted,
              );
              yield pw.SizedBox(height: 16);
              return;
            }

            yield pw.SizedBox(height: 10);
            yield pw.Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <pw.Widget>[
                _metricSummaryCard(
                  width: 236,
                  title: 'Pass',
                  value: metric.summary.passCount.toString(),
                  subtitle: '${metric.summary.passRate}% of total',
                  background: greenSoft,
                  valueColor: green,
                  border: greenSoft,
                ),
                _metricSummaryCard(
                  width: 236,
                  title: 'Fail',
                  value: metric.summary.failCount.toString(),
                  subtitle: '${metric.summary.failRate}% of total',
                  background: redSoft,
                  valueColor: red,
                  border: redSoft,
                ),
                _metricSummaryCard(
                  width: 236,
                  title: 'Total',
                  value: metric.summary.totalCount.toString(),
                  subtitle: 'Measured results in this section',
                  background: surface,
                  valueColor: ink,
                  border: border,
                ),
              ],
            );
            yield pw.SizedBox(height: 10);
            yield _buildPassFailBar(
              summary: metric.summary,
              passColor: green,
              failColor: red,
              background: border,
            );
            yield pw.SizedBox(height: 10);
            yield pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: accentMuted,
                borderRadius: pw.BorderRadius.circular(14),
                border: pw.Border.all(color: accentSoft),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: <pw.Widget>[
                  pw.Text(
                    metric.highlightTitle,
                    style: pw.TextStyle(
                      fontSize: 10.5,
                      fontWeight: pw.FontWeight.bold,
                      color: accent,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    metric.highlightValue,
                    style: pw.TextStyle(
                      fontSize: 11.8,
                      fontWeight: pw.FontWeight.bold,
                      color: ink,
                      lineSpacing: 2,
                    ),
                  ),
                ],
              ),
            );

            if (metric.topItems.isNotEmpty) {
              yield pw.SizedBox(height: 10);
              yield _attentionList(
                title: 'Top attention items',
                items: metric.topItems,
                surface: surface,
                border: border,
                ink: ink,
                muted: muted,
                alert: red,
              );
            }

            if (metric.items.isNotEmpty) {
              yield pw.SizedBox(height: 12);
              yield pw.TableHelper.fromTextArray(
                headers: const <String>[
                  'Item',
                  'Pass',
                  'Fail',
                  'Total',
                  'Pass %',
                  'Fail %',
                ],
                data: metric.items
                    .map(
                      (ReportExportDistributionItem item) => <String>[
                        item.label,
                        item.passCount.toString(),
                        item.failCount.toString(),
                        item.totalCount.toString(),
                        '${item.passRate}%',
                        '${item.failRate}%',
                      ],
                    )
                    .toList(),
                headerStyle: pw.TextStyle(
                  fontSize: 10.2,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: pw.BoxDecoration(color: accent),
                cellStyle: pw.TextStyle(fontSize: 9.8, color: ink),
                cellAlignments: const <int, pw.Alignment>{
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.center,
                  2: pw.Alignment.center,
                  3: pw.Alignment.center,
                  4: pw.Alignment.center,
                  5: pw.Alignment.center,
                },
                columnWidths: <int, pw.TableColumnWidth>{
                  0: const pw.FlexColumnWidth(5.6),
                  1: const pw.FlexColumnWidth(1.1),
                  2: const pw.FlexColumnWidth(1.1),
                  3: const pw.FlexColumnWidth(1.1),
                  4: const pw.FlexColumnWidth(1),
                  5: const pw.FlexColumnWidth(1),
                },
                border: null,
                cellPadding: const pw.EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 8,
                ),
                oddRowDecoration: pw.BoxDecoration(color: PdfColors.white),
                rowDecoration: pw.BoxDecoration(color: surface),
                textStyleBuilder: (int index, dynamic _, int rowNum) {
                  if (index == 0) {
                    return pw.TextStyle(
                      fontSize: 9.8,
                      fontWeight: pw.FontWeight.bold,
                      color: ink,
                    );
                  }

                  return pw.TextStyle(fontSize: 9.4, color: ink);
                },
              );
            }

            yield pw.SizedBox(height: 18);
          }),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _metricHeader({
    required ReportExportMetricSection metric,
    required PdfColor ink,
    required PdfColor muted,
    required PdfColor border,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(16),
        border: pw.Border.all(color: border),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: <pw.Widget>[
              pw.Expanded(
                child: pw.Text(
                  metric.title,
                  style: pw.TextStyle(
                    fontSize: 14.5,
                    fontWeight: pw.FontWeight.bold,
                    color: ink,
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              _metaChip(
                label: metric.available ? 'Live data' : 'No data',
                background: metric.available
                    ? PdfColor.fromInt(0xFFDCFCE7)
                    : PdfColor.fromInt(0xFFF8FAFC),
                foreground: metric.available
                    ? PdfColor.fromInt(0xFF166534)
                    : muted,
                border: metric.available
                    ? PdfColor.fromInt(0xFFDCFCE7)
                    : border,
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            metric.subtitle,
            style: pw.TextStyle(fontSize: 10.6, color: muted, lineSpacing: 2),
          ),
        ],
      ),
    );
  }

  pw.Widget _metricSummaryCard({
    required double width,
    required String title,
    required String value,
    required String subtitle,
    required PdfColor background,
    required PdfColor valueColor,
    required PdfColor border,
  }) {
    return pw.SizedBox(
      width: width,
      child: pw.Container(
        padding: const pw.EdgeInsets.all(14),
        decoration: pw.BoxDecoration(
          color: background,
          borderRadius: pw.BorderRadius.circular(16),
          border: pw.Border.all(color: border),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: <pw.Widget>[
            pw.Text(
              title,
              style: pw.TextStyle(fontSize: 10.5, color: valueColor),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: valueColor,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              subtitle,
              style: pw.TextStyle(fontSize: 9.6, color: valueColor),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _attentionList({
    required String title,
    required List<ReportExportDistributionItem> items,
    required PdfColor surface,
    required PdfColor border,
    required PdfColor ink,
    required PdfColor muted,
    required PdfColor alert,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: surface,
        borderRadius: pw.BorderRadius.circular(14),
        border: pw.Border.all(color: border),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 10.8,
              fontWeight: pw.FontWeight.bold,
              color: ink,
            ),
          ),
          pw.SizedBox(height: 10),
          ...items.asMap().entries.map((entry) {
            final int index = entry.key;
            final ReportExportDistributionItem item = entry.value;

            return pw.Padding(
              padding: pw.EdgeInsets.only(
                bottom: index == items.length - 1 ? 0 : 8,
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: <pw.Widget>[
                  pw.Container(
                    width: 20,
                    height: 20,
                    alignment: pw.Alignment.center,
                    decoration: pw.BoxDecoration(
                      color: alert,
                      borderRadius: pw.BorderRadius.circular(999),
                    ),
                    child: pw.Text(
                      '${index + 1}',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: <pw.Widget>[
                        pw.Text(
                          item.label,
                          style: pw.TextStyle(
                            fontSize: 10.6,
                            fontWeight: pw.FontWeight.bold,
                            color: ink,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          '${item.failRate}% fail rate • ${item.failCount} fail / ${item.totalCount} total',
                          style: pw.TextStyle(fontSize: 9.6, color: muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  pw.Widget _emptyMetricNotice({
    required String message,
    required PdfColor border,
    required PdfColor surface,
    required PdfColor muted,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: surface,
        borderRadius: pw.BorderRadius.circular(14),
        border: pw.Border.all(color: border),
      ),
      child: pw.Text(
        message,
        style: pw.TextStyle(fontSize: 10.6, color: muted, lineSpacing: 2),
      ),
    );
  }

  pw.Widget _buildPassFailBar({
    required ReportExportRatioSummary summary,
    required PdfColor passColor,
    required PdfColor failColor,
    required PdfColor background,
  }) {
    if (summary.totalCount <= 0) {
      return pw.Container(
        height: 10,
        decoration: pw.BoxDecoration(
          color: background,
          borderRadius: pw.BorderRadius.circular(999),
        ),
      );
    }

    if (summary.failCount <= 0) {
      return pw.Container(
        height: 10,
        decoration: pw.BoxDecoration(
          color: passColor,
          borderRadius: pw.BorderRadius.circular(999),
        ),
      );
    }

    if (summary.passCount <= 0) {
      return pw.Container(
        height: 10,
        decoration: pw.BoxDecoration(
          color: failColor,
          borderRadius: pw.BorderRadius.circular(999),
        ),
      );
    }

    return pw.ClipRRect(
      horizontalRadius: 999,
      verticalRadius: 999,
      child: pw.Container(
        height: 10,
        decoration: pw.BoxDecoration(color: background),
        child: pw.Row(
          children: <pw.Widget>[
            pw.Expanded(
              flex: summary.passCount,
              child: pw.Container(color: passColor),
            ),
            pw.Expanded(
              flex: summary.failCount,
              child: pw.Container(color: failColor),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _guideRow({
    required String label,
    required String description,
    required PdfColor ink,
    required PdfColor muted,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        pw.SizedBox(
          width: 52,
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10.6,
              fontWeight: pw.FontWeight.bold,
              color: ink,
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            description,
            style: pw.TextStyle(fontSize: 10.4, color: muted, lineSpacing: 2),
          ),
        ),
      ],
    );
  }

  pw.Widget _metaChip({
    required String label,
    required PdfColor background,
    required PdfColor foreground,
    PdfColor? border,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: pw.BoxDecoration(
        color: background,
        borderRadius: pw.BorderRadius.circular(999),
        border: border == null ? null : pw.Border.all(color: border),
      ),
      child: pw.Text(
        label,
        style: pw.TextStyle(
          fontSize: 9.8,
          fontWeight: pw.FontWeight.bold,
          color: foreground,
        ),
      ),
    );
  }
}

class ReportExportBundleDocument {
  const ReportExportBundleDocument({
    required this.bundleKey,
    required this.label,
    required this.subtitle,
    required this.areaMeaning,
    required this.sectionMeaning,
    required this.accentColorValue,
    required this.auditCount,
    required this.watchLabel,
    required this.summary,
    required this.metrics,
    required this.generatedAt,
    required this.stationId,
    required this.fromDate,
    required this.toDate,
  });

  factory ReportExportBundleDocument.fromOverview({
    required Map<String, dynamic> overview,
    required String bundleKey,
    required String fallbackTitle,
    required String fallbackSubtitle,
    required String areaMeaning,
    required String sectionMeaning,
    required int accentColorValue,
  }) {
    final Map<String, dynamic> bundleMap = _asMap(
      _asMap(overview['bundles'])[bundleKey],
    );
    final ReportExportRatioSummary summary = ReportExportRatioSummary.fromMap(
      bundleMap,
    );
    final List<ReportExportMetricSection> metrics =
        (bundleMap['metrics'] as List? ?? const <dynamic>[])
            .map(
              (dynamic entry) =>
                  ReportExportMetricSection.fromMap(_asMap(entry)),
            )
            .toList();

    return ReportExportBundleDocument(
      bundleKey: bundleKey,
      label: _stringOrFallback(bundleMap['label'], fallbackTitle),
      subtitle: fallbackSubtitle,
      areaMeaning: areaMeaning,
      sectionMeaning: sectionMeaning,
      accentColorValue: accentColorValue,
      auditCount: _toInt(bundleMap['auditCount']),
      watchLabel: _stringOrFallback(
        bundleMap['watchLabel'],
        'No issues flagged',
      ),
      summary: summary,
      metrics: metrics,
      generatedAt: DateTime.tryParse(
        overview['generatedAt']?.toString() ?? '',
      )?.toLocal(),
      stationId: overview['stationId']?.toString().trim(),
      fromDate: _readDateString(_asMap(overview['filters'])['fromDate']),
      toDate: _readDateString(_asMap(overview['filters'])['toDate']),
    );
  }

  final String bundleKey;
  final String label;
  final String subtitle;
  final String areaMeaning;
  final String sectionMeaning;
  final int accentColorValue;
  final int auditCount;
  final String watchLabel;
  final ReportExportRatioSummary summary;
  final List<ReportExportMetricSection> metrics;
  final DateTime? generatedAt;
  final String? stationId;
  final String? fromDate;
  final String? toDate;

  bool get hasData => auditCount > 0 || summary.totalCount > 0;

  String get generatedAtLabel {
    final DateTime timestamp = generatedAt ?? DateTime.now();
    return DateFormat('MMM d, yyyy  h:mm a').format(timestamp);
  }

  String get dateRangeLabel {
    final DateFormat formatter = DateFormat('MMM d, yyyy');
    final DateTime? from = DateTime.tryParse(fromDate ?? '')?.toLocal();
    final DateTime? to = DateTime.tryParse(toDate ?? '')?.toLocal();

    if (from != null && to != null) {
      return '${formatter.format(from)} to ${formatter.format(to)}';
    }
    if (from != null) {
      return 'From ${formatter.format(from)}';
    }
    if (to != null) {
      return 'Until ${formatter.format(to)}';
    }
    return 'All available dates';
  }

  String get exportFileBaseName {
    final DateTime timestamp = generatedAt ?? DateTime.now();
    final String slug = label
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');

    return '${slug.isEmpty ? bundleKey : slug}-report-${DateFormat('yyyyMMdd_HHmm').format(timestamp)}';
  }
}

class ReportExportMetricSection {
  const ReportExportMetricSection({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.available,
    required this.note,
    required this.summary,
    required this.highlightTitle,
    required this.highlightValue,
    required this.items,
    required this.topItems,
  });

  factory ReportExportMetricSection.fromMap(Map<String, dynamic> map) {
    final List<ReportExportDistributionItem> items =
        (map['items'] as List? ?? const <dynamic>[])
            .map(
              (dynamic entry) =>
                  ReportExportDistributionItem.fromMap(_asMap(entry)),
            )
            .where(
              (ReportExportDistributionItem item) =>
                  item.label.trim().isNotEmpty && item.totalCount > 0,
            )
            .toList();
    final List<ReportExportDistributionItem> topItems =
        (map['topItems'] as List? ?? const <dynamic>[])
            .map(
              (dynamic entry) =>
                  ReportExportDistributionItem.fromMap(_asMap(entry)),
            )
            .where(
              (ReportExportDistributionItem item) =>
                  item.label.trim().isNotEmpty && item.totalCount > 0,
            )
            .toList();

    return ReportExportMetricSection(
      key: _stringOrFallback(map['key'], 'metric'),
      title: _stringOrFallback(map['title'], 'Report metric'),
      subtitle: _stringOrFallback(map['subtitle'], ''),
      available: map['available'] == true,
      note: _stringOrFallback(map['note'], 'No live data available yet.'),
      summary: ReportExportRatioSummary.fromMap(_asMap(map['summary'])),
      highlightTitle: _stringOrFallback(map['highlightTitle'], 'Current read'),
      highlightValue: _stringOrFallback(
        map['highlightValue'],
        'No live data available yet.',
      ),
      items: items,
      topItems: topItems.isNotEmpty ? topItems : items.take(3).toList(),
    );
  }

  final String key;
  final String title;
  final String subtitle;
  final bool available;
  final String note;
  final ReportExportRatioSummary summary;
  final String highlightTitle;
  final String highlightValue;
  final List<ReportExportDistributionItem> items;
  final List<ReportExportDistributionItem> topItems;
}

class ReportExportRatioSummary {
  const ReportExportRatioSummary({
    required this.passCount,
    required this.failCount,
    required this.totalCount,
    required this.passRate,
    required this.failRate,
  });

  factory ReportExportRatioSummary.fromMap(Map<String, dynamic> map) {
    final int passCount = _toInt(map['passCount']);
    final int failCount = _toInt(map['failCount']);
    final int totalCount = _toInt(map['totalCount']) == 0
        ? passCount + failCount
        : _toInt(map['totalCount']);

    return ReportExportRatioSummary(
      passCount: passCount,
      failCount: failCount,
      totalCount: totalCount,
      passRate: _toInt(map['passRate']),
      failRate: _toInt(map['failRate']),
    );
  }

  final int passCount;
  final int failCount;
  final int totalCount;
  final int passRate;
  final int failRate;
}

class ReportExportDistributionItem extends ReportExportRatioSummary {
  const ReportExportDistributionItem({
    required this.label,
    required super.passCount,
    required super.failCount,
    required super.totalCount,
    required super.passRate,
    required super.failRate,
  });

  factory ReportExportDistributionItem.fromMap(Map<String, dynamic> map) {
    final ReportExportRatioSummary summary = ReportExportRatioSummary.fromMap(
      map,
    );
    return ReportExportDistributionItem(
      label: _stringOrFallback(map['label'], 'Unknown'),
      passCount: summary.passCount,
      failCount: summary.failCount,
      totalCount: summary.totalCount,
      passRate: summary.passRate,
      failRate: summary.failRate,
    );
  }

  final String label;
}

class ReportExportResult {
  const ReportExportResult({required this.fileName, required this.savedPath});

  final String fileName;
  final String? savedPath;
}

PdfColor _pdfColor(int value) => PdfColor.fromInt(value);

PdfColor _softenedColor(int colorValue, double mix) {
  final int red = (colorValue >> 16) & 0xFF;
  final int green = (colorValue >> 8) & 0xFF;
  final int blue = colorValue & 0xFF;

  int soften(int channel) => (channel + ((255 - channel) * mix)).round();

  return PdfColor.fromInt(
    (0xFF << 24) | (soften(red) << 16) | (soften(green) << 8) | soften(blue),
  );
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map(
      (dynamic key, dynamic entry) => MapEntry(key.toString(), entry),
    );
  }
  return const <String, dynamic>{};
}

int _toInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.round();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _stringOrFallback(dynamic value, String fallback) {
  final String text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

String? _readDateString(dynamic value) {
  final String text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}
