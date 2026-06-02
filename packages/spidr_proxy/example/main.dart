import 'package:spidr_proxy/spidr_proxy.dart';

void main() async {
  final pool = BasicProxyPool();
  await pool.add(const ProxyInfo(host: 'proxy1.example.com', port: 3128));
  await pool.add(const ProxyInfo(host: 'proxy2.example.com', port: 3128));

  final proxy = await pool.next();
  print('Selected rotating proxy from pool: $proxy');
}
