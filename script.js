document.addEventListener('DOMContentLoaded', () => {
    const loadBtn = document.getElementById('load-commands-btn');
    const appContent = document.getElementById('app-content');
    const addCommandForm = document.getElementById('add-command-form');
    const deleteCommandForm = document.getElementById('delete-command-form');

    // ========== КОНФИГУРАЦИЯ ==========
    const GITHUB_USER = "PafApps";
    const GITHUB_REPO = "lisp";
    const FILE_PATH = "HELP_LISP.lsp";

    // Тази конфигурация трябва да е синхронизирана с тази от основния сайт
    const categoryConfig = {
        "СИТУАЦИЯ": { markerName: "SITUACIA" },
        "НАДЛЪЖНИ": { markerName: "NADLZHNI" },
        "НАПРЕЧНИ": { markerName: "NAPRECHNI" },
        "БЛОКОВЕ": { markerName: "BLOKOVE" },
        "ЛЕЙАУТИ": { markerName: "LAYOUTI" },
        "СИВИЛ": { markerName: "CIVIL" },
        "РЕГИСТРИ": { markerName: "REGISTRI" },
        "ДРУГИ": { markerName: "DRUGI" },
    };
    // ===================================

    let GITHUB_PAT = '';
    let lispData = { commandMap: {}, uniqueCommandKeys: [] };

    async function getFileContent(user, repo, path, token) {
        try {
            const url = `https://api.github.com/repos/${user}/${repo}/contents/${path}`;
            const response = await fetch(url, { headers: { 'Authorization': `token ${token}`, 'Accept': 'application/vnd.github.v3.raw' } });
            if (!response.ok) throw new Error(`Грешка при зареждане: ${response.statusText}`);
            const content = await response.text();
            const sha = response.headers.get('ETag').replace(/"/g, ''); // Взимаме SHA от хедърите
            return { content, sha };
        } catch (error) {
            updateStatus(`Мрежова грешка: ${error.message}. Проверете PAT и интернет връзката си.`, 'error');
            return null;
        }
    }
    
    async function updateFileContent(user, repo, path, token, newContent, sha, commitMessage) {
        try {
            const url = `https://api.github.com/repos/${user}/${repo}/contents/${path}`;
            const encodedContent = btoa(unescape(encodeURIComponent(newContent)));
            const response = await fetch(url, {
                method: 'PUT',
                headers: { 'Authorization': `token ${token}`, 'Content-Type': 'application/json' },
                body: JSON.stringify({ message: commitMessage, content: encodedContent, sha: sha }),
            });
            if (!response.ok) { const errorData = await response.json(); throw new Error(`Грешка при запис: ${errorData.message}`); }
            return await response.json();
        } catch (error) {
            const statusElementId = commitMessage.includes('Добавена') ? 'add-status-message' : 'delete-status-message';
            updateStatus(`Грешка при запис: ${error.message}`, 'error', statusElementId);
            return null;
        }
    }

    // --- НОВА ФУНКЦИЯ ЗА ПАРСВАНЕ ---
    function parseNewLispContent(content) {
        const commandMapSectionMatch = content.match(/public static readonly Dictionary<string, string> CommandMap[\s\S]*?{([\s\S]*?)};/);
        const commandMap = {};
        const uniqueCommandKeys = new Set();

        if (commandMapSectionMatch && commandMapSectionMatch[1]) {
            const mapContent = commandMapSectionMatch[1];
            const mapEntryRegex = /{\s*"([^"]+)"\s*,\s*"[^"]*"\s*}/g;
            let entryMatch;
            while ((entryMatch = mapEntryRegex.exec(mapContent)) !== null) {
                const key = entryMatch[1];
                commandMap[key] = key;
                uniqueCommandKeys.add(key);
            }
        }
        return { commandMap, uniqueCommandKeys: Array.from(uniqueCommandKeys) };
    }
    
    function displayData({ uniqueCommandKeys }) {
        document.getElementById('command-count').textContent = uniqueCommandKeys.length;
        const sectionSelect = document.getElementById('command-section');
        sectionSelect.innerHTML = '<option value="" disabled selected>Избери секция...</option>';
        Object.keys(categoryConfig).forEach(cyrillicName => {
            const option = document.createElement('option');
            option.value = cyrillicName;
            option.textContent = cyrillicName;
            sectionSelect.appendChild(option);
        });
    }

    // --- ОБНОВЕНА ФУНКЦИЯ ЗА ДОБАВЯНЕ ---
    function addNewCommandToContent(originalContent, newCommand) {
        const { section, key, label, autocadCommand } = newCommand;
        const categoryInfo = categoryConfig[section];
        if (!categoryInfo) return null;

        const marker = categoryInfo.markerName;
        const endMarkerRegex = new RegExp(`(;;; END DCL ${marker} ITEMS)`);
        
        let content = originalContent;
        
        // 1. Добавяне в списъка с команди за съответната категория
        const endMarkerMatch = content.match(endMarkerRegex);
        if (endMarkerMatch) {
            const endMarkerIndex = endMarkerMatch.index;
            const newMenuItem = `                new MenuItem { Key = "${key}", Label = "${key}", Description = "- ${label}", AutoCADCommand = "${autocadCommand}" },\n`;
            content = content.slice(0, endMarkerIndex) + newMenuItem + content.slice(endMarkerIndex);
        } else {
            updateStatus(`Грешка: Не е намерен маркер за край на секция '${marker}'.`, 'error', 'add-status-message');
            return null;
        }

        // 2. Добавяне в CommandMap
        const commandMapEndMarker = /}\s*;\s*\/\/\s*;;;\s*END COMMAND MAP/;
        const commandMapEndMatch = content.match(commandMapEndMarker);
        if(commandMapEndMatch) {
             const endMapIndex = commandMapEndMatch.index;
             const newMapEntry = `            { "${key}", "${autocadCommand}" },\n`;
             content = content.slice(0, endMapIndex) + newMapEntry + content.slice(endMapIndex);
        } else {
            updateStatus('Грешка: Не е намерен маркер за край на CommandMap.', 'error', 'add-status-message');
            return null;
        }

        return content;
    }

    // --- ОБНОВЕНА ФУНКЦИЯ ЗА ИЗТРИВАНЕ ---
    function removeCommandFromContent(originalContent, commandKey) {
        const originalLength = originalContent.length;
        let content = originalContent;

        // 1. Премахване от списъка с команди (MenuItem)
        const menuItemRegex = new RegExp(`\\s*new MenuItem\\s*{\\s*Key\\s*=\\s*"${commandKey}"[\\s\\S]*?},?\\n?`);
        content = content.replace(menuItemRegex, '');
        
        // 2. Премахване от CommandMap
        const commandMapRegex = new RegExp(`\\s*{\\s*"${commandKey}"\\s*,\\s*"[^"]*"\\s*},?\\n?`);
        content = content.replace(commandMapRegex, '');

        if (content.length >= originalLength) {
            return null; // Връщаме null, ако ключът не е намерен никъде
        }

        return content;
    }

    function updateStatus(message, type, elementId = 'status-message') {
        const statusDiv = document.getElementById(elementId);
        if (!statusDiv) return;
        statusDiv.className = `form-status-message status-${type}`;
        statusDiv.textContent = message;
        statusDiv.style.display = 'block';
        setTimeout(() => { statusDiv.style.display = 'none'; }, 5000);
    }
    
    // --- Събития ---
    loadBtn.addEventListener('click', async () => {
        GITHUB_PAT = document.getElementById('githubPat').value.trim();
        if (!GITHUB_PAT) { updateStatus('Моля, въведете Personal Access Token (PAT).', 'error'); return; }
        appContent.classList.remove('hidden');
        const summary = document.getElementById('command-summary');
        summary.innerHTML = '<p class="loading">Зареждане...</p>';
        
        const fileData = await getFileContent(GITHUB_USER, GITHUB_REPO, FILE_PATH, GITHUB_PAT);
        if (fileData) {
            summary.innerHTML = `<h2>Обобщение на командите</h2><p>Общо уникални команди: <span id="command-count">0</span></p>`;
            lispData = parseNewLispContent(fileData.content);
            displayData(lispData);
        }
    });

    addCommandForm.addEventListener('submit', async (e) => {
        e.preventDefault();
        const statusId = 'add-status-message';
        const newCommand = {
            section: document.getElementById('command-section').value,
            key: document.getElementById('command-key').value.trim(),
            label: document.getElementById('command-label').value.trim(),
            autocadCommand: document.getElementById('autocad-command').value.trim(),
        };

        if (!newCommand.section || !newCommand.key || !newCommand.label || !newCommand.autocadCommand) {
            updateStatus('Моля, попълнете всички полета.', 'error', statusId);
            return;
        }
        if (lispData.commandMap && lispData.commandMap.hasOwnProperty(newCommand.key)) {
            updateStatus(`Ключ '${newCommand.key}' вече съществува!`, 'error', statusId);
            return;
        }

        updateStatus('Добавяне...', 'success', statusId);
        const fileData = await getFileContent(GITHUB_USER, GITHUB_REPO, FILE_PATH, GITHUB_PAT);
        if (!fileData) return;
        
        const newContent = addNewCommandToContent(fileData.content, newCommand);
        if (newContent === null) {
             updateStatus('Възникна вътрешна грешка при генериране на файла.', 'error', statusId);
             return;
        }

        const commitMessage = `[Admin] Добавена е нова команда: ${newCommand.key}`;
        const result = await updateFileContent(GITHUB_USER, GITHUB_REPO, FILE_PATH, GITHUB_PAT, newContent, fileData.sha, commitMessage);
        if (result) {
            updateStatus(`Команда '${newCommand.key}' е добавена успешно!`, 'success', statusId);
            addCommandForm.reset();
            loadBtn.click();
        }
    });

    deleteCommandForm.addEventListener('submit', async (e) => {
        e.preventDefault();
        const statusId = 'delete-status-message';
        const keyToDelete = document.getElementById('delete-command-key').value.trim();

        if (!keyToDelete) {
            updateStatus('Моля, въведете ключ за изтриване.', 'error', statusId);
            return;
        }
        if (!lispData.commandMap.hasOwnProperty(keyToDelete)) {
            updateStatus(`Команда с ключ '${keyToDelete}' не съществува!`, 'error', statusId);
            return;
        }
        if (!confirm(`Сигурни ли сте, че искате да изтриете '${keyToDelete}'?`)) return;

        updateStatus('Изтриване...', 'success', statusId);
        const fileData = await getFileContent(GITHUB_USER, GITHUB_REPO, FILE_PATH, GITHUB_PAT);
        if (!fileData) return;

        const newContent = removeCommandFromContent(fileData.content, keyToDelete);
        if (newContent === null) {
            updateStatus(`Ключ '${keyToDelete}' не беше намерен във файла за изтриване.`, 'error', 'delete-status-message');
            return;
        }

        const commitMessage = `[Admin] Премахната е команда: ${keyToDelete}`;
        const result = await updateFileContent(GITHUB_USER, GITHUB_REPO, FILE_PATH, GITHUB_PAT, newContent, fileData.sha, commitMessage);
        if (result) {
            updateStatus(`Команда '${keyToDelete}' е изтрита успешно!`, 'success', statusId);
            document.getElementById('delete-command-key').value = '';
            loadBtn.click();
        }
    });
});
