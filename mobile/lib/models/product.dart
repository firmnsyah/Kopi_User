class Product {
  final String name;
  final int price;
  int qty;

  Product({required this.name, required this.price, this.qty = 0});
}

const defaultProducts = [
  ('Kopi Susu', 10000),
  ('Kopi Gula Aren', 13000),
  ('Coklat Susu', 10000),
];

const expenseCategories = [
  'Bahan Baku',
  'Operasional',
  'Gaji Staff',
  'Perlengkapan',
  'Lain-lain',
];

const paymentMethods = ['QRIS', 'Tunai', 'Transfer'];
