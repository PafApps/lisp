document.addEventListener('DOMContentLoaded', () => {
    const loadBtn = document.getElementById('load-commands-btn');
    const appContent = document.getElementById('app-content');
    const addCommandForm = document.getElementById('add-command-form');

    let GITHUB_USER = '';
    let GITHUB_REPO = '';
    let FILE_PATH = '';
    let GITHUB_PAT = '';
    
    // --- API Взаимодействие ---
    async function getFileContent(user, repo, path, token) {
        console.log("getFileContent: Изпращане на заявка до GitHub...");
        const url = `https://api.github.com/repos/${user}/${repo}/contents/${path}`;
        try {
            const response = await fetch(url, { headers: { 'Authorization': `token ${token}`, 'Accept': 'application/vnd.github.v3+json' } });
            console.log("getFileContent: Получен отговор със статус:", response.status);
            if (!response.ok) throw new Error(`Грешка при зареждане: ${response.statusText}`);
            const data = await response.json();
            const decodedContent = decodeURIComponent(escape(atob(data.content)));
            console.log("getFileContent: Файлът е успешно изтеглен и декодиран.");
            return { content: decodedContent, sha: data.sha };
        } catch (error) {
            console.error("getFileContent: ГРЕШКА:", error);
            updateStatus(`Грешка: ${error.message}`, 'error');
            return null;
        }
    }
    
    async function updateFileContent(user, repo, path, token, newContent, sha, commitMessage) {
        // ... (Тази функция е коректна и остава същата)
    }

    // --- ПАРСЕР С ПОВЕЧЕ ДИАГНОСТИКА ---
    function parseLispContent(content) {
        console.log("parseLispContent: Започвам парсване на съдържанието...");
        const commands = [];
        const sections = [];
        const lines = content.split('\n');
        
const sectionRegex = /;;; START (.*) KEYS/; 
        const commandMapRegex = /\("([^"]+)"\s+\.\s+"([^"]+)"\)/;
        const dclLabelRegex = /label = "([^"]*)"/; 
        const dclKeyRegex = /key = "([^"]+)"/;

        let commandMap = {};
        let inCommandMap = false;

        lines.forEach(line => {
            if (line.includes(';;; START COMMAND MAP')) inCommandMap = true;
            if (line.includes(';;; END COMMAND MAP')) inCommandMap = false;
            if (inCommandMap) {
                const match = line.match(commandMapRegex);
                if (match) commandMap[match[1]] = match[2];
            }
        });
        console.log("parseLispContent: Намерени команди в *command-map*:", Object.keys(commandMap).length);
        
        let descriptions = {};
        let currentDclKey = null;
        lines.forEach(line => {
             if (line.includes(': button {')) {
                const keyMatch = line.match(dclKeyRegex);
                if (keyMatch) currentDclKey = keyMatch[1].trim();
            }
            if (line.includes(': text_part {')) {
                 const labelMatch = line.match(dclLabelRegex);
                 if(labelMatch && currentDclKey) {
                    const desc = labelMatch[1].trim().replace(/^-\s*/, '').trim();
                    if(desc) descriptions[currentDclKey] = desc;
                    currentDclKey = null; 
                 }
            }
        });
        console.log("parseLispContent: Извлечени описания от DCL:", Object.keys(descriptions).length);

        lines.forEach(line => {
            const sectionMatch = line.match(sectionRegex);
            if (sectionMatch && sectionMatch[1]) {
                const sectionNameRaw = sectionMatch[1].trim();
                // Преобразуваме име като SITUACIA в Situacia
                const sectionName = sectionNameRaw.charAt(0) + sectionNameRaw.slice(1).toLowerCase();
                if (!sections.includes(sectionName)) {
                    console.log(`parseLispContent: Намерена нова секция: ${sectionName}`);
                    sections.push(sectionName);
                }
                
                // Този Regex е по-надежден, защото не зависи от името на променливата
                const keysMatch = line.match(/'(\(.*\))/);
                if (keysMatch && keysMatch[1]) {
                    const keys = keysMatch[1].match(/"[^"]+"/g).map(k => k.replace(/"/g, ''));
                    console.log(`parseLispContent: Намерени ${keys.length} ключа за секция ${sectionName}`);
                    keys.forEach(key => {
                        if (commandMap[key] && !commands.some(cmd => cmd.key === key)) {
                           commands.push({
                               key: key,
                               label: descriptions[key] || `Изпълнява: ${commandMap[key]}`,
                               section: sectionName,
                           });
                        }
                    });
                }
            }
        });
        
        console.log(`parseLispContent: Парсването приключи. Общо намерени команди: ${commands.length}, Общо секции: ${sections.length}`);
        return { commands, sections };
    }

    // ... (displayCommands остава същата)
    function displayCommands(commands, sections) { /* ... */ }
    
    const sectionToKeyMap = { /* ... */ };

    function addNewCommandToContent(originalContent, newCommand) { /* ... */ }
    
    function updateStatus(message, type) { /* ... */ }
    
    // --- СЪБИТИЕ С ВЪРНАТА ДИАГНОСТИКА ---
    loadBtn.addEventListener('click', async () => {
        console.clear(); // Изчистваме конзолата за нов тест
        console.log("=====================================");
        console.log("НОВ ОПИТ ЗА ЗАРЕЖДАНЕ");
        console.log("=====================================");
        
        console.log("1. Прочитане на потребителските данни...");
        GITHUB_USER = document.getElementById('githubUser').value.trim();
        GITHUB_REPO = document.getElementById('githubRepo').value.trim();
        FILE_PATH = document.getElementById('filePath').value.trim();
        GITHUB_PAT = document.getElementById('githubPat').value.trim();
        console.log(" -> Потребител:", GITHUB_USER);
        console.log(" -> Хранилище:", GITHUB_REPO);
        console.log(" -> Файл:", FILE_PATH);
        console.log(" -> Токен (дължина):", GITHUB_PAT.length);

        if (!GITHUB_USER || !GITHUB_REPO || !FILE_PATH || !GITHUB_PAT) {
            updateStatus('Моля, попълнете всички полета за настройка.', 'error');
            return;
        }
        
        console.log("2. Показване на 'Зареждане...'");
        appContent.classList.remove('hidden');
        document.getElementById('commands-container').innerHTML = '<p class="loading">Зареждане...</p>';
        
        console.log("3. Извикване на getFileContent...");
        const fileData = await getFileContent(GITHUB_USER, GITHUB_REPO, FILE_PATH, GITHUB_PAT);
        
        if (fileData) {
            console.log("4. Данните са получени. Извикване на parseLispContent...");
            const { commands, sections } = parseLispContent(fileData.content);
            
            console.log("5. Парсването приключи. Извикване на displayCommands...");
            displayCommands(commands, sections);
            console.log("6. displayCommands приключи.");
        } else {
            console.error("7. getFileContent не върна данни. Процесът е прекратен.");
        }
    });

    addCommandForm.addEventListener('submit', async (e) => { /* ... */ });
});
