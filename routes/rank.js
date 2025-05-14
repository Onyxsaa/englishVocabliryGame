const express = require('express');
const mongoose = require('mongoose');
const router = express.Router();

// 'rank' veritabanına bağlan
const rankConn = mongoose.createConnection(
  'mongodb://root:12345678@localhost:27017/rank?authSource=admin',
  { useNewUrlParser: true, useUnifiedTopology: true }
);

rankConn.on('connected', () => console.log('✅ Rank DB bağlantısı başarılı'));
rankConn.on('error', err => console.error('❌ Rank DB bağlantı hatası:', err));

// Rank şeması ve modeli
const rankSchema = new mongoose.Schema({
  username:  { type: String, required: true },
  totalTime: { type: Number, required: true },
  score:     { type: Number, required: true },
  createdAt: { type: Date, default: Date.now }
}, {
  collection: 'rank'
});

const Rank = rankConn.model('Rank', rankSchema);

// POST /rank -> veri ekle ve sonra tüm verileri gönder
router.post('/', async (req, res) => {
  try {
    const { username, totalTime, score } = req.body;

    // Yeni veriyi kaydet
    const newDoc = new Rank({ username, totalTime, score });
    await newDoc.save();

    console.log('✅ Yeni kayıt eklendi:', newDoc);

    // Tüm verileri çek
    const allRanks = await Rank.find().sort({ score: -1 }); // skor sırasına göre büyükten küçüğe

    res.status(201).json({
      data: allRanks
    });

  } catch (err) {
    console.error('❌ Hata:', err);
    res.status(500).json({ error: 'Veri eklenemedi veya veriler çekilemedi.' });
  }
});

module.exports = router;
