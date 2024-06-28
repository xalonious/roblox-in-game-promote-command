const express = require('express');
const noblox = require('noblox.js');
const fs = require("fs");
const path = require("path");
require("dotenv").config();
const app = express();
const port = process.env.PORT;

app.use(express.json());

fs.readdirSync(path.join(__dirname, "routes")).forEach((file) => {
    const route = require(path.join(__dirname, "routes", file));
    app.use(route);
});

app.listen(port, async() => {
    console.log(`✅ | Server is running on port ${port}`);
    await noblox.setCookie(process.env.COOKIE);
    console.log("✅ | Logged in as " + (await noblox.getCurrentUser()).UserName);
});
