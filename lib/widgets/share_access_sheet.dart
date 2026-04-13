import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;
import 'package:qr/qr.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import '../models/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class ShareAccessSheet extends StatefulWidget {
  const ShareAccessSheet({super.key});

  @override
  State<ShareAccessSheet> createState() => _ShareAccessSheetState();
}

class _ShareAccessSheetState extends State<ShareAccessSheet> {
  late List<int> _selectedDeviceIds;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    _selectedDeviceIds = state.devices.map((d) => d.id).toList();
  }

  void _toggleDevice(int id) {
    setState(() {
      if (_selectedDeviceIds.contains(id)) {
        _selectedDeviceIds.remove(id);
      } else {
        _selectedDeviceIds.add(id);
      }
    });
  }

  void _saveQRCode(BuildContext context) {
    // Save QR code to device gallery/downloads
    final c = colorsOf(context);
    _generateAndSaveQR(context, c);
  }

  Future<void> _generateAndSaveQR(BuildContext context, AppColors c) async {
    // Capture context before async operations
    final capturedContext = context;
    
    try {
      // Generate QR code data (invite link with selected device IDs)
      final inviteData = 'https://flameguard.app/invite?devices=${_selectedDeviceIds.join(',')}';
      
      // Create QR code
      final qrCode = QrCode.fromData(
        data: inviteData,
        errorCorrectLevel: QrErrorCorrectLevel.H,
      );
      
      // Generate QR image (200x200 pixels)
      const int moduleSize = 4;
      final size = ((qrCode as dynamic).size + 2) * moduleSize;
      
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      
      // Draw white background
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
        Paint()..color = Colors.white,
      );
      
      // Draw QR code modules
      final qrPaint = Paint()..color = Colors.black;
      for (int x = 0; x < (qrCode as dynamic).size; x++) {
        for (int y = 0; y < (qrCode as dynamic).size; y++) {
          if ((qrCode as dynamic).modules[y][x]) {
            canvas.drawRect(
              Rect.fromLTWH(
                ((x + 1) * moduleSize).toDouble(),
                ((y + 1) * moduleSize).toDouble(),
                moduleSize.toDouble(),
                moduleSize.toDouble(),
              ),
              qrPaint,
            );
          }
        }
      }
      
      final picture = recorder.endRecording();
      final image = await picture.toImage(size, size);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();
      
      // Save to gallery
      final result = await ImageGallerySaver.saveImage(pngBytes, name: 'flameguard_invite_qr');
      
      if (capturedContext.mounted) {
        if (result != null && result['isSuccess']) {
          ScaffoldMessenger.of(capturedContext).showSnackBar(
            SnackBar(
              content: const Text('QR code saved to gallery!'),
              backgroundColor: c.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        } else {
          ScaffoldMessenger.of(capturedContext).showSnackBar(
            SnackBar(
              content: const Text('Failed to save QR code'),
              backgroundColor: c.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    } catch (e) {
      if (capturedContext.mounted) {
        ScaffoldMessenger.of(capturedContext).showSnackBar(
          SnackBar(
            content: Text('Error saving QR code: $e'),
            backgroundColor: c.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    final state = context.watch<AppState>();
    final devices = state.devices;
    final isAllSelected = _selectedDeviceIds.length == devices.length;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: c.borderMid,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header (Truly Fixed)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Share Access', style: AppText.h(19, c.t1)),
                    const SizedBox(height: 2),
                    Text('Let others control your appliances',
                        style: AppText.body(12, c.t3)),
                  ],
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: c.raised,
                      shape: BoxShape.circle,
                    ),
                    child: AppIcon('x', size: 14, color: c.t2),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Fixed Top Section (QR + Buttons + Label)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                // QR Section
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: c.blue.withValues(alpha: 0.12),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Image.network(
                          'https://api.qrserver.com/v1/create-qr-code/?size=160x160&data=flameguard_access_invite',
                          width: 160,
                          height: 160,
                        ),
                  ),
                ),
                const SizedBox(height: 20),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: GhostButton(
                        label: 'Copy Link',
                        onPressed: () {
                           ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Invite link copied to clipboard!'),
                              backgroundColor: c.blue,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PrimaryButton(
                        label: 'Save QR',
                        onPressed: () => _saveQRCode(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Manage Access Label (Fixed)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('MANAGE ACCESS', style: AppText.lbl(c.t3)),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isAllSelected) {
                            _selectedDeviceIds = [];
                          } else {
                            _selectedDeviceIds = devices.map((d) => d.id).toList();
                          }
                        });
                      },
                      child: Text(
                        isAllSelected ? 'Deselect All' : 'Select All',
                        style: AppText.semi(12, c.blue),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),

          // Independent Scrollable Appliance List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 60),
              itemCount: devices.length,
              itemBuilder: (context, index) {
                final d = devices[index];
                final isSelected = _selectedDeviceIds.contains(d.id);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: () => _toggleDevice(d.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected ? c.blueFade : c.bg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? c.blue.withValues(alpha: 0.5) : c.border,
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isSelected ? c.blue.withValues(alpha: 0.1) : c.raised,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: AppIcon(d.icon, size: 16, color: isSelected ? c.blue : c.t3),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(d.name, style: AppText.semi(14, c.t1)),
                                Text(d.zone, style: AppText.body(11, c.t3)),
                              ],
                            ),
                          ),
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: isSelected ? c.blue : Colors.transparent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? c.blue : c.borderMid,
                                width: 1.5,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, size: 12, color: Colors.white)
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
