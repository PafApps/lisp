document.addEventListener('DOMContentLoaded', () => {
    const loadBtn = document.getElementById('load-commands-btn');
    const appContent = document.getElementById('app-content');
    const addCommandForm = document.getElementById('add-command-form');
    const deleteCommandForm = document.getElementById('delete-command-form');

    // ========== ХАРДКОДНАТИ ДАННИ ==========
    const GITHUB_USER = "PafApps";
    const GITHUB_REPO = "lisp";
    const FILE_PATH = "HELP_LISP.lsp";
    // =======================================

    let GITHUB_PAT = '';
    let lispData = { commands: [], sections: [], commandMap: {} };
    
    // --- API Взаимодействие (без промяна) ---
    async function getFileContent(user, repo, path, token) {
        try {
            const url = `https://api.github.com/repos/${user}/${repo}/contents/${path}`;
            const response = await fetch(url, { headers: { 'Authorization': `token ${token}`, 'Accept': 'application/vnd.github.v3+json' } });
            if (!response.ok) throw new Error(`Грешка при зареждане: ${response.statusText}`);
            const data = await response.json();
            return { content: decodeURIComponent(escape(atob(data.content))), sha: data.sha };
        } catch (error) {
            updateStatus(`Грешка: ${error.message}`, 'error'); // Глобално съобщение
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
            // Грешката при запис ще се покаже в съответната форма
            const statusElementId = commitMessage.includes('Добавена') ? 'add-status-message' : 'delete-status-message';
            updateStatus(`Грешка при запис: ${error.message}`, 'error', statusElementId);
            return null;
        }
    }

    // --- Парсване (без промяна) ---
    function parseLispContent(content) {
        const sections = [];
        const lines = content.split('\n');
        const sectionRegex = /;;; START (.*?) KEYS/;
        const commandMapRegex = /\("([^"]+)"\s+\.\s+"([^"]+)"\)/;
        let commandMap = {};
        let inCommandMapBlock = false;
        lines.forEach(line => {
            if (line.includes('(setq *command-map*')) inCommandMapBlock = true;
            if (inCommandMapBlock) {
                const match = line.match(commandMapRegex);
                if (match) commandMap[match[1]] = match[2];
                if (line.trim() === ')') inCommandMapBlock = false;
            }
        });
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i];
            const sectionMatch = line.match(sectionRegex);
            if (sectionMatch && sectionMatch[1]) {
                const sectionNameRaw = sectionMatch[1].trim();
                const sectionName = sectionNameRaw.charAt(0).toUpperCase() + sectionNameRaw.slice(1).toLowerCase();
                if (!sections.includes(sectionName)) sections.push(sectionName);
            }
        }
        return { sections, commandMap };
    }
    
    // --- Визуализация (без промяна) ---
    const sectionToCyrillic = { "Main": "Раздели", "Situacia": "Ситуация", "Naprechni": "Напречни", "Nadlazhni": "Надлъжни", "Blokove": "Блокове", "Layouts": "Лейаути", "Drugi": "Други", "Civil": "Civil", "Registri": "Регистри" };
    function displayData({ sections, commandMap }) {
        const commandCountSpan = document.getElementById('command-count');
        commandCountSpan.textContent = Object.keys(commandMap).length;
        const sectionSelect = document.getElementById('command-section');
        sectionSelect.innerHTML = '<option value="" disabled selected>Избери секция...</option>';
        sections.filter(s => s.toLowerCase() !== 'main').forEach(section => {
            const option = document.createElement('option');
            option.value = section.toUpperCase();
            option.textContent = sectionToCyrillic[section] || section;
            sectionSelect.appendChild(option);
        });
    }

    // --- Модификация на съдържание (без промяна в логиката) ---
    const sectionToKeyMap = { "MAIN": "MAIN", "SITUACIA": "SITUACIA", "NAPRECHNI": "NAPRECHNI", "NADLAZHNI": "NADLAZHNI", "BLOKOVE": "BLOKOVE", "LAYOUTS": "LAYOUTS", "DRUGI": "DRUGI", "CIVIL": "CIVIL", "REGISTRI": "REGISTRI" };
    const keyToLispFuncMap = { "SITUACIA": "СИТУАЦИЯ", "NAPRECHNI": "НАПРЕЧНИ", "NADLAZHNI": "НАДЛЪЖНИ", "BLOKOVE": "БЛОКОВЕ", "LAYOUTS": "ЛЕЙАУТИ", "DRUGI": "ДРУГИ", "CIVIL": "СИВИЛ", "REGISTRI": "РЕГИСТРИ" };
    function addNewCommandToContent(originalContent, newCommand) {
        let lines = originalContent.split('\n');
        let commandMapEndIndex = -1, inMap = false;
        for(let i=0; i<lines.length; i++){
            if(lines[i].includes('(setq *command-map*')) inMap = true;
            if(inMap && lines[i].trim() === ')') { commandMapEndIndex = i; break; }
        }
        if (commandMapEndIndex === -1) return null; // Грешка ще се обработи отвън
        lines.splice(commandMapEndIndex, 0, `    ("${newCommand.key}" . "${newCommand.key}")`);
        const sectionKeyName = sectionToKeyMap[newCommand.section.toUpperCase()];
        const sectionKeysStartMarker = `(setq *${sectionKeyName.toLowerCase()}-command-keys*`;
        let sectionKeysLineIndex = lines.findIndex(line => line.trim().startsWith(sectionKeysStartMarker));
        if (sectionKeysLineIndex === -1) return null;
        let lineToModify = lines[sectionKeysLineIndex];
        const backIndex = lineToModify.lastIndexOf('"back"');
        if (backIndex > -1) lines[sectionKeysLineIndex] = lineToModify.substring(0, backIndex) + `"${newCommand.key}" ` + lineToModify.substring(backIndex);
        else return null;
        const lispFuncName = keyToLispFuncMap[newCommand.section.toUpperCase()];
        const functionStartMarker = `defun create_dclhelplisp${lispFuncName}`;
        let functionStartIndex = lines.findIndex(line => line.includes(functionStartMarker));
        if (functionStartIndex === -1) return null;
        let commandItemsEndIndex = -1, inItems = false;
        for (let i = functionStartIndex; i < lines.length; i++) {
            if (lines[i].includes('(setq command_items')) { inItems = true; continue; }
            if (inItems && lines[i].trim() === ')') { commandItemsEndIndex = i; break; }
        }
        if (commandItemsEndIndex > -1) lines.splice(commandItemsEndIndex, 0, `      ("${newCommand.key}" "   ${newCommand.key}  " "  - ${newCommand.label}")`);
        else return null;
        return lines.join('\n');
    }
    function removeCommandFromContent(originalContent, commandKey) {
        let lines = originalContent.split('\n');
        const initialLineCount = lines.length;
        lines = lines.filter(line => !new RegExp(`^\\s*\\("${commandKey}"\\s+\\.\\s+"[^"]+"\\)`).test(line));
        lines = lines.map(line => line.replace(new RegExp(`\\s*"${commandKey}"`), ''));
        lines = lines.filter(line => !new RegExp(`^\\s*\\("${commandKey}"\\s+`).test(line));
        if (lines.join('\n').length === originalContent.length) return null;
        return lines.join('\n');
    }

    /**
     * ПРОМЕНЕНА ФУНКЦИЯ: Показва съобщение в определен елемент.
     * @param {string} message - Текстът на съобщението.
     * @param {'success'|'error'} type - Типът на съобщението.
     * @param {string} [elementId='status-message'] - ID на елемента, в който да се покаже.
     */
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
            summary.innerHTML = `<h2>Обобщение на командите</h2><p>Общо извлечени команди: <span id="command-count">0</span></p>`;
            lispData = parseLispContent(fileData.content);
            displayData(lispData);
        }
    });

    addCommandForm.addEventListener('submit', async (e) => {
        e.preventDefault();
        const statusId = 'add-status-message'; // Дефинираме ID за съобщенията на тази форма
        const newCommand = {
            section: document.getElementById('command-section').value,
            key: document.getElementById('command-key').value.trim(),
            label: document.getElementById('command-label').value.trim(),
        };

        if (!newCommand.section || !newCommand.key || !newCommand.label) {
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

        const commitMessage = `Добавена е нова команда: ${newCommand.key}`;
        const result = await updateFileContent(GITHUB_USER, GITHUB_REPO, FILE_PATH, GITHUB_PAT, newContent, fileData.sha, commitMessage);
        if (result) {
            updateStatus(`Команда '${newCommand.key}' е добавена успешно!`, 'success', statusId);
            addCommandForm.reset();
            loadBtn.click();
        }
    });

    deleteCommandForm.addEventListener('submit', async (e) => {
        e.preventDefault();
        const statusId = 'delete-status-message'; // Дефинираме ID за съобщенията на тази форма
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
            updateStatus(`Ключ '${keyToDelete}' не беше намерен във файла за изтриване.`, 'error', statusId);
            return;
        }

        const commitMessage = `Премахната е команда: ${keyToDelete}`;
        const result = await updateFileContent(GITHUB_USER, GITHUB_REPO, FILE_PATH, GITHUB_PAT, newContent, fileData.sha, commitMessage);
        if (result) {
            updateStatus(`Команда '${keyToDelete}' е изтрита успешно!`, 'success', statusId);
            document.getElementById('delete-command-key').value = '';
            loadBtn.click();
        }
    });
});
