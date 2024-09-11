import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  var initializationSettingsIOS = IOSInitializationSettings();
  var initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crypto Trends',
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: Colors.indigo[50],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.indigo[600],
          elevation: 0,
        ),
      ),
      home: const CryptoTrendPage(),
    );
  }
}

class CryptoTrendPage extends StatefulWidget {
  const CryptoTrendPage({Key? key}) : super(key: key);

  @override
  _CryptoTrendPageState createState() => _CryptoTrendPageState();
}

class _CryptoTrendPageState extends State<CryptoTrendPage> {
  List<CryptoTrend> trends = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchTrends();
  }

  Future<void> fetchTrends() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse('http://139.84.237.32:5000/trends'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        setState(() {
          trends = data.entries.map((entry) => CryptoTrend.fromJson(entry.key, entry.value)).toList();
          isLoading = false;
        });
        checkForAlignedTrends();
      } else {
        throw Exception('Failed to load trends');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load trends: ${e.toString()}')),
      );
    }
  }

  void checkForAlignedTrends() {
    for (var trend in trends) {
      if (trend.trends.values.toSet().length == 1) {
        showNotification(trend.pair, trend.trends.values.first);
      }
    }
  }

  Future<void> showNotification(String pair, String trend) async {
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'crypto_trends', 'Crypto Trends',
        importance: Importance.max, priority: Priority.high, ticker: 'ticker');
    var iOSPlatformChannelSpecifics = IOSNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics, iOS: iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
        0,
        'Aligned Trend for $pair',
        'All timeframes are $trend',
        platformChannelSpecifics,
        payload: 'item x');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crypto Trends'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchTrends,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: fetchTrends,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: trends.length,
                itemBuilder: (context, index) {
                  return CryptoTrendCard(trend: trends[index]);
                },
              ),
      ),
    );
  }
}

class CryptoTrendCard extends StatelessWidget {
  final CryptoTrend trend;

  const CryptoTrendCard({Key? key, required this.trend}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool allAligned = _areAllTimeframesAligned(trend.trends);
    bool shortTermAligned = _areShortTermTimeframesAligned(trend.trends);
    String overallTrend = allAligned ? trend.trends.values.first : 'Mixed';
    
    Color borderColor;
    String statusText;
    Color statusColor;

    if (allAligned) {
      borderColor = _getStatusColor(overallTrend);
      statusText = '4/4 $overallTrend';
      statusColor = borderColor;
    } else if (shortTermAligned) {
      borderColor = Colors.amber;
      statusText = '3/4';
      statusColor = Colors.amber[800]!;
    } else {
      borderColor = Colors.transparent;
      statusText = overallTrend;
      statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  trend.pair,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.indigo[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTrendItem(context, '1m', trend.trends['1m'] ?? 'N/A'),
                _buildTrendItem(context, '5m', trend.trends['5m'] ?? 'N/A'),
                _buildTrendItem(context, '15m', trend.trends['15m'] ?? 'N/A'),
                _buildTrendItem(context, '1h', trend.trends['1h'] ?? 'N/A'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendItem(BuildContext context, String timeframe, String trendValue) {
    Color trendColor = _getStatusColor(trendValue);
    return Column(
      children: [
        Text(
          timeframe,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: trendColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            trendValue,
            style: TextStyle(
              color: trendColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String trend) {
    switch (trend.toLowerCase()) {
      case 'up':
        return Colors.green;
      case 'down':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  bool _areAllTimeframesAligned(Map<String, String> trends) {
    return trends.values.toSet().length == 1 && trends.length == 4;
  }

  bool _areShortTermTimeframesAligned(Map<String, String> trends) {
    var shortTermTrends = [trends['1m'], trends['5m'], trends['15m']];
    return shortTermTrends.toSet().length == 1 && 
           !shortTermTrends.contains(null) && 
           trends['1h'] != shortTermTrends.first;
  }
}

class CryptoTrend {
  final String pair;
  final Map<String, String> trends;

  CryptoTrend({required this.pair, required this.trends});

  factory CryptoTrend.fromJson(String pair, Map<String, dynamic> json) {
    return CryptoTrend(
      pair: pair,
      trends: Map<String, String>.from(json),
    );
  }
}