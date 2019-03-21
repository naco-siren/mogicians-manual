import 'package:flutter/material.dart';

import 'package:scoped_model/scoped_model.dart';

import 'package:mogicians_manual/ui/tabs.dart';
import 'package:mogicians_manual/data/models.dart';

class HomePage extends StatefulWidget {
  HomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final shuoModel = TabModel();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Icon(Icons.school), // Image.asset('assets/images/ic_guy_fawkes.png'),
        title: Text(widget.title),
      ),
      backgroundColor: Colors.grey.shade200,
      body: Center(
        child: _getTab(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(title: Text('【说】'), icon: Icon(Icons.mic)),
          BottomNavigationBarItem(title: Text('【学】'), icon: Icon(Icons.local_library)),
          BottomNavigationBarItem(title: Text('【逗】'), icon: Icon(Icons.sentiment_very_satisfied)),
          BottomNavigationBarItem(title: Text('【唱】'), icon: Icon(Icons.music_note)),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _getTab() {
    switch (_selectedIndex) {
      case 0:
        shuoModel.loadData();
        return ScopedModel<TabModel>(
          model: shuoModel,
          child: TabShuo(),
        );
      default:
        return new Text('PLACEHOLDER');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}