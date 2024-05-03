#Requires AutoHotkey v2.0
#SingleInstance Force
#Include lib\Gdip_All.ahk
pToken := Gdip_Startup()

WS_EX_LAYERED := 0x80000, WS_EX_TOPMOST := 0x8, WS_EX_TOOLWINDOW := 0x80
EXStyle := WS_EX_LAYERED | WS_EX_TOPMOST | WS_EX_TOOLWINDOW
;; Gui
GM := Gui("+E" EXStyle " -Caption")
GM.Show()
GM.AddText("vMove x0 y0 w500 h30")
GM.AddText("vView x13 y42 w90 h30")
GM.AddText("vCopy x113 y42 w90 h30")
w:=216,ho:=85
hbm := CreateDIBSection(w, ho+100)
hdc := CreateCompatibleDC()
obm := SelectObject(hdc, hbm)
G := Gdip_GraphicsFromHDC(hdc)
Gdip_SetSmoothingMode(G, 2), Gdip_SetInterpolationMode(G, 7)
UpdateLayeredWindow(GM.hWnd, hdc, A_ScreenWidth//2-w//2, A_ScreenHeight//2-ho//2, w, ho+100)
drawWindow()

drawWindow(p*) {
    Gdip_GraphicsClear(G)
    ;; titleBar
    h := IsSet(HBitmapClip) && HBitmapClip && !p.has(1) ? ho + 100 : ho
	pBrush := Gdip_BrushCreateSolid("0xFFF24646"), Gdip_FillRoundedRectanglePath(G, pBrush, 8, 0, w-16, 30, 12), Gdip_FillRectangle(G, pBrush, 8, 13, w-16, 20), Gdip_DeleteBrush(pBrush)
	Gdip_TextToGraphics(G, "BASE64", "x23 y8 s15 cffffffff Bolder","Arial", w-16, 30)

	;;Background
	Gdip_FillRectangle(G, pBrush := Gdip_BrushCreateSolid("0xFF131416"), 8, 32, w-16, h-42), Gdip_FillRoundedRectanglePath(G, pBrush, 8, h-20, w-16, 20, 12),Gdip_DeleteBrush(pBrush)

    ;;Buttons
    Gdip_FillRoundedRectanglePath(G, pBrush := Gdip_BrushCreateSolid("0xFFF24646"), 13, 42, 90, 30, 8), Gdip_DeleteBrush(pBrush)
    Gdip_TextToGraphics(G, "View", "x13 y44 s20 Center vCenter cFFFFFFFF","Arial", 90, 30)
    Gdip_FillRoundedRectanglePath(G, pBrush := Gdip_BrushCreateSolid("0xFFF24646"), 113, 42, 90, 30, 8), Gdip_DeleteBrush(pBrush)
    Gdip_TextToGraphics(G, "Copy", "x113 y44 s20 Center vCenter cFFFFFFFF","Arial", 90, 30)

    ;; image
    if IsSet(HBitmapClip) && HBitmapClip {
        pBM := Gdip_CreateBitmapFromHBITMAP(HBitmapClip)
        if pBM {
        Gdip_GetImageDimensions(pBM, &iw, &ih)
        iScale := Min(200/iw, 95/ih)
        iw *= iScale, ih *= iScale
        Gdip_DrawImage(G, pBM, w//2-iw/2, 80, iw, ih), Gdip_DisposeImage(pBM)
        }
    }

    UpdateLayeredWindow(GM.hwnd, hdc)
    OnMessage(0x201, WM_LBUTTONDOWN)
    WM_LBUTTONDOWN(*) {
        global HBitmapClip
        mouseGetPos ,,, &hCtrl, 2
        if !hCtrl
            return
        switch GM[hCtrl].name, 0 {
            case "Move":PostMessage(0xA1,2)
            case "View":
            DllCall("OpenClipboard", "uint", 0)
            hBitmapClip := DllCall("GetClipboardData", "uint", 0x2)
            DllCall("CloseClipboard")
            if !hBitmapClip
                pBM:=Gdip_BitmapFromBase64(A_Clipboard),
                pBM > 0 ? hBitmapClip := Gdip_CreateHBITMAPFromBitmap(pBM) : MsgBox("Not a valid b64 string in clip",,0x40010), Gdip_DisposeImage(pBM)
            drawWindow()
            case "Copy":
                DllCall("OpenClipboard", "uint", 0)
                hBitmapClip := DllCall("GetClipboardData", "uint", 0x2)
                DllCall("CloseClipboard")
                if !hBitmapClip
                    return MsgBox("No image in clipboard",,0x40010)
                pBMC := Gdip_CreateBitmapFromHBITMAP(hBitmapClip)
                A_Clipboard := Gdip_EncodeBitmapTo64string(pBMC)
                Gdip_DisposeImage(pBMC)
                drawWindow(1)
        }
    }
}