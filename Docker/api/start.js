const express = require("express");
require("dotenv").config(); // Load environment variables

const app = express();
app.use(express.json()); // Enable JSON parsing

const PORT = process.env.PORT || 3000;
app.get("/", (req, res) => {
  res.status(200).json({ message: "API is running successfully!" });
});
// Example Write-Only API Endpoint
app.post("/store-data", (req, res) => {
  console.log("Received Data:", req.body);
  res.status(200).send({ message: "Data stored successfully!" });
});

app.listen(PORT, "0.0.0.0", () => {
  console.log(`✅ Server is running on http://0.0.0.0:${PORT}`);
});
