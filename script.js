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
            // Декодиране на Base64 съдържанието
            const content = atob(data.content);
            return { content, sha: data.sha };
        } catch (error) {
            updateStatus(`Грешка: ${error.message}`, 'error');
            return null;
        }
    }
    
    async function updateFileContent(user, repo, path, token, newContent, sha, commitMessage) {
        const url = `https://api.github.com/repos/${user}/${repo}/contents/${path}`;
        // Кодиране на новото съдържание в Base64
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


    // --- Парсване и Визуализация ---

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
                // Търсим описанието на следващите няколко реда
                let label = '';
                const nextLines = lines.slice(lines.indexOf(line) + 1, lines.indexOf(line) + 5);
                for(const nextLine of nextLines){
                    const labelMatch = nextLine.trim().match(labelRegex);
                    if(labelMatch){
                        label = labelMatch[1].replace(/\\"/g, '"'); // Handle escaped quotes
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
        // Тази функция трябва да се адаптира към точната структура на вашия DCL
        // Тук е даден прост пример, който добавя командата в края на съответната секция
        const sectionMarker = `;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  HELP ${newCommand.section}`;
        const lines = originalContent.split('\n');
        
        // Намиране на реда, където започва секцията
        let sectionStartIndex = lines.findIndex(line => line.includes(sectionMarker));
        if (sectionStartIndex === -1) {
            updateStatus(`Не е намерена секция: ${newCommand.section}`, 'error');
            return originalContent;
        }

        // Намиране на края на DCL дефиницията за тази секция
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
        // Добавяме новия DCL код преди затварящата скоба на секцията
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
    
    loadBtn.addEventListener('click', async () => {
         console.log("Бутонът е натиснат!"); 
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

        // 1. Взимаме текущата версия на файла
        const fileData = await getFileContent(GITHUB_USER, GITHUB_REPO, FILE_PATH, GITHUB_PAT);
        if (!fileData) return;

        // 2. Добавяме новото съдържание
        const newContent = addNewCommandToContent(fileData.content, newCommand);
        if (newContent === fileData.content) return; // Ако не е направена промяна

        // 3. Записваме променения файл в GitHub
        const commitMessage = `Добавена е нова команда: ${newCommand.key}`;
        const result = await updateFileContent(GITHUB_USER, GITHUB_REPO, FILE_PATH, GITHUB_PAT, newContent, fileData.sha, commitMessage);

        if (result) {
            // Презареждаме командите, за да се види новата
            addCommandForm.reset();
            const updatedFileData = await getFileContent(GITHUB_USER, GITHUB_REPO, FILE_PATH, GITHUB_PAT);
             if (updatedFileData) {
                const { commands, sections } = parseLispContent(updatedFileData.content);
                displayCommands(commands, sections);
            }
        }
    });
});
