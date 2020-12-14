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
#       inimigo amarelo = -1 vida                                    # 
#       inimigo verde = -100 pontos                                  #
#                                                                    #
#       o ponto de colisão do personagem estará vermelho             #
#                                                                    #
#       use a tecla espaço para pular (32 em ASCII)                  #       
######################################################################

.data
	#informações
	
	#tela
	altura: .word 32
	largura: .word 64
	
	#cores
	principal: .word 0xDCDCDC #cinza
	inimigo1: .word 0xFFFF00 #amarelo
	inimigo2: .word 0x00FF00 #verde
	pontodecolisao: .word 0xFF0000 #vermelho
	cenario: .word 0xFFFAFA #branco
	fundo: .word 0x000000 #preto
	
	#pontuação
	score: .word 0
	scoreGain: .word 10
	
	#velocidade
	speed: .word 100
	
	#mensagens
	perdeu: .asciiz "Você morreu... Sua pontuação foi: "
	replay: .asciiz "Deseja jogar novamente? 1 - sim ou 2 - não"
	
	.globl main

.text	

	##################################################################
	#                   Função CoordinateToAddress                  #
	##################################################################
	CoordinateToAddress: #$a0 = x e $a1 = y 
		lw $v0, largura	#largura da tela pra $v0
		mul $v0, $v0, $a1	#multiplica por y 
		add $v0, $v0, $a0	#soma x
		mul $v0, $v0, 4		#multiplica por 4
		add $v0, $v0, $gp	#soma gp que é o endereço inicial do bit map
		jr $ra			# retorna o endereço em v0

	##################################################################
	#                         Função desenhaPixel                    #
	##################################################################	
	desenhaPixel: #$a0 = endereço para desenhar e $a1 = cor 
		sw $a1, 0($a0) 	#desenha
		jr $ra		#retorna	
		
	main: 
	
	################################################
	#    Pinta a tela de preto pra (re)iniciar     #
	################################################
	lw $a0, altura
	lw $a1, largura
	lw $a2, fundo
	mul $a3, $a0, $a1 #total number of pixels on screen
	mul $a3, $a3, 4 #align addresses
	add $a3, $a3, $gp #add base of gp
	add $a0, $gp, $zero #loop counter
	FillLoop:
		beq $a0, $a3, inicio
		sw $a2, 0($a0) #store color
		addiu $a0, $a0, 4 #increment counter
		j FillLoop
		
	################################################
	#            Inicializando variáveis           #
	################################################
	inicio: sw $zero, score
	
 	limparRegistradores:

		li $v0, 0
		li $a0, 0
		li $a1, 0
		li $a2, 0
		li $a3, 0
		li $t0, 0
		li $t1, 0
		li $t2, 0
		li $t3, 0
		li $t4, 0
		li $t5, 0
		li $t6, 0
		li $t7, 0
		li $t8, 0
		li $t9, 0
		li $s0, 0
		li $s1, 0
		li $s2, 0
		li $s3, 0
		li $s4, 0	
	################################################
	#              desenhar cenario                #
	################################################
	desenhaBorda: #e plataforma
		li $t1, 0	#coordenada Y para a borda esquerda
		loopEsquerda:
			move $a1, $t1	#move a coordena y para a1
			li $a0, 0	#direção X para a0 (não muda)
			jal CoordinateToAddress	#transforma as coordenadas em endereços
			move $a0, $v0	#coordenadas para a0
			lw $a1, cenario	#cor para a1
			jal desenhaPixel #desenha a cor na tela
			add $t1, $t1, 1	#incrementa y 
	
			bne $t1, 32, loopEsquerda #loop para desenhar toda a borda
		#se repete para a próxima borda
		li $t1, 0	
		loopDireita:
			move $a1, $t1
			li $a0, 63	#seta x para 63 (borda direita)
			jal CoordinateToAddress	
			move $a0, $v0	
			lw $a1, cenario
			jal desenhaPixel 
			add $t1, $t1, 1	
	
			bne $t1, 32, loopDireita
	
		li $t1, 0
		loopCima:
			move $a0, $t1	# move x para $a0
			li $a1, 0	# seta y para zero
			jal CoordinateToAddress	#transforma a coordenada
			move $a0, $v0	# move as coordenadas para $a0
			lw $a1, cenario	#faz store da cor para $a1
			jal desenhaPixel #desenha a cor 
			add $t1, $t1, 1 #incrementa X
	
			bne $t1, 64, loopCima #loop para desenhar toda a borda
		
		#repete para a próxima e para a plataforma
		li $t1, 0	
		loopBaixo:
			move $a0, $t1
			li $a1, 31 #seta y
			jal CoordinateToAddress	
			move $a0, $v0	
			lw $a1, cenario	
			jal desenhaPixel	
			add $t1, $t1, 1	
	
			bne $t1, 64, loopBaixo
			
		li $t1, 0	
		loopPlat:
			move $a0, $t1
			li $a1, 28 #seta y
			jal CoordinateToAddress	
			move $a0, $v0	
			lw $a1, cenario	
			jal desenhaPixel	
			add $t1, $t1, 1	
	
			bne $t1, 64, loopPlat
			
	########################################		
	#         desenhar personagem          #
	########################################		
	desenhaPersonagem: #quadrado 3x3
		li $t1, 30
		linha1: 
			move $a0, $t1 # x
			li $a1, 25 # y
			jal CoordinateToAddress	
			move $a0, $v0	
			lw $a1, principal
			jal desenhaPixel	
			add $t1, $t1, 1	
	
			bne $t1, 33, linha1
		
		li $t1, 30	
		linha2:
			move $a0, $t1 # x
			li $a1, 26 # y
			jal CoordinateToAddress	
			move $a0, $v0	
			lw $a1, principal
			jal desenhaPixel	
			add $t1, $t1, 2	
	
			bne $t1, 34, linha2
			
		pontodecolisão:
			li $a0, 31
			li $a1, 26
			jal CoordinateToAddress	
			move $a0, $v0	
			lw $a1, pontodecolisao
			jal desenhaPixel
		
		li $t1, 30	
		linha3:
			move $a0, $t1 # x
			li $a1, 27 # y
			jal CoordinateToAddress	
			move $a0, $v0	
			lw $a1, principal
			jal desenhaPixel	
			add $t1, $t1, 1	
	
			bne $t1, 33, linha3
	
	j fim
			
	fim:
