#################################################################################################
##################################################################################################
(setvar "cmdecho" 0)
(command ".undefine" "help")
(setvar "cmdecho" 1)
(vl-load-com)


;;; ======================================================================
;;;           ������������ ������� �� ���������� �� DCL �������
;;; ======================================================================

;;; --- �������� ������� ������� �� ���������� �� DCL �� ������ ����
;;; --- ���� � �������� �� �������� ������ � �������� ������.
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

;;; --- �������� ������� ������� �� ���������� �� DCL �� ������ � �������
;;; --- ���� � �������� �� ������� ������ ����� � �������� ������.
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

;;; --- ���� ������� �� ����� �� DCL ���������� ��� ����
(defun write_dcl_file (filename dcl_content / acadfn dcl_handle)
  (if (null (wcmatch (strcase filename) ".DCL")) (setq filename (strcat filename ".DCL")))
  (if (setq acadfn (findfile "ACAD.pat"))
    (progn
      (setq dcl_handle (open (vl-string-subst filename "ACAD.pat" acadfn) "w"))
      (foreach line dcl_content (write-line line dcl_handle))
      (close dcl_handle)
      t
    )
    (progn (princ (strcat "\n������: �� ���� �� �� ������ 'ACAD.pat' �� ���������� �� ����.")) nil)
  )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                  1. ������ ���� � ������� (HELP Lisp �������)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun create_dclhelplispR (fn / dcl_content menu_items separator)
  ;;; START DCL MAIN MENU ITEMS
  (setq menu_items
    '(
      ("��������" "�� ��������"  "  - ������� �������� ��� ����������")
      ("��������"  "�� ��������"   "  - ������� �������� � ���������� �������")
      ("��������"  "�� ��������"   "  - ������� �������� � ���������� �������")
      ("�������"   "�� �������"     "  - ������� �������� � ����������� �� �������")
      ("�������"   "�� LAYOUTS"     "  - ������� �������� � LAYOUTS")
      ("�����"     "�����"          "  - ����� ������� ")
      ("---"       ""               "")
      ("�����"     "�� CIVIL 3D"    "  - ������� �������� ��� CIVIL 3D")
      ("---"       ""               "")
      ("��������"  "�� �������� (CIVIL)" "  - ������� �� ��������� �� �������� �� CIVIL")
    )
  )
  ;;; END DCL MAIN MENU ITEMS
  (setq separator '(": row { label = \"============================================================================\"; }"))
  (setq dcl_content
    (append
      '("help1 : dialog { " "label = \"                                                              ������� �������\"; ")
      '(": row {fixed_width = true; alignment = left; : button {width = 14; fixed_width = true; key = \"back\"; label = \"<< ����� ��� PPS\"; is_default = false;}}")
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
;;;                        2. ���� "��������"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun create_dclhelplisp�������� (fn / dcl_content command_items)
  ;;; START DCL SITUACIA ITEMS
  (setq command_items
    '(
      ("km" "   km  " "  - ������ ������ �� txt/mtext/����/������� � �� ������� � ���� txt/mtext/����/�������")
      ("slope" " slope" "  - ������� �� ������� �� ��������.")
      ("vpo" "VPOL" "  - ��������� ����������� �� VP � Model-�. � ��������� VPOA �� ����� �� ������ VP ������������.")
      ("dims" "dims" "  - ������� ���� �������� �� �������� (��� ����), ����� �� ����� � ����� �������� (aligned)")
      ("qe" "QE" "  - ��������� ������ �� TEXT, �������� � ����� MTEXT � ������� ��� �� ������� � ���")
      ("qec" "QEC" "  - ��������� ����� �� TEXT, �������� � ����� MTEXT � ������� ��� �� ������� � ���")
      ("addtoblock" "addtoblock" "  - ������ ��������� ������ � �������� �� ��� ����")
      ("ndel" "ndel" "  - ���� ����� �� ���� ��� �� �� ������ �� �� ����� � ����")
      ("ncut" "ncut" "  - CUT-va ����� �� ���� ��� �� �� ������ �� �� ����� � ����")
      ("nmove" "nmove" "  - ��������� ������ � ������� � XREF ��� �� �� ������ �� ������� � ���. (���������� ������ ����� save �� xref ���� �� � �������!)")
      ("label" "label" "  - ������� ������� �� ��� ������ �� ����������� �� Line/Polyline/Curve ")
      ("delblocks" "delblocks" "  - ������� ������ ���� ��� ������� �� �����")
      ("ww" "ww" "  - ����� ����������� �� ����� �� ��������� ������ � ��������, ����� � �������� �� ���� ���� �������")
      ("calc" "calc" "  - ������/������� ��� ����� (TEXT,MTEXT) � ������� ��������� ��� ���� TEXT/MTEXT")
      ("wf" "wf" "  - ������� width factor �� ������/� �������� ������")
      ("wfb" "wfb" "  - ������� width factor �� �����, ����� �� ������ � ����")
      ("DIt" "DIt" "  - ������� ������������ ����� ��� ����� � �� ������� � ������ TEXT ��� MTEXT")
      ("etr" "BatchETR" "  - ������� ETRANS�IT �� ������� ������� � �������� 3 ��������� ")
      ("etr1" "ETR" "  - ������� ETRANS�IT �� ����� � �������� 3 ��������� ")
      ("PJ" "PJ" "  -  	- ������� �����/��������� ���� �� �� ��������� ���� ��� �� ��� ����� ���������� ����� ���")
      ("STRELKA" "STRELKA" "  -  	- ������� ��������� � ������ �� ���������, ���� �������� ������� �� ��������� � � �������� ������ ��� (� �� ������) ������ �����")
      ("loadlineM" "LoadLineM" "  -  	- ������ ������ ���������� ������ ����� ��� �����")
      ("tkm" "TKM" "  -  	- ������ ������ ������ ����� �������� � TKM")
      ("MTA" "MTA" "  -  	- ����� MapTrim/���� � ������/ �� ������ ������ ��� ����� ����� �������� �������")
      ("Bind-Detach" "Bind-Detach" "  -  	- ������ ���������� xref-��� ��� ����� ���� �������, � ������������ �� �������")
      ("MTB" "MTB" "  -  	- ������ ���� MTA, �� �� �������.")
    )
  )
  ;;; END DCL SITUACIA ITEMS
  (setq dcl_content (list "help�������� : dialog { label = \"                       HELP ������� �� ��������\"; "))
  (setq dcl_content (append dcl_content '(": row {fixed_width = true; alignment = left; : button {width = 14; fixed_width = true; key = \"back\"; label = \"<< �����\"; is_default = false;}}")))
  (foreach item command_items (setq dcl_content (append dcl_content (generate_command_list_button (nth 0 item) (nth 1 item) (nth 2 item)))))
  (setq dcl_content (append dcl_content '(": boxed_row { : button { key = \"cancel\"; label = \"Close\"; is_default = true; is_cancel = true; alignment = centered;}} }")))
  (write_dcl_file fn dcl_content)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                        3. ���� "��������"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun create_dclhelplisp�������� (fn / dcl_content command_items)
  ;;; START DCL NADLZHNI ITEMS
  (setq command_items
    '(
      ("km" "   km  " "  - ������ ������ �� txt/mtext/����/������� � �� ������� � ���� txt/mtext/����/�������")
      ("vpo" "VPOL" "  - ��������� ����������� �� VP � Model-�. � ��������� VPOA �� ����� �� ������ VP ������������.")
      ("qe" "QE" "  - ��������� ������ �� TEXT, �������� � ����� MTEXT � ������� ��� �� ������� � ���")
      ("qec" "QEC" "  - ��������� ����� �� TEXT, �������� � ����� MTEXT � ������� ��� �� ������� � ���")
      ("Ln" "Ln" "  - �������� � ���������� ����� ��� ������� �� ��� ������ � %")
      ("addtoblock" "addtoblock" "  - ������ ��������� ������ � �������� �� ��� ����")
      ("ndel" "ndel" "  - ���� ����� �� ���� ��� �� �� ������ �� �� ����� � ����")
      ("ncut" "ncut" "  - CUT-va ����� �� ���� ��� �� �� ������ �� �� ����� � ����")
      ("nmove" "nmove" "  - ��������� ������ � ������� � XREF ��� �� �� ������ �� ������� � ���. (���������� ������ ����� save �� xref ���� �� � �������!)")
      ("delblocks" "delblocks" "  - ������� ������ ���� ��� ������� �� �����")
      ("calc" "calc" "  - ������/������� ��� ����� (TEXT,MTEXT) � ������� ��������� ��� ���� TEXT/MTEXT")
      ("wf" "wf" "  - ������� width factor �� ������/� �������� ������")
      ("wfb" "wfb" "  - ������� width factor �� �����, ����� �� ������ � ����")
      ("DIt" "DIt" "  - ������� ������������ ����� ��� ����� � �� ������� � ������ TEXT ��� MTEXT")
    )
  )
  ;;; END DCL NADLZHNI ITEMS
  (setq dcl_content (list "help�������� : dialog { label = \"                                    HELP ������� �� ��������\"; "))
  (setq dcl_content (append dcl_content '(": row {fixed_width = true; alignment = left; : button {width = 14; fixed_width = true; key = \"back\"; label = \"<< �����\"; is_default = false;}}")))
  (foreach item command_items (setq dcl_content (append dcl_content (generate_command_list_button (nth 0 item) (nth 1 item) (nth 2 item)))))
  (setq dcl_content (append dcl_content '(": boxed_row { : button { key = \"cancel\"; label = \"Close\"; is_default = true; is_cancel = true; alignment = centered;}} }")))
  (write_dcl_file fn dcl_content)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                        4. ���� "��������"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun create_dclhelplisp�������� (fn / dcl_content command_items)
  ;;; START DCL NAPRECHNI ITEMS
  (setq command_items
    '(
      ("d3" "   d3  " "  - ������� �� �������� � ���������� �������.")
      ("a3" "   a3  " "  - ��������� �� �������� ����� � ��������� ������ � �������.")
      ("a3a" "   a3a  " "  - ���� �3, �� ������� ������ ����� ������ � �� �� ����� ������ ��������")
      ("km" "   km  " "  - ������ ������ �� txt/mtext/����/������� � �� ������� � ���� txt/mtext/����/�������")
      ("otkos" "OTKOS" "  - �������� ������� �� ������ 1:n")
      ("naklon" "NAKLON" "  - �������� ������ � %")
      ("dimc" "dimc" "  - ������� ���� �������� �� �������� ������� (��� ����), ����� �� ����� � ����� �������� (lineal)")
      ("qe" "QE" "  - ��������� ������ �� TEXT, �������� � ����� MTEXT � ������� ��� �� ������� � ���")
      ("qec" "QEC" "  - ��������� ����� �� TEXT, �������� � ����� MTEXT � ������� ��� �� ������� � ���")
      ("Ln" "Ln" "  - �������� � ���������� ����� ��� ������� �� ��� ������ � %")
      ("L�" "L�" "  - �������� � ���������� ������� ����� ��� ������� �� ��� ������ - 1:2 (Y:X)")
      ("addtoblock" "addtoblock" "  - ������ ��������� ������ � �������� �� ��� ����")
      ("ndel" "ndel" "  - ���� ����� �� ���� ��� �� �� ������ �� �� ����� � ����")
      ("ncut" "ncut" "  - CUT-va ����� �� ���� ��� �� �� ������ �� �� ����� � ����")
      ("nmove" "nmove" "  - ��������� ������ � ������� � XREF ��� �� �� ������ �� ������� � ���. (���������� ������ ����� save �� xref ���� �� � �������!)")
      ("delblocks" "delblocks" "  - ������� ������ ���� ��� ������� �� �����")
      ("calc" "calc" "  - ������/������� ��� ����� (TEXT,MTEXT) � ������� ��������� ��� ���� TEXT/MTEXT")
      ("wf" "wf" "  - ������� width factor �� ������/� �������� ������")
      ("wfb" "wfb" "  - ������� width factor �� �����, ����� �� ������ � ����")
      ("laq" "LaQ" "  - ������� �������� �� ��������� �� ����������. ��� ����� �� ������� ����, ������� �� ��� ����� Layers.csv � ����� TitleBlocks �� ��� ������� ")
      ("DIt" "DIt" "  - ������� ������������ ����� ��� ����� � �� ������� � ������ TEXT ��� MTEXT")
      ("regATT" "regATT" "  - ������� � �������� ������� ����������� �� ��������� � ���������� � ����� ��� �� ��������� � ���������� ��������")
      ("regATT2" "regATT2" "  - ������� � �������� ������� ����������� �� ��������� � ����������, ����� � ��������, ����� �� ������� �� ������ � ���������� ��������")
      ("regATTall" "regATTall" "  - ������� � �������� ������� ����������� �� ��������� � ���������� + X � Y ���������� �� �����")
      ("ATTCH" "ATTCH" "  - ������ �������� �� ������������ ������� �� ����������, ����� �� ������� ��� ����� Layers.csv")
      ("a3all" "a3all" "  - ����������� ������� ��������� � ����������. ������ ������� �� Layout-� � ����� ������, ����� ������ � ���")
      ("D3all" "D3all" "  - ����� ����������� Dl3-�� �� 1 ������, ���� �� ������� ����� ��o���. �������� �� �� � ��� ������� �� �� ���������.")
      ("D3all2" "D3all2" "  - ����� ����������� Dl3-�� �� n-���� �������, ���� �� �������� ������� �� Layout-� . �������� �� �� � ��� ������� �� �� ���������.")
      ("d3RO" "D3RO" "  - ����� Dl3-�� �� ����� �������� �������, ����� �������� �� ��������")
      ("QBZ" "QBZ" "  - ����������� ������� ������� �� ��� ������ � ������� �����. ���� �� ���� ������ ��� ��-����� ��������� ������� � ��-���������� ������")
      ("QALL" "QH" "  - ��������� �� ������ ���������� 1 �� 1, ���� ������� ������� ������ � �� ������� ���� � ���� (��� ������� �� � �������� ��� ��� ������� �������� ���� ������)")
      ("QB" "QB" "  - ��������� �� ������ ���������� 1 �� 1, ���� ������� ������� ������, �������� �� �������� ����� ����� �� �� ����� ������� � �� ������� � Boundery. ��-�������� � �� QH")
    )
  )
  ;;; END DCL NAPRECHNI ITEMS
  (setq dcl_content (list "help�������� : dialog { label = \"                                   HELP ������� �� ��������\"; "))
  (setq dcl_content (append dcl_content '(": row {fixed_width = true; alignment = left; : button {width = 14; fixed_width = true; key = \"back\"; label = \"<< �����\"; is_default = false;}}")))
  (foreach item command_items (setq dcl_content (append dcl_content (generate_command_list_button (nth 0 item) (nth 1 item) (nth 2 item)))))
  (setq dcl_content (append dcl_content '(": boxed_row { : button { key = \"cancel\"; label = \"Close\"; is_default = true; is_cancel = true; alignment = centered;}} }")))
  (write_dcl_file fn dcl_content)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                        5. ���� "�������"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun create_dclhelplisp������� (fn / dcl_content command_items)
  ;;; START DCL BLOKOVE ITEMS
  (setq command_items
    '(
      ("km" "   km  " "  - ������ ������ �� txt/mtext/����/������� � �� ������� � ���� txt/mtext/����/�������")
      ("qe" "QE" "  - ��������� ������ �� TEXT, �������� � ����� MTEXT � ������� ��� �� ������� � ���")
      ("qec" "QEC" "  - ��������� ����� �� TEXT, �������� � ����� MTEXT � ������� ��� �� ������� � ���")
      ("addtoblock" "addtoblock" "  - ������ ��������� ������ � �������� �� ��� ����")
      ("ndel" "ndel" "  - ���� ����� �� ���� ��� �� �� ������ �� �� ����� � ����")
      ("ncut" "ncut" "  - CUT-va ����� �� ���� ��� �� �� ������ �� �� ����� � ����")
      ("nmove" "nmove" "  - ��������� ������ � ������� � XREF ��� �� �� ������ �� ������� � ���. (���������� ������ ����� save �� xref ���� �� � �������!)")
      ("delblocks" "delblocks" "  - ������� ������ ���� ��� ������� �� �����")
      ("wfb" "wfb" "  - ������� width factor �� �����, ����� �� ������ � ����")
    )
  )
  ;;; END DCL BLOKOVE ITEMS
  (setq dcl_content (list "help������� : dialog { label = \"                                      HELP ������� �� �������\"; "))
  (setq dcl_content (append dcl_content '(": row {fixed_width = true; alignment = left; : button {width = 14; fixed_width = true; key = \"back\"; label = \"<< �����\"; is_default = false;}}")))
  (foreach item command_items (setq dcl_content (append dcl_content (generate_command_list_button (nth 0 item) (nth 1 item) (nth 2 item)))))
  (setq dcl_content (append dcl_content '(": boxed_row { : button { key = \"cancel\"; label = \"Close\"; is_default = true; is_cancel = true; alignment = centered;}} }")))
  (write_dcl_file fn dcl_content)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                        6. ���� "�������"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun create_dclhelplisp������� (fn / dcl_content command_items)
  ;;; START DCL LAYOUTI ITEMS
  (setq command_items
    '(
      ("prop" "  prop  " "  - ������� �� dwg custom properties, ���� ���� �� �������.")
      ("DATA" "  DATA  " "  - ������� ������ �� ��������� (��� � ��������� � fields � dwgproperties).")
      ("podpisi" "  podpisi  " "  - � ���� ������� ������� ������ �� ��������� ����� �� ������� � ���������.")
      ("---" "" "") ; --- ��������� ������� �� ����� ��� ����� ---
      ("fields" "  fields  " "  - ������ �������� fields ���� ��� �� ����, ���� �� �������, ������� � ��.")
      ("psu" "  psu  " "  - ������ Imported Page Setup �� ������� ��� ������ Layouts.")
      ("relay" "RElay " "  - ���������� Layout-��� � ��������� �� 1 �� N.")
      ("Lsteal" "Lsteal" "  - ������� �� Layout-� �� ���� ����.")
      ("vpo" "VPOL" "  - ��������� ����������� �� VP � Model-�. � ��������� VPOA �� ����� �� ������ VP ������������.")
      ("ttbhelp" "TTBhelp" "  - ������ ���� �����, � ����� � �������� ������ �� TitleBlock-�����")
      ("ttb" "TTB" "  - ������ ������ �� ��� ���� �������� �� ������� ����� TitleBlock")
      ("ttbu" "TTBU" "  - �������� � ��������� ���� ������ ��� �������� TitleBlock, ����� �� � ���������� �� ����� ����� ��� �� ����� ����")
      ("TabSort" "TabSort" "  - ����������� �� ��������� - ���������/�������/������/������� �� prefix/ ")
      ("copyVp" "copyVp" "  - ������ ������� ������� �� ��������� ������ ��� ������� /������ �� ��������� ���� MAPWSPACE/ ")
      ("c2l" "c2l" "  - ������ ������ �� ��� �����/������ � ������� �� ��� ������� ��� ����� ")
      ("c2al" "c2al" "  - ������ ������ �� ��� �����/������ ��� ������ ������� ��� ����� ")
      ("selectRWC" "selectRWC" "  - ������� �������������� �� Y ������� �� ���������� �������, �� �� ���� �� �� �������� Layout-� � MAPWSPACE ")
    )
  )
  ;;; END DCL LAYOUTI ITEMS
  (setq dcl_content (list "help������� : dialog { label = \"                                     HELP ������� �� �������\"; "))
  (setq dcl_content (append dcl_content '(": row {fixed_width = true; alignment = left; : button {width = 14; fixed_width = true; key = \"back\"; label = \"<< �����\"; is_default = false;}}")))
  (foreach item command_items
    (if (eq (car item) "---")
      (setq dcl_content (append dcl_content '(": text_part { label = \"                                                                       (��� ���������� �� ���� ������ �� �� �� ���� �������)\";}")))
      (setq dcl_content (append dcl_content (generate_command_list_button (nth 0 item) (nth 1 item) (nth 2 item))))
    )
  )
  (setq dcl_content (append dcl_content '(": boxed_row { : button { key = \"cancel\"; label = \"Close\"; is_default = true; is_cancel = true; alignment = centered;}} }")))
  (write_dcl_file fn dcl_content)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                        7. ���� "�����"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun create_dclhelplisp����� (fn / dcl_content command_items)
  ;;; START DCL DRUGI ITEMS
  (setq command_items
    '(
      ("ETR" "        ETR        " "  - ����� eTransmit �� ��������� ����, ���� �� ���� 3 �����.")
      ("BATCHETR" "BATCH ETR" "  - ����� eTransmit �� ������� �� ��� ������� (�� ����� ����� �� � ���������).")
      ("BATCHPDF" "BATCH PDF" "  - ����� PDF-� �� ������� �� ��� ������� ���� ���� �� ����� ���� ���� ����� ������� � ���� �� �� ������.")
      ("BATCHPDF2" "BATCH PDF2" "  - ����� PDF-� �� ������� �� ��� ������� ���� ���� ������� � ����� Signature � ����� PDF ��� �������, � ����� � �����.")
      ("getv" "       GetV        " "  - ������� � ��� ������ �� ������� � save-��� �����.")
      ("getversions" "GetVersions" "  - ������� � ��� ������ �� ������� � save-��� ������ �� ��� ����.")
      ("meters" "   METERS   " "  - ����� DWGUNITS � �����. ������ ����� ������� � ���������� � ��������� � ������������ �� ������� � xref.")
      ("BS" "         BS         " "  - �������� ������� � ��������.")
      ("SHOWLAYERS" "showLayers" "  - ��������� ����� � ������� �� ������ Layer-�, ����� ��� ��� �����.")
      ("kmAll" "      kmAll       " "  - ��� ���� �������� �� CIVIL �������� � �������� � �������� �������� �����������, � �� ������ �������� ����.")
      ("kmDel" "     kmDel      " "  - ������ ���� km ����, �� ��� ������, ����� �� ������ � � ���� 40 �� ����.")
      ("template" "   template   " "  - ������ ������� � ����� �� ������� �������� ��������� �� ACAD,CIVIL � �� ������� �� �������")
      ("LayerChange" "LayerChange" "  - ������� ��������� ��� ����� (Layers - change Names.csv) � ���������� ������.")
      ("regAttAll" "regAttAll" "  - ������� ������ �������� ������ � ������������ �� �����")
      ("pcoord" "pcoord" "  - � ������� �������� ��� ���� ���������� �� �������� �� ��� �����, ���� ���� �� �������� ���� �� ����")
      ("rtl" "RTL" "  - ����� TEXT � MTEXT ������ ����� ��� ���������")
    )
  )
  ;;; END DCL DRUGI ITEMS
  (setq dcl_content (list "help����� : dialog { label = \"                                     HELP ������� �� �����\"; "))
  (setq dcl_content (append dcl_content '(": row {fixed_width = true; alignment = left; : button {width = 14; fixed_width = true; key = \"back\"; label = \"<< �����\"; is_default = false;}}")))
  (foreach item command_items (setq dcl_content (append dcl_content (generate_command_list_button (nth 0 item) (nth 1 item) (nth 2 item)))))
  (setq dcl_content (append dcl_content '(": boxed_row { : button { key = \"cancel\"; label = \"Close\"; is_default = true; is_cancel = true; alignment = centered;}} }")))
  (write_dcl_file fn dcl_content)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                        8. ���� "�����"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun create_dclhelplisp����� (fn / dcl_content command_items)
  ;;; START DCL CIVIL ITEMS
  (setq command_items
    '(
      ("slg" "slg" "  - ������� �� ������������� �������� SampleLine Groups")
      ("s2p" "S2P" "  - ����� �� ��������� SampleLine ���������, ���� � ������ ��� ���� �� SampleLine")
      ("s2f" "S2F" "  - ����� Feature ����� �� ������ SampleLines, ��� �� ���������. ������� � ��������� �� ������������� �������� ��� ����� SampleLineGroups.csv")
      ("flkm" "FLkm" "  - ���������� FL � ������ ��, ��� � ���������������� ��� FL �� ��� ����� �����")
      ("bExp" "bExp" "  - ������� mtext/������� ��� ����: ��� �� �������, ����������, ���� ��.�., ����� � ���������� �� ��������� �������")
      ("bExp2" "bExp2" "  - ������� mtext/������� ��� ����: ��� �� �������, ����������, ����� � ���������� �� ��������� ������� ( �� � ����� ��������)")
      ("pExp" "pExp" "  - ������� mtext/������� ��� ����: ��� �� ����� (������� �� �� ���), ����������, ���� ��.�., ����� � ���������� �� ����� ������� �� ��� � �������")
      ("regV" "regV" "  - ������� �������� � ������ ��� ���� � ������ �����. �������� �������� � ������� ���������� �� ����� �� �� ������ ���������.")
      ("regH" "regH" "  - ������� �������� � ���� ��� ���� � ������ �����. �������� ��������.")
      ("regC" "regC" "  - ������� ����������� �������� ��� ���� � ������ �����. �������� ��������, ��������, ��������� �/� �������, ����� � ������������ ����� ���� ������ �������.")
      ("regS" "regS" "  - ������� �������� �� �������� ��� ���� � ������ �����. �������� ��������� (������ �� �� ������������ ������� �� ���), �������� � ��������.")
      ("kmATT" "kmATT" "  - ����������� ���������� ���� ������ (Incert Point) �� ����� - ������ �� �������� ���������, Alignment-� � �� ������� ���-� �� �������� �� km.")
      ("GRR" "GRR" "  - ����� BrakeLines � Boundery �� �������� ����� �� ��������� �� ���������� �� ���. ��. ����� - ������� �� ����, �� ����� ������ �� �������� Surface")
      ("GRR2" "GRR2" "  - ���� GRR ����, �� ��� �� �������� ������ ����� � ������ ����� ������ ����� ������ �� �� ����� �� �����, ������ ��� ������ ����������� ���� ������ - �� �� �������� Bounderyto")
      ("cPExp" "cPExp" "  - ������� �������� �� �������� �� �������� �����. ������� �� �������� � ������ �������� �����")
    )
  )
  ;;; END DCL CIVIL ITEMS
  (setq dcl_content (list "help����� : dialog { label = \"	HELP ������� �� �����\"; "))
  (setq dcl_content (append dcl_content '(": row {fixed_width = true; alignment = left; : button {width = 14; fixed_width = true; key = \"back\"; label = \"<< �����\"; is_default = false;}}")))
  (foreach item command_items (setq dcl_content (append dcl_content (generate_command_list_button (nth 0 item) (nth 1 item) (nth 2 item)))))
  (setq dcl_content (append dcl_content '(": boxed_row { : button { key = \"cancel\"; label = \"Close\"; is_default = true; is_cancel = true; alignment = centered;}} }")))
  (write_dcl_file fn dcl_content)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                        9. ���� "��������"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun create_dclhelplisp�������� (fn / dcl_content command_items)
  ;;; START DCL REGISTRI ITEMS
  (setq command_items
    '(
      ("bExp" "bExp" "  - ������� mtext/������� ��� ����: ��� �� �������, ����������, ���� ��.�., ����� � ���������� �� ��������� �������")
      ("pExp" "pExp" "  - ������� mtext/������� ��� ����: ��� �� ����� (������� �� �� ���), ����������, ���� ��.�., ����� � ���������� �� ����� ������� �� ��� � �������")
      ("regV" "regV" "  - ������� �������� � ������ ��� ���� � ������ �����. �������� �������� � ������� ���������� �� ����� �� �� ������ ���������.")
      ("regH" "regH" "  - ������� �������� � ���� ��� ���� � ������ �����. �������� ��������.")
      ("regC" "regC" "  - ������� ����������� �������� ��� ���� � ������ �����. �������� ��������, ��������, ��������� �/� �������, ����� � ������������ ����� ���� ������ �������.")
      ("regS" "regS" "  - ������� �������� �� �������� ��� ���� � ������ �����. �������� ��������� (������ �� �� ������������ ������� �� ���), �������� � ��������.")
      ("regS2" "regS2" "  - ���� regS, ���� �� ������� ������� � �� ���������� (�� ����) - ���������� � �������: ����� - �������")
      ("regHro" "regHro" "  - ������� �������� � ���� �� ��� ��� ���� � ������ �����.")
      ("regVro" "regVro" "  - ������� �������� � ������ �� ��� ��� ���� � ������ �����.")
      ("regCro" "regCro" "  - ������� ����������� �������� �� ��� ��� ���� � ������ �����.")
      ("cPExp" "cPExp" "  - ������� �������� �� �������� �� �������� �����. ������� �� �������� � ������ �������� �����")
    )
  )
  ;;; END DCL REGISTRI ITEMS
  (setq dcl_content (list "help�������� : dialog { label = \"	HELP ������� �� �������� �� �����\"; "))
  (setq dcl_content (append dcl_content '(": row {fixed_width = true; alignment = left; : button {width = 14; fixed_width = true; key = \"back\"; label = \"<< �����\"; is_default = false;}}")))
  (foreach item command_items (setq dcl_content (append dcl_content (generate_command_list_button (nth 0 item) (nth 1 item) (nth 2 item)))))
  (setq dcl_content (append dcl_content '(": boxed_row { : button { key = \"cancel\"; label = \"Close\"; is_default = true; is_cancel = true; alignment = centered;}} }")))
  (write_dcl_file fn dcl_content)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                   10. ���� ������ HELP LISP (��� ��� ��� �� ������)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun create_dclhelplisp (fn / dcl_content command_items)
  ;;; START DCL MAIN HELP ITEMS
  (setq command_items
    '(
      ("d3" "   d3  " "  - ������� �� �������� � ���������� �������.")
      ("a3" "   a3  " "  - ��������� �� �������� ����� � ��������� ������ � �������.")
      ("km" "   km  " "  - ������ ������ �� txt/mtext/����/������� � �� ������� � ���� txt/mtext/����/�������")
      ("slope" " slope" "  - ������� �� ������� �� ��������.")
      ("psu" "  psu  " "  - ������ Imported Page Setup �� ������� ��� ������ Layouts.")
      ("relay" "RElay " "  - ���������� Layout-��� � ��������� �� 1 �� N.")
      ("Lsteal" "Lsteal" "  - ������� �� Layout-� �� ���� ����.")
      ("vpo" "VPOL" "  - ��������� ����������� �� VP � Model-�. � ��������� VPOA �� ����� �� ������ VP ������������.")
      ("otkos" "OTKOS" "  - �������� ������� �� ������ 1:n")
      ("naklon" "NAKLON" "  - �������� ������ � %")
      ("dimc" "dimc" "  - ������� ���� �������� �� �������� ������� (��� ����), ����� �� ����� � ����� �������� (lineal)")
      ("dims" "dims" "  - ������� ���� �������� �� �������� (��� ����), ����� �� ����� � ����� �������� (aligned)")
      ("ttbhelp" "TitleBlock Help" "  - ������ ���� �����, � ����� � �������� ������ �� TitleBlock-�����")
      ("qe" "QE" "  - ��������� ������ �� TEXT, �������� � ����� MTEXT � ������� ��� �� ������� � ���")
      ("qec" "QEC" "  - ��������� ����� �� TEXT, �������� � ����� MTEXT � ������� ��� �� ������� � ���")
      ("Ln" "Ln" "  - �������� � ���������� ����� ��� ������� �� ��� ������ � %")
      ("L�" "L�" "  - �������� � ���������� ������� ����� ��� ������� �� ��� ������ - 1:2 (Y:X)")
      ("addtoblock" "addtoblock" "  - ������ ��������� ������ � �������� �� ��� ����")
      ("ndel" "ndel" "  - ���� ����� �� ���� ��� �� �� ������ �� �� ����� � ����")
      ("ncut" "ncut" "  - CUT-va ����� �� ���� ��� �� �� ������ �� �� ����� � ����")
      ("nmove" "nmove" "  - ��������� ������ � ������� � XREF ��� �� �� ������ �� ������� � ���. (���������� ������ ����� save �� xref ���� �� � �������!)")
      ("label" "label" "  - ������� ������� �� ��� ������ �� ����������� �� Line/Polyline/Curve ")
      ("delblocks" "delblocks" "  - ������� ������ ���� ��� ������� �� �����")
      ("ww" "ww" "  - ����� ����������� �� ����� �� ��������� ������ � ��������")
      ("calc" "calc" "  - ������/������� ��� ����� (TEXT,MTEXT) � ������� ��������� ��� ���� TEXT/MTEXT")
      ("wf" "wf" "  - ������� width factor �� ������/� �������� ������")
      ("wfb" "wfb" "  - ������� width factor �� �����, ����� �� ������ � ����")
      ("---" "" "") ; ���������� �� CIVIL 3D
      ("slg" "slg" "  - ������� �� ������������� �������� SampleLine Groups")
      ("s2p" "s2p" "  - ����� �� ��������� SampleLine ���������, ���� � ������ ��� ���� �� SampleLine")
      ("s2f" "s2f" "  - ����� Feature ����� �� ������ SampleLines, ��� �� ���������. ������� � ��������� �� ������������� �������� ��� ����� SampleLineGroups.csv")
    )
  )
  ;;; END DCL MAIN HELP ITEMS
  (setq dcl_content (list "help : dialog { label = \"                                              HELP LISP\"; "))
  (foreach item command_items 
      (if (eq (car item) "---")
          (setq dcl_content (append dcl_content '(": row { label = \"======================================================================================================================================\"; }" ": row { label = \"___________________________________________________________    �� CIVIL 3D   _______________________________________________________________\"; }")))
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
;;;           1. ��������� ���� ����� � ������ �������
;;; ������: ("DCL ����" . "AutoCAD �������")
;;; ������ ��� ���������� ������ �� ������ ������ ���� � ���� ����.
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
    ("L�"          . "LO")
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
    ("��������"    . "��������")
    ("��������"    . "��������")
    ("��������"    . "��������")
    ("�������"     . "�������")
    ("�������"     . "�������")
    ("�����"       . "�����")
    ("�����"       . "�����")
    ("��������"    . "��������")
;;; END COMMAND MAP
  )
)


;;; ==============================================================================================
;;;           2. ������� � ������� �� ����� ������
;;; ==============================================================================================

;;; START MAIN KEYS
(setq *main-command-keys* '("��������" "��������" "��������" "�������" "�������" "�����" "�����" "��������" "pps_back"))
;;; END MAIN KEYS

;;; START SITUACIA KEYS
(setq *situacia-command-keys* '("km" "slope" "vpo" "dims" "qe" "qec" "addtoblock" "ndel" "ncut" "nmove" "label" "delblocks" "ww" "calc" "wf" "wfb" "DIt" "etr" "etr1" "PJ" "STRELKA" "loadlineM" "tkm" "MTA" "Bind-Detach" "MTB" "back"))
;;; END SITUACIA KEYS

;;; START NAPRECHNI KEYS
(setq *naprechni-command-keys* '("d3" "a3" "a3a" "km" "otkos" "naklon" "dimc" "qe" "qec" "Ln" "L�" "addtoblock" "ndel" "ncut" "nmove" "delblocks" "calc" "wf" "wfb" "laq" "DIt" "regATT" "regATT2" "regATTall" "ATTCH" "a3all" "D3all" "D3all2" "d3RO" "QBZ" "QALL" "QB" "back"))
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
(setq *drugi-command-keys* '("ETR" "BATCHETR" "BATCHPDF" "BATCHPDF2" "getv" "getversions" "meters" "BS" "SHOWLAYERS" "kmAll" "kmDel" "template" "LayerChange" "regAttAll" "pcoord" "rtl" "back"))
;;; END DRUGI KEYS

;;; START CIVIL KEYS
(setq *civil-command-keys* '("slg" "s2p" "s2f" "flkm" "bExp" "bExp2" "pExp" "regV" "regH" "regC" "regS" "kmATT" "GRR" "GRR2" "cPExp" "back"))
;;; END CIVIL KEYS

;;; START REGISTRI KEYS
(setq *registri-command-keys* '("bExp" "pExp" "regV" "regH" "regC" "regS" "regS2" "regHro" "regVro" "regCro" "cPExp" "back"))
;;; END REGISTRI KEYS


;;; ==============================================================================================
;;;                  3. ������ C: ������� �� ����� ������
;;; ==============================================================================================
(defun ETP-ShowDialog-Universal (dcl_name key_list / dcl_id *error* key)
  (defun *error* (msg) (if (and dcl_id (>= dcl_id 0)) (unload_dialog dcl_id)) (princ (strcat "\n������: " msg)) (princ))
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
(defun C:�������� () (create_dclhelplisp�������� "help��������") (ETP-ShowDialog-Universal "help��������" *situacia-command-keys*))
(defun C:�������� () (create_dclhelplisp�������� "help��������") (ETP-ShowDialog-Universal "help��������" *naprechni-command-keys*))
(defun C:�������� () (create_dclhelplisp�������� "help��������") (ETP-ShowDialog-Universal "help��������" *nadlazhni-command-keys*))
(defun C:������� () (create_dclhelplisp������� "help�������") (ETP-ShowDialog-Universal "help�������" *blokove-command-keys*))
(defun C:������� () (create_dclhelplisp������� "help�������") (ETP-ShowDialog-Universal "help�������" *layouts-command-keys*))
(defun C:����� () (create_dclhelplisp����� "help�����") (ETP-ShowDialog-Universal "help�����" *drugi-command-keys*))
(defun C:����� () (create_dclhelplisp����� "help�����") (ETP-ShowDialog-Universal "help�����" *civil-command-keys*))
(defun C:�������� () (create_dclhelplisp�������� "help��������") (ETP-ShowDialog-Universal "help��������" *registri-command-keys*))

(princ "\n�������, ����������� � ������������ ������ �� Lisp ����� � ��������.")
(princ)
##################################################################################################
##################################################################################################
##################################################################################################
##################################################################################################
##################################################################################################
##################################################################################################
##################################################################################################
