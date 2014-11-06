VERSION 5.00
Begin VB.UserControl pdTextBox 
   Appearance      =   0  'Flat
   BackColor       =   &H0080FF80&
   ClientHeight    =   975
   ClientLeft      =   0
   ClientTop       =   0
   ClientWidth     =   3015
   BeginProperty Font 
      Name            =   "Tahoma"
      Size            =   8.25
      Charset         =   0
      Weight          =   400
      Underline       =   0   'False
      Italic          =   0   'False
      Strikethrough   =   0   'False
   EndProperty
   ScaleHeight     =   65
   ScaleMode       =   3  'Pixel
   ScaleWidth      =   201
End
Attribute VB_Name = "pdTextBox"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
'***************************************************************************
'PhotoDemon Unicode Text Box control
'Copyright �2013-2014 by Tanner Helland
'Created: 03/November/14
'Last updated: 05/November/14
'Last update: continued work on initial build
'
'In a surprise to precisely no one, PhotoDemon has some unique needs when it comes to user controls - needs that
' the intrinsic VB controls can't handle.  These range from the obnoxious (lack of an "autosize" property for
' anything but labels) to the critical (no Unicode support).
'
'As such, I've created many of my own UCs for the program.  All are owner-drawn, with the goal of maintaining
' visual fidelity across the program, while also enabling key features like Unicode support.
'
'A few notes on this text box control, specifically:
'
' 1) Unlike other PD custom controls, this one is simply a wrapper to a system text box.
' 2) The idea with this control was not to expose all text box properties, but simply those most relevant to PD.
' 3) Focus is the real nightmare for this control, and as you will see, some complicated tricks are required to work
'    around VB's handling of tabstops in particular.  (Focus is still on my to-do list!)
' 4) To allow use of arrow keys and other control keys, this control must hook the keyboard.  (If it does not, VB will
'    eat control keypresses, because it doesn't know about windows created via the API!)  A byproduct of this is that
'    accelerators flat-out WILL NOT WORK while this control has focus.  I haven't yet settled on a good way to handle
'    this; what I may end up doing is manually forwarding any key combinations that use Alt to the default window
'    handler, but I'm not sure this will help.  TODO!
' 5) Dynamic hooking can occasionally cause trouble in the IDE, particularly when used with break points.  It should
'    be fine once compiled.
'
'All source code in this file is licensed under a modified BSD license.  This means you may use the code in your own
' projects IF you provide attribution.  For more information, please visit http://photodemon.org/about/license/
'
'***************************************************************************


Option Explicit

'Window styles
Private Enum enWindowStyles
    WS_BORDER = &H800000
    WS_CAPTION = &HC00000
    WS_CHILD = &H40000000
    WS_CLIPCHILDREN = &H2000000
    WS_CLIPSIBLINGS = &H4000000
    WS_DISABLED = &H8000000
    WS_DLGFRAME = &H400000
    WS_GROUP = &H20000
    WS_HSCROLL = &H100000
    WS_MAXIMIZE = &H1000000
    WS_MAXIMIZEBOX = &H10000
    WS_MINIMIZE = &H20000000
    WS_MINIMIZEBOX = &H20000
    WS_OVERLAPPED = &H0&
    WS_POPUP = &H80000000
    WS_SYSMENU = &H80000
    WS_TABSTOP = &H10000
    WS_THICKFRAME = &H40000
    WS_VISIBLE = &H10000000
    WS_VSCROLL = &H200000
    WS_EX_ACCEPTFILES = &H10&
    WS_EX_DLGMODALFRAME = &H1&
    WS_EX_NOACTIVATE = &H8000000
    WS_EX_NOPARENTNOTIFY = &H4&
    WS_EX_TOPMOST = &H8&
    WS_EX_TRANSPARENT = &H20&
    WS_EX_TOOLWINDOW = &H80&
    WS_EX_MDICHILD = &H40
    WS_EX_WINDOWEDGE = &H100
    WS_EX_CLIENTEDGE = &H200
    WS_EX_CONTEXTHELP = &H400
    WS_EX_RIGHT = &H1000
    WS_EX_LEFT = &H0
    WS_EX_RTLREADING = &H2000
    WS_EX_LTRREADING = &H0
    WS_EX_LEFTSCROLLBAR = &H4000
    WS_EX_RIGHTSCROLLBAR = &H0
    WS_EX_CONTROLPARENT = &H10000
    WS_EX_STATICEDGE = &H20000
    WS_EX_APPWINDOW = &H40000
    WS_EX_OVERLAPPEDWINDOW = (WS_EX_WINDOWEDGE Or WS_EX_CLIENTEDGE)
    WS_EX_PALETTEWINDOW = (WS_EX_WINDOWEDGE Or WS_EX_TOOLWINDOW Or WS_EX_TOPMOST)
End Enum

#If False Then
    Private Const WS_BORDER = &H800000, WS_CAPTION = &HC00000, WS_CHILD = &H40000000, WS_CLIPCHILDREN = &H2000000, WS_CLIPSIBLINGS = &H4000000, WS_DISABLED = &H8000000, WS_DLGFRAME = &H400000, WS_EX_ACCEPTFILES = &H10&, WS_EX_DLGMODALFRAME = &H1&, WS_EX_NOPARENTNOTIFY = &H4&, WS_EX_TOPMOST = &H8&, WS_EX_TRANSPARENT = &H20&, WS_EX_TOOLWINDOW = &H80&, WS_GROUP = &H20000, WS_HSCROLL = &H100000, WS_MAXIMIZE = &H1000000, WS_MAXIMIZEBOX = &H10000, WS_MINIMIZE = &H20000000, WS_MINIMIZEBOX = &H20000, WS_OVERLAPPED = &H0&, WS_POPUP = &H80000000, WS_SYSMENU = &H80000, WS_TABSTOP = &H10000, WS_THICKFRAME = &H40000, WS_VISIBLE = &H10000000, WS_VSCROLL = &H200000, WS_EX_MDICHILD = &H40, WS_EX_WINDOWEDGE = &H100, WS_EX_CLIENTEDGE = &H200, WS_EX_CONTEXTHELP = &H400, WS_EX_RIGHT = &H1000, WS_EX_LEFT = &H0, WS_EX_RTLREADING = &H2000, WS_EX_LTRREADING = &H0, WS_EX_LEFTSCROLLBAR = &H4000, WS_EX_RIGHTSCROLLBAR = &H0, WS_EX_CONTROLPARENT = &H10000, WS_EX_STATICEDGE = &H20000, WS_EX_APPWINDOW = &H40000
    Private Const WS_EX_OVERLAPPEDWINDOW = (WS_EX_WINDOWEDGE Or WS_EX_CLIENTEDGE), WS_EX_PALETTEWINDOW = (WS_EX_WINDOWEDGE Or WS_EX_TOOLWINDOW Or WS_EX_TOPMOST)
#End If

Private Const ES_AUTOHSCROLL = &H80
Private Const ES_AUTOVSCROLL = &H40
Private Const ES_CENTER = &H1
Private Const ES_LEFT = &H0
Private Const ES_LOWERCASE = &H10
Private Const ES_MULTILINE = &H4
Private Const ES_NOHIDESEL = &H100
Private Const ES_NUMBER = &H2000
Private Const ES_OEMCONVERT = &H400
Private Const ES_PASSWORD = &H20
Private Const ES_READONLY = &H800
Private Const ES_RIGHT = &H2
Private Const ES_UPPERCASE = &H8
Private Const ES_WANTRETURN = &H1000

'Updating the font is done via WM_SETFONT
Private Const WM_SETFONT = &H30

'Window creation/destruction APIs
Private Declare Function CreateWindowEx Lib "user32" Alias "CreateWindowExW" (ByVal dwExStyle As Long, ByVal lpClassName As Long, ByVal lpWindowName As Long, ByVal dwStyle As Long, ByVal x As Long, ByVal y As Long, ByVal nWidth As Long, ByVal nHeight As Long, ByVal hWndParent As Long, ByVal hMenu As Long, ByVal hInstance As Long, ByRef lpParam As Any) As Long
Private Declare Function DestroyWindow Lib "user32" (ByVal hWnd As Long) As Long

'Handle to the system edit box wrapped by this control
Private m_EditBoxHwnd As Long

'pdFont handles the creation and maintenance of the font used to render the text box.  It is also used to determine control width for
' single-line text boxes, as the control is auto-sized to fit the current font.
Private curFont As pdFont

'Rather than use an StdFont container (which requires VB to create redundant font objects), we track font properties manually,
' via dedicated properties.
Private m_FontSize As Single

'Custom subclassing is required for IME support
Private Type winMsg
    hWnd As Long
    sysMsg As Long
    wParam As Long
    lParam As Long
    msgTime As Long
    ptX As Long
    ptY As Long
End Type

'GetKeyboardState fills a [256] array with the state of all keyboard keys.  Rather than constantly redimming an array for holding those
' return values, we simply declare one array at a module level, and re-use it as necessary.
Private Declare Function GetKeyboardState Lib "user32" (ByRef pbKeyState As Byte) As Long
Private m_keyStateData(0 To 255) As Byte
Private m_OverrideDoubleCheck As Boolean

Private Declare Function ToUnicode Lib "user32" (ByVal uVirtKey As Long, ByVal uScanCode As Long, lpKeyState As Byte, ByVal pwszBuff As Long, ByVal cchBuff As Long, ByVal wFlags As Long) As Long

Private Const MAPVK_VK_TO_VSC As Long = &H0
Private Const MAPVK_VK_TO_CHAR As Long = &H2
Private Declare Function MapVirtualKey Lib "user32" Alias "MapVirtualKeyW" (ByVal uCode As Long, ByVal uMapType As Long) As Long

Private Const PM_REMOVE As Long = &H1
Private Const WM_KEYFIRST As Long = &H100
Private Const WM_KEYLAST As Long = &H108
Private Declare Function PeekMessage Lib "user32" Alias "PeekMessageW" (ByRef lpMsg As winMsg, ByVal hWnd As Long, ByVal wMsgFilterMin As Long, ByVal wMsgFilterMax As Long, ByVal wRemoveMsg As Long) As Long
Private Declare Function DispatchMessage Lib "user32" Alias "DispatchMessageW" (lpMsg As winMsg) As Long

Private Const WM_KEYDOWN As Long = &H100
Private Const WM_KEYUP As Long = &H101
Private Const WM_CHAR As Long = &H102
Private Const WM_SETFOCUS As Long = &H7
Private Const WM_KILLFOCUS As Long = &H8
Private cSubclass As cSelfSubHookCallback

'Now, for a rather lengthy explanation on these next variables, and why they're necessary.
'
'Per Wikipedia: "A dead key is a special kind of a modifier key on a typewriter or computer keyboard that is typically used to attach
' a specific diacritic to a base letter. The dead key does not generate a (complete) character by itself but modifies the character
' generated by the key struck immediately after... For example, if a keyboard has a dead key for the grave accent (`), the French
' character � can be generated by first pressing ` and then A, whereas � can be generated by first pressing ` and then E. Usually, the
' diacritic in an isolated form can be generated with the dead key followed by space, so a plain grave accent can be typed by pressing
' ` and then Space."
'
'Dead keys are a huge PITA in Windows.  As an example of how few people have cracked this problem, see:
' http://stackoverflow.com/questions/2604541/how-can-i-use-tounicode-without-breaking-dead-key-support
' http://stackoverflow.com/questions/1964614/toascii-tounicode-in-a-keyboard-hook-destroys-dead-keys
' http://stackoverflow.com/questions/3548932/keyboard-hook-changes-the-behavior-of-keys
' http://stackoverflow.com/questions/15488682/double-characters-shown-when-typing-special-characters-while-logging-keystrokes
'
'Because of this mess, we must do a fairly significant amount of custom processing to make sure dead keys are handled correctly.
'
'The problem, in a nutshell, is that Windows provides one function pair for processing a string of keypresses into a usable character:
' ToUnicode/ToUnicodeEx.  These functions have the unenviable job of taking a string of virtual keys (including all possible modifiers),
' comparing them against the thread's active keyboard layout, and returning one or more Unicode characters resulting from those keypresses.
' For some East Asian languages, a half-dozen keypresses can be chained together to form a single glyph, so this task is not a simple one,
' and it is DEFINITELY not something a sole programmer could ever hope to reverse-engineer.
'
'In an attempt to be helpful, Microsoft engineers decided that when ToUnicode successfully detects and returns a glyph, it will also
' purge the current key buffer of any keystrokes that were used to generate said glyph.  This is fine if you intend to immediately return
' the glyph without further processing, but then the engineers did something truly asinine - they also made ToUnicode the recommended way
' to check for dead keys!  ToUnicode returns -1 if it determines that the current keystroke pattern consists of only dead keys, and you can
' use that return value to detect times when you shouldn't raise a character press (because you're waiting for the rest of the dead key
' pattern to arrive).  The problem?  *As soon as you use ToUnicode to check the dead key state, the dead key press is permanently removed
' from the key buffer!*  AAARRRRGGGHHH @$%@#$^&#$
'
'After a painful amount of trial and error, I have devised the following system for working around this mess.  Whenever ToUnicode returns
' a -1 (indicating a dead keypress), PD makes a full copy of the dead key keyboard state, including scan codes and a full key map.  On a
' subsequent keypress, all that dead key information is artificially inserted into the key buffer, then ToUnicode is used to analyze
' this artificially constructed buffer.
'
'This is not pretty in any way, but the code is quite concise, and this is a resolution that thousands of other angry programmers
' were unable to locate - so I'm counting myself lucky and not obsessing over the inelegance of it.
'
'Anyway, these module-level variables are used to cache dead key values until they are actually needed.
Private m_DeadCharVal As Long
Private m_DeadCharScanCode As Long
Private m_DeadCharKeyStateData(0 To 255) As Byte

'Dynamic hooking requires us to track focus events with care.  When focus is lost, we must relinquish control of the keyboard.
' This value will be set to TRUE if the tracked object currently has focus.
Private m_HasFocus As Boolean

'Additional helpers for rendering themed and multiline tooltips
Private m_ToolTip As clsToolTip
Private m_ToolString As String

'hWnds aren't exposed by default
Public Property Get hWnd() As Long
    hWnd = UserControl.hWnd
End Property

'Container hWnd must be exposed for external tooltip handling
Public Property Get containerHwnd() As Long
    containerHwnd = UserControl.containerHwnd
End Property

'Font properties; only a subset are used, as PD handles most font settings automatically
Public Property Get FontSize() As Single
    FontSize = m_FontSize
End Property

Public Property Let FontSize(ByVal newSize As Single)
    If newSize <> m_FontSize Then
        m_FontSize = newSize
        refreshFont
    End If
End Property

'When the user control is hidden, we must hide the edit box window as well
' TODO!
Private Sub UserControl_Hide()
    
    
    
End Sub

Private Sub UserControl_Initialize()

    m_EditBoxHwnd = 0
    
    Set curFont = New pdFont
    m_FontSize = 10
    
    'Create an initial font object
    refreshFont
    
    'At run-time, initialize a subclasser
    If g_UserModeFix Then Set cSubclass = New cSelfSubHookCallback
    
End Sub

Private Sub UserControl_InitProperties()
    FontSize = 10
End Sub

Private Sub UserControl_ReadProperties(PropBag As PropertyBag)

    With PropBag
        FontSize = .ReadProperty("FontSize", 10)
    End With

End Sub

'When the user control is resized, the text box must be resized to match
' TODO: use a single helper function for calculating the edit box window rect.  We may want to draw our own border around the text box,
' for theming purposes, so we don't want multiple functions calculating their own window rect.
Private Sub UserControl_Resize()

    If m_EditBoxHwnd <> 0 Then
        MoveWindow m_EditBoxHwnd, 0, 0, UserControl.ScaleWidth, UserControl.ScaleHeight, 1
    End If

End Sub

'TODO: When the user control is shown, we must show the edit box window as well
Private Sub UserControl_Show()

    'If we have not yet created the edit box, do so now
    If m_EditBoxHwnd = 0 Then
    
        If Not createEditBox() Then Debug.Print "Edit box could not be created!"
    
    'The edit box has already been created, so we just need to show it
    Else
    
    End If
    
    'When the control is first made visible, remove the control's tooltip property and reassign it to the checkbox
    ' using a custom solution (which allows for linebreaks and theming).  Note that this has the ugly side-effect of
    ' permanently erasing the extender's tooltip, so FOR THIS CONTROL, TOOLTIPS MUST BE SET AT RUN-TIME!
    '
    'TODO!  Add helper functions for setting the tooltip to the created hWnd, instead of the VB control
    m_ToolString = Extender.ToolTipText

    If m_ToolString <> "" Then

        Set m_ToolTip = New clsToolTip
        With m_ToolTip

            .Create Me
            .MaxTipWidth = PD_MAX_TOOLTIP_WIDTH
            .AddTool Me, m_ToolString
            Extender.ToolTipText = ""

        End With

    End If

End Sub

'As the wrapped system edit box may need to be recreated when certain properties are changed, this function is used to
' automate the process of destroying an existing window (if any) and recreating it anew.
Private Function createEditBox() As Boolean

    'If the edit box already exists, kill it
    destroyEditBox
    
    'Figure out which flags to use, based on the control's properties
    Dim flagsWinStyle As Long, flagsWinStyleExtended As Long, flagsEditControl As Long
    flagsWinStyle = WS_VISIBLE Or WS_CHILD
    flagsWinStyleExtended = 0
    flagsEditControl = ES_AUTOHSCROLL Or ES_AUTOVSCROLL Or ES_MULTILINE 'Or ES_NOHIDESEL
    
    m_EditBoxHwnd = CreateWindowEx(flagsWinStyleExtended, ByVal StrPtr("EDIT"), ByVal StrPtr(""), flagsWinStyle Or flagsEditControl, _
        0, 0, UserControl.ScaleWidth, UserControl.ScaleHeight, UserControl.hWnd, 0, App.hInstance, ByVal 0&)
    
    'Assign a subclasser to enable IME support
    If g_UserModeFix Then
        If Not cSubclass Is Nothing Then
            cSubclass.ssc_Subclass m_EditBoxHwnd, 0, 1, Me, True, True, True
            cSubclass.ssc_AddMsg m_EditBoxHwnd, MSG_BEFORE, WM_KEYDOWN, WM_SETFOCUS, WM_KILLFOCUS
        Else
            Debug.Print "subclasser could not be initialized for text box!"
        End If
    End If
        
    
    'Assign the default font to the edit box
    refreshFont True
    
    'Return TRUE if successful
    createEditBox = (m_EditBoxHwnd <> 0)

End Function

Private Function destroyEditBox() As Boolean

    If m_EditBoxHwnd <> 0 Then
        If Not cSubclass Is Nothing Then cSubclass.ssc_UnSubclass m_EditBoxHwnd
        DestroyWindow m_EditBoxHwnd
    End If
    
    destroyEditBox = True

End Function

Private Sub UserControl_Terminate()
    
    'Destroy the edit box, as necessary
    destroyEditBox
    
    'Release any extra subclasser(s)
    If Not cSubclass Is Nothing Then cSubclass.ssc_Terminate
    
End Sub

'When the font used for the edit box changes in some way, it can be recreated (refreshed) using this function.  Note that font
' creation is expensive, so it's worthwhile to avoid this step as much as possible.
Private Sub refreshFont(Optional ByVal forceRefresh As Boolean = False)
    
    Dim fontRefreshRequired As Boolean
    fontRefreshRequired = curFont.hasFontBeenCreated
    
    'Update each font parameter in turn.  If one (or more) requires a new font object, the font will be recreated as the final step.
    
    'Font face is always set automatically, to match the current program-wide font
    If (Len(g_InterfaceFont) > 0) And (StrComp(curFont.getFontFace, g_InterfaceFont, vbBinaryCompare) <> 0) Then
        fontRefreshRequired = True
        curFont.setFontFace g_InterfaceFont
    End If
    
    'In the future, I may switch to GDI+ for font rendering, as it supports floating-point font sizes.  In the meantime, we check
    ' parity using an Int() conversion, as GDI only supports integer font sizes.
    If Int(m_FontSize) <> Int(curFont.getFontSize) Then
        fontRefreshRequired = True
        curFont.setFontSize m_FontSize
    End If
        
    'Request a new font, if one or more settings have changed
    If fontRefreshRequired Or forceRefresh Then
        curFont.createFontObject
        
        'Whenever the font is recreated, we need to reassign it to the text box.  This is done via the WM_SETFONT message.
        If m_EditBoxHwnd <> 0 Then SendMessage m_EditBoxHwnd, WM_SETFONT, curFont.getFontHandle, IIf(UserControl.Extender.Visible, 1, 0)
        
    End If
    
    'Also, the back buffer needs to be rebuilt to reflect the new font metrics
    'updateControlSize

End Sub

Private Sub UserControl_WriteProperties(PropBag As PropertyBag)

    'Store all associated properties
    With PropBag
        .WriteProperty "FontSize", m_FontSize, 10
    End With
    
End Sub

'External functions can call this to request a redraw.  This is helpful for live-updating theme settings, as in the Preferences dialog.
Public Sub updateAgainstCurrentTheme()
    
    If g_UserModeFix Then
        
        'Update the current font, as necessary
        refreshFont
        
        'Force an immediate repaint
        'updateControlSize
                
    End If
    
End Sub

'Given a virtual keycode, return TRUE if the keycode is a command key that must be manually forwarded to an edit box.  Command keys include
' arrow keys at present, but in the future, additional keys can be added to this list.
'
'NOTE FOR OUTSIDE USERS!  These key constants are declared publicly in PD, because they are used many places.  You can find virtual keycode
' declarations in PD's Public_Constants module, or at this MSDN link:
' http://msdn.microsoft.com/en-us/library/windows/desktop/dd375731%28v=vs.85%29.aspx
Private Function doesVirtualKeyRequireSpecialHandling(ByVal vKey As Long) As Boolean
    
    Select Case vKey
    
        Case VK_LEFT, VK_UP, VK_RIGHT, VK_DOWN
            doesVirtualKeyRequireSpecialHandling = True
        
        Case Else
            doesVirtualKeyRequireSpecialHandling = False
    
    End Select
    
End Function

'This routine MUST BE KEPT as the next-to-last routine for this form. Its ordinal position determines its ability to hook properly.
Private Sub myHookProc(ByVal bBefore As Boolean, ByRef bHandled As Boolean, ByRef lReturn As Long, ByVal nCode As Long, ByVal wParam As Long, ByVal lParam As Long, ByVal lHookType As eHookType, ByRef lParamUser As Long)
'*************************************************************************************************
' http://msdn2.microsoft.com/en-us/library/ms644990.aspx
'* bBefore    - Indicates whether the callback is before or after the next hook in chain.
'* bHandled   - In a before next hook in chain callback, setting bHandled to True will prevent the
'*              message being passed to the next hook in chain and (if set to do so).
'* lReturn    - Return value. For Before messages, set per the MSDN documentation for the hook type
'* nCode      - A code the hook procedure uses to determine how to process the message
'* wParam     - Message related data, hook type specific
'* lParam     - Message related data, hook type specific
'* lHookType  - Type of hook calling this callback
'* lParamUser - User-defined callback parameter. Change vartype as needed (i.e., Object, UDT, etc)
'*************************************************************************************************
    
    
    If lHookType = WH_KEYBOARD Then
    
        bHandled = False
        
        'MSDN states that negative codes must be passed to the next hook, without processing
        ' (see http://msdn.microsoft.com/en-us/library/ms644984.aspx)
        If nCode >= 0 Then
        
            'Before proceeding, cache the status of all 256 keyboard keys.  This is important for non-Latin keyboards, which can
            ' produce Unicode characters in a variety of ways.  (For example, by holding down multiple keys at once.)  If we end
            ' up forwarding a key event to the default WM_KEYDOWN handler, it will need this information in order to parse any
            ' IME input.
            GetKeyboardState m_keyStateData(0)
            
            'Bit 31 of lParam is 0 if a key is being pressed, and 1 if it is being released.  We use this to raise
            ' separate KeyDown and KeyUp events, as necessary.
            If lParam < 0 Then
            
                'The default key handler works just fine for character keys.  However, dialog keys (e.g. arrow keys) get eaten
                ' by VB, so we must manually catch them in this hook, and forward them direct to the edit control.
                If doesVirtualKeyRequireSpecialHandling(wParam) Then
                
                    'WM_KEYUP requires that certain bits be set.  See http://msdn.microsoft.com/en-us/library/windows/desktop/ms646281%28v=vs.85%29.aspx
                    If ((lParam And 1) <> 0) And ((lParam And 3) = 1) Then
                        SendMessage m_EditBoxHwnd, WM_KEYUP, wParam, ByVal (lParam And &HDFFFFF81 Or &HC0000000)
                        bHandled = True
                    End If
                
                End If
                
            Else
            
                'The default key handler works just fine for character keys.  However, dialog keys (e.g. arrow keys) get eaten
                ' by VB, so we must manually catch them in this hook, and forward them direct to the edit control.
                If doesVirtualKeyRequireSpecialHandling(wParam) Then
                
                    'WM_KEYDOWN requires that certain bits be set.  See http://msdn.microsoft.com/en-us/library/windows/desktop/ms646280%28v=vs.85%29.aspx
                    SendMessage m_EditBoxHwnd, WM_KEYDOWN, wParam, ByVal (lParam And &H51111111)
                    bHandled = True
                    
                End If
                
            End If
            
        End If
                
        'Per MSDN, return the value of CallNextHookEx, contingent on whether or not we handled the keypress internally.
        ' Note that if we do not manually handle a keypress, this behavior allows the default keyhandler to deal with
        ' the pressed keys (and raise its own WM_CHAR events, etc).
        If (Not bHandled) Then
            lReturn = CallNextHookEx(0, nCode, wParam, ByVal lParam)
        Else
            lReturn = 1
        End If
            
    End If
    
End Sub

'All events subclassed by this window are processed here.
Private Sub myWndProc(ByVal bBefore As Boolean, _
                      ByRef bHandled As Boolean, _
                      ByRef lReturn As Long, _
                      ByVal lng_hWnd As Long, _
                      ByVal uMsg As Long, _
                      ByVal wParam As Long, _
                      ByVal lParam As Long, _
                      ByRef lParamUser As Long)
'*************************************************************************************************
'* bBefore    - Indicates whether the callback is before or after the original WndProc. Usually
'*              you will know unless the callback for the uMsg value is specified as
'*              MSG_BEFORE_AFTER (both before and after the original WndProc).
'* bHandled   - In a before original WndProc callback, setting bHandled to True will prevent the
'*              message being passed to the original WndProc and (if set to do so) the after
'*              original WndProc callback.
'* lReturn    - WndProc return value. Set as per the MSDN documentation for the message value,
'*              and/or, in an after the original WndProc callback, act on the return value as set
'*              by the original WndProc.
'* lng_hWnd   - Window handle.
'* uMsg       - Message value.
'* wParam     - Message related data.
'* lParam     - Message related data.
'* lParamUser - User-defined callback parameter. Change vartype as needed (i.e., Object, UDT, etc)
'*************************************************************************************************
    
    'Now comes a really messy bit of VB-specific garbage.
    '
    'Normally, a Unicode window (e.g. one created with CreateWindowW/ExW) automatically receives Unicode window messages.
    ' Keycodes are an exception to this, because they use a unique message chain that also involves the parent window
    ' of the Unicode window - and in the case of VB, that parent window's message pump is *not* Unicode-aware, so it
    ' doesn't matter that our window *is*!
    '
    'Why involve the parent window in the keyboard processing chain?  In a nutshell, an initial WM_KEYDOWN message contains only
    ' a virtual key code (which can be thought of as representing the ID of a physical keyboard key, not necessarily a specific
    ' character or letter).  This virtual key code must be translated into either a character or an accelerator, based on the use
    ' of Alt/Ctrl/Shift/Tab etc keys, any IME mapping, other accessibility features, and more.  In the case of accelerators, the
    ' parent window must be involved in the translation step, because it is most likely the window with an accelerator table (as
    ' would be used for menu shortcuts, among other things).  So a child window can't avoid its parent window being involved in
    ' key event handling.
    '
    'Anyway, the moral of the story is that we have to do a shitload of extra work to bypass the default message translator.
    ' Without this, IME entry methods (easily tested via the Windows on-screen keyboard and some non-Latin language) result in
    ' ???? chars, despite use of a Unicode window - and that ultimately defeats the whole point of a Unicode text box, no?
    Select Case uMsg
        
        'Manually dispatch WM_KEYDOWN messages
        Case WM_KEYDOWN
            
            'Because we will be dispatching our own WM_CHAR messages with any processed Unicode characters, we must manually
            ' assemble a full window message.  All messages will be sent to the API edit box we've created, so we can mark the
            ' message's hWnd and message type just once, at the start of the dispatch loop.
            Dim tmpMsg As winMsg
            tmpMsg.hWnd = m_EditBoxHwnd
            tmpMsg.sysMsg = WM_CHAR
            
            'Normally, we would next retrieve the status of all 256 keyboard keys.  However, our hook proc, above, has already
            ' done this for us.  The results are cached inside m_keyStateData().
            
            'Next, we need to prepare a string buffer to receive the Unicode translation of the current virtual key.
            ' This is tricky because ToUnicode/Ex do not specify a max buffer size they may write.  Michael Kaplan's
            ' definitive article series on this topic (dead link on MSDN; I found it here: http://www.siao2.com/2006/03/23/558674.aspx)
            ' uses a 10-char buffer.  That should be sufficient for our purposes as well.
            Dim tmpString As String
            tmpString = String$(10, vbNullChar)
            
            Dim unicodeResult As Long, tmpLong As Long
            
            'Before proceeding, see if a dead key was pressed.  Per MapVirtualKey's documentation (http://msdn.microsoft.com/en-us/library/windows/desktop/ms646306%28v=vs.85%29.aspx)
            ' "Dead keys (diacritics) are indicated by setting the top bit of the return value," we we can easily check in VB
            ' as it will seem to be a negative number.
            '
            'Because it is not possible to detect a dead char via ToUnicode without also removing that char from the key buffer, this
            ' is the only safe way (I know of) to detect and preprocess dead chars.  Note also that we SKIP THIS STEP if we already
            ' have a dead char in the buffer.  This allows repeat presses of a dead key (e.g. `` on a U.S. International keyboard) to
            ' pass through as double characters, which is the expected behavior.
            If (MapVirtualKey(wParam, MAPVK_VK_TO_CHAR) < 0) And (m_DeadCharVal = 0) Then
                
                'A dead key was pressed.  Rather than send this character to the edit box immediately (which defeats the whole
                ' purpose of a dead key!), we will make a note of it, and reinsert it to the key queue on a subsequent WM_KEYDOWN.
                
                'Update our stored dead key values
                m_DeadCharVal = wParam
                m_DeadCharScanCode = MapVirtualKey(wParam, MAPVK_VK_TO_VSC)
                GetKeyboardState m_DeadCharKeyStateData(0)
                
                'Setting unicodeResult to 0 prevents further processing by this proc
                unicodeResult = 0
            
            'The current key is NOT a dead char, or it is but we already have a dead char in the buffer, so we have no choice
            ' but to process it immediately.
            Else
                
                'If a dead char was initiated previously, and the current key press is NOT another dead char, insert the original
                ' dead char back into the key state buffer.  Note that we don't care about the return value, as we know it will
                ' be -1 since a dead key is being added!
                If (m_DeadCharVal <> 0) Then
                    ToUnicode m_DeadCharVal, m_DeadCharScanCode, m_DeadCharKeyStateData(0), StrPtr(tmpString), Len(tmpString), 0
                End If
                
                'Perform a Unicode translation using the pressed virtual key (wParam), a buffer of all previous relevant characters
                ' (e.g. dead chars from previous steps), and a full buffer of all current key states.
                unicodeResult = ToUnicode(wParam, MapVirtualKey(wParam, MAPVK_VK_TO_VSC), m_keyStateData(0), StrPtr(tmpString), Len(tmpString), 0)
                
                'Reset any dead character tracking
                m_DeadCharVal = 0
                
            End If
                                    
            'ToUnicode has four possible return values:
            ' -1: the char is an accent or diacritic.  If possible, it has been translated to a standalone spacing version
            '     (always a UTF-16 entry point), and placed in the output buffer.  Generally speaking, we don't want to treat
            '     this as an actual character until we receive the *next* character input.  This allows us to properly assemble
            '     mixed characters (for example `a should map to �, while `c maps to just `c - but we can't know how to use a
            '     dead key until the next keypress is received).  This behavior is affected by the current keyboard layout.
            '
            ' 0: function failed.  This is not a bad thing; many East Asian IMEs will merge multiple keypresses into a single
            '    character, so the preceding keypresses will not return anything.
            '
            ' 1: success.  A single Unicode character was written to the buffer.
            
            ' 2+: also success.  Multiple Unicode characters were written to the buffer, typically when a matching ligature was
            '    not found for a relevant multi-glyph input.  This is a valid return, and all characters in the buffer should
            '    be sent to the text box.  IMPORTANT NOTE: the string buffer can contain more values than the return value specifies,
            '    so it's important to handle the buffer using *this return value*, and *not the buffer's actual contents*.
            
            'We will now proceed to parse the results of ToUnicode, using its return value as our guide.
            Select Case unicodeResult
            
                'Dead character, meaning an accent or other diacritic.  Because we deal with the "dead key" case explicitly
                ' in previous steps, we don't have to deal with it here.
                Case -1
                    
                    'Note that the message was handled successfully.  (This may not be necessary, but I'm including it
                    ' "just in case", to work around potential oddities in dead key handling.)
                    bHandled = True
                    lReturn = 0
                    
                'Failure; no Unicode result.  This can happen if an IME is still assembling characters, and no action
                ' is required on our part.
                Case 0
                    
                '1 or more chars were successfully processed and returned.
                Case 1 To Len(tmpString)
                    
                    'Send each processed Unicode character in turn, using DispatchMessage to completely bypass VB's
                    ' default handler.  This prevents forcible down-conversion to ANSI.
                    Dim i As Long
                    For i = 1 To unicodeResult
                        
                        'Each unprocessed character will have left a pending WM_KEYDOWN message in this window's queue.
                        ' To prevent other handlers from getting that original message (which is no longer valid), we are
                        ' going to iterate through each message in turn, replacing them with our own custom dispatches.
                        PeekMessage tmpMsg, m_EditBoxHwnd, WM_KEYFIRST, WM_KEYLAST, PM_REMOVE
                        
                        'Retrieve the unsigned Int value of this string char
                        CopyMemory tmpLong, ByVal StrPtr(tmpString) + ((i - 1) * 2), 2
                        
                        'Assemble a new window message, passing the retrieved string char as the wParam
                        tmpMsg.wParam = tmpLong
                        tmpMsg.lParam = lParam
                        tmpMsg.msgTime = GetTickCount()
                        
                        'Dispatch the message directly, bypassing TranslateMessage entirely.  NOTE!  This prevents accelerators
                        ' from working while the text box has focus, but I do not currently know a better way around this.  A custom
                        ' accelerator solution for PD would work fine, but we would need to do our own mapping from inside this proc.
                        DispatchMessage tmpMsg
                        
                    Next i
                                        
                    'Note that the message was handled successfully
                    bHandled = True
                    lReturn = 0
                
                'This case should never fire
                Case Else
                    Debug.Print "Excessively large Unicode buffer value returned: " & unicodeResult
                
            End Select
            
        'When the control receives focus, initialize a keyboard hook.  This prevents accelerators from working, but it is the
        ' only way to bypass VB's internal message translator, which will forcibly convert certain Unicode chars to ANSI.
        Case WM_SETFOCUS
        
            'Check for an existing hook
            If Not m_HasFocus Then
            
                'No hook exists.  Hook the control now.
                'Debug.Print "Installing keyboard hook for API edit box due to WM_SETFOCUS"
                cSubclass.shk_SetHook WH_KEYBOARD, False, MSG_BEFORE, m_EditBoxHwnd, 2, Me, , True
                
                'Note that this window is now active
                m_HasFocus = True
                
            Else
                Debug.Print "API edit box just gained focus, but a keyboard hook is already installed??"
            End If
        
        Case WM_KILLFOCUS
        
            'Check for an existing hook
            If m_HasFocus Then
                
                'A hook exists.  Uninstall it now.
                'Debug.Print "Uninstalling keyboard hook for API edit box due to WM_KILLFOCUS"
                cSubclass.shk_UnHook WH_KEYBOARD
                    
                'Note that this window is now considered inactive
                m_HasFocus = False
                
            Else
                Debug.Print "API edit box just lost focus, but no keyboard hook was ever installed??"
            End If
            
        'Other messages??
        Case Else
    
    End Select



' *************************************************************
' C A U T I O N   C A U T I O N   C A U T I O N   C A U T I O N
' -------------------------------------------------------------
' DO NOT ADD ANY OTHER CODE BELOW THE "END SUB" STATEMENT BELOW
'   add this warning banner to the last routine in your class
' *************************************************************
End Sub


