#cs
UDF legt Standard TrayItems fest
an Platz 101 - Pause
an Platz 102 - Beenden
Zusätzliche 'TrayCreateItem' im Hauptskript müssen mit Parameter 'menuentry' aufsteigend ab '0' definiert werden oder werden sonst hinten drangehängt.

es gibt eine Option für den linken Doppelklick
$bPfadHoeher = False [Standard] - es wird @ScriptDir im Explorer geöffnet
$bPfadHoeher = True - es wird eine Ebene hoeher als @ScriptDir im Explorer geöffnet		- diese Variable muß im Hauptskript dann neu eingetragen werden
#ce
#include-once
#include<ResourcesEx.au3> ; nötig zum Extrahieren der Source
#include <Array.au3> ; nötig für Ausgeben der Parameter
#include <WinAPI.au3> ; nötig für Ausgeben der Parameter
#include <TrayConstants.au3>

#Region Opt TrayIcon
Opt("TrayAutoPause", 0) ; keine Auto-Pause bei anklicken
Opt("TrayMenuMode", 11) ; "1" Standard Traymenüeinträge (Skript pausieren/beenden) werden nicht angezeigt + "2" Haken werden nicht gesetzt = "3"	+8 = schaltet die automatische Überprüfung von Radioelementgruppen ab
Opt("TrayOnEventMode", 1); Wenn aktiviert funktioniert TrayGetMsg() nicht mehr, dafür werden TrayEvents sofort gezündet
#EndRegion Opt TrayIcon

Global $g_iParamterHelpStartIndex = 0; wird benötigt, wenn später (im Hauptscript) weitere Parameter dazukommen, um die Wiedergabe des Helpfile ab diesem Index fortzuführen
Global $g_aParameterHelpfile[0][2]
_ArrayAdd($g_aParameterHelpfile, "--help;shows help file", 0, ";") ; Delimiter ist ;, da | später für StringRegExp benötigt wird
_ArrayAdd($g_aParameterHelpfile, "--extract|--extrakt|--source|--quelle|--code|--au3;extracts source code to @ScriptDir", 0, ";")
_ArrayAdd($g_aParameterHelpfile, "--strip|--stripped;extracts stripped source code to @ScriptDir if available", 0, ";")
_ArrayAdd($g_aParameterHelpfile, "--nohelp;should be as an error --help in $cmdlineraw you can reject --help", 0, ";")
_ShowHelp($g_iParamterHelpStartIndex)
#cs ; bei weiteren Einträgen von Parametern folgende Zeilen im Hauptscript nutzen
$g_iParamterHelpStartIndex = _ArrayAdd($g_aParameterHelpfile, "l|list;was dazu im Hauptscript", 0, ";")
_ArrayAdd($g_aParameterHelpfile, "z|zappel;ein weiterer Eintrag im Hauptscript", 0, ";")
_ShowHelp($g_iParamterHelpStartIndex, 1) ; diese Zeile erst nach Eintragung aller zusätzlichen Parameter schreiben - 1 beendet das Hauptscript nach dem Ausgeben aller Parameter
#ce

_ExtractSource() ; extrahiert die Source wenn $cmdlineraw stimmt

Global $bPaused
Global $bPfadHoeher = False ; als Standard definiert - kann jedoch im Hauptskript auf True gesetzt werden

#Region ### START Tray section
Global $hInfo = TrayCreateItem("Info", -1, 98) ; menuentry 98, um darüber viel Platz für neue im Hauptskript zu haben
TrayItemSetOnEvent (-1, "_Info")
Global $hPfad = TrayCreateItem("Pfad " & ChrW(246) & "ffnen", -1, 99) ; menuentry 99, um darüber viel Platz für neue im Hauptskript zu haben
TrayItemSetOnEvent (-1, "_OpenPath")
TrayCreateItem("", -1, 100) ; Leerzeile
Global $hPause = TrayCreateItem("Pause", -1, 101) ; menuentry 101, um darüber viel Platz für neue im Hauptskript zu haben
TrayItemSetOnEvent (-1, "_AdlibPause")
Global $hBeenden = TrayCreateItem("Beenden", -1 , 102) ; menuentry 102 nachfolgend 101
TrayItemSetOnEvent (-1, "_Beenden")
TraySetState(1) ; zeigt das Icon
TraySetClick(16) ; TrayMenu öffnet sich bei Loslassen der rechten Maustaste
TraySetOnEvent( $TRAY_EVENT_PRIMARYDOUBLE, "_OpenPath" ) ; Doppelklick mit linker Maustaste
#EndRegion ### END Tray section

Func _ShowHelp($iIndex = 0, $bExit = 0) ; Index wird benutzt, um später weitere Parameter hinzuzufügen und das Schreiben des Helpfiles ab diesem Index fortzuführen
	If StringRegExp($cmdlineraw, "(?i)(" & $g_aParameterHelpfile[0][0] & ")") Then ; --help shows array in console out
		ConsoleWrite($g_aParameterHelpfile[0][0] & @CRLF) ; for debugging in SciTE
		If StringInStr($cmdlineraw, "--nohelp") Then ; sollte im $cmdlineraw fehlerhaft --help drin sein kann es hiermit gestoppt werden
			ConsoleWrite("--nohelp" & @CRLF)
			Return
		EndIf
		If $iIndex = 0 Then _WinAPI_AttachConsole() ; nur einmal attachen
		Local $hConsole = _WinAPI_GetStdHandle(1)
		If $iIndex = 0 Then _WinAPI_WriteConsole($hConsole, @CRLF) ; eine Leerzeile, um unter das Prompt zu rutschen
		For $i = $iIndex To UBound($g_aParameterHelpfile) -1
			_WinAPI_WriteConsole($hConsole, StringReplace($g_aParameterHelpfile[$i][0], "|", ", ") & ": " & $g_aParameterHelpfile[$i][1] & @CRLF) ; ersetzt außerdem "|" durch ", "
		Next
		If $bExit = 1 Then
			_WinAPI_FreeConsole()
			MsgBox(0, @ScriptName, "Wegen Start mit Parameter --help wird das Programm jetzt beendet." & @CRLF & @CRLF & "Mit Parameter --nohelp kann das aufgehoben werden.")
			Exit
		EndIf
	EndIf
EndFunc

Func _WinAPI_FreeConsole() ; fehlt interessanterweise in der WinAPI.au3 - provided by spudw2k
    Local $aResult = DllCall("kernel32.dll", "bool", "FreeConsole")
    If @error Then Return SetError(@error, @extended, False)
    Return $aResult[0]
EndFunc   ;==>_WinAPI_FreeConsole

Func _ExtractSource()
		Local $sInputExe, $sResNameOrID, $sFilePathAu3, $bReturn, $sErrorAddon
		If StringRegExp($cmdlineraw, "(?i)(" & $g_aParameterHelpfile[1][0] & ")") Then
			ConsoleWrite($g_aParameterHelpfile[1][0] & @CRLF) ; for debugging in SciTE
			$sInputExe = @ScriptFullPath
			$sResNameOrID = 999
			$sFilePathAu3 = StringLeft(@ScriptFullPath, StringInStr(@ScriptFullPath, ".", 0, - 1) - 1) & "_extracted_source.au3"
			$bReturn = _Resource_SaveToFile($sFilePathAu3, $sResNameOrID, Default, Default, Default, $sInputExe)
			If @error = 6 Then $sErrorAddon = " - Kein Quellcode gefunden."
			MsgBox(0, 'Sourcecode', 'Extrahiert: ' & $bReturn & @CRLF & @CRLF & 'Error: ' & @error & $sErrorAddon & @CRLF & 'Extended: ' & @extended & @CRLF & @CRLF & "Pfad: " & $sFilePathAu3)
			Exit
		EndIf
		If StringRegExp($cmdlineraw, "(?i)(" & $g_aParameterHelpfile[2][0] & ")") Then
			ConsoleWrite($g_aParameterHelpfile[2][0] & @CRLF) ; for debugging in SciTE
			$sInputExe = @ScriptFullPath
			$sResNameOrID = 998
			$sFilePathAu3 = StringLeft(@ScriptFullPath, StringInStr(@ScriptFullPath, ".", 0, - 1) - 1) & "_extracted_source_stripped.au3"
			$bReturn = _Resource_SaveToFile($sFilePathAu3, $sResNameOrID, Default, Default, Default, $sInputExe)
			If @error = 6 Then $sErrorAddon = " - Kein Quellcode gefunden."
			MsgBox(0, 'Sourcecode', 'Extrahiert: ' & $bReturn & @CRLF & @CRLF & 'Error: ' & @error & $sErrorAddon & @CRLF & 'Extended: ' & @extended & @CRLF & @CRLF & "Pfad: " & $sFilePathAu3)
			Exit
		EndIf
EndFunc

#Region TrayFuncs
Func _OpenPath() ; öffnet den Ordner indem des Skript enthalten ist oder eine Ebene hoeher
	Local $sPfad = @ScriptDir
	If $bPfadHoeher = True Then ; schaltet Ebene hoeher
		Local $iDelimiterPfad = StringInStr($sPfad, "\", 0, -1)
		$sPfad = StringLeft($sPfad, $iDelimiterPfad - 1)
	EndIf
	ShellExecute($sPfad) ; öffnet den Ordner
	Local $iDelimiterFolder = StringInStr($sPfad, "\", 0, -1)
	Local $sFolder = StringTrimLeft($sPfad, $iDelimiterFolder)
	WinWaitActive($sFolder) ; wartet bis der Ordner geöffnet ist
	If $bPfadHoeher = False Then ; nur wenn es der Ordner des Skripts ist und nicht die Ebene höher
		Local $sScriptName = @ScriptName
		Send($sScriptName) ; markiert die eigene Datei
	EndIf
EndFunc

Func _Beenden()
	ConsoleWrite("Beenden" & @CRLF)
    Exit
EndFunc

Func _AdlibPause() ; Vorstufe zur Pause die immer antriggerbar ist
	$bPaused = Not $bPaused
	If $bPaused = True Then
		AdlibRegister("_Pause", 250) ; 250 ms ist Standard
	Else
		TraySetState (8)
		TrayItemSetState($hPause, $TRAY_UNCHECKED)
		AdlibUnRegister("_Pause")
	EndIf
EndFunc

Func _Pause()
	TraySetState (4)
	TrayItemSetState($hPause, $TRAY_CHECKED)
	ConsoleWrite("Pause" & @CRLF) ; Pause die hängen bliebe, wenn sie nicht über AdlibRegister aufgerufen wäre
    While $bPaused
		Sleep(250)
    WEnd
EndFunc

Func _Info()
	Local $file = @ScriptFullPath
	Local $sName = _Read_File_Properties($file, 0)
	Local $sVersion = _Read_File_Properties($file, 166) ; WIN_7 = 156
	Local $sCompiler = _Read_File_Properties($file, 298) ; WIN_7 = 271
	Local $sBeschreibung = _Read_File_Properties($file, 34)
	Local $sErstellt = _Read_File_Properties($file, 4)
	Local $sGroesse = _Read_File_Properties($file, 1)
	Local $sCopyright = _Read_File_Properties($file, 25)
	Local $sPfad = _Read_File_Properties($file, 194) ; WIN_7 = 177
;~ 	MsgBox(0, 'Programm-Info', "Name:" & @TAB & @TAB & $sName & @CRLF & "Version:" & @TAB & @TAB & $sVersion & @CRLF & "Compiler:" & @TAB & @TAB & $sCompiler & @CRLF & "Beschreibung:" & @TAB & $sBeschreibung & @CRLF & "Erstellt:" & @TAB & @TAB & $sErstellt & @CRLF & "Gr" & Chr(0xF6) & "sse:" & @TAB & @TAB & $sGroesse & @CRLF & "Copyright:" & @TAB & $sCopyright & @CRLF & "Pfad:" & @TAB & @TAB & $sPfad)
	MsgBox(0, 'Programm-Info', "Dateiname:" & @CRLF & $sName & @CRLF & @CRLF & "File-Version:" & @CRLF & $sVersion & @CRLF & @CRLF & "AutoIt-Version:" & @CRLF & $sCompiler & @CRLF & @CRLF & "Beschreibung:" & @CRLF & $sBeschreibung & @CRLF & @CRLF & "Erstelldatum:" & @CRLF & $sErstellt & @CRLF & @CRLF & "Dateigr" & Chr(0xF6) & "sse:" & @CRLF & $sGroesse & @CRLF & @CRLF & "Copyright:" & @CRLF & $sCopyright & @CRLF & @CRLF & "Dateipfad:" & @CRLF & $sPfad)
EndFunc

Func _Read_File_Properties($sPassed_File_Name, $iNumber_of_Property)
    Local $sDir_Name = StringRegExpReplace($sPassed_File_Name, "(^.*\\)(.*)", "\1")
    Local $sFile_Name = StringRegExpReplace($sPassed_File_Name, "^.*\\", "")
    Local $sDOS_Dir = FileGetShortName($sDir_Name, 1)
    Local $oShellApp = ObjCreate("shell.application")
    If IsObj($oShellApp) Then
        Local $oDir = $oShellApp.NameSpace($sDOS_Dir)
        If IsObj($oDir) Then
            Local $oFile = $oDir.Parsename($sFile_Name)
            If IsObj($oFile) Then
                Local $sFile_Property = $oDir.GetDetailsOf($oFile, $iNumber_of_Property)
				Return $sFile_Property
            EndIf
        EndIf
    EndIf
EndFunc   ;==>_Read_File_Properties
#EndRegion TrayFuncs