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
    
    // --- API Взаимодействие (Коректно е) ---
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
        
        const sectionRegex = /;;; START (.*) KEYS/;
        const commandMapRegex = /\("([^"]+)"\s+\.\s+"([^"]+)"\)/;

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
        
        // !!!!! НОВ, ПО-НАДЕЖДЕН МЕТОД ЗА ИЗВЛИЧАНЕ НА ОПИСАНИЯ !!!!!
        let descriptions = {};
        lines.forEach(line => {
            // Търсим редове, които съдържат едновременно button и text_part
            if (line.includes(': button {') && line.includes(': text_part {')) {
                const keyMatch = line.match(/key = "([^"]+)"/);
                const labelMatch = line.match(/label = "  - ([^"]*)"/);

                if (keyMatch && keyMatch[1] && labelMatch && labelMatch[1]) {
                    const key = keyMatch[1].trim();
                    const desc = labelMatch[1].replace(/\\"/g, '"').trim();
                    descriptions[key] = desc;
                }
            }
        });
        console.log(`Извлечени ${Object.keys(descriptions).length} описания от DCL`);

        for (let i = 0; i < lines.length; i++) {
            const line = lines[i];
            const sectionMatch = line.match(sectionRegex);
            if (sectionMatch && sectionMatch[1]) {
                const sectionNameRaw = sectionMatch[1].trim();
                const sectionName = sectionNameRaw.charAt(0).toUpperCase() + sectionNameRaw.slice(1).toLowerCase();
                if (!sections.includes(sectionName)) {
                    sections.push(sectionName);
                }
                
                const nextLine = lines[i + 1];
                if (nextLine) {
                    const keys = nextLine.match(/"[^"]+"/g);
                    if (keys) {
                        const cleanedKeys = keys.map(k => k.replace(/"/g, ''));
                        cleanedKeys.forEach(key => {
                            if (commandMap[key] && !commands.some(cmd => cmd.key === key && cmd.section === sectionName)) {
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


    const sectionToCyrillic = { "Main": "Раздели", "Situacia": "Ситуация", "Naprechni": "Напречни", "Nadlazhni": "Надлъжни", "Blokove": "Блокове", "Layouts": "Лейаути", "Drugi": "Други", "Civil": "Civil", "Registri": "Регистри" };

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

    const sectionToKeyMap = { "MAIN": "MAIN", "SITUACIA": "SITUACIA", "NAPRECHNI": "NAPRECHNI", "NADLAZHNI": "NADLAZHNI", "BLOKOVE": "BLOKOVE", "LAYOUTS": "LAYOUTS", "DRUGI": "DRUGI", "CIVIL": "CIVIL", "РЕГИСТРИ": "REGISTRI" };

    function addNewCommandToContent(originalContent, newCommand) {
        let lines = originalContent.split('\n');
        
        const commandMapEndMarker = ';;; END COMMAND MAP';
        let commandMapEndIndex = lines.findIndex(line => line.includes(commandMapEndMarker));
        if (commandMapEndIndex === -1) { updateStatus("Грешка: Не е намерен маркер COMMAND_MAP_END.", 'error'); return originalContent; }
        const newCommandMapEntry = `    ("${newCommand.key}" . "${newCommand.key}")`;
        lines.splice(commandMapEndIndex, 0, newCommandMapEntry);

        const sectionKeyName = (sectionToKeyMap[newCommand.section.toUpperCase()] || newCommand.section.toUpperCase());
        const sectionKeysEndMarker = `;;; END ${sectionKeyName} KEYS`;
        let sectionKeysIndex = lines.findIndex(line => line.includes(sectionKeysEndMarker));
        if (sectionKeysIndex === -1) { updateStatus(`Грешка: Не е намерен маркер за ключове: ${sectionKeysEndMarker}`, 'error'); return originalContent; }
        
        let targetLineIndex = sectionKeysIndex;
        let lineToModify = lines[targetLineIndex];
        let closingParenIndex = lineToModify.lastIndexOf(')');
        let keyToInsert = ` \"${newCommand.key}\"`;
        lines[targetLineIndex] = lineToModify.substring(0, closingParenIndex) + keyToInsert + lineToModify.substring(closingParenIndex);

        const dclSectionMarker = `;;;;;;;; HELP_SECTION: ${newCommand.section.toUpperCase()}`;
        let dclSectionIndex = lines.findIndex(line => line.includes(dclSectionMarker));
        if (dclSectionIndex === -1) { updateStatus(`Грешка: Не е намерен маркер за DCL секция: ${dclSectionMarker}`, 'error'); return originalContent; }
        
        const dclEndMarker = ';;;;;;;; DCL_END ;;;;;;;;;;';
        let dclEndIndex = -1;
        for (let i = dclSectionIndex; i < lines.length; i++) {
            if (lines[i].includes(dclEndMarker)) { dclEndIndex = i; break; }
        }
        if (dclEndIndex === -1) { updateStatus(`Грешка: Не е намерен DCL_END маркер за секция: ${newCommand.section}`, 'error'); return originalContent; }

        const newDclRow = `": row { : button {key = \\"${newCommand.key}\\"; label = \\"${newCommand.key}\\"; width = 14; fixed_width = true;} : text_part {label = \\"  - ${newCommand.label}\\";}}"`;
        let dclInsertIndex = dclEndIndex - 1; 
        lines.splice(dclInsertIndex, 0, newDclRow);

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
        console.log("НОВ ОПИТ ЗА ЗАРЕЖДАНЕ555555554");
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

        updateStatus('Обработка... Моля, изчакайте.', 'success');

        const fileData = await getFileContent(GITHUB_USER, GITHUB_REPO, FILE_PATH, GITHUB_PAT);
        if (!fileData) return;

        const newContent = addNewCommandToContent(fileData.content, newCommand);
        if (newContent === fileData.content) return; 

        const commitMessage = `Добавена е нова команда: ${newCommand.key}`;
        const result = await updateFileContent(GITHUB_USER, GITHUB_REPO, FILE_PATH, GITHUB_PAT, newContent, fileData.sha, commitMessage);

        if (result) {
            addCommandForm.reset();
            loadBtn.click();
        }
    });
});
