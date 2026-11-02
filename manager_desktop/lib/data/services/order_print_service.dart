import 'dart:convert';
import 'package:intl/intl.dart';

import '../../domain/models/manager_order.dart';
import 'order_print_launcher_stub.dart'
    if (dart.library.io) 'order_print_launcher_io.dart'
    if (dart.library.js_interop) 'order_print_launcher_web.dart';

/// Generates and prints amount-free order item sheets for the Orders page.
/// Strictly excludes all prices, subtotals, totals, and currency amounts,
/// clearly separates each item and its exact quantity when a customer orders
/// multiple different items, and consolidates the list onto a printable sheet.
class OrderPrintService {
  static const HtmlEscape _escape = HtmlEscape();

  static String _esc(String value) => _escape.convert(value);

  /// Builds a consolidated single-sheet HTML document containing ALL items
  /// from [orders], grouping multi-item orders via `rowspan` so each item's
  /// individual quantity (`Item 1 -> Qty`, `Item 2 -> Qty`) is unmistakably clear,
  /// with ZERO amounts or prices.
  static String buildOrdersPlacedItemsListHtml(
    List<ManagerOrder> orders, {
    required String branchName,
    required String scopeTitle,
  }) {
    final printedStr = DateFormat('MMM d, yyyy • HH:mm').format(DateTime.now());
    int totalLines = 0;
    int totalUnits = 0;

    final rowsBuffer = StringBuffer();
    for (var orderIndex = 0; orderIndex < orders.length; orderIndex++) {
      final order = orders[orderIndex];
      final cleanId = order.id.startsWith('ORDER_') ? order.id.substring(6) : order.id;
      final dateStr = DateFormat('MMM d, y HH:mm').format(order.date);
      final custName =
          order.customerName.trim().isNotEmpty ? order.customerName.trim() : 'Customer';
      final custPhone = order.customerPhone.trim();
      final gpsCode = order.gpsCode.trim().isNotEmpty ? order.gpsCode.trim() : '—';
      final address = order.deliveryAddress.trim();

      final effectiveItems = order.items.isNotEmpty
          ? order.items
          : [
              OrderItem(
                title: 'Device / Merchandise Order',
                brand: '',
                price: 0,
                quantity: order.status == OrderStatus.cancelled ? 0 : 1,
              ),
            ];

      final itemCount = effectiveItems.length;
      final isMultiItem = itemCount > 1;
      final orderTotalQty = effectiveItems.fold<int>(0, (s, it) => s + it.quantity);

      for (var itemIdx = 0; itemIdx < itemCount; itemIdx++) {
        final item = effectiveItems[itemIdx];
        totalLines += 1;
        totalUnits += item.quantity;

        final subMeta = [
          if (item.brand.trim().isNotEmpty) item.brand.trim(),
          if (item.specs.trim().isNotEmpty) item.specs.trim(),
        ].join(' • ');

        final rowClass = itemIdx == 0 ? 'order-start-row' : 'sub-item-row';
        final itemLabelPrefix = isMultiItem
            ? '<span class="item-step-badge">Item ${itemIdx + 1} of $itemCount</span> '
            : '';

        if (itemIdx == 0) {
          rowsBuffer.writeln('''
            <tr class="$rowClass">
              <td rowspan="$itemCount" class="center order-num-cell">${orderIndex + 1}</td>
              <td rowspan="$itemCount" class="order-group-cell">
                <div class="bold">${_esc(cleanId)}</div>
                <div class="muted">${_esc(dateStr)}</div>
                <div class="muted status-inline">${_esc(order.status.label)}</div>
                ${isMultiItem ? '<div class="multi-summary-pill">$itemCount Different Items • Order Qty: $orderTotalQty</div>' : ''}
              </td>
              <td rowspan="$itemCount" class="order-group-cell">
                <div class="bold">${_esc(custName)}</div>
                ${custPhone.isNotEmpty ? '<div class="muted">${_esc(custPhone)}</div>' : ''}
              </td>
              <td rowspan="$itemCount" class="order-group-cell">
                <div class="bold">${_esc(gpsCode)}</div>
                ${address.isNotEmpty ? '<div class="muted">${_esc(address)}</div>' : ''}
              </td>
              <td class="item-detail-cell">
                <div>$itemLabelPrefix<span class="bold">${_esc(item.title)}</span></div>
                ${subMeta.isNotEmpty ? '<div class="muted">${_esc(subMeta)}</div>' : ''}
              </td>
              <td class="center qty-col-cell">
                <div class="qty-pill">Qty: ${item.quantity}</div>
                ${isMultiItem ? '<div class="qty-sub-label">Item ${itemIdx + 1}</div>' : ''}
              </td>
              <td class="center check-col-cell"><span class="check-box"></span></td>
            </tr>
          ''');
        } else {
          rowsBuffer.writeln('''
            <tr class="$rowClass">
              <td class="item-detail-cell">
                <div>$itemLabelPrefix<span class="bold">${_esc(item.title)}</span></div>
                ${subMeta.isNotEmpty ? '<div class="muted">${_esc(subMeta)}</div>' : ''}
              </td>
              <td class="center qty-col-cell">
                <div class="qty-pill">Qty: ${item.quantity}</div>
                <div class="qty-sub-label">Item ${itemIdx + 1}</div>
              </td>
              <td class="center check-col-cell"><span class="check-box"></span></td>
            </tr>
          ''');
        }
      }
    }

    return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <title>Siaka Phones - Order Placed Items List</title>
  <style>${_oneSheetPrintCss()}</style>
</head>
<body>
  <div class="no-print toolbar">
    <div>
      <strong>Siaka Phones — Order Placed Items Sheet</strong> (${_esc(scopeTitle)} • No Amounts)
    </div>
    <button onclick="window.print()">Print Sheet</button>
  </div>

  <div class="sheet">
    <div class="header">
      <div>
        <div class="brand">SIAKA PHONES</div>
        <div class="subtitle">Order Placed — Consolidated List of Items &amp; Per-Item Quantities</div>
        <div class="meta-line">Branch: ${_esc(branchName)} • Scope: ${_esc(scopeTitle)}</div>
      </div>
      <div class="doc-badge">
        <div class="doc-title">ORDER ITEMS SHEET</div>
        <div class="meta-line">Printed: ${_esc(printedStr)}</div>
        <div class="meta-line">Orders: ${orders.length} • Distinct Item Lines: $totalLines • Total Units: $totalUnits</div>
      </div>
    </div>

    <table>
      <thead>
        <tr>
          <th style="width: 30px;" class="center">#</th>
          <th style="width: 118px;">ORDER ID &amp; DATE</th>
          <th style="width: 135px;">CUSTOMER</th>
          <th style="width: 155px;">GPS / ADDRESS</th>
          <th>ITEM / DEVICE ORDERED (EACH ITEM SEPARATE)</th>
          <th style="width: 92px;" class="center">ITEM QUANTITY</th>
          <th style="width: 46px;" class="center">PACKED</th>
        </tr>
      </thead>
      <tbody>
        $rowsBuffer
      </tbody>
      <tfoot>
        <tr>
          <td colspan="5" class="right bold">GRAND TOTAL UNITS ACROSS ${orders.length} ORDER${orders.length == 1 ? '' : 'S'} ($totalLines ITEM LINE${totalLines == 1 ? '' : 'S'})</td>
          <td class="center bold grand-qty-cell">Qty: $totalUnits</td>
          <td></td>
        </tr>
      </tfoot>
    </table>

    <div class="signatures">
      <div class="sig-block">
        <div class="sig-line"></div>
        <div class="sig-label">Prepared By (Store Manager)</div>
      </div>
      <div class="sig-block">
        <div class="sig-line"></div>
        <div class="sig-label">Warehouse / Packing Verification</div>
      </div>
      <div class="sig-block">
        <div class="sig-line"></div>
        <div class="sig-label">Dispatch / Courier Sign-Off</div>
      </div>
    </div>
  </div>

  <script>
    window.addEventListener('load', function() {
      setTimeout(function() { window.print(); }, 250);
    });
  </script>
</body>
</html>
''';
  }

  static Future<bool> printOrdersPlacedItemsList(
    List<ManagerOrder> orders, {
    required String branchName,
    required String scopeTitle,
  }) {
    final html = buildOrdersPlacedItemsListHtml(
      orders,
      branchName: branchName,
      scopeTitle: scopeTitle,
    );
    return launchPrintableHtml(
      html,
      fileSlug: 'orders_one_sheet_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  /// Builds a compact POS / thermal receipt HTML document (`80mm` standard or
  /// `58mm` mini roll) for a single [order], suitable for customer proof of
  /// purchase and return/exchange verification.
  static String buildOrderReceiptHtml(
    ManagerOrder order, {
    required String branchName,
    int paperWidthMm = 80,
  }) {
    final safeWidthMm = paperWidthMm == 58 ? 58 : 80;
    final contentWidthMm = safeWidthMm == 58 ? 50 : 72;
    final currencyFormat = NumberFormat.currency(symbol: 'GH₵ ', decimalDigits: 2);
    final cleanId = order.id.startsWith('ORDER_') ? order.id.substring(6) : order.id;
    final seqDigits = cleanId.replaceAll(RegExp(r'[^0-9]'), '');
    final receiptNo = seqDigits.isNotEmpty ? 'RCP-$seqDigits' : 'RCP-$cleanId';
    final orderDateStr = DateFormat('MMM d, yyyy • HH:mm').format(order.date);
    final printedStr = DateFormat('MMM d, yyyy • HH:mm').format(DateTime.now());
    final custName =
        order.customerName.trim().isNotEmpty ? order.customerName.trim() : 'Walk-in / App Customer';
    final custPhone = order.customerPhone.trim();
    final gpsCode = order.gpsCode.trim();
    final address = order.deliveryAddress.trim();

    final effectiveItems = order.items.isNotEmpty
        ? order.items
        : [
            OrderItem(
              title: 'Device / Merchandise Order',
              brand: '',
              price: order.totalAmount,
              quantity: order.status == OrderStatus.cancelled ? 0 : 1,
            ),
          ];

    int totalQty = 0;
    double computedSubtotal = 0;
    final itemsBuffer = StringBuffer();

    for (var i = 0; i < effectiveItems.length; i++) {
      final item = effectiveItems[i];
      totalQty += item.quantity;
      final unitPrice = item.price > 0
          ? item.price
          : (effectiveItems.length == 1 && item.quantity > 0
              ? order.totalAmount / item.quantity
              : 0.0);
      final lineTotal = unitPrice * item.quantity;
      computedSubtotal += lineTotal;

      final metaParts = [
        if (item.brand.trim().isNotEmpty) item.brand.trim(),
        if (item.specs.trim().isNotEmpty) item.specs.trim(),
      ].join(' • ');

      itemsBuffer.writeln('''
        <div class="item-block">
          <div class="item-title">${i + 1}. ${_esc(item.title)}</div>
          ${metaParts.isNotEmpty ? '<div class="item-meta">${_esc(metaParts)}</div>' : ''}
          <div class="item-Numbers">
            <span>Qty: ${item.quantity} &times; ${_esc(currencyFormat.format(unitPrice))}</span>
            <span class="bold">${_esc(currencyFormat.format(lineTotal))}</span>
          </div>
        </div>
      ''');
    }

    final displayTotal = order.totalAmount > 0 ? order.totalAmount : computedSubtotal;
    final locationSummary = [
      if (gpsCode.isNotEmpty) gpsCode,
      if (address.isNotEmpty) address,
    ].join(' • ');

    return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <title>Receipt ${_esc(cleanId)} - Siaka Phones</title>
  <style>${_receiptPrintCss(paperWidthMm: safeWidthMm, contentWidthMm: contentWidthMm)}</style>
</head>
<body>
  <div class="no-print receipt-toolbar">
    <div>
      <strong>Receipt #${_esc(cleanId)}</strong> (${safeWidthMm}mm Compact Size)
    </div>
    <button onclick="window.print()">Print Receipt</button>
  </div>

  <div class="receipt-slip">
    <div class="center">
      <div class="store-name">SIAKA PHONES</div>
      <div class="store-sub">${_esc(branchName)}</div>
      <div class="receipt-badge">OFFICIAL SALES RECEIPT</div>
    </div>

    <div class="divider"></div>

    <div class="kv-row"><span>Receipt No:</span><span class="bold">${_esc(receiptNo)}</span></div>
    <div class="kv-row"><span>Order ID:</span><span class="bold">${_esc(cleanId)}</span></div>
    <div class="kv-row"><span>Order Date:</span><span>${_esc(orderDateStr)}</span></div>
    <div class="kv-row"><span>Printed:</span><span>${_esc(printedStr)}</span></div>
    <div class="kv-row"><span>Status:</span><span>${_esc(order.status.label)}</span></div>
    <div class="kv-row"><span>Payment:</span><span>${_esc(order.paymentMethod)}</span></div>

    <div class="divider"></div>

    <div class="section-label">CUSTOMER DETAILS</div>
    <div class="cust-line bold">${_esc(custName)}</div>
    ${custPhone.isNotEmpty ? '<div class="cust-line">Tel: ${_esc(custPhone)}</div>' : ''}
    ${locationSummary.isNotEmpty ? '<div class="cust-line">${_esc(locationSummary)}</div>' : ''}

    <div class="divider"></div>

    <div class="items-header">
      <span>ITEM / QTY &times; UNIT</span>
      <span>AMOUNT</span>
    </div>
    <div class="thin-divider"></div>
    $itemsBuffer

    <div class="divider"></div>

    <div class="kv-row">
      <span>Items / Total Qty:</span>
      <span class="bold">${effectiveItems.length} ($totalQty ${totalQty == 1 ? 'Unit' : 'Units'})</span>
    </div>
    <div class="total-row">
      <span>TOTAL</span>
      <span>${_esc(currencyFormat.format(displayTotal))}</span>
    </div>

    <div class="divider"></div>

    <div class="return-box">
      <div class="return-title">RETURN &amp; EXCHANGE VERIFICATION</div>
      <div class="return-text">
        Present this receipt with original box, serial/IMEI match &amp; accessories for returns or warranty support.
      </div>
      <div class="ref-code">*${_esc(cleanId)}*</div>
      <div class="sig-row">Verified By: ____________________</div>
    </div>

    <div class="thanks center">Thank you for shopping at Siaka Phones!</div>
  </div>

  <script>
    window.addEventListener('load', function() {
      setTimeout(function() { window.print(); }, 250);
    });
  </script>
</body>
</html>
''';
  }

  static Future<bool> printOrderReceipt(
    ManagerOrder order, {
    required String branchName,
    int paperWidthMm = 80,
  }) {
    final cleanId = order.id.startsWith('ORDER_') ? order.id.substring(6) : order.id;
    final html = buildOrderReceiptHtml(
      order,
      branchName: branchName,
      paperWidthMm: paperWidthMm,
    );
    return launchPrintableHtml(
      html,
      fileSlug: 'receipt_${cleanId}_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  static String _receiptPrintCss({
    required int paperWidthMm,
    required int contentWidthMm,
  }) {
    final isCompact58 = paperWidthMm <= 58;
    final baseFontPx = isCompact58 ? '9.5px' : '10.5px';
    final titleFontPx = isCompact58 ? '13px' : '15px';
    return '''
    @page {
      size: ${paperWidthMm}mm auto;
      margin: 2.5mm 3mm;
    }
    * { box-sizing: border-box; }
    body {
      font-family: "Consolas", "Segoe UI", Roboto, "Courier New", monospace;
      font-size: $baseFontPx;
      line-height: 1.35;
      color: #0f172a;
      background: #e2e8f0;
      margin: 0;
      padding: 16px 8px;
    }
    .receipt-toolbar {
      width: ${paperWidthMm}mm;
      max-width: 340px;
      margin: 0 auto 10px auto;
      background: #0f172a;
      color: #ffffff;
      padding: 8px 12px;
      border-radius: 6px;
      display: flex;
      align-items: center;
      justify-content: space-between;
      font-family: "Segoe UI", Arial, sans-serif;
      font-size: 11.5px;
      gap: 8px;
    }
    .receipt-toolbar button {
      background: #1c7bff;
      color: #ffffff;
      border: none;
      padding: 6px 12px;
      border-radius: 5px;
      font-weight: 700;
      font-size: 11.5px;
      cursor: pointer;
      white-space: nowrap;
    }
    .receipt-slip {
      width: ${contentWidthMm}mm;
      max-width: ${contentWidthMm}mm;
      margin: 0 auto;
      background: #ffffff;
      padding: 10px 8px 12px 8px;
      border: 1px solid #cbd5e1;
      border-radius: 4px;
      box-shadow: 0 4px 12px rgba(15, 23, 42, 0.08);
    }
    .center { text-align: center; }
    .bold { font-weight: 700; color: #000000; }
    .store-name {
      font-size: $titleFontPx;
      font-weight: 900;
      letter-spacing: 0.6px;
      color: #000000;
    }
    .store-sub {
      font-size: 9.5px;
      color: #334155;
      margin-top: 1px;
    }
    .receipt-badge {
      display: inline-block;
      margin-top: 4px;
      padding: 1.5px 7px;
      border: 1px solid #0f172a;
      border-radius: 3px;
      font-size: 9px;
      font-weight: 800;
      letter-spacing: 0.4px;
    }
    .divider {
      border-top: 1px dashed #0f172a;
      margin: 7px 0;
    }
    .thin-divider {
      border-top: 1px dotted #64748b;
      margin: 4px 0;
    }
    .kv-row {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      gap: 6px;
      margin: 2px 0;
    }
    .section-label {
      font-size: 9px;
      font-weight: 800;
      letter-spacing: 0.4px;
      color: #334155;
      margin-bottom: 2px;
    }
    .cust-line {
      font-size: 9.8px;
      word-break: break-word;
      margin: 1px 0;
    }
    .items-header {
      display: flex;
      justify-content: space-between;
      font-size: 9px;
      font-weight: 800;
      letter-spacing: 0.3px;
    }
    .item-block {
      padding: 4px 0;
      border-bottom: 1px dotted #cbd5e1;
      page-break-inside: avoid;
      break-inside: avoid;
    }
    .item-block:last-of-type {
      border-bottom: none;
    }
    .item-title {
      font-weight: 700;
      color: #000000;
      word-break: break-word;
    }
    .item-meta {
      font-size: 8.8px;
      color: #475569;
      margin-top: 1px;
    }
    .item-Numbers {
      display: flex;
      justify-content: space-between;
      align-items: baseline;
      margin-top: 2px;
      font-size: 9.6px;
    }
    .total-row {
      display: flex;
      justify-content: space-between;
      align-items: baseline;
      margin-top: 5px;
      padding-top: 4px;
      border-top: 1.5px solid #000000;
      font-size: ${isCompact58 ? '11.5px' : '12.5px'};
      font-weight: 900;
      color: #000000;
    }
    .return-box {
      border: 1px dashed #334155;
      padding: 6px;
      border-radius: 3px;
      text-align: center;
      page-break-inside: avoid;
      break-inside: avoid;
    }
    .return-title {
      font-size: 8.8px;
      font-weight: 800;
      letter-spacing: 0.3px;
      color: #000000;
    }
    .return-text {
      font-size: 8.5px;
      color: #334155;
      margin-top: 3px;
      line-height: 1.3;
    }
    .ref-code {
      margin-top: 5px;
      padding: 2px 4px;
      background: #f8fafc;
      border: 1px solid #cbd5e1;
      font-family: "Courier New", Consolas, monospace;
      font-size: 10.5px;
      font-weight: 800;
      letter-spacing: 1.2px;
    }
    .sig-row {
      margin-top: 7px;
      font-size: 8.5px;
      color: #334155;
    }
    .thanks {
      margin-top: 7px;
      font-size: 9px;
      font-weight: 700;
      color: #1e293b;
    }
    @media print {
      html, body {
        width: ${paperWidthMm}mm;
        background: #ffffff;
        padding: 0;
        margin: 0;
      }
      .no-print {
        display: none !important;
      }
      .receipt-slip {
        width: ${contentWidthMm}mm;
        max-width: ${contentWidthMm}mm;
        margin: 0 auto;
        padding: 1mm 0;
        border: none;
        border-radius: 0;
        box-shadow: none;
      }
    }
    ''';
  }

  static String _oneSheetPrintCss() => '''
    @page {
      size: A4 portrait;
      margin: 8mm;
    }
    * { box-sizing: border-box; }
    body {
      font-family: "Segoe UI", -apple-system, BlinkMacSystemFont, Roboto, Arial, sans-serif;
      color: #0f172a;
      background: #f1f5f9;
      margin: 0;
      padding: 20px;
    }
    .toolbar {
      max-width: 920px;
      margin: 0 auto 14px auto;
      background: #0f172a;
      color: #ffffff;
      padding: 10px 16px;
      border-radius: 8px;
      display: flex;
      align-items: center;
      justify-content: space-between;
      font-size: 13px;
    }
    .toolbar button {
      background: #1c7bff;
      color: #ffffff;
      border: none;
      padding: 8px 18px;
      border-radius: 6px;
      font-weight: 700;
      font-size: 13px;
      cursor: pointer;
    }
    .sheet {
      max-width: 920px;
      margin: 0 auto;
      background: #ffffff;
      padding: 22px 24px;
      border-radius: 8px;
      border: 1px solid #cbd5e1;
      page-break-inside: avoid;
      break-inside: avoid;
    }
    .header {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      border-bottom: 2px solid #0f172a;
      padding-bottom: 10px;
      margin-bottom: 12px;
    }
    .brand {
      font-size: 19px;
      font-weight: 900;
      letter-spacing: 0.5px;
      color: #0f172a;
    }
    .subtitle {
      font-size: 12px;
      font-weight: 700;
      color: #334155;
      margin-top: 2px;
    }
    .meta-line {
      font-size: 11px;
      color: #475569;
      margin-top: 2px;
    }
    .doc-badge {
      text-align: right;
    }
    .doc-title {
      font-size: 14px;
      font-weight: 800;
      color: #0f172a;
    }
    table {
      width: 100%;
      border-collapse: collapse;
      font-size: 11px;
    }
    tr {
      page-break-inside: avoid;
      break-inside: avoid;
    }
    th, td {
      border: 1px solid #cbd5e1;
      padding: 6px 8px;
      text-align: left;
      vertical-align: middle;
    }
    thead th {
      background: #f1f5f9;
      font-size: 10px;
      font-weight: 800;
      color: #1e293b;
      letter-spacing: 0.25px;
      border-bottom: 2px solid #334155;
    }
    tr.order-start-row td {
      border-top: 1.8px solid #334155;
    }
    tr.sub-item-row td {
      border-top: 1px dashed #94a3b8;
      background: #fcfdff;
    }
    .order-num-cell {
      font-weight: 800;
      color: #334155;
      background: #f8fafc;
      vertical-align: top;
      padding-top: 8px;
    }
    .order-group-cell {
      vertical-align: top;
      padding-top: 8px;
      background: #ffffff;
    }
    .status-inline {
      font-weight: 600;
      color: #1e293b;
      margin-top: 3px;
    }
    .multi-summary-pill {
      display: inline-block;
      margin-top: 5px;
      padding: 2px 6px;
      background: #eff6ff;
      border: 1px solid #93c5fd;
      border-radius: 4px;
      font-size: 9.5px;
      font-weight: 800;
      color: #1e40af;
    }
    .item-step-badge {
      display: inline-block;
      padding: 1px 6px;
      margin-right: 4px;
      background: #e2e8f0;
      border-radius: 4px;
      font-size: 9.5px;
      font-weight: 800;
      color: #0f172a;
      vertical-align: middle;
    }
    .qty-pill {
      display: inline-block;
      padding: 3px 9px;
      background: #f1f5f9;
      border: 1.5px solid #0f172a;
      border-radius: 999px;
      font-size: 11.5px;
      font-weight: 900;
      color: #0f172a;
      white-space: nowrap;
    }
    .qty-sub-label {
      font-size: 9px;
      font-weight: 700;
      color: #475569;
      margin-top: 2px;
    }
    tfoot td {
      background: #f1f5f9;
      font-size: 11.5px;
      border-top: 2px solid #0f172a;
    }
    .grand-qty-cell {
      font-size: 12.5px;
      font-weight: 900;
      color: #0f172a;
    }
    .center { text-align: center; }
    .right { text-align: right; }
    .bold { font-weight: 700; color: #0f172a; }
    .muted { font-size: 9.8px; color: #475569; margin-top: 1.5px; }
    .check-box {
      display: inline-block;
      width: 13px;
      height: 13px;
      border: 1.5px solid #0f172a;
      border-radius: 2px;
    }
    .signatures {
      display: grid;
      grid-template-columns: 1fr 1fr 1fr;
      gap: 24px;
      margin-top: 22px;
      padding-top: 6px;
      page-break-inside: avoid;
      break-inside: avoid;
    }
    .sig-line {
      border-bottom: 1px solid #475569;
      height: 20px;
      margin-bottom: 4px;
    }
    .sig-label {
      font-size: 10px;
      color: #475569;
      text-align: center;
      font-weight: 600;
    }
    @media print {
      html, body {
        background: #ffffff;
        padding: 0;
        margin: 0;
      }
      .no-print {
        display: none !important;
      }
      .sheet {
        border: none;
        padding: 0;
        max-width: 100%;
      }
      table {
        font-size: 10px;
      }
      th, td {
        padding: 5px 6px;
      }
    }
  ''';
}
