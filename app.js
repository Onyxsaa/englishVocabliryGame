// app.js
const createError  = require('http-errors');
const express      = require('express');
const path         = require('path');
const cookieParser = require('cookie-parser');
const logger       = require('morgan');
const mongoose     = require('mongoose');

// Routers
const indexRouter  = require('./routes/index');
const usersRouter  = require('./routes/users');
const basitRouter  = require("./routes/basitRouter");
const rankRouer    = require('./routes/rank');
const ortaRouter = require('./routes/orta')
const ortaRank = require('./routes/ortaRank')
const hard = require('./routes/hard')
const hardRank = require('./routes/hardRank')
const app = express();

// 1) Mongoose bağlantısı (tek seferlik, başta)
const dbURI = 'mongodb://root:12345678@localhost:27017/sozcukDb?authSource=admin';
mongoose.connect(dbURI, {
  useNewUrlParser:    true,
  useUnifiedTopology: true
})
  .then(() => console.log('✅ MongoDB bağlantısı başarılı'))
  .catch((err) => console.error('❌ MongoDB bağlantı hatası:', err));

// 2) View engine
app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'ejs');

// 3) Middlewares
app.use(logger('dev'));

// ⚠️ JSON parse hatalarını yakalayıp 400 dönsün:
app.use(express.json());
app.use((err, req, res, next) => {
  if (err instanceof SyntaxError && err.status === 400 && 'body' in err) {
    return res.status(400).send('Malformed JSON');
  }
  next();
});

// Form‑data / URL‑encoded parser
app.use(express.urlencoded({ extended: true }));

app.use(cookieParser());
app.use(express.static(path.join(__dirname, 'public')));

// 4) Router’lar
app.use('/',    indexRouter);
app.use('/users', usersRouter);
app.use('/basit', basitRouter);
app.use('/rank', rankRouer);
app.use('/orta', ortaRouter)
app.use('/ortaRank', ortaRank)
app.use('/hard', hard)
app.use('/hardRank', hardRank)




// 5) 404 handler
app.use((req, res, next) => {
  next(createError(404));
});

// 6) Genel error handler
app.use((err, req, res, next) => {
  res.locals.message = err.message;
  res.locals.error   = req.app.get('env') === 'development' ? err : {};
  res.status(err.status || 500);
  res.render('error');
});

// 7) Server start
const PORT = 3000;
app.listen(PORT, () => {
  console.log(`🚀 Server started at http://localhost:${PORT}`);
});

module.exports = app;
