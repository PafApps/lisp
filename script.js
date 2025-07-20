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
    // Глобален обект за съхранение на парсираните данни
    let lispData = {
        commands: [],
        sections: [],
        commandMap: {}
    };
    
    // --- API Взаимодействие ---
    async function getFileContent(user, repo, path, token) {
        const url = `https://api.github.com/repos/${user}/${repo}/contents/${path}`;
        try {
            const response = await fetch(url, { headers: { 'Authorization': `token ${token}`, 'Accept': 'application/vnd.github.v3+json' } });
            if (!response.ok) throw new Error(`Грешка при зареждане: ${response.statusText}`);
            const data = await response.json();
            const decodedContent = decodeURIComponent(escape(atob(data.content)));
            return { content: decodedContent, sha: data.sha };
        } catch (error) {
            updateStatus(`Грешка: ${error.message}`, 'error');
            return null;
        }
    }
    
    async function updateFileContent(user, repo, path, token, newContent, sha, commitMessage) {
        const url = `https://api.github.com/repos/${user}/${repo}/contents/${path}`;
        const encodedContent = btoa(unescape(encodeURIComponent(newContent)));
        try {
            const response = await fetch(url, {
                method: 'PUT',
                headers: { 'Authorization': `token ${token}`, 'Accept': 'application/vnd.github.v3+json', 'Content-Type': 'application/json' },
                body: JSON.stringify({ message: commitMessage, content: encodedContent, sha: sha }),
            });
            if (!response.ok) { const errorData = await response.json(); throw new Error(`Грешка при запис: ${errorData.message}`); }
            return await response.json();
        } catch (error) {
            updateStatus(`Грешка при запис: ${error.message}`, 'error');
            return null;
        }
    }

    // --- Парсване и Визуализация ---
    function parseLispContent(content) {
        const commands = [];
        const sections = [];
        const lines = content.split('\n');
        const sectionRegex = /;;; START (.*?) KEYS/;
        // Променяме регулярния израз да търси дефиницията на *command-map*
        const commandMapRegex = /\("([^"]+)"\s+\.\s+"([^"]+)"\)/;
        
        let commandMap = {};
        // Търсим в целия файл за *command-map*
        let inCommandMapBlock = false;
        lines.forEach(line => {
            if (line.includes('(setq *command-map*')) {
                inCommandMapBlock = true;
            }
            if (inCommandMapBlock) {
                const match = line.match(commandMapRegex);
                if (match) {
                    commandMap[match[1]] = match[2];
                }
                // Проверяваме за затваряща скоба на нов ред
                if (line.trim() === ')') {
                    inCommandMapBlock = false;
                }
            }
        });
        
        let descriptions = {};
        let inItemsList = false;
        const commandItemRegex = /\(\s*"([^"]+)"\s+"[^"]*"\s+"([^"]*)"\)/;
        lines.forEach(line => {
            if (line.includes('(setq command_items') || line.includes('(setq menu_items')) inItemsList = true;
            if (inItemsList && line.trim() === ")") inItemsList = false;
            if (inItemsList) {
                const match = line.match(commandItemRegex);
                if (match) {
                    const key = match[1].trim();
                    const desc = match[2].trim().replace(/^-\s*/, '');
                    if (key && desc && key !== "---") descriptions[key] = desc;
                }
            }
        });

        for (let i = 0; i < lines.length; i++) {
            const line = lines[i];
            const sectionMatch = line.match(sectionRegex);
            if (sectionMatch && sectionMatch[1]) {
                const sectionNameRaw = sectionMatch[1].trim();
                const sectionName = sectionNameRaw.charAt(0).toUpperCase() + sectionNameRaw.slice(1).toLowerCase();
                if (!sections.includes(sectionName)) sections.push(sectionName);
                let keysLine = '';
                for (let j = i; j < lines.length; j++) {
                    if (lines[j].includes(';;; END ' + sectionNameRaw)) break;
                    if (lines[j].trim().startsWith('(setq')) { keysLine = lines[j]; break; }
                }
                if (keysLine) {
                    const keys = keysLine.match(/"[^"]+"/g);
                    if (keys) {
                        const cleanedKeys = keys.map(k => k.replace(/"/g, ''));
                        cleanedKeys.forEach(key => {
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
            }
        }
        return { commands, sections, commandMap };
    }

    const sectionToCyrillic = { "Main": "Раздели", "Situacia": "Ситуация", "Naprechni": "Напречни", "Nadlazhni": "Надлъжни", "Blokove": "Блокове", "Layouts": "Лейаути", "Drugi": "Други", "Civil": "Civil", "Registri": "Регистри" };

    function displayData(data) {
        const { sections, commandMap } = data;
        const commandCountSpan = document.getElementById('command-count');
        const sectionSelect = document.getElementById('command-section');

        // Актуализирай брояча на командите спрямо броя ключове в commandMap
        commandCountSpan.textContent = Object.keys(commandMap).length;
        
        // Попълни падащото меню със секциите
        sectionSelect.innerHTML = '<option value="" disabled selected>Избери секция...</option>';
        const sectionsForDropdown = sections.filter(s => s.toLowerCase() !== 'main');
        sectionsForDropdown.forEach(section => {
            const sectionOption = document.createElement('option');
            sectionOption.value = section.toUpperCase();
            sectionOption.textContent = sectionToCyrillic[section] || section;
            sectionSelect.appendChild(sectionOption);
        });
    }

    const sectionToKeyMap = { "MAIN": "MAIN", "SITUACIA": "SITUACIA", "NAPRECHNI": "NAPRECHNI", "NADLAZHNI": "NADLAZHNI", "BLOKOVE": "BLOKOVE", "LAYOUTS": "LAYOUTS", "DRUGI": "DRUGI", "CIVIL": "CIVIL", "REGISTRI": "REGISTRI" };
    const keyToLispFuncMap = { "SITUACIA": "СИТУАЦИЯ", "NAPRECHNI": "НАПРЕЧНИ", "NADLAZHNI": "НАДЛЪЖНИ", "BLOKOVE": "БЛОКОВЕ", "LAYOUTS": "ЛЕЙАУТИ", "DRUGI": "ДРУГИ", "CIVIL": "СИВИЛ", "REGISTRI": "РЕГИСТРИ" };

    function addNewCommandToContent(originalContent, newCommand) {
        let lines = originalContent.split('\n');
        // Намиране на края на *command-map* за добавяне на нова команда
        let commandMapEndIndex = -1;
        let inMap = false;
        for(let i=0; i<lines.length; i++){
            if(lines[i].includes('(setq *command-map*')) inMap = true;
            if(inMap && lines[i].trim() === ')') {
                commandMapEndIndex = i;
                break;
            }
        }
        if (commandMapEndIndex === -1) { updateStatus("Грешка: Не е намерен край на *command-map*.", 'error'); return originalContent; }
        const newCommandMapEntry = `    ("${newCommand.key}" . "${newCommand.key}")`;
        lines.splice(commandMapEndIndex, 0, newCommandMapEntry);

        const sectionKeyName = sectionToKeyMap[newCommand.section.toUpperCase()];
        if (!sectionKeyName) { updateStatus(`Грешка: Невалидна секция '${newCommand.section}'`, 'error'); return originalContent; }
        const sectionKeysStartMarker = `(setq *${sectionKeyName.toLowerCase()}-command-keys*`;
        let sectionKeysLineIndex = lines.findIndex(line => line.trim().startsWith(sectionKeysStartMarker));
        if (sectionKeysLineIndex === -1) { updateStatus(`Грешка: Не е намерен списък с ключове за секция: ${sectionKeyName}`, 'error'); return originalContent; }
        let lineToModify = lines[sectionKeysLineIndex];
        const backMarker = '"back"';
        const backIndex = lineToModify.lastIndexOf(backMarker);
        if (backIndex > -1) {
            lines[sectionKeysLineIndex] = lineToModify.substring(0, backIndex) + `"${newCommand.key}" ` + lineToModify.substring(backIndex);
        } else {
           updateStatus(`Грешка: Не може да се намери маркерът "back" за вмъкване на ключ в: ${sectionKeyName}`, 'error');
           return originalContent;
        }

        const lispFuncName = keyToLispFuncMap[newCommand.section.toUpperCase()];
        if (!lispFuncName) { updateStatus(`Грешка: Няма дефинирана Lisp функция за секция '${newCommand.section}'`, 'error'); return originalContent; }
        const functionStartMarker = `defun create_dclhelplisp${lispFuncName}`;
        let functionStartIndex = lines.findIndex(line => line.includes(functionStartMarker));
        if (functionStartIndex === -1) { updateStatus(`Грешка: Не е намерена Lisp функция: ${functionStartMarker}`, 'error'); return originalContent; }
        let commandItemsEndIndex = -1;
        let inItems = false;
        for (let i = functionStartIndex; i < lines.length; i++) {
            if (lines[i].includes('(setq command_items')) { inItems = true; continue; }
            if (inItems && lines[i].trim() === ')') { commandItemsEndIndex = i; break; }
        }
        if (commandItemsEndIndex > -1) {
            const newLispEntry = `      ("${newCommand.key}" "   ${newCommand.key}  " "  - ${newCommand.label}")`;
            lines.splice(commandItemsEndIndex, 0, newLispEntry);
        } else {
            updateStatus(`Грешка: Не може да се намери краят на 'command_items' за секция '${lispFuncName}'`, 'error');
            return originalContent;
        }
        return lines.join('\n');
    }

    function removeCommandFromContent(originalContent, commandKey) {
        let lines = originalContent.split('\n');
        const initialLineCount = lines.length;
        const commandMapRegex = new RegExp(`^\\s*\\("${commandKey}"\\s+\\.\\s+"[^"]+"\\)`);
        lines = lines.filter(line => !commandMapRegex.test(line));
        const keyListRegex = new RegExp(`\\s*"${commandKey}"`);
        lines = lines.map(line => line.trim().startsWith('(setq *') && line.includes(`"${commandKey}"`) ? line.replace(keyListRegex, '') : line);
        const commandItemRegex = new RegExp(`^\\s*\\("${commandKey}"\\s+`);
        lines = lines.filter(line => !commandItemRegex.test(line));
        if (lines.length === initialLineCount) {
             updateStatus(`Команда с ключ '${commandKey}' не беше намерена за изтриване.`, 'error');
             return null;
        }
        return lines.join('\n');
    }
    
    function updateStatus(message, type) {
        const statusDiv = document.getElementById('status-message');
        statusDiv.textContent = message;
        statusDiv.className = `status-${type}`;
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
            lispData = parseLispContent(fileData.content); // Запазваме данните глобално
            displayData(lispData); // Подаваме целия обект
        }
    });

    addCommandForm.addEventListener('submit', async (e) => {
        e.preventDefault();
        const newCommand = {
            section: document.getElementById('command-section').value,
            key: document.getElementById('command-key').value.trim(),
            label: document.getElementById('command-label').value.trim(),
        };
        if (!newCommand.section || !newCommand.key || !newCommand.label) {
            updateStatus('Моля, попълнете всички полета за новата команда.', 'error');
            return;
        }
        
        // ПРОВЕРКА ЗА ДУБЛИРАНЕ
        if (lispData.commandMap && lispData.commandMap.hasOwnProperty(newCommand.key)) {
            updateStatus(`Грешка: Команда с ключ '${newCommand.key}' вече съществува. Моля, изберете друго име.`, 'error');
            return;
        }

        updateStatus('Обработка... Моля, изчакайте.', 'success');
        const fileData = await getFileContent(GITHUB_USER, GITHUB_REPO, FILE_PATH, GITHUB_PAT);
        if (!fileData) return;
        const newContent = addNewCommandToContent(fileData.content, newCommand);
        if (newContent === fileData.content) return; 
        const commitMessage = `Добавена е нова команда: ${newCommand.key}`;
        const result = await updateFileContent(GITHUB_USER, GITHUB_REPO, FILE_PATH, GITHUB_PAT, newContent, fileData.sha, commitMessage);
        if (result) {
            updateStatus(`Командата '${newCommand.key}' е успешно добавена!`, 'success');
            addCommandForm.reset();
            loadBtn.click();
        }
    });

    deleteCommandForm.addEventListener('submit', async (e) => {
        e.preventDefault();
        const keyToDelete = document.getElementById('delete-command-key').value.trim();
        if (!keyToDelete) {
            updateStatus('Моля, въведете ключ на команда за изтриване.', 'error');
            return;
        }
        if (!confirm(`Сигурни ли сте, че искате да изтриете командата "${keyToDelete}"? Тази операция е необратима!`)) {
            return;
        }
        updateStatus('Изтриване на команда... Моля, изчакайте.', 'success');
        const fileData = await getFileContent(GITHUB_USER, GITHUB_REPO, FILE_PATH, GITHUB_PAT);
        if (!fileData) return;
        const newContent = removeCommandFromContent(fileData.content, keyToDelete);
        if (newContent === null) return;
        const commitMessage = `Премахната е команда: ${keyToDelete}`;
        const result = await updateFileContent(GITHUB_USER, GITHUB_REPO, FILE_PATH, GITHUB_PAT, newContent, fileData.sha, commitMessage);
        if (result) {
            updateStatus(`Командата '${keyToDelete}' е успешно изтрита!`, 'success');
            document.getElementById('delete-command-key').value = '';
            loadBtn.click();
        }
    });
});
