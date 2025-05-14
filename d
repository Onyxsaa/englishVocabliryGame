<!DOCTYPE html>
<html lang="tr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Kelime Oyunu - Aşama 1</title>

</head>
<body>

    <h1 id="main-title">İngilizce Kelime Oyunu</h1>
    
    <div id="username-container">
        <h2>Oyuna Başla</h2>
        <label for="username-input">Kullanıcı Adınız:</label>
        <input type="text" id="username-input" required>
        <button id="save-username-button">Kaydet ve Başla</button>
    </div>

    <div id="timer-container" style="display: none;">
        Kalan Süre: <span id="timer">60</span> saniye
    </div>

    <div id="game-container">
        <div id="user-info">
            Merhaba, <strong id="username-display"></strong>! | Puan: <span id="score">0</span>
        </div>

        <div id="sentence-display">
            </div>
        <div class="action-buttons-container">
             <button id="speak-button" title="Dinle">🔊 Dinle</button>
        </div>
        <div id="choices-container">
            </div>
         <div class="action-buttons-container">
            <button id="next-button" title="Sonraki" disabled>İlerle</button>
         </div>
    </div>

    <div id="phase-transition-container">
        <h2>Aşama 1 Tamamlandı!</h2>
        <p>Tebrikler! İlk aşamayı bitirdin.</p>
        <p>Toplam Puanın: <span id="phase-score">0</span></p>
        <p>Aşama 1 Süresi: <span id="phase1-completion-time">0</span> saniye</p>
        <div class="selections-history">
            <h3>Aşama 1 Seçim Geçmişi</h3>
            <ul id="phase1-history"></ul>
        </div>
        <button id="start-phase2-button">Aşama 2'ye Başla</button>
    </div>

    <div id="game-over-container">
        <h2>Oyun Bitti!</h2>
        <p>Tebrikler, tüm aşamaları tamamladın!</p>
        <p>Final Puanın: <span id="final-score">0</span></p>
        <p>Toplam Oyun Süresi: <span id="total-completion-time">0</span> saniye</p>
        <div class="selections-history">
            <h3>Tüm Seçim Geçmişi</h3>
            <ul id="final-history"></ul>
        </div>
        <button id="restart-button">Yeniden Oyna</button>
    </div>

     <% if (error) { %>
        <p id="error-message"><%= error %></p>
    <% } %>

    <script>
        // --- Veriyi EJS'den Alma ---
        const allWordsData = <%- JSON.stringify(sozcukler) %>;
        const originalWordList = Object.keys(allWordsData);

        // --- DOM Elementleri ---
        const mainTitle = document.getElementById('main-title');
        const usernameContainer = document.getElementById('username-container');
        const gameContainer = document.getElementById('game-container');
        const phaseTransitionContainer = document.getElementById('phase-transition-container');
        const gameOverContainer = document.getElementById('game-over-container');
        const timerContainer = document.getElementById('timer-container');
        const timerDisplay = document.getElementById('timer');

        const usernameInput = document.getElementById('username-input');
        const saveUsernameButton = document.getElementById('save-username-button');
        const usernameDisplay = document.getElementById('username-display');
        const scoreDisplay = document.getElementById('score');
        const sentenceDisplay = document.getElementById('sentence-display'); // Aşama 2 için
        const speakButton = document.getElementById('speak-button');
        const choicesContainer = document.getElementById('choices-container');
        const nextButton = document.getElementById('next-button');
        const phaseScoreDisplay = document.getElementById('phase-score');
        const startPhase2Button = document.getElementById('start-phase2-button');
        const finalScoreDisplay = document.getElementById('final-score');
        const restartButton = document.getElementById('restart-button');
        const errorMessage = document.getElementById('error-message');
        const phase1CompletionTime = document.getElementById('phase1-completion-time');
        const totalCompletionTime = document.getElementById('total-completion-time');
        

        // --- Oyun Değişkenleri ---
        let currentPhase = 1;
        let currentScore = 0;
        let shuffledWordsPhase1 = [];
        let shuffledWordsPhase2 = [];
        let wordPointer = 0; // Mevcut listedeki sıra
        let currentWordData = null;
        let correctAnswer = '';
        let speechSupported = ('speechSynthesis' in window);
        let currentUsername = '';
        
        // Zamanlayıcı değişkenleri
        let timeRemaining = 60;
        let timerInterval = null;
        let gameStartTime = 0;
        let phase1EndTime = 0;
        let gameEndTime = 0;
        let phase1Duration = 0;
        let totalGameDuration = 0;
        
        // Seçim geçmişi için yeni eklenen değişken
        let selectionHistory = [];

        // --- Çerez (Cookie) Fonksiyonları ---
        function setCookie(name, value, days) { /* ... (öncekiyle aynı, ama artık kullanılmıyor) ... */ }
        function getCookie(name) { /* ... (öncekiyle aynı) ... */ }
        function deleteCookie(name) {
            document.cookie = name + '=; Path=/; Expires=Thu, 01 Jan 1970 00:00:01 GMT; SameSite=Lax';
        }

        // --- Yardımcı Fonksiyonlar ---
        function shuffleArray(array) {
            let newArray = [...array]; // Orijinal diziyi bozmamak için kopyala
            for (let i = newArray.length - 1; i > 0; i--) {
                const j = Math.floor(Math.random() * (i + 1));
                [newArray[i], newArray[j]] = [newArray[j], newArray[i]];
            }
            return newArray;
        }

        // --- Zamanlayıcı Fonksiyonları ---
        function startTimer() {
            timerContainer.style.display = 'block';
            timerDisplay.textContent = timeRemaining;
            
            timerInterval = setInterval(() => {
                timeRemaining--;
                timerDisplay.textContent = timeRemaining;
                
                if (timeRemaining <= 0) {
                    clearInterval(timerInterval);
                    handleTimeUp();
                }
            }, 1000);
        }
        
        function stopTimer() {
            if (timerInterval) {
                clearInterval(timerInterval);
                timerInterval = null;
            }
        }
        
        function resetTimer() {
            stopTimer();
            timeRemaining = 60;
            timerDisplay.textContent = timeRemaining;
        }
        
        // --- Rank Gönderme Fonksiyonu ---
        function sendRank() {
            const payload = {
                username: currentUsername,
                score: currentScore,
                totalTime: totalGameDuration
            };
            fetch('http://localhost:3000/rank', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(payload)
            })
            .then(response => {
                if (!response.ok) throw new Error('Sunucu hatası');
                return response.json();
            })
            .then(data => console.log('Rank kaydedildi:', data))
            .catch(err => console.error('Rank kaydedilirken hata:', err));
        }
        
        function handleTimeUp() {
            stopTimer();
            gameEndTime = Date.now();
            totalGameDuration = Math.floor((gameEndTime - gameStartTime) / 1000);
            
            // Rank sistemine puanı gönder
            sendRank();
            
            gameContainer.style.display = 'none';
            finalScoreDisplay.textContent = currentScore;
            totalCompletionTime.textContent = totalGameDuration;
            renderSelectionHistory('final-history'); // Seçim geçmişini göster
            gameOverContainer.style.display = 'block';
            mainTitle.textContent = "Oyun Bitti! - Süre Doldu";
            timerContainer.style.display = 'none';
        }

        // --- Konuşma Fonksiyonu ---
        function speakContent() {
            if (!speechSupported) {
                console.warn("Tarayıcınız konuşma sentezini desteklemiyor.");
                return;
            }
            if (!correctAnswer) return; // Henüz kelime seçilmediyse

            let textToSpeak = '';
            if (currentPhase === 1) {
                textToSpeak = correctAnswer; // Aşama 1: Kelimeyi oku
            } else {
                // Aşama 2: Tam cümleyi oku
                textToSpeak = allWordsData[correctAnswer]?.cumle?.tam || correctAnswer; // Cümle yoksa kelimeyi oku
            }

            window.speechSynthesis.cancel();
            const utterance = new SpeechSynthesisUtterance(textToSpeak);
            utterance.lang = 'en-US';
            utterance.rate = 0.5; // Yavaş hız
            window.speechSynthesis.speak(utterance);
        }

        // --- Seçim Geçmişi Görüntüleme Fonksiyonu ---
        function renderSelectionHistory(containerId, phase = null) {
            const container = document.getElementById(containerId);
            if (!container) return;
            
            const filtered = phase ? 
                selectionHistory.filter(item => item.phase === phase) : 
                selectionHistory;
            
            container.innerHTML = filtered.map((item, index) => `
                <li class="${item.isCorrect ? 'correct' : 'incorrect'}">
                    ${index + 1}. Soru - Kelime: "${item.word}" → 
                    Seçilen: "${item.selected}" 
                    (${item.isCorrect ? '✓' : '✗'})
                </li>
            `).join('');
        }

        // --- Oyun Mantığı ---
        function loadNextWord() {
            const currentList = currentPhase === 1 ? shuffledWordsPhase1 : shuffledWordsPhase2;

            // Mevcut aşamanın kelimeleri bitti mi?
            if (wordPointer >= currentList.length) {
                if (currentPhase === 1) {
                    // Aşama 1 bitti, Aşama 2'ye geçiş ekranını göster
                    stopTimer();
                    phase1EndTime = Date.now();
                    phase1Duration = Math.floor((phase1EndTime - gameStartTime) / 1000);
                    
                    gameContainer.style.display = 'none';
                    phaseScoreDisplay.textContent = currentScore;
                    phase1CompletionTime.textContent = phase1Duration;
                    renderSelectionHistory('phase1-history', 1); // Aşama 1 geçmişini göster
                    phaseTransitionContainer.style.display = 'block';
                    mainTitle.textContent += " - Aşama 1 Bitti";
                    timerContainer.style.display = 'none';
                } else {
                    // Aşama 2 bitti, Oyun Sonu ekranını göster
                    stopTimer();
                    gameEndTime = Date.now();
                    totalGameDuration = Math.floor((gameEndTime - gameStartTime) / 1000);
                    
                    // Rank sistemine puanı gönder
                    sendRank();
                    
                    gameContainer.style.display = 'none';
                    finalScoreDisplay.textContent = currentScore;
                    totalCompletionTime.textContent = totalGameDuration;
                    renderSelectionHistory('final-history'); // Tüm seçim geçmişini göster
                    gameOverContainer.style.display = 'block';
                    mainTitle.textContent = "Oyun Bitti!";
                    timerContainer.style.display = 'none';
                }
                return; // İşlemi bitir, yeni kelime yükleme
            }

            // Kelimeyi al ve quiz'i kur
            const nextWord = currentList[wordPointer];
            setupQuiz(nextWord);
            wordPointer++; // Sıradaki kelimeye geç
        }

        function setupQuiz(word) {
             if (!word || !allWordsData[word]) {
                  console.error(`Kelime verisi bulunamadı: ${word}`);
                  choicesContainer.innerHTML = "<p>Bu kelime için veri bulunamadı.</p>";
                  speakButton.disabled = true; nextButton.disabled = true; return;
             }

            correctAnswer = word;
            currentWordData = allWordsData[word];

            // Aşama 2'ye özel: Eksik cümleyi göster
            if (currentPhase === 2) {
                const incompleteSentence = currentWordData.cumle?.eksik;
                if (incompleteSentence) {
                    sentenceDisplay.textContent = incompleteSentence;
                    sentenceDisplay.style.display = 'block';
                } else {
                    sentenceDisplay.style.display = 'none'; // Cümle yoksa gizle
                }
                speakButton.textContent = "🔊 Cümleyi Dinle";
                speakButton.title = "Tam Cümleyi Dinle";
            } else {
                sentenceDisplay.style.display = 'none'; // Aşama 1'de cümle alanını gizle
                speakButton.textContent = "🔊 Kelimeyi Dinle";
                speakButton.title = "Kelimeyi Dinle";
            }

            // Şıkları oluştur (Aşama 1 ve 2 için aynı mantık)
            let choices = [correctAnswer];
            let similarWords = currentWordData.benzerler ? shuffleArray([...currentWordData.benzerler]) : [];
             const correctIndexInSimilar = similarWords.indexOf(correctAnswer);
             if (correctIndexInSimilar > -1) { similarWords.splice(correctIndexInSimilar, 1); }

             const distractorsNeeded = 3;
             for(let i = 0; i < similarWords.length && choices.length < (distractorsNeeded + 1); i++) {
                 if(!choices.includes(similarWords[i])) { choices.push(similarWords[i]); }
             }
            // Distractors'i karıştır ve 3 şıka dönüştür (doğru cevap ile toplam 4 şık)
            choices = shuffleArray([correctAnswer, ...similarWords.slice(0, 3)]);

            // Butonları oluştur
            choicesContainer.innerHTML = '';
            choices.forEach(choice => {
                const button = document.createElement('button');
                button.classList.add('choice-button');
                button.textContent = choice;
                button.dataset.answer = choice;
                button.addEventListener('click', handleAnswerClick);
                choicesContainer.appendChild(button);
            });

            speakButton.disabled = false;
            nextButton.disabled = true; // Cevap verilince aktifleşecek
        }

        function handleAnswerClick(event) {
            const selectedButton = event.target;
            const selectedAnswer = selectedButton.dataset.answer;
            const allChoiceButtons = choicesContainer.querySelectorAll('.choice-button');
            allChoiceButtons.forEach(btn => btn.disabled = true);

            if (selectedAnswer === correctAnswer) {
                selectedButton.classList.add('correct');
                currentScore += 5;
                scoreDisplay.textContent = currentScore; // Skoru ekranda güncelle
            } else {
                selectedButton.classList.add('incorrect');
                const correctButton = choicesContainer.querySelector(`.choice-button[data-answer="${correctAnswer}"]`);
                if (correctButton) { correctButton.classList.add('correct'); }
            }
            
            // Seçim geçmişine ekleme
            selectionHistory.push({
                phase: currentPhase,
                word: correctAnswer,
                selected: selectedAnswer,
                isCorrect: selectedAnswer === correctAnswer,
                timestamp: new Date().toLocaleTimeString()
            });
            
            nextButton.disabled = false; // İlerle butonunu aktif et
        }

        function startPhase2() {
            currentPhase = 2;
            wordPointer = 0; // Sayacı sıfırla
            shuffledWordsPhase2 = shuffleArray(originalWordList); // Aşama 2 için listeyi karıştır

            phaseTransitionContainer.style.display = 'none'; // Geçiş ekranını gizle
            gameContainer.style.display = 'block';          // Oyun ekranını göster
            mainTitle.textContent = "İngilizce Kelime Oyunu - Aşama 2"; // Başlığı güncelle
            scoreDisplay.textContent = currentScore; // Skoru tekrar yaz (gerekliyse)
            usernameDisplay.textContent = currentUsername; // Kullanıcı adını tekrar yaz
            
            // Aşama 1 seçim geçmişini render et
            renderSelectionHistory('phase1-history', 1);
            
            // Aşama 2 için zamanlayıcıyı yeniden başlat
            resetTimer();
            startTimer();
            timerContainer.style.display = 'block';

            loadNextWord(); // Aşama 2'nin ilk kelimesini yükle
        }

        function restartGame() {
            // Oyun yeniden başlatılmadan önce son kez seçim geçmişini göster
            renderSelectionHistory('final-history');
            window.location.reload(); // Sayfayı yeniden yükleyerek oyunu sıfırla
        }

        // --- Başlangıç Ayarları ---
        function initializeGame() {
            console.log("Oyun başlatılıyor, çerezler siliniyor...");
            deleteCookie('username');
            deleteCookie('score');

            if (errorMessage) {
                 console.error("Sunucu Hatası:", errorMessage.textContent);
                 usernameContainer.style.display = 'none'; return;
             }
             if (originalWordList.length === 0 && !errorMessage) {
                 console.error("Başlatılacak kelime bulunamadı.");
                 usernameContainer.innerHTML = "<p>Oyun başlatılamıyor. Kelime verisi yok.</p>";
                 usernameContainer.style.display = 'block'; return;
             }

            // Her zaman kullanıcı adı girişi ile başla
            usernameContainer.style.display = 'block';
            gameContainer.style.display = 'none';
            phaseTransitionContainer.style.display = 'none';
            gameOverContainer.style.display = 'none';
            timerContainer.style.display = 'none';

            // --- Event Listener'lar ---
            saveUsernameButton.addEventListener('click', () => {
                currentUsername = usernameInput.value.trim(); // Kullanıcı adını değişkene ata
                if (currentUsername) {
                    usernameDisplay.textContent = currentUsername; // Ekranda göster
                    currentScore = 0; // Skoru sıfırla
                    scoreDisplay.textContent = currentScore;
                    currentPhase = 1; // Aşama 1'den başla
                    wordPointer = 0; // Sayacı sıfırla
                    shuffledWordsPhase1 = shuffleArray(originalWordList); // Aşama 1 listesini karıştır
                    selectionHistory = []; // Seçim geçmişini temizle

                    usernameContainer.style.display = 'none'; // Giriş ekranını gizle
                    gameContainer.style.display = 'block';     // Oyun ekranını göster
                    mainTitle.textContent = "İngilizce Kelime Oyunu - Aşama 1"; // Başlığı ayarla
                    
                    // Oyunu başlat ve zamanlayıcıyı başlat
                    gameStartTime = Date.now();
                    startTimer();

                    loadNextWord(); // Aşama 1'in ilk kelimesini yükle
                } else {
                    alert('Lütfen geçerli bir kullanıcı adı girin.');
                }
            });

            speakButton.addEventListener('click', speakContent); // Güncellenmiş konuşma fonksiyonunu çağır
            nextButton.addEventListener('click', loadNextWord);
            startPhase2Button.addEventListener('click', startPhase2); // Aşama 2'yi başlatan butona olay ekle
            restartButton.addEventListener('click', restartGame); // Yeniden başlatma butonuna olay ekle
        }

        // Sayfa yüklendiğinde oyunu başlat
        window.addEventListener('DOMContentLoaded', initializeGame);
    </script>

</body>
</html>



<style>
    /* --- Temel Resetleme ve Kutu Modeli --- */
    * { margin: 0; padding: 0; box-sizing: border-box; }
    /* --- Modern Font ve Temel Gövde Stilleri --- */
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; line-height: 1.6; background-color: #f4f7f9; color: #333; padding: 20px; display: flex; flex-direction: column; align-items: center; min-height: 100vh; }
    /* --- Ana Konteynerler --- */
    #username-container, #game-container, #phase-transition-container, #game-over-container { background-color: #ffffff; padding: 25px 30px; border-radius: 8px; box-shadow: 0 4px 15px rgba(0, 0, 0, 0.1); width: 100%; max-width: 600px; margin-bottom: 25px; text-align: center; }
    /* --- Başlık --- */
    h1 { color: #2c3e50; margin-bottom: 25px; text-align: center; font-weight: 600; }
    h2 { color: #34495e; margin-bottom: 15px; font-weight: 500; }
    /* --- Kullanıcı Adı Giriş Alanı --- */
    #username-container label { display: block; margin-bottom: 10px; font-weight: 500; color: #555; }
    #username-input { width: 100%; max-width: 300px; padding: 12px 15px; border: 1px solid #ccc; border-radius: 5px; font-size: 1em; margin-bottom: 15px; transition: border-color 0.3s ease; }
    #username-input:focus { border-color: #007bff; outline: none; }
    /* --- Genel Buton Stilleri --- */
    button { padding: 12px 20px; font-size: 1em; cursor: pointer; border: none; border-radius: 5px; transition: background-color 0.3s ease, transform 0.1s ease; font-weight: 500; margin: 5px; }
    button:active:not(:disabled) { transform: scale(0.98); }
    button:disabled { cursor: not-allowed; opacity: 0.6; }
    /* --- Spesifik Butonlar --- */
    #save-username-button { background-color: #007bff; color: white; }
    #save-username-button:hover:not(:disabled) { background-color: #0056b3; }
    #speak-button { background-color: #28a745; color: white; }
    #speak-button:hover:not(:disabled) { background-color: #218838; }
    #next-button { background-color: #17a2b8; color: white; }
    #next-button:hover:not(:disabled) { background-color: #138496; }
    #start-phase2-button, #restart-button { background-color: #ffc107; color: #333; font-weight: 600; }
    #start-phase2-button:hover:not(:disabled), #restart-button:hover:not(:disabled) { background-color: #e0a800; }
    /* --- Oyun Alanı --- */
    #game-container, #phase-transition-container, #game-over-container { display: none; /* Başlangıçta gizli */ }
    /* --- Kullanıcı Bilgisi ve Skor --- */
    #user-info { margin-bottom: 20px; font-size: 1.1em; color: #555; text-align: center; border-bottom: 1px solid #eee; padding-bottom: 15px; }
    #score { font-weight: 700; color: #e8491d; margin-left: 5px; }
    #username-display { font-weight: 600; color: #333; }
    /* --- Cümle Gösterim Alanı (Aşama 2) --- */
    #sentence-display { margin: 20px 0; padding: 15px; background-color: #e9ecef; border-radius: 5px; font-size: 1.1em; color: #495057; text-align: center; display: none; /* Başlangıçta gizli */ }
    /* --- Aksiyon Butonları Konteyneri --- */
    .action-buttons-container { text-align: center; margin-bottom: 25px; }
    /* --- Şık Butonları Konteyneri --- */
    #choices-container { margin-top: 25px; margin-bottom: 25px; display: grid; grid-template-columns: repeat(auto-fit, minmax(120px, 1fr)); gap: 10px; }
    /* --- Şık Butonları --- */
    .choice-button { background-color: #e9ecef; color: #333; border: 1px solid #ced4da; width: 100%; padding: 15px 10px; font-size: 1em; text-align: center; }
    .choice-button:hover:not(:disabled) { background-color: #dee2e6; border-color: #adb5bd; }
    .choice-button.correct { background-color: #28a745; color: white; border-color: #218838; }
    .choice-button.incorrect { background-color: #dc3545; color: white; border-color: #c82333; }
    /* --- Geçiş/Oyun Sonu Mesajları --- */
    #phase-score, #final-score { font-size: 1.4em; font-weight: bold; color: #007bff; margin: 15px 0; }
    /* --- Hata Mesajı --- */
    #error-message { color: #dc3545; font-weight: bold; margin-top: 15px; text-align: center; background-color: #f8d7da; border: 1px solid #f5c6cb; padding: 10px; border-radius: 5px; max-width: 600px; width: 100%; }
    /* --- Zamanlayıcı Stili --- */
    #timer-container { 
        position: fixed; 
        top: 10px; 
        right: 10px; 
        background-color: #e8491d; 
        color: white; 
        padding: 8px 15px; 
        border-radius: 20px; 
        font-weight: bold; 
        font-size: 1.2em; 
        box-shadow: 0 2px 5px rgba(0,0,0,0.2);
        z-index: 100;
    }
    #timer { font-weight: 700; }
    
    /* --- Yeni eklenen seçim geçmişi stilleri --- */
    .selections-history { 
        margin-top: 20px;
        padding: 15px;
        background-color: #f8f9fa;
        border-radius: 8px;
        text-align: left;
    }
    .selections-history h3 {
        color: #2c3e50;
        margin-bottom: 10px;
    }
    .selections-history ul {
        list-style-type: none;
    }
    .selections-history li {
        padding: 8px;
        margin: 5px 0;
        background-color: #e9ecef;
        border-radius: 4px;
    }
    .selections-history .correct { color: #28a745; }
    .selections-history .incorrect { color: #dc3545; }
    
    /* --- Mobil Uyumluluk --- */
    @media (max-width: 480px) {
        body { padding: 10px; }
        #username-container, #game-container, #phase-transition-container, #game-over-container { padding: 20px 15px; }
        h1 { font-size: 1.8em; margin-bottom: 20px; }
        #username-input { max-width: none; }
        #speak-button, #next-button { display: block; width: 100%; margin: 10px 0; }
        #choices-container { grid-template-columns: 1fr; gap: 8px; }
        .choice-button { padding: 12px 10px; }
        #sentence-display { font-size: 1em; }
        #timer-container { font-size: 1em; padding: 5px 10px; }
    }
</style>