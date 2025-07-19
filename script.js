document.addEventListener('DOMContentLoaded', () => {
    const loadBtn = document.getElementById('load-commands-btn');
    const appContent = document.getElementById('app-content');
    const addCommandForm = document.getElementById('add-command-form');

    // ========== ХАРДКОДНАТИ ДАННИ ==========
    const GITHUB_USER = "PafApps";
    const GITHUB_REPO = "lisp";
    const FILE_PATH = "HELP_LISP.lsp";
    // =======================================

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
        const url = `https://api.github.com/repos/${user}/${repo}/contents/${path}`;
        const encodedContent = btoa(unescape(encodeURIComponent(newContent)));
        try {
            const response = await fetch(url, {
                method: 'PUT',
                headers: { 'Authorization': `token ${token}`, 'Accept': 'application/vnd.github.v3+json', 'Content-Type': 'application/json' },
                body: JSON.stringify({ message: commitMessage, content: encodedContent, sha: sha }),
            });
            if (!response.ok) { const errorData = await response.json(); throw new Error(`Грешка при запис: ${errorData.message}`); }
            updateStatus('Файлът е успешно обновен!', 'success');
            return await response.json();
        } catch (error) {
            updateStatus(`Грешка: ${error.message}`, 'error');
            return null;
        }
    }

    // --- Парсване и Визуализация ---
    function parseLispContent(content) {
        console.log("parseLispContent: Започвам парсване...");
        const commands = [];
        const sections = [];
        const lines = content.split('\n');
        
        const sectionRegex = /;;; START (.*?) KEYS/;
        const commandMapRegex = /\("([^"]+)"\s+\.\s+"([^"]+)"\)/;
        
        // 1. Извличане на commandMap (ключ -> команда)
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
        console.log(`Намерени ${Object.keys(commandMap).length} команди в *command-map*`);
        
        // 2. Извличане на всички описания от Lisp списъците (command_items)
        let descriptions = {};
        let inItemsList = false;
        const commandItemRegex = /\(\s*"([^"]+)"\s+"[^"]*"\s+"([^"]*)"\)/;
        lines.forEach(line => {
            if (line.includes('(setq command_items') || line.includes('(setq menu_items')) {
                inItemsList = true;
            }
            if (inItemsList && line.trim() === ")") {
                inItemsList = false;
            }
            if (inItemsList) {
                const match = line.match(commandItemRegex);
                if (match) {
                    const key = match[1].trim();
                    const desc = match[2].trim().replace(/^-\s*/, '');
                    if (key && desc && key !== "---") {
                        descriptions[key] = desc;
                    }
                }
            }
        });
        console.log(`Извлечени ${Object.keys(descriptions).length} описания от 'command_items' списъци.`);

        // 3. Обхождане на секциите и конструиране на крайния списък
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i];
            const sectionMatch = line.match(sectionRegex);
            if (sectionMatch && sectionMatch[1]) {
                const sectionNameRaw = sectionMatch[1].trim();
                const sectionName = sectionNameRaw.charAt(0).toUpperCase() + sectionNameRaw.slice(1).toLowerCase();
                if (!sections.includes(sectionName)) {
                    console.log(`Намерена нова секция: ${sectionName}`);
                    sections.push(sectionName);
                }
                
                let keysLine = '';
                for (let j = i; j < lines.length; j++) {
                    if (lines[j].includes(';;; END ' + sectionNameRaw)) break;
                    if (lines[j].trim().startsWith('(setq')) {
                        keysLine = lines[j];
                        break;
                    }
                }

                if (keysLine) {
                    const keys = keysLine.match(/"[^"]+"/g);
                    if (keys) {
                        const cleanedKeys = keys.map(k => k.replace(/"/g, ''));
                        console.log(`Намерени ${cleanedKeys.length} ключа за секция ${sectionName}`);
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
        
        console.log(`Парсването приключи. Общо намерени команди: ${commands.length}, Общо секции: ${sections.length}`);
        return { commands, sections, commandMap };
    }

    const sectionToCyrillic = {
        "Main": "Раздели",
        "Situacia": "Ситуация",
        "Naprechni": "Напречни",
        "Nadlazhni": "Надлъжни",
        "Blokove": "Блокове",
        "Layouts": "Лейаути",
        "Drugi": "Други",
        "Civil": "Civil",
        "Registri": "Регистри"
    };

    function displayCommands(commands, sections, commandMap) {
        const container = document.getElementById('commands-container');
        const sectionSelect = document.getElementById('command-section');
        container.innerHTML = '';
        sectionSelect.innerHTML = '<option value="" disabled selected>Избери секция...</option>';
        
        const sectionsForDropdown = sections.filter(s => s.toLowerCase() !== 'main');
        sectionsForDropdown.forEach(section => {
            const sectionOption = document.createElement('option');
            sectionOption.value = section.toUpperCase();
            sectionOption.textContent = sectionToCyrillic[section] || section;
            sectionSelect.appendChild(sectionOption);
        });

        const sectionsWithCommands = sections.filter(section => commands.some(cmd => cmd.section === section));
        
        sectionsWithCommands.forEach(section => {
            const details = document.createElement('details');
            details.open = true; // Open by default
            const summary = document.createElement('summary');
            summary.textContent = sectionToCyrillic[section] || section;
            details.appendChild(summary);
            
            const commandsInSection = commands.filter(cmd => cmd.section === section);
            commandsInSection.forEach(cmd => {
                const entryDiv = document.createElement('div');
                entryDiv.className = 'command-entry';
                const copyBtn = document.createElement('button');
                copyBtn.textContent = 'Копирай';
                copyBtn.className = 'copy-btn';
                copyBtn.title = `Копирай "${commandMap[cmd.key] || cmd.key}"`;
                copyBtn.addEventListener('click', () => {
                    navigator.clipboard.writeText(commandMap[cmd.key] || cmd.key);
                    updateStatus(`Командата "${commandMap[cmd.key] || cmd.key}" е копирана!`, 'success');
                });
                entryDiv.innerHTML = `<code>${cmd.key}</code><p>${cmd.label}</p>`;
                entryDiv.prepend(copyBtn);
                details.appendChild(entryDiv);
            });
            container.appendChild(details);
        });
    }

    const sectionToKeyMap = { "MAIN": "MAIN", "SITUACIA": "SITUACIA", "NAPRECHNI": "NAPRECHNI", "NADLAZHNI": "NADLAZHNI", "BLOKOVE": "BLOKOVE", "LAYOUTS": "LAYOUTS", "DRUGI": "DRUGI", "CIVIL": "CIVIL", "REGISTRI": "REGISTRI" };
    const keyToLispFuncMap = { "SITUACIA": "СИТУАЦИЯ", "NAPRECHNI": "НАПРЕЧНИ", "NADLAZHNI": "НАДЛЪЖНИ", "BLOKOVE": "БЛОКОВЕ", "LAYOUTS": "ЛЕЙАУТИ", "DRUGI": "ДРУГИ", "CIVIL": "СИВИЛ", "REGISTRI": "РЕГИСТРИ" };

    function addNewCommandToContent(originalContent, newCommand) {
        let lines = originalContent.split('\n');
        
        // 1. Добавяне в *command-map*
        const commandMapEndMarker = ';;; END COMMAND MAP';
        let commandMapEndIndex = lines.findIndex(line => line.includes(commandMapEndMarker));
        if (commandMapEndIndex === -1) { updateStatus("Грешка: Не е намерен маркер ;;; END COMMAND MAP.", 'error'); return originalContent; }
        const newCommandMapEntry = `    ("${newCommand.key}" . "${newCommand.key}")`;
        lines.splice(commandMapEndIndex, 0, newCommandMapEntry);
        console.log(`Добавен запис в *command-map* за '${newCommand.key}'`);

        // 2. Добавяне в списъка с ключове на секцията (ПОДОБРЕНА ЛОГИКА)
        const sectionKeyName = sectionToKeyMap[newCommand.section.toUpperCase()];
        if (!sectionKeyName) {
            updateStatus(`Грешка: Невалидна секция '${newCommand.section}'`, 'error');
            return originalContent;
        }

        const sectionKeysStartMarker = `(setq *${sectionKeyName.toLowerCase()}-command-keys*`;
        let sectionKeysLineIndex = lines.findIndex(line => line.trim().startsWith(sectionKeysStartMarker));
        
        if (sectionKeysLineIndex === -1) {
            updateStatus(`Грешка: Не е намерен списък с ключове за секция: ${sectionKeyName}`, 'error');
            return originalContent;
        }

        let lineToModify = lines[sectionKeysLineIndex];
        const backMarker = '"back"';
        const backIndex = lineToModify.lastIndexOf(backMarker);

        if (backIndex > -1) {
            const beginning = lineToModify.substring(0, backIndex);
            const end = lineToModify.substring(backIndex);
            const keyToInsert = `"${newCommand.key}" `;
            lines[sectionKeysLineIndex] = beginning + keyToInsert + end;
            console.log(`Добавен ключ '${newCommand.key}' в *${sectionKeyName.toLowerCase()}-command-keys*`);
        } else {
           updateStatus(`Грешка: Не може да се намери маркерът "back" за вмъкване на ключ в: ${sectionKeyName}`, 'error');
           return originalContent;
        }

        // 3. Добавяне в `command_items` на съответната Lisp функция
        const lispFuncName = keyToLispFuncMap[newCommand.section.toUpperCase()];
        if (!lispFuncName) { updateStatus(`Грешка: Няма дефинирана Lisp функция за секция '${newCommand.section}'`, 'error'); return originalContent; }
        
        const functionStartMarker = `defun create_dclhelplisp${lispFuncName}`;
        let functionStartIndex = lines.findIndex(line => line.includes(functionStartMarker));
        if (functionStartIndex === -1) { updateStatus(`Грешка: Не е намерена Lisp функция: ${functionStartMarker}`, 'error'); return originalContent; }
        
        let commandItemsEndIndex = -1;
        let inItems = false;
        for (let i = functionStartIndex; i < lines.length; i++) {
            if (lines[i].includes('(setq command_items')) {
                inItems = true;
                continue;
            }
            if (inItems && lines[i].trim() === ')') {
                commandItemsEndIndex = i;
                break;
            }
        }
        
        if (commandItemsEndIndex > -1) {
            // Генерираме форматиран ред, подобен на съществуващите
            const keyForLabel = `   ${newCommand.key}  `;
            const newLispEntry = `      (""${newCommand.key}"" ""${keyForLabel}"" ""  - ${newCommand.label}"")`;
            lines.splice(commandItemsEndIndex, 0, newLispEntry);
            console.log(`Добавен запис в 'command_items' за секция '${lispFuncName}'`);
        } else {
            updateStatus(`Грешка: Не може да се намери краят на 'command_items' за секция '${lispFuncName}'`, 'error');
            return originalContent;
        }

        return lines.join('\n');
    }
    
    function updateStatus(message, type) {
        const statusDiv = document.getElementById('status-message');
        statusDiv.textContent = message;
        statusDiv.className = `status-${type}`;
        statusDiv.style.display = 'block';
        setTimeout(() => {
            statusDiv.textContent = '';
            statusDiv.className = '';
            statusDiv.style.display = 'none';
        }, 5000);
    }
    
    // --- Събития ---
    
    loadBtn.addEventListener('click', async () => {
        console.clear();
        console.log("=====================================");
        console.log("НОВ ОПИТ ЗА ЗАРЕЖДАНЕ");
        console.log("=====================================");
        
        GITHUB_PAT = document.getElementById('githubPat').value.trim();
        if (!GITHUB_PAT) {
            updateStatus('Моля, въведете Personal Access Token (PAT).', 'error');
            return;
        }
        
        console.log(`1. Данни: User=${GITHUB_USER}, Repo=${GITHUB_REPO}, Path=${FILE_PATH}, Token(length)=${GITHUB_PAT.length}`);
        
        appContent.classList.remove('hidden');
        document.getElementById('commands-container').innerHTML = '<p class="loading">Зареждане...</p>';
        
        console.log("2. Извикване на getFileContent...");
        const fileData = await getFileContent(GITHUB_USER, GITHUB_REPO, FILE_PATH, GITHUB_PAT);
        
        if (fileData) {
            console.log("3. Данните са получени. Извикване на parseLispContent...");
            const { commands, sections, commandMap } = parseLispContent(fileData.content);
            
            console.log("4. Парсването приключи. Извикване на displayCommands...");
            displayCommands(commands, sections, commandMap);
            console.log("5. displayCommands приключи.");
        } else {
            console.error("6. getFileContent не върна данни. Процесът е прекратен.");
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

        updateStatus('Обработка... Моля, изчакайте.', 'info');

        const fileData = await getFileContent(GITHUB_USER, GITHUB_REPO, FILE_PATH, GITHUB_PAT);
        if (!fileData) return;

        const newContent = addNewCommandToContent(fileData.content, newCommand);
        if (newContent === fileData.content) {
            console.error("Съдържанието на файла не е променено. Вероятна грешка в логиката за добавяне.");
            updateStatus('Грешка: Командата не можа да бъде добавена.', 'error');
            return;
        }

        const commitMessage = `Добавена е нова команда: ${newCommand.key}`;
        const result = await updateFileContent(GITHUB_USER, GITHUB_REPO, FILE_PATH, GITHUB_PAT, newContent, fileData.sha, commitMessage);

        if (result) {
            addCommandForm.reset();
            // Автоматично презареждане на командите след успешна промяна
            loadBtn.click();
        }
    });
});
