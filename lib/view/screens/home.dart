import 'package:flutter/material.dart';
import 'package:billing_with_tax/model/product.dart';

import 'dart:typed_data' as typed_data;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:billing_with_tax/view/utils/custom_text_style.dart';
import 'package:printing/printing.dart';

class ProductInputScreen extends StatefulWidget {
  @override
  _ProductInputScreenState createState() => _ProductInputScreenState();
}

class _ProductInputScreenState extends State<ProductInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _productNameController = TextEditingController();
  final _productPriceController = TextEditingController();
  final _productQuantityController = TextEditingController();
  final List<Product> _products = [];
  int _editingIndex = -1;
  bool _isProceed = false;

  @override
  void dispose() {
    _customerNameController.dispose();
    _productNameController.dispose();
    _productPriceController.dispose();
    _productQuantityController.dispose();
    super.dispose();
  }

  void _addOrUpdateProduct() {
    if (_formKey.currentState!.validate()) {
      final String name = _productNameController.text;
      final double rate = double.tryParse(_productPriceController.text) ?? 0.0;
      final int quantity = int.tryParse(_productQuantityController.text) ?? 0;

      setState(() {
        if (_editingIndex == -1) {
          _products.add(Product(name: name, rate: rate, quantity: quantity));
        } else {
          _products[_editingIndex] =
              Product(name: name, rate: rate, quantity: quantity);
          _editingIndex = -1;
        }
        _productNameController.clear();
        _productPriceController.clear();
        _productQuantityController.clear();
        _isProceed = true;
      });
    }
  }

  void _proceed() {
    setState(() {
      _isProceed = false;
    });
  }

  void _editProduct(int index) {
    setState(() {
      _editingIndex = index;
      _productNameController.text = _products[index].name;
      _productPriceController.text = _products[index].rate.toString();
      _productQuantityController.text = _products[index].quantity.toString();
    });
  }

  void _deleteProduct(int index) {
    setState(() {
      _products.removeAt(index);
    });
  }

  void _refresh() {
    setState(() {
      _customerNameController.clear();
      _productNameController.clear();
      _productPriceController.clear();
      _productQuantityController.clear();
      _products.clear();
      _editingIndex = -1;
      _isProceed = false;
    });
  }

  double calculateSubtotal(List<Product> products) {
    double subtotal = 0;
    for (var product in products) {
      subtotal += product.rate / 1.13 * product.quantity;
    }
    return subtotal;
  }

  double calculateTaxableAmount(List<Product> products) {
    return calculateSubtotal(products);
  }

  double calculateVAT(List<Product> products) {
    return calculateTaxableAmount(products) * 0.13;
  }

  double calculateTotal(List<Product> products) {
    double total = 0;
    for (var product in products) {
      total +=
          (product.rate / 1.13 * product.quantity) * 1.13; // Adding 13% VAT
    }
    return total;
  }

  Future<typed_data.Uint8List> _generatePdf(PdfPageFormat format) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.robotoRegular(); // Use Roboto font

    final productsTable = <pw.TableRow>[
      pw.TableRow(
        children: [
          pw.Text('Product',
              style: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold)),
          pw.Text('Rate',
              style: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold)),
          pw.Text('Quantity',
              style: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold)),
          pw.Text('Total',
              style: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    ];

    for (var product in _products) {
      productsTable.add(
        pw.TableRow(
          children: [
            pw.Text(product.name, style: pw.TextStyle(font: font)),
            pw.Text((product.rate / 1.13).toStringAsFixed(2),
                style: pw.TextStyle(font: font)),
            pw.Text(product.quantity.toString(),
                style: pw.TextStyle(font: font)),
            pw.Text((product.rate / 1.13 * product.quantity).toStringAsFixed(2),
                style: pw.TextStyle(font: font)),
          ],
        ),
      );
    }

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Invoice', style: pw.TextStyle(font: font, fontSize: 24)),
            pw.SizedBox(height: 20),
            pw.Text('Customer Name: ${_customerNameController.text}',
                style: pw.TextStyle(font: font)),
            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.Table(children: productsTable),
            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.SizedBox(height: 20),
            pw.Text(
                'Subtotal: ${calculateSubtotal(_products).toStringAsFixed(2)}',
                style: pw.TextStyle(font: font)),
            pw.Text(
                'Taxable Amount: ${calculateTaxableAmount(_products).toStringAsFixed(2)}',
                style: pw.TextStyle(font: font)),
            pw.Text('VAT (13%): ${calculateVAT(_products).toStringAsFixed(2)}',
                style: pw.TextStyle(font: font)),
            pw.Text(
                'Grand Total Amount: ${calculateTotal(_products).toStringAsFixed(2)}',
                style:
                    pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  // void _downloadInvoice() async {
  //   try {
  //     final typed_data.Uint8List pdfFile = await _generatePdf(PdfPageFormat.a4);
  //     await Printing.sharePdf(bytes: pdfFile, filename: 'invoice.pdf');
  //   } catch (e) {
  //     print('Error: $e');
  //     // Optionally, show an alert dialog or a snackbar with the error message.
  //   }
  // }

  // void _downloadInvoice() async {
  //   try {
  //     final typed_data.Uint8List pdfFile = await _generatePdf(PdfPageFormat.a4);

  //     // Create a Blob from the Uint8List
  //     final blob = html.Blob([pdfFile], 'application/pdf');

  //     // Create a URL for the Blob
  //     final url = html.Url.createObjectUrlFromBlob(blob);

  //     // Create an anchor element and click it programmatically

  //     // Clean up the URL
  //     html.Url.revokeObjectUrl(url);
  //   } catch (e) {
  //     print('Error: $e');
  //     // Optionally, show an alert dialog or a snackbar with the error message.
  //   }
  // }

  // void _downloadInvoice() async {
  //   try {
  //     final typed_data.Uint8List pdfFile = await _generatePdf(PdfPageFormat.a4);

  //     final directory = await getApplicationDocumentsDirectory();
  //     final file = File('${directory.path}/invoice.pdf');
  //     await file.writeAsBytes(pdfFile);

  //     // Open the PDF file using open_file package
  //     final result = await OpenFile.open(file.path);
  //     if (result.type != ResultType.done) {
  //       // Handle the case when the file could not be opened
  //       print('Could not open the PDF file.');
  //     }
  //   } catch (e) {
  //     print('Error: $e');
  //     // Optionally, show an alert dialog or a snackbar with the error message.
  //   }
  // }
  void _downloadInvoice() async {
    try {
      final typed_data.Uint8List pdfFile = await _generatePdf(PdfPageFormat.a4);
      await Printing.sharePdf(bytes: pdfFile, filename: 'invoice.pdf');
    } catch (e) {
      print('Error: $e');
      // Optionally, show an alert dialog or a snackbar with the error message.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 41, 64, 238),
        title: Text('Product Input',
            style: CustomTextStyles.f24W600(
              color: Colors.white,
            )),
        centerTitle: false,
        actions: [
          IconButton(
              onPressed: _refresh,
              icon: Icon(
                Icons.refresh,
                color: Colors.white,
                size: 22,
              )),
          IconButton(
              onPressed: _downloadInvoice,
              icon: Icon(
                Icons.download,
                color: Colors.white,
                size: 22,
              )),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _customerNameController,
                      decoration: InputDecoration(
                        labelText: 'Customer Name',
                        labelStyle:
                            CustomTextStyles.f16W300(color: Colors.black),
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.black, width: 2.0),
                        ),
                      ),
                      style: TextStyle(color: Colors.black),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a customer name';
                        }
                        return null;
                      },
                    ),
                  )
                ],
              ),
              SizedBox(height: 25),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _productNameController,
                      decoration: InputDecoration(
                        labelText: 'Product Name',
                        labelStyle:
                            CustomTextStyles.f16W300(color: Colors.black),
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.black, width: 2.0),
                        ),
                      ),
                      style: TextStyle(color: Colors.black),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a product name';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(
                    width: 20,
                    height: 25,
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: _productPriceController,
                      decoration: InputDecoration(
                        labelText: 'Product Price',
                        labelStyle:
                            CustomTextStyles.f16W300(color: Colors.black),
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.black, width: 2.0),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: Colors.black),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a product price';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 25),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _productQuantityController,
                      decoration: InputDecoration(
                        labelText: 'Product Quantity',
                        labelStyle:
                            CustomTextStyles.f16W300(color: Colors.black),
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.black, width: 2.0),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: Colors.black),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a product quantity';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 25),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _isProceed ? _proceed : _addOrUpdateProduct,
                        label: Text(
                          _isProceed
                              ? 'Proceed'
                              : _editingIndex == -1
                                  ? 'Add Product'
                                  : 'Update Product',
                          style: CustomTextStyles.f16W600(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromARGB(255, 41, 64, 238),
                          padding: EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              if (!_isProceed && _products.isNotEmpty) ...[
                Text('Added Products:',
                    style: CustomTextStyles.f18W600(color: Colors.black)),
                SizedBox(height: 10),
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final product = _products[index];

                    return Card(
                      color: Color.fromARGB(255, 41, 64, 238),
                      elevation: 4,
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text(product.name,
                            style:
                                CustomTextStyles.f14W400(color: Colors.white)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Price: ${product.rate.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Quantity: ${product.quantity}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              color: Colors.white,
                              icon: Icon(Icons.edit),
                              onPressed: () => _editProduct(index),
                            ),
                            IconButton(
                              color: Colors.white,
                              icon: Icon(Icons.delete),
                              onPressed: () => _deleteProduct(index),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 20),
                Divider(),
                SizedBox(height: 20),
                Table(
                  border: TableBorder.all(color: Colors.black),
                  columnWidths: {
                    0: FlexColumnWidth(4),
                    1: FlexColumnWidth(2),
                    2: FlexColumnWidth(2),
                    3: FlexColumnWidth(2),
                  },
                  children: [
                    TableRow(children: [
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text('Invoice',
                              style: CustomTextStyles.f16W600(
                                  color: Colors.black)),
                        ),
                      ),
                    ]),
                    TableRow(children: [
                      TableCell(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                              'Customer Name: ${_customerNameController.text}',
                              style: CustomTextStyles.f14W400(
                                  color: Colors.black)),
                        ),
                      ),
                    ]),
                    TableRow(children: [
                      TableCell(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: DataTable(
                            columnSpacing: 35,
                            columns: [
                              DataColumn(
                                  label: Text('Product',
                                      style: CustomTextStyles.f14W600(
                                          color: Colors.black))),
                              DataColumn(
                                  label: Text('Rate',
                                      style: CustomTextStyles.f14W600(
                                          color: Colors.black))),
                              DataColumn(
                                  label: Text('Quantity',
                                      style: CustomTextStyles.f14W600(
                                          color: Colors.black))),
                              DataColumn(
                                  label: Text('Total',
                                      style: CustomTextStyles.f14W600(
                                          color: Colors.black))),
                            ],
                            rows: _products
                                .map(
                                  (product) => DataRow(
                                    cells: [
                                      DataCell(
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(product.name,
                                              style: TextStyle(
                                                  color: Colors.black)),
                                        ),
                                      ),
                                      DataCell(
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text((product.rate / 1.13)
                                              .toStringAsFixed(2)),
                                        ),
                                      ),
                                      DataCell(
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                              product.quantity.toString(),
                                              style: TextStyle(
                                                  color: Colors.black)),
                                        ),
                                      ),
                                      DataCell(
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            (product.rate /
                                                    1.13 *
                                                    product.quantity)
                                                .toStringAsFixed(2),
                                            style:
                                                TextStyle(color: Colors.black),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                    ]),
                    TableRow(children: [
                      TableCell(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Subtotal: ${calculateSubtotal(_products).toStringAsFixed(2)}',
                                style: TextStyle(color: Colors.black),
                              ),
                              Text(
                                'Taxable Amount: ${calculateTaxableAmount(_products).toStringAsFixed(2)}',
                                style: TextStyle(color: Colors.black),
                              ),
                              Text(
                                'VAT (13%): ${calculateVAT(_products).toStringAsFixed(2)}',
                                style: TextStyle(color: Colors.black),
                              ),
                              Text(
                                'Grand Total Amount: ${calculateTotal(_products).toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ]),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
