document.addEventListener('DOMContentLoaded', () => {
    const loadBtn = document.getElementById('load-commands-btn');
    const appContent = document.getElementById('app-content');
    const addCommandForm = document.getElementById('add-command-form');

    let GITHUB_USER = '';
    let GITHUB_REPO = '';
    let FILE_PATH = '';
    let GITHUB_PAT = '';
    
    // --- API Взаимодействие (Коректно е, остава същото) ---
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
            updateStatus('Файлът е успешно обновен!', 'success');
            return await response.json();
        } catch (error) {
            updateStatus(`Грешка: ${error.message}`, 'error');
            return null;
        }
    }

    // --- ПАРСЕР С КОРЕКЦИЯ ---
    function parseLispContent(content) {
        const commands = [];
        const sections = [];
        const lines = content.split('\n');
        
        const sectionRegex = /;;; START (\w+) KEYS/;
        const commandMapRegex = /\("([^"]+)"\s+\.\s+"([^"]+)"\)/;
        const dclLabelRegex = /label = "([^"]+)"/;
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
        
        let descriptions = {};
        let currentDclKey = null;
        lines.forEach(line => {
            if (line.includes(': button {')) {
                const keyMatch = line.match(dclKeyRegex);
                if (keyMatch) currentDclKey = keyMatch[1];
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

        lines.forEach(line => {
            const sectionMatch = line.match(sectionRegex);
            if (sectionMatch && sectionMatch[1]) {
                const sectionKeyRaw = sectionMatch[1];
                const sectionName = sectionKeyRaw.charAt(0).toUpperCase() + sectionKeyRaw.slice(1).toLowerCase();
                if (!sections.includes(sectionName)) sections.push(sectionName);

                // !!!!! КОРЕКЦИЯ ТУК !!!!!
                // Този регулярен израз е по-прост и по-надежден
                const keysMatch = line.match(/'\((.*)\)/);
                
                if (keysMatch && keysMatch[1]) {
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

    // ... (displayCommands остава същата)
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
            sectionOption.value = section.toUpperCase(); 
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

    const sectionToKeyMap = { "СИТУАЦИЯ": "SITUACIA", "НАПРЕЧНИ": "NAPRECHNI", "НАДЛЪЖНИ": "NADLAZHNI", "БЛОКОВЕ": "BLOKOVE", "ЛЕЙАУТИ": "LAYOUTS", "ДРУГИ": "DRUGI", "СИВИЛ": "CIVIL", "РЕГИСТРИ": "REGISTRI" };

    function addNewCommandToContent(originalContent, newCommand) {
        // ... (Тази функция е коректна и остава същата)
        let lines = originalContent.split('\n');
        
        const commandMapEndMarker = ';;; END COMMAND MAP';
        let commandMapEndIndex = lines.findIndex(line => line.includes(commandMapEndMarker));
        const newCommandMapEntry = `    ("${newCommand.key}" . "${newCommand.key}")`;
        lines.splice(commandMapEndIndex, 0, newCommandMapEntry);

        const sectionKeyName = (sectionToKeyMap[newCommand.section.toUpperCase()] || newCommand.section.toUpperCase());
        const sectionKeysEndMarker = `;;; END ${sectionKeyName} KEYS`;
        let sectionKeysEndIndex = lines.findIndex(line => line.includes(sectionKeysEndMarker));
        
        let targetLineIndex = sectionKeysEndIndex -1;
        let lineToModify = lines[targetLineIndex];
        let closingParenIndex = lineToModify.lastIndexOf(')');
        let keyToInsert = ` \"${newCommand.key}\"`;
        lines[targetLineIndex] = lineToModify.substring(0, closingParenIndex) + keyToInsert + lineToModify.substring(closingParenIndex);

        const dclSectionMarker = `;;;;;;;; HELP_SECTION: ${newCommand.section.toUpperCase()}`;
        let dclSectionIndex = lines.findIndex(line => line.includes(dclSectionMarker));
        const dclEndMarker = ';;;;;;;; DCL_END ;;;;;;;;;;';
        let dclEndIndex = -1;
        for (let i = dclSectionIndex; i < lines.length; i++) {
            if (lines[i].includes(dclEndMarker)) { dclEndIndex = i; break; }
        }
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
    
    // --- Събития (остават същите) ---
    loadBtn.addEventListener('click', async () => { /* ... */ });
    addCommandForm.addEventListener('submit', async (e) => { /* ... */ });
});
