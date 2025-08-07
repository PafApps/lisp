using System.Collections.Generic;
using System.Linq;

namespace PpsMenu
{
    // Клас за съхранение на информация за един елемент в менюто
    public class MenuItem
    {
        public string Key { get; set; }
        public string Label { get; set; }
        public string Description { get; set; }
        public string AutoCADCommand { get; set; }
        public bool IsSeparator { get; set; } = false;
        public bool IsTextOnly { get; set; } = false;
    }

    // Клас за съхранение на информация за категория
    public class CategoryInfo
    {
        public string Key { get; set; }
        public string Label { get; set; }
        public string Description { get; set; }
    }

    public static class CommandDatabase
    {
        // ;;; START DCL MAIN MENU ITEMS
        public static readonly List<CategoryInfo> MainCategories = new List<CategoryInfo>
        {
            new CategoryInfo { Key = "СИТУАЦИЯ", Label = "ЗА СИТУАЦИЯ", Description = "- КОМАНДИ СВЪРЗАНИ СЪС СИТУАЦИЯТА" },
            new CategoryInfo { Key = "НАПРЕЧНИ",  Label = "ЗА НАПРЕЧНИ", Description = "- КОМАНДИ СВЪРЗАНИ С НАПРЕЧНИТЕ ПРОФИЛИ" },
            new CategoryInfo { Key = "НАДЛЪЖНИ",  Label = "ЗА НАДЛЪЖНИ", Description = "- КОМАНДИ СВЪРЗАНИ С НАДЛЪЖНИТЕ ПРОФИЛИ" },
            new CategoryInfo { Key = "БЛОКОВЕ",   Label = "ЗА БЛОКОВЕ", Description = "- КОМАНДИ СВЪРЗАНИ С МАНИПУЛАЦИЯ НА БЛОКОВЕ" },
            new CategoryInfo { Key = "ЛЕЙАУТИ",   Label = "ЗА LAYOUTS", Description = "- КОМАНДИ СВЪРЗАНИ С LAYOUTS" },
            new CategoryInfo { Key = "ДРУГИ",     Label = "ДРУГИ", Description = "- ДРУГИ КОМАНДИ" },
            new CategoryInfo { Key = "---" }, // Разделител
            new CategoryInfo { Key = "СИВИЛ",     Label = "ЗА CIVIL 3D", Description = "- КОМАНДИ СВЪРЗАНИ СЪС CIVIL 3D" },
            new CategoryInfo { Key = "---" }, // Разделител
            new CategoryInfo { Key = "РЕГИСТРИ",  Label = "ЗА РЕГИСТРИ (CIVIL)", Description = "- КОМАНДИ ЗА ИЗКАРВАНЕ НА РЕГИСТРИ ОТ CIVIL" },
        };
        // ;;; END DCL MAIN MENU ITEMS

        // База данни с всички менюта и техните елементи
        public static readonly Dictionary<string, List<MenuItem>> Menus = new Dictionary<string, List<MenuItem>>
        {
            // ;;; START DCL SITUACIA ITEMS
            { "СИТУАЦИЯ", new List<MenuItem> {
                new MenuItem { Key = "km", Label = "km", Description = "- Копира текста от txt/mtext/блок/атрибут и го пейства в друг txt/mtext/блок/атрибут", AutoCADCommand = "km" },
                new MenuItem { Key = "slope", Label = "slope", Description = "- Правене на мустаци на откосите.", AutoCADCommand = "slope" },
                new MenuItem { Key = "vpo", Label = "VPOL", Description = "- Прехвърля очертанията на VP в Model-а. С командата VPOA го прави за всички VP едновременно.", AutoCADCommand = "vpol" },
                new MenuItem { Key = "dims", Label = "dims", Description = "- Създава стил дименсии за Ситуация (ако няма), слага го текущ и прави дименсия (aligned)", AutoCADCommand = "dims" },
                new MenuItem { Key = "qe", Label = "QE", Description = "- Променяте текста на TEXT, АТРИБУТИ и някои MTEXT в блокове без да влизате в тях", AutoCADCommand = "qe" },
                new MenuItem { Key = "qec", Label = "QEC", Description = "- Променяте цвета на TEXT, АТРИБУТИ и някои MTEXT в блокове без да влизате в тях", AutoCADCommand = "qec" },
                new MenuItem { Key = "addtoblock", Label = "addtoblock", Description = "- Вкарва маркирани обекти в маркиран от вас блок", AutoCADCommand = "addtoblock" },
                new MenuItem { Key = "ndel", Label = "ndel", Description = "- Трие обект от блок без да се налага да се влиза в него", AutoCADCommand = "ndel" },
                new MenuItem { Key = "ncut", Label = "ncut", Description = "- CUT-va обект от блок без да се налага да се влиза в него", AutoCADCommand = "ncut" },
                new MenuItem { Key = "nmove", Label = "nmove", Description = "- Премества обекти в блокове и XREF без да се налага да влизате в тях. (Внимавайте защото прави save На xref дори да е отворен!)", AutoCADCommand = "nmove" },
                new MenuItem { Key = "label", Label = "label", Description = "- Поставя написан от вас надпис по продължение на Line/Polyline/Curve", AutoCADCommand = "label" },
                new MenuItem { Key = "delblocks", Label = "delblocks", Description = "- Изтрива избран блок или блокове от файла", AutoCADCommand = "delblocks" },
                new MenuItem { Key = "ww", Label = "ww", Description = "- Бързо отбелязване на точки от напречния профил в ситуация, както и нанасяне на кота дъно канавка", AutoCADCommand = "ww" },
                new MenuItem { Key = "calc", Label = "calc", Description = "- Събира/Изважда две числа (TEXT,MTEXT) и поставя резултата във друг TEXT/MTEXT", AutoCADCommand = "calc" },
                new MenuItem { Key = "wf", Label = "wf", Description = "- Променя width factor на избран/и текстови обекти", AutoCADCommand = "wf" },
                new MenuItem { Key = "wfb", Label = "wfb", Description = "- Променя width factor на текст, който се намира в блок", AutoCADCommand = "wfb" },
                new MenuItem { Key = "DIt", Label = "DIt", Description = "- Измерва разстоянието между две точки и го записва в избран TEXT или MTEXT", AutoCADCommand = "DIt" },
                new MenuItem { Key = "etr", Label = "BatchETR", Description = "- Правите ETRANSМIT на избрани файлове с възможни 3 настройки", AutoCADCommand = "BatchETR" },
                new MenuItem { Key = "etr1", Label = "ETR", Description = "- Правите ETRANSМIT на файла с възможни 3 настройки", AutoCADCommand = "ETR" },
                new MenuItem { Key = "PJ", Label = "PJ", Description = "- Свързва линии/полилинии дори да се застъпват леко или да има малко разстояние между тях", AutoCADCommand = "PJ" },
                new MenuItem { Key = "STRELKA", Label = "STRELKA", Description = "- добавяш стрелката с посока на канавката, като маркираш линията на канавката и я поставяш спрямо нея (и на оффсет) където решиш", AutoCADCommand = "STRELKA" },
                new MenuItem { Key = "loadlineM", Label = "LoadLineM", Description = "- добавя всички аутокадски видове линии във файла", AutoCADCommand = "loadlinem" },
                new MenuItem { Key = "tkm", Label = "TKM", Description = "- добавя всички типови линии свързани с TKM", AutoCADCommand = "tkm" },
                new MenuItem { Key = "MTA", Label = "MTA", Description = "- прави MapTrim/трие и тримва/ на всички обекти във файла извън посочена граница", AutoCADCommand = "MTA" },
                new MenuItem { Key = "Bind-Detach", Label = "Bind-Detach", Description = "- вкарва заредените xref-ове във файла като блокове, а незаредените ги детачва", AutoCADCommand = "Bind-Detach" },
                new MenuItem { Key = "MTB", Label = "MTB", Description = "- същото като MTA, но за блокове.", AutoCADCommand = "MTB" },
                new MenuItem { Key = "WWD", Label = "WWD", Description = "- Обратна команда на WW. Пренасяш обекти от ситуация в напречен профил. Всичко се случва в един файл", AutoCADCommand = "WWD" },
                new MenuItem { Key = "WWS", Label = "WWS", Description = "- Тази команда в комбинация с WWC е същата като WWD, само че тук работим в два отделни файла. В ситуация с командата WWS взимаме оффсет, след това във файла с напречните профили с командата WWC пренасяме оффсетите", AutoCADCommand = "WWS" },
             // ;;; END DCL SITUACIA ITEMS
            }},


            // ;;; START DCL NADLZHNI ITEMS
            { "НАДЛЪЖНИ", new List<MenuItem> {
                new MenuItem { Key = "km", Label = "km", Description = "- Копира текста от txt/mtext/блок/атрибут и го пейства в друг txt/mtext/блок/атрибут", AutoCADCommand = "km" },
                new MenuItem { Key = "vpo", Label = "VPOL", Description = "- Прехвърля очертанията на VP в Model-а. С командата VPOA го прави за всички VP едновременно.", AutoCADCommand = "vpol" },
                new MenuItem { Key = "qe", Label = "QE", Description = "- Променяте текста на TEXT, АТРИБУТИ и някои MTEXT в блокове без да влизате в тях", AutoCADCommand = "qe" },
                new MenuItem { Key = "qec", Label = "QEC", Description = "- Променяте цвета на TEXT, АТРИБУТИ и някои MTEXT в блокове без да влизате в тях", AutoCADCommand = "qec" },
                new MenuItem { Key = "Ln", Label = "Ln", Description = "- Чертаете и надписвате линия със зададен от вас наклон в %", AutoCADCommand = "Ln" },
                new MenuItem { Key = "addtoblock", Label = "addtoblock", Description = "- Вкарва маркирани обекти в маркиран от вас блок", AutoCADCommand = "addtoblock" },
                new MenuItem { Key = "ndel", Label = "ndel", Description = "- Трие обект от блок без да се налага да се влиза в него", AutoCADCommand = "ndel" },
                new MenuItem { Key = "ncut", Label = "ncut", Description = "- CUT-va обект от блок без да се налага да се влиза в него", AutoCADCommand = "ncut" },
                new MenuItem { Key = "nmove", Label = "nmove", Description = "- Премества обекти в блокове и XREF без да се налага да влизате в тях. (Внимавайте защото прави save На xref дори да е отворен!)", AutoCADCommand = "nmove" },
                new MenuItem { Key = "delblocks", Label = "delblocks", Description = "- Изтрива избран блок или блокове от файла", AutoCADCommand = "delblocks" },
                new MenuItem { Key = "calc", Label = "calc", Description = "- Събира/Изважда две числа (TEXT,MTEXT) и поставя резултата във друг TEXT/MTEXT", AutoCADCommand = "calc" },
                new MenuItem { Key = "wf", Label = "wf", Description = "- Променя width factor на избран/и текстови обекти", AutoCADCommand = "wf" },
                new MenuItem { Key = "wfb", Label = "wfb", Description = "- Променя width factor на текст, който се намира в блок", AutoCADCommand = "wfb" },
                new MenuItem { Key = "DIt", Label = "DIt", Description = "- Измерва разстоянието между две точки и го записва в избран TEXT или MTEXT", AutoCADCommand = "DIt" },
                new MenuItem { Key = "LNi", Label = "LNi", Description = "- Избираш вертикален мащаб (1:1 , 1:10, 1:100) и мерни единици (проценти или промили) и чертаеш линия на която можеш да сменяш наклона преди да си маркирал втората точка. С + и - или със Space и число показваш какъв наклон да е линията", AutoCADCommand = "LNi" }
            // ;;; END DCL NADLZHNI ITEMS 
            }},


            // ;;; START DCL NAPRECHNI ITEMS
            { "НАПРЕЧНИ", new List<MenuItem> {
                new MenuItem { Key = "d3", Label = "d3", Description = "- Пускане на ординати в напречните профили.", AutoCADCommand = "d3" },
                new MenuItem { Key = "a3", Label = "a3", Description = "- Изкарване на оградени площи в напречния профил в таблици.", AutoCADCommand = "a3" },
                new MenuItem { Key = "a3a", Label = "a3a", Description = "- Като а3, но изкарва всички площи заедно с км на даден профил наведнъж", AutoCADCommand = "a3a" },
                new MenuItem { Key = "km", Label = "km", Description = "- Копира текста от txt/mtext/блок/атрибут и го пейства в друг txt/mtext/блок/атрибут", AutoCADCommand = "km" },
                new MenuItem { Key = "otkos", Label = "OTKOS", Description = "- Надписва наклона на откоса 1:n", AutoCADCommand = "otkos" },
                new MenuItem { Key = "naklon", Label = "NAKLON", Description = "- Надписва наклон в %", AutoCADCommand = "naklon" },
                new MenuItem { Key = "dimc", Label = "dimc", Description = "- Създава стил дименсии за Напречни профили (ако няма), слага го текущ и прави дименсия (lineal)", AutoCADCommand = "dimc" },
                new MenuItem { Key = "qe", Label = "QE", Description = "- Променяте текста на TEXT, АТРИБУТИ и някои MTEXT в блокове без да влизате в тях", AutoCADCommand = "qe" },
                new MenuItem { Key = "qec", Label = "QEC", Description = "- Променяте цвета на TEXT, АТРИБУТИ и някои MTEXT в блокове без да влизате в тях", AutoCADCommand = "qec" },
                new MenuItem { Key = "Ln", Label = "Ln", Description = "- Чертаете и надписвате линия със зададен от вас наклон в %", AutoCADCommand = "Ln" },
                new MenuItem { Key = "Lо", Label = "Lо", Description = "- Чертаете и надписвате откосна линия със зададен от вас наклон - 1:2 (Y:X)", AutoCADCommand = "LO" },
                new MenuItem { Key = "addtoblock", Label = "addtoblock", Description = "- Вкарва маркирани обекти в маркиран от вас блок", AutoCADCommand = "addtoblock" },
                new MenuItem { Key = "ndel", Label = "ndel", Description = "- Трие обект от блок без да се налага да се влиза в него", AutoCADCommand = "ndel" },
                new MenuItem { Key = "ncut", Label = "ncut", Description = "- CUT-va обект от блок без да се налага да се влиза в него", AutoCADCommand = "ncut" },
                new MenuItem { Key = "nmove", Label = "nmove", Description = "- Премества обекти в блокове и XREF без да се налага да влизате в тях. (Внимавайте защото прави save На xref дори да е отворен!)", AutoCADCommand = "nmove" },
                new MenuItem { Key = "delblocks", Label = "delblocks", Description = "- Изтрива избран блок или блокове от файла", AutoCADCommand = "delblocks" },
                new MenuItem { Key = "calc", Label = "calc", Description = "- Събира/Изважда две числа (TEXT,MTEXT) и поставя резултата във друг TEXT/MTEXT", AutoCADCommand = "calc" },
                new MenuItem { Key = "wf", Label = "wf", Description = "- Променя width factor на избран/и текстови обекти", AutoCADCommand = "wf" },
                new MenuItem { Key = "wfb", Label = "wfb", Description = "- Променя width factor на текст, който се намира в блок", AutoCADCommand = "wfb" },
                new MenuItem { Key = "laq", Label = "LaQ", Description = "- Създава слоевете за ограждане на количества. Ако искаш да добавиш нови, направи го във файла Layers.csv в папка TitleBlocks на ЕТП сървъра", AutoCADCommand = "LAQ" },
                new MenuItem { Key = "DIt", Label = "DIt", Description = "- Измерва разстоянието между две точки и го записва в избран TEXT или MTEXT", AutoCADCommand = "DIt" },
                new MenuItem { Key = "regATT", Label = "regATT", Description = "- Изкарва в екселска таблица стойностите от таблиците с количества в готов вид за пействане в подробната ведомост", AutoCADCommand = "regATT" },
                new MenuItem { Key = "regATT2", Label = "regATT2", Description = "- Изкарва в екселска таблица стойностите от таблиците с количества, както и сметките, които по принцип се правят в подробната ведомост", AutoCADCommand = "regATT2" },
                new MenuItem { Key = "regATTall", Label = "regATTall", Description = "- Изкарва в екселска таблица стойностите от таблиците с количества + X и Y координати на блока", AutoCADCommand = "regattall" },
                new MenuItem { Key = "ATTCH", Label = "ATTCH", Description = "- Оправя таговете на атрибутската таблица за количества, както са описани във файла Layers.csv", AutoCADCommand = "ATTCH" },
                new MenuItem { Key = "a3all", Label = "a3all", Description = "- автоматично попълва таблиците с количества. Ползва рамките за Layout-и и взима всичко, което попада в тях", AutoCADCommand = "a3all" },
                new MenuItem { Key = "D3all", Label = "D3all", Description = "- Пуска автоматично Dl3-ки на 1 профил, като се маркира целия прoфил. Слоевете за ОП и ЗОП трявбва да са конкретни.", AutoCADCommand = "D3all" },
                new MenuItem { Key = "D3all2", Label = "D3all2", Description = "- Пуска автоматично Dl3-ки на n-брой профили, като се мракират рамките за Layout-и . Слоевете за ОП и ЗОП трявбва да са конкретни.", AutoCADCommand = "D3all2" },
                new MenuItem { Key = "d3RO", Label = "D3RO", Description = "- Пуска Dl3-ки на пътни напречни профили, както последно са уточнени", AutoCADCommand = "d3RO" },
                new MenuItem { Key = "QBZ", Label = "QBZ", Description = "- автоматично огражда площите на нов баласт и защитен пласт. Може да дава грешки при не-добре затворени контури и по-специфични случаи", AutoCADCommand = "QBZ" },
                new MenuItem { Key = "QALL", Label = "QH", Description = "- ограждане на всички количества 1 по 1, като изолира нужните слоеве и се огражда като с хетч (ако контура не е затворен или има блокове понякога дава грешки)", AutoCADCommand = "QH" },
                new MenuItem { Key = "QB", Label = "QB", Description = "- ограждане на всички количества 1 по 1, като изолира нужните слоеве, маркират се обектите между които да се пусне граница и се огражда с Boundery. По-надеждно е от QH", AutoCADCommand = "QB" },
                new MenuItem { Key = "d3t", Label = "d3t", Description = "- изкарва теренните коти в напречен профил през 1 метър.", AutoCADCommand = "d3t" },
                new MenuItem { Key = "BK", Label = "BK", Description = "- Добавя базовите коти в атрибута на скарата на напречния профил", AutoCADCommand = "BK" }
            // ;;; END DCL NAPRECHNI ITEMS
            }},

            
            // ;;; START DCL BLOKOVE ITEMS
            { "БЛОКОВЕ", new List<MenuItem> {
                new MenuItem { Key = "km", Label = "km", Description = "- Копира текста от txt/mtext/блок/атрибут и го пейства в друг txt/mtext/блок/атрибут", AutoCADCommand = "km" },
                new MenuItem { Key = "qe", Label = "QE", Description = "- Променяте текста на TEXT, АТРИБУТИ и някои MTEXT в блокове без да влизате в тях", AutoCADCommand = "qe" },
                new MenuItem { Key = "qec", Label = "QEC", Description = "- Променяте цвета на TEXT, АТРИБУТИ и някои MTEXT в блокове без да влизате в тях", AutoCADCommand = "qec" },
                new MenuItem { Key = "addtoblock", Label = "addtoblock", Description = "- Вкарва маркирани обекти в маркиран от вас блок", AutoCADCommand = "addtoblock" },
                new MenuItem { Key = "ndel", Label = "ndel", Description = "- Трие обект от блок без да се налага да се влиза в него", AutoCADCommand = "ndel" },
                new MenuItem { Key = "ncut", Label = "ncut", Description = "- CUT-va обект от блок без да се налага да се влиза в него", AutoCADCommand = "ncut" },
                new MenuItem { Key = "nmove", Label = "nmove", Description = "- Премества обекти в блокове и XREF без да се налага да влизате в тях. (Внимавайте защото прави save На xref дори да е отворен!)", AutoCADCommand = "nmove" },
                new MenuItem { Key = "delblocks", Label = "delblocks", Description = "- Изтрива избран блок или блокове от файла", AutoCADCommand = "delblocks" },
                new MenuItem { Key = "wfb", Label = "wfb", Description = "- Променя width factor на текст, който се намира в блок", AutoCADCommand = "wfb" }
            // ;;; END DCL BLOKOVE ITEMS
            }},


            // ;;; START DCL LAYOUTI ITEMS
            { "ЛЕЙАУТИ", new List<MenuItem> {
                new MenuItem { Key = "prop", Label = "prop", Description = "- Промяна на dwg custom properties, като дата на ревизия.", AutoCADCommand = "prop" },
                new MenuItem { Key = "DATA", Label = "DATA", Description = "- Сменяте датата на ревизията (ако е направена с fields в dwgproperties).", AutoCADCommand = "DATA" },
                new MenuItem { Key = "podpisi", Label = "podpisi", Description = "- С ТАЗИ КОМАНДА ИЗБИРАШ ПОДПИС НА ПРОЕКТАНТ КОЙТО ДА ВМЪКНЕШ В АНТЕТКАТА.", AutoCADCommand = "podpisi" },
                new MenuItem { Key = "---", IsTextOnly = true, Description = "(ако проектанта го няма свържи се за да бъде добавен)"},
                new MenuItem { Key = "fields", Label = "fields", Description = "- Вкарва динаични fields като име на файл, дата на ревизия, ревизия и др.", AutoCADCommand = "fields" },
                new MenuItem { Key = "psu", Label = "psu", Description = "- Добавя Imported Page Setup на избрани или всички Layouts.", AutoCADCommand = "psu" },
                new MenuItem { Key = "relay", Label = "RElay", Description = "- Преименува Layout-ите с номерация от 1 до N.", AutoCADCommand = "relay" },
                new MenuItem { Key = "Lsteal", Label = "Lsteal", Description = "- Взимане на Layout-и от друг файл.", AutoCADCommand = "LSteal" },
                new MenuItem { Key = "vpo", Label = "VPOL", Description = "- Прехвърля очертанията на VP в Model-а. С командата VPOA го прави за всички VP едновременно.", AutoCADCommand = "vpol" },
                new MenuItem { Key = "ttbhelp", Label = "TTBhelp", Description = "- отваря хелп файла, в който е обяснено всичко за TitleBlock-овете", AutoCADCommand = "ttbhelp" },
                new MenuItem { Key = "ttb", Label = "TTB", Description = "- вкарва избран от теб вече създаден за дадения обект TitleBlock", AutoCADCommand = "ttb" },
                new MenuItem { Key = "ttbu", Label = "TTBU", Description = "- ъпдейтва в отворения файл всичко във вкарания TitleBlock, което не е специфично за всяка фирма или за всяка част", AutoCADCommand = "ttbu" },
                new MenuItem { Key = "TabSort", Label = "TabSort", Description = "- манипулация на лейаутите - Сортиране/Местене/Триене/Слагане на prefix/", AutoCADCommand = "TabSort" },
                new MenuItem { Key = "copyVp", Label = "copyVp", Description = "- копира горните лейаути на надлъжния профил при долните /когато са направени чрез MAPWSPACE/", AutoCADCommand = "copyVp" },
                new MenuItem { Key = "c2l", Label = "c2l", Description = "- копира избран от вас обект/обекти в избрани от вас лейаути във файла", AutoCADCommand = "c2l" },
                new MenuItem { Key = "c2al", Label = "c2al", Description = "- копира избран от вас обект/обекти във всички лейаути във файла", AutoCADCommand = "c2al" },
                new MenuItem { Key = "selectRWC", Label = "selectRWC", Description = "- маркира последователно по Y рамките на напречните профили, за да може да се направят Layout-и с MAPWSPACE", AutoCADCommand = "selectRWC" }
            // ;;; END DCL LAYOUTI ITEMS
            }},


            // ;;; START DCL DRUGI ITEMS
            { "ДРУГИ", new List<MenuItem> {
                new MenuItem { Key = "ETR", Label = "ETR", Description = "- Прави eTransmit на отворения файл, като ти дава 3 опции.", AutoCADCommand = "ETR" },
                new MenuItem { Key = "BATCHETR", Label = "BATCHETR", Description = "- Прави eTransmit на избрани от теб файлове (не пипай преди да е завършило).", AutoCADCommand = "BATCHETR" },
                new MenuItem { Key = "BATCHPDF", Label = "BATCHPDF", Description = "- Прави PDF-и на избрани от теб файлове като пита за всеки един дали искаш подписи и къде да го запази.", AutoCADCommand = "BATCHPDF" },
                new MenuItem { Key = "BATCHPDF2", Label = "BATCHPDF2", Description = "- Прави PDF-и на избрани от теб файлове като заси подписи в слаой Signature и сейва PDF във папката, в която е файла.", AutoCADCommand = "BATCHPDF2" },
                new MenuItem { Key = "getv", Label = "GetV", Description = "- Показва с коя версия на аутокад е save-нат файла.", AutoCADCommand = "getv" },
                new MenuItem { Key = "getversions", Label = "GetVersions", Description = "- Показва с коя версия на аутокад е save-нат избран от вас файл.", AutoCADCommand = "getversions" },
                new MenuItem { Key = "meters", Label = "METERS", Description = "- Прави DWGUNITS в метри. Когато имате проблем с копирането с бейспоинт и импортването на блокове и xref.", AutoCADCommand = "meters" },
                new MenuItem { Key = "BS", Label = "BS", Description = "- Ъпдейтва блокове с атрибути.", AutoCADCommand = "BS" },
                new MenuItem { Key = "SHOWLAYERS", Label = "showLayers", Description = "- Изчертава линии и имената на всички Layer-и, които има във файла.", AutoCADCommand = "SHOWLAYERS" },
                new MenuItem { Key = "kmAll", Label = "kmAll", Description = "- При нови изкарани от CIVIL пресечки в надлъжен и ситуация надписва километража, а за дренаж надписва кота.", AutoCADCommand = "kmAll" },
                new MenuItem { Key = "kmDel", Label = "kmDel", Description = "- Работи като km само, че ако текста, който се копира е в цвят 40 го трие.", AutoCADCommand = "kmDel" },
                new MenuItem { Key = "template", Label = "template", Description = "- Отваря папката в която се намират темплейт файловете за ACAD,CIVIL и за правене на лейаути", AutoCADCommand = "template" },
                new MenuItem { Key = "LayerChange", Label = "LayerChange", Description = "- Променя описаните във файла (Layers - change Names.csv) в актуалните слоеве.", AutoCADCommand = "LayerChange" },
                new MenuItem { Key = "regAttAll", Label = "regAttAll", Description = "- Изкарва всички атрибути заедно с координатите на блока", AutoCADCommand = "regattall" },
                new MenuItem { Key = "pcoord", Label = "pcoord", Description = "- В аутокад изкарваш във файл координати на посочени от теб точки, като също ги именуваш една по една", AutoCADCommand = "pcoord" },
                new MenuItem { Key = "rtl", Label = "RTL", Description = "- върти TEXT и MTEXT спрямо линия или полилиния", AutoCADCommand = "RTL" },
                new MenuItem { Key = "askGemini", Label = "askGemini", Description = "- пишеш в ноутпат въпрос към AI Gemini - той ти връща отговор отново в Notepad. Ползва по-стар модел gemini-1.5", AutoCADCommand = "askGemini" },
                new MenuItem { Key = "iskam", Label = "iskam", Description = "- Добавя предложение/желание за нова команда или функционалност в сайта на програмите", AutoCADCommand = "iskam" },
                new MenuItem { Key = "CUIPAF", Label = "CUIPAF", Description = "- При ON заменя бутоните F1 - с отваряне на страницата с командите в PPS и F5 - с командата LISPLOAD. При OFF връща старите команди. Добавя и меню с команди", AutoCADCommand = "CUIPAF" }
            // ;;; END DCL DRUGI ITEMS
            }},


            // ;;; START DCL CIVIL ITEMS
            { "СИВИЛ", new List<MenuItem> {
                new MenuItem { Key = "slg", Label = "slg", Description = "- Правене на предварително зададени SampleLine Groups", AutoCADCommand = "slg" },
                new MenuItem { Key = "s2p", Label = "S2P", Description = "- Прави от маркирана SampleLine полилиния, като я вкарва във слоя на SampleLine", AutoCADCommand = "s2p" },
                new MenuItem { Key = "s2f", Label = "S2F", Description = "- Прави Feature линии на всички SampleLines, или на маркирани. Имената и стиловете са предварително зададени във файла SampleLineGroups.csv", AutoCADCommand = "s2f" },
                new MenuItem { Key = "flkm", Label = "FLkm", Description = "- преименува FL с новият КМ, ако е прекиломертирано или FL са със стари имена", AutoCADCommand = "flkm" },
                new MenuItem { Key = "bExp", Label = "bExp", Description = "- изкарва mtext/записва във файл: име на атрибут, километраж, кота гл.р., офсет и координати на маркирани блокове", AutoCADCommand = "bExp" },
                new MenuItem { Key = "bExp2", Label = "bExp2", Description = "- изкарва mtext/записва във файл: име на атрибут, километраж, офсет и координати на маркирани блокове ( не е нужен надлъжен)", AutoCADCommand = "bExp2" },
                new MenuItem { Key = "pExp", Label = "pExp", Description = "- изкарва mtext/записва във файл: име на точка (въвежда се от теб), километраж, кота гл.р., офсет и координати на точки избрани от теб с мишката", AutoCADCommand = "pExp" },
                new MenuItem { Key = "regV", Label = "regV", Description = "- Изкарва регистър в ПРОФИЛ във файл в същата папка. Маркираш алаймънт и избираш Нивелетата за която да се изкара регистъра.", AutoCADCommand = "regV" },
                new MenuItem { Key = "regH", Label = "regH", Description = "- Изкарва регистър в ПЛАН във файл в същата папка. Маркираш алаймънт.", AutoCADCommand = "regH" },
                new MenuItem { Key = "regC", Label = "regC", Description = "- Изкарва КООРДИНАТЕН регистър във файл в същата папка. Маркираш алаймънт, нивелета, разстояни м/у точките, както и допълнителни точки като начало стрелка.", AutoCADCommand = "regC" },
                new MenuItem { Key = "regS", Label = "regS", Description = "- Изкарва регистър на СРЕЛКИТЕ във файл в същата папка. Маркираш стрелките (трябва да са динамничните блокове от ППС), алаймънт и нивелета.", AutoCADCommand = "regS" },
                new MenuItem { Key = "kmATT", Label = "kmATT", Description = "- Километрира атрибутски блок спрямо (Incert Point) на блока - трябва да маркираш блоковете, Alignment-а и да напишеш таг-а на атрибута за km.", AutoCADCommand = "kmATT" },
                new MenuItem { Key = "GRR", Label = "GRR", Description = "- Прави BrakeLines и Boundery от сивилски точки за направата на повърхнина на същ. гл. релса - маркира се оста, на която искаме да направим Surface", AutoCADCommand = "GRR" },
                new MenuItem { Key = "GRR2", Label = "GRR2", Description = "- Като GRR само, че тук се маркират самите точки и когато имаме големи криви трябва да се прави на части, защото при голямо закръгление дава грешки - да се коригира Bounderyto", AutoCADCommand = "GRR2" },
                new MenuItem { Key = "cPExp", Label = "cPExp", Description = "- Изкарва регистър на реперите от сивилски точки. Маркира се алаймънт и всички сивилски точки", AutoCADCommand = "cPExp" },
                new MenuItem { Key = "Bazovi", Label = "Bazovi", Description = "- В сивил сменя базовите коти на много профили наведнъж, като му задаваш разстоянието от кота глава релса до базовата кота", AutoCADCommand = "Bazovi" },
                new MenuItem { Key = "RamkaLR", Label = "RamkaLR", Description = "- Мести напречните профили в ляво и дясно, като го правиш за повече профили едновременно и с по-голяма стойност", AutoCADCommand = "RamkaLR" },
                new MenuItem { Key = "RWCedit", Label = "RWCedit", Description = "- В сивил манипулираш (местиш) нагоре надолу с по 1м един или няколко профила наведнъж", AutoCADCommand = "RWCedit" }
            // ;;; END DCL CIVIL ITEMS
            }},

            
            // ;;; START DCL REGISTRI ITEMS
            { "РЕГИСТРИ", new List<MenuItem> {
                new MenuItem { Key = "bExp", Label = "bExp", Description = "- изкарва mtext/записва във файл: име на атрибут, километраж, кота гл.р., офсет и координати на маркирани блокове", AutoCADCommand = "bExp" },
                new MenuItem { Key = "pExp", Label = "pExp", Description = "- изкарва mtext/записва във файл: име на точка (въвежда се от теб), километраж, кота гл.р., офсет и координати на точки избрани от теб с мишката", AutoCADCommand = "pExp" },
                new MenuItem { Key = "regV", Label = "regV", Description = "- Изкарва регистър в ПРОФИЛ във файл в същата папка. Маркираш алаймънт и избираш Нивелетата за която да се изкара регистъра.", AutoCADCommand = "regV" },
                new MenuItem { Key = "regH", Label = "regH", Description = "- Изкарва регистър в ПЛАН във файл в същата папка. Маркираш алаймънт.", AutoCADCommand = "regH" },
                new MenuItem { Key = "regC", Label = "regC", Description = "- Изкарва КООРДИНАТЕН регистър във файл в същата папка. Маркираш алаймънт, нивелета, разстояни м/у точките, както и допълнителни точки като начало стрелка.", AutoCADCommand = "regC" },
                new MenuItem { Key = "regS", Label = "regS", Description = "- Изкарва регистър на СРЕЛКИТЕ във файл в същата папка. Маркираш стрелките (трябва да са динамничните блокове от ППС), алаймънт и нивелета.", AutoCADCommand = "regS" },
                new MenuItem { Key = "regS2", Label = "regS2", Description = "- Като regS, само че изважда стрелки и по отклонение (за ИННО) - подредбата е старата: четни - нечетни", AutoCADCommand = "regS2" },
                new MenuItem { Key = "regHro", Label = "regHro", Description = "- Изкарва регистър в ПЛАН на ПЪТ във файл в същата папка.", AutoCADCommand = "regHro" },
                new MenuItem { Key = "regVro", Label = "regVro", Description = "- Изкарва регистър в ПРОФИЛ на ПЪТ във файл в същата папка.", AutoCADCommand = "regVro" },
                new MenuItem { Key = "regCro", Label = "regCro", Description = "- Изкарва КООРДИНАТЕН регистър на ПЪТ във файл в същата папка.", AutoCADCommand = "regCro" },
                new MenuItem { Key = "cPExp", Label = "cPExp", Description = "- Изкарва регистър на реперите от сивилски точки. Маркира се алаймънт и всички сивилски точки", AutoCADCommand = "cPExp" }
            // ;;; END DCL REGISTRI ITEMS
            }}

        };

        // ;;; ==============================================================================================
        // ;;;           1. ЦЕНТРАЛНА БАЗА ДАННИ С ВСИЧКИ КОМАНДИ
        // ;;; Формат: ("DCL ключ" . "AutoCAD команда")
        // ;;; ТОВА Е 1:1 КОПИЕ НА ВАШИЯ *command-map* ЗА СПРАВКА И ПОДДРЪЖКА
        // ;;; ==============================================================================================
        // ;;; START COMMAND MAP
        public static readonly Dictionary<string, string> CommandMap = new Dictionary<string, string>
        {
            { "km", "km" },
            { "slope", "slope" },
            { "vpo", "vpol" },
            { "dims", "dims" },
            { "qe", "qe" },
            { "qec", "qec" },
            { "addtoblock", "addtoblock" },
            { "ndel", "ndel" },
            { "ncut", "ncut" },
            { "nmove", "nmove" },
            { "label", "label" },
            { "delblocks", "delblocks" },
            { "ww", "ww" },
            { "calc", "calc" },
            { "wf", "wf" },
            { "wfb", "wfb" },
            { "DIt", "DIt" },
            { "etr", "BatchETR" },
            { "etr1", "ETR" },
            { "PJ", "PJ" },
            { "STRELKA", "STRELKA" },
            { "loadlineM", "loadlinem" },
            { "tkm", "tkm" },
            { "MTA", "MTA" },
            { "Bind-Detach", "Bind-Detach" },
            { "MTB", "MTB" },
            { "d3", "d3" },
            { "a3", "a3" },
            { "a3a", "a3a" },
            { "otkos", "otkos" },
            { "naklon", "naklon" },
            { "dimc", "dimc" },
            { "Ln", "Ln" },
            { "Lо", "LO" },
            { "laq", "LAQ" },
            { "regATT", "regATT" },
            { "regATT2", "regATT2" },
            { "ATTCH", "ATTCH" },
            { "a3all", "a3all" },
            { "D3all", "D3all" },
            { "D3all2", "D3all2" },
            { "d3RO", "d3RO" },
            { "QBZ", "QBZ" },
            { "QALL", "QH" },
            { "QB", "QB" },
            { "prop", "prop" },
            { "DATA", "DATA" },
            { "podpisi", "podpisi" },
            { "fields", "fields" },
            { "psu", "psu" },
            { "relay", "relay" },
            { "Lsteal", "LSteal" },
            { "ttbhelp", "ttbhelp" },
            { "ttb", "ttb" },
            { "ttbu", "ttbu" },
            { "TabSort", "TabSort" },
            { "copyVp", "copyVp" },
            { "c2l", "c2l" },
            { "c2al", "c2al" },
            { "selectRWC", "selectRWC" },
            { "ETR", "ETR" },
            { "BATCHETR", "BATCHETR" },
            { "BATCHPDF", "BATCHPDF" },
            { "BATCHPDF2", "BATCHPDF2" },
            { "getv", "getv" },
            { "getversions", "getversions" },
            { "meters", "meters" },
            { "BS", "BS" },
            { "SHOWLAYERS", "SHOWLAYERS" },
            { "kmAll", "kmAll" },
            { "kmDel", "kmDel" },
            { "template", "template" },
            { "LayerChange", "LayerChange" },
            { "regAttAll", "regattall" },
            { "pcoord", "pcoord" },
            { "rtl", "RTL" },
            { "slg", "slg" },
            { "s2p", "s2p" },
            { "s2f", "s2f" },
            { "flkm", "flkm" },
            { "bExp", "bExp" },
            { "bExp2", "bExp2" },
            { "pExp", "pExp" },
            { "regV", "regV" },
            { "regH", "regH" },
            { "regC", "regC" },
            { "regS", "regS" },
            { "regS2", "regS2" },
            { "kmATT", "kmATT" },
            { "GRR", "GRR" },
            { "GRR2", "GRR2" },
            { "cPExp", "cPExp" },
            { "regHro", "regHro" },
            { "regVro", "regVro" },
            { "regCro", "regCro" },
            { "d3t", "d3t" },
            { "askGemini", "askGemini" },
            { "BK", "BK" },
            { "Bazovi", "Bazovi" },
            { "RamkaLR", "RamkaLR" },
            { "RWCedit", "RWCedit" },
            { "iskam", "iskam" },
            { "CUIPAF", "CUIPAF" },
            { "LNi", "LNi" },
            { "WWD", "WWD" },
            { "WWS", "WWS" },
        // ;;; END COMMAND MAP
        };
    }

    // Помощен клас за Distinct(), за да премахва дубликати по ключ
    class KeyValuePairComparer : IEqualityComparer<KeyValuePair<string, string>>
    {
        public bool Equals(KeyValuePair<string, string> x, KeyValuePair<string, string> y) => x.Key == y.Key;
        public int GetHashCode(KeyValuePair<string, string> obj) => obj.Key.GetHashCode();
    }
}
