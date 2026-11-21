import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/models.dart';
import '../providers/product_search_provider.dart';
import '../utils/app_colors.dart';
import 'add_portion_sheet.dart';
import 'create_custom_product_screen.dart';

/// Fullscreen barcode scanner using [MobileScanner] with custom viewfinder overlay,
/// torch toggle, camera switcher, haptic feedback, and automatic lookup against
/// local Hive and Open Food Facts database.
class BarcodeScannerScreen extends ConsumerStatefulWidget {
  final MealType mealType;
  final DateTime? date;

  const BarcodeScannerScreen({
    super.key,
    this.mealType = MealType.breakfast,
    this.date,
  });

  @override
  ConsumerState<BarcodeScannerScreen> createState() =>
      _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends ConsumerState<BarcodeScannerScreen> {
  late final MobileScannerController _scannerController;
  bool _isProcessing = false;
  bool _isTorchOn = false;
  CameraFacing _cameraFacing = CameraFacing.back;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _toggleTorch() async {
    try {
      await _scannerController.toggleTorch();
      setState(() {
        _isTorchOn = !_isTorchOn;
      });
    } catch (_) {}
  }

  void _switchCamera() async {
    try {
      await _scannerController.switchCamera();
      setState(() {
        _cameraFacing = _cameraFacing == CameraFacing.back
            ? CameraFacing.front
            : CameraFacing.back;
      });
    } catch (_) {}
  }

  Future<void> _handleBarcodeDetected(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final rawCode = barcodes.first.rawValue;
    if (rawCode == null || rawCode.trim().isEmpty) return;

    final barcode = rawCode.trim();

    setState(() => _isProcessing = true);
    HapticFeedback.mediumImpact();

    try {
      final productRepo = ref.read(productRepositoryProvider);

      // Show temporary loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Text('Wyszukiwanie kodu: $barcode...'),
              ],
            ),
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      // Query local Hive, then Open Food Facts remote fallback
      final product = await productRepo.findProductByBarcode(barcode);

      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (product != null) {
        // Product found! Open portion sheet
        final entry = await AddPortionSheet.show(
          context,
          product: product,
          initialMealType: widget.mealType,
          date: widget.date,
        );

        if (mounted && entry != null) {
          // If product was logged, pop scanner back to previous screen
          Navigator.of(context).pop(entry);
          return;
        }
      } else {
        // Product not found in local or remote database
        await _showNotFoundDialog(barcode);
      }
    } catch (e) {
      debugPrint('Failed to scan barcode: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nie udało się odczytać kodu kreskowego.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        // Debounce before allowing next scan
        await Future.delayed(const Duration(milliseconds: 1200));
        if (mounted) {
          setState(() => _isProcessing = false);
        }
      }
    }
  }

  Future<void> _showNotFoundDialog(String barcode) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.search_off_rounded, color: AppColors.warning),
            SizedBox(width: 10),
            Text('Nie znaleziono'),
          ],
        ),
        content: Text(
          'Nie odnaleziono produktu dla kodu kreskowego:\n\n$barcode\n\nCzy chcesz utworzyć własny produkt z tym kodem?',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Utwórz produkt'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      final newProduct = await Navigator.of(context).push<FoodProduct>(
        MaterialPageRoute(
          builder: (_) => CreateCustomProductScreen(initialBarcode: barcode),
        ),
      );

      if (mounted && newProduct != null) {
        // Open portion sheet for newly created product
        final entry = await AddPortionSheet.show(
          context,
          product: newProduct,
          initialMealType: widget.mealType,
          date: widget.date,
        );

        if (mounted && entry != null) {
          Navigator.of(context).pop(entry);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Stream
          MobileScanner(
            controller: _scannerController,
            onDetect: _handleBarcodeDetected,
          ),

          // Viewfinder Overlay
          _ViewfinderOverlay(isProcessing: _isProcessing),

          // Top App Bar Controls
          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.black.withOpacity(0.5),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: _isTorchOn
                            ? AppColors.primary
                            : Colors.black.withOpacity(0.5),
                        child: IconButton(
                          icon: Icon(
                            _isTorchOn
                                ? Icons.flash_on_rounded
                                : Icons.flash_off_rounded,
                            color: Colors.white,
                          ),
                          onPressed: _toggleTorch,
                        ),
                      ),
                      const SizedBox(width: 10),
                      CircleAvatar(
                        backgroundColor: Colors.black.withOpacity(0.5),
                        child: IconButton(
                          icon: const Icon(
                            Icons.cameraswitch_rounded,
                            color: Colors.white,
                          ),
                          onPressed: _switchCamera,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Bottom Instruction Banner
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.75),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Skieruj aparat na kod kreskowy produktu',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Obsługuje Open Food Facts i lokalną bazę produktów',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter rendering a darkened mask with a clear rounded viewfinder window
/// and green targeting corner brackets.
class _ViewfinderOverlay extends StatelessWidget {
  final bool isProcessing;

  const _ViewfinderOverlay({required this.isProcessing});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scanAreaSize = constraints.maxWidth * 0.75;
        final left = (constraints.maxWidth - scanAreaSize) / 2;
        final top = (constraints.maxHeight - scanAreaSize) / 2.3;

        return Stack(
          children: [
            // Darkened cut-out mask
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.65),
                BlendMode.srcOut,
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.transparent,
                      backgroundBlendMode: BlendMode.dstOut,
                    ),
                  ),
                  Positioned(
                    left: left,
                    top: top,
                    child: Container(
                      width: scanAreaSize,
                      height: scanAreaSize,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Viewfinder border corners
            Positioned(
              left: left,
              top: top,
              child: Container(
                width: scanAreaSize,
                height: scanAreaSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isProcessing ? AppColors.warning : AppColors.primary,
                    width: 2.5,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
