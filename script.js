document.addEventListener('DOMContentLoaded', () => {
    const loadBtn = document.getElementById('load-commands-btn');
    const appContent = document.getElementById('app-content');
    const addCommandForm = document.getElementById('add-command-form');
    const deleteCommandForm = document.getElementById('delete-command-form');

    const GITHUB_USER = "PafApps";
    const GITHUB_REPO = "lisp";
    const FILE_PATH = "HELP_LISP.lsp";

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

    let GITHUB_PAT = '';
    let lispData = { commandMap: {}, sha: '' };

    async function getFileContent(user, repo, path, token) {
        try {
            const url = `https://api.github.com/repos/${user}/${repo}/contents/${path}`;
            const response = await fetch(url, {
                headers: { 'Authorization': `token ${token}`, 'Accept': 'application/vnd.github.v3+json' }
            });
            if (!response.ok) {
                const errorData = await response.json();
                throw new Error(`Грешка при зареждане: ${response.statusText} - ${errorData.message}`);
            }
            const data = await response.json();
            const decodedContent = decodeURIComponent(atob(data.content).split('').map(c => '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2)).join(''));
            return { content: decodedContent, sha: data.sha };
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

    function parseLispContent(content) {
        const commandMap = {};
        const commandMapSectionMatch = content.match(/;;; START COMMAND MAP([\s\S]*?);;; END COMMAND MAP/);
        
        if (commandMapSectionMatch && commandMapSectionMatch[1]) {
            const mapContent = commandMapSectionMatch[1];
            const mapEntryRegex = /{\s*"([^"]+)"\s*,\s*"[^"]*"\s*}/g;
            let entryMatch;
            while ((entryMatch = mapEntryRegex.exec(mapContent)) !== null) {
                commandMap[entryMatch[1]] = true;
            }
        } else {
             updateStatus('Грешка: Не може да бъде намерен "COMMAND MAP" маркер в съдържанието на файла.', 'error');
        }
        return { commandMap };
    }
    
    function displayData(data) {
        const commandCount = Object.keys(data.commandMap).length;
        document.getElementById('command-count').textContent = commandCount;
        if (commandCount === 0 && GITHUB_PAT) {
            updateStatus('Предупреждение: Не са намерени команди. Файлът може да е празен или с грешна структура.', 'error');
        }
        const sectionSelect = document.getElementById('command-section');
        sectionSelect.innerHTML = '<option value="" disabled selected>Избери секция...</option>';
        Object.keys(categoryConfig).forEach(cyrillicName => {
            const option = document.createElement('option');
            option.value = cyrillicName;
            option.textContent = cyrillicName;
            sectionSelect.appendChild(option);
        });
    }

    function addNewCommandToContent(originalContent, newCommand) {
        const { section, key, label } = newCommand;
        const autocadCommand = key;
        const categoryInfo = categoryConfig[section];
        if (!categoryInfo) {
            updateStatus('Избраната секция не е валидна.', 'error', 'add-status-message');
            return null;
        }

        let lines = originalContent.split('\n');
        
        // 1. Добавяне на MenuItem
        const marker = categoryInfo.markerName;
        const endMarkerIndex = lines.findIndex(line => line.includes(`;;; END DCL ${marker} ITEMS`));
        if (endMarkerIndex !== -1) {
            const newMenuItem = `                new MenuItem { Key = "${key}", Label = "${key}", Description = "- ${label}", AutoCADCommand = "${autocadCommand}" }`;
            let previousLineIndex = endMarkerIndex - 1;
            while(previousLineIndex > 0 && lines[previousLineIndex].trim() === '') {
                previousLineIndex--;
            }
            if (lines[previousLineIndex] && lines[previousLineIndex].trim().endsWith('}')) {
                lines[previousLineIndex] += ',';
            }
            lines.splice(endMarkerIndex, 0, newMenuItem);
        } else {
            updateStatus(`Грешка: Не е намерен маркер за край на секция '${marker}'.`, 'error', 'add-status-message');
            return null;
        }

        // 2. Добавяне в CommandMap
        const commandMapEndIndex = lines.findIndex(line => line.includes(';;; END COMMAND MAP'));
        if(commandMapEndIndex !== -1) {
            const newMapEntry = `            { "${key}", "${autocadCommand}" }`;
             let previousLineIndex = commandMapEndIndex - 1;
             while(previousLineIndex > 0 && lines[previousLineIndex].trim() === '') {
                previousLineIndex--;
            }
            if (lines[previousLineIndex] && lines[previousLineIndex].trim().endsWith('}')) {
                lines[previousLineIndex] += ',';
            }
             lines.splice(commandMapEndIndex, 0, newMapEntry);
        } else {
            updateStatus('Грешка: Не е намерен маркер за край на CommandMap.', 'error', 'add-status-message');
            return null;
        }

        return lines.join('\n');
    }

    // --- БЕЗОПАСНА ФУНКЦИЯ ЗА ИЗТРИВАНЕ ---
    function removeCommandFromContent(originalContent, commandKey) {
        let lines = originalContent.split('\n');
        let linesChanged = false;

        // Стъпка 1: Намираме и премахваме реда с MenuItem
        const menuItemLineIndex = lines.findIndex(line =>
            line.includes('new MenuItem') && line.includes(`Key = "${commandKey}"`)
        );

        if (menuItemLineIndex !== -1) {
            const lineToRemove = lines[menuItemLineIndex];
            if (!lineToRemove.trim().endsWith(',')) {
                 let previousLineIndex = menuItemLineIndex - 1;
                 while(previousLineIndex > 0 && lines[previousLineIndex].trim() === '') {
                     previousLineIndex--;
                 }
                 if (lines[previousLineIndex] && lines[previousLineIndex].trim().endsWith('},')) {
                    lines[previousLineIndex] = lines[previousLineIndex].trim().slice(0, -1);
                 }
            }
            lines.splice(menuItemLineIndex, 1);
            linesChanged = true;
        }

        // Стъпка 2: Намираме и премахваме реда от CommandMap
        const commandMapLineIndex = lines.findIndex(line =>
            line.trim().startsWith(`{ "${commandKey}"`)
        );

        if (commandMapLineIndex !== -1) {
            const lineToRemove = lines[commandMapLineIndex];
             if (!lineToRemove.trim().endsWith(',')) {
                 let previousLineIndex = commandMapLineIndex - 1;
                 while(previousLineIndex > 0 && lines[previousLineIndex].trim() === '') {
                     previousLineIndex--;
                 }
                 if (lines[previousLineIndex] && lines[previousLineIndex].trim().endsWith('},')) {
                    lines[previousLineIndex] = lines[previousLineIndex].trim().slice(0, -1);
                 }
            }
            lines.splice(commandMapLineIndex, 1);
            linesChanged = true;
        }

        if (!linesChanged) {
            return null;
        }

        return lines.join('\n');
    }

    function updateStatus(message, type, elementId = 'status-message') {
        const statusDiv = document.getElementById(elementId);
        if (!statusDiv) return;
        statusDiv.className = `form-status-message status-${type}`;
        statusDiv.textContent = message;
        statusDiv.style.display = 'block';
        if (elementId === 'status-message') {
            setTimeout(() => { statusDiv.style.display = 'none'; }, 5000);
        }
    }
    
    function clearFormStatus() {
        document.getElementById('add-status-message').style.display = 'none';
        document.getElementById('delete-status-message').style.display = 'none';
    }

    loadBtn.addEventListener('click', async () => {
        GITHUB_PAT = document.getElementById('githubPat').value.trim();
        if (!GITHUB_PAT) {
            updateStatus('Моля, въведете Personal Access Token (PAT).', 'error');
            return;
        }
        
        updateStatus('Зареждане...', 'success');
        appContent.classList.add('hidden');
        
        const fileData = await getFileContent(GITHUB_USER, GITHUB_REPO, FILE_PATH, GITHUB_PAT);
        if (fileData) {
            updateStatus('Файлът е зареден успешно.', 'success');
            lispData = { ...parseLispContent(fileData.content), sha: fileData.sha };
            displayData(lispData);
            appContent.classList.remove('hidden');
        }
    });

    addCommandForm.addEventListener('submit', async (e) => {
        e.preventDefault();
        clearFormStatus();
        const statusId = 'add-status-message';
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
        if (newContent === null) return; 

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
        clearFormStatus();
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
