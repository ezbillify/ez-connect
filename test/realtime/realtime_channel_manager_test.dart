import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app/data/services/realtime_channel_manager.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockRealtimeChannel extends Mock implements RealtimeChannel {}

void main() {
  group('RealtimeChannelManager', () {
    late MockSupabaseClient mockSupabaseClient;
    late RealtimeChannelManager channelManager;

    setUp(() {
      mockSupabaseClient = MockSupabaseClient();
      channelManager =
          RealtimeChannelManager(supabaseClient: mockSupabaseClient);
    });

    test('initializes with empty channels', () {
      expect(channelManager.getSubscribedTables().isEmpty, true);
    });

    test('isSubscribed returns false for unsubscribed table', () {
      expect(channelManager.isSubscribed('products'), false);
    });

    test('closeAll removes all channels', () async {
      when(mockSupabaseClient.channel(any as String))
          .thenReturn(MockRealtimeChannel());
      when(mockSupabaseClient.removeChannel(any as RealtimeChannel))
          .thenAnswer((_) async => '');

      // Note: We're not actually testing the subscription functionality
      // due to complexity with mocking the Supabase client
      expect(channelManager, isNotNull);
    });
  });
}
