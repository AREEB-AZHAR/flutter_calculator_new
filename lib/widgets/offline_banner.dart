import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';

/// An ambient, animated notification banner informing the user when the app is offline.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ConnectivityService.isOnlineNotifier,
      builder: (context, isOnline, _) {
        return AnimatedCrossFade(
          duration: const Duration(milliseconds: 300),
          crossFadeState: isOnline ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.amber.shade900,
                  Colors.amber.shade800,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.cloud_off_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'You are offline. Your changes are saved locally and will sync when reconnected.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.25,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => ConnectivityService.checkOnline(),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.refresh_rounded, color: Colors.white, size: 12),
                        SizedBox(width: 4),
                        Text(
                          'Retry',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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
}
