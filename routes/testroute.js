const express = require("express");
const router = express.Router();

router.get("/test", (req, res) => {
    res.send("this shit works hahaha");
});

module.exports = router;

