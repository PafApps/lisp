document.addEventListener('DOMContentLoaded', () => {
    const loadBtn = document.getElementById('load-commands-btn');
    const appContent = document.getElementById('app-content');
    const addCommandForm = document.getElementById('add-command-form');

    let GITHUB_USER = '';
    let GITHUB_REPO = '';
    let FILE_PATH = '';
    let GITHUB_PAT = '';
    
    // --- API Взаимодействие (остава същото) ---
    async function getFileContent(user, repo, path, token) { /* ... */ }
    async function updateFileContent(user, repo, path, token, newContent, sha, commitMessage) { /* ... */ }

    // --- НОВ, ПРАВИЛЕН ПАРСЕР ---
    function parseLispContent(content) {
        const commands = [];
        const sections = [];
        const lines = content.split('\n');
        
        const sectionRegex = /;;; START (\w+) KEYS/;
        const commandMapRegex = /\("([^"]+)"\s+\.\s+"([^"]+)"\)/;
        const dclLabelRegex = /: text_part {label = "([^"]*)";}/;
        const dclKeyRegex = /key = "([^"]+)"/;

        let commandMap = {};
        let inCommandMap = false;

        // 1. Попълваме commandMap от Lisp кода
        lines.forEach(line => {
            if (line.includes(';;; START COMMAND MAP')) inCommandMap = true;
            if (line.includes(';;; END COMMAND MAP')) inCommandMap = false;
            if (inCommandMap) {
                const match = line.match(commandMapRegex);
                if (match) commandMap[match[1]] = match[2];
            }
        });
        
        // 2. Извличаме описанията от DCL блоковете
        let descriptions = {};
        let currentDclKey = null;
        lines.forEach(line => {
            const keyMatch = line.match(dclKeyRegex);
            if (keyMatch) currentDclKey = keyMatch[1];
            
            const labelMatch = line.match(dclLabelRegex);
            if(labelMatch && currentDclKey && labelMatch[1].trim().startsWith("-")) {
                descriptions[currentDclKey] = labelMatch[1].trim().replace(/^-\s*/, '');
                currentDclKey = null;
            }
        });

        // 3. Обхождаме секциите и конструираме финалния обект
        lines.forEach(line => {
            const sectionMatch = line.match(sectionRegex);
            if (sectionMatch) {
                const sectionNameRaw = sectionMatch[1];
                const sectionName = sectionNameRaw.charAt(0) + sectionNameRaw.slice(1).toLowerCase();
                if (!sections.includes(sectionName)) sections.push(sectionName);

                const keysMatch = line.match(/\(setq \*[\w-]+-keys\* '(\(.*\))\)/);
                if (keysMatch) {
                    const keys = keysMatch[1].match(/"[^"]+"/g).map(k => k.replace(/"/g, ''));
                    keys.forEach(key => {
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
        });
        
        return { commands, sections };
    }

    // ... (displayCommands остава същата)
    function displayCommands(commands, sections) { /* ... */ }
    
    // MAP за преобразуване на имената на секциите
    const sectionToKeyMap = { "СИТУАЦИЯ": "SITUACIA", "НАПРЕЧНИ": "NAPRECHNI", /* ... и т.н. */ };

    function addNewCommandToContent(originalContent, newCommand) {
        let lines = originalContent.split('\n');
        
        // --- 1. Добавяне в *command-map* ---
        const commandMapEndMarker = ';;; END COMMAND MAP';
        let commandMapEndIndex = lines.findIndex(line => line.includes(commandMapEndMarker));
        const newCommandMapEntry = `    ("${newCommand.key}" . "${newCommand.key}")`;
        lines.splice(commandMapEndIndex, 0, newCommandMapEntry);

        // --- 2. Добавяне в списъка с ключове за секцията ---
        const sectionKeyName = (sectionToKeyMap[newCommand.section.toUpperCase()] || newCommand.section.toUpperCase());
        const sectionKeysEndMarker = `;;; END ${sectionKeyName} KEYS`;
        let sectionKeysEndIndex = lines.findIndex(line => line.includes(sectionKeysEndMarker));
        
        let targetLineIndex = sectionKeysEndIndex -1;
        let lineToModify = lines[targetLineIndex];
        let closingParenIndex = lineToModify.lastIndexOf(')');
        let keyToInsert = ` \"${newCommand.key}\"`;
        lines[targetLineIndex] = lineToModify.substring(0, closingParenIndex) + keyToInsert + lineToModify.substring(closingParenIndex);

        // --- 3. Добавяне на DCL ред ---
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

    // ... (updateStatus и събитията остават същите)
    function updateStatus(message, type) { /* ... */ }
    loadBtn.addEventListener('click', async () => { /* ... */ });
    addCommandForm.addEventListener('submit', async (e) => { /* ... */ });
});
