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
        
        const sectionRegex = /;;;;;;;;;; HELP_SECTION: (.*) ;;;;;;;;;;/;
        const dclKeyRegex = /key = "([^"]+)"/;
        const dclLabelRegex = /label = "  - ([^"]*)"/;

        let descriptions = {};
        let inDclBlock = false;
        let lastKeyFound = null;

        // --- НОВ, ПО-НАДЕЖДЕН МЕТОД ЗА ИЗВЛИЧАНЕ НА ОПИСАНИЯ ---
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i];
            if(line.includes(";;;;;;;; DCL_START ;;;;;;;;")) inDclBlock = true;
            if(line.includes(";;;;;;;; DCL_END ;;;;;;;;;;")) inDclBlock = false;

            if(inDclBlock) {
                const keyMatch = line.match(dclKeyRegex);
                if (keyMatch) {
                    lastKeyFound = keyMatch[1];
                    // Търсим описанието на следващите няколко реда
                    for (let j = i + 1; j < i + 5 && j < lines.length; j++) {
                        const nextLine = lines[j];
                        const labelMatch = nextLine.match(dclLabelRegex);
                        if (labelMatch) {
                            descriptions[lastKeyFound] = labelMatch[1].replace(/\\"/g, '"').trim();
                            break; // Намерихме го, спираме вътрешния цикъл
                        }
                    }
                }
            }
        }
        console.log(`Извлечени ${Object.keys(descriptions).length} описания от DCL`);

        for (let i = 0; i < lines.length; i++) {
            const line = lines[i];
            const sectionMatch = line.match(sectionRegex);
            if (sectionMatch && sectionMatch[1]) {
                const sectionName = sectionMatch[1].trim();
                if (!sections.includes(sectionName)) {
                    console.log(`Намерена нова секция: ${sectionName}`);
                    sections.push(sectionName);
                }
                
                // Намираме съответната C: команда, за да вземем action_tile
                for(let j = i; j < lines.length; j++){
                    if(lines[j].startsWith(`(defun C:${sectionName}`)){
                        let inLogicBlock = false;
                        for(let k = j; k < lines.length; k++){
                            if(lines[k].includes(";;;;;;;; LISP_LOGIC_START ;;;;;;;;;;")) inLogicBlock = true;
                            if(lines[k].includes(";;;;;;;; LISP_LOGIC_END ;;;;;;;;;;")) break;

                            if(inLogicBlock){
                                const actionMatch = lines[k].match(/\(action_tile "([^"]+)"/);
                                if(actionMatch){
                                    const key = actionMatch[1];
                                     if (!commands.some(cmd => cmd.key === key && cmd.section === sectionName)) {
                                        commands.push({
                                            key: key,
                                            label: descriptions[key] || `Команда: ${key}`,
                                            section: sectionName,
                                        });
                                     }
                                }
                            }
                        }
                        break;
                    }
                }
            }
        }
        
        console.log(`Парсването приключи. Общо намерени команди: ${commands.length}, Общо секции: ${sections.length}`);
        return { commands, sections };
    }


    function displayCommands(commands, sections) {
        const container = document.getElementById('commands-container');
        const sectionSelect = document.getElementById('command-section');
        container.innerHTML = '';
        sectionSelect.innerHTML = '<option value="" disabled selected>Избери секция...</option>';
        
        const sectionsWithCommands = sections.filter(section => commands.some(cmd => cmd.section === section));

        sectionsWithCommands.forEach(section => {
            const details = document.createElement('details');
            const summary = document.createElement('summary');
            summary.textContent = section;
            details.appendChild(summary);
            
            const sectionOption = document.createElement('option');
            sectionOption.value = section;
            sectionOption.textContent = section;
            sectionSelect.appendChild(sectionOption);
            
            const commandsInSection = commands.filter(cmd => cmd.section === section);
            commandsInSection.forEach(cmd => {
                const entryDiv = document.createElement('div');
                entryDiv.className = 'command-entry';
                const copyBtn = document.createElement('button');
                copyBtn.textContent = 'Копирай';
                copyBtn.className = 'copy-btn';
                copyBtn.title = `Копирай "${cmd.key}"`;
                copyBtn.addEventListener('click', () => {
                    navigator.clipboard.writeText(cmd.key);
                    updateStatus(`Командата "${cmd.key}" е копирана!`, 'success');
                });
                entryDiv.innerHTML = `<code>${cmd.key}</code><p>${cmd.label}</p>`;
                entryDiv.prepend(copyBtn);
                details.appendChild(entryDiv);
            });
            container.appendChild(details);
        });
    }

    function addNewCommandToContent(originalContent, newCommand) {
        // ... (Тази функция е сложна и ще я добавя, след като потвърдим, че четенето работи)
        // Засега връщаме оригиналното съдържание, за да не правим промени
        updateStatus("Функцията за добавяне все още не е имплементирана.", "error");
        return originalContent;
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
        console.log("НОВ ОПИТ ЗА ЗАРЕЖДАНЕ");
        
        GITHUB_PAT = document.getElementById('githubPat').value.trim();
        if (!GITHUB_PAT) {
            updateStatus('Моля, въведете Personal Access Token (PAT).', 'error');
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
        // ... (Логиката за добавяне ще бъде активирана по-късно)
        updateStatus("Функцията за добавяне все още не е имплементирана.", "error");
    });
});
