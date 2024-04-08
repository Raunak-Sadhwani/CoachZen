// import 'dart:convert';

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:timezone/timezone.dart' as tz;

// class NotificationManager {
//   final FlutterLocalNotificationsPlugin notificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   Future<void> initNotification() async {
//     AndroidInitializationSettings initializationSettingsAndroid =
//         const AndroidInitializationSettings('flutter_logo');

//     DarwinInitializationSettings initializationIos =
//         DarwinInitializationSettings(
//       requestAlertPermission: true,
//       requestBadgePermission: true,
//       requestSoundPermission: true,
//       onDidReceiveLocalNotification: (id, title, body, payload) {},
//     );
//     InitializationSettings initializationSettings = InitializationSettings(
//         android: initializationSettingsAndroid, iOS: initializationIos);
//     await notificationsPlugin.initialize(
//       initializationSettings,
//       onDidReceiveNotificationResponse: (details) {},
//     );
//   }

//   Future<void> simpleNotificationShow(title, subtitle) async {
//     AndroidNotificationDetails androidNotificationDetails =
//         const AndroidNotificationDetails('1', 'Plan Reminders',
//             priority: Priority.max,
//             importance: Importance.max,
//             icon: 'flutter_logo',
//             channelShowBadge: true,
//             largeIcon: DrawableResourceAndroidBitmap('flutter_logo'));

//     NotificationDetails notificationDetails =
//         NotificationDetails(android: androidNotificationDetails);
//     await notificationsPlugin.show(0, title, subtitle, notificationDetails);
//   }

//   // Future<void> bigPictureNotificationShow() async {
//   //   BigPictureStyleInformation bigPictureStyleInformation =
//   //       const BigPictureStyleInformation(
//   //           DrawableResourceAndroidBitmap('flutter_logo'),
//   //           contentTitle: 'Code Compilee',
//   //           largeIcon: DrawableResourceAndroidBitmap('flutter_logo'));

//   //   AndroidNotificationDetails androidNotificationDetails =
//   //       AndroidNotificationDetails('big_picture_id', 'big_picture_title',
//   //           priority: Priority.high,
//   //           importance: Importance.max,
//   //           styleInformation: bigPictureStyleInformation);

//   //   NotificationDetails notificationDetails =
//   //       NotificationDetails(android: androidNotificationDetails);
//   //   await notificationsPlugin.show(
//   //       1, 'Big Picture Notification', 'New Message', notificationDetails);
//   // }

//   // Future<void> multipleNotificationShow() async {
//   //   AndroidNotificationDetails androidNotificationDetails =
//   //       const AndroidNotificationDetails('Channel_id', 'Channel_title',
//   //           priority: Priority.high,
//   //           importance: Importance.max,
//   //           groupKey: 'commonMessage');

//   //   NotificationDetails notificationDetails =
//   //       NotificationDetails(android: androidNotificationDetails);
//   //   notificationsPlugin.show(
//   //       0, 'New Notification', 'User 1 send message', notificationDetails);

//   //   Future.delayed(
//   //     const Duration(milliseconds: 1000),
//   //     () {
//   //       notificationsPlugin.show(
//   //           1, 'New Notification', 'User 2 send message', notificationDetails);
//   //     },
//   //   );

//   //   Future.delayed(
//   //     const Duration(milliseconds: 1500),
//   //     () {
//   //       notificationsPlugin.show(
//   //           2, 'New Notification', 'User 3 send message', notificationDetails);
//   //     },
//   //   );

//   //   List<String> lines = ['user1', 'user2', 'user3'];

//   //   InboxStyleInformation inboxStyleInformation = InboxStyleInformation(lines,
//   //       contentTitle: '${lines.length} messages', summaryText: 'Code Compilee');

//   //   AndroidNotificationDetails androidNotificationSpesific =
//   //       AndroidNotificationDetails('groupChennelId', 'groupChennelTitle',
//   //           styleInformation: inboxStyleInformation,
//   //           groupKey: 'commonMessage',
//   //           setAsGroupSummary: true);
//   //   NotificationDetails platformChannelSpe =
//   //       NotificationDetails(android: androidNotificationSpesific);
//   //   await notificationsPlugin.show(
//   //       3, 'Attention', '${lines.length} messages', platformChannelSpe);
//   // }

//   Future<void> scheduleNotification(
//       int days, Map<String, dynamic> payload) async {
//     final SharedPreferences prefs = await SharedPreferences.getInstance();
//     String userId = payload['uid'];
//     List<String> userIdMap = [];
//     AndroidNotificationDetails androidNotificationDetails =
//         const AndroidNotificationDetails('Channel_id', 'Channel_title',
//             priority: Priority.max,
//             importance: Importance.max,
//             icon: 'flutter_logo',
//             channelShowBadge: false,
//             largeIcon: DrawableResourceAndroidBitmap('flutter_logo'));
//     NotificationDetails notificationDetails =
//         NotificationDetails(android: androidNotificationDetails);
//     for (var i = 1; i <= days; i++) {
//       if (i == 1) {
//         final now = DateTime.now();
//         final hour = now.hour;
//         // final minute = now.minute;
//         if (hour >= 8) {
//           continue;
//         }
//       }
//       int rDays = days - i;
//       int notificationId = '$userId$rDays'.hashCode;
//       userIdMap.add('$notificationId');
//       tz.TZDateTime scheduledDate =
//           tz.TZDateTime.now(tz.local).add(Duration(days: i - 1));
//       scheduledDate = tz.TZDateTime(tz.local, scheduledDate.year,
//           scheduledDate.month, scheduledDate.day, 2, 30);
//       String name = payload['name'];
//       String plan = payload['plan'];
//       final String planStatus = rDays == 0
//           ? 'ends today'
//           : rDays == 1
//               ? 'ends tomorrow'
//               : 'ends in $rDays days';
//       // append in the decodedPayload the scheduled date
//       payload['scheduledDate'] = scheduledDate.toString();
//       String encodedPayload = jsonEncode(payload);
//       await notificationsPlugin.zonedSchedule(
//         notificationId,
//         "$plan ending",
//         "$name's - $plan $planStatus",
//         scheduledDate,
//         notificationDetails,
//         uiLocalNotificationDateInterpretation:
//             UILocalNotificationDateInterpretation.absoluteTime,
//         // androidAllowWhileIdle: true,
//         androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
//         matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
//         payload: encodedPayload,
//       );
//     }
//     await prefs.setStringList(userId, userIdMap);
//   }

//   Future<void> customScheduleNotification(
//       String title, String body, int notificationId, int seconds) async {
//     AndroidNotificationDetails androidNotificationDetails =
//         const AndroidNotificationDetails('2', 'test',
//             priority: Priority.max,
//             importance: Importance.max,
//             icon: 'flutter_logo',
//             channelShowBadge: false,
//             largeIcon: DrawableResourceAndroidBitmap('flutter_logo'));
//     NotificationDetails notificationDetails =
//         NotificationDetails(android: androidNotificationDetails);
//     await notificationsPlugin.zonedSchedule(
//       notificationId,
//       title,
//       body,
//       tz.TZDateTime.now(tz.local).add(Duration(seconds: seconds)),
//       notificationDetails,
//       uiLocalNotificationDateInterpretation:
//           UILocalNotificationDateInterpretation.absoluteTime,
//       // androidAllowWhileIdle: true,
//       androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
//       matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
//     );
//   }

//   // create a method which return us the list of pending notifications
//   Future<List<PendingNotificationRequest>> getPendingNotifications() async {
//     List<PendingNotificationRequest> pendingNotificationRequests =
//         await notificationsPlugin.pendingNotificationRequests();
//     return pendingNotificationRequests;
//   }

//   // schedule all notifications
//   Future<List<Map<String, dynamic>>> scheduleAllNotifications() async {
//     if (!await Permission.notification.isGranted) {
//       await Permission.notification.request();
//       await Future.delayed(const Duration(milliseconds: 2000));
//     } else {
//       await cancelAllNotifications();
//     }

//     List<Map<String, dynamic>> remindUsers = [];
//     await FirebaseFirestore.instance
//         .collection('Users')
//         .where('cid', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
//         .get()
//         .then((value) async {
//       for (var i = 0; i < value.docs.length; i++) {
//         final plans = value.docs[i].data()['plans'];
//         if (plans != null && plans.length > 0) {
//           plans.sort((a, b) {
//             DateTime dateA = a['started'].toDate();
//             DateTime dateB = b['started'].toDate();
//             return dateB.compareTo(dateA);
//           });
//           //  sorted whole array in descending order
//           // check if 0th index plan remaining days are less than 7
//           // difference between plan days and plan start date
//           DateTime startDate = plans[0]['started'].toDate();
//           final daysSinceStarted = DateTime.now().difference(startDate).inDays;
//           int remainingDays = plans[0]['days'] - daysSinceStarted;
//           if (remainingDays < 8 && remainingDays > 0) {
//             final user = {
//               'name': value.docs[i].data()['name'],
//               'phone': value.docs[i].data()['phone'],
//               'plan': plans[0]['name'],
//               'gender': value.docs[i].data()['gender'],
//               'uid': value.docs[i].id,
//               'image': value.docs[i].data()['image'],
//               'remainingDays': remainingDays,
//             };
//             remindUsers.add(user);
//             // if still permission is not granted then continue
//             if (!await Permission.notification.isGranted) {
//               continue;
//             }
//             Map<String, dynamic> payload = {
//               'uid': user['uid'],
//               'name': user['name'],
//               'plan': user['plan'],
//             };
//             await scheduleNotification(
//               remainingDays,
//               payload,
//             );
//           }
//         }
//       }
//     });
//     return remindUsers;
//   }

//   // cancel all notifications
//   Future<void> cancelAllNotifications() async {
//     await notificationsPlugin.cancelAll();
//   }
// }
