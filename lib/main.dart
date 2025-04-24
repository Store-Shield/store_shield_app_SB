import 'package:flutter/material.dart';

// sunbin_pages 폴더에 있는 management_page.dart 파일을 import 합니다.
import 'sunbin_pages/managementPage/management_page.dart';   
import 'sunbin_pages/socket_service.dart';

void main() {
  // Initialize the socket service singleton so the connection is established once
  SocketService();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ManagementPage(),   // 여기서 네 페이지 호출!
    );
  }
}