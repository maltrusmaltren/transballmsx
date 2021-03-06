;-----------------------------------------------
DCOMPR: equ #0020
ENASLT: equ #0024
WRTVDP: equ #0047
WRTVRM: equ #004d
SETWRT: equ #0053
FILVRM: equ #0056
LDIRMV: equ #0059
LDIRVM: equ #005c
CHGMOD: equ #005f
CHGCLR: equ #0062
GICINI: equ #0090   
WRTPSG: equ #0093 
CHGET:  equ #009f
CHPUT:  equ #00a2
GTSTCK: equ #00d5
GTTRIG: equ #00d8
RSLREG: equ #0138
KILBUF: equ #0156
;-----------------------------------------------
; System variables
VDP_DATA: equ #98
CLIKSW: equ #f3db       ; keyboard sound
FORCLR: equ #f3e9
BAKCLR: equ #f3ea
BDRCLR: equ #f3eb
PUTPNT: equ #f3f8
GETPNT: equ #f3fa
KEYS:   equ #fbe5    
KEYBUF: equ #fbf0
EXPTBL: equ #fcc1
JPCODE: equ #c3
;-----------------------------------------------
; VRAM map in Screen 2
CHRTBL2:  equ     #0000   ; pattern table address
SPRTBL2:  equ     #3800   ; sprite pattern address          
NAMTBL2:  equ     #1800   ; name table address 
CLRTBL2:  equ     #2000   ; color table address             
SPRATR2:  equ     #1b00   ; sprite attribute address            
;-----------------------------------------------
; game constants:
SHIPCOLOR:      equ 7
THRUSTERCOLOR:  equ 8
PLAYER_BULLET_COLOR: equ 15
ENEMY_BULLET_COLOR: equ 10
BALL_INACTIVE_COLOR: equ 15
BALL_ACTIVE_COLOR: equ 5
MAXSPEED:       equ 1024
MINSPEED:       equ -1024
GRAVITY:        equ 3
MAXMAPSIZE:     equ 64      ;; maps cannot be larger than MAXMAPSIZE*MAXMAPSIZE in bytes
MAXANIMATIONS:  equ 64   ; the maximum number of tiles in the map that can animate
MAXENEMIES:     equ 32
FUEL_UNIT:      equ 128
MAX_PLAYER_BULLETS: equ 4
MAX_ENEMY_BULLETS: equ 4
MAX_EXPLOSIONS: equ 2
MAX_DOORS: equ 8
MAX_TANKS: equ 4
TANK_MOVE_SPEED: equ 25
BALL_ACTIVATION_DISTANCE: equ 16    ; (in pixels)
ENEMY_BULLET_COLLISION_SIZE: equ 4
CANON_COOLDOWN_PERIOD: equ  150
TANK_COOLDOWN_PERIOD: equ 100
; Sound definition constants:
SFX_REPEAT:     equ  #fa
SFX_END_REPEAT: equ  #fb
SFX_GOTO:       equ  #fc
SFX_SKIP:       equ  #fd
SFX_MULTISKIP:  equ  #fe
SFX_END:        equ  #ff
; GFX definition constants:
PATTERN_FUEL2:  equ  222
PATTERN_FUEL1:  equ  223
PATTERN_FUEL0:  equ  21
PATTERN_BALL_STAND: equ 147
PATTERN_EXPLOSION1: equ 172
PATTERN_EXPLOSION2: equ 174
PATTERN_LEFT_BALL_DOOR: equ 39
PATTERN_LEFT_DOOR: equ 239
PATTERN_RIGHT_DOOR: equ 255
PATTERN_DOOR_BEAM: equ 231
PATTERN_TANK: equ 1
PATTERN_H_LASER: equ 252
; map constants:
RLE_META:   equ #ff
;-----------------------------------------------

    org #4000   ; Somewhere out of the way of small basic programs

;-----------------------------------------------
    db "AB"     ; ROM signature
    dw Execute  ; start address
    db 0,0,0,0,0,0,0,0,0,0,0,0
;-----------------------------------------------


;-----------------------------------------------
; Code that gets executed when the game starts
Execute:
    call move_ROMpage2_to_memorypage1

    ; Silence and init keyboard:
    xor a
    ld (CLIKSW),a
    ld (fire_button_status),a

    ld a,2      ; Change screen mode
    call CHGMOD

    ; Change colors:
    ld a,15
    ld (FORCLR),a
    xor a
    ld (BAKCLR),a
    ld (BDRCLR),a
    call CHGCLR

    ;; clear the screen
    xor a
    call FILLSCREEN

    ; Define the graphic patterns:
    call SETUPPATTERNS

    ;; 16x16 sprites:
    ld bc,#e201  ;; write #e2 in VDP register #01 (activate sprites, generate interrupts, 16x16 sprites with no magnification)
    call WRTVDP

    call setupBaseSprites

    ;; clear the best times:
    ld hl,best_times
    ld b,16
clear_best_times_loop:
    ld (hl),10   ;; minutes (setting it to 10, means "no-time-yet")
    inc hl
    ld (hl),0   ;; ten seconds
    inc hl
    ld (hl),0   ;; seconds
    inc hl
    ld (hl),0  ;; tenths of a second
    inc hl
    ld (hl),0  ;; hundredths of a second
    inc hl
    djnz clear_best_times_loop

    jp SplashScreen


;-----------------------------------------------
; Source: (thanks to ARTRAG) https://www.msx.org/forum/msx-talk/development/memory-pages-again
; Sets the memory pages to : BIOS, ROM, ROM, RAM
move_ROMpage2_to_memorypage1:
    call RSLREG     ; Reads the primary slot register
    rrca
    rrca
    and #03         ; keep the two bits for page 1
    ld c,a
    add a,#C1       
    ld l,a
    ld h,#FC        ; HL = EXPTBL + a
    ld a,(hl)
    and #80         ; keep just the most significant bit (expanded or not)
    or c
    ld c,a          ; c = a || c (a had #80 if slot was expanded, and #00 otherwise)
    inc l           
    inc l
    inc l
    inc l           ; increment 4, in order to get tot the corresponding SLTTBL
    ld a,(hl)       
    and #0C         
    or c            ; in A the rom slotvar 
    ld h,#80        ; move page 1 of the ROM to page 2 in main memory
    call ENASLT       
    ret

;-----------------------------------------------
; additional assembler files
    include "transball-gameloop.asm"
    include "transball-interlevel.asm"
    include "transball-input.asm"
    include "transball-physics.asm"
    include "transball-enemies.asm"
    include "transball-auxiliar.asm"
    include "transball-sound.asm"
    include "transball-gfx.asm"
    include "transball-sprites.asm"
    include "transball-maps.asm"
    include "transball-titlescreen.asm"
    include "transball-song.asm"

InterLevel_text:
    db "    PULSA ESPACIO PARA EMPEZAR   "
Time_is_up_text:
    db "             TIEMPO!             "
Level_complete_text1:
    db  " FASE ACABADA! "
Level_complete_text2:
    db   "TIEMPO: 0:00:00"
Level_complete_text3:
    db   "RECORD: 0:00:00"
Level_complete_text4:
    db       "A - REPETIR"
Level_complete_text5:
    db "DISPARO - SIGUIENTE NIVEL"
Level_complete_text6:
    db     "ESC - SALIR"


splash_line1:
    db "BRAIN  GAMES"
splash_line2:
    db "PRESENTA"


game_complete_line1:
    db "  FELICIDADES!  "
game_complete_line2:
    db "HAS RECOLECTADO TODAS LAS "
game_complete_line3:
    db "ESFERAS DE ENERGIA!"


highscores_header:
    db " RECORDS  "
highscores_text:
    db "FASE       0:00:00"

titlescreen:
    db 0,0,83,65,78,84,73,0,40,80,79,80,79,76,79,78,41,0,79,78,84,65,78,79,78,0,50,48,49,54,0,0
    db 255,0,32
    db 255,0,32
    db 0,0,255,255,1,206,239,203,231,202,203,231,202,247,0,0,247,203,231,239,203,202,0,203,231,202,247,0,0,247,255,0,4
    db 255,0,3,230,0,230,0,230,230,0,230,207,202,0,230,230,0,0,230,230,0,230,0,230,230,0,0,230,255,0,4
    db 255,0,3,230,0,230,0,230,230,0,230,230,204,202,230,230,0,0,230,230,0,230,0,230,230,0,0,230,255,0,4
    db 255,0,3,230,0,207,206,201,207,231,205,230,0,204,205,204,231,202,207,246,202,207,231,205,230,0,0,230,255,0,4
    db 255,0,3,230,0,230,204,202,230,0,230,230,0,0,230,0,0,230,230,0,230,230,0,230,230,0,0,230,255,0,4
    db 255,0,3,247,0,247,0,247,247,0,247,247,0,0,247,255,255,1,231,201,204,231,201,247,0,247,204,231,239,204,231,239,0,0
    db 0,101,97,255,96,26,97,100,0
    db 0,0,149,92,92,160,161,176,160,176,161,160,176,161,161,160,176,176,161,161,160,160,161,177,176,176,160,91,91,95,0,0
    db 255,0,5,149,92,92,161,91,91,255,92,3,91,91,92,91,92,91,255,92,4,161,92,95,255,0,5
    db 255,0,8,230,255,0,15,230,255,0,7
    db 255,0,8,230,255,0,15,230,255,0,7
    db 0,248,249,255,0,5,230,255,0,15,230,255,0,5,134,105
    db 96,181,180,96,96,100,101,96,180,106,255,0,12,101,97,180,155,0,164,165,105,181,160
    db 177,176,161,161,160,96,96,161,161,128,255,0,3,69,77,80,69,90,65,82,255,0,3,129,177,150,96,180,181,151,176,161
    db 161,161,160,255,161,4,176,177,95,255,0,13,149,177,160,177,177,160,176,177,177
    db 160,161,176,162,163,160,177,160,128,255,0,4,82,69,67,79,82,68,83,255,0,4,129,176,161,161,183,161,161,160
    db 177,176,160,178,179,176,177,160,98,255,0,15,149,177,160,160,255,161,3,160
    db 182,160,176,160,160,176,176,160,128,255,0,5,67,76,65,86,69,255,0,6,129,160,177,176,161,166,176
    db 160,255,161,4,183,161,177,93,255,0,16,94,160,255,177,5
    db 255,161,3,177,255,161,3,177,95,255,0,16,149,161,161,182,255,161,3
    db 255,161,3,255,177,4,95,255,0,18,149,161,255,177,3,161


;-----------------------------------------------
; Game variables to be copied to RAM
ROMtoRAM:
map_offsetROM:     ;; top-left coordinates of the portion of the map drawn on screen (lowest 4 bits are the decimal part)
    dw 0, 0
shipstateROM:
    db 0
shipangleROM:      ;; angle goes from 0 - 255
    db 0
shippositionROM:
    dw 16*16,128*16      ;; lowest 4 bits are the decimal part
shipvelocityROM:
    dw 0,0
ballpositionROM:
    dw 0,0
ballvelocityROM:
    dw 0,0
scoreboardROM:
    db "FUEL -----  FASE 00 TIEMPO 00:00"
scoreboard_level_offset: equ 17

InterLevel_text2ROM:
    db "CLAVE:     "
InterLevel_text2_passwordROM:
    db "XXXXXXXX"


;; These variables need to be at the end of the ROM-to-RAM space, since they need to be contiguous with the bullet sprites, which are not in ROM
thruster_spriteattributesROM:
    db 64,64,1*4,THRUSTERCOLOR    ;; 4 is the address of the second sprite shape, 
                                ;; since we are in 16x16 sprite mode, each shape is 4 blocks in size
ship_spriteattributesROM:       
    db 64,64,0,SHIPCOLOR

ball_spriteattributesROM:
    db 0,0,3*4,0     
endROMtoRAM:


End:

    ds ((($-1)/#4000)+1)*#4000-$


;-----------------------------------------------
; Cartridge ends here, below is just a definition of the RAM space used by the game 
;-----------------------------------------------


    org #c000
RAM:    
map_offset:      ;; top-left coordinates of the portion of the map drawn on screen (lowest 4 bits are the decimal part)
    ds virtual 4
shipstate:
    ds virtual 1    ;; 0: ship alive, 1: ship collided
shipangle:       ;; angle from 0 - 63
    ds virtual 1
shipposition:
    ds virtual 4    ;; lowest 4 bits are the decimal part
shipvelocity:
    ds virtual 4
ballposition:
    ds virtual 4
ballvelocity:
    ds virtual 4
scoreboard:
    ds virtual 32
InterLevel_text2:
    ds virtual 11
InterLevel_text2_password:
    ds virtual 8

thruster_spriteattributes:
    ds virtual 4
ship_spriteattributes:
    ds virtual 4
ball_spriteattributes:
    ds virtual 4

AdditionalRAM:  ;; things that are not copied from ROM at the beginning

enemy_bullet_sprite_attributes:
    ds virtual 4*MAX_ENEMY_BULLETS

player_bullet_sprite_attributes:
    ds virtual 4*MAX_PLAYER_BULLETS

current_level:
    ds virtual 1
current_play_time:
    ds virtual 4    ;; minutes, 10 seconds, seconds, frames
current_fuel_left:
    ds virtual 2
current_map_ship_limits:
    ds virtual 8
current_map_dimensions:
    ds virtual 4    ;; byte 0: height, byte 1: width, bytes 2,3: width*height
currentMap:
    ds virtual MAXMAPSIZE*MAXMAPSIZE

;; animations:
currentNAnimations:
    ds virtual 1
currentAnimations:
    ds virtual MAXANIMATIONS*6  ;; each animation: map pointer (dw), animation definition pointer (dw), timer (db), step (db)

;; enemies:
currentNEnemies:
    ds virtual 1
currentEnemies:
    ;; each enemy is 11 bytes:
    ;; type (1 byte)
    ;; map pointer (2 bytes)
    ;; enemy type pointer (2 bytes)
    ;; y (2 bytes)
    ;; x (2 bytes)
    ;; state (1 byte)
    ;; health (1 byte)
    ds virtual MAXENEMIES*11

;; tanks:
currentNTanks:
    ds virtual 1
currentTanks:
    ;; each tank is 8 bytes:
    ;; health (1 byte)
    ;; fire state (1 byte)
    ;; movement state (1 byte)
    ;; y (1 byte)   (in map pattern coordinates)
    ;; x (1 byte)   (in map pattern coordinates)
    ;; map pointer (2 bytes)
    ;; turret angle: 0 (left), 1 (left-up), 2 (right-up), 3 (right)
    ds virtual MAX_TANKS*8

;; bullets:
player_bullet_active:
    ds virtual MAX_PLAYER_BULLETS
player_bullet_positions:
    ds virtual 2*2*MAX_PLAYER_BULLETS
player_bullet_velocities:
    ds virtual 2*2*MAX_PLAYER_BULLETS

;; enemy bullets:
enemy_bullet_active:
    ds virtual MAX_PLAYER_BULLETS
enemy_bullet_positions:
    ds virtual 2*2*MAX_PLAYER_BULLETS
enemy_bullet_velocities:
    ds virtual 2*2*MAX_PLAYER_BULLETS

ballstate:
    ds virtual 1    ;; 0: inactive, 1: active
levelComplete:
    ds virtual 1

;; doors:
ndoors:
    ds virtual 1    
doors:
    ds virtual 3*MAX_DOORS  ;; 1st byte is state (0 closed, 1 open), 2nd and 3rd byte are a pointer to the map position

;; ball doors (doors that are open/closed when the ball is picked up):
nballdoors:
    ds virtual 1    
balldoors:
    ds virtual 3*MAX_DOORS  ;; 1st byte is state (0 closed, 1 open), 2nd and 3rd byte are a pointer to the map position

;; explosions:
explosions_active:
    ds virtual MAX_EXPLOSIONS
explosions_positions_and_replacement:
    ds virtual 4*MAX_EXPLOSIONS     ;; ptr_to_map_position,ptr_to_replacement_pattern_aftet_explosion 

;; main menu variables:
menu_selected_option:
    ds virtual 1
menu_timer:
    ds virtual 1
menu_input_buffer:  ;; previous state of the joystick
    ds virtual 1
fire_button_status:
    ds virtual 1

;; music/SFX variables:
;; SFX:
SFX_play:       ds virtual 1
MUSIC_play:       ds virtual 1
SFX_skip_counter:  ds virtual 1
SFX_pointer:    ;; pointer and channel1_pointer are the same
SFX_channel1_pointer:    ds virtual 2
SFX_channel2_pointer:    ds virtual 2
SFX_channel3_pointer:    ds virtual 2
SFX_channel1_skip_counter:  ds virtual 1
SFX_channel2_skip_counter:  ds virtual 1
SFX_channel3_skip_counter:  ds virtual 1
SFX_channel1_repeat_stack_ptr:  ds virtual 2
SFX_channel2_repeat_stack_ptr:  ds virtual 2
SFX_channel3_repeat_stack_ptr:  ds virtual 2
MUSIC_tempo:  ds virtual 1
MUSIC_tempo_counter: ds virtual 1
SFX_channel1_repeat_stack:  ds virtual 4*3
SFX_channel2_repeat_stack:  ds virtual 4*3
SFX_channel3_repeat_stack:  ds virtual 4*3

;; best times:
current_time_buffer:
    ds virtual 5
best_times:
    ds virtual 16*5 ;; 5 bytes per map
password_buffer:
best_times_buffer:
    ds virtual 32   ;; a one line buffer, to write things to screen

;; temporary variables:
ballPositionBeforePhysics:  ;; temporary storage to restore the position of the ball after a collision
    ds virtual 4
ballCollisioncount:         ;; temporary variable to count the number of points that collide with the ball
    ds virtual 1
