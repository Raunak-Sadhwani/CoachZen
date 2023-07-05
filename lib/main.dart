import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:slimtrap/pages/home.dart';
import 'package:slimtrap/pages/login.dart';
// import 'pages/home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  static GlobalKey mtAppKey = GlobalKey();
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: user == null ? const LoginPage() : const HomePage(),
    );
  }
}

// import 'package:flutter/material.dart';
// // import 'package:cached_network_image/cached_network_image.dart';

// class UserProfile extends StatelessWidget {
//   final Map<String, dynamic> userData;

//   const UserProfile({super.key, required this.userData});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('User Profile'),
//       ),
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [
//               Colors.blue.shade400,
//               Colors.blue.shade900,
//             ],
//           ),
//         ),
//         child: ListView(
//           padding: const EdgeInsets.all(16.0),
//           children: [
//             // Card(
//             //   elevation: 4.0,
//             //   shadowColor: Colors.black54,
//             //   child: ListTile(
//             //     leading: CircleAvatar(
//             //       backgroundImage: CachedNetworkImageProvider(
//             //         userData['image'],
//             //       ),
//             //     ),
//             //     title: Text(userData['name']),
//             //     subtitle: Text('Gender: ${userData['gender']}'),
//             //   ),
//             // ),
//             Card(
//               elevation: 4.0,
//               shadowColor: Colors.black54,
//               child: ListTile(
//                 title: const Text('Phone'),
//                 subtitle: Text(userData['phone']),
//               ),
//             ),
//             Card(
//               elevation: 4.0,
//               shadowColor: Colors.black54,
//               child: ListTile(
//                 title: const Text('Date of Birth'),
//                 subtitle: Text(userData['dob']),
//               ),
//             ),
//             Card(
//               elevation: 4.0,
//               shadowColor: Colors.black54,
//               child: ListTile(
//                 title: const Text('Height'),
//                 subtitle: Text(userData['height']),
//               ),
//             ),
//             Card(
//               elevation: 4.0,
//               shadowColor: Colors.black54,
//               child: ListTile(
//                 title: const Text('Plan'),
//                 subtitle: Text(userData['plan']),
//               ),
//             ),
//             Card(
//               elevation: 4.0,
//               shadowColor: Colors.black54,
//               child: ListTile(
//                 title: const Text('Created'),
//                 subtitle: Text(userData['created']),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'User Profile',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//       ),
//       home: const UserProfile(userData: {
//         "created": "__Timestamp__2023-06-30T18:30:00.869Z",
//         "dob": "__Timestamp__1990-06-03T18:30:00.670Z",
//         "gender": "m",
//         "height": "170",
//         "image":
//             "https://firebasestorage.googleapis.com/v0/b/slimtrap-12284.appspot.com/o/5dPosXyGbNcahO2HpXpJq7obnGv1.jpg?alt=media&token=d0b68798-eedf-41ee-b052-549d269451c7",
//         "name": "Ron",
//         "phone": "9156147895",
//         "plan": "10 days marathon",
//       }),
//     );
//   }
// }

