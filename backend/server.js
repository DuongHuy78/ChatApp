require('dotenv').config();
const WebSocket = require("ws");
const express = require("express");
const moment = require("moment");
const mongoose = require("mongoose");
const jwt = require("jsonwebtoken");



// Connect to MongoDB
// mongoose.connect("mongodb://127.0.0.1/chat", {
//   useNewUrlParser: true,
//   useUnifiedTopology: true,
// });
// mongoose.connect("mongodb://127.0.0.1/chat");

mongoose.connect(process.env.MONGODB_URI);
const port = process.env.PORT || 8000;
const wsPort = process.env.WS_PORT || 6060;

// Define user schema and model
const userSchema = new mongoose.Schema({
  userid: { type: String, unique: true, required: true },
  email: { type: String, unique: true, required: true },
  password: { type: String, required: true },
  createdAt: { type: Date, default: Date.now },
});
const User = mongoose.model("User", userSchema);

// Define message schema and model
const messageSchema = new mongoose.Schema({
  cmd: String,
  senderid: String,
  receiverid: String,
  msgtext: String,
  timestamp: String,
});
const Message = mongoose.model("Message", messageSchema);
messageSchema.index({ senderid: 1, receiverid: 1, timestamp: 1 }, { unique: true });

const app = express();
app.use(express.json());
// const port = 8000; //port for https



//login and signup

async function generateUserId() {
  const lastUser = await User.findOne().sort({ userid: -1 });  // Tìm userid lớn nhất, -1 là decrease giảm dần, ngc lại là 1
  const nextId = lastUser ? parseInt(lastUser.userid) + 1 : 1;  // Tăng 1, hoặc bắt đầu từ 1
  return nextId.toString();
}

app.post("/register", async (req, res) => {
  const { email, password } = req.body;
  try {
    const userid = await generateUserId();
    const user = new User({ userid, email, password: password });
    await user.save();
    res.status(201).json({ message: "User registered successfully" });
  } catch (error) {
    res.status(400).json({ error: "Registration failed", details: error.message });
  }
});

// Login route
app.post("/login", async (req, res) => {
  const { email, password } = req.body;
  try {
    const user = await User.findOne({ email });
    if (user &&  user.password == password) {
      const token = jwt.sign({ userid: user.userid }, "your_secret_key", { expiresIn: "1h" });
      res.json({ token, userid: user.userid });
    } else {
      res.status(401).json({ error: "Invalid credentials" });
    }
  } catch (error) {
    res.status(500).json({ error: "Login failed" });
  }
});


//list message User
app.get("/users", async (req, res) => {
  try {
    const users = await User.find({}, { userid: 1, email: 1, _id: 0 });  // Chỉ lấy userid và email
    res.json(users);
  }
  catch (e) {
    console.log("Database query error:", error);
    res.status(500).json({ error: "Failed to load users" });
  }
})


//message
app.get("/messages/:userid1/:userid2", async (req, res) => {
  const userid1 = req.params.userid1;
  const userid2 = req.params.userid2;
  try {
      const messages = await Message.find({
      $or: [  // Điều kiện OR: tin nhắn từ user1 hoặc user2
        { senderid: userid1, receiverid: userid2 }, 
        { senderid: userid2, receiverid: userid1 }
      ]
    }).sort({ timestamp: 1 });  // Sắp xếp theo thời gian tăng dần (cũ nhất trước)
    console.log("DAYYYYYYYYYYYYYYYYYYYYYYYYYYY");
    console.log(messages);
    res.json(messages);  // Trả về array JSON cho client
  } catch (error) {
    console.log("Database query error:", error);
    res.status(500).json({ error: "Failed to load messages" });
  }
});

// app.listen(port, () => {
//   console.log(`Example app listening at ${port}`);
// });
const http = require("http");

// create http server from express
const server = http.createServer(app);
const wss = new WebSocket.Server({ noServer: true });

server.on("upgrade", (request, socket, head) => {
  // Optionally validate auth here using request.headers, cookies, etc.
  wss.handleUpgrade(request, socket, head, (ws) => {
    wss.emit("connection", ws, request);
  });
});

server.listen(port, () => {
  console.log(`HTTP + WS server listening on port ${port}`);
});

var webSockets = {};

//const wss = new WebSocket.Server({ port: 6060 }); //run websocket server with port 6060
wss.on("connection", function (ws, req) {
  var userID = req.url.substr(1); //get userid from URL /userid
  webSockets[userID] = ws; //add new user to the connection list

  console.log("User " + userID + " Connected ");

  ws.on("message", async (message) => {
    //if there is any message
    console.log(message);
    var datastring = message.toString();
    if (datastring.charAt(0) == "{") {
      datastring = datastring.replace(/\'/g, '"');
      var data = JSON.parse(datastring);
      if (data.auth == "addauthkeyifrequired") {
        if (data.cmd == "send") {
          var boardws = webSockets[data.receiverid]; //check if there is receiver connection
          if (!data.senderid || !data.receiverid || !data.msgtext) {
            console.log("Missing required fields in data");
            ws.send(data.cmd + ":error");
            return;
          }
          if (boardws) {
            var cdata =
              "{'cmd':'" +
              data.cmd +
              "','senderid':'" +
              data.senderid +
              "', 'receiverid':'" +
              data.receiverid +
              "', 'msgtext':'" +
              data.msgtext +
              "'}";
              console.log("DU Lieu Server luu");
              console.log(cdata);
            boardws.send(cdata); //send message to receiver
            ws.send(data.cmd + ":success");

            // Save message to database
            const message = new Message({
              cmd: data.cmd,
              senderid: userID,
              receiverid: data.receiverid,
              msgtext: data.msgtext,
              timestamp: moment().format(),
            });
            await message.save();
          } else {
            console.log("No receiver user found.");
            ws.send(data.cmd + ":error");
          }
        } else {
          console.log("No send command");
          ws.send(data.cmd + ":error");
        }
      } else {
        console.log("App Authentication error");
        ws.send(data.cmd + ":error");
      }
    } else {
      console.log("Non JSON type data");
      ws.send(data.cmd + ":error");
    }
  });

  ws.on("close", function () {
    var userID = req.url.substr(1);
    delete webSockets[userID]; //on connection close, remove receiver from connection list
    console.log("User Disconnected: " + userID);
  });

  ws.send("connected"); //initial connection return message
});


