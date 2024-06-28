const express = require("express");
const router = express.Router();
require("dotenv").config();
const noblox = require("noblox.js");
const axios = require("axios");
const getUserAvatar = require("../utils/getUserAvatar");

router.post("/promote", async (req, res) => {

    const authHeader = req.headers.authorization;
    if (authHeader !== process.env.APIKEY) {
        const clientIP = req.headers['x-forwarded-for'] 
        console.log(`❗| Unauthorized request from ${clientIP}`);
        return res.status(401).json({ success: false, message: "Unauthorized" });
    }

    const { username, runner } = req.body;

    if(!username || !runner) return res.status(400).json({ success: false, message: "Bad request"})

    try {
        const targetID = await noblox.getIdFromUsername(username);
        const oldRank = await noblox.getRankNameInGroup(process.env.GROUP_ID, targetID);
        await noblox.promote(process.env.GROUP_ID, targetID);
        const newRank = await noblox.getRankNameInGroup(process.env.GROUP_ID, targetID);

        const webhookUrl = process.env.WEBHOOK_URL;
        const avatarUrl = await getUserAvatar(targetID);

        const embed = {
            title: "User promoted",
            description: "Someone was promoted using the in-game promote command",
            color: 0x5865F2,
            thumbnail: {
                url: avatarUrl
            },
            fields: [
                {
                    name: "Username",
                    value: username
                },
                {
                    name: "Promoted by",
                    value: runner
                },
                {
                    name: "Old Rank",
                    value: oldRank
                },
                {
                    name: "New Rank",
                    value: newRank
                }
            ]
        };

        await axios.post(webhookUrl, { embeds: [embed] });

        return res.status(200).json({ success: true, message: "User has been promoted" });

    } catch (e) {
        console.error("Error promoting user:", e);
        return res.status(500).json({ success: false, message: "An error occurred, please try again later" });
    }
});

module.exports = router;