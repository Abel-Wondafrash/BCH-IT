const express = require("express");
const cors = require("cors");
const bodyParser = require("body-parser");
const path = require("path"); // Import path module for serving static files

const app = express();
const port = 3000;

app.use(cors()); // Enable CORS
app.use(bodyParser.json()); // Parse JSON bodies

let dataStore = {};

// Serve static files from the 'ti-client' directory
app.use(express.static(path.join(__dirname, "../ti-client")));

// Handle POST requests at /data
app.post("/data", (req, res) => {
  // console.log("Received data:", req.body); // Log received data
  dataStore = req.body; // Store the entire request body in dataStore
  res.status(200).json({
    message: "Data received",
    receivedData: req.body,
  });
});

// Handle GET requests at /data
app.get("/data", (req, res) => {
  // console.log("Sending data:", dataStore); // Log stored data
  res.status(200).json(dataStore); // Send the stored data
});

// Default route to serve index.html
app.get("*", (req, res) => {
  res.sendFile(path.join(__dirname, "../ti-client/index.html"));
});

app.listen(port, () => {
  console.log(`Server is running on http://localhost:${port}`);
});
