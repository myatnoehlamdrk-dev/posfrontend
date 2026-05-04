import 'package:flutter/material.dart';

class ImageCarouselWidget extends StatelessWidget {
  const ImageCarouselWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200, // Height of your scrolling area
      child: ListView.builder(
        scrollDirection: Axis.horizontal, // Scrolls beside by beside
        itemCount: 3, // Number of images
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemBuilder: (context, index) {
          return Container(
            width: MediaQuery.of(context).size.width * 0.8, // 80% of screen width
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.blueGrey[100],
              borderRadius: BorderRadius.circular(16),
              image: const DecorationImage(
                image: AssetImage('assets/product2.jpg'), // Your local path
                fit: BoxFit.cover,
                  ),
            ),
          );
        },
      ),
    );
  }
}