
option casemap:none

extern rand:proc
extern srand:proc
extern time:proc
extern atoi:proc
extern GetModuleHandleA:proc
extern LoadCursorA:proc
extern RegisterClassExA:proc
extern CreateWindowExA:proc
extern DefWindowProcA:proc
extern ShowWindow:proc
extern UpdateWindow:proc
extern GetMessageA:proc
extern TranslateMessage:proc
extern DispatchMessageA:proc
extern PostQuitMessage:proc
extern BeginPaint:proc
extern EndPaint:proc
extern GetClientRect:proc
extern FillRect:proc
extern CreateSolidBrush:proc
extern RoundRect:proc
extern SelectObject:proc
extern SetTextColor:proc
extern SetBkMode:proc
extern TextOutA:proc
extern CreateFontA:proc
extern InvalidateRect:proc
extern EnableWindow:proc
extern GetWindowTextA:proc
extern wsprintfA:proc

WS_OVERLAPPEDWINDOW equ 0CF0000h
WS_VISIBLE          equ 10000000h
WS_CHILD            equ 40000000h
WS_TABSTOP          equ 10000h
BS_DEFPUSHBUTTON    equ 1h
ES_NUMBER           equ 2000h
ES_CENTER           equ 1h
WM_CREATE           equ 1
WM_DESTROY          equ 2
WM_PAINT            equ 0Fh
WM_COMMAND          equ 111h
CW_USEDEFAULT       equ 80000000h
SW_SHOWNORMAL       equ 1
IDC_ARROW           equ 32512
TRANSPARENT         equ 1
CS_HREDRAW          equ 2
CS_VREDRAW          equ 1
WS_EX_CLIENTEDGE    equ 200h

ID_HIT    equ 101
ID_STAND  equ 102
ID_SPLIT  equ 103
ID_DOUBLE equ 104
ID_DEAL   equ 105

C_FELT   equ 0356B2Eh
C_WHITE  equ 0FFFFFFh
C_BLACK  equ 0h
C_RED    equ 00000FFh
C_BLUE   equ 0883311h
C_GOLD   equ 020C0FFh
C_TEXT   equ 0F0F0F0h

.data
clsName   db "BJWINCLS",0
winTitle  db "Blackjack  -  vbucks",0
btnClass  db "BUTTON",0
editClass db "EDIT",0

lHit      db "hit that bitch",0
lStand    db "no im a pussy",0
lSplit    db "split it brochacho",0
lDouble   db "MY WIFE IS GOING TO DIVORCE ME",0
lDeal     db "DEAL",0
fontFace  db "Segoe UI",0

rk1  db "A",0
rk2  db "2",0
rk3  db "3",0
rk4  db "4",0
rk5  db "5",0
rk6  db "6",0
rk7  db "7",0
rk8  db "8",0
rk9  db "9",0
rk10 db "10",0
rk11 db "J",0
rk12 db "Q",0
rk13 db "K",0
rankTbl qword 0, rk1,rk2,rk3,rk4,rk5,rk6,rk7,rk8,rk9,rk10,rk11,rk12,rk13
su0 db "S",0
su1 db "H",0
su2 db "D",0
su3 db "C",0
suitTbl qword su0,su1,su2,su3

fmtBal   db "Balance: %d vbucks",0
fmtDeal  db "DEALER",0
fmtYou   db "YOU",0
fmtDTot  db "Dealer: %d",0
fmtPTot  db "You: %d",0
defBet   db "100",0

mDealHint db "Set your bet and press DEAL.",0
mWin      db "YOU WIN!",0
mLose     db "Dealer wins.",0
mPush     db "Push.",0
mBJ       db "BLACKJACK! Paid 3:2.",0
mBroke    db "Out of vbucks!",0

hInst     qword 0
hWndMain  qword 0
hHit      qword 0
hStand    qword 0
hSplit    qword 0
hDouble   qword 0
hDeal     qword 0
hEdit     qword 0
hFeltBr   qword 0
hWhiteBr  qword 0
hBlueBr   qword 0
hFontBig  qword 0
hFontMed  qword 0
creatingHwnd qword 0

state     dd 0
balance   dd 1000
bet       dd 100
numHands  dd 1
actHand   dd 0
revealed  dd 0

pRank     db 24 dup(0)
pSuit     db 24 dup(0)
pN        dd 0,0
pTot      dd 0,0
pAce      dd 0,0
pBust     dd 0,0
pBet      dd 0,0

dRank     db 12 dup(0)
dSuit     db 12 dup(0)
dN        dd 0
dTot      dd 0
dAce      dd 0

tmpRank   dd 0
tmpSuit   dd 0
tmpIdx    dd 0
hLoop     dd 0
curMsg    qword 0

dcHdc  qword 0
dcX    dd 0
dcY    dd 0
dcRank dd 0
dcSuit dd 0
dcFace dd 0

dtHdc  qword 0
dtX    dd 0
dtY    dd 0
dtStr  qword 0
dtFont qword 0
dtColor dd 0

curHdc qword 0

wc        db 80 dup(0)
msgbuf    db 64 dup(0)
ps        db 72 dup(0)
rc        db 16 dup(0)
txtbuf    db 128 dup(0)
editbuf   db 32 dup(0)

.code

rnd proc
    push rbp
    mov  rbp, rsp
    sub  rsp, 48
    and  rsp, -16
    mov  [rbp-8], ecx
    call rand
    xor  edx, edx
    mov  ecx, [rbp-8]
    div  ecx
    mov  eax, edx
    mov  rsp, rbp
    pop  rbp
    ret
rnd endp

rank_value proc
    mov  eax, ecx
    cmp  eax, 10
    jle  rv_d
    mov  eax, 10
rv_d:
    ret
rank_value endp

soft_fix proc
sf_l:
    mov  eax, [r10]
    cmp  eax, 21
    jle  sf_d
    cmp  dword ptr [r11], 0
    je   sf_d
    sub  dword ptr [r10], 10
    dec  dword ptr [r11]
    jmp  sf_l
sf_d:
    ret
soft_fix endp

player_add proc
    push rbp
    mov  rbp, rsp
    sub  rsp, 64
    and  rsp, -16
    mov  [tmpIdx], ecx
    mov  ecx, 13
    call rnd
    inc  eax
    mov  [tmpRank], eax
    mov  ecx, 4
    call rnd
    mov  [tmpSuit], eax

    mov  ecx, [tmpIdx]
    lea  r10, pN
    mov  r9d, [r10 + rcx*4]
    mov  eax, ecx
    imul eax, eax, 12
    add  eax, r9d
    movsxd r8, eax
    lea  r10, pRank
    mov  edx, [tmpRank]
    mov  byte ptr [r10 + r8], dl
    lea  r10, pSuit
    mov  edx, [tmpSuit]
    mov  byte ptr [r10 + r8], dl

    mov  ecx, [tmpRank]
    call rank_value
    mov  edx, [tmpRank]
    cmp  edx, 1
    jne  pa_nace
    mov  eax, 11
    mov  ecx, [tmpIdx]
    lea  r11, pAce
    inc  dword ptr [r11 + rcx*4]
pa_nace:
    mov  ecx, [tmpIdx]
    lea  r10, pTot
    add  [r10 + rcx*4], eax

    mov  ecx, [tmpIdx]
    lea  r10, pTot
    lea  r10, [r10 + rcx*4]
    lea  r11, pAce
    lea  r11, [r11 + rcx*4]
    call soft_fix
    mov  ecx, [tmpIdx]
    lea  r10, pN
    inc  dword ptr [r10 + rcx*4]

    mov  ecx, [tmpIdx]
    lea  r10, pTot
    mov  eax, [r10 + rcx*4]
    cmp  eax, 21
    jle  pa_d
    lea  r10, pBust
    mov  dword ptr [r10 + rcx*4], 1
pa_d:
    mov  rsp, rbp
    pop  rbp
    ret
player_add endp

dealer_add proc
    push rbp
    mov  rbp, rsp
    sub  rsp, 64
    and  rsp, -16
    mov  ecx, 13
    call rnd
    inc  eax
    mov  [tmpRank], eax
    mov  ecx, 4
    call rnd
    mov  [tmpSuit], eax
    mov  r9d, [dN]
    movsxd r8, r9d
    lea  r10, dRank
    mov  edx, [tmpRank]
    mov  byte ptr [r10 + r8], dl
    lea  r10, dSuit
    mov  edx, [tmpSuit]
    mov  byte ptr [r10 + r8], dl
    mov  ecx, [tmpRank]
    call rank_value
    mov  edx, [tmpRank]
    cmp  edx, 1
    jne  da_nace
    mov  eax, 11
    inc  dword ptr [dAce]
da_nace:
    add  [dTot], eax
    lea  r10, dTot
    lea  r11, dAce
    call soft_fix
    inc  dword ptr [dN]
    mov  rsp, rbp
    pop  rbp
    ret
dealer_add endp

set_single proc
    mov  r9d, edx
    mov  eax, ecx
    imul eax, eax, 12
    movsxd r10, eax
    lea  r11, pRank
    mov  byte ptr [r11 + r10], r9b
    lea  r11, pSuit
    mov  byte ptr [r11 + r10], r8b
    mov  eax, r9d
    cmp  eax, 10
    jle  ss_v
    mov  eax, 10
ss_v:
    cmp  r9d, 1
    jne  ss_nace
    mov  eax, 11
    lea  r11, pAce
    mov  dword ptr [r11 + rcx*4], 1
    jmp  ss_store
ss_nace:
    lea  r11, pAce
    mov  dword ptr [r11 + rcx*4], 0
ss_store:
    lea  r11, pTot
    mov  [r11 + rcx*4], eax
    lea  r11, pN
    mov  dword ptr [r11 + rcx*4], 1
    lea  r11, pBust
    mov  dword ptr [r11 + rcx*4], 0
    ret
set_single endp

repaint proc
    push rbp
    mov  rbp, rsp
    sub  rsp, 48
    and  rsp, -16
    mov  rcx, [hWndMain]
    xor  rdx, rdx
    mov  r8d, 1
    call InvalidateRect
    mov  rsp, rbp
    pop  rbp
    ret
repaint endp

set_actions proc
    push rbp
    mov  rbp, rsp
    sub  rsp, 48
    and  rsp, -16
    mov  [rbp-8], ecx
    mov  rcx, [hHit]
    mov  edx, [rbp-8]
    call EnableWindow
    mov  rcx, [hStand]
    mov  edx, [rbp-8]
    call EnableWindow
    mov  rcx, [hSplit]
    mov  edx, [rbp-8]
    call EnableWindow
    mov  rcx, [hDouble]
    mov  edx, [rbp-8]
    call EnableWindow
    mov  rsp, rbp
    pop  rbp
    ret
set_actions endp

dealer_play proc
    push rbp
    mov  rbp, rsp
    sub  rsp, 48
    and  rsp, -16
    mov  dword ptr [revealed], 1
dp_l:
    cmp  dword ptr [dTot], 17
    jge  dp_d
    call dealer_add
    jmp  dp_l
dp_d:
    mov  rsp, rbp
    pop  rbp
    ret
dealer_play endp

settle_all proc
    push rbp
    mov  rbp, rsp
    sub  rsp, 48
    and  rsp, -16
    mov  dword ptr [tmpIdx], 0
sa_loop:
    mov  eax, [tmpIdx]
    cmp  eax, [numHands]
    jge  sa_done
    mov  ecx, [tmpIdx]
    lea  r10, pBust
    cmp  dword ptr [r10 + rcx*4], 1
    je   sa_lose
    cmp  dword ptr [dTot], 21
    jg   sa_win
    mov  ecx, [tmpIdx]
    lea  r10, pTot
    mov  eax, [r10 + rcx*4]
    cmp  eax, [dTot]
    jg   sa_win
    je   sa_push
    jmp  sa_lose
sa_win:
    mov  ecx, [tmpIdx]
    lea  r10, pBet
    mov  eax, [r10 + rcx*4]
    add  eax, eax
    add  [balance], eax
    lea  rax, mWin
    mov  [curMsg], rax
    jmp  sa_next
sa_push:
    mov  ecx, [tmpIdx]
    lea  r10, pBet
    mov  eax, [r10 + rcx*4]
    add  [balance], eax
    lea  rax, mPush
    mov  [curMsg], rax
    jmp  sa_next
sa_lose:
    lea  rax, mLose
    mov  [curMsg], rax
sa_next:
    inc  dword ptr [tmpIdx]
    jmp  sa_loop
sa_done:
    mov  rsp, rbp
    pop  rbp
    ret
settle_all endp

finish_round proc
    push rbp
    mov  rbp, rsp
    sub  rsp, 48
    and  rsp, -16
    call dealer_play
    call settle_all
    mov  dword ptr [state], 2
    mov  ecx, 0
    call set_actions
    mov  rcx, [hDeal]
    mov  edx, 1
    call EnableWindow
    call repaint
    mov  rsp, rbp
    pop  rbp
    ret
finish_round endp

advance_or_finish proc
    push rbp
    mov  rbp, rsp
    sub  rsp, 48
    and  rsp, -16
    mov  eax, [actHand]
    inc  eax
    cmp  eax, [numHands]
    jl   aof_next
    call finish_round
    jmp  aof_d
aof_next:
    mov  [actHand], eax
    call repaint
aof_d:
    mov  rsp, rbp
    pop  rbp
    ret
advance_or_finish endp

do_deal proc
    push rbp
    mov  rbp, rsp
    sub  rsp, 64
    and  rsp, -16
    cmp  dword ptr [balance], 1
    jge  dd_ok
    lea  rax, mBroke
    mov  [curMsg], rax
    call repaint
    jmp  dd_ret
dd_ok:
    mov  rcx, [hEdit]
    lea  rdx, editbuf
    mov  r8d, 31
    call GetWindowTextA
    lea  rcx, editbuf
    call atoi
    cmp  eax, 1
    jl   dd_usebet
    cmp  eax, [balance]
    jg   dd_usebet
    mov  [bet], eax
dd_usebet:
    mov  dword ptr [numHands], 1
    mov  dword ptr [actHand], 0
    mov  dword ptr [revealed], 0
    xor  eax, eax
    mov  dword ptr [pN+0], eax
    mov  dword ptr [pN+4], eax
    mov  dword ptr [pTot+0], eax
    mov  dword ptr [pTot+4], eax
    mov  dword ptr [pAce+0], eax
    mov  dword ptr [pAce+4], eax
    mov  dword ptr [pBust+0], eax
    mov  dword ptr [pBust+4], eax
    mov  dword ptr [dN], eax
    mov  dword ptr [dTot], eax
    mov  dword ptr [dAce], eax
    mov  ecx, [bet]
    mov  dword ptr [pBet+0], ecx
    mov  dword ptr [pBet+4], eax
    mov  ecx, [bet]
    sub  [balance], ecx
    mov  ecx, 0
    call player_add
    call dealer_add
    mov  ecx, 0
    call player_add
    call dealer_add
    mov  dword ptr [state], 1
    lea  rax, mDealHint
    mov  [curMsg], rax
    cmp  dword ptr [pTot+0], 21
    jne  dd_play
    cmp  dword ptr [dTot], 21
    jne  dd_bj
    mov  ecx, [bet]
    add  [balance], ecx
    lea  rax, mPush
    mov  [curMsg], rax
    jmp  dd_natend
dd_bj:
    mov  ecx, [bet]
    add  [balance], ecx
    mov  eax, [bet]
    imul eax, eax, 3
    cdq
    mov  ecx, 2
    idiv ecx
    add  [balance], eax
    lea  rax, mBJ
    mov  [curMsg], rax
dd_natend:
    mov  dword ptr [revealed], 1
    mov  dword ptr [state], 2
    mov  ecx, 0
    call set_actions
    mov  rcx, [hDeal]
    mov  edx, 1
    call EnableWindow
    call repaint
    jmp  dd_ret
dd_play:
    mov  ecx, 1
    call set_actions
    mov  rcx, [hDeal]
    mov  edx, 0
    call EnableWindow
    call repaint
dd_ret:
    mov  rsp, rbp
    pop  rbp
    ret
do_deal endp

do_hit proc
    push rbp
    mov  rbp, rsp
    sub  rsp, 48
    and  rsp, -16
    cmp  dword ptr [state], 1
    jne  dh_d
    mov  ecx, [actHand]
    call player_add
    mov  ecx, [actHand]
    lea  r10, pBust
    cmp  dword ptr [r10 + rcx*4], 1
    jne  dh_rep
    call advance_or_finish
    jmp  dh_d
dh_rep:
    call repaint
dh_d:
    mov  rsp, rbp
    pop  rbp
    ret
do_hit endp

do_stand proc
    push rbp
    mov  rbp, rsp
    sub  rsp, 48
    and  rsp, -16
    cmp  dword ptr [state], 1
    jne  ds_d
    call advance_or_finish
ds_d:
    mov  rsp, rbp
    pop  rbp
    ret
do_stand endp

do_double proc
    push rbp
    mov  rbp, rsp
    sub  rsp, 48
    and  rsp, -16
    cmp  dword ptr [state], 1
    jne  dbl_d
    mov  ecx, [actHand]
    lea  r10, pN
    cmp  dword ptr [r10 + rcx*4], 2
    jne  dbl_d
    mov  eax, [bet]
    cmp  [balance], eax
    jl   dbl_d
    sub  [balance], eax
    mov  ecx, [actHand]
    lea  r10, pBet
    add  [r10 + rcx*4], eax
    mov  ecx, [actHand]
    call player_add
    call advance_or_finish
dbl_d:
    mov  rsp, rbp
    pop  rbp
    ret
do_double endp

do_split proc
    push rbp
    mov  rbp, rsp
    sub  rsp, 64
    and  rsp, -16
    cmp  dword ptr [state], 1
    jne  ds2_d
    cmp  dword ptr [numHands], 1
    jne  ds2_d
    mov  ecx, [actHand]
    lea  r10, pN
    cmp  dword ptr [r10 + rcx*4], 2
    jne  ds2_d
    movzx eax, byte ptr [pRank+0]
    movzx edx, byte ptr [pRank+1]
    cmp  eax, edx
    jne  ds2_d
    mov  eax, [bet]
    cmp  [balance], eax
    jl   ds2_d
    sub  [balance], eax
    mov  dword ptr [pBet+4], eax
    movzx edx, byte ptr [pRank+1]
    movzx r8d, byte ptr [pSuit+1]
    mov  ecx, 1
    call set_single
    movzx edx, byte ptr [pRank+0]
    movzx r8d, byte ptr [pSuit+0]
    mov  ecx, 0
    call set_single
    mov  dword ptr [numHands], 2
    mov  ecx, 0
    call player_add
    mov  ecx, 1
    call player_add
    call repaint
ds2_d:
    mov  rsp, rbp
    pop  rbp
    ret
do_split endp

draw_card proc
    push rbp
    mov  rbp, rsp
    sub  rsp, 96
    and  rsp, -16
    mov  rcx, [dcHdc]
    cmp  dword ptr [dcFace], 0
    jne  dc_white
    mov  rdx, [hBlueBr]
    jmp  dc_sel
dc_white:
    mov  rdx, [hWhiteBr]
dc_sel:
    call SelectObject
    mov  rcx, [dcHdc]
    mov  edx, [dcX]
    mov  r8d, [dcY]
    mov  r9d, [dcX]
    add  r9d, 72
    mov  eax, [dcY]
    add  eax, 100
    mov  [rsp+32], rax
    mov  qword ptr [rsp+40], 14
    mov  qword ptr [rsp+48], 14
    call RoundRect
    cmp  dword ptr [dcFace], 0
    je   dc_done
    mov  rcx, [dcHdc]
    mov  edx, C_BLACK
    mov  eax, [dcSuit]
    cmp  eax, 1
    je   dc_red
    cmp  eax, 2
    je   dc_red
    jmp  dc_setc
dc_red:
    mov  edx, C_RED
dc_setc:
    call SetTextColor
    mov  rcx, [dcHdc]
    mov  rdx, [hFontBig]
    call SelectObject

    mov  rcx, [dcHdc]
    mov  edx, [dcX]
    add  edx, 8
    mov  r8d, [dcY]
    add  r8d, 6
    movsxd rax, dword ptr [dcRank]
    lea  r10, rankTbl
    mov  r9, [r10 + rax*8]
    mov  eax, 1
    cmp  dword ptr [dcRank], 10
    jne  dc_l1
    mov  eax, 2
dc_l1:
    mov  [rsp+32], rax
    call TextOutA

    mov  rcx, [dcHdc]
    mov  edx, [dcX]
    add  edx, 28
    mov  r8d, [dcY]
    add  r8d, 46
    movsxd rax, dword ptr [dcSuit]
    lea  r10, suitTbl
    mov  r9, [r10 + rax*8]
    mov  qword ptr [rsp+32], 1
    call TextOutA
dc_done:
    mov  rsp, rbp
    pop  rbp
    ret
draw_card endp

draw_text proc
    push rbp
    mov  rbp, rsp
    sub  rsp, 64
    and  rsp, -16
    mov  rcx, [dtHdc]
    mov  rdx, [dtFont]
    call SelectObject
    mov  rcx, [dtHdc]
    mov  edx, [dtColor]
    call SetTextColor
    mov  r10, [dtStr]
    xor  eax, eax
dt_len:
    cmp  byte ptr [r10 + rax], 0
    je   dt_lend
    inc  eax
    jmp  dt_len
dt_lend:
    mov  rcx, [dtHdc]
    mov  edx, [dtX]
    mov  r8d, [dtY]
    mov  r9, [dtStr]
    mov  [rsp+32], rax
    call TextOutA
    mov  rsp, rbp
    pop  rbp
    ret
draw_text endp

on_paint proc
    push rbp
    mov  rbp, rsp
    sub  rsp, 96
    and  rsp, -16
    mov  [curHdc], rcx
    mov  rcx, [hWndMain]
    lea  rdx, rc
    call GetClientRect
    mov  rcx, [curHdc]
    lea  rdx, rc
    mov  r8, [hFeltBr]
    call FillRect
    mov  rcx, [curHdc]
    mov  edx, TRANSPARENT
    call SetBkMode

    mov  rax, [curHdc]
    mov  [dtHdc], rax
    mov  rax, [hFontMed]
    mov  [dtFont], rax
    mov  dword ptr [dtColor], C_TEXT
    mov  dword ptr [dtX], 40
    mov  dword ptr [dtY], 24
    lea  rax, fmtDeal
    mov  [dtStr], rax
    call draw_text
    mov  dword ptr [dtY], 300
    lea  rax, fmtYou
    mov  [dtStr], rax
    call draw_text

    lea  rcx, txtbuf
    lea  rdx, fmtBal
    mov  r8d, [balance]
    call wsprintfA
    mov  rax, [hFontMed]
    mov  [dtFont], rax
    mov  dword ptr [dtColor], C_GOLD
    mov  dword ptr [dtX], 560
    mov  dword ptr [dtY], 24
    lea  rax, txtbuf
    mov  [dtStr], rax
    call draw_text

    mov  rax, [curMsg]
    test rax, rax
    je   op_nomsg
    mov  [dtStr], rax
    mov  rax, [hFontMed]
    mov  [dtFont], rax
    mov  dword ptr [dtColor], C_WHITE
    mov  dword ptr [dtX], 560
    mov  dword ptr [dtY], 300
    call draw_text
op_nomsg:

    cmp  dword ptr [revealed], 1
    jne  op_nodtot
    lea  rcx, txtbuf
    lea  rdx, fmtDTot
    mov  r8d, [dTot]
    call wsprintfA
    mov  rax, [hFontMed]
    mov  [dtFont], rax
    mov  dword ptr [dtColor], C_WHITE
    mov  dword ptr [dtX], 170
    mov  dword ptr [dtY], 24
    lea  rax, txtbuf
    mov  [dtStr], rax
    call draw_text
op_nodtot:

    lea  rcx, txtbuf
    lea  rdx, fmtPTot
    mov  r8d, [pTot+0]
    call wsprintfA
    mov  rax, [hFontMed]
    mov  [dtFont], rax
    mov  dword ptr [dtColor], C_WHITE
    mov  dword ptr [dtX], 120
    mov  dword ptr [dtY], 300
    lea  rax, txtbuf
    mov  [dtStr], rax
    call draw_text

    mov  rax, [curHdc]
    mov  [dcHdc], rax
    mov  dword ptr [tmpIdx], 0
op_dloop:
    mov  eax, [tmpIdx]
    cmp  eax, [dN]
    jge  op_ddone
    mov  eax, [tmpIdx]
    imul eax, eax, 80
    add  eax, 40
    mov  [dcX], eax
    mov  dword ptr [dcY], 60
    mov  ecx, [tmpIdx]
    movsxd r8, ecx
    lea  r10, dRank
    movzx eax, byte ptr [r10 + r8]
    mov  [dcRank], eax
    lea  r10, dSuit
    movzx eax, byte ptr [r10 + r8]
    mov  [dcSuit], eax
    mov  dword ptr [dcFace], 1
    cmp  dword ptr [revealed], 1
    je   op_dface
    cmp  dword ptr [tmpIdx], 1
    jne  op_dface
    mov  dword ptr [dcFace], 0
op_dface:
    call draw_card
    inc  dword ptr [tmpIdx]
    jmp  op_dloop
op_ddone:

    mov  dword ptr [hLoop], 0
op_hloop:
    mov  eax, [hLoop]
    cmp  eax, [numHands]
    jge  op_hdone
    mov  eax, [hLoop]
    cmp  eax, 0
    jne  op_h1
    mov  dword ptr [tmpRank], 40
    jmp  op_hbase
op_h1:
    mov  dword ptr [tmpRank], 480
op_hbase:
    mov  dword ptr [tmpIdx], 0
op_cloop:
    mov  ecx, [hLoop]
    lea  r10, pN
    mov  eax, [tmpIdx]
    cmp  eax, [r10 + rcx*4]
    jge  op_cdone
    mov  eax, [tmpIdx]
    imul eax, eax, 80
    add  eax, [tmpRank]
    mov  [dcX], eax
    mov  dword ptr [dcY], 340
    mov  eax, [hLoop]
    imul eax, eax, 12
    add  eax, [tmpIdx]
    movsxd r8, eax
    lea  r10, pRank
    movzx eax, byte ptr [r10 + r8]
    mov  [dcRank], eax
    lea  r10, pSuit
    movzx eax, byte ptr [r10 + r8]
    mov  [dcSuit], eax
    mov  dword ptr [dcFace], 1
    call draw_card
    inc  dword ptr [tmpIdx]
    jmp  op_cloop
op_cdone:
    inc  dword ptr [hLoop]
    jmp  op_hloop
op_hdone:
    mov  rsp, rbp
    pop  rbp
    ret
on_paint endp

create_children proc
    push rbp
    mov  rbp, rsp
    sub  rsp, 160
    and  rsp, -16

    mov  rcx, WS_EX_CLIENTEDGE
    lea  rdx, editClass
    lea  r8,  defBet
    mov  r9d, WS_CHILD
    or   r9d, WS_VISIBLE
    or   r9d, ES_NUMBER
    or   r9d, ES_CENTER
    mov  dword ptr [rsp+32], 560
    mov  dword ptr [rsp+40], 60
    mov  dword ptr [rsp+48], 120
    mov  dword ptr [rsp+56], 30
    mov  rax, [creatingHwnd]
    mov  [rsp+64], rax
    mov  qword ptr [rsp+72], 0
    mov  rax, [hInst]
    mov  [rsp+80], rax
    mov  qword ptr [rsp+88], 0
    call CreateWindowExA
    mov  [hEdit], rax

    mov  rcx, 0
    lea  rdx, btnClass
    lea  r8,  lDeal
    mov  r9d, WS_CHILD
    or   r9d, WS_VISIBLE
    or   r9d, BS_DEFPUSHBUTTON
    or   r9d, WS_TABSTOP
    mov  dword ptr [rsp+32], 690
    mov  dword ptr [rsp+40], 60
    mov  dword ptr [rsp+48], 110
    mov  dword ptr [rsp+56], 30
    mov  rax, [creatingHwnd]
    mov  [rsp+64], rax
    mov  qword ptr [rsp+72], ID_DEAL
    mov  rax, [hInst]
    mov  [rsp+80], rax
    mov  qword ptr [rsp+88], 0
    call CreateWindowExA
    mov  [hDeal], rax

    mov  rcx, 0
    lea  rdx, btnClass
    lea  r8,  lHit
    mov  r9d, WS_CHILD
    or   r9d, WS_VISIBLE
    or   r9d, WS_TABSTOP
    mov  dword ptr [rsp+32], 40
    mov  dword ptr [rsp+40], 470
    mov  dword ptr [rsp+48], 150
    mov  dword ptr [rsp+56], 34
    mov  rax, [creatingHwnd]
    mov  [rsp+64], rax
    mov  qword ptr [rsp+72], ID_HIT
    mov  rax, [hInst]
    mov  [rsp+80], rax
    mov  qword ptr [rsp+88], 0
    call CreateWindowExA
    mov  [hHit], rax

    mov  rcx, 0
    lea  rdx, btnClass
    lea  r8,  lStand
    mov  r9d, WS_CHILD
    or   r9d, WS_VISIBLE
    or   r9d, WS_TABSTOP
    mov  dword ptr [rsp+32], 200
    mov  dword ptr [rsp+40], 470
    mov  dword ptr [rsp+48], 150
    mov  dword ptr [rsp+56], 34
    mov  rax, [creatingHwnd]
    mov  [rsp+64], rax
    mov  qword ptr [rsp+72], ID_STAND
    mov  rax, [hInst]
    mov  [rsp+80], rax
    mov  qword ptr [rsp+88], 0
    call CreateWindowExA
    mov  [hStand], rax

    mov  rcx, 0
    lea  rdx, btnClass
    lea  r8,  lSplit
    mov  r9d, WS_CHILD
    or   r9d, WS_VISIBLE
    or   r9d, WS_TABSTOP
    mov  dword ptr [rsp+32], 360
    mov  dword ptr [rsp+40], 470
    mov  dword ptr [rsp+48], 170
    mov  dword ptr [rsp+56], 34
    mov  rax, [creatingHwnd]
    mov  [rsp+64], rax
    mov  qword ptr [rsp+72], ID_SPLIT
    mov  rax, [hInst]
    mov  [rsp+80], rax
    mov  qword ptr [rsp+88], 0
    call CreateWindowExA
    mov  [hSplit], rax

    mov  rcx, 0
    lea  rdx, btnClass
    lea  r8,  lDouble
    mov  r9d, WS_CHILD
    or   r9d, WS_VISIBLE
    or   r9d, WS_TABSTOP
    mov  dword ptr [rsp+32], 540
    mov  dword ptr [rsp+40], 470
    mov  dword ptr [rsp+48], 300
    mov  dword ptr [rsp+56], 34
    mov  rax, [creatingHwnd]
    mov  [rsp+64], rax
    mov  qword ptr [rsp+72], ID_DOUBLE
    mov  rax, [hInst]
    mov  [rsp+80], rax
    mov  qword ptr [rsp+88], 0
    call CreateWindowExA
    mov  [hDouble], rax

    mov  ecx, 0
    call set_actions
    mov  rsp, rbp
    pop  rbp
    ret
create_children endp

make_fonts proc
    push rbp
    mov  rbp, rsp
    sub  rsp, 160
    and  rsp, -16
    mov  rcx, 30
    xor  rdx, rdx
    xor  r8, r8
    xor  r9, r9
    mov  qword ptr [rsp+32], 700
    mov  qword ptr [rsp+40], 0
    mov  qword ptr [rsp+48], 0
    mov  qword ptr [rsp+56], 0
    mov  qword ptr [rsp+64], 0
    mov  qword ptr [rsp+72], 0
    mov  qword ptr [rsp+80], 0
    mov  qword ptr [rsp+88], 0
    mov  qword ptr [rsp+96], 0
    lea  rax, fontFace
    mov  [rsp+104], rax
    call CreateFontA
    mov  [hFontBig], rax
    mov  rcx, 22
    xor  rdx, rdx
    xor  r8, r8
    xor  r9, r9
    mov  qword ptr [rsp+32], 600
    mov  qword ptr [rsp+40], 0
    mov  qword ptr [rsp+48], 0
    mov  qword ptr [rsp+56], 0
    mov  qword ptr [rsp+64], 0
    mov  qword ptr [rsp+72], 0
    mov  qword ptr [rsp+80], 0
    mov  qword ptr [rsp+88], 0
    mov  qword ptr [rsp+96], 0
    lea  rax, fontFace
    mov  [rsp+104], rax
    call CreateFontA
    mov  [hFontMed], rax
    mov  rsp, rbp
    pop  rbp
    ret
make_fonts endp

WndProc proc
    push rbp
    mov  rbp, rsp
    sub  rsp, 256
    and  rsp, -16
    mov  [rbp-8], rcx
    mov  [rbp-16], rdx
    mov  [rbp-24], r8
    mov  [rbp-32], r9

    mov  eax, edx
    cmp  eax, WM_CREATE
    je   wp_create
    cmp  eax, WM_COMMAND
    je   wp_command
    cmp  eax, WM_PAINT
    je   wp_paint
    cmp  eax, WM_DESTROY
    je   wp_destroy
    jmp  wp_def

wp_create:
    mov  rax, [rbp-8]
    mov  [creatingHwnd], rax
    call create_children
    jmp  wp_zero

wp_command:
    mov  r8, [rbp-24]
    movzx eax, r8w
    cmp  eax, ID_HIT
    je   wp_hit
    cmp  eax, ID_STAND
    je   wp_stand
    cmp  eax, ID_SPLIT
    je   wp_split
    cmp  eax, ID_DOUBLE
    je   wp_double
    cmp  eax, ID_DEAL
    je   wp_deal
    jmp  wp_def
wp_hit:
    call do_hit
    jmp  wp_zero
wp_stand:
    call do_stand
    jmp  wp_zero
wp_split:
    call do_split
    jmp  wp_zero
wp_double:
    call do_double
    jmp  wp_zero
wp_deal:
    call do_deal
    jmp  wp_zero

wp_paint:
    mov  rcx, [rbp-8]
    lea  rdx, ps
    call BeginPaint
    mov  rcx, rax
    call on_paint
    mov  rcx, [rbp-8]
    lea  rdx, ps
    call EndPaint
    jmp  wp_zero

wp_destroy:
    xor  rcx, rcx
    call PostQuitMessage
    jmp  wp_zero

wp_def:
    mov  rcx, [rbp-8]
    mov  rdx, [rbp-16]
    mov  r8,  [rbp-24]
    mov  r9,  [rbp-32]
    call DefWindowProcA
    jmp  wp_ret
wp_zero:
    xor  rax, rax
wp_ret:
    mov  rsp, rbp
    pop  rbp
    ret
WndProc endp

main proc
    push rbp
    mov  rbp, rsp
    sub  rsp, 160
    and  rsp, -16

    xor  rcx, rcx
    call time
    mov  rcx, rax
    call srand

    xor  rcx, rcx
    call GetModuleHandleA
    mov  [hInst], rax

    mov  ecx, C_FELT
    call CreateSolidBrush
    mov  [hFeltBr], rax
    mov  ecx, C_WHITE
    call CreateSolidBrush
    mov  [hWhiteBr], rax
    mov  ecx, C_BLUE
    call CreateSolidBrush
    mov  [hBlueBr], rax
    call make_fonts

    xor  rcx, rcx
    mov  rdx, IDC_ARROW
    call LoadCursorA
    mov  [rbp-8], rax

    mov  dword ptr [wc+0], 80
    mov  eax, CS_HREDRAW
    or   eax, CS_VREDRAW
    mov  dword ptr [wc+4], eax
    lea  rax, WndProc
    mov  qword ptr [wc+8], rax
    mov  dword ptr [wc+16], 0
    mov  dword ptr [wc+20], 0
    mov  rax, [hInst]
    mov  qword ptr [wc+24], rax
    mov  qword ptr [wc+32], 0
    mov  rax, [rbp-8]
    mov  qword ptr [wc+40], rax
    mov  rax, [hFeltBr]
    mov  qword ptr [wc+48], rax
    mov  qword ptr [wc+56], 0
    lea  rax, clsName
    mov  qword ptr [wc+64], rax
    mov  qword ptr [wc+72], 0

    lea  rcx, wc
    call RegisterClassExA

    mov  rcx, 0
    lea  rdx, clsName
    lea  r8,  winTitle
    mov  r9d, WS_OVERLAPPEDWINDOW
    or   r9d, WS_VISIBLE
    mov  dword ptr [rsp+32], CW_USEDEFAULT
    mov  dword ptr [rsp+40], CW_USEDEFAULT
    mov  dword ptr [rsp+48], 880
    mov  dword ptr [rsp+56], 620
    mov  qword ptr [rsp+64], 0
    mov  qword ptr [rsp+72], 0
    mov  rax, [hInst]
    mov  [rsp+80], rax
    mov  qword ptr [rsp+88], 0
    call CreateWindowExA
    mov  [hWndMain], rax

    mov  rcx, rax
    mov  edx, SW_SHOWNORMAL
    call ShowWindow
    mov  rcx, [hWndMain]
    call UpdateWindow

    lea  rax, mDealHint
    mov  [curMsg], rax

mloop:
    lea  rcx, msgbuf
    xor  rdx, rdx
    xor  r8, r8
    xor  r9, r9
    call GetMessageA
    test eax, eax
    jle  mdone
    lea  rcx, msgbuf
    call TranslateMessage
    lea  rcx, msgbuf
    call DispatchMessageA
    jmp  mloop
mdone:
    xor  eax, eax
    mov  rsp, rbp
    pop  rbp
    ret
main endp

end
