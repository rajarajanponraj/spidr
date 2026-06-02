import 'package:test/test.dart';
import 'package:spidr_proxy/spidr_proxy.dart';

void main() {
  group('ProxyInfo Tests', () {
    test('authority and toString return formatted output', () {
      const proxy = ProxyInfo(
        host: '127.0.0.1',
        port: 8080,
        protocol: ProxyProtocol.http,
      );
      expect(proxy.authority, equals('127.0.0.1:8080'));
      expect(proxy.toString(), equals('http://127.0.0.1:8080'));
    });
  });

  group('BasicProxyPool Tests', () {
    test('pool add/remove and rotation strategies work', () async {
      final pool = BasicProxyPool();
      const p1 = ProxyInfo(host: '1.1.1.1', port: 80);
      const p2 = ProxyInfo(host: '2.2.2.2', port: 80);

      await pool.add(p1);
      await pool.add(p2);
      expect(pool.proxies.length, equals(2));

      final selected = await pool.next(strategy: ProxyStrategy.roundRobin);
      expect(selected, isNotNull);

      await pool.remove(p1);
      expect(pool.proxies.length, equals(1));
    });
  });
}
