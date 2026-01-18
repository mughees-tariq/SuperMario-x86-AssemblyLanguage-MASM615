INCLUDE Irvine32.inc
INCLUDELIB winmm.lib

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PlaySound PROTO, pszSound:PTR BYTE, hmod:DWORD, fdwSound:DWORD

SND_SYNC        EQU 00000000h   ;Play and wait
SND_ASYNC       EQU 00000001h   ;Play and continue
SND_LOOP        EQU 00000008h   ;Loop the sound
SND_FILENAME    EQU 00020000h   ;Specifies that the name is a filename

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Constants:
screenWidth = 80
screenHeight = 25
screenSize = screenWidth * screenHeight
maxEnemies = 10
maxPowerUps = 5
maxProjectiles = 4
maxPlatforms = 8
                              ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Game States:
menu = 0
playing = 1
paused = 2
lost = 3
won = 4
showingScore = 5
highScores = 6
                              ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Objects:
goomba = 1
koopa = 2
paratroopa = 3
piranha = 4
bowser = 5
mushroom = 6
fireFlower = 7
iceFlower = 8
star = 9
coin = 10
block = 11
pipe = 12
platform = 13
fireBar = 14
lava = 15
flagPole = 16
                              ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Colors:
black = 0
blue = 1
green = 2
cyan = 3
red = 4
magenta = 5
brown = 6
lightGray = 7
darkGray = 8
lightBlue = 9
lightGreen = 10
lightCyan = 11
lightered = 12
lightMagenta = 13
yellow = 14
white = 15

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Structures:
Character Struct
	xCord db 10
	yCord db 20
	char db "M"
	color db lightBlue

	isJumping db 0
	isFalling db 0
	isOnGround db 0
	isSuper db 0		;; (0,1) = (small mario, large mario)
	isFire db 1			;;Have to keep this 1 always because of my roll number (24I-0806)
	;isIce db 0
	isInvincible db 0
	isRunning db 0
	
	lives db 3
	score dword 0
	coins db 0
	jumpTimer db 0
	;iceTimer db 0
	;invincibleTimer db 0

	fireColor db lightBlue
	;iceCount db 0
Character ends
                              ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
gameObject Struct
	xCord db 0
	yCord db 0
	char db 0
	color db 0
	active db 0
	objectType db 0		;;(0,1,2) = (enemy, block, powerup)
	xVel db 0
	yVel db 0
	timer db 0
	data db 0
gameObject ends
                              ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Scene Struct
	sceneNumber db 0
	sceneType db 0	;;(0,1,2) = (grass, underground, sky, castle)
	bgColor db 0
	groundLevel db 20
	timeLimit db 30

	enemies gameObject maxEnemies dup(<>)
	powerups gameObject maxPowerUps dup(<>)
	blocks gameObject 50 dup(<>)
	platforms gameObject maxPlatforms dup(<>)

	enemyCount db 0
	powerCount db 0
	blockCount db 0
	platfCount db 0

	hasWeather db 0
	hasBreakable db 0
	hasMovingPlatforms db 0
	hasDayNight db 0
	hasSmartEnemies db 0
Scene ends
                              ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Projectile Struct
	xCord db 0
	yCord db 0
	char db 0
	color db 0
	active db 0
	direction db 0	;;(0,1) = (Left, Right)
	isIce db 0		;;(0,1) = (Fire, Ice)
Projectile ends

Rain Struct
	xCord db 10 dup(0)
	yCord db 10 dup(0)
	isActive db 0
Rain ends

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.data
	;States:
		gameState db menu
		currentScene db 0
		isGamePaused db 0
		gameTime dd 0
		sceneTimer db 30
		totalScore db 0
		menuSelection db 1
		isBossLoaded db 0
                              ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;Player:
		mario Character<>
		ballX db 2 dup(0)
		ballY db 2 dup(0)
		ballActive db 2 dup(0)
		ballColor db 2 dup(blue)
                              ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;Scenes:
		scene1 Scene<>
		;Coins:
			scene1coinsX db 33, 34, 35, 53, 54
			scene1coinsY db 16, 16, 16, 14, 14
			scene1active db 1, 1, 1, 1, 1
		;Enemies:
			scene1GoombaX db 40, 60, 25
			scene1GoombaY db 20, 20, 20
			scene1GoombaActive db 1, 1, 1
			scene1GoombaDirection db 1, 0, 1
		;RainDrops:
			rainX db 10 dup (0)
			rainY db 10 dup (0)
			rainActive db 10 dup(0)
			rainDamageCooldown db 0

		scene2 Scene<>
		;Coins:
			scene2coinsX db 25, 40, 55, 60, 75
			scene2coinsY db 18, 16, 14, 18, 16
			scene2active db 1, 1, 1, 1, 1
		;Enemies:
			scene2KoopaX db 35, 55, 70
			scene2KoopaY db 20, 20, 20
			scene2KoopaActive db 1, 1, 1
			scene2KoopaDirection db 0, 1, 0
			scene2KoopaState db 0,0,0
			scene2KoopaShellTimer db 0,0,0
		;Star Room:
			starX db 40
			starY db 13
			starActive db 1
			starRoomCoinsX db 37, 37, 39, 40, 41, 43, 43
			starRoomCoinsY db 10, 11, 11, 11, 11, 11, 10
			starRoomCoinsActive db 1,1,1,1,1,1,1
			inStarRoom db 0
			starRoomExitX db 0
			starRoomExitY db 0
		;Bonus:
			scene2EnemiesDefeated db 0
			flagBonusEarned dword 0
			timeBonusEarned dword 0
			enemyBonusEarned dword 0
			levelCompleted db 0
			flagTop db ".", 0
		
		scene3 Scene<>
		;Coins:
			scene3coinsX db 40, 50, 60, 30, 45
			scene3coinsY db 18, 18, 18, 16, 16
			scene3active db 1, 1, 1, 1, 1
		;Enemies:
			bossX db 0
			bossY db 0
			bossHp db 7
			bossActive db 1
			bossDirection db 0
			bossFireDirection db 2 dup (0)
			bossFireX db 2 dup(0)
			bossFireY db 2 dup(0)
			bossFireActive db 2 dup(0)
			bossFireColor db 2 dup(red)
		;Environment:
			giveLife db 1
			bossHpDisplay db "| Boss HP = ", 0
			floatingPlatformX db 47     
			floatingPlatformDir db 1    
			floatingPlatformSpeed db 2  
			floatingPlatformMinX db 10   
			floatingPlatformMaxX db 68
			onMovingPlatform db 0
                              ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;Weather Effects:
		raindrops rain<>

	;Projectiles:
		;fireBalls projectile maxProjectiles dup (<>)
		;iceBalls projectile maxProjectiles dup (<>)
                              ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;Input:
		keyPressed db 0
                              ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;Displays:
		gameTitle db "Super Mario", 0
		rollNumber db "Roll Number: 24I-0806", 0
		startGame db "1. Start Game", 0
		highscore db "2. High Scores", 0
		exitGame db "3. Exit Game", 0
		gameControlsInstructions db "A = Left | D = Right | SpaceBar = Jump | F = Fire | P = Pause", 0
        pauseInstructions db "P = Unpause | E = Exit Game", 0    
		pressAnyKeyText db "Press any key to continue...", 0

		scoreDisplay db "Scores: ",0
		coinsDisplay db "Coins: ", 0
		sceneDisplay db "Scene: ", 0
		livesDisplay db "Lives: ", 0
		timeDisplay db "Time: ", 0

		gamePaused db "Game Paused", 0 
		gameLost db "Game Lost", 0
		gameWon db "Game Won", 0

		cloud1Line1 db "  _  _   ", 0
		cloud1Line2 db " ( )( )  ", 0
		cloud1Line3 db " (____)  ", 0

		cloud2Line1 db "   __   ", 0
		cloud2Line2 db " _(  )_ ", 0
		cloud2Line3 db "(______)", 0
                              ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;Music files:
		jumpSound db "jump.wav", 0
		coinSound db "coin.wav", 0
		enemySound db "enemy.wav", 0
		flagSound db "flag.wav", 0
		powerupSound db "powerup.wav", 0
		sceneSound1 db "scene1.wav", 0
		sceneSound2 db "scene2.wav", 0
		sceneSound3 db "scene3.wav", 0
		titleSound db "title.wav", 0
		resultSound db "won.wav", 0
		previousPtr dd 0
		soundTimer dd 0
		switchSound db 0
                              ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;Scores management:
		namePrompt db "Enter your name (max 20 chars): ", 0
		nameBuffer db 21 dup(0)          
		nameLength db 0
		highScoreTitle db "=== HIGH SCORES ===", 0
		noScoresMsg db "No high scores yet!", 0

		esiTemp dd 0
		esiIndex dd 0
		eaxNameLength dd 0

		playerName db 21 dup(0)
		scoreValue dword 10 dup (0)               
		
		fileLineBuffer db 50 dup(0)
		tempIntBuffer db 11 dup(0)         
		newLineChars db 13, 10, 0          
		
		scoreFileName db "highscores.txt", 0  
		fileHandle2 dword ?                

		;highScoreRecords highScoreRecord 10 dup(<>)
		scoreCount db 0  

		tempNameBuffer db 21 dup(0)
		tempScoreBuffer db 11 dup(0)     ; Max 10 digits + null
		fileErrorMsg db "Error accessing scores file!", 0
		fileCreatedMsg db "Created new scores file", 0

		scoreLineBuffer db "  ", 21 dup(' '), " - ", 10 dup(' '), 0
		rankDisplay db "1.", 0

		;Win screen messages:
		lowScoreMsg db "Keep practicing!", 0
		averageScoreMsg db "Good job! Try for more coins!", 0
		goodScoreMsg db "Excellent score!", 0
		excellentScoreMsg db "AMAZING! You're a Mario master!", 0
    
		;Lose screen messages:
		timeOutMsg db "Time ran out! Be faster next time!", 0
		fellMsg db "Watch your step! Try again!", 0
		highScorePrompt db "Great score! Check the high scores!", 0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.code
                              ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
main proc
	call initializeGame
	call gameLoop
	exit
main endp
                              ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
initializeGame proc
	mov floatingPlatformX, 47
	mov floatingPlatformDir, 1
	mov floatingPlatformSpeed, 2
	
	mov ballActive[0], 0
	mov ballActive[1], 0
	mov ballX[0], 0
    mov ballX[1], 0
    mov ballY[0], 0
    mov ballY[1], 0

	mov isBossLoaded, 0
	mov givelife, 1

	;mov iceFlowerActive, 1
	;mov iceFlowerX, 50
	;mov iceFlowerY, 14

	mov bossX, 40   
	mov bossY, 20 
	mov bosshP, 7    
	mov bossActive, 1    
	mov bossDirection, 0

	mov ecx, 2           
    mov esi, 0
    initializeBoss:
        mov bossFireActive[esi], 0
        mov bossFireX[esi], 0
        mov bossFireY[esi], 0
        mov bossFireDirection[esi], 0
        inc esi
        loop initializeBoss

	mov mario.xCord, 10
    mov mario.yCord, 20
    mov mario.char, 'M'
    mov mario.color, blue
    mov mario.isFire, 1
    mov mario.fireColor, lightBlue
    mov mario.lives, 3
    mov mario.score, 0
    mov mario.coins, 0
    mov mario.isJumping, 0
    mov mario.isFalling, 0
    mov mario.jumpTimer, 0
    mov mario.isOnGround, 1
    mov mario.isSuper, 0
    mov mario.isInvincible, 0
    mov mario.isRunning, 0

	;;;;;;;;;;;;;;;;;;;;
	mov gamestate, menu
	mov currentScene, 0
	mov sceneTimer, 30
	mov gameTime, 0
	mov keyPressed, 0
	;;;;;;;;;;;;;;;;;;;;

	mov ecx, 5
    mov esi, 0
    resetScene1Coins:
        mov scene1active[esi], 1
        inc esi
        loop resetScene1Coins

	mov ecx, 3
    mov esi, 0
    resetScene1Enemies:
        mov scene1GoombaActive[esi], 1
        inc esi
        loop resetScene1Enemies

	mov ecx, 5
    mov esi, 0
    resetScene2Coins:
        mov scene2active[esi], 1
        inc esi
        loop resetScene2Coins

	mov ecx, 3
    mov esi, 0
    resetScene2Enemies:
        mov scene2KoopaActive[esi], 1
        mov scene2KoopaState[esi], 0
        mov scene2KoopaShellTimer[esi], 0
        inc esi
        loop resetScene2Enemies

	mov ecx, 5
    mov esi, 0
    resetScene3Coins:
        mov scene3active[esi], 1
        inc esi
        loop resetScene3Coins

	mov inStarRoom, 0
    mov starActive, 1
    mov starRoomExitX, 0
    mov starRoomExitY, 0

	mov ecx, 7
    mov esi, 0
    resetStarRoomCoins:
        mov starRoomCoinsActive[esi], 1
        inc esi
        loop resetStarRoomCoins

	mov scene2EnemiesDefeated, 0
    mov flagBonusEarned, 0
    mov timeBonusEarned, 0
    mov enemyBonusEarned, 0
    mov levelCompleted, 0

	mov onMovingPlatform, 0

	mov previousPtr, 0
	mov soundTimer, 0
	mov switchSound, 0
	call playTitleSound
	call initializeScene1
	ret
initializeGame endp
                              ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
gameLoop proc
	mainGameLoop:
		cmp gameState, menu
		je menuDisplay
		cmp gameState, playing
		je playDisplay
		cmp gameState, paused
		je pauseDisplay
		cmp gameState, lost 
		je lostDisplay
		cmp gameState, won
		je wonDisplay
		cmp gameState, showingScore
		je showingScoreDisplay
		cmp gameState, highScores
		je highScoresDisplay
		
	mov gameState, menu

	menuDisplay:
		call drawTitleScreen
		call menuInput
		mov eax, 50
		call delay
		jmp mainGameLoop

	playDisplay:
		call drawGameScreen
		call gameInput
		call updateGame
		call checkCollision
		mov eax, 110
		call delay
		jmp mainGameLoop

	pauseDisplay:
		call drawPauseScreen
		call pauseInput
		mov eax, 50
		call delay
		jmp mainGameLoop

	lostDisplay:
		call drawLostScreen
		call lostInput
		mov eax, 50
		call delay
		jmp mainGameLoop

	wonDisplay:
		call drawWonScreen
		call wonInput
		mov eax, 50
		call delay
		jmp mainGameLoop

	showingScoreDisplay:
		ret

	highScoresDisplay:
		call displayHighScores
        call highScoresInput
        mov eax, 50
        call delay
        jmp mainGameLoop

	ret
gameLoop endp

                    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
										;Menu Procedures:
drawTitleScreen proc
	mov eax, white + (blue * 16)
    call SetTextColor
	call clrscr

	mov eax, yellow + (blue * 16)
	call setTextColor

	;Game title:
	mov dl, 33 
	mov dh, 5      
	call Gotoxy
	mov edx, OFFSET gameTitle
    call WriteString

	;Roll Number:
	mov dl, 28
    mov dh, 7
    call Gotoxy
	mov edx, OFFSET rollNumber
    call WriteString

	mov eax, lightGray + (blue * 16)
    call SetTextColor

	;Cloud1:
	mov dl, 20
    mov dh, 10
    call gotoxy
    mov edx, OFFSET cloud2Line1
    call writeString
    mov dl, 20
    mov dh, 11
    call gotoxy
    mov edx, OFFSET cloud2Line2
    call writeString
    mov dl, 20
    mov dh, 12
    call gotoxy
    mov edx, OFFSET cloud2Line3
    call writeString

	;Cloud2:
	mov dl, 50
    mov dh, 10
    call gotoxy
    mov edx, OFFSET cloud2Line1
    call writeString
    mov dl, 50
    mov dh, 11
    call gotoxy
    mov edx, OFFSET cloud2Line2
    call writeString
    mov dl, 50
    mov dh, 12
    call gotoxy
    mov edx, OFFSET cloud2Line3
    call writeString

	mov eax, lightGreen + (blue * 16)
    call setTextColor

	;Start Game option:
	mov dl, 32
    mov dh, 15
    call gotoxy
    mov edx, OFFSET startGame
    call writeString
    
	;High Scores option:
    mov dl, 32
    mov dh, 16
    call gotoxy
    mov edx, OFFSET highscore
    call writeString

	;Exit Game option:
	mov dl, 32
    mov dh, 17
    call gotoxy
    mov edx, OFFSET exitGame
    call writeString
	ret
drawTitleScreen endp
                                  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
menuInput proc
	call readKey
	jz noInput

	cmp al, '1'
	je option1
	cmp al, '2'
	je option2
	cmp al, '3'
	je option3

	jmp noInput
	option1:
		call getNameInput
		call playSceneSound1
		mov gameState, playing
		ret

	option2:
		mov gameState, highscores
		ret

	option3:
		exit

	noInput:
		mov eax, 50
		call delay
		ret
menuInput endp
                                  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
getNameInput proc
    
    mov eax, white + (blue * 16)
    call setTextColor
    call clrscr
    
    mov eax, yellow + (blue * 16)
    call setTextColor
    mov dl, 25
    mov dh, 10
    call gotoxy
    mov edx, offset namePrompt
    call writeString
    
    mov dl, 25
    mov dh, 12
    call gotoxy
    
    mov edx, offset nameBuffer
    mov ecx, 20
    call ReadString
    mov nameLength, al    
    
    cmp al, 0
    jne nameEntered
    
    mov edi, offset nameBuffer
    mov byte ptr [edi], 'P'
    mov byte ptr [edi+1], 'l'
    mov byte ptr [edi+2], 'a'
    mov byte ptr [edi+3], 'y'
    mov byte ptr [edi+4], 'e'
    mov byte ptr [edi+5], 'r'
    mov byte ptr [edi+6], 0
    mov nameLength, 6
    
    nameEntered:
    mov eax, 1000
    call Delay
    
    ret
getNameInput endp
                                  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
comment!
readHighScores proc
    mov scoreCount, 0   
    
    mov edx, offset scoreFileName
    call OpenInputFile
    cmp eax, invalid_handle_value
    je createNewFile
    
    mov fileHandle2, eax
    mov esi, 0          
    
	readLoop:
		cmp esi, 10
		jge closeFile1
    
		mov edx, offset fileLineBuffer
		mov ecx, 50         
		mov eax, fileHandle2
		call ReadFromFile
		jc closeFile1     
		cmp eax, 0          
		je closeFile1
    
		mov edi, offset fileLineBuffer
    
		mov ecx, 50
		mov al, ','
		repne scasb
		jnz skipBadLine     
    
		mov ebx, edi
		sub ebx, offset fileLineBuffer
		dec ebx             
    
		mov ecx, ebx
		mov esiIndex, esi   
		mov esi, offset fileLineBuffer
		mov edi, offset tempNameBuffer
		cld
		rep movsb
		mov byte ptr [edi], 0  
    
		mov edx, offset tempScoreBuffer
		mov ecx, 10
		call ClearBuffer
    
		mov edi, offset fileLineBuffer
	    add edi, ebx        
		inc edi             
    
		mov esi, edi
		mov edi, offset tempScoreBuffer

	copyScoreLoop:
	    mov al, [esi]
		cmp al, 0
		je convertScore
		cmp al, 13          
		je convertScore
		cmp al, 10          
		je convertScore
		mov [edi], al
		inc esi
		inc edi
		jmp copyScoreLoop
    
	convertScore:
		mov byte ptr [edi], 0
    
		mov edx, offset tempScoreBuffer
		call ParseInteger32
		jc skipBadLine     
    
		mov esi, esiIndex   
    
   
		mov eax, esi
		mov ebx, type highScoreRecord
		mul ebx
    
		lea edi, highScoreRecords[eax].playerName
		mov esiTemp, esi    
		mov esi, offset tempNameBuffer
		mov ecx, 21
		cld
		rep movsb
    
		mov esi, esiTemp    
		lea edi, highScoreRecords[eax].scoreValue
		mov [edi], eax      
    
		inc esi
		inc scoreCount
		jmp readLoop
    
	skipBadLine:
		mov esi, esiIndex   
		jmp readLoop
    
closeFile1:
    mov eax, fileHandle2
    call CloseFile
    ret
    
createNewFile:
    mov edx, offset scoreFileName
    mov ecx, 0          
    call CreateOutputFile
    mov fileHandle2, eax
    call CloseFile
    
    mov ecx, 10
    mov esi, 0
	initLoop:
		mov eax, esi
		mov ebx, type highScoreRecord
	    mul ebx
		lea edi, highScoreRecords[eax].playerName
		mov byte ptr [edi], 0
		lea edi, highScoreRecords[eax].scoreValue
		mov dword ptr [edi], 0
		inc esi
		loop initLoop
    
    ret
readHighScores endp
!
                                  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
comment!
writeHighScores proc
    mov edx, offset scoreFileName
    mov ecx, 0          
    call CreateOutputFile
    cmp eax, INVALID_HANDLE_VALUE
    je writeError
    mov fileHandle2, eax
    
    mov esi, 0          
writeLoop:
    cmp esi, 10
    jge closeWriteFile
    
    mov eax, esi
    mov ebx, type highScoreRecord
    mul ebx
    
    lea edi, highScoreRecords[eax].playerName
    cmp byte ptr [edi], 0
    je skipEmpty        
    
    mov ecx, 0
    mov edx, edi
countNameLength:
    cmp byte ptr [edx], 0
    je doneCounting
    inc ecx
    inc edx
    jmp countNameLength
    
doneCounting:
    mov eaxNameLength, ecx
    
    mov eax, fileHandle2
    mov edx, edi
    mov ecx, eaxNameLength
    call WriteToFile
    
    mov al, ','
    mov tempScoreBuffer, al
    mov eax, fileHandle2
    mov edx, offset tempScoreBuffer
    mov ecx, 1
    call WriteToFile
    
    mov eax, esi
    mov ebx, type highScoreRecord
    mul ebx
    lea edi, highScoreRecords[eax].scoreValue
    mov eax, [edi]

    mov edi, offset tempScoreBuffer
    call ConvertIntToString
    
    mov eax, fileHandle2
    mov edx, offset tempScoreBuffer
    mov ecx, 0
getScoreLength:
    cmp byte ptr [edx+ecx], 0
    je foundScoreLength
    inc ecx
    jmp getScoreLength
    
foundScoreLength:
    call WriteToFile
    
    mov eax, fileHandle2
    mov edx, offset newLineChars
    mov ecx, 2
    call WriteToFile
    
skipEmpty:
    inc esi
    jmp writeLoop
    
closeWriteFile:
    mov eax, fileHandle2
    call CloseFile
    ret
    
writeError:
    ret
writeHighScores endp
                                  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ClearBuffer proc
    push edi
    mov edi, edx
    mov al, 0
    rep stosb
    pop edi
    ret
ClearBuffer endp

ConvertIntToString proc
    pushad
    
    test eax, eax
    jns positive
    mov byte ptr [edi], '-'
    inc edi
    neg eax
    
positive:
    mov ebx, 10
    mov ecx, 0
    
pushDigits:
    xor edx, edx
    div ebx
    add dl, '0'
    push edx
    inc ecx
    test eax, eax
    jnz pushDigits
    
popDigits:
    pop eax
    mov [edi], al
    inc edi
    loop popDigits
    
    mov byte ptr [edi], 0
    
    popad
    ret
ConvertIntToString endp
!
                                  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
displayHighScores proc
    mov eax, white + (blue * 16)
    call setTextColor
    call clrscr
    
    mov eax, yellow + (blue * 16)
    call setTextColor
    mov dl, 30
    mov dh, 7
    call gotoxy
    mov edx, offset highScoreTitle
    call writeString

    ;call loadScoresFromFile  

	comment!
    mov dh, 5                
    mov ecx, 0               
	displayLoop:
		cmp cl, scoreCount
		jge noMoreScores

    mov eax, 0
    mov al, cl
    mov bl, 21
    mul bl
    add eax, offset playerName
    
    mov edx, 0
    mov dl, cl
    shl edx, 2              
    add edx, offset scoreValue

    mov eax, lightCyan + (blue * 16)
    call SetTextColor
    mov dl, 25
    call Gotoxy
    mov eax, ecx
    inc eax
    call WriteDec
    mov al, '.'
    call WriteChar
    
    mov eax, white + (blue * 16)
    call SetTextColor
    mov dl, 28
    call Gotoxy
    mov edx, eax            
    call WriteString
    
    mov dl, 50
    call Gotoxy
    mov eax, [edx]          
    call WriteDec
    
    inc dh
    inc cl
    jmp displayLoop
    
	noMoreScores:
    cmp scoreCount, 0
    jne showInstructions
	!
    
    mov eax, lightGray + (blue * 16)
    call setTextColor
    mov dl, 30
    mov dh, 10
    call gotoxy
    mov edx, offset noScoresMsg
    call writeString

    mov dl, 27
    mov dh, 13
    call gotoxy
    mov edx, offset pressAnyKeyText
    call writeString
    
	waitForKey:
        call readKey
        jz waitForKey
    
    mov gameState, menu
    ret
displayHighScores endp
                                  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
comment!
loadScoresFromFile proc
    mov scoreCount, 0
    
    mov edx, offset scoreFileName
    call OpenInputFile
    cmp eax, INVALID_HANDLE_VALUE
    je noFile
    
    mov fileHandle2, eax
    mov ecx, 0               
    
readLoop:
    cmp cl, 10               
    jge closeLoadFile
    
    mov edx, offset fileLineBuffer
    push ecx
    mov ecx, 50
    mov eax, fileHandle2
    call ReadFromFile
    pop ecx
    
    jc closeLoadFile
    cmp eax, 0
    je closeLoadFile
    
    cmp byte ptr [fileLineBuffer], 13
    je closeLoadFile
    cmp byte ptr [fileLineBuffer], 10
    je closeLoadFile
    cmp byte ptr [fileLineBuffer], 0
    je closeLoadFile
    
    mov esi, offset fileLineBuffer
    mov edi, offset tempNameBuffer
    
readNameLoad:
    mov al, [esi]
    cmp al, ','
    je foundCommaLoad
    cmp al, 13
    je skipLine
    cmp al, 10
    je skipLine
    cmp al, 0
    je skipLine
    
    mov [edi], al
    inc esi
    inc edi
    jmp readNameLoad
    
foundCommaLoad:
    mov byte ptr [edi], 0
    inc esi
    
    mov eax, 0
    mov al, cl
    mov bl, 21
    mul bl
    add eax, offset playerName
    mov edi, eax
    
    mov esi, offset tempNameBuffer
copyNameLoop:
    mov al, [esi]
    mov [edi], al
    inc esi
    inc edi
    cmp byte ptr [esi], 0
    jne copyNameLoop
    mov byte ptr [edi], 0  
    
    mov ebx, 0              
    
readScoreLoad:
    mov al, [esi]
    cmp al, '0'
    jl endScoreLoad
    cmp al, '9'
    jg endScoreLoad
    
    sub al, '0'
    movzx eax, al
    
    push ecx
    mov ecx, ebx
    shl ebx, 3              
    add ebx, ecx            
    add ebx, ecx            
    add ebx, eax            
    pop ecx
    
    inc esi
    jmp readScoreLoad
    
endScoreLoad:
    mov eax, 0
    mov al, cl
    shl eax, 2              
    add eax, offset scoreValue
    mov [eax], ebx          
    
    inc cl                  
    inc scoreCount
    jmp readLoop
    
skipLine:
    jmp readLoop
    
closeLoadFile:
    mov eax, fileHandle2
    call CloseFile
    ret
    
noFile:
    mov scoreCount, 0
    ret
loadScoresFromFile endp
!
                                  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
comment!
displayHighScoresScreen proc
    
    mov eax, white + (blue * 16)
    call setTextColor
    call clrscr
    
    mov eax, yellow + (blue * 16)
    call setTextColor
    mov dl, 30
    mov dh, 3
    call otoxy
    mov edx, offset highScoreTitle
    call WriteString

    cmp scoreCount, 0
    jne displayScores

    mov eax, lightGray + (blue * 16)
    call SetTextColor
    mov dl, 30
    mov dh, 10
    call Gotoxy
    mov edx, offset noScoresMsg
    call WriteString
    jmp displayInstructions
    
displayScores:
    mov esi, 0          
    mov ebx, 5          
    
displayLoop:
    cmp esi, 10
    jge displayInstructions
    
    mov eax, esi
    mov ecx, type highScoreRecord
    mul ecx
    
    lea edi, highScoreRecords[eax].playerName
    cmp byte ptr [edi], 0
    je skipEmptyDisplay
    
    mov eax, lightCyan + (blue * 16)
    call SetTextColor
    mov dl, 25
    mov dh, bl
    call Gotoxy
    mov eax, esi
    inc eax
    call WriteDec
    mov al, '.'
    call WriteChar
    
    mov eax, white + (blue * 16)
    call SetTextColor
    mov dl, 28
    mov dh, bl
    call Gotoxy
    mov edx, edi
    call WriteString
    
    mov dl, 50
    mov dh, bl
    call Gotoxy
    lea edi, highScoreRecords[eax].scoreValue
    mov eax, [edi]
    call WriteDec
    
skipEmptyDisplay:
    inc esi
    inc ebx
    jmp displayLoop
    
displayInstructions:
    mov eax, lightGray + (blue * 16)
    call SetTextColor
    mov dl, 25
    mov dh, 22
    call Gotoxy
    mov edx, offset pressAnyKeyText
    call WriteString
    
    ret
displayHighScoresScreen endp
!
                                  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
highScoresInput proc

	ret
    call ReadKey
    jz noInput
    
    mov gameState, menu
    
    noInput:
        ret
highScoresInput endp
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


















					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
										;Game Procedures:
drawGameScreen PROC
    ;mov eax, white + (lightBlue * 16)

	cmp currentScene, 2
    jne notBoss1
    mov eax, white + (lightblue * 16)
    jmp setColor1
	notBoss1:
    mov eax, white + (lightBlue * 16)
	setColor1:
    call setTextColor
    call clrscr

	call drawControlsInfo
	call drawBoss
	call drawProjectiles  
	call drawbossFireballs
    call drawHeader
    call drawGround
    call drawMario
    call drawObstacles
	call drawEnemies
	call drawRain
    ret
drawGameScreen ENDP
                                  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
gameInput proc
	
	call readKey
	jz noInput

	cmp al, 'a'
	je moveLeft
	cmp al, 'A'
	je moveLeft
	cmp al, 'd'
	je moveRight
	cmp al, 'D'
	je moveRight
	cmp al, ' '
	je jumpMove
	cmp al, 'p'
	je pauseGame
	cmp al, 'P'
	je pauseGame
	cmp al, 'f'
	je fire
	cmp al, 'F'
	je fire

	moveLeft:
		cmp mario.xCord, 0
		jle noInput
		dec mario.xCord
		ret

	moveRight:
		inc mario.xCord
		cmp mario.xCord, 79
		jl noInput
		cmp currentScene, 2
		jne normalExit
		cmp bossActive, 1
		je blockExit
    
		normalExit:
			call nextScene
			ret
		blockExit:
			dec mario.xCord
			jmp noInput

	jumpMove:
		cmp mario.isOnGround, 1
		jne noInput

		mov mario.isOnGround, 0
		mov mario.isJumping, 1
		mov mario.jumpTimer, 8
		call playJumpSound
		jmp noInput

	pauseGame:
		mov gameState, paused
		jmp noInput

	fire:
		cmp mario.isFire, 1
		jne noInput
		call createFireBall

	noInput:
	ret
gameInput endp
                                  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
updateGame proc
	mov eax, gameTime
	mov ebx, 9
	mov edx, 0
	div ebx
	cmp edx, 0
	jne skipInc
	inc soundTimer
	skipInc:
	call updateSound

	cmp gameState, paused
	je skipAll

	cmp mario.isJumping, 1
	jne chkGravity
	call processJump
	jmp checkBounds

	chkGravity:
		cmp mario.isOnGround, 1
		je checkBounds
		call gravity

	checkBounds:
		cmp mario.yCord, 24
		jg marioFell
		cmp mario.yCord, 1
		jl hitCeiling
		;ret

	inc gameTime

	cmp inStarRoom, 1
    je skipTimer

	mov eax, gameTime
	mov ebx, 9
	mov edx, 0
	div ebx
	cmp edx, 0
	jne skipTimer

	cmp sceneTimer, 0
	je skipTimer
	dec sceneTimer

	cmp sceneTimer, 0
	jne skipTimer

	dec mario.lives
	cmp mario.lives, 0
	jle timeOver

	mov mario.xCord, 10
	mov mario.yCord, 20
    mov mario.isJumping, 0
    mov mario.isFalling, 0
    mov mario.isOnGround, 1

	cmp currentScene, 2
	je resetBossTimer
	mov sceneTimer, 30
	jmp skipTimer

	resetBossTimer:
		mov sceneTimer, 60
		jmp skipTimer

	timeOver:
		call playResultSound
		mov gameState, lost

	skipTimer:

	mov eax, gameTime
	and eax, 3
	cmp eax, 0
	jne skipAll

	call updateProjectiles
	call updateRain
	call updateEnemies
	call updateBoss
	call updatebossFireballs

	cmp currentScene, 2
	jne skipPlatformUpdate

	mov al, floatingPlatformDir
	cmp al, 0
	je movePlatformLeft

	;Moving the platform right:
		mov al, floatingPlatformX
		add al, floatingPlatformSpeed
		mov floatingPlatformX, al

	;Checking if mario is on platform:
		cmp onMovingPlatform, 1
		jne checkPlatformMax
		mov al, floatingPlatformSpeed
		add mario.xCord, al

	checkPlatformMax:
		mov al, floatingPlatformMaxX
		cmp floatingPlatformX, al
		jl skipPlatformUpdate
		mov floatingPlatformDir, 0 
		mov al, floatingPlatformMaxX
		jmp skipPlatformUpdate

	movePlatformLeft:
		mov al, floatingPlatformX
		sub al, floatingPlatformSpeed
		mov floatingPlatformX, al

		cmp onMovingPlatform, 1
		jne checkPlatformMin
		mov al, floatingPlatformSpeed
		sub mario.xCord, al 

		cmp mario.xCord, 0
		jge checkPlatformMin
		mov mario.xCord, 0
	
	checkPlatformMin:
		mov al, floatingPlatformMinX
		cmp floatingPlatformX, al
		jg skipPlatformUpdate
		mov floatingPlatformDir, 1 
		mov floatingPlatformX, al

	skipPlatformUpdate:
		mov onMovingPlatform, 0
		ret

	marioFell:
		dec mario.lives
		cmp mario.lives, 0
		jle gameOver

		mov mario.xCord, 10
		mov mario.yCord, 20
	    mov mario.isJumping, 0
		mov mario.isFalling, 0
	    mov mario.isOnGround, 1
		ret
		
	hitCeiling:
		mov mario.isJumping, 0
		mov mario.isFalling, 1
		ret

	gameOver:
		;call saveAllScores
		call playResultSound
		mov gameState, lost

	skipAll:
		ret
updateGame endp
                                  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
gravity proc
	cmp mario.isOnGround, 1
	je stillMoving

	cmp mario.isJumping, 1
	je stillMoving

	cmp mario.isFalling, 1
    je moveDown

	mov mario.isFalling, 1

	moveDown:
		inc mario.yCord
		cmp mario.yCord, 20
		jl stillmoving

		mov mario.yCord, 20
		mov mario.isFalling, 0
		mov mario.isOnGround, 1

	stillMoving:
		ret
gravity endp
                                  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
processJump proc
	dec mario.jumpTimer
	cmp mario.jumpTimer, 0
	jle endJump

	dec mario.yCord
	cmp mario.yCord, 2
	jg continueJump
	mov mario.jumpTimer, 0

	continueJump:
		ret

	endJump:
		mov mario.isJumping, 0
		mov mario.isFalling, 1
		ret
processJump endp
                                  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
checkCollision proc
	cmp mario.yCord, 20 
    jl platformCollision
    
	mov mario.yCord, 20
    mov mario.isOnGround, 1
    mov mario.isFalling, 0
	mov mario.isJumping, 0
	
	call checkCoinCollision
	call checkStarCollision
	call checkStarCoinCollision
	call checkStarRoomExitCollision
	call checkRainCollision
	;call checkIceFlowerCollision
	call checkEnemyCollision
	call checkLavaCollision
	call checkBossCollision
    ret

	platformCollision:
		call checkPlatformCollision
		call checkCoinCollision
		call checkStarCollision
		call checkStarCoinCollision
		call checkStarRoomExitCollision
		call checkRainCollision
		;call checkIceFlowerCollision
		call checkEnemyCollision
		call checkLavaCollision
		call checkBossCollision
		ret
checkCollision endp
								  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
checkPlatformCollision proc

	cmp instarRoom, 1
	je starRoomPlatforms
	
	cmp currentScene, 0
    je scene1Check
    cmp currentScene, 1
    je scene2Check
    cmp currentScene, 2
    je scene3Check
    ret

	scene1Check:
		;Checking Platform 1:
			cmp mario.yCord, 16
			jne checkNext1

			mov al, mario.xCord
			cmp al, 30
			jl checkNext1
			cmp al, 39
			jg checkNext1

		;On platform 1:
			mov mario.isOnGround, 1
			mov mario.isFalling, 0
			ret
	
		;Checking Platform 2:
		checkNext1:
			cmp mario.yCord, 14
			jne none
    
			mov al, mario.xCord
			cmp al, 50
			jl none
			cmp al, 57
			jg none

		;On platform 2:
			mov mario.isOnGround, 1
			mov mario.isFalling, 0
			ret

	scene2Check:
		;Checking Platform 1:
			cmp mario.yCord, 15
			jne checkNext2

			mov al, mario.xCord
			cmp al, 20
			jl checkNext2
			cmp al, 27
			jg checkNext2

		;On platform 1:
			mov mario.isOnGround, 1
			mov mario.isFalling, 0
			ret
	
		;Checking Platform 2:
		checkNext2:
			cmp mario.yCord, 13
			jne none
    
			mov al, mario.xCord
			cmp al, 45
			jl none
			cmp al, 50
			jg none

		;On platform 2:
			mov mario.isOnGround, 1
			mov mario.isFalling, 0
			ret

	scene3Check:
		cmp giveLife, 1
		jne checkPlatform1
		cmp mario.yCord, 6
		jne checkPlatform1
		cmp mario.xCord, 15
		jne checkPlatform1

		inc mario.lives
		mov givelife, 0
		add mario.score, 1000
		call playPowerupSound

		checkPlatform1:
		cmp mario.yCord, 14
		jne pl2

		mov al, mario.xCord
		cmp al, 35
		jl pl2
		cmp al, 44
		jg pl2

		mov mario.isOnGround, 1
		mov mario.isFalling, 0
		ret

		pl2:
		cmp mario.yCord, 10
		jne pl3

		mov al, mario.xCord
		cmp al, 42
		jl pl3
		cmp al, 49
		jg pl3

		mov mario.isOnGround, 1
		mov mario.isFalling, 0
		ret

		pl3:
		cmp mario.yCord, 6
		jne none

		mov al, mario.xCord
		mov bl, floatingPlatformX
		cmp al, bl
		jl none
		add bl, 5
		cmp al, bl
		jg none

		mov mario.isOnGround, 1
		mov mario.isFalling, 0
		mov onMovingPLatform, 1
		ret

	starRoomPlatforms:
		cmp mario.yCord, 14
		jle checkStarRoomWalls
		mov mario.yCord, 14
		mov mario.isOnGround, 1
	    mov mario.isFalling, 0
		mov mario.isJumping, 0
		ret

		checkStarRoomWalls:
			cmp mario.xCord, 31
			jg checkRightWall
			mov mario.xCord, 31
			ret
    
		checkRightWall:
			cmp mario.xCord, 49
			jl noStarRoomCollision
			mov mario.xCord, 49
			ret

		noStarRoomCollision:
	none:
		mov mario.isOnGround, 0
		ret
checkPlatformCollision endp
								  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
checkLavaCollision proc
    cmp currentScene, 2
    jne none
    
    cmp mario.yCord, 20
    jne none
    
    mov al, mario.xCord
    cmp al, 15
    je hitLava
    cmp al, 30
    je hitLava
    cmp al, 50
    je hitLava
    cmp al, 65
    je hitLava
    jmp none
    
hitLava:
    dec mario.lives
    cmp mario.lives, 0
    jle gameOverLava
    
    mov mario.xCord, 10
    mov mario.yCord, 20
    mov mario.isJumping, 0
    mov mario.isFalling, 0
    mov mario.isOnGround, 1
    ret
    
gameOverLava:
    mov gameState, lost
	call playResultSound
    ret
    
none:
    ret
checkLavaCollision endp

nextScene proc

	cmp currentScene, 1
    jne noBonus
	call calculateBonus

	noBonus:
	inc currentScene
	cmp currentScene, 2
	jl regularScene
	cmp currentScene, 2
	je bossScene

	cmp currentScene, 3
    jne checkWin
    cmp bossActive, 1
    je bossStillAlive

	checkWin:
		call playResultSound
		mov gameState, won
		ret

	regularScene:
		mov mario.xCord, 0
		mov mario.yCord, 20
		mov sceneTimer, 30
		mov inStarRoom, 0
		mov scene2EnemiesDefeated, 0
		mov levelCompleted, 0
		jmp sceneCleanup
		ret

	bossScene:
		cmp bossActive, 0
		je bossAlreadyDead
		
		mov mario.xCord, 0
		mov mario.yCord, 20
		mov sceneTimer, 60
		mov inStarRoom, 0
		jmp sceneCleanup

	bossAlreadyDead:
		mov gameState, won
		call playResultSound
		ret

	bossStillAlive:
		dec currentScene
		ret

	sceneCleanup: 
		mov esi, 0
        mov ecx, 2
        clearBallsLoop:
            mov ballActive[esi], 0 
            mov ballX[esi], 0      
            mov ballY[esi], 0
            inc esi
            loop clearBallsLoop

	cmp currentScene, 1
    je playScene2Sound
    cmp currentScene, 2
    je playScene3Sound
    jmp skipSound
    
    playScene2Sound:
        call playSceneSound2
        jmp noReset
    
    playScene3Sound:
        call playSceneSound3
        jmp noReset
	
	skipSound:
		cmp currentScene, 1       
		je resetRain
		cmp currentScene, 2        
		je resetBoss
		jmp noReset

	resetRain:
		mov ecx, 10
		mov esi, 0
			resetRainLoop:
			mov rainActive[esi], 0
			inc esi
			loop resetRainLoop
		jmp noReset

	resetBoss:
		mov ecx, 2
        mov esi, 0
        resetBossFireLoop:
            mov bossFireActive[esi], 0
            mov bossFireX[esi], 0
            mov bossFireY[esi], 0
            inc esi
            loop resetBossFireLoop

	noReset:
		ret
    
nextScene endp
                                  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
drawHeader proc
	mov eax, white + (blue * 16)
    call setTextColor
    
	;Scores:
	    mov dh, 0
		mov dl, 0
	    call gotoxy
		mov edx, offset scoreDisplay
	    call writeString
		mov eax, mario.score
		call writeDec

	;Coins:
		mov dh, 0
		mov dl, 18
	    call gotoxy
		mov edx, offset coinsDisplay
	    call writeString
		movzx eax, mario.coins
		call writeDec

	;Scene:
		mov dh, 0
		mov dl, 36
	    call gotoxy
		mov edx, offset sceneDisplay
		call writeString
		movzx eax, currentScene
		inc eax
		call writeDec

	;Time:
		mov dh, 0
		mov dl, 54
		call gotoxy
		mov edx, offset timeDisplay
		call writeString
		movzx eax, sceneTimer
		call writeDec
    
    ;Lives:
		mov dh, 0
	    mov dl, 72
		call gotoxy
		mov edx, offset livesDisplay
		call writeString
		movzx eax, mario.lives
		call writeDec

	mov dh, 1
    mov dl, 0
    call gotoxy
    mov ecx, 80
    mov al, '='
	separator:
		call WriteChar
		loop separator
	ret
drawHeader endp
                                  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
drawGround proc

	cmp inStarRoom, 1
	je drawStarRoomBg

	cmp currentScene, 2
	je bossGround

	mov eax, green + (lightBlue * 16)
    call setTextColor

	mov dh, 21
    mov dl, 0
    call gotoxy

	mov ecx, 80
	mov al, 219
	drawGroundLoop:
		call writeChar
		loop drawGroundLoop

	mov eax, brown + (lightBlue * 16)
    call setTextColor
	call drawScenePlatforms

	cmp currentScene, 1
	jne noFlag

	mov eax, white + (lightBlue * 16)
	call setTextColor

	mov dh, 14
	mov dl, 79
	call gotoxy
	mov ecx, 7
	mov al, '|'
	drawFlagPole:
		call writeChar
		inc dh
		mov dl, 79
		call gotoxy
		loop drawFlagPole

	mov dh, 13
	mov dl, 79
	call gotoxy
	mov edx, offset flagTop    
	call writeString
	noFlag:
	ret

	bossGround:
	mov eax, brown + (lightblue * 16)
    call setTextColor

	mov dh, 21
    mov dl, 0
    call gotoxy

	mov ecx, 80
	mov al, 178
	drawGroundLoop2:
		call writeChar
		loop drawGroundLoop2

	mov eax, white + (lightblue * 16)
    call setTextColor
    mov dh, 22
    mov dl, 62
    call gotoxy
	mov edx, offset bossHpDisplay
    call writeString

	movzx eax, bossHp
	call writeDec  
	mov al, '/'
	call writeChar
	mov al, '7'
	call writeChar

	mov eax, red + (lightblue * 16)
    call setTextColor

	;LavaBlocks:
	mov dh, 21
    mov dl, 15      
    call gotoxy
    mov al, 178     
    call writeChar
	mov dh, 21
    mov dl, 30
    call gotoxy
    mov al, 178
    call writeChar
    mov dh, 21
    mov dl, 50
    call gotoxy
    mov al, 178
    call writeChar
	mov dh, 21
    mov dl, 65      
    call gotoxy
    mov al, 178
    call writeChar
	cmp giveLife, 1
	jne skipIt
	mov dh, 6
	mov dl, 15
	call gotoxy
	mov al, 'L'
	call writeChar
	skipit:
	call drawScenePlatforms
	ret

	drawStarRoomBg:
		mov eax, white + (black * 16)
		call setTextColor

		mov dh, 6
		mov dl, 30
		call gotoxy
		mov ecx, 21
		mov al, 205  
		drawBorderTop:
			call writeChar
			loop drawBorderTop
	
		mov dh, 15
		mov dl, 30
		call gotoxy
		mov ecx, 21
		drawBorderBottom:
			call writeChar
			loop drawBorderBottom

		mov dh, 7
		mov dl, 30
		drawLeftBorder:
			call gotoxy
			mov al, 186
			call writeChar
			inc dh
			cmp dh, 15
			jl drawLeftBorder

		mov dh, 7
		mov dl, 50
		drawRightBorder:
			call gotoxy
			mov al, 186
			call writeChar
			inc dh
			cmp dh, 15
			jl drawRightBorder
	ret
drawGround endp
                                  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
drawScenePlatforms proc
	movzx eax, currentScene
    
    cmp eax, 0
    je platform1
    cmp eax, 1
    je platform2
    cmp eax, 2
    je platform3
    ret

	platform1:
		mov dh, 17
		mov dl, 30
		call gotoxy
		mov ecx, 10
		mov al, 178
		platform11:
			call writeChar
			loop platform11

		mov dh, 15
		mov dl, 50
		call gotoxy
		mov ecx, 8
		mov al, 178
		platform12:
			call writeChar
			loop platform12

		mov eax, white + (lightBlue * 16)
		call SetTextColor

		;Cloud1:
		mov dl, 17
	    mov dh, 9
	    call gotoxy
	    mov edx, OFFSET cloud2Line1
	    call writeString
	    mov dl, 17
	    mov dh, 10
	    call gotoxy
	    mov edx, OFFSET cloud2Line2
	    call writeString
	    mov dl, 17
	    mov dh, 11
	    call gotoxy
		mov edx, OFFSET cloud2Line3
		call writeString

		;Cloud2:
		mov dl, 55
		mov dh, 6
	    call gotoxy
	    mov edx, OFFSET cloud2Line1
	    call writeString
	    mov dl, 55
		mov dh, 7
		call gotoxy
		mov edx, OFFSET cloud2Line2
		call writeString
	    mov dl, 55
	    mov dh, 8
	    call gotoxy
	    mov edx, OFFSET cloud2Line3
	    call writeString
		ret

	platform2:
		mov dh, 16
	    mov dl, 20
		call gotoxy
		mov ecx, 8
		mov al, 178
		platform21:
			call writeChar
			loop platform21
    
		mov dh, 14
		mov dl, 45
		call gotoxy
		mov ecx, 6
		mov al, 178
		platform22:
		    call writeChar
			loop platform22

		mov eax, white + (lightBlue * 16)
		call SetTextColor

		;Cloud1:
		mov dl, 19
	    mov dh, 9
	    call gotoxy
	    mov edx, OFFSET cloud2Line1
	    call writeString
	    mov dl, 19
	    mov dh, 10
	    call gotoxy
	    mov edx, OFFSET cloud2Line2
	    call writeString
	    mov dl, 19
	    mov dh, 11
	    call gotoxy
		mov edx, OFFSET cloud2Line3
		call writeString

		;Cloud2:
		mov dl, 53
		mov dh, 6
	    call gotoxy
	    mov edx, OFFSET cloud2Line1
	    call writeString
	    mov dl, 53
		mov dh, 7
		call gotoxy
		mov edx, OFFSET cloud2Line2
		call writeString
	    mov dl, 53
	    mov dh, 8
	    call gotoxy
	    mov edx, OFFSET cloud2Line3
	    call writeString

		;Cloud3:
		mov dl, 37
		mov dh, 8
	    call gotoxy
	    mov edx, OFFSET cloud1Line1
	    call writeString
	    mov dl, 37
		mov dh, 9
		call gotoxy
		mov edx, OFFSET cloud1Line2
		call writeString
	    mov dl, 37
	    mov dh, 10
	    call gotoxy
	    mov edx, OFFSET cloud1Line3
	    call writeString
		ret

	platform3:
		mov eax, darkGray + (lightblue * 16)
		call setTextColor
		
		mov dh, 15
		mov dl, 35
		call gotoxy
		mov ecx, 10
		mov al, 178	
		bossPlatform1:
			call writeChar
			loop bossPlatform1

		mov dh, 11
		mov dl, 42
		call gotoxy
		mov ecx, 8
		mov al, 178	
		bossPlatform2:
			call writeChar
			loop bossPlatform2

		mov dh, 7
		mov dl, floatingPlatformX 
		call gotoxy
		mov ecx, 6
		mov al, 178	
		bossPlatform3:
			call writeChar
			loop bossPlatform3
		ret
drawScenePlatforms endp
                                  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
drawMario proc
	movzx eax, mario.color
    add eax, (lightBlue * 16) 
    call setTextColor

	mov dh, mario.yCord
    mov dl, mario.xCord
    call gotoxy
	mov al, mario.char
    call writeChar

	ret
drawMario endp
                                  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
drawObstacles proc
	call drawCoins
	call drawStars
	ret
drawObstacles endp
                                  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
drawEnemies proc
	cmp currentScene, 2
	je skipAll
	call drawGoombas
	call drawKoopas
	skipAll:
	ret
drawEnemies endp
                                  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
updateEnemies proc
	cmp currentScene, 2
	je skipAll

	call updateGoombas
	call updateKoopas
	skipAll:
	ret
updateEnemies endp
                                  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
checkEnemyCollision proc
	cmp currentScene, 2
	je skipAll
	call checkGoombasCollision
	call checkKoopasCollision
	skipAll:
	ret
checkEnemyCollision endp
                                  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
checkKoopasCollision proc
	cmp currentScene, 1
	je two
	ret

	two:
		mov esi, 0
		mov ecx, 3
		loop2:
			cmp ecx, 0
			je endLoop2

			cmp scene2KoopaActive[esi], 0
			je skip2
    
			;checking x:
			mov al, mario.xCord
			sub al, scene2KoopaX[esi]
			cmp al, 0
			je checkV1
			cmp al, 1
			je checkV1
			cmp al, -1
			je checkV1
			jmp skip2
    
			checkV1:
				mov al, scene2KoopaState[esi]
				cmp al, 0
				je walkingKoopaCollision
				cmp al, 1
				je shellCollision
				jmp slidingShellCollision
    
			walkingKoopaCollision:
				mov al, mario.yCord
				inc al
				cmp al, scene2KoopaY[esi]
				jne walkingSideCollision
    
				cmp mario.isFalling, 1
				jne skip2

				mov scene2KoopaState[esi], 1
				mov scene2KoopaShellTimer[esi], 0
				add mario.score, 100
				inc scene2EnemiesDefeated
				mov mario.isFalling, 0
				mov mario.isJumping, 1
				mov mario.jumpTimer, 4
				jmp skip2
    
			walkingSideCollision:
			    mov al, mario.yCord
			    cmp al, scene2KoopaY[esi]
			    jne skip2
    
				dec mario.lives
				cmp mario.lives, 0
				jle gameOverKoopa

				mov mario.xCord, 10
			    mov mario.yCord, 20     
				mov mario.isJumping, 0  
				mov mario.isFalling, 0  
				mov mario.isOnGround, 1 
				jmp skip2
    
			shellCollision:
				mov al, mario.yCord
				inc al
				cmp al, scene2KoopaY[esi]
				jne kickShell 

				cmp mario.isFalling, 1
				jne skip2

				mov scene2KoopaActive[esi], 0 
				add mario.score, 200
				inc scene2EnemiesDefeated
	            mov mario.isFalling, 0
		        mov mario.isJumping, 1
			    mov mario.jumpTimer, 4
				call playEnemySound
			    jmp skip2

				comment!
			    mov scene2KoopaState[esi], 2  
				mov al, mario.xCord
				cmp al, scene2KoopaX[esi]
				jl kickRight
				
				mov scene2KoopaDirection[esi], 0
				jmp skip2
				!

			kickShell:
				mov scene2KoopaState[esi], 2

				mov al, mario.xCord
				cmp al, scene2KoopaX[esi]
				jl kickRight

				mov scene2KoopaDirection[esi], 0
				jmp skip2

			kickRight:
				mov scene2KoopaDirection[esi], 1
				jmp skip2
    
			slidingShellCollision:
				mov al, mario.yCord
				inc al
				cmp al, scene2KoopaY[esi]
				je slidingStompCollision
				inc al
				cmp al, scene2KoopaY[esi]
				je slidingStompCollision
				jne slidingSideCollision
    
			slidingStompCollision:
				cmp mario.isFalling, 1
				jne skip2
    
				mov scene2KoopaActive[esi], 0 
				add mario.score, 200
				mov mario.isFalling, 0
				mov mario.isJumping, 1
				mov mario.jumpTimer, 4
				call playEnemySound
				jmp skip2
    
			slidingSideCollision:
				mov al, mario.yCord
				cmp al, scene2KoopaY[esi]
				jne skip2
    
				dec mario.lives
				cmp mario.lives, 0
				jle gameOverKoopa

				mov mario.xCord, 10
			    mov mario.yCord, 20     
				mov mario.isJumping, 0  
				mov mario.isFalling, 0  
				mov mario.isOnGround, 1 
				jmp skip2
			
			skip2:
				inc esi
				dec ecx
				jmp loop2

		endLoop2:
			ret

	gameOverKoopa:
		mov gameState, lost
		call playResultSound
	skipAll:
		ret
checkKoopasCollision endp
                                  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
checkGoombasCollision proc

	cmp currentScene, 0
	je one
	cmp currentScene, 2
	je three
	ret

	one:
		mov esi, 0
		mov ecx, 3
		loop1:
			cmp ecx, 0
			je endLoop1

			cmp scene1goombaActive[esi], 1
			jne skip1

			mov al, mario.xCord
			sub al, scene1goombaX[esi]
			cmp al, 0
			je xCol1
			cmp al, 1
			je xCol1
			cmp al, -1
			je xCol1
			jmp skip1

			xCol1:
				mov al, mario.yCord
				inc al
				cmp al, scene1goombaY[esi]
				jne side1

				cmp mario.isFalling, 1
				je kill1
				jmp skip1

			side1:
				mov al, mario.yCord
				cmp al, scene1goombaY[esi]
				jne skip1 

				dec mario.lives
				cmp mario.lives, 0
				jle gameOverGoomba

				mov mario.xCord, 10
				mov mario.yCord, 20
				mov mario.isJumping, 0
				mov mario.isFalling, 0
				mov mario.isOnGround, 1
				jmp skip1

			kill1:
				mov scene1goombaActive[esi], 0
				call playEnemySound
				add mario.score, 100
				mov mario.jumpTimer, 4
				mov mario.isFalling, 0
				mov mario.isJumping, 1
				ret

			skip1:
				inc esi
				dec ecx
				jmp loop1

		endLoop1:
			ret			

	three:

	gameOverGoomba:
		mov gameState, lost
		call playResultSound
		ret
checkGoombasCollision endp
                                  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
updateGoombas proc
	cmp gameState, paused
	je skipAll
	
	cmp currentScene, 0
	je one
	cmp currentScene, 2
	je three
	ret

	one:
		mov esi, 0
		mov ecx, 3
		loop1:
			cmp scene1GoombaActive[esi], 1
			jne skip1

			mov al, scene1GoombaDirection[esi]
			cmp al, 0
			je moveLeft1

			inc scene1GoombaX[esi]
			cmp scene1GoombaX[esi], 78
			jl skip1
			mov scene1GoombaDirection[esi], 0
			jmp skip1

			moveLeft1:
				dec scene1goombaX[esi]
				cmp scene1goombaX[esi], 1
				jg skip1
				mov scene1goombaDirection[esi], 1

			skip1:
				inc esi
				loop loop1
		ret

	three:

	skipAll:
		ret
updateGoombas endp
                                  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
updateKoopas proc
	cmp gameState, paused
    je skipAll

	comment!
	mov eax, gameTime
    and eax, 3
    cmp eax, 0
    jne skipAll
	!

    cmp currentScene, 1
    je one
    ret

	one:
		mov esi, 0
		mov ecx, 3
		loop1:
			cmp ecx, 0
			je endLoop1

			cmp scene2KoopaActive[esi], 0
			je skip1

			mov al, scene2KoopaState[esi]
			cmp al, 0
			je walkingKoopa
			cmp al, 1
			je shellKoopa
			jmp slidingShell
    
			walkingKoopa:
				mov al, scene2KoopaDirection[esi]
			    cmp al, 0
			    je moveKoopaLeft
    
				inc scene2KoopaX[esi]
				cmp scene2KoopaX[esi], 78
				jl skip1
				mov scene2KoopaDirection[esi], 0
				jmp skip1
    
			moveKoopaLeft:
				dec scene2KoopaX[esi]
				cmp scene2KoopaX[esi], 1
				jg skip1
				mov scene2KoopaDirection[esi], 1
				jmp skip1
    
			shellKoopa:
				inc scene2KoopaShellTimer[esi]
				cmp scene2KoopaShellTimer[esi], 50 
				jl skip1
    
			
			mov scene2KoopaState[esi], 0
			mov scene2KoopaShellTimer[esi], 0
			jmp skip1
    
			slidingShell:
				mov al, scene2KoopaDirection[esi]
				cmp al, 0
				je slideShellLeft
    
			;Sliding right:
				add scene2KoopaX[esi], 2 
				cmp scene2KoopaX[esi], 78
				jl skip1
				mov scene2KoopaActive[esi], 0  
				call playEnemySound
				jmp skip1
    
			slideShellLeft:
				sub scene2KoopaX[esi], 2
				cmp scene2KoopaX[esi], 1
				jg skip1
				mov scene2KoopaActive[esi], 0  
				call playEnemySound
    
			skip1:
				inc esi
				dec ecx
				jmp loop1
	
	endLoop1:
	skipAll:
		ret
updateKoopas endp
                                  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
drawstars proc

	cmp currentScene, 1
	jne skipStar

	cmp inStarRoom, 1
    jne checkStarActive
	call drawStarRoomCoins
    call drawStarRoomStar
    ret

	checkStarActive:
    cmp starActive, 1
    jne skipStar
    
    mov eax, yellow + (lightBlue * 16)
    call setTextColor
    
    mov dh, starY
    mov dl, starX
    call gotoxy
    mov al, '*' 
    call writeChar

	skipStar:
		ret
drawstars endp
                                  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
drawStarRoomCoins proc
	mov eax, yellow + (black * 16)  
    call setTextColor
	
	mov esi, 0
    mov ecx, 7
	coinLoop:
		cmp starRoomCoinsActive[esi], 1
		jne skip1
    
	    mov dh, starRoomCoinsY[esi]
		mov dl, starRoomCoinsX[esi]
	    call gotoxy
		mov al, 'C'
		call writeChar

		skip1:
			inc esi
			loop coinLoop
    ret
drawStarRoomCoins endp
                                  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
drawStarRoomStar proc
    mov eax, white + (black * 16)
    call setTextColor
    
    mov dh, 10
    mov dl, 40
    call gotoxy
    mov al, '*'
    call writeChar
    ret
drawStarRoomStar endp
                                  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
drawGoombas proc
	mov eax, brown + (lightBlue * 16)
    call setTextColor
    
    cmp currentScene, 0
    je draw1
    cmp currentScene, 2
    je draw3
    ret

	draw1:
		mov esi, 0
		mov ecx, 3
		loop1:
			cmp scene1GoombaActive[esi], 1
			jne skip1
			mov dh, scene1goombaY[esi]
			mov dl, scene1goombaX[esi]
			call gotoxy
			mov al, 'G'    
			call writeChar
			skip1:
				inc esi
				loop loop1
		ret

	draw3:
	ret
drawGoombas endp
                                  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
drawKoopas proc
	cmp inStarRoom, 1
	je skipAll

	mov eax, brown + (lightBlue * 16)
    call setTextColor
    
    cmp currentScene, 1
    je draw2
    ret

	draw2:
		mov esi, 0
		mov ecx, 3
		loop2:
			cmp scene2KoopaActive[esi], 1
			jne skip2
			
			mov eax, green + (lightBlue * 16)
		    cmp scene2KoopaState[esi], 0
			je drawChar
			mov eax, darkGray + (lightBlue * 16)

			drawChar:
				call setTextColor
				mov dh, scene2KoopaY[esi]
				mov dl, scene2KoopaX[esi]
				call gotoxy	

				cmp scene2KoopaState[esi], 0
				jne drawShell
				mov al, 'K'
				jmp writeKoopa

			drawShell:
				mov al, 'S'

			writeKoopa:
				call writeChar
			skip2:
				inc esi
				loop loop2
		ret

	skipAll:
		ret
drawKoopas endp
                                  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
drawControlsInfo proc
	mov eax, lightGray + (lightBlue * 16)
    call setTextColor

	mov dh, 22
    mov dl, 0
    call gotoxy

	mov edx, offset gameControlsInstructions
    call writeString
	ret
drawControlsInfo endp
                                  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
initializeScene1 proc

	call randomize
	mov ecx, 10
    mov esi, 0
	initializeRain:
		mov eax, 71      
		call randomRange
		add al, 5
		mov rainX[esi], al
		mov eax, 8      
		call randomRange
		add al, 3
		mov rainY[esi], al
		mov rainActive[esi], 1
		inc esi
		loop initializeRain
		mov rainDamageCooldown, 0
	ret
initializeScene1 endp
                                  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
drawRain proc
	cmp currentScene, 0      
    jne skipDraw
    
    mov eax, red + (lightBlue * 16)  
    call setTextColor
    
    mov esi, 0
    mov ecx, 10
	drawRainLoop:
		cmp rainActive[esi], 1
		jne skipRaindrop
    
		mov dh, rainY[esi]
		mov dl, rainX[esi]
		call gotoxy
		mov al, '|'           
		call writeChar
    
	skipRaindrop:
		inc esi
		loop drawRainLoop
    
	skipDraw:
		ret
drawRain endp
                                  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
updateRain proc
    cmp currentScene, 0      
    jne skipUpdate
    
    cmp rainDamageCooldown, 0
    jle noCooldown
    dec rainDamageCooldown
    
	noCooldown:
		mov esi, 0
		mov ecx, 10
		updateRainLoop:
			cmp rainActive[esi], 1
			jne skipUpdateDrop
    
			add rainY[esi], 2
			cmp rainY[esi], 21
			jl skipResetDrop
    
			mov eax, 71
			call RandomRange
			add al, 5
			mov rainX[esi], al
			mov rainY[esi], 3       
skipResetDrop:
skipUpdateDrop:
    inc esi
    loop updateRainLoop
    
skipUpdate:
    ret
updateRain endp
                                  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
checkRainCollision proc
    cmp currentScene, 0      
    jne skipCheck
    
    cmp rainDamageCooldown, 0
    jg skipCheck
    
    mov esi, 0
    mov ecx, 10
	rainCollisionLoop:
		cmp rainActive[esi], 1
		jne skipRainCollision
    
		mov al, mario.xCord
		sub al, rainX[esi]
		cmp al, 0
		je checkRainY
		jmp skipRainCollision
    
		checkRainY:
		mov al, mario.yCord
		sub al, rainY[esi]
		cmp al, 0
		je hitRainCheck
		cmp al, 1
		je hitRainCheck
		cmp al, -1
		je hitRainCheck
		cmp al, 2
		je hitRainCheck
		cmp al, -2
		je hitRainCheck
		jmp skipRainCollision

		hitRainCheck:
		dec mario.lives
		mov rainDamageCooldown, 15 
		call playEnemySound
    
		mov eax, 71
		call RandomRange
		add al, 5
		mov rainX[esi], al
		mov rainY[esi], 3
    
		cmp mario.lives, 0
		jle gameOverRain
		ret
    
	gameOverRain:
		mov gameState, lost
		call playResultSound
		ret
    
	skipRainCollision:
		inc esi
		loop rainCollisionLoop
    
	skipCheck:
		ret
checkRainCollision endp
                                  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
initializeScene2 proc

	ret
initializeScene2 endp
                                  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
initializeScene3 proc

	ret
initializeScene3 endp
                                  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
drawCoins proc

	cmp inStarRoom, 1
	je none
	
	mov eax, yellow + (lightBlue * 16)
	call setTextColor

	cmp currentScene, 0
	je coin1
	cmp currentScene, 1
	je coin2
	cmp currentScene, 2
	je coin3
	ret

	coin1:
		mov esi, 0
		mov ecx, 5
		draw1:
			cmp scene1active[esi], 1
			jne skip1
			
			mov dh, scene1coinsY[esi]
			mov dl, scene1coinsX[esi]
			call gotoxy

			mov al, 'C'
			call writeChar
			
			skip1:
				inc esi
				loop draw1
		jmp none

	coin2:
		mov esi, 0
		mov ecx, 5
		draw2:
			cmp scene2active[esi], 1
			jne skip2
			
			mov dh, scene2coinsY[esi]
			mov dl, scene2coinsX[esi]
			call gotoxy

			mov al, 'C'
			call writeChar
			
			skip2:
				inc esi
				loop draw2
		jmp none

	coin3:
		mov esi, 0
		mov ecx, 5
		draw3:
			cmp scene3active[esi], 1
			jne skip3
			
			mov dh, scene3coinsY[esi]
			mov dl, scene3coinsX[esi]
			call gotoxy

			mov al, 'C'
			call writeChar
			
			skip3:
				inc esi
				loop draw3
	none:
		ret
drawCoins endp
                                  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
checkCoinCollision Proc

	cmp currentScene, 0
	je collision1
	cmp currentScene, 1
	je collision2
	cmp currentScene, 2
	je collision3
	ret

	collision1:
		mov ecx, 5
		mov esi, 0
		coins1:
			cmp scene1active[esi], 1
			jne skip1	

			mov al, mario.xCord
			cmp al, scene1coinsX[esi]
			jne skip1
			mov al, mario.yCord
			cmp al, scene1coinsY[esi]
			jne skip1

			mov scene1active[esi], 0
			inc mario.coins
			add mario.score, 200
			call playCoinSound

			skip1:
				inc esi
				loop coins1		
		jmp none

	collision2:
		mov ecx, 5
		mov esi, 0
		coins2:
			cmp scene2active[esi], 1
			jne skip2	

			mov al, mario.xCord
			cmp al, scene2coinsX[esi]
			jne skip2
			mov al, mario.yCord
			cmp al, scene2coinsY[esi]
			jne skip2

			mov scene2active[esi], 0
			inc mario.coins
			add mario.score, 200
			call playCoinSound

			skip2:
				inc esi
				loop coins2
		jmp none

	collision3:
		mov ecx, 5
		mov esi, 0
		coins3:
			cmp scene3active[esi], 1
			jne skip3

			mov al, mario.xCord
			cmp al, scene3coinsX[esi]
			jne skip3
			mov al, mario.yCord
			cmp al, scene3coinsY[esi]
			jne skip3

			mov scene3active[esi], 0
			inc mario.coins
			add mario.score, 200
			call playCoinSound

			skip3:
				inc esi
				loop coins3
	none:
		ret
checkCoinCollision endp
                                  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
checkStarCollision proc

	cmp currentScene, 1
	jne skipCheck

	cmp starActive, 1
    jne skipCheck
    cmp inStarRoom, 1
    je skipCheck 
    
    mov al, mario.xCord
    cmp al, starX
    jne skipCheck
    
    mov al, mario.yCord
    cmp al, starY
    jne skipCheck
    
    mov inStarRoom, 1
	call playPowerupSound

    mov al, mario.xCord
    mov starRoomExitX, al
    mov al, mario.yCord
    mov starRoomExitY, al
    
    mov mario.xCord, 37  
    mov mario.yCord, 12

	skipCheck:
		ret
checkStarCollision endp
                                  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
checkStarCoinCollision proc
	mov esi, 0
    mov ecx, 7
	loop1:
		cmp starRoomCoinsActive[esi], 1
		jne skip1
    
		mov al, mario.xCord
		cmp al, starRoomCoinsX[esi]
		jne skip1
    
		mov al, mario.yCord
		cmp al, starRoomCoinsY[esi]
		jne skip1

		mov starRoomCoinsActive[esi], 0
		inc mario.coins
		add mario.score, 500 
		call playCoinSound

		skip1:
			inc esi
			loop loop1
	ret
checkStarCoinCollision endp
                                  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
checkStarRoomExitCollision proc
	mov al, mario.xCord
    cmp al, 40
    jne skipExit
    
    mov al, mario.yCord
    cmp al, 10
    jne skipExit
    
    mov inStarRoom, 0
    mov starActive, 0
	call playCoinSound

	mov al, starRoomExitX
    mov mario.xCord, al
    mov al, starRoomExitY
    mov mario.yCord, al

	skipExit:
		ret
checkStarRoomExitCollision endp
								  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

















					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
										;Pause Procedures:
drawPauseScreen proc

	;call drawGameScreen
	mov eax, lightGray + (black*16)
    call setTextColor

	mov dh, 6
    mov dl, 16
    call gotoxy
    
    mov ecx, 11

	drawRowsAbove:
    mov ebx, ecx
    mov ecx, 46
    mov al, ' '

	drawColsAbove:
    call writeChar
    loop drawColsAbove
    mov ecx, ebx

    inc dh
    mov dl, 16
    call gotoxy
    loop drawRowsAbove

	mov eax, yellow + (black * 16)
    call setTextColor
    
    mov dh, 8
    mov dl, 32
    call gotoxy
    mov edx, offset gamePaused
    call writeString

	mov eax, lightGray + (black * 16)
    call setTextColor
    mov dh, 14
    mov dl, 25
    call gotoxy
    mov edx, offset pauseInstructions
    call writeString

	ret
drawPauseScreen endp
                                  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
pauseInput proc
	call readKey
    jz noPause

	cmp al, 'E'
	je backToMain
	cmp al, 'e'
	je backToMain
	cmp al, 'p'
	je unpause
	cmp al, 'P'
	je unpause
	jmp nopause

	unpause:
		mov gameState, playing
		mov menuSelection, 1
		jmp noPause

	backToMain:
		mov gameState, menu
		mov menuSelection, 1
		call initializeGame
		jmp noPause

	noPause:
		mov eax, 50
		call delay
		ret
pauseInput endp
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
										;Lost Procedures:
drawLostScreen proc
    mov eax, white + (red * 16)
    call setTextColor
    call clrscr
    
    mov eax, yellow + (red * 16)
    call setTextColor
    
    mov dh, 5
    mov dl, 20
    call gotoxy
    mov ecx, 40
    mov al, 196
    drawLostTopBorder:
        call writeChar
        loop drawLostTopBorder
    
    mov eax, yellow + (red * 16)
    call setTextColor
    mov dh, 7
    mov dl, 34
    call gotoxy
    mov edx, offset gameLost
    call writeString
    
    mov dh, 7
    mov dl, 28
    call gotoxy
    mov al, '+'
    call writeChar
    mov dh, 7
    mov dl, 48
    call gotoxy
    mov al, '+'
    call writeChar
    
    mov eax, white + (red * 16)
    call setTextColor
    mov dh, 9
    mov dl, 34
    call gotoxy
    mov edx, offset scoreDisplay
    call writeString
    mov eax, mario.score
    call writeDec
    
    mov dh, 10
    mov dl, 34
    call gotoxy
    mov edx, offset coinsDisplay
    call writeString
    movzx eax, mario.coins
    call writeDec
    
    mov dh, 11
    mov dl, 34
    call gotoxy
    mov edx, offset sceneDisplay
    call writeString
    movzx eax, currentScene
    inc eax
    call writeDec
    
	comment!
    mov eax, lightGray + (red * 16)
    call setTextColor
    mov dh, 13
    mov dl, 25
    call gotoxy
    
    cmp mario.lives, 0
    jne notZeroLives
    
    mov edx, OFFSET timeOutMsg
    jmp displayDeathMsg
    
notZeroLives:
    mov edx, OFFSET fellMsg
    
displayDeathMsg:
    call writeString
   
    mov eax, darkGray + (red * 16)
    call setTextColor
    mov dh, 15
    mov dl, 35
    call gotoxy
    mov al, 178
    call writeChar
    mov al, 178
    call writeChar
    mov al, 178
    call writeChar
    
    mov dh, 16
    mov dl, 35
    call gotoxy
    mov al, 178
    call writeChar
    mov al, 219
    call writeChar
    mov al, 178
    call writeChar
    
    mov dh, 17
    mov dl, 35
    call gotoxy
    mov al, 178
    call writeChar
    mov al, 178
    call writeChar
    mov al, 178
    call writeChar
    !
    
    mov eax, white + (red * 16)
    call setTextColor
    mov dh, 18
    mov dl, 25
    call gotoxy
    mov edx, offset pressAnyKeyText
    call writeString
    
    mov eax, mario.score
    cmp eax, 1000
    jl noHighScorePrompt
    
    mov eax, yellow + (red * 16)
    call setTextColor
    mov dh, 19
    mov dl, 25
    call gotoxy
    mov edx, OFFSET highScorePrompt
    call writeString
    
noHighScorePrompt:
    mov eax, yellow + (red * 16)
    call setTextColor
    mov dh, 20
    mov dl, 20
    call gotoxy
    mov ecx, 40
    mov al, 196
    drawLostBottomBorder:
        call writeChar
        loop drawLostBottomBorder
    
    ret
drawLostScreen endp
                                  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
lostInput proc
	mov eax, 2000
	call delay
	call readKey
    jz noInput
	mov gameState, menu
    call initializeGame
	noInput:
		ret
lostInput endp

					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
										;Won Procedures:
comment!
drawWonScreen proc
	mov eax, white + (green * 16)
    call setTextColor
    call clrscr
    
    mov eax, yellow + (green * 16)
    call setTextColor
    mov dh, 10
    mov dl, 37
    call gotoxy
    mov edx, offset gameWon
    call writeString

    mov eax, white + (green * 16)
    call setTextColor
    mov dh, 12
    mov dl, 33
    call gotoxy
    mov edx, offset scoreDisplay
    call writeString
    mov eax, mario.score
    call writeDec
    
    mov dh, 13
    mov dl, 33
    call gotoxy
    mov edx, offset coinsDisplay
    call writeString
    movzx eax, mario.coins
    call writeDec
    
    mov dh, 15
    mov dl, 30
    call gotoxy
    mov edx, offset pressAnyKeyText
    call writeString

	ret
drawWonScreen endp
!
drawWonScreen proc
    mov eax, white + (green * 16)
    call setTextColor
    call clrscr
    
    mov eax, yellow + (green * 16)
    call setTextColor
    
    mov dh, 5
    mov dl, 20
    call gotoxy
    mov ecx, 40
    mov al, 205
    drawTopBorder:
        call writeChar
        loop drawTopBorder
    
    mov eax, yellow + (green * 16)
    call setTextColor
    mov dh, 7
    mov dl, 35
    call gotoxy
    mov edx, offset gameWon
    call writeString
    
    mov dh, 7
    mov dl, 30
    call gotoxy
    mov al, '*'
    call writeChar
    mov dh, 7
    mov dl, 48
    call gotoxy
    mov al, '*'
    call writeChar
    
    mov eax, white + (green * 16)
    call setTextColor
    mov dh, 9
    mov dl, 33
    call gotoxy
    mov edx, offset scoreDisplay
    call writeString
    mov eax, mario.score
    call writeDec
    
    mov dh, 10
    mov dl, 33
    call gotoxy
    mov edx, offset coinsDisplay
    call writeString
    movzx eax, mario.coins
    call writeDec
    
    mov dh, 11
    mov dl, 33
    call gotoxy
    mov edx, offset livesDisplay
    call writeString
    movzx eax, mario.lives
    call writeDec
    
    mov eax, lightCyan + (green * 16)
    call setTextColor
    mov dh, 13
    mov dl, 25
    call gotoxy
    
    mov eax, mario.score
    cmp eax, 5000
    jg excellentScore
    cmp eax, 3000
    jg goodScore
    cmp eax, 1000
    jg averageScore
    
    mov edx, OFFSET lowScoreMsg
    jmp displayMsg
    
averageScore:
    mov edx, OFFSET averageScoreMsg
    jmp displayMsg
    
goodScore:
    mov edx, OFFSET goodScoreMsg
    jmp displayMsg
    
excellentScore:
    mov edx, OFFSET excellentScoreMsg
    
displayMsg:
    call writeString
    
    mov eax, white + (green * 16)
    call setTextColor
    mov dh, 18
    mov dl, 28
    call gotoxy
    mov edx, offset pressAnyKeyText
    call writeString
    
    mov eax, yellow + (green * 16)
    call setTextColor
    mov dh, 20
    mov dl, 20
    call gotoxy
    mov ecx, 40
    mov al, 205
    drawBottomBorder:
        call writeChar
        loop drawBottomBorder
    
    ret
drawWonScreen endp
                                  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
wonInput proc
	mov eax, 2000 
    call Delay
	call readKey
    jz noInput
	;call saveAllScores
    mov gameState, menu
    call initializeGame
	noInput:
		ret
wonInput endp
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


















					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
										;Fireball Procedures:
createFireBall proc
    cmp inStarRoom, 1
    je skipAll

    cmp ballActive[0], 0
    je useFirstSlot
    cmp ballActive[1], 0
    je useSecondSlot
    
    jmp skipAll
    
    useFirstSlot:
        mov esi, 0
        jmp createBall
        
    useSecondSlot:
        mov esi, 1
        
    createBall:
        mov ballActive[esi], 1
        mov al, mario.xCord
        inc al
        mov ballX[esi], al
        mov al, mario.yCord
        mov ballY[esi], al
    skipAll:
    ret
createFireBall endp
								;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
updateProjectiles proc
	cmp instarroom, 1
	je skipAll

	cmp ballActive[0], 1
    jne checkSecond
    
    mov al, ballX[0]
    add al, 3
    mov ballX[0], al
	cmp al, 79
    jge deactivateFirst

    checkCollision0:
    mov esi, 0
    call checkFireballCollision
    jmp checkSecond
    
    deactivateFirst:
        mov ballActive[0], 0
		call playEnemySound

	checkSecond:
    cmp ballActive[1], 1
    jne skipAll

    mov al, ballX[1]
    add al, 3
    mov ballX[1], al
    cmp al, 79
    jge deactivateSecond

    mov esi, 1
    call checkFireballCollision
    jmp skipAll

	deactivateSecond:
        mov ballActive[1], 0
		call playEnemySound

    skipAll:
    ret
updateProjectiles endp
                                  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
checkFireballCollision proc

	push esi
    push edi
    push ecx
	
	cmp inStarRoom, 1
	je collisionDone
    
    cmp currentScene, 0
    je checkScene1Fireball
    cmp currentScene, 1
    je checkScene2Fireball
    cmp currentScene, 2
    je checkScene3Fireball
    jmp collisionDone
    
    checkScene1Fireball:
        mov edi, 0
        mov ecx, 3
        scene1FireLoop:
            cmp scene1GoombaActive[edi], 0
            je nextGoomba1
            
            mov al, ballX[esi]
            cmp al, scene1GoombaX[edi]
            je checkY1
            inc al
            cmp al, scene1GoombaX[edi]
            je checkY1
            dec al
            dec al
            cmp al, scene1GoombaX[edi]
            jne nextGoomba1
            
            checkY1:
            mov al, ballY[esi]
            cmp al, scene1GoombaY[edi]
            je collision1
            inc al
            cmp al, scene1GoombaY[edi]
            je collision1
            dec al
            dec al
            cmp al, scene1GoombaY[edi]
            jne nextGoomba1
            
			collision1:
            mov scene1GoombaActive[edi], 0
			call playEnemySound
            mov ballActive[esi], 0
            add mario.score, 200
            jmp collisionDone

            nextGoomba1:
                inc edi
                loop scene1FireLoop
        jmp collisionDone
        
    checkScene2Fireball:
        mov edi, 0
        mov ecx, 3
        scene2FireLoop:
			cmp ecx, 0
			je endScene2Loop

            cmp scene2KoopaActive[edi], 0
            je nextKoopa
            
            mov al, ballX[esi]
            cmp al, scene2KoopaX[edi]
            je checkY2
            inc al
            cmp al, scene2KoopaX[edi]
            je checkY2
			inc al
            cmp al, scene2KoopaX[edi]
            je checkY2
            dec al
            dec al
			dec al
            cmp al, scene2KoopaX[edi]
            je checkY2
			dec al
			cmp al, scene2KoopaX[edi] 
			je checkY2
			jne nextKoopa
            
            checky2:
			mov al, ballY[esi]
            cmp al, scene2KoopaY[edi]
            je collision2
            inc al
            cmp al, scene2KoopaY[edi]
            je collision2
            dec al
            dec al
            cmp al, scene2KoopaY[edi]
            jne nextKoopa
            
			collision2:
            mov scene2KoopaActive[edi], 0
			call playEnemySound
            mov ballActive[esi], 0
            add mario.score, 200
			inc scene2EnemiesDefeated
            jmp collisionDone
            
            nextKoopa:
                inc edi
				dec ecx
                jmp scene2FireLoop

		endScene2Loop:
        jmp collisionDone
        
    checkScene3Fireball:
		cmp bossActive, 1
		jne skipBossCollision
    
		mov al, ballX[esi]
		sub al, bossX
		cmp al, 0
		je checkBossY
		cmp al, 1
		je checkBossY
		cmp al, -1
		je checkBossY
		jmp skipBossCollision
    
		checkBossY:
			mov al, ballY[esi]
			sub al, bossY
			cmp al, 0
			je hitBoss
	        cmp al, 1
		    je hitBoss
			cmp al, -1
	       je hitBoss
		    jmp skipBossCollision
        
		hitBoss:
			dec bossHp
			mov ballActive[esi], 0
			call playEnemySound
			add mario.score, 500    
        
		cmp bossHp, 0
        jg bossStillAlive
        
        mov bossActive, 0
		call playEnemySound
        add mario.score, 5000   
        jmp skipBossCollision
        
    bossStillAlive:
	skipBossCollision:
	
    collisionDone:
        pop ecx
        pop edi
        pop esi
	skipAll:
        ret
checkFireballCollision endp
                                  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
drawProjectiles proc
   
    cmp inStarRoom, 1
    je skipAll

    cmp ballActive[0], 1
    jne checkSecondDraw
    
    mov eax, blue + (lightBlue * 16)
    call SetTextColor
    mov dh, ballY[0]
    mov dl, ballX[0]
    call Gotoxy
    mov al, 'o'
    call WriteChar
    
    checkSecondDraw:
		cmp ballActive[1], 1
		jne skipAll
    
    mov eax, blue + (lightBlue * 16)
    call SetTextColor
    mov dh, ballY[1]
    mov dl, ballX[1]
    call Gotoxy
    mov al, 'o'
    call WriteChar
    
    skipAll:
    ret
drawProjectiles endp
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


















					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
										;Bonus Procedures:
calculateBonus proc
	call playFlagSound
    cmp mario.yCord, 10
    jl topFlag
    cmp al, 15
    jl middleFlag
    jmp bottomFlag
    
	topFlag:
		mov flagBonusEarned, 1000
		jmp calculateTime
    
	middleFlag:
		mov flagBonusEarned, 500
		jmp calculateTime
    
	bottomFlag:
		mov flagBonusEarned, 200
    
	calculateTime:
		movzx eax, sceneTimer
		mov ebx, 50
		mul ebx
		mov timeBonusEarned, eax
    
	movzx eax, scene2EnemiesDefeated
	mov ebx, 500
	mul ebx
	mov enemyBonusEarned, eax
    
    mov eax, flagBonusEarned
    add eax, timeBonusEarned
    add eax, enemyBonusEarned
    add mario.score, eax
    
    mov levelCompleted, 1
    ret
calculateBonus endp
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


















					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
										;Boss Procedures:
drawBoss proc
	cmp currentScene, 2
	jne skipDraw

    cmp bossActive, 1
    jne skipDraw
    
    mov eax, magenta + (lightblue * 16)  
    call SetTextColor
    
    mov dh, bossY
    mov dl, bossX
    call Gotoxy
    mov al, 'B'        
    call WriteChar
    
    skipDraw:
    ret
drawBoss endp
                                  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
updateBoss proc
	cmp currentScene, 2
	jne skipUpdate

    cmp bossActive, 1
    jne skipUpdate
    
    cmp currentScene, 2
    jne skipUpdate
    
    mov eax, gameTime
    mov ebx, 5
    mov edx, 0
    div ebx
    cmp edx, 0
    jne skipUpdate
    
	call bossShoot

    mov al, bossX
    cmp al, mario.xCord
    jl moveRight
    jg moveLeft
    jmp skipUpdate    
        
    moveRight:
		inc bossX
        mov bossDirection, 1  
        jmp skipUpdate
            
	moveLeft:
		dec bossX
        mov bossDirection, 0  
            
    skipUpdate:
    ret
updateBoss endp
                                  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
bossShoot proc
	cmp currentScene, 2
	jne noslot

    mov esi, 0
    findSlot:
        cmp esi, 2
        je noSlot
        
        cmp bossFireActive[esi], 0
        je foundSlot
        inc esi
        jmp findSlot
    
    foundSlot:
        mov bossFireActive[esi], 1
        mov al, bossX
        mov bossFireX[esi], al
        mov al, bossY
        mov bossFireY[esi], al
        
        mov al, bossDirection
        mov bossFireDirection[esi], al
    
    noSlot:
    ret
bossShoot endp
                                  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
updateBossFireballs proc
	cmp currentScene, 2
	jne doneupdate

    mov esi, 0
    updateLoop:
        cmp esi, 2
        je doneUpdate
        
        cmp bossFireActive[esi], 1
        jne nextFireball
        
        mov al, bossFireDirection[esi]
        cmp al, 0
        je moveLeftFB
        
        add bossFireX[esi], 2
        cmp bossFireX[esi], 79
        jge deactivate
        jmp checkCollisionn
        
        moveLeftFB:
            sub bossFireX[esi], 2
            cmp bossFireX[esi], 0
            jle deactivate
            
        checkCollisionn:
            mov al, bossFireX[esi]
            sub al, mario.xCord
            cmp al, 0
            je checkY
            cmp al, 1
            je checkY
            cmp al, -1
            je checkY
            jmp nextFireball
            
        checkY:
            mov al, bossFireY[esi]
            sub al, mario.yCord
            cmp al, 0
            je hitMario
            cmp al, 1
            je hitMario
            cmp al, -1
            je hitMario
            jmp nextFireball
            
        hitMario:
            dec mario.lives
            cmp mario.lives, 0
            jle gameOverBoss
            
            mov mario.xCord, 0
            mov mario.yCord, 20
            mov mario.isJumping, 0
            mov mario.isFalling, 0
            mov mario.isOnGround, 1
            
            deactivate:
                mov bossFireActive[esi], 0
				call playEnemySound
                jmp nextFireball
                
        gameOverBoss:
            mov gameState, lost
			call playResultSound
            
        nextFireball:
            inc esi
            jmp updateLoop
            
    doneUpdate:
    ret
updateBossFireballs endp
                                  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
drawBossFireballs proc
	cmp currentScene, 2
	jne donedraw

    mov esi, 0
    drawLoop:
        cmp esi, 2
        je doneDraw
        
        cmp bossFireActive[esi], 1
        jne nextDraw
        
        mov eax, red + (lightblue * 16)
        call SetTextColor
        
        mov dh, bossFireY[esi]
        mov dl, bossFireX[esi]
        call Gotoxy
        mov al, '*'     
        call WriteChar
        
        nextDraw:
            inc esi
            jmp drawLoop
            
    doneDraw:
    ret
drawBossFireballs endp
                                  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
checkBossCollision proc
    cmp currentScene, 2
    jne skipBossCheck
    
    cmp bossActive, 1
    jne skipBossCheck
    
    mov al, mario.xCord
    sub al, bossX
    cmp al, 0
    je checkBossYJump
    cmp al, 1
    je checkBossYJump
    cmp al, -1
    je checkBossYJump
    jmp skipBossCheck
    
    checkBossYJump:
        mov al, mario.yCord
        inc al
        cmp al, bossY
		je checkStompingFalling
		inc al
		cmp al, bossY
		je checkStompingFalling
        jmp checkSideCollision
        
	checkStompingFalling:
        cmp mario.isFalling, 1
        je stompBoss
        jmp checkSideCollision
        
    stompBoss:
        dec bossHp
        add mario.score, 300
        
        mov mario.isFalling, 0
        mov mario.isJumping, 1
        mov mario.jumpTimer, 4
        
        cmp bossHp, 0
        jg bossStillAliveStomp

        mov bossActive, 0
		call playEnemySound
        add mario.score, 5000
        jmp skipBossCheck
        
    bossStillAliveStomp:
        jmp skipBossCheck
        
    checkSideCollision:
        mov al, mario.yCord
        cmp al, bossY
        jne skipBossCheck
        
        dec mario.lives
        cmp mario.lives, 0
        jle gameOverBossSide
        
        mov mario.xCord, 0
        mov mario.yCord, 20
        mov mario.isJumping, 0
        mov mario.isFalling, 0
        mov mario.isOnGround, 1
        jmp skipBossCheck
        
    gameOverBossSide:
        mov gameState, lost
		call playResultSound
        
    skipBossCheck:
    ret
checkBossCollision endp
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

















					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
										;Sound Procedures:
updateSound proc
	cmp switchSound, 1
	jne skip
	cmp soundTimer, 2
	jl skip
	
	pusha
	invoke playSound, previousPtr, NULL, SND_ASYNC OR SND_FILENAME
	mov switchSound, 0
	mov soundTimer, 0
	popa

	skip:
		ret
updateSound endp
                                  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
playJumpSound proc
	pusha
	mov switchSound, 1
    mov soundTimer, 0
    invoke playSound, offset jumpSound, NULL, SND_ASYNC OR SND_FILENAME
	popa
    ret
playJumpSound endp
                                  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
playCoinSound proc
	pusha
	mov switchSound, 1
    mov soundTimer, 0
    invoke playSound, offset coinSound, NULL, SND_ASYNC OR SND_FILENAME
	popa
    ret
playCoinSound endp
                                  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
playEnemySound proc
	pusha
	mov switchSound, 1
    mov soundTimer, 0
    invoke playSound, offset enemySound, NULL, SND_ASYNC OR SND_FILENAME
	popa
    ret
playEnemySound endp
                                  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
playFlagSound proc
	pusha
	mov switchSound, 1
    mov soundTimer, 0
    invoke playSound, offset flagSound, NULL, SND_ASYNC OR SND_FILENAME
	popa
    ret
playFlagSound endp
                                  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
playPowerupSound proc
	pusha
	mov switchSound, 1
    mov soundTimer, 0
    invoke playSound, offset powerupSound, NULL, SND_ASYNC OR SND_FILENAME
	popa
    ret
playPowerupSound endp
                                  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
playSceneSound1 proc
	pusha
    invoke playSound, offset sceneSound1, NULL, SND_ASYNC OR SND_LOOP OR SND_FILENAME
	mov previousPtr, offset sceneSound1
	popa
    ret
playSceneSound1 endp
                                  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
playSceneSound2 proc
	pusha
    invoke playSound, offset sceneSound2, NULL, SND_ASYNC OR SND_LOOP OR SND_FILENAME
	mov previousPtr, offset sceneSound2
	popa
    ret
playSceneSound2 endp
                                  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
playSceneSound3 proc
	pusha
    invoke playSound, offset sceneSound3, NULL, SND_ASYNC OR SND_LOOP OR SND_FILENAME
	mov previousPtr, offset sceneSound3
	popa
    ret
playSceneSound3 endp
                                  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
playTitleSound proc
	pusha
    invoke playSound, offset titleSound, NULL, SND_ASYNC OR SND_LOOP OR SND_FILENAME
	mov previousPtr, offset titleSound
	popa
    ret
playTitleSound endp
                                  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
playResultSound proc
	pusha
	mov switchSound, 1
    mov soundTimer, 0
    invoke playSound, offset resultSound, NULL, SND_ASYNC OR SND_FILENAME
	popa
    ret
playResultSound endp
                                  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
end main
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;