import 'dart:convert';

import 'package:chat_app/model/message_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';

class ChatPage extends StatefulWidget {
  final String myid;
  final String receiverid;
  const ChatPage({super.key, required this.myid, required this.receiverid});

  @override
  State<StatefulWidget> createState() {
    return ChatPageState();
  }
}

class ChatPageState extends State<ChatPage> {
  late IOWebSocketChannel channel; //channel variable for websocket
  late bool connected; // boolean value to track connection status

  // String myid = "1234"; //my id
  // String receiverid = "4321"; //receiver id
  //   String myid = "4321"; //my id
  // String receiverid = "1234"; //receiver id
  late String myid;
  late String receiverid;
  // swap myid and receiverid value on another mobile to test send and receive
  String auth = "addauthkeyifrequired"; //auth key
  String ip ="chatapp-6ehz.onrender.com" ;

  List<MessageData> msglist = [];

  TextEditingController msgtext = TextEditingController();

  late Dio dio = Dio(BaseOptions(baseUrl: "https://$ip",
    connectTimeout: const Duration(seconds: 60), 
      receiveTimeout: const Duration(seconds: 60),));

  @override
  void initState() {
    connected = false;
    msgtext.text = "";
    myid = widget.myid;
    receiverid = widget.receiverid;
    channelconnect();
    loadmsg();
    super.initState();
  }

  channelconnect() {
    //function to connect
    try {
      channel = IOWebSocketChannel.connect(
          "wss://$ip/$myid");
      channel.stream.listen(
        (message) {
          if (kDebugMode) {
            print(message);
          }
          setState(() {
            if (message == "connected") {
              connected = true;
              setState(() {});
              if (kDebugMode) {
                print("Connection establised.");
              }
            } else if (message == "send:success") {
              if (kDebugMode) {
                print("Message send success");
              }
              setState(() {
                msgtext.text = "";
              });
            } else if (message == "send:error") {
              if (kDebugMode) {
                print("Message send error");
              }
            } else if (message.substring(0, 6) == "{'cmd'") {
              if (kDebugMode) {
                print("Message data");
              }
              message = message.replaceAll(RegExp("'"), '"');
              var jsondata = json.decode(message);

              msglist.add(MessageData(
                //on message receive, add data to model
                msgtext: jsondata["msgtext"],
                senderid: jsondata["senderid"],
                receiverid: jsondata["receiverid"],
                isme: false,
              ));
              setState(() {
                //update UI after adding data to message model
              });
            }
          });
        },
        onDone: () {
          //if WebSocket is disconnected
          if (kDebugMode) {
            print("Web socket is closed");
          }
          setState(() {
            connected = false;
          });
        },
        onError: (error) {
          if (kDebugMode) {
            print(error.toString());
          }
        },
      );
    } catch (_) {
      if (kDebugMode) {
        print("error on connecting to websocket.");
      }
    }
  }

  Future<void> loadmsg() async {
    try {
      final response = await dio.get("/messages/$myid/$receiverid");
      print(response.data);
      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        setState(() {
          msglist = data.map((msg) => MessageData(
            msgtext: msg['msgtext'],
            senderid: msg['senderid'],
            receiverid: msg['receiverid'],
            isme: msg['senderid'] == myid,
          )).toList();
        });
      }
    } catch (e) {
      if (kDebugMode) print("Error loading messages: $e");
    }
  }

  Future<void> sendmsg(String sendmsg) async {
    if (connected == true) {
      String msg =
          "{'auth':'$auth','cmd':'send','senderid':'$myid', 'receiverid':'$receiverid', 'msgtext':'$sendmsg'}";
      setState(() {
        msgtext.text = "";
        msglist.add(MessageData(msgtext: sendmsg, senderid: myid,receiverid: receiverid , isme: true));
      });
      channel.sink.add(msg); //send message to receiver channel
    } else {
      channelconnect();
      if (kDebugMode) {
        print("Websocket is not connected.");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("My ID: $myid - Chat App Example"),
          leading: Icon(Icons.circle,
              color: connected ? Colors.greenAccent : Colors.redAccent),
          //if app is connected to node.js then it will be gree, else red.
          titleSpacing: 0,
        ),
        body: Stack(
          children: [
        Positioned(
            top: 0,
            bottom: 70,
            left: 0,
            right: 0,
            child: Container(
                padding: const EdgeInsets.all(15),
                child: SingleChildScrollView(
                    child: Column(
                  children: [
                    const Text("Your Messages",
                        style: TextStyle(fontSize: 20)),
                    Column(
                      children: msglist.map((onemsg) {
                    return Container(
                        margin: EdgeInsets.only(
                          //if is my message, then it has margin 40 at left
                          left: onemsg.isme ? 40 : 0,
                          right: onemsg.isme
                              ? 0
                              : 40, //else margin at right
                        ),
                        child: Card(
                            color: onemsg.isme
                                ? Colors.blue[100]
                                : Colors.red[100],
                            //if its my message then, blue background else red background
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(15),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(onemsg.isme
                                      ? "ID: ME"
                                      : "ID: ${onemsg.receiverid}"),
                                  Container(
                                    margin: const EdgeInsets.only(
                                        top: 10, bottom: 10),
                                    child: Text(
                                        "Message: ${onemsg.msgtext}",
                                        style: const TextStyle(fontSize: 17)),
                                  ),
                                ],
                              ),
                            )));
                      }).toList(),
                    )
                  ],
                )))),
        Positioned(
          //position text field at bottom of screen

          bottom: 0, left: 0, right: 0,
          child: Container(
              color: Colors.black12,
              height: 70,
              child: Row(
                children: [
                  Expanded(
                      child: Container(
                    margin: const EdgeInsets.all(10),
                    child: TextField(
                      controller: msgtext,
                      decoration:
                          const InputDecoration(hintText: "Enter your Message"),
                    ),
                  )),
                  Container(
                      margin: const EdgeInsets.all(10),
                      child: ElevatedButton(
                        child: const Icon(Icons.send),
                        onPressed: () {
                          if (msgtext.text != "") {
                            sendmsg(msgtext.text); //send message with webspcket
                          } else {
                            if (kDebugMode) {
                              print("Enter message");
                            }
                          }
                        },
                      ))
                ],
              )),
        )
          ],
        ));
  }
}
