import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'transfer_screen.dart';

class QrScannerScreen extends StatefulWidget {
  final bool isStandalone;
  const QrScannerScreen({super.key, this.isStandalone = true});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> with SingleTickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController();
  bool _isScanned = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleBarcode(BarcodeCapture capture) {
    if (_isScanned) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        setState(() => _isScanned = true);
        final String code = barcode.rawValue!;
        
        // Success feedback
        HapticFeedback.vibrate();
        
        if (widget.isStandalone) {
          Navigator.pop(context, code);
        } else {
          // If in a tab, navigate to Transfer screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TransferScreen(initialRecipient: code),
            ),
          ).then((_) => setState(() => _isScanned = false));
        }
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.isStandalone ? AppBar(
        title: const Text('Scan QR Code'),
        backgroundColor: const Color(0xFFD32F2F),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _controller,
              builder: (context, state, child) {
                switch (state.torchState) {
                  case TorchState.off: return const Icon(Icons.flash_off);
                  case TorchState.on: return const Icon(Icons.flash_on);
                  default: return const Icon(Icons.flash_off);
                }
              },
            ),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ) : null,
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _handleBarcode,
          ),
          
          // Custom Overlay
          _buildOverlay(context),
          
          // Instructions
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text(
                  'Center the QR code in the frame',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ),
          
          if (!widget.isStandalone) 
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.flash_on, color: Colors.white),
                onPressed: () => _controller.toggleTorch(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOverlay(BuildContext context) {
    final scanAreaSize = 250.0;
    
    return Center(
      child: Container(
        width: scanAreaSize,
        height: scanAreaSize,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Stack(
          children: [
            // Corner Borders
            _buildCorner(top: true, left: true),
            _buildCorner(top: true, right: true),
            _buildCorner(bottom: true, left: true),
            _buildCorner(bottom: true, right: true),
            
            // Animated Scan Line
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Positioned(
                  top: _animationController.value * (scanAreaSize - 4),
                  left: 10,
                  right: 10,
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD32F2F).withValues(alpha: 0.8),
                          blurRadius: 4,
                          spreadRadius: 2,
                        ),
                      ],
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFD32F2F).withValues(alpha: 0.1),
                          const Color(0xFFD32F2F),
                          const Color(0xFFD32F2F).withValues(alpha: 0.1),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCorner({bool top = false, bool bottom = false, bool left = false, bool right = false}) {
    const length = 20.0;
    const thickness = 4.0;
    const color = Color(0xFFD32F2F);
    
    return Positioned(
      top: top ? 0 : null,
      bottom: bottom ? 0 : null,
      left: left ? 0 : null,
      right: right ? 0 : null,
      child: SizedBox(
        width: length,
        height: length,
        child: Stack(
          children: [
            if (top) Positioned(top: 0, left: 0, right: 0, child: Container(height: thickness, color: color)),
            if (bottom) Positioned(bottom: 0, left: 0, right: 0, child: Container(height: thickness, color: color)),
            if (left) Positioned(top: 0, bottom: 0, left: 0, child: Container(width: thickness, color: color)),
            if (right) Positioned(top: 0, bottom: 0, right: 0, child: Container(width: thickness, color: color)),
          ],
        ),
      ),
    );
  }
}
