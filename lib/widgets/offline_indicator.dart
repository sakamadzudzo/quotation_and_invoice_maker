import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class OfflineIndicator extends StatefulWidget {
  final Widget child;

  const OfflineIndicator({super.key, required this.child});

  @override
  State<OfflineIndicator> createState() => _OfflineIndicatorState();
}

class _OfflineIndicatorState extends State<OfflineIndicator> {
  late Connectivity _connectivity;
  ConnectivityResult _connectionStatus = ConnectivityResult.none;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _connectivity = Connectivity();
    _initConnectivity();
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  Future<void> _initConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
    }
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
    setState(() {
      _connectionStatus = result;
      _isOnline = result != ConnectivityResult.none;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (!_isOnline)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.orange,
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              child: Row(
                children: [
                  const Icon(
                    Icons.wifi_off,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Offline - Google Drive sync unavailable',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                    onPressed: () => setState(() => _isOnline = true),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class ConnectivityBanner extends StatelessWidget {
  final bool isOnline;
  final VoidCallback? onDismiss;

  const ConnectivityBanner({
    super.key,
    required this.isOnline,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    if (isOnline) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      color: Colors.red.shade700,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_off,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'No internet connection. Some features may be limited.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onDismiss != null)
            IconButton(
              icon: const Icon(
                Icons.close,
                color: Colors.white,
                size: 20,
              ),
              onPressed: onDismiss,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}

class NetworkStatusWidget extends StatefulWidget {
  final Widget Function(BuildContext context, bool isOnline) builder;

  const NetworkStatusWidget({super.key, required this.builder});

  @override
  State<NetworkStatusWidget> createState() => _NetworkStatusWidgetState();
}

class _NetworkStatusWidgetState extends State<NetworkStatusWidget> {
  late Connectivity _connectivity;
  ConnectivityResult _connectionStatus = ConnectivityResult.none;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _connectivity = Connectivity();
    _initConnectivity();
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  Future<void> _initConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
    }
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    setState(() {
      _connectionStatus = result;
      _isOnline = result != ConnectivityResult.none;
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _isOnline);
  }
}