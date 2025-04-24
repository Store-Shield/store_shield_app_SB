import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService _instance = SocketService._();
  late final IO.Socket socket;

  factory SocketService() => _instance;

  SocketService._() {
    socket = IO.io(
      'https://857c-121-132-154-44.ngrok-free.app',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .build(),
    );
    socket.on('connect', (_) => print('🔗 소켓 연결됨: ${socket.id}'));
    socket.on('disconnect', (_) => print('🔌 소켓 끊김'));
    socket.on('error', (e) => print('⚠️ 소켓 에러: $e'));
  }
}