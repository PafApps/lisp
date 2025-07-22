#################################################################################################
##################################################################################################
(setvar "cmdecho" 0)
(command ".undefine" "help")
(setvar "cmdecho" 1)
(vl-load-com)


;;; ======================================================================
;;;           ОПТИМИЗИРАНИ ФУНКЦИИ ЗА ГЕНЕРИРАНЕ НА DCL ФАЙЛОВЕ
;;; ======================================================================

;;; --- Глобална помощна функция за генериране на DCL за главно меню
;;; --- Това е шаблонът за големите бутони с описание отдолу.
(defun generate_main_menu_button (key label explanation)
  (list
    "    : row {"
    "fixed_width = true;"
    "alignment = left;"
    "      : button {"
    "width = 20;"
    "height = 3;"
    "fixed_width = true;"
    (strcat "        key = \"" key "\";")
    (strcat "        label = \"" label "\";")
    "	is_default = false;"
    "fixed_width=true;"
    "      }"
    ": row {"
    "fixed_width = true;"
    "      : text_part {"
    (strcat "        label = \"" explanation "\";")
    "fixed_width_font=true;"
    "fixed_width=true;"
    "height = 1;"
    "alignment = centered;"
    "      }"
    "    }"
    ""
    "}"
  )
)

;;; --- Глобална помощна функция за генериране на DCL за списък с команди
;;; --- Това е шаблонът за малките бутони вляво и описание вдясно.
(defun generate_command_list_button (key label explanation)
  (list
    "/////////////////////////////////////////////////////////////"
    ": row {"
    "fixed_width = true;"
    "alignment = left;"
    "      : button {"
    "width = 14;"
    "fixed_width = true;"
    (strcat "        key = \"" key "\";")
    (strcat "        label = \"" label "\";")
    "		is_default = false;"
    "fixed_width=true;"
    "      }"
    ": row {"
    "fixed_width = true;"
    "      : text_part {"
    (strcat "        label = \"" explanation "\";")
    "fixed_width_font=true;"
    "fixed_width=true;"
    "height = 1;"
    "alignment = centered;"
    "      }"
    "    }"
    ""
    "}"
  )
)

;;; --- Обща функция за запис на DCL съдържание във файл
(defun write_dcl_file (filename dcl_content / acadfn dcl_handle)
  (if (null (wcmatch (strcase filename) ".DCL")) (setq filename (strcat filename ".DCL")))
  (if (setq acadfn (findfile "ACAD.pat"))
    (progn
      (setq dcl_handle (open (vl-string-subst filename "ACAD.pat" acadfn) "w"))
      (foreach line dcl_content (write-line line dcl_handle))
      (close dcl_handle)
      t
    )
    (progn (princ (strcat "\nГрешка: Не може да се намери 'ACAD.pat' за определяне на пътя.")) nil)
  )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                  1. ГЛАВНО МЕНЮ С РАЗДЕЛИ (HELP Lisp РАЗДЕЛИ)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun create_dclhelplispR (fn / dcl_content menu_items separator)
  ;;; START DCL MAIN MENU ITEMS
  (setq menu_items
    '(
      ("СИТУАЦИЯ" "ЗА СИТУАЦИЯ"  "  - КОМАНДИ СВЪРЗАНИ СЪС СИТУАЦИЯТА")
      ("НАПРЕЧНИ"  "ЗА НАПРЕЧНИ"   "  - КОМАНДИ СВЪРЗАНИ С НАПРЕЧНИТЕ ПРОФИЛИ")
      ("НАДЛЪЖНИ"  "ЗА НАДЛЪЖНИ"   "  - КОМАНДИ СВЪРЗАНИ С НАДЛЪЖНИТЕ ПРОФИЛИ")
      ("БЛОКОВЕ"   "ЗА БЛОКОВЕ"     "  - КОМАНДИ СВЪРЗАНИ С МАНИПУЛАЦИЯ НА БЛОКОВЕ")
      ("ЛЕЙАУТИ"   "ЗА LAYOUTS"     "  - КОМАНДИ СВЪРЗАНИ С LAYOUTS")
      ("ДРУГИ"     "ДРУГИ"          "  - ДРУГИ КОМАНДИ ")
      ("---"       ""               "")
      ("СИВИЛ"     "ЗА CIVIL 3D"    "  - КОМАНДИ СВЪРЗАНИ СЪС CIVIL 3D")
      ("---"       ""               "")
      ("РЕГИСТРИ"  "ЗА РЕГИСТРИ (CIVIL)" "  - КОМАНДИ ЗА ИЗКАРВАНЕ НА РЕГИСТРИ ОТ CIVIL")
    )
  )
  ;;; END DCL MAIN MENU ITEMS
  (setq separator '(": row { label = \"============================================================================\"; }"))
  (setq dcl_content
    (append
      '("help1 : dialog { " "label = \"                                                              ПОЛЕЗНИ КОМАНДИ\"; ")
      '(": row {fixed_width = true; alignment = left; : button {width = 14; fixed_width = true; key = \"back\"; label = \"<< НАЗАД към PPS\"; is_default = false;}}")
    )
  )
  (foreach item menu_items
    (if (eq (car item) "---")
        (setq dcl_content (append dcl_content separator))
        (setq dcl_content (append dcl_content (generate_main_menu_button (nth 0 item) (nth 1 item) (nth 2 item))))
    )
  )
  (setq dcl_content (append dcl_content '(": boxed_row { : button { key = \"cancel\"; label = \"Close\"; is_default = true; is_cancel = true; alignment = centered;}} }")))
  (write_dcl_file fn dcl_content)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                        2. МЕНЮ "СИТУАЦИЯ"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun create_dclhelplispСИТУАЦИЯ (fn / dcl_content command_items)
  ;;; START DCL SITUACIA ITEMS
  (setq command_items
    '(
      ("km" "   km  " "  - Копира текста от txt/mtext/блок/атрибут и го пейства в друг txt/mtext/блок/атрибут")
      ("slope" " slope" "  - Правене на мустаци на откосите.")
      ("vpo" "VPOL" "  - Прехвърля очертанията на VP в Model-а. С командата VPOA го прави за всички VP едновременно.")
      ("dims" "dims" "  - Създава стил дименсии за Ситуация (ако няма), слага го текущ и прави дименсия (aligned)")
      ("qe" "QE" "  - Променяте текста на TEXT, АТРИБУТИ и някои MTEXT в блокове без да влизате в тях")
      ("qec" "QEC" "  - Променяте цвета на TEXT, АТРИБУТИ и някои MTEXT в блокове без да влизате в тях")
      ("addtoblock" "addtoblock" "  - Вкарва маркирани обекти в маркиран от вас блок")
      ("ndel" "ndel" "  - Трие обект от блок без да се налага да се влиза в него")
      ("ncut" "ncut" "  - CUT-va обект от блок без да се налага да се влиза в него")
      ("nmove" "nmove" "  - Премества обекти в блокове и XREF без да се налага да влизате в тях. (Внимавайте защото прави save На xref дори да е отворен!)")
      ("label" "label" "  - Поставя написан от вас надпис по продължение на Line/Polyline/Curve ")
      ("delblocks" "delblocks" "  - Изтрива избран блок или блокове от файла")
      ("ww" "ww" "  - Бързо отбелязване на точки от напречния профил в ситуация, както и нанасяне на кота дъно канавка")
      ("calc" "calc" "  - Събира/Изважда две числа (TEXT,MTEXT) и поставя резултата във друг TEXT/MTEXT")
      ("wf" "wf" "  - Променя width factor на избран/и текстови обекти")
      ("wfb" "wfb" "  - Променя width factor на текст, който се намира в блок")
      ("DIt" "DIt" "  - Измерва разстоянието между две точки и го записва в избран TEXT или MTEXT")
      ("etr" "BatchETR" "  - Правите ETRANSМIT на избрани файлове с възможни 3 настройки ")
      ("etr1" "ETR" "  - Правите ETRANSМIT на файла с възможни 3 настройки ")
      ("PJ" "PJ" "  -  	- Свързва линии/полилинии дори да се застъпват леко или да има малко разстояние между тях")
      ("STRELKA" "STRELKA" "  -  	- добавяш стрелката с посока на канавката, като маркираш линията на канавката и я поставяш спрямо нея (и на оффсет) където решиш")
      ("loadlineM" "LoadLineM" "  -  	- добавя всички аутокадски видове линии във файла")
      ("tkm" "TKM" "  -  	- добавя всички типови линии свързани с TKM")
      ("MTA" "MTA" "  -  	- прави MapTrim/трие и тримва/ на всички обекти във файла извън посочена граница")
      ("Bind-Detach" "Bind-Detach" "  -  	- вкарва заредените xref-ове във файла като блокове, а незаредените ги детачва")
      ("MTB" "MTB" "  -  	- същото като MTA, но за блокове.")
    )
  )
  ;;; END DCL SITUACIA ITEMS
  (setq dcl_content (list "helpСИТУАЦИЯ : dialog { label = \"                       HELP КОМАНДИ ЗА СИТУАЦИЯ\"; "))
  (setq dcl_content (append dcl_content '(": row {fixed_width = true; alignment = left; : button {width = 14; fixed_width = true; key = \"back\"; label = \"<< НАЗАД\"; is_default = false;}}")))
  (foreach item command_items (setq dcl_content (append dcl_content (generate_command_list_button (nth 0 item) (nth 1 item) (nth 2 item)))))
  (setq dcl_content (append dcl_content '(": boxed_row { : button { key = \"cancel\"; label = \"Close\"; is_default = true; is_cancel = true; alignment = centered;}} }")))
  (write_dcl_file fn dcl_content)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                        3. МЕНЮ "НАДЛЪЖНИ"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun create_dclhelplispНАДЛЪЖНИ (fn / dcl_content command_items)
  ;;; START DCL NADLZHNI ITEMS
  (setq command_items
    '(
      ("km" "   km  " "  - Копира текста от txt/mtext/блок/атрибут и го пейства в друг txt/mtext/блок/атрибут")
      ("vpo" "VPOL" "  - Прехвърля очертанията на VP в Model-а. С командата VPOA го прави за всички VP едновременно.")
      ("qe" "QE" "  - Променяте текста на TEXT, АТРИБУТИ и някои MTEXT в блокове без да влизате в тях")
      ("qec" "QEC" "  - Променяте цвета на TEXT, АТРИБУТИ и някои MTEXT в блокове без да влизате в тях")
      ("Ln" "Ln" "  - Чертаете и надписвате линия със зададен от вас наклон в %")
      ("addtoblock" "addtoblock" "  - Вкарва маркирани обекти в маркиран от вас блок")
      ("ndel" "ndel" "  - Трие обект от блок без да се налага да се влиза в него")
      ("ncut" "ncut" "  - CUT-va обект от блок без да се налага да се влиза в него")
      ("nmove" "nmove" "  - Премества обекти в блокове и XREF без да се налага да влизате в тях. (Внимавайте защото прави save На xref дори да е отворен!)")
      ("delblocks" "delblocks" "  - Изтрива избран блок или блокове от файла")
      ("calc" "calc" "  - Събира/Изважда две числа (TEXT,MTEXT) и поставя резултата във друг TEXT/MTEXT")
      ("wf" "wf" "  - Променя width factor на избран/и текстови обекти")
      ("wfb" "wfb" "  - Променя width factor на текст, който се намира в блок")
      ("DIt" "DIt" "  - Измерва разстоянието между две точки и го записва в избран TEXT или MTEXT")
    )
  )
  ;;; END DCL NADLZHNI ITEMS
  (setq dcl_content (list "helpНАДЛЪЖНИ : dialog { label = \"                                    HELP КОМАНДИ ЗА НАДЛЪЖНИ\"; "))
  (setq dcl_content (append dcl_content '(": row {fixed_width = true; alignment = left; : button {width = 14; fixed_width = true; key = \"back\"; label = \"<< НАЗАД\"; is_default = false;}}")))
  (foreach item command_items (setq dcl_content (append dcl_content (generate_command_list_button (nth 0 item) (nth 1 item) (nth 2 item)))))
  (setq dcl_content (append dcl_content '(": boxed_row { : button { key = \"cancel\"; label = \"Close\"; is_default = true; is_cancel = true; alignment = centered;}} }")))
  (write_dcl_file fn dcl_content)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                        4. МЕНЮ "НАПРЕЧНИ"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun create_dclhelplispНАПРЕЧНИ (fn / dcl_content command_items)
  ;;; START DCL NAPRECHNI ITEMS
  (setq command_items
    '(
      ("d3" "   d3  " "  - Пускане на ординати в напречните профили.")
      ("a3" "   a3  " "  - Изкарване на оградени площи в напречния профил в таблици.")
      ("a3a" "   a3a  " "  - Като а3, но изкарва всички площи заедно с км на даден профил наведнъж")
      ("km" "   km  " "  - Копира текста от txt/mtext/блок/атрибут и го пейства в друг txt/mtext/блок/атрибут")
      ("otkos" "OTKOS" "  - Надписва наклона на откоса 1:n")
      ("naklon" "NAKLON" "  - Надписва наклон в %")
      ("dimc" "dimc" "  - Създава стил дименсии за Напречни профили (ако няма), слага го текущ и прави дименсия (lineal)")
      ("qe" "QE" "  - Променяте текста на TEXT, АТРИБУТИ и някои MTEXT в блокове без да влизате в тях")
      ("qec" "QEC" "  - Променяте цвета на TEXT, АТРИБУТИ и някои MTEXT в блокове без да влизате в тях")
      ("Ln" "Ln" "  - Чертаете и надписвате линия със зададен от вас наклон в %")
      ("Lо" "Lо" "  - Чертаете и надписвате откосна линия със зададен от вас наклон - 1:2 (Y:X)")
      ("addtoblock" "addtoblock" "  - Вкарва маркирани обекти в маркиран от вас блок")
      ("ndel" "ndel" "  - Трие обект от блок без да се налага да се влиза в него")
      ("ncut" "ncut" "  - CUT-va обект от блок без да се налага да се влиза в него")
      ("nmove" "nmove" "  - Премества обекти в блокове и XREF без да се налага да влизате в тях. (Внимавайте защото прави save На xref дори да е отворен!)")
      ("delblocks" "delblocks" "  - Изтрива избран блок или блокове от файла")
      ("calc" "calc" "  - Събира/Изважда две числа (TEXT,MTEXT) и поставя резултата във друг TEXT/MTEXT")
      ("wf" "wf" "  - Променя width factor на избран/и текстови обекти")
      ("wfb" "wfb" "  - Променя width factor на текст, който се намира в блок")
      ("laq" "LaQ" "  - Създава слоевете за ограждане на количества. Ако искаш да добавиш нови, направи го във файла Layers.csv в папка TitleBlocks на ЕТП сървъра ")
      ("DIt" "DIt" "  - Измерва разстоянието между две точки и го записва в избран TEXT или MTEXT")
      ("regATT" "regATT" "  - Изкарва в екселска таблица стойностите от таблиците с количества в готов вид за пействане в подробната ведомост")
      ("regATT2" "regATT2" "  - Изкарва в екселска таблица стойностите от таблиците с количества, както и сметките, които по принцип се правят в подробната ведомост")
      ("regATTall" "regATTall" "  - Изкарва в екселска таблица стойностите от таблиците с количества + X и Y координати на блока")
      ("ATTCH" "ATTCH" "  - Оправя таговете на атрибутската таблица за количества, както са описани във файла Layers.csv")
      ("a3all" "a3all" "  - автоматично попълва таблиците с количества. Ползва рамките за Layout-и и взима всичко, което попада в тях")
      ("D3all" "D3all" "  - Пуска автоматично Dl3-ки на 1 профил, като се маркира целия прoфил. Слоевете за ОП и ЗОП трявбва да са конкретни.")
      ("D3all2" "D3all2" "  - Пуска автоматично Dl3-ки на n-брой профили, като се мракират рамките за Layout-и . Слоевете за ОП и ЗОП трявбва да са конкретни.")
      ("d3RO" "D3RO" "  - Пуска Dl3-ки на пътни напречни профили, както последно са уточнени")
      ("QBZ" "QBZ" "  - автоматично огражда площите на нов баласт и защитен пласт. Може да дава грешки при не-добре затворени контури и по-специфични случаи")
      ("QALL" "QH" "  - ограждане на всички количества 1 по 1, като изолира нужните слоеве и се огражда като с хетч (ако контура не е затворен или има блокове понякога дава грешки)")
      ("QB" "QB" "  - ограждане на всички количества 1 по 1, като изолира нужните слоеве, маркират се обектите между които да се пусне граница и се огражда с Boundery. По-надеждно е от QH")
      ("d3t" "d3t" "  - изкарва теренните коти в напречен профил през 1 метър.")
    )
  )
  ;;; END DCL NAPRECHNI ITEMS
  (setq dcl_content (list "helpНАПРЕЧНИ : dialog { label = \"                                   HELP КОМАНДИ ЗА НАПРЕЧНИ\"; "))
  (setq dcl_content (append dcl_content '(": row {fixed_width = true; alignment = left; : button {width = 14; fixed_width = true; key = \"back\"; label = \"<< НАЗАД\"; is_default = false;}}")))
  (foreach item command_items (setq dcl_content (append dcl_content (generate_command_list_button (nth 0 item) (nth 1 item) (nth 2 item)))))
  (setq dcl_content (append dcl_content '(": boxed_row { : button { key = \"cancel\"; label = \"Close\"; is_default = true; is_cancel = true; alignment = centered;}} }")))
  (write_dcl_file fn dcl_content)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                        5. МЕНЮ "БЛОКОВЕ"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun create_dclhelplispБЛОКОВЕ (fn / dcl_content command_items)
  ;;; START DCL BLOKOVE ITEMS
  (setq command_items
    '(
      ("km" "   km  " "  - Копира текста от txt/mtext/блок/атрибут и го пейства в друг txt/mtext/блок/атрибут")
      ("qe" "QE" "  - Променяте текста на TEXT, АТРИБУТИ и някои MTEXT в блокове без да влизате в тях")
      ("qec" "QEC" "  - Променяте цвета на TEXT, АТРИБУТИ и някои MTEXT в блокове без да влизате в тях")
      ("addtoblock" "addtoblock" "  - Вкарва маркирани обекти в маркиран от вас блок")
      ("ndel" "ndel" "  - Трие обект от блок без да се налага да се влиза в него")
      ("ncut" "ncut" "  - CUT-va обект от блок без да се налага да се влиза в него")
      ("nmove" "nmove" "  - Премества обекти в блокове и XREF без да се налага да влизате в тях. (Внимавайте защото прави save На xref дори да е отворен!)")
      ("delblocks" "delblocks" "  - Изтрива избран блок или блокове от файла")
      ("wfb" "wfb" "  - Променя width factor на текст, който се намира в блок")
    )
  )
  ;;; END DCL BLOKOVE ITEMS
  (setq dcl_content (list "helpБЛОКОВЕ : dialog { label = \"                                      HELP КОМАНДИ ЗА БЛОКОВЕ\"; "))
  (setq dcl_content (append dcl_content '(": row {fixed_width = true; alignment = left; : button {width = 14; fixed_width = true; key = \"back\"; label = \"<< НАЗАД\"; is_default = false;}}")))
  (foreach item command_items (setq dcl_content (append dcl_content (generate_command_list_button (nth 0 item) (nth 1 item) (nth 2 item)))))
  (setq dcl_content (append dcl_content '(": boxed_row { : button { key = \"cancel\"; label = \"Close\"; is_default = true; is_cancel = true; alignment = centered;}} }")))
  (write_dcl_file fn dcl_content)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                        6. МЕНЮ "ЛЕЙАУТИ"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun create_dclhelplispЛЕЙАУТИ (fn / dcl_content command_items)
  ;;; START DCL LAYOUTI ITEMS
  (setq command_items
    '(
      ("prop" "  prop  " "  - Промяна на dwg custom properties, като дата на ревизия.")
      ("DATA" "  DATA  " "  - Сменяте датата на ревизията (ако е направена с fields в dwgproperties).")
      ("podpisi" "  podpisi  " "  - С ТАЗИ КОМАНДА ИЗБИРАШ ПОДПИС НА ПРОЕКТАНТ КОЙТО ДА ВМЪКНЕШ В АНТЕТКАТА.")
      ("---" "" "") ; --- Специален елемент за текст без бутон ---
      ("fields" "  fields  " "  - Вкарва динаични fields като име на файл, дата на ревизия, ревизия и др.")
      ("psu" "  psu  " "  - Добавя Imported Page Setup на избрани или всички Layouts.")
      ("relay" "RElay " "  - Преименува Layout-ите с номерация от 1 до N.")
      ("Lsteal" "Lsteal" "  - Взимане на Layout-и от друг файл.")
      ("vpo" "VPOL" "  - Прехвърля очертанията на VP в Model-а. С командата VPOA го прави за всички VP едновременно.")
      ("ttbhelp" "TTBhelp" "  - отваря хелп файла, в който е обяснено всичко за TitleBlock-овете")
      ("ttb" "TTB" "  - вкарва избран от теб вече създаден за дадения обект TitleBlock")
      ("ttbu" "TTBU" "  - ъпдейтва в отворения файл всичко във вкарания TitleBlock, което не е специфично за всяка фирма или за всяка част")
      ("TabSort" "TabSort" "  - манипулация на лейаутите - Сортиране/Местене/Триене/Слагане на prefix/ ")
      ("copyVp" "copyVp" "  - копира горните лейаути на надлъжния профил при долните /когато са направени чрез MAPWSPACE/ ")
      ("c2l" "c2l" "  - копира избран от вас обект/обекти в избрани от вас лейаути във файла ")
      ("c2al" "c2al" "  - копира избран от вас обект/обекти във всички лейаути във файла ")
      ("selectRWC" "selectRWC" "  - маркира последователно по Y рамките на напречните профили, за да може да се направят Layout-и с MAPWSPACE ")
    )
  )
  ;;; END DCL LAYOUTI ITEMS
  (setq dcl_content (list "helpЛЕЙАУТИ : dialog { label = \"                                     HELP КОМАНДИ ЗА ЛЕЙАУТИ\"; "))
  (setq dcl_content (append dcl_content '(": row {fixed_width = true; alignment = left; : button {width = 14; fixed_width = true; key = \"back\"; label = \"<< НАЗАД\"; is_default = false;}}")))
  (foreach item command_items
    (if (eq (car item) "---")
      (setq dcl_content (append dcl_content '(": text_part { label = \"                                                                       (ако проектанта го няма свържи се за да бъде добавен)\";}")))
      (setq dcl_content (append dcl_content (generate_command_list_button (nth 0 item) (nth 1 item) (nth 2 item))))
    )
  )
  (setq dcl_content (append dcl_content '(": boxed_row { : button { key = \"cancel\"; label = \"Close\"; is_default = true; is_cancel = true; alignment = centered;}} }")))
  (write_dcl_file fn dcl_content)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                        7. МЕНЮ "ДРУГИ"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun create_dclhelplispДРУГИ (fn / dcl_content command_items)
  ;;; START DCL DRUGI ITEMS
  (setq command_items
    '(
      ("ETR" "        ETR        " "  - Прави eTransmit на отворения файл, като ти дава 3 опции.")
      ("BATCHETR" "BATCHETR" "  - Прави eTransmit на избрани от теб файлове (не пипай преди да е завършило).")
      ("BATCHPDF" "BATCHPDF" "  - Прави PDF-и на избрани от теб файлове като пита за всеки един дали искаш подписи и къде да го запази.")
      ("BATCHPDF2" "BATCHPDF2" "  - Прави PDF-и на избрани от теб файлове като заси подписи в слаой Signature и сейва PDF във папката, в която е файла.")
      ("getv" "       GetV        " "  - Показва с коя версия на аутокад е save-нат файла.")
      ("getversions" "GetVersions" "  - Показва с коя версия на аутокад е save-нат избран от вас файл.")
      ("meters" "   METERS   " "  - Прави DWGUNITS в метри. Когато имате проблем с копирането с бейспоинт и импортването на блокове и xref.")
      ("BS" "         BS         " "  - Ъпдейтва блокове с атрибути.")
      ("SHOWLAYERS" "showLayers" "  - Изчертава линии и имената на всички Layer-и, които има във файла.")
      ("kmAll" "      kmAll       " "  - При нови изкарани от CIVIL пресечки в надлъжен и ситуация надписва километража, а за дренаж надписва кота.")
      ("kmDel" "     kmDel      " "  - Работи като km само, че ако текста, който се копира е в цвят 40 го трие.")
      ("template" "   template   " "  - Отваря папката в която се намират темплейт файловете за ACAD,CIVIL и за правене на лейаути")
      ("LayerChange" "LayerChange" "  - Променя описаните във файла (Layers - change Names.csv) в актуалните слоеве.")
      ("regAttAll" "regAttAll" "  - Изкарва всички атрибути заедно с координатите на блока")
      ("pcoord" "pcoord" "  - В аутокад изкарваш във файл координати на посочени от теб точки, като също ги именуваш една по една")
      ("rtl" "RTL" "  - върти TEXT и MTEXT спрямо линия или полилиния")
      ("askGemini" "askGemini" "  - пишеш в ноутпат въпрос към AI Gemini - той ти връща отговор отново в Notepad. Ползва по-стар модел gemini-1.5")
    )
  )
  ;;; END DCL DRUGI ITEMS
  (setq dcl_content (list "helpДРУГИ : dialog { label = \"                                     HELP КОМАНДИ ЗА ДРУГИ\"; "))
  (setq dcl_content (append dcl_content '(": row {fixed_width = true; alignment = left; : button {width = 14; fixed_width = true; key = \"back\"; label = \"<< НАЗАД\"; is_default = false;}}")))
  (foreach item command_items (setq dcl_content (append dcl_content (generate_command_list_button (nth 0 item) (nth 1 item) (nth 2 item)))))
  (setq dcl_content (append dcl_content '(": boxed_row { : button { key = \"cancel\"; label = \"Close\"; is_default = true; is_cancel = true; alignment = centered;}} }")))
  (write_dcl_file fn dcl_content)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                        8. МЕНЮ "СИВИЛ"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun create_dclhelplispСИВИЛ (fn / dcl_content command_items)
  ;;; START DCL CIVIL ITEMS
  (setq command_items
    '(
      ("slg" "slg" "  - Правене на предварително зададени SampleLine Groups")
      ("s2p" "S2P" "  - Прави от маркирана SampleLine полилиния, като я вкарва във слоя на SampleLine")
      ("s2f" "S2F" "  - Прави Feature линии на всички SampleLines, или на маркирани. Имената и стиловете са предварително зададени във файла SampleLineGroups.csv")
      ("flkm" "FLkm" "  - преименува FL с новият КМ, ако е прекиломертирано или FL са със стари имена")
      ("bExp" "bExp" "  - изкарва mtext/записва във файл: име на атрибут, километраж, кота гл.р., офсет и координати на маркирани блокове")
      ("bExp2" "bExp2" "  - изкарва mtext/записва във файл: име на атрибут, километраж, офсет и координати на маркирани блокове ( не е нужен надлъжен)")
      ("pExp" "pExp" "  - изкарва mtext/записва във файл: име на точка (въвежда се от теб), километраж, кота гл.р., офсет и координати на точки избрани от теб с мишката")
      ("regV" "regV" "  - Изкарва регистър в ПРОФИЛ във файл в същата папка. Маркираш алаймънт и избираш Нивелетата за която да се изкара регистъра.")
      ("regH" "regH" "  - Изкарва регистър в ПЛАН във файл в същата папка. Маркираш алаймънт.")
      ("regC" "regC" "  - Изкарва КООРДИНАТЕН регистър във файл в същата папка. Маркираш алаймънт, нивелета, разстояни м/у точките, както и допълнителни точки като начало стрелка.")
      ("regS" "regS" "  - Изкарва регистър на СРЕЛКИТЕ във файл в същата папка. Маркираш стрелките (трябва да са динамничните блокове от ППС), алаймънт и нивелета.")
      ("kmATT" "kmATT" "  - Километрира атрибутски блок спрямо (Incert Point) на блока - трябва да маркираш блоковете, Alignment-а и да напишеш таг-а на атрибута за km.")
      ("GRR" "GRR" "  - Прави BrakeLines и Boundery от сивилски точки за направата на повърхнина на същ. гл. релса - маркира се оста, на която искаме да направим Surface")
      ("GRR2" "GRR2" "  - Като GRR само, че тук се маркират самите точки и когато имаме големи криви трябва да се прави на части, защото при голямо закръгление дава грешки - да се коригира Bounderyto")
      ("cPExp" "cPExp" "  - Изкарва регистър на реперите от сивилски точки. Маркира се алаймънт и всички сивилски точки")
    )
  )
  ;;; END DCL CIVIL ITEMS
  (setq dcl_content (list "helpСИВИЛ : dialog { label = \"	HELP КОМАНДИ ЗА СИВИЛ\"; "))
  (setq dcl_content (append dcl_content '(": row {fixed_width = true; alignment = left; : button {width = 14; fixed_width = true; key = \"back\"; label = \"<< НАЗАД\"; is_default = false;}}")))
  (foreach item command_items (setq dcl_content (append dcl_content (generate_command_list_button (nth 0 item) (nth 1 item) (nth 2 item)))))
  (setq dcl_content (append dcl_content '(": boxed_row { : button { key = \"cancel\"; label = \"Close\"; is_default = true; is_cancel = true; alignment = centered;}} }")))
  (write_dcl_file fn dcl_content)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                        9. МЕНЮ "РЕГИСТРИ"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun create_dclhelplispРЕГИСТРИ (fn / dcl_content command_items)
  ;;; START DCL REGISTRI ITEMS
  (setq command_items
    '(
      ("bExp" "bExp" "  - изкарва mtext/записва във файл: име на атрибут, километраж, кота гл.р., офсет и координати на маркирани блокове")
      ("pExp" "pExp" "  - изкарва mtext/записва във файл: име на точка (въвежда се от теб), километраж, кота гл.р., офсет и координати на точки избрани от теб с мишката")
      ("regV" "regV" "  - Изкарва регистър в ПРОФИЛ във файл в същата папка. Маркираш алаймънт и избираш Нивелетата за която да се изкара регистъра.")
      ("regH" "regH" "  - Изкарва регистър в ПЛАН във файл в същата папка. Маркираш алаймънт.")
      ("regC" "regC" "  - Изкарва КООРДИНАТЕН регистър във файл в същата папка. Маркираш алаймънт, нивелета, разстояни м/у точките, както и допълнителни точки като начало стрелка.")
      ("regS" "regS" "  - Изкарва регистър на СРЕЛКИТЕ във файл в същата папка. Маркираш стрелките (трябва да са динамничните блокове от ППС), алаймънт и нивелета.")
      ("regS2" "regS2" "  - Като regS, само че изважда стрелки и по отклонение (за ИННО) - подредбата е старата: четни - нечетни")
      ("regHro" "regHro" "  - Изкарва регистър в ПЛАН на ПЪТ във файл в същата папка.")
      ("regVro" "regVro" "  - Изкарва регистър в ПРОФИЛ на ПЪТ във файл в същата папка.")
      ("regCro" "regCro" "  - Изкарва КООРДИНАТЕН регистър на ПЪТ във файл в същата папка.")
      ("cPExp" "cPExp" "  - Изкарва регистър на реперите от сивилски точки. Маркира се алаймънт и всички сивилски точки")
    )
  )
  ;;; END DCL REGISTRI ITEMS
  (setq dcl_content (list "helpРЕГИСТРИ : dialog { label = \"	HELP КОМАНДИ ЗА РЕГИСТРИ ОТ СИВИЛ\"; "))
  (setq dcl_content (append dcl_content '(": row {fixed_width = true; alignment = left; : button {width = 14; fixed_width = true; key = \"back\"; label = \"<< НАЗАД\"; is_default = false;}}")))
  (foreach item command_items (setq dcl_content (append dcl_content (generate_command_list_button (nth 0 item) (nth 1 item) (nth 2 item)))))
  (setq dcl_content (append dcl_content '(": boxed_row { : button { key = \"cancel\"; label = \"Close\"; is_default = true; is_cancel = true; alignment = centered;}} }")))
  (write_dcl_file fn dcl_content)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                   10. СТАР ГЛАВЕН HELP LISP (ако все още се ползва)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun create_dclhelplisp (fn / dcl_content command_items)
  ;;; START DCL MAIN HELP ITEMS
  (setq command_items
    '(
      ("d3" "   d3  " "  - Пускане на ординати в напречните профили.")
      ("a3" "   a3  " "  - Изкарване на оградени площи в напречния профил в таблици.")
      ("km" "   km  " "  - Копира текста от txt/mtext/блок/атрибут и го пейства в друг txt/mtext/блок/атрибут")
      ("slope" " slope" "  - Правене на мустаци на откосите.")
      ("psu" "  psu  " "  - Добавя Imported Page Setup на избрани или всички Layouts.")
      ("relay" "RElay " "  - Преименува Layout-ите с номерация от 1 до N.")
      ("Lsteal" "Lsteal" "  - Взимане на Layout-и от друг файл.")
      ("vpo" "VPOL" "  - Прехвърля очертанията на VP в Model-а. С командата VPOA го прави за всички VP едновременно.")
      ("otkos" "OTKOS" "  - Надписва наклона на откоса 1:n")
      ("naklon" "NAKLON" "  - Надписва наклон в %")
      ("dimc" "dimc" "  - Създава стил дименсии за Напречни профили (ако няма), слага го текущ и прави дименсия (lineal)")
      ("dims" "dims" "  - Създава стил дименсии за Ситуация (ако няма), слага го текущ и прави дименсия (aligned)")
      ("ttbhelp" "TitleBlock Help" "  - отваря хелп файла, в който е обяснено всичко за TitleBlock-овете")
      ("qe" "QE" "  - Променяте текста на TEXT, АТРИБУТИ и някои MTEXT в блокове без да влизате в тях")
      ("qec" "QEC" "  - Променяте цвета на TEXT, АТРИБУТИ и някои MTEXT в блокове без да влизате в тях")
      ("Ln" "Ln" "  - Чертаете и надписвате линия със зададен от вас наклон в %")
      ("Lо" "Lо" "  - Чертаете и надписвате откосна линия със зададен от вас наклон - 1:2 (Y:X)")
      ("addtoblock" "addtoblock" "  - Вкарва маркирани обекти в маркиран от вас блок")
      ("ndel" "ndel" "  - Трие обект от блок без да се налага да се влиза в него")
      ("ncut" "ncut" "  - CUT-va обект от блок без да се налага да се влиза в него")
      ("nmove" "nmove" "  - Премества обекти в блокове и XREF без да се налага да влизате в тях. (Внимавайте защото прави save На xref дори да е отворен!)")
      ("label" "label" "  - Поставя написан от вас надпис по продължение на Line/Polyline/Curve ")
      ("delblocks" "delblocks" "  - Изтрива избран блок или блокове от файла")
      ("ww" "ww" "  - Бързо отбелязване на точки от напречния профил в ситуация")
      ("calc" "calc" "  - Събира/Изважда две числа (TEXT,MTEXT) и поставя резултата във друг TEXT/MTEXT")
      ("wf" "wf" "  - Променя width factor на избран/и текстови обекти")
      ("wfb" "wfb" "  - Променя width factor на текст, който се намира в блок")
      ("---" "" "") ; Разделител за CIVIL 3D
      ("slg" "slg" "  - Правене на предварително зададени SampleLine Groups")
      ("s2p" "s2p" "  - Прави от маркирана SampleLine полилиния, като я вкарва във слоя на SampleLine")
      ("s2f" "s2f" "  - Прави Feature линии на всички SampleLines, или на маркирани. Имената и стиловете са предварително зададени във файла SampleLineGroups.csv")
    )
  )
  ;;; END DCL MAIN HELP ITEMS
  (setq dcl_content (list "help : dialog { label = \"                                              HELP LISP\"; "))
  (foreach item command_items 
      (if (eq (car item) "---")
          (setq dcl_content (append dcl_content '(": row { label = \"======================================================================================================================================\"; }" ": row { label = \"___________________________________________________________    За CIVIL 3D   _______________________________________________________________\"; }")))
          (setq dcl_content (append dcl_content (generate_command_list_button (nth 0 item) (nth 1 item) (nth 2 item))))
      )
  )
  (setq dcl_content (append dcl_content '(": boxed_row { : button { key = \"cancel\"; label = \"Close\"; is_default = true; is_cancel = true; alignment = centered;}} }")))
  (write_dcl_file fn dcl_content)
)














;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; ==============================================================================================
;;;           1. ЦЕНТРАЛНА БАЗА ДАННИ С ВСИЧКИ КОМАНДИ
;;; Формат: ("DCL ключ" . "AutoCAD команда")
;;; ВАШЕТО УЕБ ПРИЛОЖЕНИЕ ТРЯБВА ДА ДОБАВЯ РЕДОВЕ САМО В ТОЗИ БЛОК.
;;; ==============================================================================================
;;; START COMMAND MAP
(setq *command-map*
  '(
    ("km"          . "km")
    ("slope"       . "slope")
    ("vpo"         . "vpol")
    ("dims"        . "dims")
    ("qe"          . "qe")
    ("qec"         . "qec")
    ("addtoblock"  . "addtoblock")
    ("ndel"        . "ndel")
    ("ncut"        . "ncut")
    ("nmove"       . "nmove")
    ("label"       . "label")
    ("delblocks"   . "delblocks")
    ("ww"          . "ww")
    ("calc"        . "calc")
    ("wf"          . "wf")
    ("wfb"         . "wfb")
    ("DIt"         . "DIt")
    ("etr"         . "BatchETR")
    ("etr1"        . "ETR")
    ("PJ"          . "PJ")
    ("STRELKA"     . "STRELKA")
    ("loadlineM"   . "loadlinem")
    ("tkm"         . "tkm")
    ("MTA"         . "MTA")
    ("Bind-Detach" . "Bind-Detach")
    ("MTB"         . "MTB")
    ("d3"          . "d3")
    ("a3"          . "a3")
    ("a3a"         . "a3a")
    ("otkos"       . "otkos")
    ("naklon"      . "naklon")
    ("dimc"        . "dimc")
    ("Ln"          . "Ln")
    ("Lо"          . "LO")
    ("laq"         . "LAQ")
    ("regATT"      . "regATT")
    ("regATT2"     . "regATT2")
    ("ATTCH"       . "ATTCH")
    ("a3all"       . "a3all")
    ("D3all"       . "D3all")
    ("D3all2"      . "D3all2")
    ("d3RO"        . "d3RO")
    ("QBZ"         . "QBZ")
    ("QALL"        . "QH")
    ("QB"          . "QB")
    ("prop"        . "prop")
    ("DATA"        . "DATA")
    ("podpisi"     . "podpisi")
    ("fields"      . "fields")
    ("psu"         . "psu")
    ("relay"       . "relay")
    ("Lsteal"      . "LSteal")
    ("ttbhelp"     . "ttbhelp")
    ("ttb"         . "ttb")
    ("ttbu"        . "ttbu")
    ("TabSort"     . "TabSort")
    ("copyVp"      . "copyVp")
    ("c2l"         . "c2l")
    ("c2al"        . "c2al")
    ("selectRWC"   . "selectRWC")
    ("ETR"         . "ETR")
    ("BATCHETR"    . "BATCHETR")
    ("BATCHPDF"    . "BATCHPDF")
    ("BATCHPDF2"   . "BATCHPDF2")
    ("getv"        . "getv")
    ("getversions" . "getversions")
    ("meters"      . "meters")
    ("BS"          . "BS")
    ("SHOWLAYERS"  . "SHOWLAYERS")
    ("kmAll"       . "kmAll")
    ("kmDel"       . "kmDel")
    ("template"    . "template")
    ("LayerChange" . "LayerChange")
    ("regAttAll"   . "regattall")
    ("pcoord"      . "pcoord")
    ("rtl"         . "RTL")
    ("slg"         . "slg")
    ("s2p"         . "s2p")
    ("s2f"         . "s2f")
    ("flkm"        . "flkm")
    ("bExp"        . "bExp")
    ("bExp2"       . "bExp2")
    ("pExp"        . "pExp")
    ("regV"        . "regV")
    ("regH"        . "regH")
    ("regC"        . "regC")
    ("regS"        . "regS")
    ("regS2"       . "regS2")
    ("kmATT"       . "kmATT")
    ("GRR"         . "GRR")
    ("GRR2"        . "GRR2")
    ("cPExp"       . "cPExp")
    ("regHro"      . "regHro")
    ("regVro"      . "regVro")
    ("regCro"      . "regCro")
    ("back"        . "help")
    ("pps_back"    . "pps")
    ("СИТУАЦИЯ"    . "СИТУАЦИЯ")
    ("НАДЛЪЖНИ"    . "НАДЛЪЖНИ")
    ("НАПРЕЧНИ"    . "НАПРЕЧНИ")
    ("БЛОКОВЕ"     . "БЛОКОВЕ")
    ("ЛЕЙАУТИ"     . "ЛЕЙАУТИ")
    ("ДРУГИ"       . "ДРУГИ")
    ("СИВИЛ"       . "СИВИЛ")
    ("РЕГИСТРИ"    . "РЕГИСТРИ")
    ("d3t" . "d3t")
    ("askGemini" . "askGemini")
;;; END COMMAND MAP
  )
)


;;; ==============================================================================================
;;;           2. СПИСЪЦИ С КЛЮЧОВЕ ЗА ВСЕКИ ДИАЛОГ
;;; ==============================================================================================

;;; START MAIN KEYS
(setq *main-command-keys* '("СИТУАЦИЯ" "НАДЛЪЖНИ" "НАПРЕЧНИ" "БЛОКОВЕ" "ЛЕЙАУТИ" "ДРУГИ" "СИВИЛ" "РЕГИСТРИ" "pps_back"))
;;; END MAIN KEYS

;;; START SITUACIA KEYS
(setq *situacia-command-keys* '("km" "slope" "vpo" "dims" "qe" "qec" "addtoblock" "ndel" "ncut" "nmove" "label" "delblocks" "ww" "calc" "wf" "wfb" "DIt" "etr" "etr1" "PJ" "STRELKA" "loadlineM" "tkm" "MTA" "Bind-Detach" "MTB" "back"))
;;; END SITUACIA KEYS

;;; START NAPRECHNI KEYS
(setq *naprechni-command-keys* '("d3" "a3" "a3a" "km" "otkos" "naklon" "dimc" "qe" "qec" "Ln" "Lо" "addtoblock" "ndel" "ncut" "nmove" "delblocks" "calc" "wf" "wfb" "laq" "DIt" "regATT" "regATT2" "regATTall" "ATTCH" "a3all" "D3all" "D3all2" "d3RO" "QBZ" "QALL" "QB" "d3t" "back"))
;;; END NAPRECHNI KEYS

;;; START NADLAZHNI KEYS
(setq *nadlazhni-command-keys* '("km" "vpo" "qe" "qec" "Ln" "addtoblock" "ndel" "ncut" "nmove" "delblocks" "calc" "wf" "wfb" "DIt" "back"))
;;; END NADLAZHNI KEYS

;;; START BLOKOVE KEYS
(setq *blokove-command-keys* '("km" "qe" "qec" "addtoblock" "ndel" "ncut" "nmove" "delblocks" "wfb" "back"))
;;; END BLOKOVE KEYS

;;; START LAYOUTS KEYS
(setq *layouts-command-keys* '("prop" "DATA" "podpisi" "fields" "psu" "relay" "Lsteal" "vpo" "ttbhelp" "ttb" "ttbu" "TabSort" "copyVp" "c2l" "c2al" "selectRWC" "back"))
;;; END LAYOUTS KEYS

;;; START DRUGI KEYS
(setq *drugi-command-keys* '("ETR" "BATCHETR" "BATCHPDF" "BATCHPDF2" "getv" "getversions" "meters" "BS" "SHOWLAYERS" "kmAll" "kmDel" "template" "LayerChange" "regAttAll" "pcoord" "rtl" "askGemini" "back"))
;;; END DRUGI KEYS

;;; START CIVIL KEYS
(setq *civil-command-keys* '("slg" "s2p" "s2f" "flkm" "bExp" "bExp2" "pExp" "regV" "regH" "regC" "regS" "kmATT" "GRR" "GRR2" "cPExp" "back"))
;;; END CIVIL KEYS

;;; START REGISTRI KEYS
(setq *registri-command-keys* '("bExp" "pExp" "regV" "regH" "regC" "regS" "regS2" "regHro" "regVro" "regCro" "cPExp" "back"))
;;; END REGISTRI KEYS


;;; ==============================================================================================
;;;                  3. ГЛАВНИ C: КОМАНДИ ЗА ВСЕКИ ДИАЛОГ
;;; ==============================================================================================
(defun ETP-ShowDialog-Universal (dcl_name key_list / dcl_id *error* key)
  (defun *error* (msg) (if (and dcl_id (>= dcl_id 0)) (unload_dialog dcl_id)) (princ (strcat "\nГРЕШКА: " msg)) (princ))
  (setq dcl_id (load_dialog (strcat dcl_name ".dcl")))
  (if (not (new_dialog dcl_name dcl_id)) (exit))
  (foreach key key_list
    (action_tile key (strcat "(vla-SendCommand (vla-get-activedocument (vlax-get-acad-object)) (strcat (cdr (assoc \"" key "\" *command-map*)) \" \"))(done_dialog)"))
  )
  (action_tile "cancel" "(done_dialog)")
  (start_dialog)
  (unload_dialog dcl_id)
  (princ)
)

(defun C:help () (create_dclhelplispR "help1") (ETP-ShowDialog-Universal "help1" *main-command-keys*))
(defun C:СИТУАЦИЯ () (create_dclhelplispСИТУАЦИЯ "helpСИТУАЦИЯ") (ETP-ShowDialog-Universal "helpСИТУАЦИЯ" *situacia-command-keys*))
(defun C:НАПРЕЧНИ () (create_dclhelplispНАПРЕЧНИ "helpНАПРЕЧНИ") (ETP-ShowDialog-Universal "helpНАПРЕЧНИ" *naprechni-command-keys*))
(defun C:НАДЛЪЖНИ () (create_dclhelplispНАДЛЪЖНИ "helpНАДЛЪЖНИ") (ETP-ShowDialog-Universal "helpНАДЛЪЖНИ" *nadlazhni-command-keys*))
(defun C:БЛОКОВЕ () (create_dclhelplispБЛОКОВЕ "helpБЛОКОВЕ") (ETP-ShowDialog-Universal "helpБЛОКОВЕ" *blokove-command-keys*))
(defun C:ЛЕЙАУТИ () (create_dclhelplispЛЕЙАУТИ "helpЛЕЙАУТИ") (ETP-ShowDialog-Universal "helpЛЕЙАУТИ" *layouts-command-keys*))
(defun C:ДРУГИ () (create_dclhelplispДРУГИ "helpДРУГИ") (ETP-ShowDialog-Universal "helpДРУГИ" *drugi-command-keys*))
(defun C:СИВИЛ () (create_dclhelplispСИВИЛ "helpСИВИЛ") (ETP-ShowDialog-Universal "helpСИВИЛ" *civil-command-keys*))
(defun C:РЕГИСТРИ () (create_dclhelplispРЕГИСТРИ "helpРЕГИСТРИ") (ETP-ShowDialog-Universal "helpРЕГИСТРИ" *registri-command-keys*))

(princ "\nФинална, форматирана и оптимизирана версия на Lisp файла е заредена.")
(princ)
##################################################################################################
##################################################################################################
##################################################################################################
##################################################################################################
##################################################################################################
##################################################################################################
##################################################################################################
