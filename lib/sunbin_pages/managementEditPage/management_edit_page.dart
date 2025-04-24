import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:async';
import '../fontstyle.dart';

class EditManagementPage extends StatefulWidget {
  final List<Map<String,dynamic>> items;
  final IO.Socket socket;

  const EditManagementPage({
    Key? key,
    required this.items,
    required this.socket,
  }) : super(key: key);

  @override
  _EditManagementPageState createState() => _EditManagementPageState();
}

class _EditManagementPageState extends State<EditManagementPage> {
  late List<Map<String,dynamic>> _editableItems;

  @override
  void initState() {
    super.initState();
    _editableItems = List.from(widget.items);
  }

  Future<void> _deleteAllOnServer() {
    final completer = Completer<void>();
    widget.socket.emit('delete_all_products');
    widget.socket.once('delete_all_success', (_) {
      setState(() => _editableItems.clear());
            completer.complete();
    });
      widget.socket.once('delete_all_error', (err) {
      completer.completeError(err);
    });
    return completer.future;
  }

  
  Future<void> _deleteOneOnServer(int idx) {
    final completer = Completer<void>();
    final name = _editableItems[idx]['name'] as String;
    widget.socket.emit('delete_product', {'product_name': name});
    widget.socket.once('delete_success', (_) {
      setState(() => _editableItems.removeAt(idx));
      completer.complete();
    });
      widget.socket.once('delete_error', (err) {
      completer.completeError(err);
    });
    return completer.future;
  }

  /// 전체삭제 확인 다이얼로그
  void _showDeleteAllDialog() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const StoreText('전체삭제', fontSize: 20, fontWeight: FontWeight.bold),
              const SizedBox(height: 16),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(fontSize: 16, color: Colors.black),
                  children: [
                    const TextSpan(text: '상품을 '),
                    TextSpan(text: '전체삭제', style: const TextStyle(color: Colors.red)),
                    const TextSpan(text: ' 하시겠습니까?'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black54,
                      minimumSize: const Size(100, 40),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    child: const StoreText('취소', color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  // 전체삭제 버튼
                    ElevatedButton(
                      onPressed: () async {
                        await _deleteAllOnServer();   // 서버 응답 기다림
                        Navigator.of(context).pop();
                      },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      minimumSize: const Size(100, 40),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    child: const StoreText('확인', color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 개별 상품 삭제 확인 다이얼로그
  void _showDeleteItemDialog(int idx) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('상품삭제',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(fontSize: 16, color: Colors.black),
                  children: [
                    const TextSpan(text: '해당 상품을 '),
                    TextSpan(text: '삭제', style: const TextStyle(color: Colors.red)),
                    const TextSpan(text: ' 하시겠습니까?'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black54,
                      minimumSize: const Size(100, 40),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    child: const Text('취소', style: TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(width: 16),
                  // 개별삭제 버튼
                    ElevatedButton(
                      onPressed: () async {
                        await _deleteOneOnServer(idx);  // 서버 응답 기다림
                        Navigator.of(context).pop();
                      },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      minimumSize: const Size(100, 40),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    child: const Text('확인', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const StoreText('재고관리 (편집)', color: Colors.black, fontWeight: FontWeight.bold),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      backgroundColor: const Color(0xFFF2F5FD),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 검색창
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: '검색어를 입력하세요...',
                  icon: Icon(Icons.search),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 전체제품 + 전체삭제 / 완료 버튼
            Row(
              children: [
                const StoreText('전체제품', fontSize: 18, fontWeight: FontWeight.bold),
                const Spacer(),
                ElevatedButton(
                  onPressed: _showDeleteAllDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: const StoreText('전체삭제', color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE1E3E8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: const StoreText('완료', color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 편집 모드 상품 리스트
            Expanded(
              child: _editableItems.isEmpty
                  ? const Center(child: StoreText('삭제할 항목이 없습니다.'))
                  : ListView.builder(
                      itemCount: _editableItems.length,
                      padding: const EdgeInsets.only(top: 8, bottom: 8),
                      itemBuilder: (context, idx) {
                        final itm = _editableItems[idx];
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: Colors.white, borderRadius: BorderRadius.circular(20)),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  itm['imageBytes'] as Uint8List,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 16),
                                  decoration: BoxDecoration(
                                      color: const Color(0xFFF2F5FD),
                                      borderRadius: BorderRadius.circular(20)),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(itm['name'] as String,
                                              style: const TextStyle(
                                                  fontSize: 20, fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 8),
                                          Text(itm['price'] as String,
                                              style: const TextStyle(
                                                  fontSize: 16, fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.remove_circle,
                                          color: Colors.red,
                                          size: 32,
                                        ),
                                        onPressed: () => _showDeleteItemDialog(idx),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}