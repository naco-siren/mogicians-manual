import 'package:flutter/material.dart';

import 'tab_shuo.dart';

class HomePage extends StatefulWidget {
  HomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Image.asset('images/ic_guy_fawkes.png'),
        title: Text(widget.title),
      ),
      backgroundColor: Colors.grey.shade200,
      body: Center(
        child: _getTab(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.mic), title: Text('【说】')),
          BottomNavigationBarItem(icon: Icon(Icons.local_library), title: Text('【学】')),
          BottomNavigationBarItem(icon: Icon(Icons.sentiment_very_satisfied), title: Text('【逗】')),
          BottomNavigationBarItem(icon: Icon(Icons.music_note), title: Text('【唱】')),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _getTab() {
    switch (_selectedIndex) {
      case 0:
        return new TabShuo();
      default:
        return new Text('NULL');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}