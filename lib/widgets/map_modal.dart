import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../provider/font_size_provider.dart';
import '../theme/app_theme.dart' as app_theme_config;

class MapModalWidget extends StatefulWidget {
  final dynamic location;

  const MapModalWidget({
    super.key,
    required this.location,
  });

  @override
  State<MapModalWidget> createState() => _MapModalWidgetState();
}

class _MapModalWidgetState extends State<MapModalWidget> {
  GoogleMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    final colors = app_theme_config.AppColorScheme.light();
    final locationName = widget.location['location_name'] ?? 'ไม่ระบุชื่อสถานที่';
    final locationCode = widget.location['location_code'] ?? '';
    final address = widget.location['address'] ?? '';
    final latitude = widget.location['latitude'] ?? '';
    final longitude = widget.location['longitude'] ?? '';
    final jobCharacteristic = widget.location['job_characteristic'] ?? '';

    // Create coordinates string for display
    String coordinates = '';
    if (latitude.isNotEmpty && longitude.isNotEmpty) {
      coordinates = '$latitude, $longitude';
    }

    return Consumer<FontSizeProvider>(
      builder: (context, fontProvider, child) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              
              // Header with location icon
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.location_on,
                        color: colors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ข้อมูลสถานที่',
                            style: GoogleFonts.notoSansThai(
                              fontSize: fontProvider.getScaledFontSize(18.0),
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                          ),
                          if (locationCode.isNotEmpty)
                            Text(
                              locationCode,
                              style: GoogleFonts.notoSansThai(
                                fontSize: fontProvider.getScaledFontSize(14.0),
                                color: colors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () {
                            _openExternalMap(context, widget.location);
                          },
                          icon: Icon(Icons.open_in_new, color: colors.primary),
                          tooltip: 'เปิด Google Maps',
                          constraints: BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          padding: EdgeInsets.all(4),
                        ),
                        SizedBox(width: 8),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close, color: colors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Location details
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Location name
                    _buildInfoRow(
                      'ชื่อสถานที่',
                      locationName,
                      Icons.business,
                      colors,
                      fontProvider,
                    ),
                    
                    if (address.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        'ที่อยู่',
                        address,
                        Icons.home_outlined,
                        colors,
                        fontProvider,
                      ),
                    ],
                    
                    if (coordinates.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        'พิกัด',
                        coordinates,
                        Icons.gps_fixed,
                        colors,
                        fontProvider,
                      ),
                    ],
                    
                    if (jobCharacteristic.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        'ประเภทงาน',
                        jobCharacteristic,
                        Icons.work_outline,
                        colors,
                        fontProvider,
                      ),
                    ],
                  ],
                ),
              ),
              
              // Google Map
              Container(
                margin: const EdgeInsets.all(20),
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.divider),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildGoogleMap(latitude, longitude, locationCode),
                ),
              ),
              
              // Close button at bottom
              Container(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    label: Text(
                      'ปิด',
                      style: GoogleFonts.notoSansThai(
                        fontSize: fontProvider.getScaledFontSize(14.0),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.textSecondary,
                      side: BorderSide(color: colors.divider),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGoogleMap(String latitude, String longitude, String locationCode) {
    // Parse coordinates
    double? lat, lng;
    try {
      if (latitude.isNotEmpty && longitude.isNotEmpty) {
        lat = double.parse(latitude);
        lng = double.parse(longitude);
      }
    } catch (e) {
      // If parsing fails, show error message
    }

    // Default location (Bangkok) if no coordinates
    if (lat == null || lng == null) {
      lat = 13.7563;
      lng = 100.5018;
    }

    final LatLng center = LatLng(lat, lng);
    
    // Create marker
    final Set<Marker> markers = {
      Marker(
        markerId: const MarkerId('location'),
        position: center,
        infoWindow: InfoWindow(
          title: locationCode.isNotEmpty ? locationCode : 'สถานที่',
          snippet: 'คลิกเพื่อดูรายละเอียด',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    };

    return GoogleMap(
      onMapCreated: (GoogleMapController controller) {
        setState(() {
          _mapController = controller;
        });
      },
      initialCameraPosition: CameraPosition(
        target: center,
        zoom: 15.0,
      ),
      markers: markers,
      mapType: MapType.normal,
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: true,
      mapToolbarEnabled: false,
      compassEnabled: true,
      rotateGesturesEnabled: true,
      scrollGesturesEnabled: true,
      tiltGesturesEnabled: true,
      zoomGesturesEnabled: true,
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon,
    dynamic colors,
    FontSizeProvider fontProvider,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: colors.textSecondary,
          size: 16,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.notoSansThai(
                  fontSize: fontProvider.getScaledFontSize(12.0),
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.notoSansThai(
                  fontSize: fontProvider.getScaledFontSize(14.0),
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _openExternalMap(BuildContext context, dynamic location) async {
    final latitude = location['latitude'] ?? '';
    final longitude = location['longitude'] ?? '';
    final locationName = location['location_name'] ?? '';

    // Try multiple URL schemes for better compatibility
    List<String> urlsToTry = [];

    if (latitude.isNotEmpty && longitude.isNotEmpty) {
      // Android Google Maps App URL schemes
      if (Platform.isAndroid) {
        urlsToTry.addAll([
          'google.navigation:q=$latitude,$longitude', // Direct navigation
          'geo:$latitude,$longitude?q=$latitude,$longitude', // Geo protocol
          'https://maps.google.com/?q=$latitude,$longitude', // Web fallback
        ]);
        
        // Add location name if available
        if (locationName.isNotEmpty) {
          final encodedName = Uri.encodeComponent(locationName);
          urlsToTry.insert(0, 'geo:$latitude,$longitude?q=$latitude,$longitude($encodedName)');
        }
      }
      // iOS Google Maps URLs  
      else if (Platform.isIOS) {
        if (locationName.isNotEmpty) {
          final encodedName = Uri.encodeComponent(locationName);
          urlsToTry.addAll([
            'comgooglemaps://?q=$encodedName&center=$latitude,$longitude', // Google Maps App
            'https://maps.google.com/?q=$encodedName+$latitude,$longitude', // Web fallback
          ]);
        } else {
          urlsToTry.addAll([
            'comgooglemaps://?center=$latitude,$longitude&zoom=15', // Google Maps App
            'https://maps.google.com/?q=$latitude,$longitude', // Web fallback
          ]);
        }
      }
      // Web fallback for other platforms
      else {
        if (locationName.isNotEmpty) {
          final encodedName = Uri.encodeComponent(locationName);
          urlsToTry.add('https://www.google.com/maps/search/?api=1&query=$encodedName+$latitude,$longitude');
        } else {
          urlsToTry.add('https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');
        }
      }
    }
    // Fallback: search by location name only
    else if (locationName.isNotEmpty) {
      final encodedName = Uri.encodeComponent(locationName);
      if (Platform.isAndroid) {
        urlsToTry.addAll([
          'geo:0,0?q=$encodedName',
          'https://maps.google.com/?q=$encodedName',
        ]);
      } else if (Platform.isIOS) {
        urlsToTry.addAll([
          'comgooglemaps://?q=$encodedName',
          'https://maps.google.com/?q=$encodedName',
        ]);
      } else {
        urlsToTry.add('https://www.google.com/maps/search/?api=1&query=$encodedName');
      }
    }

    // Try each URL until one works
    bool success = false;
    for (String urlString in urlsToTry) {
      try {
        final Uri url = Uri.parse(urlString);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
          success = true;
          break;
        }
      } catch (e) {
        // Continue to next URL
        continue;
      }
    }

    // Show appropriate message
    if (success) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'เปิด Google Maps สำหรับ ${location['location_name'] ?? 'สถานที่นี้'}',
              style: GoogleFonts.notoSansThai(),
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              urlsToTry.isEmpty 
                ? 'ไม่พบข้อมูลตำแหน่งสำหรับสถานที่นี้'
                : 'ไม่สามารถเปิด Google Maps ได้',
              style: GoogleFonts.notoSansThai(),
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}