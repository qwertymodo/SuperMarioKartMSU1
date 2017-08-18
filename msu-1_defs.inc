if !{defined _msu1_defs_inc} {
define _msu1_defs_inc()

define REG_MSU_STATUS($2000)
define REG_MSU_DATA($2001)
define REG_MSU_ID_0($2002)
define REG_MSU_ID_1($2003)
define REG_MSU_ID_2($2004)
define REG_MSU_ID_3($2005)
define REG_MSU_ID_4($2006)
define REG_MSU_ID_5($2007)

define REG_MSU_ID_01($2002)
define REG_MSU_ID_23($2004)
define REG_MSU_ID_45($2006)

define VAL_MSU_ID_0(#$53)   // 'S'
define VAL_MSU_ID_1(#$2D)   // '-'
define VAL_MSU_ID_2(#$4D)   // 'M'
define VAL_MSU_ID_3(#$53)   // 'S'
define VAL_MSU_ID_4(#$55)   // 'U'
define VAL_MSU_ID_5(#$31)   // '1'

define VAL_MSU_ID_01(#$2D53)// 'S-'
define VAL_MSU_ID_23(#$534D)// 'MS'
define VAL_MSU_ID_45(#$3155)// 'U1'

define REG_MSU_SEEK_0($2000)
define REG_MSU_SEEK_1($2001)
define REG_MSU_SEEK_2($2002)
define REG_MSU_SEEK_3($2003)

define REG_MSU_SEEK_01($2000)
define REG_MSU_SEEK_23($2002)


define REG_MSU_TRACK($2004)
define REG_MSU_TRACK_LO($2004)
define REG_MSU_TRACK_HI($2005)
define REG_MSU_VOLUME($2006)
define REG_MSU_CONTROL($2007)


define FLAG_MSU_PLAY(#$01)
define FLAG_MSU_REPEAT(#$02)
define FLAG_MSU_RESUME(#$04)
define FLAG_MSU_STATUS_REVISION(#$07)
define FLAG_MSU_STATUS_TRACK_MISSING(#$08)
define FLAG_MSU_STATUS_AUDIO_PLAYING(#$10)
define FLAG_MSU_STATUS_AUDIO_REPEATING(#$20)
define FLAG_MSU_STATUS_AUDIO_BUSY(#$40)
define FLAG_MSU_STATUS_DATA_BUSY(#$80)


define REG_APU_PORT_0($2140)
define REG_APU_PORT_1($2141)
define REG_APU_PORT_2($2142)
define REG_APU_PORT_3($2143)


macro CHECK_FOR_MSU(variable jump_not_found) {
    php
    phb
    rep #$20
    pha
    sep #$20
    lda #$00
    pha
    plb
    rep #$20
    lda {REG_MSU_ID_01}
    cmp {VAL_MSU_ID_01}
    bne +
    lda {REG_MSU_ID_23}
    cmp {VAL_MSU_ID_23}
    bne +
    lda {REG_MSU_ID_45}
    cmp {VAL_MSU_ID_45}
    beq ++
+;  pla
    plb
    plp
    jml jump_not_found
+;  pla
    plb
    plp
}

macro MSU_TO_VRAM(count) {
    lda #$80
    sta $2115   // VRAM single word transfer, word increment
    ldx #$1809
    stx $4300   // DMA destination: VMDATAL/VMDATAH, fixed source
    ldx #{REG_MSU_DATA}// MSU-1 data read port
    stx $4302   // Low DMA source address
    lda #$00
    sta $4304   // High DMA source address
    ldx.w {count}
    stx $4305   // Transfer 2048 bytes
    lda #$01
    sta $420B   // Start DMA transfer
}

macro MSU_TO_CGRAM() {
    stz $2121   // Start at color 0
    ldx #$2208
    stx $4300   // DMA destination: CGDATA, byte increment
    ldx #{REG_MSU_DATA}// MSU-1 data read port
    stx $4302   // Low DMA source address
    lda #$00
    sta $4304   // High DMA source address
    ldx #$0200
    stx $4305   // Transfer 512 bytes
    lda #$01
    sta $420B   // Start DMA transfer
}

} // _msu1_defs_inc