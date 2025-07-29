import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../provider/font_size_provider.dart';

class TripTimelineWidget extends StatelessWidget {
  final List<dynamic> tripLocations;

  const TripTimelineWidget({
    super.key,
    required this.tripLocations,
  });

  @override
  Widget build(BuildContext context) {
    if (tripLocations.isEmpty) {
      return const Center(
        child: Text('ไม่พบข้อมูลแผนการเดินทาง'),
      );
    }

    return Consumer<FontSizeProvider>(
      builder: (context, fontSizeProvider, child) {
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.05),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.route,
                      color: Colors.blue[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'แผนการเดินทาง',
                      style: TextStyle(
                        fontSize: fontSizeProvider.getScaledFontSize(16),
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _buildTimelineItems(context, fontSizeProvider),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildTimelineItems(BuildContext context, FontSizeProvider fontSizeProvider) {
    return tripLocations.map<Widget>((location) {
      return Flexible(
        flex: 1,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: _buildTimelineItem(context, location, fontSizeProvider),
        ),
      );
    }).toList();
  }

  Widget _buildTimelineItem(BuildContext context, dynamic location, FontSizeProvider fontSizeProvider) {
    final locationName = location['location_name'] ?? '';
    final locationCode = location['location_code'] ?? '';
    final jobCharacteristic = location['job_characteristic'] ?? '';
    
    // Get color based on job characteristic
    Color iconColor = _getJobCharacteristicColor(jobCharacteristic);
    Color backgroundColor = iconColor.withValues(alpha: 0.1);
    
    return GestureDetector(
      onTap: () => _openLocationMap(context, location),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Timeline dot with truck icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
              border: Border.all(color: iconColor, width: 2),
              boxShadow: [
                BoxShadow(
                  color: iconColor.withValues(alpha: 0.3),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.local_shipping,
                  color: iconColor,
                  size: 18,
                ),
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: iconColor, width: 1),
                    ),
                    child: Icon(
                      Icons.location_on,
                      color: iconColor,
                      size: 8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 6),
        // Location info
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Location code
            Text(
              locationCode,
              style: TextStyle(
                fontSize: fontSizeProvider.getScaledFontSize(12),
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            // Location name
            Text(
              locationName,
              style: TextStyle(
                fontSize: fontSizeProvider.getScaledFontSize(9),
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Job characteristic badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: iconColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                _getJobCharacteristicShort(jobCharacteristic),
                style: TextStyle(
                  fontSize: fontSizeProvider.getScaledFontSize(8),
                  fontWeight: FontWeight.w500,
                  color: iconColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        ],
      ),
    );
  }


  Color _getJobCharacteristicColor(String jobCharacteristic) {
    final characteristic = jobCharacteristic.toLowerCase();
    
    if (characteristic.contains('pick up') || characteristic.contains('รับตู้')) {
      return Colors.blue;
    } else if (characteristic.contains('delivery') || characteristic.contains('ส่งสินค้า')) {
      return Colors.green;
    } else if (characteristic.contains('return') || characteristic.contains('คืนตู้')) {
      return Colors.orange;
    } else if (characteristic.contains('drop') || characteristic.contains('วางตู้')) {
      return Colors.purple;
    }
    
    return Colors.grey;
  }

  String _getJobCharacteristicShort(String jobCharacteristic) {
    final characteristic = jobCharacteristic.toLowerCase();
    
    if (characteristic.contains('pick up') || characteristic.contains('รับตู้')) {
      return 'รับตู้';
    } else if (characteristic.contains('delivery') || characteristic.contains('ส่งสินค้า')) {
      return 'ส่งสินค้า';
    } else if (characteristic.contains('return') || characteristic.contains('คืนตู้')) {
      return 'คืนตู้';
    } else if (characteristic.contains('drop') || characteristic.contains('วางตู้')) {
      return 'วางตู้';
    }
    
    return 'อื่นๆ';
  }

  void _openLocationMap(BuildContext context, dynamic location) async {
    final mapUrl = location['map_url'] ?? '';
    final latitude = location['latitude'] ?? '';
    final longitude = location['longitude'] ?? '';
    final locationName = location['location_name'] ?? '';

    String urlToOpen = '';

    // Try to use the provided map_url first
    if (mapUrl.isNotEmpty) {
      urlToOpen = mapUrl;
    } 
    // If no map_url, try to create one from coordinates
    else if (latitude.isNotEmpty && longitude.isNotEmpty) {
      urlToOpen = 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    }
    // Last resort: search by location name
    else if (locationName.isNotEmpty) {
      final encodedName = Uri.encodeComponent(locationName);
      urlToOpen = 'https://www.google.com/maps/search/?api=1&query=$encodedName';
    }

    if (urlToOpen.isNotEmpty) {
      try {
        final Uri url = Uri.parse(urlToOpen);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          if (context.mounted) {
            _showMapErrorDialog(context, 'ไม่สามารถเปิดแผนที่ได้');
          }
        }
      } catch (e) {
        if (context.mounted) {
          _showMapErrorDialog(context, 'เกิดข้อผิดพลาดในการเปิดแผนที่: $e');
        }
      }
    } else {
      if (context.mounted) {
        _showMapErrorDialog(context, 'ไม่พบข้อมูลตำแหน่งสำหรับสถานที่นี้');
      }
    }
  }

  void _showMapErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('ไม่สามารถเปิดแผนที่ได้'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ตกลง'),
            ),
          ],
        );
      },
    );
  }
}