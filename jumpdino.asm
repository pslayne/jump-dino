######################################################################
#      	              Layne, Gabi e Rigoberto                        #
######################################################################
#	Esse programa precisa que o Keyboard and Display MMIO        #
#       e o Bitmap Display estejam conectados ao MIPS.               #
#								     #
#       Configurações do Bitmap Display:                             #
#	Unit Width: 8						     #
#	Unit Height: 8						     #
#	Display Width: 512					     #
#	Display Height: 256					     #
#	Base Address for Display: 0x10008000 ($gp)	             #
#	                                                             #
#                                                                    #
#                                                                    #
#       use a tecla W para pular                                     #       
######################################################################

.data

#cores
fundo: .word 0xFFE4E1
dino: .word 0x8B0000
cacto: .word 0xFFC125

keyPress: .word 0xFFFF0004
zero: .word 0x00000000

msg: .asciiz "que pena, você perdeu... sua pontuação foi: "
msgr: .asciiz "deseja recomeçar? 1 para sim e 2 para não"

#endereço
screenStart: .word 0x10008000 #a tela começa em $gp

.macro Fim
#finaliza o programa
	la $a0, msg
	li $v0, 4
	syscall
	move $a0, $t9
	li $v0, 1
	syscall
        li $v0, 10
        syscall
.end_macro

.macro Sleep
#espera
	li $a0, 50							
	li $v0, 32						
	syscall
.end_macro

.macro SleepShorter
#espera um pouco menos
	li $a0, 1							
	li $v0, 32					
	syscall
.end_macro

.macro SleepLonger
#espera um pouco mais
	li $a0, 500
	li $v0, 32
	syscall
.end_macro

.macro SleepLongest
#espera um pouco mais
	li $a0, 2500
	li $v0, 32
	syscall
.end_macro

.macro desenha
#desenha o cenário
	li $t0, 256
	li $t1, 0
	lw $t3, screenStart #t3 recebe o endereço inicial da tela
	lw $t4, fundo #t2 recebe a cor do fundo
	
	desenhaLinha:
		sw $t4, ($t3) #faz o store da cor de fundo em t3
		addi $t3, $t3, 4 #incrementa o endereço 
		addi $t1, $t1, 4 #incrementa o contador
		blt $t1, $t0, desenhaLinha
		b proxLinha
	
	desenhaChao:
		lw $t4, cacto
		
		desenhaChaoLinha:
			sw $t4, ($t3) #faz o store da cor do cacto em t3
			addi $t3, $t3, 4 #incrementa o endereço
			addi $t1, $t1, 4 #incrementa o contador para saber quando trocar de linha
			blt $t1, $t0, desenhaChaoLinha
			lw $t4, fundo
			b proxLinha
			
	proxLinha:
		addi $t0, $t0, 256
		beq $t0, 6656, desenhaChao
		ble $t0, 8192, desenhaLinha
		
.end_macro

.macro finaliza
#pinta todos o cenário da cor do cacto quando o jogador perde
	li $t0, 256
	li $t1, 0
	lw $t3, screenStart #t3 recebe o endereço de início da tela
	lw $t4, cacto #t2 recebe a cor do cacto
	
	desenhaLinha:
		sw $t4, ($t3) #faz o store da cor para o endereço em t3
		addi $t3, $t3, 4 #incrementa o endereço
		addi $t1, $t1, 4 #incrementa o contador
		SleepShorter
		blt $t1, $t0, desenhaLinha
		b proxLinha
	
	desenhaChao:
		lw $t4, cacto
		
		desenhaChaoLinha:
			sw $t4, ($t3) #faz o store da cor para o endereço em t3
			addi $t3, $t3, 4 #incrementa o endereço 
			addi $t1, $t1, 4 #incrementa o contador para saber quando mudar de linha
			blt $t1, $t0, desenhaChaoLinha
			lw $t4, cacto
			b proxLinha
			
	proxLinha:
		addi $t0, $t0, 256
		beq $t0, 6656, desenhaChao
		ble $t0, 8192, desenhaLinha
.end_macro 



.macro dinoUp
	add $a2, $s6, $zero
	subi $s6, $s6, 256
	jal apagaDino #apaga o dinossauro
	jal desenhaDino #desenha o dinossauro
.end_macro 

.macro dinoDown
	add $a2, $s6, $zero
	addi $s6, $s6, 256
	jal apagaDino #apaga o dinossauro
	jal desenhaDino #desenha o dinossauro
.end_macro 

.macro checarColisao
#a colisão acontece se o bit que vai ser desenhado tem a cor do dinossauro
lw $t0, ($s3)
bne $t0, 0x8B0000, score

addi $v1, $v1, -1

beq $v1, 0, gameOver
bne $v1, 0, menosVida

score: addi $t9, $t9, 100	
.end_macro

.macro cactus1Left
	#movo o cacto pra esquerda
	jal apagaCacto1
	sub $a3, $a3, 4
	jal desenhaCacto1
	
	#para de desenhar quando chega ao fim da tela
	addi $s1, $s1, 1
	beq $s1, 62, novoCacto
	
	Sleep
.end_macro 

.text
reset:

li $t9, 0 #salva a pontuação
li $v1, 3 #salva as vidas

menosVida:
desenha
li $a1, 0xFFFF0004 #salva o local da entrada do teclado em a1

jal inicioDino
jal inicioCacto1

syscall

displayLoop:
	lw $t7, ($a1) #carrega a entrada pra t7

	beq $t7, 0x00000077, jumpingDisplayLoop #pula se a entrada for um W
	cactus1Left

	
	j displayLoop
	
inicioDino:
	#inicializa a posição do dinossauro
	li $s7, 48 
	li $s6, 24

	li $s5, 256
	multu $s6,$s5
	mflo $s6
	add $s6, $s6, $s7
	j desenhaDino
	
desenhaDino:
	li $t1, 0 #reseta o contador horizontal
	li $t0, 0 #reseta o contador vertical
	
	li $t4, 3 #largura máxima do corpo
	li $t7, 3 #altura máxima do corpo
	li $t6, 6 #altura máxima da cabeça
	li $t5, 12 
	
	lw $s4, screenStart #s4 recebe o início da tela
	add $s4, $s4, $s6 #adiciona a pos inicial do dino À posição inicial da tela
	lw $s2, dino #faz o store da cor do dinossauro
	add $s3, $s4, $zero
	
	desenhaCorpoHor:
		sw $s2, ($s3)
		addi $s3, $s3, 4
		addi $t1, $t1, 1
		blt $t1, $t4, desenhaCorpoHor
		
	desenhaCorpoVer:
		
		sub $s3, $s3, $t5
		subi $s3, $s3, 256
		li $t1, 0 # reset the horizontal counter
		addi $t0, $t0, 1
		blt $t0, $t7, desenhaCorpoHor
		
		li $t4, 5 # maximum head width
		li $t5, 20 # how much to move back for each level with head
		blt $t0, $t6, desenhaCorpoHor
		j desenhaCauda
		
	desenhaCauda:
		add $s3, $s4, $zero
		subi $s3, $s3, 12
		subi $s3, $s3, 248
		
		sw $s2, ($s3)
		
		add $s3, $s4, $zero
		subi $s3, $s3, 12
		subi $s3, $s3, 508
		sw $s2, ($s3)
		jr $ra

apagaDino:
	li $t1, 0 #reseta o contador horizontal
	li $t0, 0 #reseta o contador vertical
	
	li $t4, 3 #largura máxima do corpo
	li $t7, 3 #altura máxima do corpo
	li $t6, 6 #altura máxima da cabeça
	li $t5, 12
	
	lw $s4, screenStart #s4 recebe o endereço inicial da tela
	add $s4, $s4, $a2 #adiciona a posição inicail do dino à posição inicial da tela
	lw $s2, fundo #store da cor do dino
	add $s3, $s4, $zero
	
	apagaCorpoHor:
		sw $s2, ($s3)
		addi $s3, $s3, 4
		addi $t1, $t1, 1
		blt $t1, $t4, apagaCorpoHor
		
	apagaCorpoVer:
		
		sub $s3, $s3, $t5
		subi $s3, $s3, 256
		li $t1, 0 # reset the horizontal counter
		addi $t0, $t0, 1
		blt $t0, $t7, apagaCorpoHor
		
		li $t4, 5 # maximum head width
		li $t5, 20 # how much to move back for each level with head
		blt $t0, $t6, apagaCorpoHor
		j apagaCauda
		
	apagaCauda:
		add $s3, $s4, $zero
		subi $s3, $s3, 12
		subi $s3, $s3, 248
		
		sw $s2, ($s3)
		
		add $s3, $s4, $zero
		subi $s3, $s3, 12
		subi $s3, $s3, 508
		sw $s2, ($s3)
		jr $ra
		
#desenha cacto 1
inicioCacto1:
	#inicializa a posição do cacto
	li $s7, 236
	li $a3, 24 

	li $s5, 256
	multu $a3,$s5
	mflo $a3
	add $a3, $a3, $s7 
	j displayLoop
		
desenhaCacto1:
	li $t1, 0 #reseta o contador horizontal
	li $t2, 0 #reseta o contador vertical
	
	li $t4, 3 #largura do cacto
	li $t7, 5 #altura do cacto
	li $t5, 12
	
	lw $s4, screenStart #posição inicial da tela
	add $s4, $s4, $a3 
	lw $s2, cacto #faz store da cor num registrador
	add $s3, $s4, $zero
	
	desenhaCacto1Hor:
		checarColisao
		
		sw $s2, ($s3)
		addi $s3, $s3, 4
		addi $t1, $t1, 1
		blt $t1, $t4, desenhaCacto1Hor
		
	desenhaCacto1Ver:
		
		sub $s3, $s3, $t5
		subi $s3, $s3, 256
		li $t1, 0 #reseta o contador horizontal
		addi $t2, $t2, 1
		blt $t2, $t7, desenhaCacto1Hor
	
		j desenhaCacto1Bracos
		
	desenhaCacto1Bracos:
		#desenha os braços do cacto
		add $s3, $s4, $zero 
		subi $s3, $s3,8
		subi $s3, $s3, 764
		checarColisao
		sw $s2, ($s3)
		
		add $s3, $s4, $zero
		subi $s3, $s3, 12
		subi $s3, $s3, 1020
		checarColisao
		sw $s2, ($s3)
		
		add $s3, $s4, $zero
		addi $s3, $s3, 8
		subi $s3, $s3, 508
		checarColisao
		sw $s2, ($s3)
		
		add $s3, $s4, $zero
		addi $s3, $s3, 12
		subi $s3, $s3, 764
		checarColisao
		sw $s2, ($s3)
		
		jr $ra
		
apagaCacto1:
	li $t1, 0 #reseta o contador inicial
	li $t2, 0 #reseta o contador vertical
	
	li $t4, 3 #largura do corpo
	li $t7, 5 #altura do corpo
	li $t5, 12 
	
	lw $s4, screenStart #endereço inicial da tela
	add $s4, $s4, $a3 
	lw $s2, fundo #store da cor pra um registrador
	add $s3, $s4, $zero
	
	apagaCacto1Hor:
		sw $s2, ($s3)
		addi $s3, $s3, 4
		addi $t1, $t1, 1
		blt $t1, $t4, apagaCacto1Hor
		
	apagaCacto1Ver:
		
		sub $s3, $s3, $t5
		subi $s3, $s3, 256
		li $t1, 0 #reseta o contador horizontal
		addi $t2, $t2, 1
		blt $t2, $t7, apagaCacto1Hor
	
		j apagaCacto1Braco
		
	apagaCacto1Braco:
		#apaga os braços
		add $s3, $s4, $zero 
		subi $s3, $s3,8
		subi $s3, $s3, 764
		
		sw $s2, ($s3)
		
		add $s3, $s4, $zero
		subi $s3, $s3, 12
		subi $s3, $s3, 1020
		sw $s2, ($s3)
		
		add $s3, $s4, $zero
		addi $s3, $s3, 8
		subi $s3, $s3, 508
		sw $s2, ($s3)
		
		add $s3, $s4, $zero
		addi $s3, $s3, 12
		subi $s3, $s3, 764
		sw $s2, ($s3)
		
		jr $ra

novoCacto:
	li $s1, 0 #reseta o contador pra redesenhar o cacto
	jal apagaCacto1
	jal inicioCacto1
	addi $s0, $s0, 1
	
	j displayLoop
	
jumpBack:
	jr $ra

jumpingDisplayLoop:
	lw $t0, zero #refresh da entrada do teclado
	sw $t0, ($a1)
	
	li $t8, 0 #começa o contador
	upLoop:
		dinoUp
		cactus1Left
		
		addi $t8, $t8, 1
		bne $t8, 12, upLoop
	
	li $t8, 0 #começa o contador
	downLoop:
		dinoDown
		cactus1Left
		
		addi $t8, $t8, 1
		bne $t8, 12, downLoop
	j displayLoop
	
gameOver:
	finaliza
	la $a0, msgr
	li $v0, 4
	syscall
	li $v0, 5
	syscall
	beq $v0, 1, reset
	Fim
