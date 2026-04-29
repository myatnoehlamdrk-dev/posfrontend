import 'package:flutter/material.dart';
import 'category/book.dart'; // Ensure this is imported
import 'category/fashion.dart';
import 'category/gift.dart';
import 'category/newhome.dart';

class CategorySection extends StatelessWidget {
  // 1. Remove 'const' from the constructor
  CategorySection({super.key}); 

  // 2. Remove 'const' from the list definition
  final List<Map<String, dynamic>> categories = [
    {'name': 'NewHome', 'icon': Icons.home_repair_service_outlined,'page': NewHomePage()},
    {'name': 'Gift', 'icon': Icons.card_giftcard,'page':const GiftPage()},
    // 3. Now you can safely include the Widget object
    {'name': 'Book', 'icon': Icons.book, 'page': const BookPage()}, 
    {'name': 'Fashion', 'icon': Icons.category, 'page': const FashionPage()},
    
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text("Categories", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            return InkWell( // 4. Wrap with InkWell to make it clickable
              onTap: () {
                if (categories[index]['page'] != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => categories[index]['page']),
                  );
                }
              },
              child: Column(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    child: Icon(categories[index]['icon'], color: Colors.blue),
                  ),
                  const SizedBox(height: 5),
                  Text(categories[index]['name'], style: const TextStyle(fontSize: 12)),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}