import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../managementEditPage/management_edit_page.dart';
import '../socket_service.dart';
import '../fontstyle.dart';

class ManagementPage extends StatefulWidget {
  const ManagementPage({super.key});
  @override
  State<ManagementPage> createState() => _ManagementPageState();
}

class _ManagementPageState extends State<ManagementPage> {
  final SocketService _svc = SocketService();
  late final socket;
  final ImagePicker _picker = ImagePicker();

  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  late final TextEditingController _searchController;
  String _searchTerm = '';

  @override
  void initState() {
    super.initState();
    socket = _svc.socket;
    _initializeSocket();
    _searchController = TextEditingController();
    _searchController.addListener(() {
      setState(() {
        _searchTerm = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    socket.off('products');
    socket.off('error');
    socket.off('connect');
    socket.off('add_success');
    socket.off('add_error');
    _searchController.dispose();
    super.dispose();
  }

  void _initializeSocket() {
    socket.connect();
    socket.off('connect');
    socket.on('connect', (_) {
      _loadProducts();
    });
    socket.off('error');
    socket.on('error', (err) {
      _errorMessage = '연결 오류: $err';
      _handleError();
    });
    socket.off('products');
    socket.on('products', _onProducts);
    socket.off('products_error');
    socket.on('products_error', (err) {
      _errorMessage = '서버 오류: $err';
      _handleError();
    });
  }

  void _showEditProductDialog(Map<String, dynamic> itm) {
    showDialog(
      context: context,
      builder: (context) {
        Uint8List? pickedImage = itm['imageBytes'] as Uint8List;
        final nameCtrl = TextEditingController(text: itm['name'] as String);
        int price = int.tryParse((itm['price'] as String).replaceAll('원', '')) ?? 0;
        int stock = itm['stock'] as int;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F5FD),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const StoreText(
                          '상품 이미지',
                          fontSize: 22,
                        ),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black12,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () async {
                        final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
                        if (file != null) {
                          final bytes = await file.readAsBytes();
                          setStateDialog(() => pickedImage = bytes);
                        }
                      },
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
                          ],
                        ),
                        child: pickedImage == null
                            ? const Icon(Icons.add, size: 40, color: Colors.black54)
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.memory(pickedImage!, fit: BoxFit.cover),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        hintText: '상품명을 입력해주세요...',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const StoreText('가격', fontSize: 16),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 48,
                                child: TextField(
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                    suffixText: '원',
                                  ),
                                  controller: TextEditingController(text: price.toString()),
                                  onChanged: (val) {
                                    price = int.tryParse(val) ?? 0;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const StoreText('재고', fontSize: 16),
                              const SizedBox(height: 8),
                              Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline),
                                      iconSize: 24,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                                      onPressed: () {
                                        if (stock > 0) setStateDialog(() => stock--);
                                      },
                                    ),
                                    Flexible(
                                      child: StoreText(
                                        '$stock',
                                        fontSize: 16,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline),
                                      iconSize: 24,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                                      onPressed: () => setStateDialog(() => stock++),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () {
                                socket.emit('delete_product', {'product_name': nameCtrl.text});
                                socket.once('delete_success', (_) {
                                  Navigator.of(context).pop();
                                });
                                socket.once('delete_error', (err) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: StoreText('상품 삭제 실패: ${err['error'] ?? err}'))
                                  );
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                elevation: 2,
                              ),
                              child: const StoreText(
                                '삭제',
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () {
                                if (nameCtrl.text.isEmpty || pickedImage == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: StoreText('상품명과 이미지를 모두 입력해주세요'))
                                  );
                                  return;
                                }
                                final img64 = base64Encode(pickedImage!);
                                final payload = {
                                  'product_name': nameCtrl.text,
                                  'product_price': price,
                                  'product_stock': stock,
                                  'product_image': img64,
                                };
                                socket.emit('update_product', payload);
                                socket.once('update_success', (_) {
                                  Navigator.of(context).pop();
                                });
                                socket.once('update_error', (err) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: StoreText('상품 수정 실패: ${err['error'] ?? err}'))
                                  );
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[900],
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                elevation: 2,
                              ),
                              child: const StoreText(
                                '수정',
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _loadProducts() {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });
    socket.emit('get_products');
  }

  void _onProducts(dynamic data) {
    try {
      final loaded = <Map<String, dynamic>>[];
      for (var raw in data) {
        final m = Map<String, dynamic>.from(raw);
        final bytes = base64Decode(m['product_image'] as String);
        final stock = (m['product_stock'] as num).toInt();
        final priceValue = (m['product_price'] as num).toInt();
        loaded.add({
          'imageBytes': bytes,
          'name': m['product_name'],
          'price': '${priceValue}원',
          'stock': stock,
        });
      }
      setState(() {
        _items = loaded;
        _isLoading = false;
        _hasError = false;
      });
    } catch (e) {
      _errorMessage = '데이터 처리 오류: $e';
      _handleError();
    }
  }

  void _handleError() {
    if (mounted) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showErrorSnackbar(_errorMessage!);
      });
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: StoreText(message)),
    );
  }

  void _showAddProductDialog() {
    showDialog(
      context: context,
      builder: (context) {
        Uint8List? pickedImage;
        final nameCtrl = TextEditingController();
        int price = 0;
        int stock = 0;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F5FD),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const StoreText(
                          '상품 이미지',
                          fontSize: 22,
                        ),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black12,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () async {
                        final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
                        if (file != null) {
                          final bytes = await file.readAsBytes();
                          setStateDialog(() => pickedImage = bytes);
                        }
                      },
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
                          ],
                        ),
                        child: pickedImage == null
                            ? const Icon(Icons.add, size: 40, color: Colors.black54)
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.memory(pickedImage!, fit: BoxFit.cover),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        hintText: '상품명을 입력해주세요...',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const StoreText('가격', fontSize: 16),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 48,
                                child: TextField(
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                    suffixText: '원',
                                  ),
                                  onChanged: (val) {
                                    price = int.tryParse(val) ?? 0;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const StoreText('재고', fontSize: 16),
                              const SizedBox(height: 8),
                              Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline),
                                      iconSize: 24,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                                      onPressed: () {
                                        if (stock > 0) setStateDialog(() => stock--);
                                      },
                                    ),
                                    Flexible(
                                      child: StoreText(
                                        '$stock',
                                        fontSize: 16,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline),
                                      iconSize: 24,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                                      onPressed: () => setStateDialog(() => stock++),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          if (nameCtrl.text.isEmpty || pickedImage == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: StoreText('상품명과 이미지를 모두 입력해주세요'))
                            );
                            return;
                          }
                          final img64 = base64Encode(pickedImage!);
                          socket.emit('add_product', {
                            'product_name': nameCtrl.text,
                            'product_price': price,
                            'product_stock': stock,
                            'product_image': img64,
                          });
                          socket.once('add_success', (_) {
                            Navigator.of(context).pop();
                          });
                          socket.once('add_error', (err) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: StoreText('상품 추가 실패: ${err['error'] ?? err}'))
                            );
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[900],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          elevation: 2,
                        ),
                        child: const StoreText(
                          '등록',
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null && _hasError) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showErrorSnackbar(_errorMessage!);
        _errorMessage = null;
      });
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        centerTitle: true,
        title: const StoreText('재고관리'),
        actions: const [
          Padding(padding: EdgeInsets.only(right: 16), child: Icon(Icons.home, color: Colors.black)),
        ],
      ),
      backgroundColor: const Color(0xFFF2F5FD),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBar(),
            const SizedBox(height: 20),
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildProductList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue[900],
        onPressed: _showAddProductDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchBar() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
        child: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            border: InputBorder.none,
            hintText: '검색어를 입력하세요...',
            icon: Icon(Icons.search),
          ),
        ),
      );

  Widget _buildHeader(BuildContext context) => Row(
        children: [
          const StoreText('전체제품', fontSize: 18),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.blue[900]),
            tooltip: '새로고침',
            onPressed: _loadProducts,
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _items.isEmpty
                ? null
                : () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => EditManagementPage(socket: socket, items: _items)))
                    .then((_) => _loadProducts()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[900],
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: const StoreText(
              '편집',
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ],
      );

  Widget _buildProductList() {
    final displayed = _searchTerm.isEmpty
        ? _items
        : _items.where((itm) =>
            (itm['name'] as String).toLowerCase().contains(_searchTerm.toLowerCase())
          ).toList();
    if (_isLoading) return const Expanded(child: Center(child: CircularProgressIndicator()));
    if (_hasError) {
      return Expanded(
        child: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const StoreText('데이터를 불러오는데 실패했습니다'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadProducts,
              child: const StoreText('다시 시도', fontSize: 16),
            ),
          ]),
        ),
      );
    }
    if (displayed.isEmpty) return const Expanded(child: Center(child: StoreText('등록된 제품이 없습니다')));
    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        itemCount: displayed.length,
        itemBuilder: (context, idx) {
          final itm = displayed[idx];
          final bool isSufficient = (itm['stock'] as int) >= 5;
          return GestureDetector(
            onTap: () => _showEditProductDialog(itm),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(itm['imageBytes'] as Uint8List, width: 60, height: 60, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(color: const Color(0xFFF2F5FD), borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            StoreText(itm['name'] as String, fontSize: 20),
                            const SizedBox(height: 4),
                            StoreText(itm['price'] as String, fontSize: 16),
                          ]),
                          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            StoreText(
                              isSufficient ? '재고충분' : '재고부족',
                              fontSize: 16,
                              color: isSufficient ? Colors.blue : Colors.red,
                            ),
                            const SizedBox(height: 4),
                            StoreText('${itm['stock']}개', fontSize: 14),
                          ]),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}