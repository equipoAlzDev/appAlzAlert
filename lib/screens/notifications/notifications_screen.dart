import 'package:flutter/material.dart';
import 'package:pruebavercel/theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<Map<String, dynamic>> _notifications = [
    {
      'type': 'alert',
      'title': 'Alerta enviada',
      'message': 'Se ha enviado una alerta a tus contactos de emergencia',
      'time': '10:30 AM',
      'date': 'Hoy',
      'read': false,
    },
    {
      'type': 'response',
      'title': 'Respuesta a alerta',
      'message': 'Has confirmado que te encuentras bien',
      'time': '9:15 AM',
      'date': 'Hoy',
      'read': true,
    },
    {
      'type': 'emergency',
      'title': 'Emergencia activada',
      'message': 'Has activado el botón de emergencia',
      'time': '3:45 PM',
      'date': 'Ayer',
      'read': true,
    },
    {
      'type': 'alert',
      'title': 'Alerta sin respuesta',
      'message': 'No respondiste a la alerta programada',
      'time': '11:20 AM',
      'date': '12/04/2023',
      'read': true,
    },
  ];

  void _clearAllNotifications() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Borrar notificaciones'),
          content: const Text('¿Estás seguro de que deseas borrar todas las notificaciones?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondaryRed,
              ),
              onPressed: () {
                setState(() {
                  _notifications.clear();
                });
                Navigator.pop(context);
              },
              child: const Text('Borrar'),
            ),
          ],
        );
      },
    );
  }

  void _markAsRead(int index) {
    setState(() {
      _notifications[index]['read'] = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          if (_notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _clearAllNotifications,
            ),
        ],
      ),
      body: _notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off,
                    size: 80,
                    color: AppTheme.textLight,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay notificaciones',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                
                IconData iconData;
                Color iconColor;
                
                switch (notification['type']) {
                  case 'alert':
                    iconData = Icons.notifications;
                    iconColor = AppTheme.primaryBlue;
                    break;
                  case 'response':
                    iconData = Icons.check_circle;
                    iconColor = AppTheme.secondaryGreen;
                    break;
                  case 'emergency':
                    iconData = Icons.warning;
                    iconColor = AppTheme.secondaryRed;
                    break;
                  default:
                    iconData = Icons.info;
                    iconColor = AppTheme.primaryBlue;
                }
                
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: notification['read']
                      ? null
                      : AppTheme.primaryBlue.withOpacity(0.05),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: iconColor.withOpacity(0.2),
                      child: Icon(
                        iconData,
                        color: iconColor,
                      ),
                    ),
                    title: Text(
                      notification['title'],
                      style: TextStyle(
                        fontWeight:
                            notification['read'] ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(notification['message']),
                        const SizedBox(height: 4),
                        Text(
                          '${notification['date']} - ${notification['time']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textLight,
                          ),
                        ),
                      ],
                    ),
                    trailing: notification['read']
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.mark_email_read),
                            onPressed: () => _markAsRead(index),
                          ),
                    isThreeLine: true,
                    onTap: () {
                      if (!notification['read']) {
                        _markAsRead(index);
                      }
                    },
                  ),
                );
              },
            ),
    );
  }
}

