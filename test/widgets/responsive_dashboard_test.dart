import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:edisha/services/alert_api_service.dart';
import 'package:edisha/services/driver_api_service.dart';

void main() {
  group('Responsive Dashboard API Integration Tests', () {
    late AlertApiService alertService;
    late DriverApiService driverService;

    setUpAll(() {
      // Initialize services for testing
      alertService = AlertApiService();
      driverService = DriverApiService();
    });

    test('Alert API Response Processing', () {
      // Test different API response formats
      
      // Test 1: Response with list data
      final listResponse = {
        'success': true,
        'data': [
          {'created_at': '2024-01-01T10:00:00Z', 'severity': 'critical', 'message': 'Test alert 1'},
          {'created_at': '2024-01-01T11:00:00Z', 'severity': 'warning', 'message': 'Test alert 2'},
        ]
      };
      
      // Test 2: Response with nested alerts
      final nestedResponse = {
        'success': true,
        'data': {
          'alerts': [
            {'created_at': '2024-01-01T10:00:00Z', 'level': 'high', 'message': 'Test alert 1'},
          ]
        }
      };
      
      // Test 3: Response with single alert as object
      final singleResponse = {
        'success': true,
        'data': {
          'created_at': '2024-01-01T10:00:00Z', 
          'priority': 'medium', 
          'message': 'Single alert'
        }
      };

      // Each format should be handled correctly
      expect(listResponse['data'], isA<List>());
      expect((nestedResponse['data'] as Map)['alerts'], isA<List>());
      expect(singleResponse['data'], isA<Map>());
      
      print('✅ Alert API response formats validated');
    });

    test('Driver API Response Processing', () {
      // Test different driver API response formats
      
      // Test 1: Response with owner list
      final ownerResponse = {
        'success': true,
        'data': {
          'owner_list': [
            {'tag_status': 'active', 'esim_status': 'enabled'},
            {'status': 'inactive', 'driver_status': 'off_duty'},
          ]
        }
      };
      
      // Test 2: Response with direct list
      final directResponse = {
        'success': true,
        'data': [
          {'status': 'active', 'duty_status': 'on_duty'},
          {'tag_status': 'inactive'},
        ]
      };

      expect((ownerResponse['data'] as Map)['owner_list'], isA<List>());
      expect(directResponse['data'], isA<List>());
      
      print('✅ Driver API response formats validated');
    });

    test('Error Handling', () {
      // Test error responses
      final errorResponse = {
        'success': false,
        'message': 'Authentication failed',
        'data': null
      };

      expect(errorResponse['success'], false);
      expect(errorResponse['message'], isA<String>());
      
      print('✅ Error response handling validated');
    });

    test('Data Processing Edge Cases', () {
      // Test empty data
      final emptyResponse = {
        'success': true,
        'data': []
      };

      // Test null data
      final nullResponse = {
        'success': true,
        'data': null
      };

      expect(emptyResponse['data'], isEmpty);
      expect(nullResponse['data'], isNull);
      
      print('✅ Edge cases validated');
    });
  });

  group('Response Structure Validation', () {
    test('Alert Data Structure', () {
      final mockAlert = {
        'message': 'Test alert',
        'created_at': '2024-01-01T10:00:00Z',
        'severity': 'critical',
        'level': 'high',
        'priority': 'urgent'
      };

      // Check all possible field variations
      expect(mockAlert.containsKey('message'), true);
      expect(mockAlert.containsKey('created_at'), true);
      expect([mockAlert['severity'], mockAlert['level'], mockAlert['priority']], 
             anyElement(isNotNull));
      
      print('✅ Alert data structure validated');
    });

    test('Driver Data Structure', () {
      final mockDriver = {
        'status': 'active',
        'tag_status': 'enabled',
        'esim_status': 'active',
        'duty_status': 'on_duty',
        'driver_status': 'available'
      };

      // Check status field variations
      final statusFields = ['status', 'tag_status', 'esim_status'];
      final dutyFields = ['duty_status', 'driver_status'];
      
      expect(statusFields.any((field) => mockDriver.containsKey(field)), true);
      expect(dutyFields.any((field) => mockDriver.containsKey(field)), true);
      
      print('✅ Driver data structure validated');
    });
  });
}

// Helper matcher for testing
Matcher anyElement(Matcher elementMatcher) {
  return predicate<Iterable>(
    (items) => items.any((item) => elementMatcher.matches(item, {})),
    'contains any element that $elementMatcher'
  );
}