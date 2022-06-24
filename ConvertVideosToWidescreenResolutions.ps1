################################################################################
#
# File Name: ConvertVideosToWidescreenResolutions.ps1
#
# Tested Platorm: Windows 10
#
# Original Author: Carlos Muñoz ("Mr. M"/"El Sr. M")
#
# Modified By: <your name/handle here>
#
# Required Windows Executables: ffmpeg.exe, ffprobe.exe
#
# Obtain Required Windows Executables: https://www.gyan.dev/ffmpeg/builds/
#
# Purpose: Automatically convert large batches of sorted videos to their nearest
#           standard widescreen resolution using "ffmpeg.exe" and "ffprobe.exe"
#           to scale up/down and also add black bars to the right+left and/or
#           top+bottom of the videos
#
# Reason: Some projectors, including the cheap one I have, don't deal with
#          non-standard resolutions very well when playing videos off a directly
#          attached USB drive, so this is the overkill workaround I created when
#          I had to process a large batch of videos (300+) for a project so that
#          I could have minimal output from ffmpeg (which doesn't have an option
#          to *only* display the information I'm interested in)
#
# Instructions:
#   0: Create and/or modify the directory paths noted in the "InputPath" and
#       "OutputPath" values for each output resolution in the "Setup Part 0"
#       section as desired, or create your own new ones
#   1: Move the videos to be modified to the appropriate input folder per the
#       desired output resolution
#   2: Modify the ffmpeg.exe command (near the end of this script) as desired 
#   3: Run this script in the PowerShell prompt
#   4: Go do something else while you wait for it to finish if it looks like it
#       is going to take a while
#
# Known Issues:
#   0: I am not a great PowerShell programmer. There is undoubtably a much, much
#       better way to do this
#   1: Both "ffmpeg.exe" and "ffprobe.exe" must be located in a directory that
#       is defined in your "PATH" variable. Moving those executables to:
#          C:\Users\<your windows username>\AppData\Local\Microsoft\WindowsApps\
#       *should* work if modifying the "PATH" variable is undesireable
#   2: If "ffmpeg.exe" throws an error, this script will hide it from view and
#       you might not be able to tell where it errored out or why it errored out
#   3: If there are filename collisions in *both* an input and an output folder,
#       only one collision error will be displayed and the second collision
#       error won't be displayed until the script is run again (you may have to
#       run this script a few times if there are lots of filename collisions in
#       order to clean those up)
#   4: If there are non-video files in any of the input folders, that will cause
#       "ffmpeg.exe" to throw an unseen error, so clear out those input folders
#       of all non-video files before running this script
#
################################################################################

################################################################################
# BEGIN: Setup Section
################################################################################

# -- Setup Part 0 --

# Define the videos, paths, and resolutions of 720 × 1280 (HD) videos
$ConversionData0720x1280 = [PSCustomObject]@{
	InputPath          = "$HOME\Videos\Modify\m0720x1280\"
	OutputPath         = "$HOME\Videos\Modified\"
	Height             = 720
	Width              = 1280
}
# Then add two more properties to the HD video object that depend on the object
# definition being completed (this is done separately because I know I would
# forget to modify all location instancess when I next update this script)
$ConversionData0720x1280 | Add-Member -MemberType NoteProperty `
	-Name "ListOfInputVideos" `
	-Value ( Get-ChildItem -Path $ConversionData0720x1280.InputPath -File | Select-Object -ExpandProperty Name )
$ConversionData0720x1280 | Add-Member -MemberType NoteProperty `
	-Name "ListOfOutputVideos" `
	-Value ( Get-ChildItem -Path $ConversionData0720x1280.OutputPath -File | Select-Object -ExpandProperty Name )

# - -

# Define the videos, paths, and resolutions of 1080 × 1920 (Full HD/FHD) videos
$ConversionData1080x1920 = [PSCustomObject]@{
	InputPath          = "$HOME\Videos\Modify\m1080x1920\"
	OutputPath         = "$HOME\Videos\Modified\"
	Height             = 1080
	Width              = 1920
}
# As with the HD video object, add two more properties to the FHD video object
$ConversionData1080x1920 | Add-Member -MemberType NoteProperty `
	-Name "ListOfInputVideos" `
	-Value ( Get-ChildItem -Path $ConversionData1080x1920.InputPath -File | Select-Object -ExpandProperty Name )
$ConversionData1080x1920 | Add-Member -MemberType NoteProperty `
	-Name "ListOfOutputVideos" `
	-Value ( Get-ChildItem -Path $ConversionData1080x1920.OutputPath -File | Select-Object -ExpandProperty Name )

# - -

# Define the videos, paths, and resolutions of 2160 × 3840 (UHD) videos
$ConversionData2160x3840 = [PSCustomObject]@{
	InputPath          = "$HOME\Videos\Modify\m2160x3840\"
	OutputPath         = "$HOME\Videos\Modified\"
	Height             = 2160
	Width              = 3840
}
# As with the HD video object, add two more properties to the UHD video object
$ConversionData2160x3840 | Add-Member -MemberType NoteProperty `
	-Name "ListOfInputVideos" `
	-Value ( Get-ChildItem -Path $ConversionData2160x3840.InputPath -File | Select-Object -ExpandProperty Name )
$ConversionData2160x3840 | Add-Member -MemberType NoteProperty `
	-Name "ListOfOutputVideos" `
	-Value ( Get-ChildItem -Path $ConversionData2160x3840.OutputPath -File | Select-Object -ExpandProperty Name )

# - -

# Define the videos, paths, and resolutions of 2160 × 4096 (4K) videos
$ConversionData2160x4096 = [PSCustomObject]@{
	InputPath          = "$HOME\Videos\Modify\m2160x4096\"
	OutputPath         = "$HOME\Videos\Modified\"
	Height             = 2160
	Width              = 4096
}
# As with the HD video object, add two more properties to the 4K video object
$ConversionData2160x4096 | Add-Member -MemberType NoteProperty `
	-Name "ListOfInputVideos" `
	-Value ( Get-ChildItem -Path $ConversionData2160x4096.InputPath -File | Select-Object -ExpandProperty Name )
$ConversionData2160x4096 | Add-Member -MemberType NoteProperty `
	-Name "ListOfOutputVideos" `
	-Value ( Get-ChildItem -Path $ConversionData2160x4096.OutputPath -File | Select-Object -ExpandProperty Name )

# ------------------------------------------------------------------------------

# -- Setup Part 1 --

# Define the collection of the above objects
$ConvertTheseVideos = New-Object System.Collections.Generic.List[System.Object]
$ConvertTheseVideos.Add( $ConversionData0720x1280 )
$ConvertTheseVideos.Add( $ConversionData1080x1920 )
$ConvertTheseVideos.Add( $ConversionData2160x3840 )
$ConvertTheseVideos.Add( $ConversionData2160x4096 )

# ------------------------------------------------------------------------------

# -- Setup Part 2 --

# If there are any filename collisions from the input and output folders, ffmpeg
# will throw an error. As currently set up, this will be silent (no displayed
# output) and look like the script has crashed. To prevent this, first test for
# any current naming collisions in the input and output folders.

# Create lists to hold all current videos in the input and output folders
$VideosInInputFoldersWithPaths     = New-Object System.Collections.Generic.List[System.Object]
$VideosInInputFoldersWithoutPaths  = New-Object System.Collections.Generic.List[System.Object]
$VideosInOutputFolders             = New-Object System.Collections.Generic.List[System.Object]
$VideoNamingCollisions             = New-Object System.Collections.Generic.List[System.Object]

################################################################################
# END: Setup Section
################################################################################

################################################################################
# BEGIN: Prep-Work Section
################################################################################

# Loop through each item in the collections to build a list of videos currently
# in the output folder(s)
ForEach ( $VideoObject in $ConvertTheseVideos ) {
	# Determine if there are videos already in the output folder
	If ( $VideoObject.ListOfOutputVideos ) {
		# Loop through the individual lists of videos
		ForEach ( $OutputFolderVideo in $VideoObject.ListOfOutputVideos ) {
			# Set up the output video and path
			$OutputFolderVideoWithPath = $VideoObject.OutputPath + $OutputFolderVideo
			# Check to see if the item is already in the array
			If ( $VideosInOutputFolders -iNotContains $OutputFolderVideoWithPath ) {
				# If it isn't, add the video (with full path) to the array
				$VideosInOutputFolders.Add( $OutputFolderVideoWithPath )
			}
		}
	}
}

# ------------------------------------------------------------------------------

# Loop through each item in the collections to build a list of videos that would
# be written to the output folder(s)
ForEach ( $VideoObject in $ConvertTheseVideos ) {
	# Determine if there are videos already in the input folder
	If ( $VideoObject.ListOfInputVideos ) {
		# Loop through the individual lists of videos
		ForEach ( $InputFolderVideo in $VideoObject.ListOfInputVideos ) {
			# Set up the input video and path
			$InputFolderVideoWithPath = $VideoObject.InputPath + $InputFolderVideo
			# Set up the output video and path
			$OutputFolderVideoWithPath = $VideoObject.OutputPath + $InputFolderVideo
			# Check to see if there would be a naming collision
			If ( $VideosInInputFoldersWithoutPaths -iContains $InputFolderVideo ) {
				# This would result in an error, so add it to a list
				$VideoNamingCollisions.Add( "input:  " + $VideosInInputFoldersWithPaths.Where( { $_ -Match $InputFolderVideo } ) )
				$VideoNamingCollisions.Add( "input:  $InputFolderVideoWithPath" )
			}
			# Check to see if there is a collision with existing videos in the
			# output folder(s)
			ElseIf ( $VideosInOutputFolders -iContains $OutputFolderVideoWithPath ) {
				# This would result in an error, so add it to a list
				$VideoNamingCollisions.Add( "output: $InputFolderVideoWithPath" )
			}
			Else {
				# Add the video (with full path) to the arrays
				$VideosInInputFoldersWithPaths.Add( $InputFolderVideoWithPath )
				$VideosInInputFoldersWithoutPaths.Add( $InputFolderVideo )
			}
		}
	}
}

################################################################################
# END: Prep-Work Section
################################################################################

################################################################################
# BEGIN: Work Section
################################################################################

# From the Setup Section, there may be filename collisions. If so, error out in
# a nice way and give the user information on what is causing the collision(s)
If ( $VideoNamingCollisions ) {
	# Sort the collisions to group file names together, start by creating a
	# temporary array to store transient data (I tried doing it "in-line" with
	# the current array, but that didn't work)
	$TemporaryArray = New-Object System.Collections.Generic.List[System.Object]
	# Then reverse each string in the collision array and put that in the
	# temporary array
	ForEach ( $Collision in $VideoNamingCollisions ) {
		# Modified from: https://learn-powershell.net/2012/08/12/reversing-a-string-using-powershell/
		$TemporaryArray.Add( ( [Regex]::Matches( $Collision, ".", "RightToLeft" ) | ForEach-Object { $_.Value } ) -Join "" )
	}
	#Sort that array
	$TemporaryArray = $TemporaryArray | Sort-Object
	# Clear the initial array
	$VideoNamingCollisions.Clear()
	# Reverse the reversed strings and re-add them to the original array
	ForEach ( $TemporaryString in $TemporaryArray ) {
		# Modified from: https://learn-powershell.net/2012/08/12/reversing-a-string-using-powershell/
		$VideoNamingCollisions.Add( ( [Regex]::Matches( $TemporaryString, ".", "RightToLeft" ) | ForEach-Object { $_.Value } ) -Join "" )
	}
	# Display the collisions for the user to fix
	ForEach ( $Collision in $VideoNamingCollisions ) {
		Write-Host "Filename collision with $Collision" -BackgroundColor Yellow -ForegroundColor Red
	}
}
# If there are no filename collisions, proceed with video processing
Else {
	# Announce the start of video processing
	Write-Host " Starting Video Processing "  -BackgroundColor DarkCyan -ForegroundColor White
	# Start a stopwatch for the overall processing time
	$AllVideosConversionStopwatch = [Diagnostics.Stopwatch]::StartNew()
	# Loop through each item in the collection
	ForEach ( $VideoObject in $ConvertTheseVideos ) {
		# Determine if there are videos in each list that should be converted
		If ( $VideoObject.ListOfInputVideos ) {
			# Loop through the individual lists of videos
			ForEach ( $Video in $VideoObject.ListOfInputVideos ) {
				# Set up the strings representing the input and output (I tried
				# having these "in-line" with the individual commands but that
				# didn't work)
				$InputFileWithPath  = $VideoObject.InputPath + $Video
				$OutputFileWithPath = $VideoObject.OutputPath + $Video
				$FrameHeight = $VideoObject.Height
				$FrameWidth  = $VideoObject.Width
				# Get the overall length of the current video
				# Modified from: https://superuser.com/questions/650291/how-to-get-video-duration-in-seconds
				$CurrentVideoLength = ffprobe.exe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 $InputFileWithPath
				# Get the overall size (kB, MB, GB, etc.) of the current video
				$CurrentVideoRawSize = ( Get-Item $InputFileWithPath ).Length
				# Convert that size data into a human-readable format
				# Modified from: https://www.spguides.com/check-file-size-using-powershell/
				If ( $CurrentVideoRawSize -gt 1TB ) {
					$CurrentVideoReadableSize = [String]::Format( "{0:0.00} TB", $CurrentVideoRawSize / 1TB )
				}
				ElseIf ( $CurrentVideoRawSize -gt 1GB ) {
					$CurrentVideoReadableSize = [String]::Format( "{0:0.00} GB", $CurrentVideoRawSize / 1GB )
				}
				ElseIf ( $CurrentVideoRawSize -gt 1MB ) {
					$CurrentVideoReadableSize = [String]::Format( "{0:0.00} MB", $CurrentVideoRawSize / 1MB )
				}
				ElseIf ( $CurrentVideoRawSize -gt 1KB ) {
					$CurrentVideoReadableSize = [String]::Format( "{0:0.00} kB", $CurrentVideoRawSize / 1KB )
				}
				ElseIf ( $CurrentVideoRawSize -gt 0 ) {
					$CurrentVideoReadableSize = [String]::Format( "{0:0.00} B", $CurrentVideoRawSize ) }
				Else {
					$CurrentVideoReadableSize = ""
				}
				# Announce which video is about to be processed
				Write-Host "   Starting Input: " -BackgroundColor Magenta -ForegroundColor White -NoNewline
				Write-Host " $InputFileWithPath" -ForegroundColor Magenta
				# Announce the total run time of the video being processed
				Write-Host "      Current Video Length: " -NoNewline
				Write-Host ( "{0:hh\:mm\:ss\.ff}" -f [TimeSpan]::FromSeconds( $CurrentVideoLength ) ) -ForegroundColor Blue -NoNewline
				# Announce the total size of the video being processed
				Write-Host "   Total Video Size: " -NoNewline
				Write-Host $CurrentVideoReadableSize -ForegroundColor DarkMagenta
				# Start a stopwatch
				$VideoConversionStopwatch = [Diagnostics.Stopwatch]::StartNew()
				# Run ffmpeg.exe to modify the video
				# Modify this command (anything before the "2>&1 | `" line) as
				# desired for a different video transformation
				# Modified from: https://stackoverflow.com/questions/46671252/how-to-add-black-borders-to-video
				ffmpeg.exe `
					-i $InputFileWithPath `
					-vf "scale=(iw*sar)*min(${FrameWidth}/(iw*sar)\,${FrameHeight}/ih):ih*min(${FrameWidth}/(iw*sar)\,${FrameHeight}/ih), pad=${FrameWidth}:${FrameHeight}:(${FrameWidth}-iw*min(${FrameWidth}/iw\,${FrameHeight}/ih))/2:(${FrameHeight}-ih*min(${FrameWidth}/iw\,${FrameHeight}/ih))/2" `
					$OutputFileWithPath `
					2>&1 | `
					Select-String -Pattern 'time=[^\s]+' | `
					ForEach-Object { $_.Matches } | `
					ForEach-Object { $_.Value.Substring( 5 ) } | `
					ForEach-Object {
						# Announce the current time position (I wish I could
						# find where I learned the carriage return ("`r")
						# combined with the "-NoNewline" flag trickery again so
						# I could give proper credit)
						Write-Host "`r          Current Position: " -NoNewline;
						Write-Host $_ -ForegroundColor Red -NoNewline;
						# Announce the current percentage completed
						Write-Host "          Completed: " -NoNewline;
						Write-Host ( [Math]::Round( 100 * ( [TimeSpan]::Parse( $_ ) ).TotalSeconds / $CurrentVideoLength, 2 ) ).ToString("00.00") -ForegroundColor Cyan -NoNewline;
						Write-Host "%" -ForegroundColor Cyan -NoNewline
					}
				# Stop the stopwatch
				$VideoConversionStopwatch.Stop()
				# Announce how long the processing of that video took
				Write-Host "`r     Video Processing Time: " -NoNewline
				Write-Host ( "{0:hh\:mm\:ss\.ff}" -f [TimeSpan]::FromSeconds( $VideoConversionStopwatch.Elapsed.TotalSeconds ) ) -ForegroundColor Cyan -NoNewline
				# Announce that the process has been completed (otherwise the
				# last percentage will be left on the screen)
				Write-Host "          Completed: " -NoNewline
				Write-Host "100%  " -ForegroundColor Green
				# Announce that the current video is done being processed
				Write-Host "  Finished Output: " -BackgroundColor Green -ForegroundColor White -NoNewline
				Write-Host " $OutputFileWithPath" -ForegroundColor Green
			}
		}
	}
	# Stop the overall processing time stopwatch
	$AllVideosConversionStopwatch.Stop()
	# Announce that all videos have completed processing
	Write-Host " All Videos Have Completed Processing "  -BackgroundColor DarkCyan -ForegroundColor White -NoNewline
	Write-Host  "   Total Processing Time: " -NoNewline
	Write-Host ( "{0:hh\:mm\:ss\.ff}" -f [TimeSpan]::FromSeconds( $AllVideosConversionStopwatch.Elapsed.TotalSeconds ) ) -ForegroundColor Cyan -NoNewline
}
################################################################################
# END: Work Section
################################################################################