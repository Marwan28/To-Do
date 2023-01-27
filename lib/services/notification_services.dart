import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:todo/models/task.dart';
import 'package:todo/ui/pages/notification_screen.dart';

class NotifyHelper {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  String selectedNotificationPayload = '';
  final BehaviorSubject<String> selectNotificationSubject =
  BehaviorSubject<String>();

  initializeNotification() async {
    tz.initializeTimeZones();
    _configureSelectNotificationSubject();
    await _configureLocalTimeZone();
    // await requestIOSPermissions(flutterLocalNotificationsPlugin);
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('appicon');
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
      onDidReceiveLocalNotification: onDidReceiveLocalNotification,
    );
    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (notificationResponse) async {
        if(notificationResponse.payload != null){
          debugPrint('notification payload: ${notificationResponse.payload}');
        }
        selectNotificationSubject.add(notificationResponse.payload!);
        //selectNotification(notificationResponse.payload!);
      },
    );
  }

  requestIOSPermissions(){
    flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
      sound: true,
      alert: true,
      badge: true
    );
  }

  displayNotification({required String title, required String body}) async {
    print('doing test');
    AndroidNotificationDetails androidPlatformChannelSpecifies =
        const AndroidNotificationDetails(
            'your channel id', 'your channel name', channelDescription: 'your channel description',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: false);
    DarwinNotificationDetails iosPlatformChannelSpecifies =
        const DarwinNotificationDetails();
    NotificationDetails platformChannelSpecifies = NotificationDetails(
      android: androidPlatformChannelSpecifies,
      iOS: iosPlatformChannelSpecifies,
    );
    await flutterLocalNotificationsPlugin.show(
        0, title, body, platformChannelSpecifies,
        payload: 'Default_Sound');
  }

  cancelNotification(Task task)async{
    await flutterLocalNotificationsPlugin.cancel(task.id!);
  }
  cancelAllNotification()async{
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  scheduledNotification({required int hour, required int minutes,required Task task}) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
        task.id!,
        task.title,
        task.note,
        //tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5)),
        _nextInstanceOfTenAM(hour,minutes,task.remind!,task.repeat!,task.date!),
        const NotificationDetails(
          android: AndroidNotificationDetails('your channel id',
              'your channel name',channelDescription: 'your channel description'),
        ),
        androidAllowWhileIdle: true,
        payload: '${task.title}|${task.note}|${task.startTime}|',
        matchDateTimeComponents: DateTimeComponents.time,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime);
  }

  /*Future selectNotification(String payload) async {
    if (payload != null) {
      debugPrint('notification payload: $payload');
      print('notification payload: $payload');
    }
    await Get.to(NotificationScreen(payload: payload));
  }*/

  //older IOS
  Future onDidReceiveLocalNotification(
      int id, String? title, String? body, String? payload) async {
    // display a dialog with the notification details, tap ok to go to another page
    Get.dialog(Text(body!));
    /* showDialog(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Text('Title'),
        content: const Text('Body'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Ok'),
            onPressed: () async {
              Navigator.of(context, rootNavigator: true).pop();
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Container(color: Colors.white),
                ),
              );
            },
          )
        ],
      ),
    );
 */
  }

  tz.TZDateTime _nextInstanceOfTenAM(int hour, int minutes,int remind, String repeat,String date) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    var formattedDate = DateFormat.yMd().parse(date);
    final tz.TZDateTime fd = tz.TZDateTime.from(formattedDate, tz.local);
    tz.TZDateTime scheduledDate =
    tz.TZDateTime(tz.local, fd.year, fd.month, fd.day, hour, minutes);

    scheduledDate = afterRemind(remind, scheduledDate);
    if(scheduledDate.isBefore(now)){
      if (repeat=='Daily') {
        scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, (formattedDate.day)+1, hour, minutes);
      }
      if (repeat=='Weekly') {
        scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, (formattedDate.day)+7, hour, minutes);
      }
      if (repeat=='Monthly') {
        scheduledDate = tz.TZDateTime(tz.local, now.year, (formattedDate.month)+1, formattedDate.day, hour, minutes);
      }
      scheduledDate = afterRemind(remind, scheduledDate);
    }


    return scheduledDate;
  }

  tz.TZDateTime afterRemind(int remind, tz.TZDateTime scheduledDate) {
      scheduledDate = scheduledDate.subtract(Duration(minutes: remind));
    return scheduledDate;
  }

  void _configureSelectNotificationSubject() {
    selectNotificationSubject.stream.listen((String payload) async {
      debugPrint('My payload is $payload');
      await Get.to(() => NotificationScreen(payload: payload,));
    });
  }

  Future<void> _configureLocalTimeZone() async {
    tz.initializeTimeZones();
    final String timeZoneName = await FlutterNativeTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));
  }
}
