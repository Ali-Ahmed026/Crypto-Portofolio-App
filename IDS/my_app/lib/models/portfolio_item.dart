class PortfolioItem {
  final String symbol;
  final double quantity;
  final double investmentAmount;
  final double currentValue;

  PortfolioItem({
    required this.symbol,
    required this.quantity,
    required this.investmentAmount,
    required this.currentValue,
  });

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'quantity': quantity,
      'investmentAmount': investmentAmount,
      'currentValue': currentValue,
    };
  }

  factory PortfolioItem.fromJson(Map<String, dynamic> json) {
    return PortfolioItem(
      symbol: json['symbol'] as String,
      quantity: json['quantity'] as double,
      investmentAmount: json['investmentAmount'] as double,
      currentValue: json['currentValue'] as double,
    );
  }
}
