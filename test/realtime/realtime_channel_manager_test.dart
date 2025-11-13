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
      channelManager = RealtimeChannelManager(supabaseClient: mockSupabaseClient);
    });

    test('initializes with empty channels', () {
      expect(channelManager.getSubscribedTables().isEmpty, true);
    });

    test('isSubscribed returns false for unsubscribed table', () {
      expect(channelManager.isSubscribed('products'), false);
    });

    test('closeAll removes all channels', () async {
      when(mockSupabaseClient.channel(any)).thenReturn(MockRealtimeChannel());
      when(mockSupabaseClient.removeChannel(any))
          .thenAnswer((_) async => null);

      channelManager.subscribe(
        table: 'products',
        onEvent: (_) {},
      );

      await Future.delayed(const Duration(milliseconds: 100));
      await channelManager.closeAll();

      expect(channelManager.getSubscribedTables().isEmpty, true);
    });
  });
}
