;change date 23.06.2020

#NoENV
SetBatchLines, -1

pToken := Gdip_Startup()
global	IMT                           	:= IniParserEx(A_ScriptDir "\IMT.ini")
global 	IMagickDir	         		:= StrReplace(IMT.ImageMagickMain.IMagickDir, "%A_ScriptDir%", A_ScriptDir)
If !FileExist(IMagickDir "\magick.exe") {

	defaultFolder := A_ScriptDir

	SelectIMagickFolder:
	FileSelectFolder, IMagickDir, % defaultFolder, 0, % "set imagemagick folder here"
	If ErrorLevel {
		ExitApp
	} else if !FileExist(IMagickDir "\magick.exe") {
		MsgBox, 4, % "This folder`n" IMagickDir "`ndoes not seem to be an imagemagick program folder!`n`nDo you want to repeat the folder selection?"
		IfMsgBox, No
			ExitApp
		goto SelectIMagickFolder
	}
	IniWrite, % IMagickDir, % A_ScriptDir "\IMT.ini", % "ImageMagickMain", % "IMagickDir"

}

global 	Originals         	     		:= PictureDir2List(A_ScriptDir "\scans", false)
global	Modifieds                 	:= PictureDir2List(A_ScriptDir "\scans", true)
global	IMOptions                	:= CreateIMOptions(IMT, "ImageMagickOptions")
global 	MagickOptions          	:= Object()
global 	Textshow
global 	q	:= Chr(0x22)

MagickCommands()
MagickGui()

return

MagickGui() {

	global

	;{ gui setup
	origPicH	:= Floor(A_ScreenHeight/1.3)
	WinX    	:= StrLen(IMT.last.WinX) = 0 ? 0 : IMT.last.WinX
	WinY    	:= StrLen(IMT.last.WinY) = 0 ? 0 : IMT.last.WinY

	If (A_ScreenWidth > 1920)
		fSize1:= 20, fSize2:= 14, fsize3:= 10, fsize4:= 9
	else
		fSize1:= 16, fSize2:= 10, fsize3:= 9, fsize4:= 8

	Original            	:= IMT.last.Original
	Modified          	:= IMT.last.Modified
	If StrLen(Modified) = 0
		Modified:= mod_Original

	SplitPath, OriginalPicPath,, picPath
	LvOptW	:= 200
	GrpBoxH	:= 260
	;}

	;{ the gui
	Gui, scan: New, -DPIScale +HWNDhIMTG ;, ;+AlwaysOnTop
	Gui, scan: Margin, 5, 5
	Gui, scan: Color, cA0A0A0

	;-: listview for avaible options
	Gui, scan: Add, ListView     	, % "xm ym w" LvOptW " h" origPicH " AltSubmit vAvCmdList HWNDhAvCMDList gAvCmdList", % "options"

	;-: the picture frames
	Gui, scan: Add, Picture     	, % "x+5 ym w-1 h" origPicH " 0xE vOriginalPic HWNDhOriginalPic", % A_ScriptDir "\scans\" Original
			GuiControlGet, p, scan: Pos, OriginalPic
	Gui, scan: Add, Picture     	, % "x+5 ym w" pW " h" origPicH " 0xE vModifiedPic HWNDhModifiedPic", % A_ScriptDir "\scans\" Modified

	;-: filenames
	Gui, scan: Font, % "s" 5     " normal cBlack"
	Gui, scan: Add, GroupBox   	, % "x" LvOptW+10 " y" pH " w" pW " h" GrpBoxH " Section vGrpBox1", % ""

	;-: cmdline exe combobox
	ct:= GuiControlPos("scan", "GrpBox1", 0)
	Gui, scan: Font, % "s" fsize4 " normal cBlack"
	Gui, scan: Add, Combobox	, % "x" LvOptW+20 " y" ct.Y+10 " w" 130 " r6 vmagickCmd HWNDhmagickCmd gmagickAC ", % "convert|magick|compare|composite|conjure|identify|mogrify|montage|stream"
	ct:= GuiControlPos("scan", "magickCMD", 5)
	Gui, scan: Add, Combobox	, % "x" ct.R " y" ct.Y " w" (LvOptW+pW-ct.R) " r8 vVCmdOptions HWNDhCmdOptions gmagickCmdOptions", % IMOptions
	ct:= GuiControlPos("scan", "VCmdOptions", 10)
	Gui, scan: Font, % "s" fsize2 " bold cWhite"
	Gui, scan: Add, Text				, % "x" LvOptW+20 " y" ct.B, % "<<"
	Gui, scan: Font, % "s" 10 " normal cBlack"
	Gui, scan: Add, Combobox	, % "x+5" " w" 300 " vPicPath1 HWNDhPicPath1", % Originals
	Gui, scan: Font, % "s" fsize2 " bold cWhite"
	Gui, scan: Add, Text				, % "x" LvOptW+20 " y+10", % ">>"
	Gui, scan: Font, % "s" 10 " normal cBlack"
	Gui, scan: Add, Combobox	, % "x+5 w" 300 " vPicPath2 HWNDhPicPath2", % Modifieds
	ct:= GuiControlPos("scan", "PicPath1", 10)

	Gui, scan: Font, % "s" fsize3 " normal cBlack"
	;Gui, scan: Font, % "s" fsize2 " bold cWhite"
	;Gui, scan: Add, Text				, % "x" ct.R " y" ct.Y , % "tool"
	ct:= GuiControlPos("scan", "PicPath2", 10)
	Gui, scan: Add, Button     	, % "x" ct.X " y" ct.B " w" ct.W " vRun HWNDhRun gRunImageMagick", % "run ImageMagick command"
	ct:= GuiControlPos("scan", "Run", 25)
	Gui, scan: Add, Button     	, % "x" ct.X " y" ct.B " w" ct.W " vRestartScript gScanGuiClose     	", % "reload this script"

	;-: Imagemagick console output
	ct:= GuiControlPos("scan", "PicPath1", 10)
	Gui, scan: Font, % "s" fsize4 " cBlack"
	Gui, scan: Add, Edit			   , % "x" ct.R " y" ct.Y " w" (LvOptW+pW-ct.R) " h" GrpBoxH-ct.H-35 " t7 t28 t40 t46 t64 vPicCompare HWNDhPicCompare", % ""
	WinSet, Style	,	0x5001184, % "ahk_id " PicCompare
	WinSet, ExStyle,	0x200   	 , % "ahk_id " PicCompare

	;-: Histogram or magnifier groupboxes
	ct:= GuiControlPos("scan", "GrpBox1", 5)
	Gui, scan: Font, % "s" 5     " normal cBlack"
	Gui, scan: Add, GroupBox   , % "x" ct.R " y" pH " w" Floor(pW/2 - 2.5) " h" GrpBoxH " vGrpBox2", % ""
	ct:= GuiControlPos("scan", "GrpBox2", 5), mrg:=5
	Gui, scan: Add, Picture     	, % "x"ct.X+mrg " y" ct.Y+mrg+5 " w" ct.W-2*mrg " h" ct.H-2*mrg " 0xE vInfoPic1 HWNDhInfopic1", % A_ScriptDir "\scans\histogram.png"

	ct:= GuiControlPos("scan", "GrpBox2", 5)
	Gui, scan: Font, % "s" 5     " normal cBlack"
	Gui, scan: Add, GroupBox   	, % "x" ct.R " y" pH " w" Floor(pW/2 - 2.5) " h" GrpBoxH " vGrpBox3", % ""

	Gui, scan: Font, % "s" fsize1 " cRED"
	Gui, scan: Add, Text            , % "x" LvOptW+pW+5 " y" Floor(pH/2) " w" pW " vWaiting Center", work in progress...
	Gui, scan: Add, Text            , % "x" LvOptW+pW+5 " y+10 w" pW " vTextshow Center", % "-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --"
	Gui, scan: Font, % "s" fsize1 " cBlue"
	Gui, scan: Add, Text            , % "x" LvOptW " ym w" pW " vOriginal BackgroundTrans Center", % "original picture"
	Gui, scan: Font, % "s" fsize4 " cNavyBlue"
	Gui, scan: Add, Text            , % "x" LvOptW " y+0 w" pW " vPic1Size BackgroundTrans Center", % GetImageDimensionString(A_ScriptDir "\scans\" Original)
	Gui, scan: Font, % "s" fsize1 " cBlue"
	Gui, scan: Add, Text            , % "x" LvOptW+pW+5 " ym w" pW-5 " vModified BackgroundTrans Center", % "modified picture"
	Gui, scan: Font, % "s" fsize4 " cNavyBlue"
	Gui, scan: Add, Text            , % "x" LvOptW+pW+5 " y+0 w" pW-5 	" vPic2Size BackgroundTrans Center", % GetImageDimensionString(A_ScriptDir "\scans\" Modified)
	Gui, scan: Font, % "s" fsize4-2 " cBlack"
	GuiControl,scan: Hide, Waiting
	GuiControl,scan: Hide, Textshow
	;GuiControl,scan: Hide, PicCompare

	;-: adding magick cmdline options
	For CLIndex, options in MagickOptions
		LV_Add("", options.cmd)
	LV_ModifyCol(1, 160)

	;-: show the gui but hide it
	Gui, scan: Show, % "x" WinX " y" WinY " Hide AutoSize", ImageMagick Test Gui

	;-: get gui size and resize the listview to max height
	scangui:= GetWindowSpot(hIMTG)
	GuiControl, scan: Move, AvCmdList, % "h" scanGui.CH

	;-: some control settings are left
	GuiControl, scan: ChooseString, magickCmd		, % IMT.last.cmd
	GuiControl, scan: Choose    	  , VCmdOptions	, % IMT.last.option
	GuiControl, scan: ChooseString, PicPath1       	, % Original
	GuiControl, scan: ChooseString, PicPath2       	, % Modified
	GuiControl, scan: Focus       	  , VCmdOptions

	;-: and ready to show!
	Gui, scan: Show, % "x" WinX " y" WinY " AutoSize", ImageMagick Test Gui
	;}

	;{ Onmessage and Hotkey
	OnMessage(0x200	, "WM_MOUSEMOVE")
	OnMessage(0x2A2	, "WM_MOUSELEAVE")

	Hotkey, IfWinActive , ImageMagick Test Gui
	Hotkey, Enter, RunImageMagick
	Hotkey, IfWinActive
	;}

return

scanGuiClose:       	;{

	Gui, scan: Submit, NoHide
	win := GetWindowSpot(hIMTG)
	IniWrite, % win.X     	, % A_ScriptDir "\IMT.ini", % "last", % "WinX"
	IniWrite, % win.Y        	, % A_ScriptDir "\IMT.ini", % "last", % "WinY"
	IniWrite, % Original    	, % A_ScriptDir "\IMT.ini", % "last", % "Original"
	IniWrite, % Modified  	, % A_ScriptDir "\IMT.ini", % "last", % "Modified"
	If Instr(A_GuiControl, "RestartScript")
		Reload
	else
		ExitApp

	Gui, scan: Destroy
return ;}

RunImageMagick: 	;{

	Gui, scan: Submit, NoHide
	VCmdOptions := Trim(VCmdOptions, " ")
	If !Instr(IMOptions, VCmdOptions)
	{
		IMOptions.= "|" VCmdOptions
		IMOptions:= LTrim(IMOptions, "|")
		GuiControl, scan: , VCmdOptions, % IMOptions
		Loop
		{
				IniRead, iniVar, % A_ScriptDir "\IMT.ini", % "ImageMagickOptions", % "cmd" SubStr("0000" A_Index, -3)
				If Instr(iniVar, "Error")
				{
					IniWrite, % VCmdOptions, % A_ScriptDir "\IMT.ini",  % "ImageMagickOptions", % "cmd" SubStr("0000" A_Index, -3)
					idx:= A_Index
					break
				}
		}
	}
	else
	{
		For idx, cmd in IMT.ImageMagickOptions
			If Instr(cmd, VCmdOptions)
				break
	}

	IniWrite, % idx, % A_ScriptDir "\IMT.ini",  % "last", % "Option"

	If !Instr(FileExist(IMagickDir), "D")
	{
			MsgBox, 4, ToDo, You have to specify the path to your `nImageMagick cmdline-tools folder!`nIt must be set in IMT.ini file!`n`nClick 'YES' if you wan't to open the download page`nin your browser now!
			IfMsgBox, Yes
				Run, https://imagemagick.org/script/download.php
			return
	}

	If RegExMatch(VCmdOptions, "(?<cmdLine>.*histogram\:)(?<odified>[\w]+\.\w{3})\s*", M)
		cmdline:= q IMagickDir "\" magickCmd ".exe " q " " q A_ScriptDir "\scans\" Original q " -monitor " McmdLine q A_ScriptDir "\scans\" Modified q
	else
		cmdline:= q IMagickDir "\" magickCmd ".exe " q " " q A_ScriptDir "\scans\" Original q " -monitor " VCmdOptions " " q A_ScriptDir "\scans\" Modified q

	compare_cmdline1:= q IMagickDir "\compare.exe" q " " q A_ScriptDir "\scans\" Original q " -metric RMSE " q A_ScriptDir "\scans\" Modified q
	compare_cmdline2:= q IMagickDir "\compare.exe" q " " q A_ScriptDir "\scans\" Original q " -metric PAE " q A_ScriptDir "\scans\" Modified q

	Gui, scan: Default
	GuiControl,scan: Hide   	, ModifiedPic
	;GuiControl,scan: Hide  	, PicCompare
	GuiControl,scan:          	, Pic2Size     	, % ""
	GuiControl,scan: Show	, Waiting
	GuiControl,scan:          	, TextShow   	, % "-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --"
	GuiControl,scan: Show	, Textshow

	out:= StdOutToVar(cmdline)

	WinActivate, ImageMagick Test Gui

	Gui, scan: Default
	GuiControl,scan: Hide  	, Waiting
	GuiControl,scan: Hide  	, Textshow
	GuiControl,scan:          	, ModifiedPic	, % A_ScriptDir "\scans\" Modified
	GuiControl,scan: Move   	, ModifiedPic	, % "w" pW " h" pH
	GuiControl,scan: Show	, ModifiedPic
	GuiControl,scan:          	, Pic2Size     	, % GetImageDimensionString(A_ScriptDir "\scans\" Modified)

	out1:= StdOutToVar(compare_cmdline1)
	out2:= StdOutToVar(compare_cmdline2)

	If Instr(out1, "error/")
		out1:= StrReplace(out1, "@", "@`n             `t|  ")
	If Instr(out2, "error/")
		out2:= StrReplace(out2, "@", "@`n             `t|  ")

	imageInfoOut =
		(LTrim
		%A_Space%     image differences measured

		%A_Space%method `t|  difference
		%A_Space%--------------|---------------------------------------------------------------------------------
		%A_Space%RMSE    `t|  %out1%
		%A_Space%PAE       `t|  %out2%
		)

	GuiControl,scan:          	, PicCompare	, % imageInfoOut
	;GuiControl,scan: Show  	, PicCompare

return ;}

magickAC:           	;{
	Gui, scan: Submit, NoHide
	IniWrite, % magickCmd, % A_ScriptDir "\IMT.ini",  % "last", % "CMD"
return ;}

magickCmdOptions:   	;{
	cp:= C_Caret(hCmdOptions)
	 CaretPos:= cp.S
	;ToolTip, % "CaretPos: " CaretPos
return ;}

AvCmdList:          	;{

	if Instr(A_GuiEvent, "DoubleClick")
	{
			;Zeile ermitteln und des Textes aus dem Feld der ersten Spalte
			Gui, scan: Default
			LV_GetText(ChoosedOption, A_EventInfo)
			;SendMessage, 0xB1, -1, 0, , % "ahk_id" hCmdOptions ;removes selection and keep "caret" position unchanged!
			SendMessage, 0xB1, % CaretPos, 0, , % "ahk_id" hCmdOptions ;removes selection and keep "caret" position unchanged!
			ControlFocus, , % "ahk_id" hCmdOptions
			;ToolTip, % CaretPos , 300, 300, 5
			;GuiControl, scan: Focus, CmdOptions
	}

return ;}

ScriptReload:       	;{
	Reload
return ;}
}

GuiControlPos(guiID, vGuiControl, distance:=0) {			; extended GuiControl position function

	; this function is sometimes necessary if there is no easier way to position controls, because options like Section wan't work
	; with .R you get the right positioning coordinate
	; with .B you get the right positioning coordinate
	; specify a distance, so there's no need to for an extra calculation code

	ct:= Object()
	Gui, % guiID  ": Default"
	GuiControlGet, ct, % guiID ": Pos", % vGuiControl
	ct.X:= ctX
	ct.Y:= ctY
	ct.W:= ctW
	ct.H:= ctH
	ct.R:= ctX + ctW + distance
	ct.B:= ctY + ctH + distance

return ct
}

MagickCommands() {

	; https://imagemagick.org/script/command-line-options.php

	convertOptions =
	(LTrim
	-blur|geometry|adaptively blur pixels; decrease effect near edges
	-resize|geometry|adaptively resize image with data dependent triangulation
	-sharpen|geometry|adaptively sharpen pixels; increase effect near edges
	-adjoin||join images into a single multi-image file
	-affine|matrix|affine transform matrix
	-alpha||on, activate, off, deactivate, set, opaque, copy,transparent, extract, background, or shape the alpha channel
	-annotate|geometry text|annotate the image with text
	-antialias||remove pixel-aliasing
	-append||append an image sequence
	-authenticate|value|decipher image with this password
	-gamma||automagically adjust gamma level of image
	-level||automagically adjust color levels of image
	-orient||automagically orient image
	-threshold|method|automatically perform image thresholding
	-background|color|background color
	-bench|iterations|measure performance
	-bias|value|add bias when convolving an image
	-threshold|value|force all pixels below the threshold into black
	-primary|point|chromaticity blue primary point
	-shift|factor|simulate a scene at nighttime in the moonlight
	-blur|geometry|reduce image noise and reduce detail levels
	-border|geometry|surround image with a border of color
	-bordercolor|color|border color
	-contrast|geometry|improve brightness / contrast of the image
	-canny|geometry|use a multi-stage algorithm to detect a wide range of edges in the image
	-caption|string|assign a caption to an image
	-cdl|filename|color correct with a color decision list
	-channel|type|apply option to select image channels
	-charcoal|radius|simulate a charcoal drawing
	-chop|geometry|remove pixels from the image interior
	-clahe|geometry|contrast limited adaptive histogram equalization
	-clamp||set each pixel whose value is below zero to zero and any the pixel whose value is above the quantum range to the quantum range (e.g. 65535) otherwise the pixel value remains unchanged
	-clip||clip along the first path from the 8BIM profile
	-mask|filename|associate clip mask with the image
	-path|id|clip along a named path from the 8BIM profile
	-clone|index|clone an image
	-clut||apply a color lookup table to the image
	-components|connectivity|connected-components uniquely labeled, choose from 4 or 8 way connectivity
	-stretch|geometry|improve the contrast in an image by stretching the range of intensity value
	-coalesce||merge a sequence of images
	-colorize|value|colorize the image with the fill color
	-matrix|matrix|apply color correction to the image
	-colors|value|preferred number of colors in the image
	-colorspace|type|set image colorspace
	-combine||combine a sequence of images
	-comment|string|annotate image with comment
	-compare||compare image
	-complex|operator|perform complex mathematics on an image sequence
	-compose|operator|set image composite operator
	-composite||composite image
	-compress|type|image compression type
	-contrast||enhance or reduce the image contrast
	-convolve|coefficients|apply a convolution kernel to the image
	-copy|geometry offset|copy pixels from one area of an image to another
	-crop|geometry|crop the image
	-cycle|amount|cycle the image colormap
	-decipher|filename|convert cipher pixels to plain
	-debug|events|display copious debugging information
	-define|format:option|define one or more image format options
	-deconstruct||break down an image sequence into constituent parts
	-delay|value|display the next image after pausing
	-delete|index|delete the image from the image sequence
	-density|geometry|horizontal and vertical density of the image
	-depth|value|image depth
	-despeckle||reduce the speckles within an image
	-direction|type|render text right-to-left or left-to-right
	-display|server|get image or font from this X server
	-dispose|method|layer disposal method
	-cache|port|launch a distributed pixel cache server
	-distort|type coefficients|distort image
	-dither|method|apply error diffusion to image
	-draw|string|annotate the image with a graphic primitive
	-duplicate|count,indexes|duplicate an image one or more times
	-edge|radius|apply a filter to detect edges in the image
	-emboss|radius|emboss an image
	-encipher|filename|convert plain pixels to cipher pixels
	-encoding|type|text encoding type
	-endian|type|endianness (MSB or LSB) of the image
	-enhance||apply a digital filter to enhance a noisy image
	-equalize||perform histogram equalization to an image
	-evaluate|operator value|evaluate an arithmetic, relational, or logical expression
	-sequence|operator|evaluate an arithmetic, relational, or logical expression for an image sequence
	-extent|geometry|set the image size
	-extract|geometry|extract area from image
	-family|name|render text with this font family
	-features|distance|analyze image features (e.g. contract, correlations, etc.)
	-fft||implements the discrete Fourier transform (DFT)
	-fill|color|color to use when filling a graphic primitive
	-filter|type|use this filter when resizing an image
	-flatten||flatten a sequence of images
	-flip||flip image in the vertical direction
	-floodfill|geometry color|floodfill the image with color
	-flop||flop image in the horizontal direction
	-font|name|render text with this font
	-format|string|output formatted image characteristics
	-frame|geometry|surround image with an ornamental border
	-function|name|apply a function to the image
	-fuzz|distance|colors within this distance are considered equal
	-fx|expression|apply mathematical expression to an image channel(s)
	-gamma|value|level of gamma correction
	-blur|geometry|reduce image noise and reduce detail levels
	-geometry|geometry|preferred size or location of the image
	-gravity|type|horizontal and vertical text placement
	-grayscale|method|convert image to grayscale
	-primary|point|chromaticity green primary point
	-help||print program options
	-lines|geometry|identify lines in the image
	-identify||identify the format and characteristics of the image
	-ift||implements the inverse discrete Fourier transform (DFT)
	-implode|amount|implode image pixels about the center
	-insert|index|insert last image into the image sequence
	-intensity|method|method to generate an intensity value from a pixel
	-intent|type|type of rendering intent when managing the image color
	-interlace|type|type of image interlacing scheme
	-spacing|value|the space between two text lines
	-interpolate|method|pixel color interpolation method
	-spacing|value|the space between two words
	-kerning|value|the space between two characters
	-kuwahara|geometry|edge preserving noise reduction filter
	-label|string|assign a label to an image
	-lat|geometry|local adaptive thresholding
	-layers|method|optimize or compare image layers
	-level|value|adjust the level of image contrast
	-limit|type value|pixel cache resource limit
	-stretch|geometry|linear with saturation histogram stretch
	-rescale|geometry|rescale image with seam-carving
	-list|type|Color, Configure, Delegate, Format, Magic, Module, Resource, or Type
	-log|format|format of debugging information
	-loop|iterations|add Netscape loop extension to your GIF animation
	-mattecolor|color|frame color
	-median|radius|apply a median filter to the image
	-shift|geometry|delineate arbitrarily shaped clusters in the image
	-metric|type|measure differences between images with this metric
	-mode|radius|make each pixel the 'predominant color' of the neighborhood
	-modulate|value|vary the brightness, saturation, and hue
	-moments||display image moments
	-monitor||monitor progress
	-monochrome||transform image to black and white
	-morph|value|morph an image sequence
	-morphology|method kernel|apply a morphology method to the image
	-blur|geometry|simulate motion blur
	-negate||replace each pixel with its complementary color
	-noise|radius|add or reduce noise in an image
	-normalize||transform image to span the full range of colors
	-opaque|color|change this color to the fill color
	-dither|NxN|ordered dither the image
	-orient|type|image orientation
	-page|geometry|size and location of an image canvas (setting)
	-paint|radius|simulate an oil painting
	-perceptible||set each pixel whose value is less than 'epsilon' to -epsilon or epsilon (whichever is closer) otherwise the pixel value remains unchanged
	-ping||efficiently determine image attributes
	-pointsize|value|font point size
	-polaroid|angle|simulate a Polaroid picture
	-poly|terms|build a polynomial from the image sequence and the corresponding terms (coefficients and degree pairs)
	-posterize|levels|reduce the image to a limited number of color levels
	-precision|value|set the maximum number of significant digits to be printed
	-preview|type|image preview type
	-print|string|interpret string and print to console
	-process|image-filter|process the image with a custom image filter
	-profile|filename|add, delete, or apply an image profile
	-quality|value|JPEG/MIFF/PNG compression level
	-quantize|colorspace|reduce image colors in this colorspace
	-quiet||suppress all warning messages
	-blur|angle|radial blur the image
	-raise|value|lighten/darken image edges to create a 3-D effect
	-threshold|low, high|random threshold the image
	-range-threshold|low-black, low-white, high-white, high-black|perform either hard or soft thresholding within some range of values in an image
	-mask|filename|associate a read mask with the image
	-primary|point|chromaticity red primary point
	-regard-warnings||pay attention to warning messages
	-region|geometry|apply options to a portion of the image
	-remap|filename|transform image colors to match this set of colors
	-render||render vector graphics
	-repage|geometry|size and location of an image canvas
	-resample|geometry|change the resolution of an image
	-resize|geometry|resize the image
	-respect-parentheses||settings remain in effect until parenthesis boundary
	-roll|geometry|roll an image vertically or horizontally
	-rotate|degrees|apply Paeth rotation to the image
	-sample|geometry|scale image with pixel sampling
	-factor|geometry|horizontal and vertical sampling factor
	-scale|geometry|scale the image
	-scene|value|image scene number
	-seed|value|seed a new sequence of pseudo-random numbers
	-segment|values|segment an image
	-blur|geometry|selectively blur pixels within a contrast threshold
	-separate||separate an image channel into a grayscale image
	-tone|threshold|simulate a sepia-toned photo
	-set|attribute value|set an image attribute
	-shade|degrees|shade the image using a distant light source
	-shadow|geometry|simulate an image shadow
	-sharpen|geometry|sharpen the image
	-shave|geometry|shave pixels from the image edges
	-shear|geometry|slide one edge of the image along the X or Y axis
	-contrast|geometry|increase the contrast without saturating highlights or shadows
	-smush|offset|smush an image sequence together
	-size|geometry|width and height of image
	-sketch|geometry|simulate a pencil sketch
	-solarize|threshold|negate all pixels above the threshold level
	-splice|geometry|splice the background color into the image
	-spread|radius|displace image pixels by a random amount
	-statistic|type geometry|replace each pixel with corresponding statistic from the neighborhood
	-strip|strip image of all profiles and comments
	-stroke|color|graphic primitive stroke color
	-strokewidth|value|graphic primitive stroke width
	-stretch|type|render text with this font stretch
	-style|type|render text with this font style
	-swap|indexes|swap two images in the image sequence
	-swirl|degrees|swirl image pixels about the center
	-synchronize|synchronize image to storage device
	-taint|mark the image as modified
	-texture|filename|name of texture to tile onto the image background
	-threshold|value|threshold the image
	-thumbnail|geometry|create a thumbnail of the image
	-tile|filename|tile image when filling a graphic primitive
	-offset|geometry|set the image tile offset
	-tint|value|tint the image with the fill color
	-transform|affine transform image
	-transparent|color|make this color transparent within the image
	-color|color|transparent color
	-transpose|flip image in the vertical direction and rotate 90 degrees
	-transverse|flop image in the horizontal direction and rotate 270 degrees
	-treedepth|value|color tree depth
	-trim|trim image edges
	-type|type|image type
	-undercolor|color|annotation bounding box color
	-unique-colors|discard all but one of any pixel color
	-units|type|the units of image resolution
	-unsharp|geometry|sharpen the image
	-verbose||print detailed information about the image
	-version||print version information
	-view||FlashPix viewing transforms
	-vignette|geometry|soften the edges of the image in vignette style
	-pixel|method|access method for pixels outside the boundaries of the image
	-wave|geometry|alter an image along a sine wave
	-denoise|threshold|removes noise from the image using a wavelet transform
	-weight|type|render text with this font weight
	-point|point|chromaticity white point
	-threshold|value|force all pixels above the threshold into white
	-write|filename|write images to this file
	-mask|filename|associate a write mask with the image
	)

	Loop, Parse, convertOptions, `n, `r
	{
			li:= StrSplit(A_LoopField, "|")
			MagickOptions.Push({"cmd":li[1], "var": li[2], "info": li[3]})
	}
}

CreateIMOptions(IMT, iniKey) {

	cbox:=""
	For idx, val in IMT[inikey]
		cbox.= StrReplace(val, "%A_ScriptDir%", A_ScriptDir) "|"

return RTrim(cbox, "|")
}

GetImageDimensionString(picFilePath) {
	IMG_GetImageSize(picFilePath ,Width, Height)
return Width " x " Height
}

StdOutToVar(cmd) {						                                                            								;-- catches the command line stream

	;https://github.com/cocobelgica/AutoHotkey-Util/blob/master/StdOutToVar.ahk
	DllCall("CreatePipe", "PtrP", hReadPipe, "PtrP", hWritePipe, "Ptr", 0, "UInt", 0)
	DllCall("SetHandleInformation", "Ptr", hWritePipe, "UInt", 1, "UInt", 1)

	VarSetCapacity(PROCESS_INFORMATION, (A_PtrSize == 4 ? 16 : 24), 0)    ; http://goo.gl/dymEhJ
	cbSize := VarSetCapacity(STARTUPINFO, (A_PtrSize == 4 ? 68 : 104), 0) ; http://goo.gl/QiHqq9
	NumPut(cbSize, STARTUPINFO, 0, "UInt")                                ; cbSize
	NumPut(0x100, STARTUPINFO, (A_PtrSize == 4 ? 44 : 60), "UInt")        ; dwFlags
	NumPut(hWritePipe, STARTUPINFO, (A_PtrSize == 4 ? 60 : 88), "Ptr")    ; hStdOutput
	NumPut(hWritePipe, STARTUPINFO, (A_PtrSize == 4 ? 64 : 96), "Ptr")    ; hStdError

	if !DllCall(
	(Join Q C
		"CreateProcess",            					; http://goo.gl/9y0gw
		"Ptr",  0,                   							; lpApplicationName
		"Ptr",  &cmd,                						; lpCommandLine
		"Ptr",  0,                   							; lpProcessAttributes
		"Ptr",  0,                   							; lpThreadAttributes
		"UInt", true,                						; bInheritHandles
		"UInt", 0x08000000,     					; dwCreationFlags
		"Ptr",  0,                   							; lpEnvironment
		"Ptr",  0,                   							; lpCurrentDirectory
		"Ptr",  &STARTUPINFO,        				; lpStartupInfo
		"Ptr",  &PROCESS_INFORMATION 		; lpProcessInformation
	)) {
		DllCall("CloseHandle", "Ptr", hWritePipe)
		DllCall("CloseHandle", "Ptr", hReadPipe)
		return ""
	}

	DllCall("CloseHandle", "Ptr", hWritePipe)
	VarSetCapacity(buffer, 4096, 0)
	while DllCall("ReadFile", "Ptr", hReadPipe, "Ptr", &buffer, "UInt", 4096, "UIntP", dwRead, "Ptr", 0)
	{
		stmp:= StrGet(&buffer, dwRead, "CP0")
		Gui, scan: Default
		If RegExMatch(stmp, "(\d+\s*\w+\s*\d+)\s*\,\s*(\d+)\%\s*\w+", complete)
			GuiControl,scan:, TextShow, % complete
		sOutput .= stmp
	}
	DllCall("CloseHandle", "Ptr", NumGet(PROCESS_INFORMATION, 0))         ; hProcess
	DllCall("CloseHandle", "Ptr", NumGet(PROCESS_INFORMATION, A_PtrSize)) ; hThread
	DllCall("CloseHandle", "Ptr", hReadPipe)
	return sOutput
}

IMG_GetImageSize(p_FileOrHandle, ByRef r_Width:=0, ByRef r_Height:=0) {								;-- https://www.autohotkey.com/boards/viewtopic.php?p=290795#p290795
    Static Dummy27649730


          ,IMAGE_BITMAP:=0
          ,IMAGE_ICON  :=1
          ,IMAGE_CURSOR:=2

          ;-- LoadImage flags
          ,LR_LOADFROMFILE:=0x10

          ;-- Object types
          ,OBJ_BITMAP:=7

          ;-- Seek origin
          ,SEEK_SET:=0
                ;-- Seek from the beginning of the file.
          ,SEEK_CUR:=1
                ;-- Seek from the current position of the file pointer.
          ,SEEK_END:=2
                ;-- Seek from the end of the file.  The Distance should usually
                ;   be a negative value

    ;-- Initialize
    r_Width:=r_Height:=0

    ;[===========]
    ;[  Handle?  ]
    ;[===========]
    if p_FileOrHandle is Integer
        {
        if (DllCall("GetObjectType","UPtr",p_FileOrHandle)=OBJ_BITMAP)
            IMG_GetBitmapSize(p_FileOrHandle,r_Width,r_Height)
         else  ;-- Assume icon or cursor
            IMG_GetIconSize(p_FileOrHandle,r_Width,r_Height)

        Return {Width:r_Width,Height:r_Height}
        }

    ;[========]
    ;[  Open  ]
    ;[========]
    if not File:=FileOpen(p_FileOrHandle,"r","CP0")
        {
        l_Message:=IMG_SystemMessage(A_LastError)
        outputdebug,
           (ltrim join`s
            Function: %A_ThisFunc% -
            Unexpected return code from FileOpen function.
            A_LastError=%A_LastError% - %l_Message%
            File: %p_FileOrHandle%
           )

        Return False
        }

;;;;;    outputdebug % "File Length: " . File.Length

    ;-- Bounce if the file is not at least 30 bytes
    if (File.Length<30)
        {
        outputdebug,
           (ltrim join`s
            Function: %A_ThisFunc% -
            The file is too small to contain an image.
            File: %p_FileOrHandle%
           )

        File.Close()
        Return False
        }

    ;-- Read the first 30 bytes
    VarSetCapacity(FileData,30,0)
    File.RawRead(FileData,30)

    ;-- Convert the first 30 bytes to a string (Encoding=ANSI)
    ;
    ;   Note 1: This step allows some of the first 30 bytes to be evaluated as
    ;   a string of characters instead of having to evaluate each byte as a
    ;   number.
    ;
    ;   Note 2: The StrGet command will automatically stop converting data when
    ;   a null character is found so if the first 30 bytes includes dynamic data
    ;   or a null character, it is possible that not all 30 characters will make
    ;   it to the FileString variable.  Hint: It is only safe to use the leading
    ;   characters in this string.  If there are any non-static or null
    ;   characters after the initial characters, it's best to reconvert the
    ;   characters after the gap if needed.  Ex:
    ;   NewString:=StrGet(&FileData+12,4,"CP0")
    ;
    FileString:=StrGet(&FileData,30,"CP0")
;;;;;    outputdebug FileString: %FileString%

    if (SubStr(FileString,1,4)="RIFF" and StrGet(&FileData+8,4,"CP0")="ACON")
        {
;;;;;        outputdebug ANI File!
        FilePos:=12
        File.Seek(FilePos,SEEK_SET)
        VarSetCapacity(Chunk,4,0)
        VarSetCapacity(LISTType,8,0)
        Loop 6  ;-- Limit to the first 6 ACON chunks
            {
            ;-- Get the next chunk string
            File.RawRead(Chunk,4)
            FilePos+=4
            ChunkString:=StrGet(&Chunk,4,"CP0")

            ;-- Get the length of the chunk data
            ChunkDataLength:=File.ReadUInt()
            FilePos+=4

            ;-- Add 1 to ChunkDataLength if it is an odd number (rare)
            if ChunkDataLength & 0x1
                ChunkDataLength+=1

;;;;;            if ChunkString in anih,rate,seq%A_Space%
;;;;;                {
;;;;;                FilePos+=ChunkDataLength
;;;;;                File.Seek(FilePos,SEEK_SET)
;;;;;                Continue
;;;;;                }

            if (ChunkString="LIST")
                {
                File.RawRead(LISTType,8)
                LISTType:=StrGet(&LISTType,8,"CP0")
;;;;;                outputdebug LISTType: %LISTType%

                if (LISTType="framicon")
                    {
                    File.Seek(10,SEEK_CUR)
                    r_Width :=File.ReadUChar()
                    r_Height:=File.ReadUChar()
                    Break
                    }
                }

            ;-- Position past the chunk data
            FilePos+=ChunkDataLength
            File.Seek(FilePos,SEEK_SET)
            }

        ;-- ##### For now, assume that we found what we were looking for
        File.Close()
        Return {Width:r_Width,Height:r_Height}
        }

    ;[==========]
    ;[  Bitmap  ]
    ;[==========]
    ;-- https://en.wikipedia.org/wiki/BMP_file_format
    if (SubStr(FileString,1,2)="BM")
        {
;;;;;        outputdebug Bitmap file.
        DIBHeaderSize:=NumGet(FileData,14,"UInt")
;;;;;        outputdebug DIBHeaderSize: %DIBHeaderSize%

        if (DIBHeaderSize=12) ;-- BITMAPCOREHEADER (Windows 2.0+)
            {
            outputdebug p_FileOrHandle: %p_FileOrHandle%
            outputdebug BITMAPCOREHEADER (Windows 2.0+)
            r_Width :=NumGet(FileData,18,"UShort")
            r_Height:=NumGet(FileData,20,"UShort")
            outputdebug r_Width: %r_Width%, r_Height: %r_Height%
            }
         else  ;-- everything else
            {
            r_Width :=NumGet(FileData,18,"Int")
            r_Height:=Abs(NumGet(FileData,22,"Int"))
            }

        File.Close()
        Return {Width:r_Width,Height:r_Height}
        }

    ;[==========]
    ;[  Cursor  ]
    ;[==========]
    ;-- https://en.wikipedia.org/wiki/ICO_(file_format)
    if (NumGet(FileData,0,"UInt")=0x00020000)  ;-- 4 bytes
        {
;;;;;        outputdebug Cursor_1!
;;;;;        NbrOfImages:=NumGet(FileData,4,"UShort")
;;;;;        outputdebug NbrOfImages: %NbrOfImages%

        r_Width :=NumGet(FileData,6,"UChar")
        r_Height:=NumGet(FileData,7,"UChar")
        File.Close()
        Return {Width:r_Width,Height:r_Height}
        }

    ;[=======]
    ;[  EMF  ]
    ;[=======]
    if (NumGet(FileData,0,"UInt")=0x1)  ;-- 4 bytes
        {
        ;-- Get the frame size (measured in 0.01 millimeter units)
        File.Seek(24,SEEK_SET)
        FrameLeft  :=File.ReadInt()
        FrameTop   :=File.ReadInt()
        FrameRight :=File.ReadInt()
        FrameBottom:=File.ReadInt()
        FrameWidth :=FrameRight-FrameLeft
        FrameHeight:=FrameBottom-FrameTop
;;;;;        outputdebug FrameLeft, Top, Right, Bottom, %FrameLeft%, %FrameTop%, %FrameRight%, %FrameBottom%
;;;;;        outputdebug FrameWidth, Height: %FrameWidth%, %FrameHeight%

        ;-- Get the reference device sizes (in pixels and in millimeters)
        File.Seek(72,SEEK_SET)
        WidthDevPixels :=File.ReadInt()
        HeightDevPixels:=File.ReadInt()
        WidthDevMM     :=File.ReadInt()
        HeightDevMM    :=File.ReadInt()

        ;-- Calculate the size
        r_Width :=1+Round(WidthDevPixels*(FrameWidth/100/WidthDevMM))
        r_Height:=1+Round(HeightDevPixels*(FrameHeight/100/HeightDevMM))
        File.Close()
        Return {Width:r_Width,Height:r_Height}
        }

    ;[=======]
    ;[  GIF  ]
    ;[=======]
     if (SubStr(FileString,1,3)="GIF"
    and  SubStr(FileString,4,3)="89a" or SubStr(FileString,4,3)="87a")
        {
        r_Width :=NumGet(FileData,6,"UShort")
        r_Height:=NumGet(FileData,8,"UShort")
        File.Close()
        Return {Width:r_Width,Height:r_Height}
        }

    ;[=========]
    ;[   Icon  ]
    ;[  ##### Version 4  ]
    ;[=========]
    ;-- https://en.wikipedia.org/wiki/ICO_(file_format)
    if (NumGet(FileData,0,"UInt")=0x00010000)  ;-- 4 bytes
        {
        NbrOfImages:=NumGet(FileData,4,"UShort")
;;;;;        outputdebug NbrOfImages: %NbrOfImages%
        r_Width :=NumGet(FileData,6,"UChar")
        r_Height:=NumGet(FileData,7,"UChar")

        ;-- Width and height < 256 and only 1 icon in the file
        if (r_Width and r_Height and NbrOfImages=1)
            {
            File.Close()
            Return {Width:r_Width,Height:r_Height}
            }

        ;-- Everything else

        ;-- Close the file
        ;   Note: This is performed here because the LoadImage system function
        ;   needs to open the file in the following statements.
        File.Close()

        ;-- Reset to the default (not found) values
        r_Width:=r_Height:=0

        ;-- Use LoadImage to determined the icon size or the default icon size
        hIcon:=DllCall("LoadImage"
            ,"UPtr",0                               ;-- hinst
            ,"Str",p_FileOrHandle                   ;-- lpszName
            ,"UInt",IMAGE_ICON                      ;-- uType
            ,"Int",0                                ;-- cxDesired
            ,"Int",0                                ;-- cyDesired
            ,"UInt",LR_LOADFROMFILE)                ;-- fuLoad

        if hIcon
            {
            IMG_GetIconSize(hIcon,r_Width,r_Height)
            DllCall("DestroyIcon","UPtr",hIcon)
            }

        Return {Width:r_Width,Height:r_Height}
        }

    ;[========]
    ;[  JPEG  ]
    ;[========]
     if (NumGet(FileData,0,"UChar")=0xFF
    and  NumGet(FileData,1,"UChar")=0xD8
    and  NumGet(FileData,2,"UChar")=0xFF)
        {
;;;;;        outputdebug JPEG file
;;;;;        IDString:=StrGet(&FileData+6,4,"CP0")
;;;;;        outputdebug IDString: %IDString%

        ;-- Loop through the tags
        FilePos:=2
        File.Seek(FilePos,SEEK_SET)
        ThisByte:=File.ReadUChar()

;;;;;            outputdebug % "Before the loop -  ThisByte: " . Format("0x{:X}",ThisByte)
        While (ThisByte=0xFF)
            {
;;;;;           outputdebug % "Top of the loop -  ThisByte: " . Format("0x{:X}",ThisByte)
            ThisByte:=File.ReadUChar()

            /*
                #####
                Note: Only found images with 0xC0 and 0xC2 tags.  Need to find
                all the formats to ensure that this works right.
            */
;;;;;           if (ThisByte>=0xC0 and ThisByte<=0xC3)
           if ThisByte Between 0xC0 and 0xC3
                {
;;;;;               outputdebug % "Desire header Hit! -  ThisByte: " . Format("0x{:X}",ThisByte)

                if (ThisByte<>0xC0 and ThisByte<>0xC2)
                    outputdebug % "Found image with odd tag!: " . Format("0x{:X}",ThisByte)
                        . ", File: " . p_FileOrHandle

                File.Seek(3,SEEK_CUR)
                r_Height:=IMG_ByteSwap(File.ReadUShort(),"UShort")
                r_Width :=IMG_ByteSwap(File.ReadUShort(),"UShort")
                File.Close()
                Return {Width:r_Width,Height:r_Height}
                }

            BlockSize:=IMG_ByteSwap(File.ReadUShort(),"UShort")

            FilePos+=BlockSize+2
            File.Seek(FilePos,SEEK_SET)
            ThisByte:=File.ReadUChar()

            }

        File.Close()
        Return False
        }

    if (NumGet(FileData,0,"UInt")=0x01BC4949)  ;-- 01=Version 1 (##### may need to add Version 0 later)
        {
        FilePos:=4
        File.Seek(FilePos,SEEK_SET)
        IFDOffset:=File.ReadUInt()
        FilePos:=IFDOffset
        File.Seek(FilePos,SEEK_SET)
        IFDTagCount:=File.ReadUShort()
        FilePos:=File.Position

        Loop %IFDTagCount%
            {
            TagID:=File.ReadUShort()

            if (TagID=0xBC80)
                {
                DataType :=File.ReadUShort()
                DataCount:=File.ReadUInt()  ;-- Always 1 for this tag
                r_Width:=DataType=3 ? File.ReadUShort():File.ReadUInt()
                }

            if (TagID=0xBC81)
                {
                DataType :=File.ReadUShort()
                DataCount:=File.ReadUInt()  ;-- Always 1 for this tag
                r_Height:=DataType=3 ? File.ReadUShort():File.ReadUInt()
                }

            FilePos+=12
            File.Seek(FilePos,SEEK_SET)
            }

        /*
            #####
            For now, assume that we found what we were looking for.  This might
            change in the future.
        */
        File.Close()
        Return {Width:r_Width,Height:r_Height}
        }


    if (NumGet(FileData,0,"UChar")=0x0A and NumGet(FileData,1,"UChar")<=0x5)
        {
        XStart  :=NumGet(FileData,4,"UShort")
        YStart  :=NumGet(FileData,6,"UShort")
        XEnd    :=NumGet(FileData,8,"UShort")
        YEnd    :=NumGet(FileData,10,"UShort")
        r_Width :=XEnd-XStart+1
        r_Height:=YEnd-YStart+1
        File.Close()
        Return {Width:r_Width,Height:r_Height}
        }


    if (NumGet(FileData,0,"UChar")=0x89
   and  SubStr(FileString,2,5)="PNG`r`n"
   and  NumGet(FileData,6,"UChar")=0x1A
   and  NumGet(FileData,7,"UChar")=0x0A     ;-- LF
   and  StrGet(&FileData+12,4,"CP0")="IHDR")
        {
        r_Width :=IMG_ByteSwap(NumGet(FileData,16,"UInt"))
        r_Height:=IMG_ByteSwap(NumGet(FileData,20,"UInt"))
        File.Close()
        Return {Width:r_Width,Height:r_Height}
        }


    if InStr(FileString,"<?xml") or InStr(FileString,"<svg")  ;-- Within the first 30 bytes
        {

        File.Seek(0,SEEK_SET)
        SVGString:=File.Read(1536)


        if SVGPos:=InStr(SVGString,"<svg")
            {
            SVGPos+=4
            if FoundPos1:=InStr(SVGString,"width=",False,SVGPos)
                {
                FoundPos1+=7
                FoundPos2:=InStr(SVGString,"""",False,FoundPos1)
                r_Width:=Floor(SubStr(SVGString,FoundPos1,FoundPos2-FoundPos1))
                }

            if FoundPos1:=InStr(SVGString,"height=",False,SVGPos)
                {
                FoundPos1+=8
                FoundPos2:=InStr(SVGString,"""",False,FoundPos1)
                r_Height:=Floor(SubStr(SVGString,FoundPos1,FoundPos2-FoundPos1))
                }

            if r_Width and r_Height
                {
                File.Close()

                Return {Width:r_Width,Height:r_Height}
                }

            r_Width:=r_Height:=0
            }
        }


     if (SubStr(FileString,1,2)="II"
    and  NumGet(FileData,2,"UShort")=42)  ;-- TIFF version
        {

        FilePos:=4
        File.Seek(FilePos,SEEK_SET)
        IFDOffset:=File.ReadUInt()

        FilePos:=IFDOffset
        File.Seek(FilePos,SEEK_SET)
        IFDTagCount:=File.ReadUShort()

        FilePos:=File.Position

        Loop %IFDTagCount%
            {

            TagID:=File.ReadUShort()

            if (TagID=0x100)
                {
                DataType :=File.ReadUShort()
                DataCount:=File.ReadUInt()  ;-- Always 1 for this tag
                r_Width:=DataType=3 ? File.ReadUShort():File.ReadUInt()
                }

            if (TagID=0x101)
                {
                DataType :=File.ReadUShort()
                DataCount:=File.ReadUInt()  ;-- Always 1 for this tag
                r_Height:=DataType=3 ? File.ReadUShort():File.ReadUInt()
                }

            FilePos+=12
            File.Seek(FilePos,SEEK_SET)
            }

        /*
            #####
            For now, assume that we found what we were looking for.  This might
            change in the future.
        */
        File.Close()
        Return {Width:r_Width,Height:r_Height}
        }


     if (SubStr(FileString,1,2)="MM"
    and  IMG_ByteSwap(NumGet(FileData,2,"UShort"),"UShort")=42)  ;-- TIFF version
        {
        FilePos:=4
        File.Seek(FilePos,SEEK_SET)
        IFDOffset:=IMG_ByteSwap(File.ReadUInt())

        FilePos:=IFDOffset
        File.Seek(FilePos,SEEK_SET)
        IFDTagCount:=IMG_ByteSwap(File.ReadUShort(),"UShort")

        FilePos:=File.Position

        Loop %IFDTagCount%
            {

            TagID:=IMG_ByteSwap(File.ReadUShort(),"UShort")

            if (TagID=0x100)
                {
                DataType :=IMG_ByteSwap(File.ReadUShort(),"UShort")
                DataCount:=IMG_ByteSwap(File.ReadUInt())  ;-- Always 1 for this tag
                r_Width:=DataType=3 ? IMG_ByteSwap(File.ReadUShort(),"UShort"):IMG_ByteSwap(File.ReadUInt())
                }


            if (TagID=0x101)
                {
                DataType :=IMG_ByteSwap(File.ReadUShort(),"UShort")
                DataCount:=IMG_ByteSwap(File.ReadUInt())  ;-- Always 1 for this tag
                r_Height:=DataType=3 ? IMG_ByteSwap(File.ReadUShort(),"UShort"):IMG_ByteSwap(File.ReadUInt())
                }

            FilePos+=12
            File.Seek(FilePos,SEEK_SET)
            }

        File.Close()
        Return {Width:r_Width,Height:r_Height}
        }


    if (SubStr(FileString,1,4)="RIFF" and StrGet(&FileData+8,4,"CP0")="WEBP")
        {
        ImageSizeFound:=False
        VP8Format:=StrGet(&FileData+12,4,"CP0")
        if (VP8Format="VP8 ")
            {
            if (NumGet(FileData,23,"UChar")<>0x9D
            or  NumGet(FileData,24,"UChar")<>0x01
            or  NumGet(FileData,25,"UChar")<>0x2A)
                outputdebug Missing start code block!
             else
                {
                File.Seek(26,SEEK_SET)
                r_Width :=File.ReadUShort()&0x3FFF
                r_Height:=File.ReadUShort()&0x3FFF
                ImageSizeFound:=True
                }
            }
        else if (VP8Format="VP8L")
            {
            File.Seek(16,SEEK_SET)
            Size     :=File.ReadUInt()  ;-- Not used (yet)
            Signature:=File.ReadUChar() ;-- Not used (yet)

            b0:=File.ReadUChar()
            b1:=File.ReadUChar()
            b2:=File.ReadUChar()
            b3:=File.ReadUChar()
            r_width :=1+(((b1&0x3F)<<8)|b0)
            r_Height:=1+(((b3&0xF)<<10)|(b2<<2)|((b1&0xC0)>>6))
            ImageSizeFound:=True
            }
        else if (VP8Format="VP8X")
            {
            File.Seek(24,SEEK_SET)
            b0:=File.ReadUChar()
            b1:=File.ReadUChar()
            b2:=File.ReadUChar()
            r_width:=1+(b2<<16|b1<<8|b0)

            b0:=File.ReadUChar()
            b1:=File.ReadUChar()
            b2:=File.ReadUChar()
            r_Height:=1+(b2<<16|b1<<8|b0)
            ImageSizeFound:=True
            }
        else
            outputdebug % "WebP format not supported: " . VP8Format

        File.Close()
        Return ImageSizeFound ? {Width:r_Width,Height:r_Height}:False
        }

    if (NumGet(FileData,0,"UInt")=0x9AC6CDD7)
        {
        Left  :=NumGet(FileData,6,"Short")
        Top   :=NumGet(FileData,8,"Short")
        Right :=NumGet(FileData,10,"Short")
        Bottom:=NumGet(FileData,12,"Short")
        Inch  :=NumGet(FileData,14,"UShort")
        ;-- Calculate and return size
        r_Width :=Round((Right-Left)/Inch*A_ScreenDPI)
        r_Height:=Round((Bottom-Top)/Inch*A_ScreenDPI)
        File.Close()
        Return {Width:r_Width,Height:r_Height}
        }


    File.Close()
Return False
}

IMG_GetBitmapSize(hBitmap,ByRef r_Width:="",ByRef r_Height:="") {
    Static Dummy89628542
          ,sizeofBITMAP:=A_PtrSize=8 ? 32:24

    ;-- Initialize
    r_Width:=r_Height:=0

    ;-- Get bitmap info
    VarSetCapacity(BITMAP,sizeofBITMAP,0)
    if not DllCall("GetObject","UPtr",hBitmap,"Int",sizeofBITMAP,"UPtr",&BITMAP)
        Return False

    ;-- Update the output variables
    r_Width :=NumGet(BITMAP,4,"Int")                    ;-- bmWidth
    r_Height:=NumGet(BITMAP,8,"Int")                    ;-- bmHeight
    Return {Width:r_Width,Height:r_Height}
}

IMG_ByteSwap(p_Nbr,p_Type:="") {
    if InStr(p_Type,"Short")
        Return ((p_Nbr&0xFF)<<8|(p_Nbr&0xFF00)>>8)
     else
        Return (p_Nbr&0xFF)<<24|(p_Nbr&0xFF00)<<8|(p_Nbr&0xFF0000)>>8|(p_Nbr&0xFF000000)>>24
 }

IMG_GetIconSize(hIcon,ByRef r_Width:="",ByRef r_Height:="")  {
    Static Dummy42372945
          ,sizeofBITMAP:=A_PtrSize=8 ? 32:24

    ;-- Initialize
    r_Width:=r_Height:=0

    ;-- Get icon info.  Bounce if not a valid icon or cursor.
    VarSetCapacity(ICONINFO,A_PtrSize=8 ? 32:20,0)
    if not DllCall("GetIconInfo","UPtr",hIcon,"UPtr",&ICONINFO)
        Return False

    hMask :=NumGet(ICONINFO,A_PtrSize=8 ? 16:12,"UPtr")
    hColor:=NumGet(ICONINFO,A_PtrSize=8 ? 24:16,"UPtr")

    ;-- Get bitmap info
    VarSetCapacity(BITMAP,sizeofBITMAP,0)
    l_Return:=DllCall("GetObject","UPtr",hMask,"Int",sizeofBITMAP,"UPtr",&BITMAP)

    ;-- Delete the bitmaps created by GetIconInfo
    if hMask
        DllCall("DeleteObject","UPtr",hMask)

    if hColor
        DllCall("DeleteObject","UPtr",hColor)

    ;-- Bounce if GetObject failed (rare at this point)
    if not l_Return
        Return False

    ;-- Update the output variables
    r_Width :=NumGet(BITMAP,4,"Int")                    ;-- bmWidth
    bmHeight:=NumGet(BITMAP,8,"Int")                    ;-- bmHeight
    r_Height:=hColor ? bmHeight:bmHeight//2
    Return {Width:r_Width,Height:r_Height}
    }

IMG_SystemMessage(p_MessageNbr)  {
    Static FORMAT_MESSAGE_FROM_SYSTEM:=0x1000

    ;-- Convert system message number into a readable message
    VarSetCapacity(l_Message,1024*(A_IsUnicode ? 2:1),0)
    DllCall("FormatMessage"
           ,"UInt",FORMAT_MESSAGE_FROM_SYSTEM           ;-- dwFlags
           ,"UPtr",0                                    ;-- lpSource
           ,"UInt",p_MessageNbr                         ;-- dwMessageId
           ,"UInt",0                                    ;-- dwLanguageId
           ,"Str",l_Message                             ;-- lpBuffer
           ,"UInt",1024                                 ;-- nSize (in TCHARS)
           ,"UPtr",0)                                   ;-- *Arguments

    ;-- If set, remove the trailing CR+LF characters
    if (SubStr(l_Message,-1)="`r`n")
        StringTrimRight l_Message,l_Message,2

    ;-- Return system message
    Return l_Message
    }

createHistogramBMP(pBitmap, OSDTextColor:="ffFFFFFF", OSDbgrColor:="ffAAAAAA" ) {

   Gdip_GetHistogram(pBitmap, 3, brLvlArray, 0, 0)
   Gdip_GetImageDimensions(pBitmap, imgW, imgH)
   ; Gdip_GetHistogram(whichBmp, 2, ArrChR, ArrChG, ArrChB)

   minBrLvlV := TotalPixelz := imgW * imgH
   Loop, 256
   {
       thisIndex := A_Index - 1
       nrPixelz := brLvlArray[thisIndex]
       If (nrPixelz="")
          Continue

       stringArray .= nrPixelz "." (thisIndex+1) "`n"
       If (nrPixelz>0)
          stringArray2 .= (thisIndex+1) "." nrPixelz "`n"
       If (nrPixelz>1)
          stringArray3 .= (thisIndex+1) "." nrPixelz "`n"
       sumTotalBr += nrPixelz * (thisIndex+1)
       SimpleSumTotalBr += nrPixelz
       If (nrPixelz>modePointV)
       {
          modePointV := nrPixelz
          modePointK := thisIndex
       }
       If (nrPixelz<modePointV && nrPixelz>2ndMaxV)
          2ndMaxV := nrPixelz

       If (nrPixelz<minBrLvlV && nrPixelz>2)
       {
          minBrLvlV := nrPixelz
          minBrLvlK := thisIndex
       }
   }

   Sort, stringArray, ND`n
   GetClientSize(mainWidth, mainHeight, PVhwnd)
   avgBrLvlK := Round(sumTotalBr/TotalPixelz - 1, 1)
   avgBrLvlV := brLvlArray[Round(avgBrLvlK)]
   modePointK2 := ST_ReadLine(stringArray, "L")
   modePointK2 := StrSplit(modePointK2, ".")
   2ndMaxVa := (2ndMaxV + avgBrLvlV)//2 + minBrLvlV
   rangeA := ST_ReadLine(stringArray3, 1)
   rangeA := StrSplit(rangeA, ".")
   rangeB := ST_ReadLine(stringArray3, "L")
   rangeB := StrSplit(rangeB, ".")
   Loop, 256
   {
       minBrLvlK2 := ST_ReadLine(stringArray, A_Index)
       minBrLvlK2 := StrSplit(minBrLvlK2, ".")
       If (minBrLvlK2[1]=0)
          Continue
       If (minBrLvlK2[2]>0)
          Break
   }
   rangeC := rangeB[1] - rangeA[1] + 1
   meanValue := SimpleSumTotalBr/rangeC
   meanValuePrc := Round(meanValue/TotalPixelz * 100)
   meanValuePrc := (meanValuePrc>0) ? " (" meanValuePrc "%) " : ""

   2ndMaxVb := (2ndMaxV + meanValue)//2 + minBrLvlV
   2ndMaxV := minU(2ndMaxVa, 2ndMaxVb)
   Loop, 256
   {
       lookMean := ST_ReadLine(stringArray, A_Index)
       lookMean := StrSplit(lookMean, ".")
       thisMean := lookMean[1]
       If (thisMean>meanValue)
       {
          meanValueK := Round((prevMean + lookMean[2] - 1)/2, 1)
          Break
       } prevMean := lookMean[2]
   }
   meanValueK := !meanValueK ? "" : " | Mean: " meanValueK meanValuePrc

   Loop, 256
   {
       lookValue := ST_ReadLine(stringArray2, A_Index)
       lookValue := StrSplit(lookValue, ".")
       thisSum += lookValue[2]
       If (thisSum>TotalPixelz//2)
       {
          medianValue := lookValue[1] - 1
          Break
       }
   }

   peakPrc := Round(modePointK2[1]/TotalPixelz * 100)
   peakPrc := (peakPrc>0) ? " (" peakPrc "%)" : ""
   minPrc := Round(minBrLvlK2[1]/TotalPixelz * 100)
   minPrc := (minPrc>0) ? " (" minPrc "%)" : ""
   medianPrc := Round(lookValue[2]/TotalPixelz * 100)
   medianPrc := (medianPrc>0) ? " (" medianPrc "%)" : ""
   avgPrc := Round(avgBrLvlV/TotalPixelz * 100)
   avgPrc := (avgPrc>0) ? " (" avgPrc "%)" : ""
   TotalPixelzSpaced := groupDigits(TotalPixelz)

   infoRange := "Range: " rangeA[1] - 1 " - " rangeB[1] - 1 " (" rangeC ")"
   infoPeak := "`nMode: " modePointK2[2] - 1 peakPrc
   infoAvg := " | Avg: " avgBrLvlK avgPrc " | Min: " minBrLvlK2[2] - 1 minPrc
   infoMin := "`nMedian: " medianValue medianPrc meanValueK
   entireString := infoRange infoPeak infoAvg infoMin "`nTotal pixels: " TotalPixelzSpaced
   infoBoxBMP := drawTextInBox(entireString, OSDFontName, OSDfntSize//1.5, mainWidth//1.3, mainHeight//1.3, OSDtextColor, "0xFF" OSDbgrColor, 1, 0)
   ; tooltip, % "|" TotalPixelz "|" modePointV ", " 2ndMaxV ", " avgBrLvlV " || "  maxW "," maxH  ;  `n" PointsList
   Scale := (PrefsLargeFonts=1) ? 2.6 : 1.7
   HistogramBMP := drawHistogram(brLvlArray, 2ndMaxV, 256, Scale, "0xFF" OSDtextColor, "0x" OSDbgrColor, imgHUDbaseUnit//3, infoBoxBMP)
   Gdip_DisposeImage(infoBoxBMP, 1)
}

ST_ReadLine(String, line, delim="`n", exclude="`r") {
   String := Trim(String, delim)
   StringReplace, String, String, %delim%, %delim%, UseErrorLevel
   TotalLcount := ErrorLevel + 1

   If (abs(line)>TotalLCount && (line!="L" || line!="R" || line!="M"))
      Return 0

   If (Line="R")
      Random, Rand, 1, %TotalLcount%
   Else If (line<=0)
      line := TotalLcount + line

   Loop, Parse, String, %delim%, %exclude%
   {
      out := (Line="R" && A_Index=Rand) ? A_LoopField
           : (Line="M" && A_Index=TotalLcount//2) ? A_LoopField
           : (Line="L" && A_Index=TotalLcount) ? A_LoopField
           : (A_Index=Line) ? A_LoopField : -1
      If (out!=-1) ; Something was found so stop searching.
         Break
   }
   Return out
}

ST_Insert(insert,input,pos=1) {
	Length := StrLen(input)
	((pos > 0) ? (pos2 := pos - 1) : (((pos = 0) ? (pos2 := StrLen(input),Length := 0) : (pos2 := pos))))
	output := SubStr(input, 1, pos2) . insert . SubStr(input, pos, Length)
	If (StrLen(output) > StrLen(input) + StrLen(insert))
		((Abs(pos) <= StrLen(input)/2) ? (output := SubStr(output, 1, pos2 - 1) . SubStr(output, pos + 1, StrLen(input))) : (output := SubStr(output, 1, pos2 - StrLen(insert) - 2) . SubStr(output, pos - StrLen(insert), StrLen(input))))
	return, output
}

minU(val1, val2, val3:="null") {
  a := (val1<val2) ? val1 : val2
  If (val3!="null")
     a := (a<val3) ? a : val3
  Return a
}

maxU(val1, val2, val3:="null") {
  a := (val1>val2) ? val1 : val2
  If (val3!="null")
     a := (a>val3) ? a : val3
  Return a
}

groupDigits(nrIn, delim:=" ") {
   nrOut := nrIn
   If StrLen(nrOut)>3
      nrOut := ST_Insert(delim, nrOut, StrLen(nrOut) - 2)
   If StrLen(nrOut)>7
      nrOut := ST_Insert(delim, nrOut, StrLen(nrOut) - 6)
   If StrLen(nrOut)>11
      nrOut := ST_Insert(delim, nrOut, StrLen(nrOut) - 10)
   If StrLen(nrOut)>15
      nrOut := ST_Insert(delim, nrOut, StrLen(nrOut) - 14)
   Return nrOut
}

drawHistogram(dataArray, maxYlimit, LengthX, Scale, fgrColor, bgrColor, borderSize, infoBoxBMP) { ;stolen from quick-picto-viewer

    graphPath := Gdip_CreatePath()
    PointsList .= 0 "," 125 "|"
    Loop, % LengthX
    {
        y1 := 125 - ((dataArray[A_Index - 1]/maxYlimit) * 100)
        If (y1<0)
           y1 := 0
        PointsList .= A_Index - 1 ","  y1 "|"
    }
    PointsList .= LengthX + 1 "," 125
    Gdip_AddPathClosedCurve(graphPath, PointsList, 0.001)
    pMatrix := Gdip_CreateMatrix()
    Gdip_ScaleMatrix(pMatrix, Scale, Scale, 1)
    Gdip_TransformPath(graphPath, pMatrix)

    thisRect := Gdip_GetPathWorldBounds(graphPath)
    imgW := thisRect.w, imgH := thisRect.h
    hbm := CreateDIBSection(imgW, imgH)
    hdc := CreateCompatibleDC()
    obm := SelectObject(hdc, hbm)
    ;G := Gdip_GraphicsFromHDC(hdc, 7, 4, 2) ; ???
    G := Gdip_GraphicsFromHDC(hdc)
    pBr0 := Gdip_BrushCreateSolid(bgrColor)
    pBr1 := Gdip_BrushCreateSolid(fgrColor)
    Gdip_FillRectangle(G, pBr0, -2, -2, imgW + 4, imgH + 4)
    Gdip_FillRectangle(G, pBrushE, -2, -2, imgW + 4, imgH + 4)

    Gdip_FillPath(G, pBr1, graphPath)
    Gdip_DeletePath(graphPath)
    Gdip_DeleteMatrix(pMatrix)
    Gdip_GetImageDimensions(infoBoxBMP, imgW2, imgH2)
    clipBMPa := Gdip_CreateBitmapFromHBITMAP(hbm)
    clipBMP := Gdip_CreateBitmap(imgW + borderSize * 2, imgH + imgH2 + Round(borderSize*1.5), 0x21808)   ; 24-RGB
    G3 := Gdip_GraphicsFromImage(clipBMP)
    Gdip_GetImageDimensions(clipBMP, maxW, maxH)
    lineThickns := borderSize//10
    Gdip_SetPenWidth(pPen1d, lineThickns)
    Gdip_FillRectangle(G3, pBr0, -2, -2, maxW + borderSize*2+12, maxH + borderSize*3)
    Gdip_DrawRectangle(G3, pPen1d, borderSize - lineThickns, borderSize - lineThickns, imgW + lineThickns*2, imgH + lineThickns*2)
    Gdip_DrawImageFast(G3, clipBMPa, borderSize, borderSize)
    Gdip_DrawImageFast(G3, infoBoxBMP, borderSize, imgH + borderSize*1.25)
    Gdip_DeleteGraphics(G3)
    Gdip_DisposeImage(clipBMPa, 1)
    Gdip_DeleteBrush(pBr0)
    Gdip_DeleteBrush(pBr1)
    SelectObject(hdc, obm)
    DeleteObject(hbm)
    DeleteDC(hdc)
    ; tooltip, % maxYlimit ", " LengthX " || "  maxW "," maxH  ;  `n" PointsList
    Return clipBMP
}

drawTextInBox(theString, fntName, theFntSize, maxW, maxH, txtColor, bgrColor, NoWrap, flippable:=0) {
    hbm := CreateDIBSection(maxW, maxH)
    hdc := CreateCompatibleDC()
    obm := SelectObject(hdc, hbm)
    ;G := Gdip_GraphicsFromHDC(hdc, 7, 4, 2) ;???
    G := Gdip_GraphicsFromHDC(hdc)
    pBr0 := Gdip_BrushCreateSolid(bgrColor)
    Gdip_FillRectangle(G, pBr0, -2, -2, maxW + 4, maxH + 4)
    If (FontBolded=1)
       txtStyle .= " Bold"
    If (FontItalica=1 && NoWrap=0)
       txtStyle .= " Italic"
    Else If (NoWrap=1)
       txtStyle .= " NoWrap"
    txtOptions := "x1 y1 " usrTextAlign " cEE" txtColor " r4 s" theFntSize txtStyle
    dimensions := Gdip_TextToGraphics(G, theString, txtOptions, fntName, maxW, maxH, 0, 0)
    txtRes := StrSplit(dimensions, "|")
    txtX := Floor(txtRes[1]-1)
    txtY := Floor(txtRes[2]-1)
    txtResW := Ceil(txtRes[3]+2)
    If (txtResW>maxW)
       txtResW := maxW
    txtResH := Ceil(txtRes[4]+2)
    If (txtResH>maxH)
       txtResH := maxH
    clipBMPa := Gdip_CreateBitmapFromHBITMAP(hbm)
    clipBMPb := Gdip_CloneBitmapArea(clipBMPa, txtX + 1, txt + 1, txtResW - 1, txtResH - 1)
    Gdip_DisposeImage(clipBMPa, 1)

    borderSize := NoWrap ? Floor(theFntSize*1.1) : Floor(theFntSize*1.3)
    clipBMP := Gdip_CreateBitmap(txtResW + borderSize * 2, txtResH + borderSize*2, 0x21808)   ; 24-RGB
    G3 := Gdip_GraphicsFromImage(clipBMP)
    Gdip_GetImageDimensions(clipBMP, maxW, maxH)
    If (flippable=1)
       setMainCanvasTransform(maxW, maxH, G3)
    Gdip_FillRectangle(G3, pBr0, -2, -2, txtResW + borderSize*2+12, txtResH + borderSize*2+12)
    Gdip_DrawImageFast(G3, clipBMPb, borderSize, borderSize)
    Gdip_DeleteGraphics(G3)
    Gdip_DisposeImage(clipBMPb, 1)
    Gdip_DeleteBrush(pBr0)
    SelectObject(hdc, obm)
    DeleteObject(hbm)
    DeleteDC(hdc)
Return clipBMP
}

setMainCanvasTransform(W, H, G:=0) {
    If (thumbsDisplaying=1)
       Return

    If !G
       G := glPG

    If (FlipImgH=1)
    {
       Gdip_ScaleWorldTransform(G, -1, 1)
       Gdip_TranslateWorldTransform(G, -W, 0)
    }

    If (FlipImgV=1)
    {
       Gdip_ScaleWorldTransform(G, 1, -1)
       Gdip_TranslateWorldTransform(G, 0, -H)
    }
}

IniParserEx(sFile) {
    arrSection := Object(), idx := 0
	FileRead, iniFile, % sFile
	iniFile:= StrReplace(inifile, "Ã¼", "ü")
    Loop, Parse, iniFile, `n, `r
		If RegExMatch(A_LoopField, "S)^\s*\[(.*)\]\s*$", sSecMatch)
		{
				arrSection[(sSecMatch1)] := Object()
				saveSecMatch1:= sSecMatch1
		}
		Else If RegExMatch(A_LoopField, "S)^\s*(\w+)\s*\=\s*(.*)\s*$", sKeyValMatch)
				If RegExMatch(sKeyValMatch1, "[A-Za-z]+\d+")
						arrSection[saveSecMatch1].Push(sKeyValMatch2)
				else
						arrSection[saveSecMatch1][skeyValMatch1]:= sKeyValMatch2

    Return arrSection
}

PictureDir2List(dir, mod:= true) {                                                           	;-- reads a directory

	Loop, Files, % dir "\*.*"
	{
			If A_LoopFileExt not in jpg,tif,png,bmp
				continue

			if mod && RegExMatch(A_LoopFileName, "^mod_")
				pics.= A_LoopFileName "|"
			else if !mod && !RegExMatch(A_LoopFileName, "^mod_")
				pics.= A_LoopFileName "|"
	}

return RTrim(pics, "|")
}

GetWindowSpot(hWnd) {                                                                                                           	;-- like GetWindowInfo, but faster because it only returns position and sizes
    NumPut(VarSetCapacity(WINDOWINFO, 60, 0), WINDOWINFO)
    DllCall("GetWindowInfo", "Ptr", hWnd, "Ptr", &WINDOWINFO)
    wi := Object()
    wi.X   	:= NumGet(WINDOWINFO, 4	, "Int")
    wi.Y   	:= NumGet(WINDOWINFO, 8	, "Int")
    wi.W  	:= NumGet(WINDOWINFO, 12, "Int") 	- wi.X
    wi.H  	:= NumGet(WINDOWINFO, 16, "Int") 	- wi.Y
    wi.CX	:= NumGet(WINDOWINFO, 20, "Int")
    wi.CY	:= NumGet(WINDOWINFO, 24, "Int")
    wi.CW 	:= NumGet(WINDOWINFO, 28, "Int") 	- wi.CX
    wi.CH  	:= NumGet(WINDOWINFO, 32, "Int") 	- wi.CY
    wi.BW	:= NumGet(WINDOWINFO, 48, "UInt")
    wi.BH	:= NumGet(WINDOWINFO, 52, "UInt")
Return wi
}

WM_MOUSEMOVE(wParam, lParam, Msg, Hwnd) {
   ; LVM_HITTEST   -> docs.microsoft.com/en-us/windows/desktop/Controls/lvm-hittest
   ; LVHITTESTINFO -> docs.microsoft.com/en-us/windows/desktop/api/Commctrl/ns-commctrl-taglvhittestinfo
   static item_old
   static maxChars	:= 45
   TT := ""
	If (A_GuiControl = "AvCmdList") {
      VarSetCapacity(LVHTI, 24, 0) ; LVHITTESTINFO
      , NumPut(lParam & 0xFFFF, LVHTI, 0, "Int")
      , NumPut((lParam >> 16) & 0xFFFF, LVHTI, 4, "Int")
      , Item := DllCall("SendMessage", "Ptr", Hwnd, "UInt", 0x1012, "Ptr", 0, "Ptr", &LVHTI, "Int") ; LVM_HITTEST
      If (Item >= 0) && (NumGet(LVHTI, 8, "UInt") & 0x0E)
	  {
			If (item_old = item)
				return
			item_old:= item

			Gui, ListView, %A_GuiControl%
			LV_GetText(TT, Item + 1)

			For idx, option in MagickOptions
				If RegExMatch(option.cmd, "^" TT)
				{
						infoT:= "Option:        " option.cmd (StrLen(option.var)= 0 ? "`n" : " [" option.var "]`n")
						infoE:= "Description: "
						rT:= StrSplit(option.info, " ")

						Loop, % rt.MaxIndex()
							If ((StrLen(infoE) + StrLen(rt[A_Index]) + 1) <= (maxChars+20))
								infoE .= " " rt[A_Index]
							else
							{
								infoT .= infoE "`n"
								infoE := ""
								infoE .= "                     " rt[A_Index]
							}

						If StrLen(infoE) > 0
							infoT .= infoE

						ToolTip, % RTrim(infoT, "`n                    "),,, 20
						SetTimer, killTip, -4000
				}
      }
	}
	else
		ToolTip,,,, 20
return
killTip:
		ToolTip,,,, 20
return
}

WM_MOUSELEAVE() {
	ToolTip,,,, 20
}

C_Caret(ControlId) {
;This function returns the Caret info relative to the specified Control's client area!
;if "ControlId = a Control Hwnd Id" the function will get the Caret S,L,X,Y positions!
;if "ControlId = S" the function returns the Caret String Position
;if "ControlId = L" the function returns the Caret Line Position
;if "ControlId = X" the function returns the Caret x Position
;if "ControlId = Y" the function returns the Caret Y Position

Static S,L,X,Y		;remember values between function calls

T_CoordModeCaret := A_CoordModeCaret	;necessary to restore thread default option before function return
CoordMode, Caret, screen
sleep, 1				;prevents A_CaretX\A_Carety from returning incorrect values

VarSetCapacity(WINDOWINFO, 60, 0)
DllCall("GetWindowInfo", Ptr, ControlId, Ptr, &WINDOWINFO)

X := A_CaretX - NumGet(WINDOWINFO, 20, "Int")	;"20" returns the control client area x pos relative to screen upper-left corner
Y := A_Carety - NumGet(WINDOWINFO, 24, "Int")	;"24" returns the control client area y pos relative to screen upper-left corner

;EM_CHARFROMPOS = 0x00D7 -> msdn.microsoft.com/en-us/library/bb761566(v=vs.85).aspx
Char := DllCall("User32.dll\SendMessage", "Ptr", ControlId, "UInt", 0x00D7, "Ptr", 0, "UInt", (Y << 16) | X, "Ptr")

S := (Char & 0xFFFF) + 1	;"+1" force 1 instead 0 to be recognised as first character
L := (Char >> 16) + 1

CoordMode, Caret, % T_CoordModeCaret	;restore thread default option before function return
sleep, 1				;prevents A_CaretX\A_Carety from returning incorrect values

return {"S": S, "L": L, "X": X, "Y": Y}
}

GetClientSize(ByRef w, ByRef h, hwnd) {
; by Lexikos http://www.autohotkey.com/forum/post-170475.html
    VarSetCapacity(rc, 16, 0)
    DllCall("GetClientRect", "uint", hwnd, "uint", &rc)
    prevW := W := NumGet(rc, 8, "int")
    prevH := H := NumGet(rc, 12, "int")
}

#include %A_ScriptDir%\libs\Gdip_All.ahk
