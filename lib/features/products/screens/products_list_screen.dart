import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/products_view_model.dart';
import '../widgets/product_list_item.dart';
import 'product_edit_screen.dart';
import 'product_detail_screen.dart';

class ProductsListScreen extends StatelessWidget {
  const ProductsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<ProductsViewModel>().loadProducts();
            },
          ),
        ],
      ),
      body: Consumer<ProductsViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading && viewModel.products.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.error != null && viewModel.products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    viewModel.error!.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red[300]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => viewModel.loadProducts(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (viewModel.products.isEmpty) {
            return const Center(
              child: Text('No products yet. Create one to get started!'),
            );
          }

          return RefreshIndicator(
            onRefresh: () => viewModel.loadProducts(),
            child: Column(
              children: [
                if (viewModel.error != null)
                  Container(
                    color: Colors.red[100],
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        const Icon(Icons.warning, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            viewModel.error!.message,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            viewModel.loadProducts();
                          },
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    itemCount: viewModel.products.length,
                    itemBuilder: (context, index) {
                      final product = viewModel.products[index];
                      return ProductListItem(
                        product: product,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProductDetailScreen(product: product),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ProductEditScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
