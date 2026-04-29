import 'package:flutter/material.dart';
import 'package:posfrontend/account.dart';
import 'package:posfrontend/order.dart';
import 'category.dart';
import 'image_carousel.dart';
import 'footer.dart';
import 'product.dart';
import 'admin.dart';
import 'register.dart';
import 'login.dart';
import 'orderdialog.dart';

void main() => runApp(const MaterialApp( debugShowCheckedModeBanner: false,home: POSHome()));

class POSHome extends StatefulWidget {
  const POSHome({super.key});

  @override
  State<POSHome> createState() => _POSHomeState();
}

class _POSHomeState extends State<POSHome> {
  int _currentIndex = 0;

  void _onFooterTap(int index) {
    if(index==2){
      Navigator.push(context, MaterialPageRoute(builder: (context)=>const OrderPage(),),);}
    else if(index==1){
      Navigator.push(context, MaterialPageRoute(builder: (context)=>const InventoryPage(),),);
    }
    else {
      setState(() {
        _currentIndex=index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: Padding(
      padding: EdgeInsets.all(8.0),
      child: GestureDetector(
      onTap: () {
        Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const InventoryPage()),
    );
      // Navigator.push(...) or anything you want
      },
      child: CircleAvatar(
      backgroundColor: Colors.blueAccent,
      radius: 10,
      backgroundImage: AssetImage('assets/loco.png'),
      ),
    ),
    ),
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const TextField(
            decoration: InputDecoration(
              hintText: 'Search products...',
              prefixIcon: Icon(Icons.search),
              border: InputBorder.none,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                'John Doe',
                style: TextStyle(
                  color: Colors.grey[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Padding(
  padding: const EdgeInsets.only(right: 16),
  child: IconButton(
    icon: const Icon(Icons.account_circle, color: Colors.blue, size: 40),
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AccountPage()),
      );
    },
  ),
),
        ],
      ),

      // 👇 YOUR BODY (fixed scrolling issue)
      body: Column(
        children: [
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              itemBuilder: (context, index) {
                return Container(
                  width: 300,
                  margin: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color.fromARGB(255, 224, 224, 224),
                    borderRadius: BorderRadius.circular(15),
                    image: const DecorationImage(
                      image: AssetImage('assets/promo_banner.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),

          // 👇 IMPORTANT: Expanded added
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children:  [
                  ImageCarouselWidget(),
                  CategorySection(),
                ],
              ),
            ),
          ),
        ],
      ),

      //  ADD FOOTER HERE
      bottomNavigationBar: PosFooter(
        currentIndex: _currentIndex,
        onTap: _onFooterTap,
      ),
    );
  }
}