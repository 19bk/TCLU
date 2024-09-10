import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crypto Trends',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.grey[900],
        appBarTheme: const AppBarTheme(backgroundColor: Colors.black),
      ),
      home: const CryptoTrendPage(),
    );
  }
}

class CryptoTrendPage extends StatefulWidget {
  const CryptoTrendPage({super.key});

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

    final response = await http.get(Uri.parse('http://139.84.237.32:5000/trends'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      setState(() {
        trends = data.entries.map((entry) => CryptoTrend.fromJson(entry.key, entry.value)).toList();
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load trends')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crypto Trends'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: RefreshIndicator( // Add RefreshIndicator
          onRefresh: fetchTrends, // Call your fetchTrends method
          child: SingleChildScrollView( // Vertical scrolling
            child: SingleChildScrollView( // Horizontal scrolling
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Pair', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('1m', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('5m', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('15m', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('1h', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: trends.map((trend) {
                  return DataRow(cells: [
                    DataCell(Text(trend.pair)),
                    DataCell(
                      Text(trend.trends['1m'] ?? 'N/A', style: TextStyle(color: _getTrendColor(trend.trends['1m']))),
                    ),
                    DataCell(
                      Text(trend.trends['5m'] ?? 'N/A', style: TextStyle(color: _getTrendColor(trend.trends['5m']))),
                    ),
                    DataCell(
                      Text(trend.trends['15m'] ?? 'N/A', style: TextStyle(color: _getTrendColor(trend.trends['15m']))),
                    ),
                    DataCell(
                      Text(trend.trends['1h'] ?? 'N/A', style: TextStyle(color: _getTrendColor(trend.trends['1h']))),
                    ),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CryptoTrendCard extends StatelessWidget {
  final CryptoTrend trend;

  const CryptoTrendCard({super.key, required this.trend});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              trend.pair,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.cyan), // Updated from headline6 to titleMedium
            ),
            const SizedBox(height: 10),
            ...['1m', '5m', '15m', '1h'].map((timeframe) => 
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 30,
                      child: Text(timeframe, style: const TextStyle(color: Colors.grey)),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: trend.trends[timeframe] == 'Up' ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        trend.trends[timeframe] ?? 'N/A',
                        style: const TextStyle(color: Colors.white),
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

// Function to determine color based on trend
Color _getTrendColor(String? trend) {
  if (trend == 'Up') {
    return Colors.green; // Bullish
  } else if (trend == 'Down') {
    return Colors.red; // Bearish
  } else {
    return Colors.grey; // Neutral
  }
}