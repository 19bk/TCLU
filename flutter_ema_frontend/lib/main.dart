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
      isLoading = true; // Show loading indicator
    });

    final response = await http.get(Uri.parse('http://139.84.237.32:5000/trends'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      setState(() {
        trends = data.entries.map((entry) => CryptoTrend.fromJson(entry.key, entry.value)).toList();
        isLoading = false; // Hide loading indicator
      });
    } else {
      setState(() {
        isLoading = false; // Hide loading indicator
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
      body: RefreshIndicator(
        onRefresh: fetchTrends,
        child: ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: trends.length,
          itemBuilder: (context, index) {
            final trend = trends[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16.0),
                title: Text(trend.pair, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('1m: ${trend.trends['1m'] ?? 'N/A'}', style: TextStyle(color: _getTrendColor(trend.trends['1m']))),
                    Text('5m: ${trend.trends['5m'] ?? 'N/A'}', style: TextStyle(color: _getTrendColor(trend.trends['5m']))),
                    Text('15m: ${trend.trends['15m'] ?? 'N/A'}', style: TextStyle(color: _getTrendColor(trend.trends['15m']))),
                    Text('1h: ${trend.trends['1h'] ?? 'N/A'}', style: TextStyle(color: _getTrendColor(trend.trends['1h']))),
                  ],
                ),
                trailing: const Icon(Icons.more_vert),
              ),
            );
          },
        ),
      ),
    );
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