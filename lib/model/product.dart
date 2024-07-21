class Product {
  String name;
  double rate; // Rename rate to rateBeforeVAT to clarify
  // double rateAfterVAT;
  int quantity;

  Product({required this.name, required this.rate, required this.quantity,}) {
     // Calculate rate after adding 13% VAT
  }
}
