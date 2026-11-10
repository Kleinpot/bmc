import 'dart:async';

import 'package:flutter/material.dart';

class SimulatedNotificationBanner extends StatefulWidget {
  const SimulatedNotificationBanner({super.key});

  @override
  State<SimulatedNotificationBanner> createState() =>
      SimulatedNotificationBannerState();
}

class SimulatedNotificationBannerState
    extends State<SimulatedNotificationBanner> {
  Timer? _dismissTimer;
  String _title = '';
  String _message = '';
  IconData _icon = Icons.notifications_none_rounded;
  bool _isVisible = false;

  void show({
    required String title,
    required String message,
    IconData icon = Icons.notifications_none_rounded,
  }) {
    _dismissTimer?.cancel();
    setState(() {
      _title = title;
      _message = message;
      _icon = icon;
      _isVisible = true;
    });
    _dismissTimer = Timer(const Duration(seconds: 4), dismiss);
  }

  void dismiss() {
    _dismissTimer?.cancel();
    if (_isVisible && mounted) {
      setState(() => _isVisible = false);
    }
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !_isVisible,
      child: AnimatedSlide(
        offset: _isVisible ? Offset.zero : const Offset(0, -1.5),
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: _isVisible ? 1 : 0,
          duration: const Duration(milliseconds: 220),
          child: Material(
            color: Colors.white,
            elevation: 8,
            shadowColor: const Color(0x14202521),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF2EC),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      _icon,
                      size: 20,
                      color: const Color(0xFF39745A),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF202521),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _message,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF707771),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: dismiss,
                    tooltip: 'Dismiss notification',
                    icon: const Icon(Icons.close_rounded, size: 18),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
