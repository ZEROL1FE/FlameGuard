import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../models/device_model.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class AddDeviceSheet extends StatefulWidget {
  final DeviceModel? device;
  const AddDeviceSheet({super.key, this.device});

  @override
  State<AddDeviceSheet> createState() => _AddDeviceSheetState();
}

class _AddDeviceSheetState extends State<AddDeviceSheet> {
  final _name = TextEditingController();
  final _customRoom = TextEditingController();
  String _zone = 'Living';
  String _type = 'fan';
  String _err = '';
  bool _showAllTypes = false;
  bool _showAllRooms = false;

  @override
  void initState() {
    super.initState();
    if (widget.device != null) {
      _name.text = widget.device!.name;
      final knownTypes = context.read<AppState>().deviceTypes;
      
      // Check if name matches a predefined type (case-insensitive)
      final matchingType = knownTypes.firstWhere(
        (t) => t.toLowerCase() == widget.device!.name.toLowerCase(),
        orElse: () => '',
      );
      
      if (matchingType.isNotEmpty) {
         _type = matchingType.toLowerCase();
      } else {
        _type = 'others';
      }
      
      final dZone = widget.device!.zone;
      final rooms = context.read<AppState>().rooms;
      if (rooms.contains(dZone)) {
        _zone = dZone;
      } else {
        _zone = 'Others';
        _customRoom.text = (dZone == 'Unknown Area') ? '' : dZone;
      }
    }
  }


  void _submit() {
    if (_name.text.trim().isEmpty) {
      setState(() => _err = 'Please enter a device name.');
      return;
    }

    const w = 500; // Default wattage
    final state = context.read<AppState>();
    String finalZone = _zone;

    if (_zone == 'Others') {
      final custom = _customRoom.text.trim();
      if (custom.isEmpty) {
        setState(() => _err = 'Please enter a name for the new area.');
        return;
      }
      state.addRoom(custom);
      finalZone = custom;
    }

    String finalType = _type;
    if (_type == 'others') {
      finalType = _name.text.trim();
      state.addType(finalType);
    }

    final name = _name.text.trim();
    if (widget.device != null) {
      // Update existing device
      final updatedDevice = widget.device!.copyWith(
        name: name,
        icon: finalType,
        zone: finalZone,
      );
      state.updateDeviceOnServer(updatedDevice).then((success) {
        if (success) {
          Navigator.pop(context);
        } else {
          setState(() => _err = 'Failed to update device');
        }
      });
    } else {
      // Add new device
      state.addDeviceToServer(
        name: name,
        zone: finalZone,
        icon: finalType,
        wattage: w,
      ).then((success) {
        if (success) {
          Navigator.pop(context);
        } else {
          setState(() => _err = 'Failed to add device');
        }
      });
    }
  }

  void _showManageRooms(BuildContext context) {
    final state = context.read<AppState>();
    showDialog(
      context: context,
      builder: (ctx) {
        final c = colorsOf(context);
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: double.maxFinite,
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: c.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: c.blueFade, borderRadius: BorderRadius.circular(10)),
                        child: AppIcon('others', size: 18, color: c.blue),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Manage Areas', style: AppText.h(18, c.t1)),
                          Text('Customize your home rooms', style: AppText.body(11, c.t3)),
                        ],
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: c.border.withValues(alpha: 0.5)),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: state.rooms.map((r) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                          decoration: BoxDecoration(
                            color: c.raised,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: c.border.withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(r, style: AppText.med(14, c.t1)),
                              Row(
                                children: [
                                  IconButton(
                                    icon: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(color: c.blueFade, shape: BoxShape.circle),
                                      child: Icon(Icons.edit_rounded, size: 16, color: c.blue),
                                    ),
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      _showRenameRoom(context, r);
                                    },
                                  ),
                                  IconButton(
                                    icon: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(color: c.red.withValues(alpha: 0.1), shape: BoxShape.circle),
                                      child: Icon(Icons.delete_outline_rounded, size: 16, color: c.red),
                                    ),
                                    onPressed: () {
                                      state.removeRoom(r);
                                      Navigator.pop(ctx);
                                      _showManageRooms(context); // Refresh
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: c.blue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(child: Text('Done', style: AppText.semi(14, Colors.white))),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRenameRoom(BuildContext context, String oldName) {
    final state = context.read<AppState>();
    final ctrl = TextEditingController(text: oldName);
    showDialog(
      context: context,
      builder: (ctx) {
        final c = colorsOf(context);
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: c.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rename Area', style: AppText.h(18, c.t1)),
                const SizedBox(height: 6),
                Text('Enter a new name for $oldName', style: AppText.body(12, c.t3)),
                const SizedBox(height: 20),
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  style: AppText.body(14, c.t1),
                  decoration: InputDecoration(
                    hintText: 'e.g. Living Area',
                    filled: true,
                    fillColor: c.bg,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: c.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: c.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: c.blue, width: 1.5)),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showManageRooms(context);
                        },
                        child: Text('Cancel', style: AppText.semi(14, c.t3)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (ctrl.text.trim().isNotEmpty) {
                            state.renameRoom(oldName, ctrl.text.trim());
                          }
                          Navigator.pop(ctx);
                          _showManageRooms(context);
                        },
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(color: c.blue, borderRadius: BorderRadius.circular(12)),
                          child: Center(child: Text('Rename', style: AppText.semi(14, Colors.white))),
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
  }

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    final state = context.watch<AppState>();
    
    // Sync local _zone if the room was renamed or deleted while this sheet was open
    if (widget.device != null && _zone != 'Others') {
      final current = state.devices.firstWhere((d) => d.id == widget.device!.id, 
          orElse: () => widget.device!);
      
      if (!state.rooms.contains(_zone)) {
        // If the device's actual zone (in AppState) is valid, sync to it (Handle Rename)
        if (state.rooms.contains(current.zone)) {
          _zone = current.zone;
        } else {
          // Truly deleted (Handle Delete)
          _zone = 'Unknown Area';
        }
      }
    } else if (widget.device == null && _zone != 'Others' && !state.rooms.contains(_zone)) {
      // For new devices, just clear to Unknown Area if the picked room is gone
      _zone = 'Unknown Area';
    }

    final content = Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20, widget.device == null ? 16 : 24, 20, 8),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(widget.device == null ? 'Final Details' : 'Edit Device Details', style: AppText.h(16, c.t1)),
            if (widget.device != null)
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                      color: c.raised,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: c.border)),
                  child: Center(child: AppIcon('x', size: 12, color: c.t3)),
                ),
              ),
          ]),
        ),
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('TYPE', style: AppText.lbl(c.t3)),
              const SizedBox(height: 9),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...state.deviceTypes
                      .take(_showAllTypes ? state.deviceTypes.length : 3)
                      .map((t) {
                    final sel = _type.toLowerCase() == t.toLowerCase();
                    final count = state.getDeviceCountByType(t);
                    return GestureDetector(
                      onTap: () => setState(() {
                        _type = t.toLowerCase();
                        _name.text = t; // Set name to type name
                        _err = '';
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: sel ? c.blueFade : c.raised,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: sel ? c.blue.withAlpha(80) : c.border),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          AppIcon(t, size: 13, color: sel ? c.blue : c.t3),
                          const SizedBox(width: 6),
                          Text(t, style: AppText.semi(11, sel ? c.blue : c.t2)),
                          if (count > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: sel ? c.blue.withValues(alpha: 0.2) : c.border,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text('$count', style: AppText.lbl(sel ? c.blue : c.t3).copyWith(fontSize: 8)),
                            ),
                          ],
                        ]),
                      ),
                    );
                  }),
                  GestureDetector(
                    onTap: () => setState(() {
                      _type = 'others';
                      // Clear if it matches a known type to prompt for a custom name
                      final knownTypes = state.deviceTypes;
                      if (knownTypes.any((t) => t.toLowerCase() == _name.text.toLowerCase())) {
                        _name.text = '';
                      }
                      _err = '';
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: _type == 'others' ? c.blueFade : c.raised,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: _type == 'others' ? c.blue.withAlpha(80) : c.border),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        AppIcon('others', size: 13, color: _type == 'others' ? c.blue : c.t3),
                        const SizedBox(width: 6),
                        Text('Others', style: AppText.semi(11, _type == 'others' ? c.blue : c.t2)),
                      ]),
                    ),
                  ),
                  if (!_showAllTypes && state.deviceTypes.length > 3)
                    GestureDetector(
                      onTap: () => setState(() => _showAllTypes = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: c.raised,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: c.border),
                        ),
                        child: Text('+ More', style: AppText.semi(11, c.blue)),
                      ),
                    ),
                ],
              ),
              if (_type == 'others') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _name,
                  style: AppText.body(13, c.t1),
                  cursorColor: c.blue,
                  onChanged: (_) => setState(() => _err = ''),
                  decoration: InputDecoration(
                    hintText: 'Enter custom device name',
                    hintStyle: AppText.body(13, c.t3),
                    filled: true,
                    fillColor: c.bg,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: c.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: c.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: c.blue, width: 1.5)),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('AREA / ROOM', style: AppText.lbl(c.t3)),
                  if (widget.device != null)
                    GestureDetector(
                      onTap: () => _showManageRooms(context),
                      child: Text('Manage', style: AppText.semi(10, c.blue)),
                    ),
                ],
              ),
              const SizedBox(height: 9),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...state.rooms
                      .take(_showAllRooms ? 100 : 3)
                      .map((z) {
                    final sel = _zone == z;
                    final count = state.getDeviceCountInRoom(z);
                    return GestureDetector(
                      onTap: () => setState(() => _zone = z),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: sel ? c.blueFade : c.raised,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: sel ? c.blue.withAlpha(80) : c.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(z, style: AppText.semi(11, sel ? c.blue : c.t2)),
                            if (count > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: sel ? c.blue.withValues(alpha: 0.2) : c.border,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text('$count', style: AppText.lbl(sel ? c.blue : c.t3).copyWith(fontSize: 8)),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
                  // "Others" chip
                  GestureDetector(
                    onTap: () => setState(() => _zone = 'Others'),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: _zone == 'Others' ? c.blueFade : c.raised,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: _zone == 'Others' ? c.blue.withAlpha(80) : c.border),
                      ),
                      child: Text('Others', style: AppText.semi(11, _zone == 'Others' ? c.blue : c.t2)),
                    ),
                  ),
                  if (!_showAllRooms && state.rooms.length > 3)
                    GestureDetector(
                      onTap: () => setState(() => _showAllRooms = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: c.raised,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: c.border),
                        ),
                        child: Text('+ More', style: AppText.semi(11, c.blue)),
                      ),
                    ),
                ],
              ),
              if (_zone == 'Others') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _customRoom,
                  style: AppText.body(13, c.t1),
                  cursorColor: c.blue,
                  decoration: InputDecoration(
                    hintText: 'Enter custom area name',
                    hintStyle: AppText.body(13, c.t3),
                    filled: true,
                    fillColor: c.bg,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: c.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: c.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: c.blue, width: 1.5)),
                  ),
                ),
              ],
              if (_err.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Text(_err, style: AppText.semi(11, c.red)),
                ),
            ]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 36),
          child: GestureDetector(
            onTap: _submit,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: c.blue,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: c.blue.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: Center(
                  child: Text(widget.device == null ? 'Add to Dashboard' : 'Save Changes', style: AppText.h(14, Colors.white))),
            ),
          ),
        ),
      ]);

    if (widget.device != null) {
      return Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: content,
      );
    }
    return content;
  }
}
