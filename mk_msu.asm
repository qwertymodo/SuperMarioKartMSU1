//**********************************************************
//* Super Mario Kart MSU-1 Audio Hack
//*
//* Copyright qwertymodo, 2017
//* 
//* Assembler: bass v14
//*   bass -d input=in.sfc -o out.sfc -create mk_msu.asm
//*
//* Song List:
//*   01: Race Fanfare
//*   05: Final Lap Notice
//*   08: Super Star Theme
//*   09: New Record
//*   10: No Record
//*   11: Ranked Out
//*   12: Mario's Rank
//*   13: Luigi's Rank
//*   14: Bowser's Rank
//*   15: Peach's Rank
//*   16: DK's Rank
//*   17: Koopa's Rank
//*   18: Toad's Rank
//*   19: Yoshi's Rank
//*   20: Game Over
//*
//*   32: Title Screen
//*   35: Kart Select
//*   36: Staff Roll
//*   38: Mario Circuit**
//*   41: Donut Plains**
//*   44: Choco Island**
//*   47: Koopa Beach**
//*   50: Vanilla Lake**
//*   53: Ghost Valley**
//*   56: Bowser Castle**
//*   59: Battle Mode**
//*   62: Tournament Win
//*   65: Tournament Lose
//*   71: Rainbow Road**
//*
//*   80: Mario Circuit 3*
//*   82: Ghost Valley 2*
//*   84: Donut Plains 2*
//*   86: Bowser Castle 2*
//*   88: Vanilla Lake 2*
//*   90: Rainbow Road*
//*   92: Koopa Beach 2*
//*   94: Mario Circuit 1*
//*   96: Ghost Valley 3*
//*   98: Bowser Castle 3*
//*  100: Choco Island 2*
//*  102: Donut Plains 3*
//*  104: Vanilla Lake 1*
//*  106: Koopa Beach 1*
//*  108: Mario Circuit 4*
//*  110: Mario Circuit 2*
//*  112: Ghost Valley 1*
//*  114: Bowser Castle 1*
//*  116: Choco Island 1*
//*  118: Donut Plains 1*
//*
//*  [*]  Song number +1 for fast version
//*  [**] Same song for all songs, +1 for fast version
//**********************************************************

arch snes.cpu

define hirom()

define CHECKSUM($FD22)

include "snes_utils.inc"
include "msu-1_defs.inc"


warning "These RAM addresses are not confirmed to be unused"
define REG_CURRENT_VOLUME($7E012A)
define REG_TARGET_VOLUME($7E012B)
define REG_CURRENT_SONG($7E012C)
define REG_CURRENT_SONG_SHORT($012C)

define REG_CURRENT_TRACK($7E0124)

define VAL_VOLUME_INCREMENT(#$10)
define VAL_VOLUME_DECREMENT(#$10)
define VAL_VOLUME_MUTE(#$0F)
define VAL_VOLUME_HALF(#$80)
define VAL_VOLUME_FULL(#$FF)


scope {
seek($81F435)
    jsl store_bank
    nop; nop; nop;
assert_end($81F43C)

seek($C11FA0)
store_bank:
    phb
    phx
    ldx #$0000
    phx
    plb
    plb
    plx
    stx {REG_CURRENT_SONG_SHORT}
    ldx #$C000
    plb
    jml continue
assert_end($C12000)

seek($84E09E)
continue:
}


scope {
seek($8097A3)
    jsl msu_main
    nop
assert_end($8097A8)

seek($C09615)
    jsr msu_short_jump
assert_end($C0961A)

seek($C09300)
msu_short_jump:
    jsl msu_main
    rts
assert_end($C093F0)

seek($C21E60)
msu_main:
    pha
    phb
    pha
    lda #$00
    pha
    plb
    pla
    CHECK_FOR_MSU(spc_continue)
    cmp #$00
    beq do_fade

// Command $1D: Mute
+;  cmp #$1D
    bne +
    lda #$00
    sta {REG_TARGET_VOLUME}
    sta {REG_MSU_VOLUME}
    bra do_fade

// Command $1E: Fade Out    
+;  cmp #$1E
    bne +
    lda #$00
    sta {REG_TARGET_VOLUME}
    bra do_fade

// Command $1F: Fade In
+;  cmp #$1F
    bne +
    lda #$FF
    sta {REG_TARGET_VOLUME}
    bra do_fade

// Command $04/$16: Play Song (Normal Speed)
+;  cmp #$04
    beq +
    cmp #$16
    bne ++
+;  brl play_song_normal

// Command $06/07/15: Play Song (Fast Speed)
+;  cmp #$06
    beq +
    cmp #$07
    beq +
    cmp #$15
    bne ++
+;  brl play_song_fast

// Command $08: Invincible
+;  cmp #$08
//  Resume??
    bne +
    brl play_song_normal

// Commands >= $20: Send to SPC normally
+;  cmp #$20
    bcc +
    bra spc_continue
    
// Ranks
+;  jsr check_song_exists
    bcc spc_continue
    cmp #$0C
    bcc play_once
    cmp #$14
    bcs play_once
    bra play_loop

do_fade:
    lda {REG_CURRENT_VOLUME}
    cmp {REG_TARGET_VOLUME}
    beq spc_continue
    bcc +
    sbc {VAL_VOLUME_DECREMENT}
//    cmp {VAL_VOLUME_MUTE}
    bcs ++
    lda #$00
    sta {REG_CURRENT_VOLUME}
    sta {REG_MSU_CONTROL}   // Stop playback when fade completes
    bra ++
+;  adc {VAL_VOLUME_INCREMENT}
    bcc +
    lda {VAL_VOLUME_FULL}
+;  sta {REG_CURRENT_VOLUME}
    sta {REG_MSU_VOLUME}
    bra spc_continue

play_loop:
    lda {VAL_VOLUME_FULL}
    sta {REG_TARGET_VOLUME}
    sta {REG_CURRENT_VOLUME}
    sta {REG_MSU_VOLUME}
    lda #$03
    sta {REG_MSU_CONTROL}
    bra spc_mute

play_once:
    lda {VAL_VOLUME_FULL}
    sta {REG_TARGET_VOLUME}
    sta {REG_CURRENT_VOLUME}
    sta {REG_MSU_VOLUME}
    lda #$01
    sta {REG_MSU_CONTROL}
    bra spc_mute

spc_mute:
    plb
    pla
    lda #$1D
    sta {REG_APU_PORT_0}
    rep #$30
    rtl

spc_continue:
    plb
    pla
    sta {REG_APU_PORT_0}
    rep #$30
    rtl

spc_skip:
    plb
    pla
    rep #$30
    rtl

play_song_normal:
// Check special tracks
    lda {REG_CURRENT_SONG}
// Title Screen
    beq ++
// Select Screen
    cmp #$03
    beq ++
// Battle Mode
    cmp #$1B
    beq ++
// Tournament Win
    cmp #$1E
    beq ++
// Tournament Lose
    cmp #$21
    beq ++
// Staff Roll
    cmp #$24
    bne +
    jsr check_song_exists
    bcc spc_continue
    bra play_once
// Check Track-Specific Songs
+;  lda {REG_CURRENT_TRACK}
    asl
    clc
    adc #$50
    jsr check_song_exists
    bcs play_loop
// Check Shared Songs
    lda {REG_CURRENT_SONG}
+;  clc
    adc #$20
    jsr check_song_exists
    bcc spc_continue
    bra play_loop

play_song_fast:
// Check Track-Specific Songs
    lda {REG_CURRENT_TRACK}
    asl
    clc
    adc #$51
    jsr check_song_exists
    bcc +
    brl play_loop
// Check Shared Songs
+;  lda {REG_CURRENT_SONG}
    clc
    adc #$21
    jsr check_song_exists
    bcc spc_continue
    brl play_loop


// Input: Song # (A, 8-bit)
// Output: Carry flag, set = true, clear = false
check_song_exists:
    pha
    sta {REG_MSU_TRACK_LO}
    stz {REG_MSU_TRACK_HI}
-;  lda {REG_MSU_STATUS}
    bit {FLAG_MSU_STATUS_AUDIO_BUSY}
    bne -
    bit {FLAG_MSU_STATUS_TRACK_MISSING}
    bne +
    pla
    sec
    rts
+;  pla
    clc
    rts
assert_end($C22000)
}
