import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Chat',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => LoginPage(),
        '/chat': (context) => ChatScreen(),
      },
    );
  }
}

class LoginPage extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<void> signIn(BuildContext context) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );
      print('User logged in: ${userCredential.user!.email}');
      // Navigate to chat screen after successful login
      Navigator.pushReplacementNamed(context, '/chat');
    } catch (e) {
      print('Error signing in: $e');
      // Handle sign in error here
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () => signIn(context),
              child: Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatScreen extends StatelessWidget {
  final TextEditingController messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: ChatService().getMessages(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }
                List<Message> messages = snapshot.data!;
                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    Message message = messages[index];
                    return ListTile(
                      title: Text(message.text),
                      subtitle: Text(message.sender),
                    );
                  },
                );
              },
            ),
          ),
          _buildMessageComposer(context),
        ],
      ),
    );
  }

  Widget _buildMessageComposer(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: messageController,
              decoration: InputDecoration(
                hintText: 'Enter your message...',
              ),
            ),
          ),
          SizedBox(width: 8.0),
          ElevatedButton(
            onPressed: () => _sendMessage(context),
            child: Text('Send'),
          ),
        ],
      ),
    );
  }

  void _sendMessage(BuildContext context) {
    String messageText = messageController.text.trim();
    if (messageText.isNotEmpty) {
      String currentUserEmail = FirebaseAuth.instance.currentUser!.email!;
      ChatService().sendMessage(messageText, currentUserEmail);
      messageController.clear();
    } else {
      // Handle empty message
    }
  }
}

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Message>> getMessages() {
    return _firestore.collection('messages').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Message(
          text: doc['text'],
          sender: doc['sender'],
        );
      }).toList();
    });
  }

  Future<void> sendMessage(String text, String sender) async {
    try {
      await _firestore.collection('messages').add({
        'text': text,
        'sender': sender,
        'timestamp': DateTime.now(),
      });
    } catch (e) {
      print('Error sending message: $e');
    }
  }
}

class Message {
  final String text;
  final String sender;

  Message({required this.text, required this.sender});
}
