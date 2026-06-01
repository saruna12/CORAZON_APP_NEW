import 'package:flutter/material.dart';

class BerandaPage extends StatelessWidget {
  const BerandaPage({super.key});

  @override
  Widget build(BuildContext context) {
    const maroonColor = Color(0xFF801A24); // Warna maroon khas Corazon
    const creamColor = Color(0xFFF6EBE6);  // Warna background card

    return Scaffold(
      backgroundColor: Colors.white,
      
      // 1. HEADER
      appBar: AppBar(
        backgroundColor: maroonColor,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Text(
                'C',
                style: TextStyle(color: maroonColor, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'CORAZON',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
        ],
      ),

      // 2. MAIN CONTENT
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Greeting
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade400, width: 2),
                  ),
                  child: Icon(Icons.person_outline, color: Colors.grey.shade600),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Halo Vivi',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Search Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: creamColor,
                borderRadius: BorderRadius.circular(25),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  icon: Icon(Icons.search, color: Colors.black54),
                  hintText: 'Telusuri',
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Card 1: Visualisasi Organ Jantung
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: creamColor,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                
                mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'VISUALISASI ORGAN JANTUNG',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Eksplorasi Jantung Berbasis AR',
                          style: TextStyle(fontSize: 11, color: Colors.black54),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: maroonColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                          ),
                          onPressed: () {},
                          child: const Text('Mulai AR', style: TextStyle(fontSize: 11, color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                  const Text('❤️', style: TextStyle(fontSize: 50)), 
                ],
              ),
            ),
            const SizedBox(height: 15),

            // Card 2: Ukur Kemampuan Kamu
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: creamColor,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                        child: const Center(child: Text('📊', style: TextStyle(fontSize: 20))),
                      ),
                      const SizedBox(width: 15),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Ukur Kemampuan Kamu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          SizedBox(height: 5),
                          Text('Status : --------', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: maroonColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                      ),
                      onPressed: () {},
                      child: const Text('Mulai Pretest', style: TextStyle(fontSize: 12, color: Colors.white)),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 15),

            // Card 3: Pemantauan Uji Kemampuan
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: creamColor,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  const Text(
                    'Pemantauan Uji Kemampuan',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: