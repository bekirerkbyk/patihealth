import 'package:flutter/material.dart';
import 'models/cart_item.dart';
import 'cart_page.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  final List<CartItem> cartItems = [];

  final List<Map<String, String>> products = [
    /*{
      "name": "Ferrari 458 Italia",
      "price": "\$250.000",
      "imageUrl":
          "https://upload.wikimedia.org/wikipedia/commons/thumb/5/59/0_488_GTB.jpg/420px-0_488_GTB.jpg"
    },
    {
      "name": "Nike Mercurial Zoom Superfly 9 Elite (pink)",
      "price": "\$100",
      "imageUrl":
          "https://0990b9.a-cdn.akinoncloud.com/products/2023/05/27/457185/48db84c0-e676-41d2-a52f-0beeb67e9c23_size3840x3840_cropCenter.jpg"
    },
    {
      "name": "Bicycle Dragon Blue ",
      "price": "\$25",
      "imageUrl":
          "https://encrypted-tbn0.gstatic.com/shopping?q=tbn:ANd9GcQDzNZ2HQ2b31I6PRMsx-SWcnVW014yJcED-QmVWQpd0FmEYbOoSxFEeq4oLQwP_JZuLWbPUN6-QGHQ8hw23zjjGBxiqt925B4CQbVmbgvUST7_EKqP72v6Qw&usqp=CAE"
    },
    {
      "name": "Victor Osimhen",
      "price": "\$100.000.000",
      "imageUrl":
          "https://liderhabercomtr.teimg.com/crop/1280x720/liderhaber-com-tr/uploads/2024/10/osimhen-1.jpg"
    },
    {
      "name": "Galatasaray Island",
      "price": "\$100.000.000",
      "imageUrl":
          "https://foto.haberler.com/haber/2024/10/10/galatasaray-adasi-satilacak-mi-galatasaray-adasi-17916149_7544_amp.jpg"
    },
    {
      "name": "Hyundai Accent Era",
      "price": "\$1000",
      "imageUrl":
          "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTb8lxQqihHpCbg-p0s2-VcCCBx81DKmWydKA&s"
    },*/
    {
      "name": "LaMito Adult Cat 15 Kg",
      "price": "\$40",
      "imageUrl":
          "https://www.temizmama.com/assets/img/urun/51/u-mito-tavuklu-balikli-yetiskin-kedi-mamasi.webp"
    },
    {
      "name": "Wunder Food Cat Food Beef 15kg",
      "price": "\$50.32",
      "imageUrl":
          "https://encrypted-tbn3.gstatic.com/shopping?q=tbn:ANd9GcS0OwPVhU-OvtlTGjVEypn2WBWzM6rgmwVwHrArP_MSaEUkMSefGWXK7OJ6CKhuUifcJ8a-1wjEyqmrHYjgXN30yenxPz9RVgMW1urSULPkLFRtfzi266Sy&usqp=CAE"
    },
    {
      "name": "Trendline 15 Kg Adult Dog Food with Beef",
      "price": "\$20",
      "imageUrl":
          "https://encrypted-tbn1.gstatic.com/shopping?q=tbn:ANd9GcTxtN3iLtPKU2DZxBNwaki14Jl-tUUHVDfwRBeW0tzMxdpNEj6D-i2ujHuDVlxO_sFxCmvG2-C2_my7Gy0WlGygn8IAscjUBlYex8K7CJKPyL9zDGnB1LNdMA&usqp=CAE"
    },
    {
      "name": "Gardenmix Platinum Honey Budgie Bird Food, 1 kg",
      "price": "\$5.75",
      "imageUrl":
          "https://m.media-amazon.com/images/I/814yl+nJ0cL._AC_SY879_.jpg"
    },
  ];

  void addToCart(Map<String, String> product) {
    setState(() {
      final existingItem = cartItems.firstWhere(
        (item) => item.name == product['name'],
        orElse: () => CartItem(
          name: product['name']!,
          price: product['price']!,
          imageUrl: product['imageUrl']!,
        ),
      );

      if (cartItems.contains(existingItem)) {
        existingItem.quantity++;
      } else {
        cartItems.add(existingItem);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${product['name']} sepete eklendi')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          "Shop",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CartPage(cartItems: cartItems),
                    ),
                  );
                },
              ),
              if (cartItems.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${cartItems.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          itemCount: products.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.7,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemBuilder: (context, index) {
            final product = products[index];
            return GestureDetector(
              onTap: () {
                // Ürün detay sayfasına yönlendirme
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductDetailPage(product: product),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.network(
                          product["imageUrl"]!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      product["name"]!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product["price"]!,
                      style: const TextStyle(fontSize: 14, color: Colors.green),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.shopping_bag_outlined,
                              color: Colors.grey),
                          onPressed: () => addToCart(product),
                        ),
                        const Icon(Icons.favorite_outline, color: Colors.grey),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Product Detail Page
class ProductDetailPage extends StatelessWidget {
  final Map<String, String> product;

  const ProductDetailPage({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(product["name"]!, style: const TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  product["imageUrl"]!,
                  fit: BoxFit.cover,
                  height: 200,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              product["name"]!,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              product["price"]!,
              style: const TextStyle(fontSize: 18, color: Colors.green),
            ),
            const SizedBox(height: 20),
            const Text(
              "Product Description: \nLorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
