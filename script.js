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
        const url = `https://api.github.com/repos/${user}/${repo}/contents/${path}`;
        try {
            const response = await fetch(url, {
                headers: {
                    'Authorization': `token ${token}`,
                    'Accept': 'application/vnd.github.v3+json',
                },
            });

            if (!response.ok) {
                throw new Error(`Грешка при зареждане на файла: ${response.statusText}`);
            }

            const data = await response.json();
            const content = atob(data.content);
            return { content, sha: data.sha };
        } catch (error) {
            updateStatus(`Грешка: ${error.message}`, 'error');
            return null;
        }
    }
    
    async function updateFileContent(user, repo, path, token, newContent, sha, commitMessage) {
        const url = `https://api.github.com/repos/${user}/${repo}/contents/${path}`;
        const encodedContent = btoa(unescape(encodeURIComponent(newContent))); // Правилно кодиране за кирилица

        try {
            const response = await fetch(url, {
                method: 'PUT',
                headers: {
                    'Authorization': `token ${token}`,
                    'Accept': 'application/vnd.github.v3+json',
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    message: commitMessage,
                    content: encodedContent,
                    sha: sha,
                }),
            });

            if (!response.ok) {
                const errorData = await response.json();
                throw new Error(`Грешка при запис на файла: ${errorData.message}`);
            }
            
            updateStatus('Файлът е успешно обновен в GitHub!', 'success');
            return await response.json();

        } catch (error) {
            updateStatus(`Грешка: ${error.message}`, 'error');
            return null;
        }
    }

    // --- Парсване и Визуализация ---

    function parseLispContent(content) {
        const commands = [];
        const sections = [];
        const lines = content.split('\n');
        
        const sectionRegex = /;;; START (\w+) KEYS/;
        const commandMapRegex = /\("([^"]+)"\s+\.\s+"([^"]+)"\)/;
        const dclLabelRegex = /: text_part {label = "([^"]*)";}/;


        let commandMap = {};
        let inCommandMap = false;

        // 1. Извличаме всички команди и техните AutoCAD еквиваленти
        lines.forEach(line => {
            if (line.includes(';;; START COMMAND MAP')) inCommandMap = true;
            if (line.includes(';;; END COMMAND MAP')) inCommandMap = false;

            if (inCommandMap) {
                const match = line.match(commandMapRegex);
                if (match) {
                    commandMap[match[1]] = match[2];
                }
            }
        });
        
        // 2. Извличаме описанията от DCL блоковете
        let descriptions = {};
        let currentDclKey = null;
        lines.forEach(line => {
            const keyMatch = line.match(/: button {key = "([^"]+)"/);
            if (keyMatch) {
                currentDclKey = keyMatch[1];
            }
            const labelMatch = line.match(dclLabelRegex);
            if(labelMatch && currentDclKey) {
                descriptions[currentDclKey] = labelMatch[1].trim().replace("  - ", "");
                currentDclKey = null; // Нулираме, за да не присвоим грешно описание
            }
        });


        // 3. Обхождаме секциите и конструираме финалния обект
        lines.forEach(line => {
            const sectionMatch = line.match(sectionRegex);
            if (sectionMatch) {
                const sectionNameRaw = sectionMatch[1];
                const sectionName = sectionNameRaw.charAt(0).toUpperCase() + sectionNameRaw.slice(1).toLowerCase().replace("_keys", "");

                if (!sections.includes(sectionName)) {
                    sections.push(sectionName);
                }

                const keysMatch = line.match(/\(setq \*[\w-]+-keys\* '(\(.*\))\)/);
                if (keysMatch) {
                    const keys = keysMatch[1].match(/"[^"]+"/g).map(k => k.replace(/"/g, ''));
                    
                    keys.forEach(key => {
                        if (commandMap[key] && !commands.some(cmd => cmd.key === key && cmd.section === sectionName)) {
                           commands.push({
                               key: key,
                               label: descriptions[key] || `Изпълнява команда: ${commandMap[key]}`,
                               section: sectionName,
                           });
                        }
                    });
                }
            }
        });
        
        return { commands, sections };
    }


    function displayCommands(commands, sections) {
        const container = document.getElementById('commands-container');
        const sectionSelect = document.getElementById('command-section');
        container.innerHTML = '';
        sectionSelect.innerHTML = '<option value="" disabled selected>Избери секция...</option>';

        const sectionsWithCommands = sections.filter(section => commands.some(cmd => cmd.section === section));

        sectionsWithCommands.forEach(section => {
            const sectionDiv = document.createElement('div');
            sectionDiv.className = 'command-section';
            
            const sectionTitle = document.createElement('h3');
            sectionTitle.textContent = section;
            sectionDiv.appendChild(sectionTitle);

            const sectionOption = document.createElement('option');
            sectionOption.value = section.toUpperCase(); // Изпращаме името с главни букви
            sectionOption.textContent = section;
            sectionSelect.appendChild(sectionOption);
            
            const commandsInSection = commands.filter(cmd => cmd.section === section);
            commandsInSection.forEach(cmd => {
                const entryDiv = document.createElement('div');
                entryDiv.className = 'command-entry';
                
                const copyBtn = document.createElement('button');
                copyBtn.textContent = 'Копирай';
                copyBtn.className = 'copy-btn';
                copyBtn.title = 'Копирай командата в клипборда';
                copyBtn.addEventListener('click', () => {
                    navigator.clipboard.writeText(cmd.key);
                    updateStatus(`Командата "${cmd.key}" е копирана!`, 'success');
                });

                entryDiv.innerHTML = `<code>${cmd.key}</code><p>${cmd.label}</p>`;
                entryDiv.prepend(copyBtn);
                sectionDiv.appendChild(entryDiv);
            });
            container.appendChild(sectionDiv);
        });
    }

    // MAP за преобразуване на имената на секциите
    const sectionToKeyMap = {
        "SITUACIA": "SITUACIA",
        "NAPRECHNI": "NAPRECHNI",
        "NADLAZHNI": "NADLAZHNI",
        "BLOKOVE": "BLOKOVE",
        "LAYOUTS": "LAYOUTS",
        "DRUGI": "DRUGI",
        "CIVIL": "CIVIL",
        "REGISTRI": "REGISTRI"
    };

    function addNewCommandToContent(originalContent, newCommand) {
        let lines = originalContent.split('\n');
        
        // --- 1. Добавяне в *command-map* ---
        const commandMapEndMarker = ';;; END COMMAND MAP';
        let commandMapEndIndex = lines.findIndex(line => line.includes(commandMapEndMarker));
        if (commandMapEndIndex === -1) { updateStatus("Грешка: Не е намерен маркер COMMAND_MAP_END.", 'error'); return originalContent; }
        const newCommandMapEntry = `    ("${newCommand.key}" . "${newCommand.key}")`;
        lines.splice(commandMapEndIndex, 0, newCommandMapEntry);

        // --- 2. Добавяне в списъка с ключове за секцията ---
        const sectionKeyName = sectionToKeyMap[newCommand.section.toUpperCase()];
        if (!sectionKeyName) { updateStatus(`Грешка: Невалидна секция ${newCommand.section}`, 'error'); return originalContent; }
        const sectionKeysEndMarker = `;;; END ${sectionKeyName} KEYS`;
        let sectionKeysEndIndex = lines.findIndex(line => line.includes(sectionKeysEndMarker));
        if (sectionKeysEndIndex === -1) { updateStatus(`Грешка: Не е намерен маркер за ключове: ${sectionKeysEndMarker}`, 'error'); return originalContent; }
        
        let targetLineIndex = sectionKeysEndIndex -1;
        let lineToModify = lines[targetLineIndex];
        let closingParenIndex = lineToModify.lastIndexOf(')');
        let keyToInsert = ` \"${newCommand.key}\"`;
        lines[targetLineIndex] = lineToModify.substring(0, closingParenIndex) + keyToInsert + lineToModify.substring(closingParenIndex);

        // --- 3. Добавяне на DCL ред ---
        const dclSectionMarker = `;;;;;;;; HELP_SECTION: ${newCommand.section.toUpperCase()} ;;;;;;;;;;`;
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
        GITHUB_USER = document.getElementById('githubUser').value.trim();
        GITHUB_REPO = document.getElementById('githubRepo').value.trim();
        FILE_PATH = document.getElementById('filePath').value.trim();
        GITHUB_PAT = document.getElementById('githubPat').value.trim();

        if (!GITHUB_USER || !GITHUB_REPO || !FILE_PATH || !GITHUB_PAT) {
            updateStatus('Моля, попълнете всички полета за настройка.', 'error');
            return;
        }
        
        appContent.classList.remove('hidden');
        document.getElementById('commands-container').innerHTML = '<p class="loading">Зареждане...</p>';
        
        const fileData = await getFileContent(GITHUB_USER, GITHUB_REPO, FILE_PATH, GITHUB_PAT);
        
        if (fileData) {
            const { commands, sections } = parseLispContent(fileData.content);
            displayCommands(commands, sections);
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
            loadBtn.click(); // Симулираме клик, за да презаредим всичко
        }
    });
});
