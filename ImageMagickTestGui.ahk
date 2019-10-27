;ImageMagickTestGui - script by Ixiko last change: 27.10.2019

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
	If (A_ScreenWidth > 1920)
		fSize1:= 20, fSize2:= 14
	else
		fSize1:= 16, fSize2:= 10

	Gui, scan: New, -DPIScale ;, ;+AlwaysOnTop
	Gui, scan: Margin, 5, 5
	Gui, scan: Color, cA0A0A0
	Gui, scan: Add, Picture, % "xm ym w-1 h" Floor(A_ScreenHeight/1.5)  " 0xE vOriginalPic HWNDhOrigninalPic", % OriginalPicPath
	GuiControlGet, p, scan: Pos, OriginalPic
	Gui, scan: Add, Picture, % "x+5 ym w" pW " h" pH " 0xE vChangedPic HWNDhChangedPic", % ""
	Gui, scan: Add, Combobox, % "xm y+10 w" 100 "r1 vmagickCmd gmagickAC HWNDhmagickCmd", % "convert|magick|compare|composite|conjure|identify|mogrify|montage|stream"
	Gui, scan: Add, Combobox, % "x+5 w" (pW * 2) - 150  "r1 vCmdOptions HWNDhCmdOptions", % IMOptions
	Gui, scan: Add, Button     	, % "xm y+5 vRun gRunImageMagick HWNDhRun", % "Run ImageMagick"
	Gui, scan: Font, % "s" fsize1 " cRED"
	Gui, scan: Add, Text            , % "x" pW+5 " y" Floor(pH/2) " w" pW " vWaiting Center", work in progress...
	Gui, scan: Add, Text            , % "x" pW+5 " y+10 w" pW " vTextshow Center", % "-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --"
	Gui, scan: Font, % "s" fsize2 " cBlue"
	Gui, scan: Add, Text            , % "xm ym+10 w" pW " vOriginal BackgroundTrans Center", original picture
	Gui, scan: Add, Text            , % "x" pW+5 " ym+10 w" pW-5 " vModified BackgroundTrans Center", modified picture
	GuiControl,scan: Hide, Waiting
	GuiControl,scan: Hide, Textshow
	Gui, scan: Font, s10 cBlack
	Gui, scan: Show, AutoSize, ImageMagick Test Gui

	GuiControl, scan: ChooseString, magickCmd, convert

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
	cmdline:= q IMagickDir "\" magickCmd ".exe " q " " q OriginalPicPath q " -monitor " CmdOptions " " q picPath "\IMagickTest.tif" q
	GuiControl,scan: Hide, ChangedPic
	GuiControl,scan: Show, Waiting
	GuiControl,scan:, TextShow, % "-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --"
	GuiControl,scan: Show, Textshow
	out:= StdOutToVar(cmdline)
	WinActivate, ImageMagick Test Gui
	Gui, scan: Default
	GuiControl,scan: Hide, Waiting
	GuiControl,scan: Hide, Textshow
	GuiControl,scan: , ChangedPic, % picPath "\IMagickTest.tif"
	GuiControl,scan: Show, ChangedPic

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
*/


