;ImageMagickTestGui - script by Ixiko last change: 28.10.2019

#NoENV
SetBatchLines, -1

global 	q	:= Chr(0x22)
global 	Textshow
global 	IMagickDir	                		:= ".....\imagemagick"  ;<----- change that to your imagemagick 'command-line-tools' directory --- download: https://imagemagick.org/script/download.php
global 	OriginalPicPath	            	:= A_ScriptDir "\temp.tif"
global 	MagickCommands          	:= Object()
			MagickCommands.convert	:= Object()
global	IMOptions                       	:= ReadIMOptions()

MagickCommands()
MagickGui()

return

MagickGui() {

	global
	SplitPath, OriginalPicPath,, picPath
	origPicH:= Floor(A_ScreenHeight/1.5)
	testpicPath:= picPath "\IMagickTest.tif"
	If (A_ScreenWidth > 1920)
		fSize1:= 20, fSize2:= 14, fsize3:= 9
	else
		fSize1:= 16, fSize2:= 10, fsize3:= 8

	Gui, scan: New, -DPIScale ;, ;+AlwaysOnTop
	Gui, scan: Margin, 5, 5
	Gui, scan: Color, cA0A0A0
	Gui, scan: Add, Picture     	, % "xm 	ym   	          	w-1"            	" h" origPicH    	" 0xE vOriginalPic 	HWNDhOriginalPic                                  	", % OriginalPicPath
	GuiControlGet, p, scan: Pos, OriginalPic
	Gui, scan: Add, Picture     	, % "x+5 	ym        		  	w" pW       		" h" pH           	" 0xE vChangedPic 	HWNDhChangedPic                                	", % ""
	Gui, scan: Add, Combobox	, % "xm 	y"  	pH+10 " 	w" pW                           	        "   	 vPicPath1     	HWNDhPicPath1                                     	", % OriginalPicPath
	Gui, scan: Add, Combobox	, % "x+5 	             		 	w" pW                          	        "   	 vPicPath2     	HWNDhPicPath2                                     	", % testpicPath
	Gui, scan: Add, Combobox	, % "xm 	y+10            	w" 100                         	        " r1	 vmagickCmd 	HWNDhmagickCmd	gmagickAC           	", % "convert|magick|compare|composite|conjure|identify|mogrify|montage|stream"
	Gui, scan: Add, Combobox	, % "x+5                        	w" (pW*2)-150                     	" r6	 vCmdOptions HWNDhCmdOptions                              	", % IMOptions
	Gui, scan: Add, Button     	, % "x+5 	                                                         	                 	 vRun           	HWNDhRun	            	gRunImageMagick"	, % "Run"
	Gui, scan: Font, % "s" fsize1 " cRED"
	Gui, scan: Add, Text            , % "x" pW+5 " y" Floor(pH/2) " w" pW " vWaiting Center", work in progress...
	Gui, scan: Add, Text            , % "x" pW+5 " y+10 w" pW " vTextshow Center", % "-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --"
	Gui, scan: Font, % "s" fsize2 " cBlue"
	Gui, scan: Add, Text            , % "xm         	ym        	w" pW  	" vOriginal BackgroundTrans Center"      	, % "original picture"
	Gui, scan: Font, % "s" fsize3 " cNavyBlue"
	Gui, scan: Add, Text            , % "xm         	y+0  		w" pW 		" vPic1Size BackgroundTrans Center"     	, % GetImageDimensionString(OriginalPicPath)
	Gui, scan: Font, % "s" fsize2 " cBlue"
	Gui, scan: Add, Text            , % "x" pW+5 " ym       	w" pW-5 	" vModified BackgroundTrans Center"   	, % "modified picture"
	Gui, scan: Font, % "s" fsize3 " cNavyBlue"
	Gui, scan: Add, Text            , % "x" pW+5 " y+0 	    	w" pW-5 	" vPic2Size BackgroundTrans Center"     	, % "0000x0000"
	GuiControl,scan: Hide, Waiting
	GuiControl,scan: Hide, Textshow
	Gui, scan: Font, s10
	Gui, scan: Show, AutoSize, ImageMagick Test Gui

	GuiControl, scan: ChooseString, magickCmd, convert
	GuiControl, scan: Choose, PicPath1, 1
	GuiControl, scan: Choose, PicPath2, 1
	GuiControl, scan: Focus, CmdOptions

	Hotkey, IfWinActive , ImageMagick Test Gui
	Hotkey, Enter, RunImageMagick
	Hotkey, IfWinActive

return

scanGuiClose:
	Gui, scan: Destroy
	ExitApp
return

RunImageMagick:

	Gui, scan: Submit, NoHide
	CmdOptions := Trim(CmdOptions)
	If !Instr(IMOptions, CmdOptions)
	{
		IMOptions.= "|" CmdOptions
		IMOptions:= LTrim(IMOptions, "|")
		GuiControl, scan: , CmdOptions, % IMOptions
		Loop
		{
				IniRead, iniVar, % A_ScriptFullPath, ImageMagickOptions, % magickCmd A_Index
				If Instr(iniVar, "Error")
				{
					IniWrite, % CmdOptions, % A_ScriptFullPath, ImageMagickOptions, % magickCmd A_Index
					break
				}
		}
	}

	cmdline:= q IMagickDir "\" magickCmd ".exe " q " " q OriginalPicPath q " -monitor " CmdOptions " " q testpicPath q

	Gui, scan: Default
	GuiControl,scan: Hide   	, ChangedPic
	GuiControl,scan:          	, PicSize2     	, % ""
	GuiControl,scan: Show	, Waiting
	GuiControl,scan:          	, TextShow   	, % "-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --"
	GuiControl,scan: Show	, Textshow

	out:= StdOutToVar(cmdline)

	WinActivate, ImageMagick Test Gui

	Gui, scan: Default
	GuiControl,scan: Hide  	, Waiting
	GuiControl,scan: Hide  	, Textshow
	GuiControl,scan:          	, ChangedPic	, % testpicPath
	GuiControl,scan: Show	, ChangedPic
	GuiControl,scan:          	, Pic2Size     	, % GetImageDimensionString(testpicPath)

return

magickAC:

return
}

MagickCommands() {

	convertOptions =
	(LTrim
	-blur|geometry|adaptively blur pixels; decrease effect near edges
	-resize|geometry|adaptively resize image with data dependent triangulation.
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
	-clamp||set each pixel whose value is below zero to zero and any the pixel whose value is above the quantum range to the quantum range (e.g. 65535) otherwise the pixel value remains unchanged.
	-clip||clip along the first path from the 8BIM profile
	-mask|filename|associate clip mask with the image
	-path|id|clip along a named path from the 8BIM profile
	-clone|index|clone an image
	-clut||apply a color lookup table to the image
	-components|connectivity|connected-components uniquely labeled, choose from 4 or 8 way connectivity
	-stretch|geometry|improve the contrast in an image by `stretching' the range of intensity value
	-coalesce||merge a sequence of images
	-colorize|value|colorize the image with the fill color
	-matrix|matrix|apply color correction to the image.
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
	-features|distance|analyze image features (e.g. contract, correlations, etc.).
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
	-moments||display image moments.
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
	-regard-warnings||pay attention to warning messages.
	-region|geometry|apply options to a portion of the image
	-remap|filename|transform image colors to match this set of colors
	-render||render vector graphics
	-repage|geometry|size and location of an image canvas
	-resample|geometry|change the resolution of an image
	-resize|geometry|resize the image
	-respect-parentheses||settings remain in effect until parenthesis boundary.
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
	-unique-colors|discard all but one of any pixel color.
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

	MagickCommands          	:=Object()
	MagickCommands.convert	:=Object()
	Loop, Parse, convertOptions, `n, `r
	{
			li:= StrSplit(A_LoopField)
			MagickCommands.convert.Push({"cmd":li[1], "var": li[2], "info": li[3]})
	}
}

ReadIMOptions() {

	Loop
	{
				IniRead, iniVar, % A_ScriptFullPath, ImageMagickOptions, % "convert" A_Index
				If Instr(iniVar, "Error")
						break
				IMOptions.= iniVar "|"
	}

return RTrim(IMOptions, "|")
}

GetImageDimensionString(picFilePath) {
	IMG_GetImageSize(picFilePath ,Width, Height)
return Width "x" Height
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

IMG_GetImageSize(p_FileOrHandle,ByRef r_Width:=0,ByRef r_Height:=0) {								;-- https://www.autohotkey.com/boards/viewtopic.php?p=290795#p290795
    Static Dummy27649730

          ;-- Image types
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

    ;[===================]
    ;[  Animated Cursor  ]
    ;[===================]
    ;-- https://www.gdgsoft.com/anituner/help/aniformat.htm
    ;-- https://en.wikipedia.org/wiki/ANI_(file_format)
    ;-- https://en.wikipedia.org/wiki/Resource_Interchange_File_Format
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



/* saved magick commands
[ImageMagickOptions]
convert1=-mean-shift 7x7+50%
convert2=-antialias
convert3=-mean-shift 7x7+80%
convert4=-swirl 30
convert5=-swirl 60
convert6=-channel RGB -threshold 100%
convert7=-channel RGB -threshold 10%
convert8=-channel RGB -threshold 1%
convert9=-channel RGB -threshold 99%
convert10=-channel RGB -threshold 77%
convert11=-channel RGB -threshold 50%
convert12=-channel RGB -threshold 80%
convert13=-channel RGB -threshold 90%
convert14=-treedepth 0.5
convert15=-treedepth 0.1
convert16=-treedepth 0.8
convert17=-treedepth 1
convert18=-treedepth 1 -colors 8
convert19=-treedepth 0.3 -colors 16
convert20=-adaptive-blur 10x0.5
convert21=-adaptive-blur 30
convert22=-gamma .45455 -resize 25% -gamma 2.2
convert23=-resize 50%
*/

