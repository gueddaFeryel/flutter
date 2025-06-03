import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';

import '../../models/intervention.dart';
import '../../models/notification.dart';
import '../../services/intervention_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/intervention_card.dart';
import 'intervention_detail.dart';
import 'intervention_form.dart';

class CalendarScreen extends StatefulWidget {
   const CalendarScreen({Key? key}) : super(key: key);
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> with SingleTickerProviderStateMixin {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Intervention> _interventions = [];
  List<Intervention> _selectedInterventions = [];
  List<AppNotification> _notifications = [];
  List<AppNotification> _readNotifications = [];
  bool _isLoading = false;
  bool _isLoadingNotifications = false;
  String _errorMessage = '';
  int _unreadCount = 0;
  bool _showNotifications = false;
  String _notificationFilter = 'all';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _initializeDateFormatting();
    _loadInterventions();
    _loadNotifications();

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeDateFormatting() async {
    await initializeDateFormatting('fr_FR', null);
  }

  Future<void> _loadInterventions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      final interventionService = Provider.of<InterventionService>(context, listen: false);
      final interventions = await interventionService.getInterventionsByStaff(user.uid);

      setState(() {
        _interventions = interventions;
        _updateSelectedInterventions();
      });
    } catch (e) {
      setState(() => _errorMessage = 'Erreur: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<List<AppNotification>> _loadReadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonData = prefs.getString('read_notifications');
    if (jsonData != null) {
      final List<dynamic> data = json.decode(jsonData);
      return data.map((json) => AppNotification.fromJson(json)).toList();
    }
    return [];
  }

  Future<void> _saveReadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'read_notifications',
      json.encode(_readNotifications.map((n) => n.toJson()).toList()),
    );
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoadingNotifications = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final notificationService = Provider.of<NotificationService>(context, listen: false);
        final unread = await notificationService.getUserNotifications(user.uid);
        final read = await _loadReadNotifications();

        setState(() {
          _notifications = [...unread, ...read];
          _readNotifications = read;
          _unreadCount = unread.length;
        });
      }
    } catch (e) {
      print('Error loading notifications: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingNotifications = false);
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final notificationService = Provider.of<NotificationService>(context, listen: false);
      await notificationService.markAllAsRead(user.uid);

      final newlyRead = _notifications.where((n) => !n.read).map((n) => n.copyWith(read: true)).toList();

      setState(() {
        _readNotifications = [..._readNotifications, ...newlyRead];
        _notifications = _notifications.map((n) => n.copyWith(read: true)).toList();
        _unreadCount = 0;
      });

      await _saveReadNotifications();
    } catch (e) {
      print('Error marking notifications as read: $e');
    }
  }

  void _updateSelectedInterventions() {
    if (_selectedDay == null) return;
    
    setState(() {
      _selectedInterventions = _interventions.where((intervention) {
        return intervention.date.year == _selectedDay!.year &&
               intervention.date.month == _selectedDay!.month &&
               intervention.date.day == _selectedDay!.day;
      }).toList();
    });
  }

  Widget _buildNotificationIcon(String type) {
    final iconSize = 28.0;
    switch (type) {
      case 'INTERVENTION_CREATED':
        return Icon(Icons.calendar_today, size: iconSize, color: Colors.blue);
      case 'INTERVENTION_UPDATED':
      case 'INTERVENTION_MODIFIED':
        return Icon(Icons.edit, size: iconSize, color: Colors.orange);
      case 'INTERVENTION_CANCELLED':
        return Icon(Icons.cancel, size: iconSize, color: Colors.red);
      case 'REMINDER_24H':
        return Icon(Icons.access_time, size: iconSize, color: Colors.green);
      default:
        return Icon(Icons.info, size: iconSize, color: Colors.grey);
    }
  }

  Future<void> _handleNotificationClick(AppNotification notification) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      if (!notification.read) {
        final notificationService = Provider.of<NotificationService>(context, listen: false);
        await notificationService.markNotificationAsRead(notification.id);

        final updatedNotification = notification.copyWith(read: true);
        
        setState(() {
          _notifications = _notifications
              .map((n) => n.id == notification.id ? updatedNotification : n)
              .toList();
          _readNotifications = [..._readNotifications, updatedNotification];
          _unreadCount--;
        });

        await _saveReadNotifications();
      }

      if (notification.interventionId != null) {
        try {
          final intervention = _interventions.firstWhere(
            (i) => i.id == notification.interventionId,
          );
          Navigator.pushNamed(
            context,
            InterventionDetailScreen.routeName,
            arguments: intervention,
          );
        } catch (e) {
          print('Intervention not found: ${notification.interventionId}');
        }
      }
    } catch (e) {
      print('Error handling notification click: $e');
    } finally {
      setState(() {
        _showNotifications = false;
      });
    }
  }

  List<AppNotification> _getFilteredNotifications() {
    switch (_notificationFilter) {
      case 'unread':
        return _notifications.where((n) => !n.read).toList();
      case 'read':
        return _notifications.where((n) => n.read).toList();
      default:
        return _notifications;
    }
  }

  Future<void> _handleRefresh() async {
    await Future.wait([
      _loadInterventions(),
      _loadNotifications(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredNotifications = _getFilteredNotifications();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Calendrier des Interventions'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.primaryColor.withOpacity(0.7),
                Colors.transparent,
              ],
            ),
          ),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadInterventions,
          ),
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _showNotifications = !_showNotifications;
                  });
                },
              ),
              if (_unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$_unreadCount',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: LiquidPullToRefresh(
        onRefresh: _handleRefresh,
        color: theme.colorScheme.secondary.withOpacity(0.2),
        backgroundColor: theme.scaffoldBackgroundColor,
        height: 150,
        animSpeedFactor: 2,
        showChildOpacityTransition: false,
        child: Stack(
          children: [
            // Background image with overlay
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/medical_bg.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Container(
              color: Colors.black.withOpacity(0.3),
            ),
            
            // Main content
            FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  children: [
                    SizedBox(height: kToolbarHeight + 20),
                    
                    // Calendar Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  theme.primaryColor.withOpacity(0.8),
                                  theme.colorScheme.secondary.withOpacity(0.8),
                                ],
                              ),
                            ),
                            child: TableCalendar(
                              firstDay: DateTime.utc(2020, 1, 1),
                              lastDay: DateTime.utc(2030, 12, 31),
                              focusedDay: _focusedDay,
                              calendarFormat: _calendarFormat,
                              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                              onDaySelected: (selectedDay, focusedDay) {
                                setState(() {
                                  _selectedDay = selectedDay;
                                  _focusedDay = focusedDay;
                                  _updateSelectedInterventions();
                                });
                              },
                              onFormatChanged: (format) {
                                setState(() => _calendarFormat = format);
                              },
                              onPageChanged: (focusedDay) => _focusedDay = focusedDay,
                              calendarStyle: CalendarStyle(
                                todayDecoration: BoxDecoration(
                                  color: theme.colorScheme.secondary,
                                  shape: BoxShape.circle,
                                ),
                                selectedDecoration: BoxDecoration(
                                  color: theme.primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                weekendTextStyle: TextStyle(color: Colors.white),
                                defaultTextStyle: TextStyle(color: Colors.white),
                              ),
                              headerStyle: HeaderStyle(
                                formatButtonVisible: false,
                                titleCentered: true,
                                titleTextStyle: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
                                rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
                              ),
                              daysOfWeekStyle: DaysOfWeekStyle(
                                weekdayStyle: TextStyle(color: Colors.white),
                                weekendStyle: TextStyle(color: Colors.white70),
                              ),
                              calendarBuilders: CalendarBuilders(
                                markerBuilder: (context, date, events) {
                                  final count = _interventions.where((i) {
                                    return i.date.year == date.year &&
                                           i.date.month == date.month &&
                                           i.date.day == date.day;
                                  }).length;
                                  
                                  if (count == 0) return SizedBox.shrink();
                                  
                                  return Positioned(
                                    right: 1,
                                    bottom: 1,
                                    child: Container(
                                      padding: EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        count.toString(),
                                        style: TextStyle(
                                          color: theme.primaryColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 16),
                    
                    // Date Title
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, color: Colors.white),
                            SizedBox(width: 12),
                            Text(
                              DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(_selectedDay!),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 16),
                    
                    // Interventions List
                    Expanded(
                      child: _selectedInterventions.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.event_available,
                                    size: 64,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Aucune intervention programmée',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : AnimationLimiter(
                              child: ListView.builder(
                                itemCount: _selectedInterventions.length,
                                itemBuilder: (context, index) {
                                  final intervention = _selectedInterventions[index];
                                  return AnimationConfiguration.staggeredList(
                                    position: index,
                                    duration: const Duration(milliseconds: 375),
                                    child: SlideAnimation(
                                      verticalOffset: 50.0,
                                      child: FadeInAnimation(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16.0,
                                            vertical: 8.0,
                                          ),
                                          child: InterventionCard(
                                            intervention: intervention,
                                            onTap: () {
                                              Navigator.pushNamed(
                                                context,
                                                InterventionDetailScreen.routeName,
                                                arguments: intervention,
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Notifications Panel
            if (_showNotifications)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => setState(() => _showNotifications = false),
                  child: Container(
                    color: Colors.black.withOpacity(0.4),
                    child: Center(
                      child: GestureDetector(
                        onTap: () {}, // Prevent click-through
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Material(
                            elevation: 24,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: double.infinity,
                              height: MediaQuery.of(context).size.height * 0.7,
                              decoration: BoxDecoration(
                                color: theme.scaffoldBackgroundColor,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  // Header
                                  Container(
                                    padding: EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: theme.primaryColor,
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(20),
                                        topRight: Radius.circular(20),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Notifications',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: Icon(Icons.refresh, color: Colors.white),
                                              onPressed: _loadNotifications,
                                            ),
                                            SizedBox(width: 8),
                                            DropdownButton<String>(
                                              value: _notificationFilter,
                                              icon: Icon(Icons.arrow_drop_down, color: Colors.white),
                                              elevation: 16,
                                              dropdownColor: theme.primaryColor,
                                              style: TextStyle(color: Colors.white),
                                              underline: Container(),
                                              onChanged: (String? newValue) {
                                                setState(() {
                                                  _notificationFilter = newValue!;
                                                });
                                              },
                                              items: <String>['all', 'unread', 'read']
                                                  .map<DropdownMenuItem<String>>((String value) {
                                                return DropdownMenuItem<String>(
                                                  value: value,
                                                  child: Text(
                                                    value == 'all' ? 'Toutes' : 
                                                    value == 'unread' ? 'Non lues' : 'Lues',
                                                    style: TextStyle(fontSize: 16),
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  if (_notifications.isNotEmpty && _notificationFilter == 'unread' && _unreadCount > 0)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: theme.primaryColor,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          padding: EdgeInsets.symmetric(vertical: 12),
                                          elevation: 3,
                                        ),
                                        onPressed: _markAllAsRead,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.check_circle, color: Colors.white),
                                            SizedBox(width: 8),
                                            Text(
                                              'Marquer tout comme lu',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  
                                  // Notifications list
                                  Expanded(
                                    child: _isLoadingNotifications
                                        ? Center(
                                            child: CircularProgressIndicator(
                                              valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                                            ),
                                          )
                                        : filteredNotifications.isEmpty
                                            ? Center(
                                                child: Text(
                                                  _notificationFilter == 'unread' 
                                                    ? 'Aucune notification non lue' 
                                                    : _notificationFilter == 'read'
                                                      ? 'Aucune notification lue'
                                                      : 'Aucune notification',
                                                  style: TextStyle(fontSize: 16, color: Colors.grey),
                                                ),
                                              )
                                            : AnimationLimiter(
                                                child: ListView.builder(
                                                  itemCount: filteredNotifications.length,
                                                  itemBuilder: (context, index) {
                                                    final notification = filteredNotifications[index];
                                                    return AnimationConfiguration.staggeredList(
                                                      position: index,
                                                      duration: const Duration(milliseconds: 375),
                                                      child: SlideAnimation(
                                                        verticalOffset: 50.0,
                                                        child: FadeInAnimation(
                                                          child: Padding(
                                                            padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                                                            child: Card(
                                                              elevation: 3,
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius: BorderRadius.circular(12),
                                                              ),
                                                              child: InkWell(
                                                                borderRadius: BorderRadius.circular(12),
                                                                onTap: () => _handleNotificationClick(notification),
                                                                child: Padding(
                                                                  padding: EdgeInsets.all(16),
                                                                  child: Column(
                                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                                    children: [
                                                                      Row(
                                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                                        children: [
                                                                          _buildNotificationIcon(notification.type),
                                                                          SizedBox(width: 12),
                                                                          Expanded(
                                                                            child: Column(
                                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                                              children: [
                                                                                Text(
                                                                                  notification.title,
                                                                                  style: TextStyle(
                                                                                    fontSize: 18,
                                                                                    fontWeight: notification.read 
                                                                                      ? FontWeight.normal 
                                                                                      : FontWeight.bold,
                                                                                    color: notification.read 
                                                                                      ? Colors.grey[600] 
                                                                                      : Colors.black,
                                                                                  ),
                                                                                ),
                                                                                SizedBox(height: 8),
                                                                                Text(
                                                                                  notification.message,
                                                                                  style: TextStyle(
                                                                                    fontSize: 16,
                                                                                    color: notification.read 
                                                                                      ? Colors.grey 
                                                                                      : Colors.black87,
                                                                                  ),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          ),
                                                                          if (!notification.read)
                                                                            Icon(Icons.brightness_1, size: 12, color: Colors.red),
                                                                        ],
                                                                      ),
                                                                      SizedBox(height: 12),
                                                                      Row(
                                                                        children: [
                                                                          Icon(Icons.access_time, size: 16, color: Colors.grey),
                                                                          SizedBox(width: 4),
                                                                          Text(
                                                                            DateFormat('dd/MM/yyyy HH:mm').format(notification.timestamp),
                                                                            style: TextStyle(
                                                                              fontSize: 14,
                                                                              color: Colors.grey,
                                                                            ),
                                                                          ),
                                                                          Spacer(),
                                                                          if (notification.read)
                                                                            Icon(Icons.check_circle, size: 18, color: Colors.green),
                                                                        ],
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: _scaleAnimation,
        child: FloatingActionButton(
          onPressed: () {
            Navigator.pushNamed(context, InterventionFormScreen.routeName);
          },
          child: Icon(Icons.add),
          backgroundColor: theme.primaryColor,
          elevation: 8,
          tooltip: 'Nouvelle intervention',
        ),
      ),
    );
  }
}