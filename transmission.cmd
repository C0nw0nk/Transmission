@ECHO OFF & setLocal EnableDelayedExpansion

:: Copyright Conor McKnight
:: https://github.com/C0nw0nk/Transmission
:: https://www.facebook.com/C0nw0nk

:: To run this Automatically open command prompt RUN COMMAND PROMPT AS ADMINISTRATOR and use the following command
:: SCHTASKS /CREATE /SC HOURLY /TN "Cons Transmission Script" /RU "SYSTEM" /TR "C:\Windows\System32\cmd.exe /c start /B "C:\transmission\transmission.cmd"

:: Script Settings

:: IF you like my work please consider helping me keep making things like this
:: DONATE! The same as buying me a beer or a cup of tea/coffee :D <3
:: PayPal : https://paypal.me/wimbledonfc
:: https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=ZH9PFY62YSD7U&source=url
:: Crypto Currency wallets :
:: BTC BITCOIN : 3A7dMi552o3UBzwzdzqFQ9cTU1tcYazaA1
:: ETH ETHEREUM : 0xeD82e64437D0b706a55c3CeA7d116407E43d7257
:: SHIB SHIBA INU : 0x39443a61368D4208775Fd67913358c031eA86D59

::Transmission settings file name
set settings_file=settings.json

::Transmission settings file path
set settings_file_path=%LocalAppData%\transmission\%settings_file%

::Transmission installation path
set transmission_path=%ProgramFiles%\Transmission\

::Transmission GUI executable path
set transmission_qt_exe=transmission-qt.exe

::Transmission daemon executable path
set transmission_daemon_exe=transmission-daemon.exe

::Transmission Daemon service settings location
set transmission_daemon_settings=C:\Windows\ServiceProfiles\LocalService\AppData\Local\transmission-daemon\settings.json

::download-dir as a example i have shown a network sharing path you can change it to a drive path like C:\\path
::double back slashes on path is mandatory for path to be recognized by transmission
::set transmission_download_directory="C:\\Users\\con\\Downloads"
set transmission_download_directory="\\\\con-laptop\\d\\transmission\\complete"

::incomplete-dir as a example i have shown a network sharing path you can change it to a drive path like C:\\path
::double back slashes on path is mandatory for path to be recognized by transmission
::set transmission_incomplete_directory="C:\\Users\\con\\Downloads"
set transmission_incomplete_directory="\\\\con-laptop\\d\\transmission\\incomplete"

::PIA installation path PrivateInternetAccess VPN
set PIA_path="C:\Program Files\Private Internet Access\piactl.exe"

::Check for port change every 60 seconds if the port changes we will set the port as the new vpn portforward
set port_recheck_time=60

::Speed that transmission torrent client downloads at in kB/s i set default at 0 download speed unlimited
:: 0 = Unlimited download speed
set transmission_download_speed=0

::Speed that transmission torrent client uploads at in kB/s i set default at 1kB per second save bandwidth
:: 0 = Unlimited upload speed
set transmission_upload_speed=1

:: End Edit DO NOT TOUCH ANYTHING BELOW THIS POINT UNLESS YOU KNOW WHAT YOUR DOING!

color 0A
%*
TITLE C0nw0nk - Automatic Transmission Script - PrivateInternetAccess PortForward

set root_path=%~dp0

if not exist "%settings_file_path%" goto :settings_incorrect
if not exist "%transmission_path%" goto :transmission_not_installed
if not exist %PIA_path% goto :PIA_not_installed

::enable or disable download and upload speed
if /I %transmission_download_speed% == 0 (
	set transmission_download_speed_enabled=false
) else (
	set transmission_download_speed_enabled=true
)
if /I %transmission_upload_speed% == 0 (
	set transmission_upload_speed_enabled=false
) else (
	set transmission_upload_speed_enabled=true
)

::5 seconds to wait for vpn to establish connection to perform check on port
set connection_time=5

::Make sure that the temporary files used does not exist already.
del "%TEMP%\%settings_file%" 2>nul
del "%TEMP%\daemon%settings_file%" 2>nul
del "%TEMP%\regions.txt" 2>nul

for /f "tokens=*" %%a in ('
%PIA_path% get regions 2^>nul
') do (
	if /I %%a == auto (
		break
	) else (
		echo %%a>>"%TEMP%\regions.txt"
	)
)

:random_country

::153 lines of text
set /a rand=%random% %% 153
for /f "tokens=1* delims=:" %%i in ('findstr /n .* "%TEMP%\regions.txt"') do (
if "%%i"=="%rand%" set random_country=%%j
)
echo Random Country to connect to : %random_country%
if defined connect_new (
	echo current vpn server does not allow port forward connecting to a different one
	%PIA_path% ^set region %random_country%
	%PIA_PATH% connect
	timeout /t %connection_time% >nul
)

for /f "tokens=*" %%a in ('
%PIA_path% get requestportforward 2^>nul
') do (
	if /I %%a == false (
		%PIA_path% ^set requestportforward true
		%PIA_path% ^set region %random_country%
		%PIA_PATH% connect
	)
)

:recheck_portforward

for /f "tokens=*" %%a in ('
%PIA_path% get portforward 2^>nul
') do (
	if /I %%a == Inactive (
		set connect_new=true
		goto :random_country
	)
	if /I %%a == Unavailable (
		set connect_new=true
		goto :random_country
	)
	if /I %%a == Failed (
		set connect_new=true
		goto :random_country
	)
	if /I %%a == Attempting (
		goto :recheck_portforward
	)
	set portforward=%%a
)
set peer-port=%portforward%
echo Currently forwarding Port : %portforward%
timeout /t %connection_time% >nul

if defined old_peer_port (goto :checkme) else (goto :next_stage)
:checkme
if /I %old_peer_port% == %peer-port% (
	echo ports matched unchanged
	goto :recheck_portforward_change
) else (
	echo ports miss match
)

goto :next_stage

:recheck_portforward_change
echo rechecking difference with ports
if defined  old_peer_port (
	if /I %old_peer_port% == %peer-port% (
		echo unchanged port going to recheck again in %port_recheck_time% seconds
		timeout /t %port_recheck_time% >nul
		goto :recheck_portforward
	) else (
		echo port changed modifying settings
		goto :next_stage
	)
)
goto :recheck_portforward_change

:next_stage

for /F "tokens=1* delims=:" %%A in (%settings_file_path%) do (
    if /I %%A == ^ ^ ^ ^ ^"peer^-port^" (
        echo %%A: %peer-port%,>>"%TEMP%\%settings_file%"
    ) else (
        if /I %%A == ^{ (
			echo %%A>>"%TEMP%\%settings_file%"
		) else (
			if /I %%A == ^} (
				echo %%A>>"%TEMP%\%settings_file%"
			) else (
				if /I %%A == ^ ^ ^ ^ ^"download^-dir^" (
					echo %%A: %transmission_download_directory%,>>"%TEMP%\%settings_file%"
				) else (
					if /I %%A == ^ ^ ^ ^ ^"incomplete^-dir^" (
						echo %%A: %transmission_incomplete_directory%,>>"%TEMP%\%settings_file%"
					) else (
						if /I %%A == ^ ^ ^ ^ ^"speed^-limit^-down^" (
							echo %%A: %transmission_download_speed%,>>"%TEMP%\%settings_file%"
						) else (
							if /I %%A == ^ ^ ^ ^ ^"speed^-limit^-down^-enabled^" (
								echo %%A: %transmission_download_speed_enabled%,>>"%TEMP%\%settings_file%"
							) else (
								if /I %%A == ^ ^ ^ ^ ^"speed^-limit^-up^" (
									echo %%A: %transmission_upload_speed%,>>"%TEMP%\%settings_file%"
								) else (
									if /I %%A == ^ ^ ^ ^ ^"speed^-limit^-up^-enabled^" (
										echo %%A: %transmission_upload_speed_enabled%,>>"%TEMP%\%settings_file%"
									) else (
										echo %%A:%%B>>"%TEMP%\%settings_file%"
									)
								)
							)
						)
					)
				)
			)
		)
	)
)

for /F "tokens=1* delims=:" %%A in (%transmission_daemon_settings%) do (
    if /I %%A == ^ ^ ^ ^ ^"peer^-port^" (
        echo %%A: %peer-port%,>>"%TEMP%\daemon%settings_file%"
    ) else (
		if /I %%A == ^{ (
			echo %%A>>"%TEMP%\daemon%settings_file%"
		) else (
			if /I %%A == ^} (
				echo %%A>>"%TEMP%\daemon%settings_file%"
			) else (
				if /I %%A == ^ ^ ^ ^ ^"download^-dir^" (
					echo %%A: %transmission_download_directory%,>>"%TEMP%\daemon%settings_file%"
				) else (
					if /I %%A == ^ ^ ^ ^ ^"incomplete^-dir^" (
						echo %%A: %transmission_incomplete_directory%,>>"%TEMP%\daemon%settings_file%"
					) else (
						if /I %%A == ^ ^ ^ ^ ^"speed^-limit^-down^" (
							echo %%A: %transmission_download_speed%,>>"%TEMP%\daemon%settings_file%"
						) else (
							if /I %%A == ^ ^ ^ ^ ^"speed^-limit^-down^-enabled^" (
								echo %%A: %transmission_download_speed_enabled%,>>"%TEMP%\daemon%settings_file%"
							) else (
								if /I %%A == ^ ^ ^ ^ ^"speed^-limit^-up^" (
									echo %%A: %transmission_upload_speed%,>>"%TEMP%\daemon%settings_file%"
								) else (
									if /I %%A == ^ ^ ^ ^ ^"speed^-limit^-up^-enabled^" (
										echo %%A: %transmission_upload_speed_enabled%,>>"%TEMP%\daemon%settings_file%"
									) else (
										echo %%A:%%B>>"%TEMP%\daemon%settings_file%"
									)
								)
							)
						)
					)
				)
			)
		)
    )
)

for /f "tokens=*" %%a in ('
taskkill /im %transmission_daemon_exe% /t /f 2^>Nul
') do break
for /f "tokens=*" %%a in ('
taskkill /im %transmission_qt_exe% /t /f 2^>Nul
') do break

move /Y "%TEMP%\%settings_file%" %settings_file_path% >nul
move /Y "%TEMP%\daemon%settings_file%" %transmission_daemon_settings% >nul

start "" /b "%transmission_path%%transmission_daemon_exe%" >nul
start "" /b "%transmission_path%%transmission_qt_exe%" >nul

set old_peer_port=%peer-port%
goto :recheck_portforward_change

:settings_incorrect
echo settings path not found please fix and try again.
goto :end
:transmission_not_installed
echo transmission is not installed please install it first and try again.
goto :end
:PIA_not_installed
echo Private Internet Access not installed please install it first and try again.
goto :end
:end

pause

exit
