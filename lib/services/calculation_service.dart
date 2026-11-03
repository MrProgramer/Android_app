import '../models/customer.dart';
import '../models/invoice.dart';
import '../models/product.dart';
import '../models/return_item.dart';
import '../models/treasury.dart';

class CustomerFinanceDetails {
  final Customer customer;
  final double liveBalance;
  final String status; // 'debtor', 'creditor', 'settled'
  final double debtAmount;
  final double creditAmount;
  final int invoicesCount;
  final String lastDate;
  final String riskLevel; // 'high', 'medium', 'normal'

  CustomerFinanceDetails({
    required this.customer,
    required this.liveBalance,
    required this.status,
    required this.debtAmount,
    required this.creditAmount,
    required this.invoicesCount,
    required this.lastDate,
    required this.riskLevel,
  });
}

class DeadStockProduct {
  final Product product;
  final double tiedUpCapital;
  final int cartons;
  final int loosePieces;

  DeadStockProduct({
    required this.product,
    required this.tiedUpCapital,
    required this.cartons,
    required this.loosePieces,
  });
}

class LiveLiquidityData {
  final double cashBalance;
  final double bankBalance;
  final double totalLiquidity;

  LiveLiquidityData({
    required this.cashBalance,
    required this.bankBalance,
    required this.totalLiquidity,
  });
}

class CalculationService {
  /// Unpaid credit debt amount of a single invoice
  static double getInvoiceCreditDebtAmount(Invoice inv) {
    if (inv.isDraft || !inv.isSale) return 0.0;
    if (inv.paymentStatus == 'cash') return 0.0;
    if (inv.paymentStatus == 'partial' || inv.paidAmount > 0) {
      if (inv.remainingAmount > 0) return inv.remainingAmount;
      return (inv.finalAmount - inv.paidAmount).clamp(0.0, double.infinity);
    }
    return inv.finalAmount;
  }

  /// Calculates the exact live ledger balance of a customer or supplier
  /// Positive: customer owes us (بدهکار به ما)
  /// Negative: we owe supplier or customer has credit (بستانکار)
  static double calculateCustomerLiveBalance(
    Customer customer,
    List<Invoice> invoices,
    List<CustomerPayment> payments,
    List<ProductReturn> productReturns,
  ) {
    final custName = customer.name.trim().toLowerCase();

    // 1. Initial balance & adjustments
    final initial = customer.initialBalance;
    final adjustment = customer.balanceAdjustment ?? 0.0;

    // 2. Sales credit invoices
    final custSalesInvoices = invoices.where((i) {
      if (i.isDraft || !i.isSale) return false;
      return i.customerId == customer.id || (i.customerName.trim().toLowerCase() == custName);
    }).toList();

    final creditSalesTotal = custSalesInvoices.fold(0.0, (sum, i) => sum + getInvoiceCreditDebtAmount(i));

    // 3. Customer payments & manual debts
    final custPayments = payments.where((p) {
      return p.customerId == customer.id || (p.customerName.trim().toLowerCase() == custName);
    }).toList();

    final deposits = custPayments.where((p) => p.amount > 0).fold(0.0, (sum, p) => sum + p.amount);
    final manualDebts = custPayments.where((p) => p.amount < 0).fold(0.0, (sum, p) => sum + p.amount.abs());

    // 4. Returns from customer (reduce debt)
    final custReturns = productReturns.where((r) {
      return (r.customerId == customer.id || r.customerName.trim().toLowerCase() == custName) &&
          r.type == 'from_customer' &&
          !r.isRefunded;
    }).fold(0.0, (sum, r) => sum + (r.netAmount ?? (r.totalAmount - (r.extraCosts ?? 0.0))));

    // 5. Purchases from supplier on credit
    final custPurchases = invoices.where((i) {
      if (i.isDraft || !i.isPurchase) return false;
      return i.customerId == customer.id || (i.customerName.trim().toLowerCase() == custName);
    }).toList();

    final creditPurchases = custPurchases.where((i) => i.paymentStatus == 'credit' || i.paymentStatus == 'partial').fold(0.0, (sum, i) {
      if (i.paymentStatus == 'partial') {
        return sum + (i.remainingAmount > 0 ? i.remainingAmount : (i.finalAmount - i.paidAmount).clamp(0.0, double.infinity));
      }
      return sum + i.finalAmount;
    });

    return initial + adjustment + creditSalesTotal + manualDebts - deposits - custReturns - creditPurchases;
  }

  /// Total customer receivables (طلب نسیه بازار)
  static double calculateTotalCustomerReceivables(
    List<Customer> customers,
    List<Invoice> invoices,
    List<CustomerPayment> payments,
    List<ProductReturn> productReturns,
  ) {
    double total = 0.0;
    for (final c in customers) {
      final bal = calculateCustomerLiveBalance(c, invoices, payments, productReturns);
      if (bal > 0) total += bal;
    }
    return total;
  }

  /// Total supplier payables (بدهی ما به تامین‌کنندگان)
  static double calculateTotalSupplierPayables(List<Invoice> invoices) {
    return invoices.where((i) => !i.isDraft && i.isPurchase && (i.paymentStatus == 'credit' || i.paymentStatus == 'partial')).fold(0.0, (sum, i) {
      if (i.paymentStatus == 'partial') {
        return sum + (i.remainingAmount > 0 ? i.remainingAmount : (i.finalAmount - i.paidAmount).clamp(0.0, double.infinity));
      }
      return sum + i.finalAmount;
    });
  }

  /// Top debtors with risk ratings
  static List<CustomerFinanceDetails> getTopDebtors(
    List<Customer> customers,
    List<Invoice> invoices,
    List<CustomerPayment> payments,
    List<ProductReturn> productReturns, {
    int limit = 5,
  }) {
    final list = <CustomerFinanceDetails>[];

    for (final cust in customers) {
      final bal = calculateCustomerLiveBalance(cust, invoices, payments, productReturns);
      if (bal > 0) {
        final custInvoices = invoices.where((i) {
          if (i.isDraft || !i.isSale) return false;
          return i.customerId == cust.id || (i.customerName.trim().toLowerCase() == cust.name.trim().toLowerCase());
        }).toList();

        final lastDate = custInvoices.isNotEmpty ? custInvoices.first.date : '';
        final risk = bal >= 20000000 ? 'high' : (bal >= 5000000 ? 'medium' : 'normal');

        list.add(CustomerFinanceDetails(
          customer: cust,
          liveBalance: bal,
          status: 'debtor',
          debtAmount: bal,
          creditAmount: 0.0,
          invoicesCount: custInvoices.length,
          lastDate: lastDate,
          riskLevel: risk,
        ));
      }
    }

    list.sort((a, b) => b.liveBalance.compareTo(a.liveBalance));
    return list.take(limit).toList();
  }

  /// Dead stock products (products with stock >= 2 cartons but 0 sales in period)
  static List<DeadStockProduct> getDeadStockProducts(
    List<Product> products,
    List<Invoice> periodSalesInvoices, {
    int limit = 5,
  }) {
    final soldKeys = <String>{};
    for (final inv in periodSalesInvoices) {
      for (final it in inv.items) {
        soldKeys.add(it.productId);
        soldKeys.add(it.productName.trim().toLowerCase());
      }
    }

    final deadList = <DeadStockProduct>[];
    for (final p in products) {
      final hasSold = soldKeys.contains(p.id) || soldKeys.contains(p.name.trim().toLowerCase());
      final cartons = p.piecesPerCarton > 0 ? p.stockPieces / p.piecesPerCarton : p.stockPieces.toDouble();

      if (!hasSold && cartons >= 2 && p.stockPieces > 0) {
        final tiedCapital = p.stockPieces * (p.purchasePrice > 0 ? p.purchasePrice : p.sellingPrice);
        final cCount = p.piecesPerCarton > 0 ? p.stockPieces ~/ p.piecesPerCarton : 0;
        final loose = p.piecesPerCarton > 0 ? p.stockPieces % p.piecesPerCarton : p.stockPieces;

        deadList.add(DeadStockProduct(
          product: p,
          tiedUpCapital: tiedCapital,
          cartons: cCount,
          loosePieces: loose,
        ));
      }
    }

    deadList.sort((a, b) => b.tiedUpCapital.compareTo(a.tiedUpCapital));
    return deadList.take(limit).toList();
  }

  /// Live cash and bank liquidity
  static LiveLiquidityData calculateRealTimeLiquidity(
    List<CustomerPayment> payments,
    List<TreasuryTransaction> treasury,
    List<Invoice> invoices,
  ) {
    double cash = 0.0;
    double bank = 0.0;

    // 1. Direct payments
    for (final p in payments) {
      if (p.paymentMethod == 'cash') {
        cash += p.amount;
      } else {
        bank += p.amount;
      }
    }

    // 2. Direct cash payments from finalized invoices
    for (final inv in invoices) {
      if (inv.isDraft) continue;
      if (inv.paymentStatus == 'cash' || inv.paidAmount > 0) {
        final paid = inv.paymentStatus == 'cash' ? inv.finalAmount : inv.paidAmount;
        if (inv.isSale) {
          if (inv.paymentAccount == 'cash') cash += paid;
          else bank += paid;
        } else {
          // purchase
          if (inv.paymentAccount == 'cash') cash -= paid;
          else bank -= paid;
        }
      }
    }

    // 3. Treasury transactions
    for (final t in treasury) {
      if (t.type == 'transfer') {
        if (t.source == 'cash' && t.destination == 'bank') {
          cash -= t.amount;
          bank += t.amount;
        } else if (t.source == 'bank' && t.destination == 'cash') {
          bank -= t.amount;
          cash += t.amount;
        }
      } else if (t.type == 'expense') {
        if (t.source == 'cash') cash -= t.amount;
        else if (t.source == 'bank') bank -= t.amount;
      } else if (t.type == 'deposit') {
        if (t.source == 'cash') cash += t.amount;
        else if (t.source == 'bank') bank += t.amount;
      }
    }

    return LiveLiquidityData(
      cashBalance: cash,
      bankBalance: bank,
      totalLiquidity: cash + bank,
    );
  }
}
