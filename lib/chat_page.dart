import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_chat_apps/login_page.dart';
import 'package:firebase_chat_apps/widget/message_bubble.dart';
import 'package:flutter/material.dart';

class ChatPage extends StatefulWidget {
  static const String id = 'chat_page';

  const ChatPage({Key? key}) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  late User? _activeUser;
  final _messageTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  @override
  void dispose() {
    _messageTextController.dispose();
    super.dispose();
  }

  void getCurrentUser() async {
    try {
      _activeUser = _auth.currentUser;
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Room'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Logout',
            onPressed: () async {
              final navigator = Navigator.of(context);
              await _auth.signOut();
              navigator.pushReplacementNamed(LoginPage.id);
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _firestore
                      .collection('messages')
                      .orderBy('dateCreated', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(child: const CircularProgressIndicator());
                    }
                    return ListView(
                      reverse: true,
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 16.0,
                      ),
                      children: snapshot.data!.docs.map<Widget>((document) {
                        final data = document.data();
                        final String messageText = data['text'];
                        final String messageSender = data['sender'];
                        return MessageBubble(
                          sender: messageSender,
                          text: messageText,
                          isMyChat: messageSender == _activeUser?.email,
                        );
                      }).toList(),
                    );
                  }),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageTextController,
                    decoration: const InputDecoration(
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                MaterialButton(
                  color: Theme.of(context).primaryColor,
                  textTheme: ButtonTextTheme.primary,
                  onPressed: () {
                    if (_messageTextController.text != "") {
                      _firestore.collection("messages").add({
                        "text": _messageTextController.text,
                        "sender": _activeUser?.email,
                        "dateCreated": Timestamp.now(),
                      });
                      _messageTextController.clear();
                    }
                  },
                  child: const Text('SEND'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
