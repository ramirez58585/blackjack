
option casemap:none

extern printf:proc
extern scanf:proc
extern rand:proc
extern srand:proc
extern time:proc

PROLOG macro
    push rbp
    mov  rbp, rsp
    sub  rsp, 64
    and  rsp, -16
endm
EPILOG macro
    mov  rsp, rbp
    pop  rbp
endm

.data

balance   dd 1000
bet       dd 0
numHands  dd 1
curIdx    dd 0
tmpIdx    dd 0
tmpRank   dd 0
choice    dd 0
again     dd 0

pTotal    dd 0,0
pAces     dd 0,0
pBet      dd 0,0
pNum      dd 0,0
pR1       dd 0,0
pR2       dd 0,0
pBust     dd 0,0

dTotal    dd 0
dAces     dd 0
dNum      dd 0
dShow     dd 0

s1  db "A",0
s2  db "2",0
s3  db "3",0
s4  db "4",0
s5  db "5",0
s6  db "6",0
s7  db "7",0
s8  db "8",0
s9  db "9",0
s10 db "10",0
s11 db "J",0
s12 db "Q",0
s13 db "K",0
rankTbl qword 0, s1,s2,s3,s4,s5,s6,s7,s8,s9,s10,s11,s12,s13

fmtCard   db "[%s] ",0
fmtNL     db 10,0
fmtD      db "%d",0

mTitle    db 10,"===================================",10
          db "         B L A C K J A C K",10
          db "===================================",10,0
mBal      db 10,"Balance: %d vbucks",10,0
mAskBet   db "Place your bet (vbucks): ",0
mBadBet   db "Invalid bet. Try again.",10,0
mBroke    db 10,"You're out of vbucks. Game over.",10,0

mDeal     db 10,"-- Dealing --",10,0
mYour     db "Your hand:   ",0
mDealer   db "Dealer shows: ",0
mHoleHid  db "[?] ",0
mTotP     db "   (total %d)",10,0
mDealTot  db "   (dealer total %d)",10,0

mMenu0    db 10,"What's your move?",10,0
mMenu1    db "  1) hit that bitch",10,0
mMenu2    db "  2) no im a pussy",10,0
mMenu3    db "  3) split it brochacho",10,0
mMenu4    db "  4) MY WIFE IS GOING TO DIVORCE ME",10,0
mPrompt   db "> ",0

mBust     db "   *** BUST ***",10,0
mNoSplit  db "   Can't split that.",10,0
mNoFunds  db "   Not enough vbucks for that.",10,0
mSplit    db 10,"-- Split! Playing two hands --",10,0
mDouble   db 10,"-- Doubling down. May god have mercy. --",10,0
mHandN    db 10,"[ Hand %d ]",10,0

mDealerP  db 10,"-- Dealer plays --",10,0
mPlayerBJ db 10,"BLACKJACK! Natural 21!",10,0

mWin      db "   You WIN %d vbucks!",10,0
mLose     db "   You lose.",10,0
mPush     db "   Push. Stake returned.",10,0
mDBust    db "   Dealer busts!",10,0

mAgain    db 10,"Play again? (1 = yes, 0 = cash out): ",0
mBye      db 10,"You cash out with %d vbucks. GG.",10,0

.code

rank_value proc
    mov eax, ecx
    cmp eax, 10
    jle rv_done
    mov eax, 10
rv_done:
    ret
rank_value endp

draw_rank proc
    PROLOG
    call rand
    xor  edx, edx
    mov  ecx, 13
    div  ecx
    mov  eax, edx
    inc  eax
    EPILOG
    ret
draw_rank endp

print_card proc
    PROLOG
    movsxd rax, ecx
    lea  r10, rankTbl
    mov  rdx, [r10 + rax*8]
    lea  rcx, fmtCard
    call printf
    EPILOG
    ret
print_card endp

player_add proc
    PROLOG
    mov  [tmpIdx], ecx
    call draw_rank
    mov  [tmpRank], eax
    mov  ecx, eax
    call print_card
    mov  ecx, [tmpRank]
    call rank_value
    mov  ecx, [tmpIdx]
    mov  edx, [tmpRank]
    cmp  edx, 1
    jne  pa_nace
    mov  eax, 11
    lea  r11, pAces
    inc  dword ptr [r11 + rcx*4]
pa_nace:
    lea  r10, pTotal
    add  dword ptr [r10 + rcx*4], eax
pa_adj:
    mov  eax, [r10 + rcx*4]
    cmp  eax, 21
    jle  pa_adjdone
    lea  r11, pAces
    cmp  dword ptr [r11 + rcx*4], 0
    je   pa_adjdone
    sub  dword ptr [r10 + rcx*4], 10
    dec  dword ptr [r11 + rcx*4]
    jmp  pa_adj
pa_adjdone:

    lea  r11, pNum
    mov  edx, [r11 + rcx*4]
    cmp  edx, 0
    jne  pa_second
    lea  r9, pR1
    mov  eax, [tmpRank]
    mov  [r9 + rcx*4], eax
    jmp  pa_count
pa_second:
    cmp  edx, 1
    jne  pa_count
    lea  r9, pR2
    mov  eax, [tmpRank]
    mov  [r9 + rcx*4], eax
pa_count:
    inc  dword ptr [r11 + rcx*4]
    EPILOG
    ret
player_add endp

set_single proc
    push rbx
    mov  ebx, ecx

    mov  eax, edx
    cmp  eax, 10
    jle  ss_v
    mov  eax, 10
ss_v:
    cmp  edx, 1
    jne  ss_nace
    mov  eax, 11
    lea  r11, pAces
    mov  dword ptr [r11 + rbx*4], 1
    jmp  ss_store
ss_nace:
    lea  r11, pAces
    mov  dword ptr [r11 + rbx*4], 0
ss_store:
    lea  r10, pTotal
    mov  [r10 + rbx*4], eax
    lea  r10, pNum
    mov  dword ptr [r10 + rbx*4], 1
    lea  r10, pR1
    mov  [r10 + rbx*4], edx
    lea  r10, pR2
    mov  dword ptr [r10 + rbx*4], 0
    lea  r10, pBust
    mov  dword ptr [r10 + rbx*4], 0
    pop  rbx
    ret
set_single endp

dealer_draw proc
    PROLOG
    call draw_rank
    mov  [tmpRank], eax
    mov  ecx, eax
    call rank_value
    mov  edx, [tmpRank]
    cmp  edx, 1
    jne  dd_nace
    mov  eax, 11
    inc  dword ptr [dAces]
dd_nace:
    add  dword ptr [dTotal], eax
dd_adj:
    mov  eax, [dTotal]
    cmp  eax, 21
    jle  dd_done
    cmp  dword ptr [dAces], 0
    je   dd_done
    sub  dword ptr [dTotal], 10
    dec  dword ptr [dAces]
    jmp  dd_adj
dd_done:
    inc  dword ptr [dNum]
    cmp  dword ptr [dShow], 0
    je   dd_ret
    mov  ecx, [tmpRank]
    call print_card
dd_ret:
    EPILOG
    ret
dealer_draw endp

play_hand proc
    PROLOG
    mov  [curIdx], ecx
ph_loop:

    mov  ecx, [curIdx]
    lea  r10, pTotal
    mov  eax, [r10 + rcx*4]
    cmp  eax, 21
    jle  ph_show
    lea  r10, pBust
    mov  dword ptr [r10 + rcx*4], 1
    lea  rcx, mBust
    call printf
    jmp  ph_ret
ph_show:

    mov  ecx, [curIdx]
    lea  r10, pTotal
    mov  edx, [r10 + rcx*4]
    lea  rcx, mTotP
    call printf

    lea  rcx, mMenu0
    call printf
    lea  rcx, mMenu1
    call printf
    lea  rcx, mMenu2
    call printf
    lea  rcx, mMenu3
    call printf
    lea  rcx, mMenu4
    call printf
    lea  rcx, mPrompt
    call printf
    lea  rcx, fmtD
    lea  rdx, choice
    call scanf
    cmp  eax, 1
    jne  ph_stand

    mov  eax, [choice]
    cmp  eax, 1
    je   ph_hit
    cmp  eax, 2
    je   ph_stand
    cmp  eax, 3
    je   ph_split
    cmp  eax, 4
    je   ph_double
    jmp  ph_loop

ph_hit:
    lea  rcx, mYour
    call printf
    mov  ecx, [curIdx]
    call player_add
    lea  rcx, fmtNL
    call printf
    jmp  ph_loop

ph_stand:
    jmp  ph_ret

ph_split:

    mov  ecx, [curIdx]
    lea  r10, pNum
    cmp  dword ptr [r10 + rcx*4], 2
    jne  ph_nosplit
    cmp  dword ptr [numHands], 1
    jne  ph_nosplit
    lea  r10, pR1
    mov  eax, [r10 + rcx*4]
    lea  r10, pR2
    cmp  eax, [r10 + rcx*4]
    jne  ph_nosplit
    mov  eax, [bet]
    cmp  [balance], eax
    jl   ph_nofunds

    sub  [balance], eax
    lea  r10, pBet
    mov  [r10 + 4], eax
    mov  edx, [r10 + 0]

    lea  r10, pR2
    mov  edx, [r10 + 0]
    mov  ecx, 1
    call set_single

    lea  r10, pR1
    mov  edx, [r10 + 0]
    mov  ecx, 0
    call set_single
    mov  dword ptr [numHands], 2
    lea  rcx, mSplit
    call printf

    lea  rcx, mYour
    call printf
    mov  ecx, 0
    call player_add
    lea  rcx, fmtNL
    call printf
    lea  rcx, mYour
    call printf
    mov  ecx, 1
    call player_add
    lea  rcx, fmtNL
    call printf
    jmp  ph_loop
ph_nosplit:
    lea  rcx, mNoSplit
    call printf
    jmp  ph_loop
ph_nofunds:
    lea  rcx, mNoFunds
    call printf
    jmp  ph_loop

ph_double:

    mov  ecx, [curIdx]
    lea  r10, pNum
    cmp  dword ptr [r10 + rcx*4], 2
    jne  ph_nodouble
    mov  eax, [bet]
    cmp  [balance], eax
    jl   ph_nodouble
    sub  [balance], eax
    mov  ecx, [curIdx]
    lea  r10, pBet
    add  [r10 + rcx*4], eax
    lea  rcx, mDouble
    call printf
    lea  rcx, mYour
    call printf
    mov  ecx, [curIdx]
    call player_add
    lea  rcx, fmtNL
    call printf

    mov  ecx, [curIdx]
    lea  r10, pTotal
    mov  eax, [r10 + rcx*4]
    cmp  eax, 21
    jle  ph_ret
    lea  r10, pBust
    mov  dword ptr [r10 + rcx*4], 1
    lea  rcx, mBust
    call printf
    jmp  ph_ret
ph_nodouble:
    lea  rcx, mNoFunds
    call printf
    jmp  ph_loop

ph_ret:
    EPILOG
    ret
play_hand endp

settle proc
    PROLOG
    mov  [curIdx], ecx
    mov  ecx, [curIdx]
    lea  r10, pBust
    cmp  dword ptr [r10 + rcx*4], 1
    je   st_lose

    cmp  dword ptr [dTotal], 21
    jg   st_win

    mov  ecx, [curIdx]
    lea  r10, pTotal
    mov  eax, [r10 + rcx*4]
    cmp  eax, [dTotal]
    jg   st_win
    je   st_push
    jmp  st_lose
st_win:
    cmp  dword ptr [dTotal], 21
    jle  st_win_pay
    lea  rcx, mDBust
    call printf
st_win_pay:
    mov  ecx, [curIdx]
    lea  r10, pBet
    mov  eax, [r10 + rcx*4]
    add  eax, eax
    add  [balance], eax
    mov  ecx, [curIdx]
    lea  r10, pBet
    mov  edx, [r10 + rcx*4]
    lea  rcx, mWin
    call printf
    jmp  st_ret
st_push:
    mov  ecx, [curIdx]
    lea  r10, pBet
    mov  eax, [r10 + rcx*4]
    add  [balance], eax
    lea  rcx, mPush
    call printf
    jmp  st_ret
st_lose:
    lea  rcx, mLose
    call printf
st_ret:
    EPILOG
    ret
settle endp

main proc
    PROLOG

    xor  rcx, rcx
    call time
    mov  rcx, rax
    call srand

    lea  rcx, mTitle
    call printf

game_loop:

    cmp  dword ptr [balance], 1
    jge  gl_havecash
    lea  rcx, mBroke
    call printf
    jmp  gl_end
gl_havecash:
    lea  rcx, mBal
    mov  edx, [balance]
    call printf

ask_bet:
    lea  rcx, mAskBet
    call printf
    lea  rcx, fmtD
    lea  rdx, bet
    call scanf
    cmp  eax, 1
    jne  gl_end
    mov  eax, [bet]
    cmp  eax, 1
    jl   bad_bet
    cmp  eax, [balance]
    jle  bet_ok
bad_bet:
    lea  rcx, mBadBet
    call printf
    jmp  ask_bet
bet_ok:
    mov  eax, [bet]
    sub  [balance], eax

    mov  dword ptr [numHands], 1
    xor  eax, eax
    mov  dword ptr [pTotal+0], eax
    mov  dword ptr [pTotal+4], eax
    mov  dword ptr [pAces+0], eax
    mov  dword ptr [pAces+4], eax
    mov  dword ptr [pNum+0], eax
    mov  dword ptr [pNum+4], eax
    mov  dword ptr [pR1+0], eax
    mov  dword ptr [pR1+4], eax
    mov  dword ptr [pR2+0], eax
    mov  dword ptr [pR2+4], eax
    mov  dword ptr [pBust+0], eax
    mov  dword ptr [pBust+4], eax
    mov  dword ptr [dTotal], eax
    mov  dword ptr [dAces], eax
    mov  dword ptr [dNum], eax
    mov  ecx, [bet]
    mov  dword ptr [pBet+0], ecx
    mov  dword ptr [pBet+4], eax

    lea  rcx, mDeal
    call printf

    lea  rcx, mYour
    call printf
    mov  ecx, 0
    call player_add
    mov  ecx, 0
    call player_add
    lea  rcx, mTotP
    mov  edx, [pTotal+0]
    call printf

    lea  rcx, mDealer
    call printf
    mov  dword ptr [dShow], 1
    call dealer_draw
    mov  dword ptr [dShow], 0
    call dealer_draw
    lea  rcx, mHoleHid
    call printf
    lea  rcx, fmtNL
    call printf

    cmp  dword ptr [pNum+0], 2
    jne  no_natural
    cmp  dword ptr [pTotal+0], 21
    jne  no_natural
    lea  rcx, mPlayerBJ
    call printf

    cmp  dword ptr [dTotal], 21
    jne  bj_pay

    mov  eax, [bet]
    add  [balance], eax
    lea  rcx, mPush
    call printf
    jmp  round_done
bj_pay:

    mov  eax, [bet]
    add  [balance], eax
    mov  eax, [bet]
    imul eax, eax, 3
    cdq
    mov  ecx, 2
    idiv ecx
    add  [balance], eax
    mov  edx, eax
    lea  rcx, mWin
    call printf
    jmp  round_done

no_natural:

    mov  dword ptr [curIdx], 0
hand_loop:
    mov  eax, [curIdx]
    cmp  eax, [numHands]
    jge  dealer_phase

    cmp  dword ptr [numHands], 1
    je   ph_no_header
    lea  rcx, mHandN
    mov  edx, [curIdx]
    inc  edx
    call printf
ph_no_header:
    mov  ecx, [curIdx]
    call play_hand
    inc  dword ptr [curIdx]
    jmp  hand_loop

dealer_phase:

    mov  eax, [pBust+0]
    cmp  eax, 1
    jne  dealer_plays
    mov  eax, [numHands]
    cmp  eax, 2
    jne  skip_dealer
    cmp  dword ptr [pBust+4], 1
    je   skip_dealer
dealer_plays:
    lea  rcx, mDealerP
    call printf
    mov  dword ptr [dShow], 1

    lea  rcx, mDealer
    call printf

dp_loop:
    cmp  dword ptr [dTotal], 17
    jge  dp_show
    call dealer_draw
    jmp  dp_loop
dp_show:
    lea  rcx, mDealTot
    mov  edx, [dTotal]
    call printf
skip_dealer:

    mov  dword ptr [curIdx], 0
settle_loop:
    mov  eax, [curIdx]
    cmp  eax, [numHands]
    jge  round_done
    cmp  dword ptr [numHands], 1
    je   st_no_header
    lea  rcx, mHandN
    mov  edx, [curIdx]
    inc  edx
    call printf
st_no_header:
    mov  ecx, [curIdx]
    call settle
    inc  dword ptr [curIdx]
    jmp  settle_loop

round_done:
    lea  rcx, mBal
    mov  edx, [balance]
    call printf
    lea  rcx, mAgain
    call printf
    lea  rcx, fmtD
    lea  rdx, again
    call scanf
    cmp  dword ptr [again], 1
    je   game_loop

gl_end:
    lea  rcx, mBye
    mov  edx, [balance]
    call printf
    xor  eax, eax
    EPILOG
    ret
main endp

end
