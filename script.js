document.addEventListener('DOMContentLoaded', () => {
    const loadBtn = document.getElementById('load-commands-btn');
    const appContent = document.getElementById('app-content');
    const addCommandForm = document.getElementById('add-command-form');

    let GITHUB_USER = '';
    let GITHUB_REPO = '';
    let FILE_PATH = '';
    let GITHUB_PAT = '';
    
    // --- API Взаимодействие (Без промяна тук) ---

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
        const encodedContent = btoa(newContent);

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


    // --- Парсване и Визуализация (Без промяна тук) ---

    function parseLispContent(content) {
        const commands = [];
        const sections = [];
        const lines = content.split('\n');
        let currentSection = 'Общи';

        const sectionRegex = /;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  HELP (.*)     ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;/;
        const keyRegex = /key = "(.*)";/;
        const labelRegex = /label = "(.*)";/;

        lines.forEach(line => {
            const sectionMatch = line.match(sectionRegex);
            if (sectionMatch) {
                currentSection = sectionMatch[1].trim();
                if (!sections.includes(currentSection)) {
                    sections.push(currentSection);
                }
            }

            const keyMatch = line.trim().match(keyRegex);
            if (keyMatch) {
                let label = '';
                const nextLines = lines.slice(lines.indexOf(line) + 1, lines.indexOf(line) + 5);
                for(const nextLine of nextLines){
                    const labelMatch = nextLine.trim().match(labelRegex);
                    if(labelMatch){
                        label = labelMatch[1].replace(/\\"/g, '"');
                        break;
                    }
                }
                
                commands.push({
                    key: keyMatch[1].trim(),
                    label: label || "Няма описание",
                    section: currentSection
                });
            }
        });
        return { commands, sections };
    }

    function displayCommands(commands, sections) {
        const container = document.getElementById('commands-container');
        const sectionSelect = document.getElementById('command-section');
        container.innerHTML = '';
        sectionSelect.innerHTML = '<option value="" disabled selected>Избери секция...</option>';

        sections.forEach(section => {
            const sectionDiv = document.createElement('div');
            sectionDiv.className = 'command-section';
            
            const sectionTitle = document.createElement('h3');
            sectionTitle.textContent = section;
            sectionDiv.appendChild(sectionTitle);

            const sectionOption = document.createElement('option');
            sectionOption.value = section;
            sectionOption.textContent = section;
            sectionSelect.appendChild(sectionOption);

            const commandsInSection = commands.filter(cmd => cmd.section === section);
            if (commandsInSection.length > 0) {
                commandsInSection.forEach(cmd => {
                    const entryDiv = document.createElement('div');
                    entryDiv.className = 'command-entry';
                    entryDiv.innerHTML = `<code>${cmd.key}</code><p>${cmd.label}</p>`;
                    sectionDiv.appendChild(entryDiv);
                });
            } else {
                 sectionDiv.innerHTML += '<p>Няма команди в тази секция.</p>';
            }
            container.appendChild(sectionDiv);
        });
    }

    function addNewCommandToContent(originalContent, newCommand) {
        const sectionMarker = `;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  HELP ${newCommand.section}`;
        const lines = originalContent.split('\n');
        
        let sectionStartIndex = lines.findIndex(line => line.includes(sectionMarker));
        if (sectionStartIndex === -1) {
            updateStatus(`Не е намерена секция: ${newCommand.section}`, 'error');
            return originalContent;
        }

        let sectionEndIndex = lines.findIndex((line, index) => index > sectionStartIndex && line.trim() === '}');
        if(sectionEndIndex === -1){
            updateStatus(`Не може да се намери края на DCL за секция: ${newCommand.section}`, 'error');
            return originalContent;
        }
        
        const newCommandDCL = `
"/////////////////////////////////////////////////////////////"
"/////////////////////////// ${newCommand.key}.lsp //////////////////////////"
"///////////////////////////////////////////////////////////// "
": row {"
"fixed_width = true;"
"alignment = left;"
"      : button {"
"width = 14;"
"fixed_width = true;"
"        key = \\"${newCommand.key}\\";"
"        label = \\"   ${newCommand.key}  \\";"
"		is_default = false;"
"fixed_width=true;"
"      }"
": row {"
"fixed_width = true;"
"      : text_part {"
"        label = \\"${newCommand.label}\\";"
"fixed_width_font=true;"
"fixed_width=true;"
"height = 1;"
"alignment = centered;"
"      }"
"    }"
""
"}"
`;
        lines.splice(sectionEndIndex - 2, 0, newCommandDCL);
        return lines.join('\n');
    }
    
    function updateStatus(message, type) {
        const statusDiv = document.getElementById('status-message');
        statusDiv.textContent = message;
        statusDiv.className = `status-${type}`;
        setTimeout(() => {
            statusDiv.textContent = '';
            statusDiv.className = '';
        }, 5000);
    }
    
    // --- Събития ---
    
    // !!!!! ТУК Е ПРОМЯНАТА !!!!!
    loadBtn.addEventListener('click', async () => {
        console.log("Бутонът е натиснат!");

        try {
            console.log("1. Прочитане на githubUser...");
            GITHUB_USER = document.getElementById('githubUser').value.trim();
            console.log(" -> Успешно: " + GITHUB_USER);

            console.log("2. Прочитане на githubRepo...");
            GITHUB_REPO = document.getElementById('githubRepo').value.trim();
            console.log(" -> Успешно: " + GITHUB_REPO);
            
            console.log("3. Прочитане на filePath...");
            FILE_PATH = document.getElementById('filePath').value.trim();
            console.log(" -> Успешно: " + FILE_PATH);

            console.log("4. Прочитане на githubPat...");
            GITHUB_PAT = document.getElementById('githubPat').value.trim();
            console.log(" -> Успешно (дължина на токена): " + GITHUB_PAT.length);

            if (!GITHUB_USER || !GITHUB_REPO || !FILE_PATH || !GITHUB_PAT) {
                updateStatus('Моля, попълнете всички полета за настройка.', 'error');
                console.log("Проверката за празни полета не мина.");
                return;
            }
            
            console.log("5. Всички полета са прочетени. Показване на съдържанието...");
            appContent.classList.remove('hidden');
            document.getElementById('commands-container').innerHTML = '<p class="loading">Зареждане...</p>';
            
            console.log("6. Извикване на getFileContent...");
            const fileData = await getFileContent(GITHUB_USER, GITHUB_REPO, FILE_PATH, GITHUB_PAT);
            
            console.log("7. getFileContent приключи. Проверка на данните...");
            if (fileData) {
                console.log(" -> Има данни. Извикване на parseLispContent...");
                const { commands, sections } = parseLispContent(fileData.content);
                console.log(" -> Парсването приключи. Извикване на displayCommands...");
                displayCommands(commands, sections);
            } else {
                 console.log(" -> Няма данни. getFileContent е върнал null.");
            }
        } catch (e) {
            console.error("ВЪЗНИКНА КРИТИЧНА ГРЕШКА:", e);
            updateStatus("Възникна критична грешка, проверете конзолата (F12)!", 'error');
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
            const updatedFileData = await getFileContent(GITHUB_USER, GITHUB_REPO, FILE_PATH, GITHUB_PAT);
             if (updatedFileData) {
                const { commands, sections } = parseLispContent(updatedFileData.content);
                displayCommands(commands, sections);
            }
        }
    });
});
