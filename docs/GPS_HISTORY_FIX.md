# GPS History API Fix - Field Name Mapping

## Problem
The GPS history playback feature was showing all markers at position (0.0, 0.0) because the API response field names didn't match what the Flutter app was expecting.

## Root Cause
The GPS history API (`/api/gps_history_map_data/`) returns data with **abbreviated field names**, while the live tracking API uses **full field names**:

### History API Field Names (Abbreviated)
```json
{
  "et": "2025-08-22T01:30:48.368514Z",    // entry time
  "ps": "EA",                              // packet status
  "lat": "26.192962",                      // latitude
  "lon": "91.752908",                      // longitude
  "s": "0.0",                              // speed
  "h": "1.26",                             // heading
  "sat": "35",                             // satellites
  "gpsS": "1",                             // GPS status
  "no": "IND airt",                        // vehicle number
  "igs": "0",                              // ignition status
  "mps": "0",                              // main power status
  ...
}
```

### Live Tracking API Field Names (Full)
```json
{
  "entry_time": "2025-08-22T01:30:48.368514Z",
  "packet_status": "EA",
  "latitude": "26.192962",
  "longitude": "91.752908",
  "speed": "0.0",
  "heading": "1.26",
  "satellites": "35",
  "vehicle_registration_number": "IND airt",
  "ignition_status": "0",
  "main_power_status": "0",
  ...
}
```

## Solution
Updated `GPSLocationData.fromgromedJson()` factory method in `gps_tracking_service.dart` to check for **both** abbreviated and full field names:

### Key Changes
1. **Latitude parsing**: Check `lat` then `latitude`
2. **Longitude parsing**: Check `lon` then `longitude`
3. **Speed parsing**: Check `s` then `speed`
4. **Heading parsing**: Check `h` then `heading`
5. **Timestamp parsing**: Check `et` then `entry_time` then `timestamp`
6. **Vehicle ID parsing**: Check `no` then `vehicle_registration_number`
7. **Satellites parsing**: Check `sat` then `satellites`
8. **Packet type parsing**: Check `ps` then `packet_type`
9. **Ignition status parsing**: Check `igs` then `ignition_status`
10. **Main power status parsing**: Check `mps` then `main_power_status`

## Testing
After making these changes:

1. **Hot restart** your Flutter app (not hot reload)
2. Navigate to GPS History
3. Select a date range and vehicle
4. The markers should now appear at the correct GPS coordinates
5. Playback animation should work correctly

## Debug Logs to Verify
Look for these logs in the console:
```
🔍 SAMPLE HISTORY ITEM STRUCTURE:
   lat field: 26.192962 (abbreviated)
   lon field: 91.752908 (abbreviated)
📍 Processing history point: IND airt at 26.192962, 91.752908 - 2025-08-22T01:30:48.368514Z
✅ Successfully parsed 546 valid GPS history points
```

## Files Modified
- `lib/services/gps_tracking_service.dart`
  - Updated `fromgromedJson()` factory method (lines ~456-535)
  - Updated history API logging (lines ~148-173)
  - Updated history point processing log (lines ~183-193)

## Compatibility
This fix maintains backward compatibility with:
- Live tracking API (full field names)
- Alert history API (nested `gps_ref` object)
- Any future APIs using either naming convention
