; set game state memory location
	.equ HEAD_X, 0x1000          ; Snake head's position on x
	.equ HEAD_Y, 0x1004          ; Snake head's position on y
	.equ TAIL_X, 0x1008          ; Snake tail's position on x
	.equ TAIL_Y, 0x100C          ; Snake tail's position on Y
	.equ SCORE, 0x1010           ; Score address
	.equ GSA, 0x1014             ; Game state array address
	
	.equ CP_VALID, 0x1200        ; Whether the checkpoint is valid.
	.equ CP_HEAD_X, 0x1204       ; Snake head's X coordinate. (Checkpoint)
	.equ CP_HEAD_Y, 0x1208       ; Snake head's Y coordinate. (Checkpoint)
	.equ CP_TAIL_X, 0x120C       ; Snake tail's X coordinate. (Checkpoint)
	.equ CP_TAIL_Y, 0x1210       ; Snake tail's Y coordinate. (Checkpoint)
	.equ CP_SCORE, 0x1214        ; Score. (Checkpoint)
	.equ CP_GSA, 0x1218          ; GSA. (Checkpoint)
	
	.equ LEDS, 0x2000            ; LED address
	.equ SEVEN_SEGS, 0x1198      ; 7 - segment display addresses
	.equ RANDOM_NUM, 0x2010      ; Random number generator address
	.equ BUTTONS, 0x2030         ; Buttons addresses
	
	; starting the game
	
	.equ START_HEAD_X, 0          ; x coordinate of the ehad at start of the game
	.equ START_HEAD_Y, 0          ; y coordinate of the ehad at start of the game
	.equ START_DIR, 4             ; the snak eoges right at the beginning of the game
	
	; button state
	.equ BUTTON_NONE, 0
	.equ BUTTON_LEFT, 1
	.equ BUTTON_UP, 2
	.equ BUTTON_DOWN, 3
	.equ BUTTON_RIGHT, 4
	.equ BUTTON_CHECKPOINT, 5
	
	; array state
	.equ DIR_LEFT, 1             ; leftward direction
	.equ DIR_UP, 2               ; upward direction
	.equ DIR_DOWN, 3             ; downward direction
	.equ DIR_RIGHT, 4            ; rightward direction
	.equ FOOD, 5                 ; food
	
	; constants
	.equ NB_ROWS, 8              ; number of rows
	.equ NB_COLS, 12             ; number of columns
	.equ NB_CELLS, 96            ; number of cells in GSA
	.equ RET_ATE_FOOD, 1         ; return value for hit_test when food was eaten
	.equ RET_COLLISION, 2        ; return value for hit_test when a collision was detected
	.equ ARG_HUNGRY, 0           ; a0 argument for move_snake when food wasn't eaten
	.equ ARG_FED, 1              ; a0 argument for move_snake when food was eaten
    .equ BLINKS, 10              ; number of times one should blink the scor eonce it is called
	.equ CYCLES, 25000000		 ; number of cycles 50 MHz clock => 50 000 000 million instructions per second, hence we make a wait of 0.5 seconds.


	
	; initialize stack pointer
	addi sp, zero, LEDS
	
	; main
	; arguments
	; none
	;
	; return values
	; This procedure should never return.
main:
	; TODO: Finish this procedure.
	
	ret
	
	
	; BEGIN: clear_leds
clear_leds:
	stw zero, LEDS(zero)
	stw zero, 4 + LEDS(zero)
	stw zero, 8 + LEDS(zero)
	ret
	; END: clear_leds
	
	
	; BEGIN: set_pixel
set_pixel:
	
	; x * 8 + y
	slli t0, a0, 3
	add t0, t0, a1
	
	; sets bit = 1 in the desired place
	addi t1, zero, 1
	sll t0, t1, t0
	
	; Implement the multiplexer
	
	addi t1, zero, 4
	blt a0, t1, enable_led1
	addi t1, t1, 4
	blt a0, t1, enable_led2
	addi t1, t1, 4
	blt a0, t1, enable_led3
	ret
	
enable_led1:
	ldw t3, LEDS(zero)
	or t0, t0, t3
	stw t0, LEDS(zero)
	ret
enable_led2:
	ldw t3, LEDS + 4 (zero)
	or t0, t0, t3
	stw t0, LEDS + 4 (zero)
	ret
enable_led3:
	ldw t3, LEDS + 8 (zero)
	or t0, t0, t3
	stw t0, LEDS + 8(zero)
	ret
	
	; END: set_pixel
	
	
	
	; BEGIN: display_score
	
divide:
	; We shall give the Euclidian division of the score by 10, and its remainder.
	
	add t0, zero, a0
	add t1, zero, a1
	; Quotient
	addi t2, zero, 0
	
division_loop:
	sub t0, t0, a1
	bge t0, a1, increment_quotient
	
	jmpi end_division_loop
	
	
increment_quotient:
	; Increment the quotient by one
	addi t2, t2, 1
	jmpi division_loop
	
	
end_division_loop:
	;Quotient by 10
	add v0, t2, zero
	; Remainder by 10
	add v1, t0, zero
	
	; We are word - aligned
	slli v0, v0, 2
	slli v1, v1, 2
	
	; Load the words in the return registers
	ldw v0, digit_map(v0)
	ldw v1, digit_map(v1)
	
	ret
	
display_score:
	
	; Make some place on the stack
	addi sp, sp, - 4
	stw ra, 0(sp)
	
	; Load the value of the score. The score's value should be capped to 99
	ldw a0, SCORE(zero)
	andi a0, a0, 99
	addi a1, zero, 10
	
	; Store the quotient in the register v0 and the remainder in the register v1
	call divide
	
	; Tens digits
	stw v0, SEVEN_SEGS + 8(zero)
	
	;Units digits
	stw v1, SEVEN_SEGS + 12(zero)
	
	;Hundreds digits : store the digit zero, since the max score is 99
	ldw t0, digit_map (zero)
	stw t0, SEVEN_SEGS + 4(zero)
	;Throusands digits : store the digit zero, since the max score is 99
	ldw t0, digit_map (zero)
	stw t0, SEVEN_SEGS (zero)

	; Restore initial stack state
	ldw ra, 0(sp)
	addi sp, sp, 4
	
	ret
	
	
	
	; END: display_score
	
	
	; BEGIN: init_game
init_game:
	
	; make some space on the stack
	addi sp, sp, - 4
	stw ra, 0(sp)
	
	; Clear the GSA
	addi t0, t0, 95
	slli t0, t0, 2
	
    init_gsa:
        addi t0, t0, - 4
        stw zero, GSA(t0)
        bne t0, zero, init_gsa
	
	; Init the snake's position
	addi t0, zero, START_HEAD_X
	stw t0, HEAD_X(zero)
	addi t0, zero, START_HEAD_X
	stw t0, TAIL_X(zero)
	
	addi t0, zero, START_HEAD_Y
	stw t0, HEAD_Y(zero)
	addi t0, zero, START_HEAD_Y
	stw t0, TAIL_Y(zero)
	
	
	; Initialize the moving direction
	
	; Recover the position in the GSA
	addi t0, zero, START_HEAD_X
	slli t0, t0, 3
	addi t0, t0, START_HEAD_Y
	
	; Shift by 2 to access the word
	slli t0, t0, 2
	addi t1, zero, START_DIR
	; Write the init direction in the GSA
	stw t1, GSA(t0)
	
	; Call the necessary procedures for initializing the game
	call display_score
	call clear_leds
	call create_food
	call draw_array
	
	
	
	; Clear the stack
	ldw ra, 0(sp)
	addi sp, sp, 4
	ret
	
	; END: init_game
	
	
	; BEGIN: create_food
create_food:
	; Find a random position that fits inside the GSA
	addi t1, zero, 95
loop_create_food:
	ldw t0, RANDOM_NUM(zero)
	andi t0, t0, 255
	bge t0, t1, loop_create_food
	
	slli t0, t0, 2
	ldw t3, GSA(t0)
	bne t3, zero, loop_create_food
	addi t2, zero, 5
	stw t2, GSA(t0)
	ret
	; END: create_food
	
	
	; BEGIN: hit_test
hit_test:
	
	addi v0, zero, 0
	
	; Load the values of the snake's position
	ldw t0, HEAD_X(zero)
	ldw t1, HEAD_Y(zero)
	
	; Recover the snake's position in the GSA
	slli t2, t0, 3
	add t2, t2, t1
	slli t2, t2, 2
	ldw t3, GSA(t2)
	
	; Implement the collision logic left, up, down, right
	
	; Collision on the left
	addi t4, zero, 1
	beq t3, t4, left
	
	; Collision up
	addi t4, zero, 1
	beq t3, t4, up
	
	; Collision down
	addi t4, zero, 1
	beq t3, t4, down
	
	; Collision right
	addi t4, zero, 1
	beq t3, t4, right
	ret
	
left:
	; Find the position that is one step left and test collision
	addi t0, t0, - 1
	slli t2, t0, 3
	add t2, t2, t1
	slli t2, t2, 2
	ldw t3, GSA(t2)
	jmpi collision_next
	
up:
	; Find the position that is one step upwards and test collision
	addi t1, t1, - 1
	slli t2, t0, 3
	add t2, t2, t1
	slli t2, t2, 2
	ldw t3, GSA(t2)
	jmpi collision_next
	
down:
	; Find the position that is one step downwards and test collision
	addi t1, t1, 1
	slli t2, t0, 3
	add t2, t2, t1
	slli t2, t2, 2
	ldw t3, GSA(t2)
	jmpi collision_next
	
right:
	; Find the position that is one step right and test collision
	addi t0, t0, 1
	slli t2, t0, 3
	add t2, t2, t1
	slli t2, t2, 2
	ldw t3, GSA(t2)
	jmpi collision_next
	
	
collision_next:
	; Leftwards
	; t4 : iterator
	; SNAKE HIT THE BOUNDARY
	
	; head is out of the boundary in the x coordinate on the left
	blt t0, zero, hit_boundary_or_body
	; head is out of the boundary in the y coordinate on the left
	blt t1, zero, hit_boundary_or_body
	; head is out of the boundary in the x coordinate on the right
	addi t4, zero, 12
	bge t0, t4, hit_boundary_or_body
	; head is out of the boundary in the y coordinate on the right
	addi t4, zero, 8
	bge t1, t4, hit_boundary_or_body
	
	; SNAKE HIT HIS BODY
	addi t4, zero, 1
	beq t3, t4, hit_boundary_or_body
	; Upwards
	addi t4, zero, 2
	beq t3, t4, hit_boundary_or_body
	
	; Downwards
	addi t4, zero, 3
	beq t3, t4, hit_boundary_or_body
	
	; Rightwards
	addi t4, zero, 4
	beq t3, t4, hit_boundary_or_body
	
	; Food
	addi t4, zero, 5
	beq t3, t4, hit_food
	
	ret
	
hit_food:
	; Returns 1 as when the snake hit food
	addi v0, zero, 1
	stw zero, GSA(t2)
	ret
	
hit_boundary_or_body:
	; Returns 2 as when the snake hit itself or the boundary.
	; In each case, it signifies game over.
	addi v0, zero, 2
	stw zero, GSA(t2)
	ret
	; END: hit_test
	
	
	; BEGIN:get_input
get_input:
	ldw t0, BUTTONS + 4 (zero)   ; t0 - > edge_capture
	stw zero, BUTTONS + 4 (zero) ; edge_capture is accualized to 0
	
	ldw t1, HEAD_X (zero)        ; t1 - > loading head x
	ldw t2, HEAD_Y (zero)        ; t2 - > loading head y
	
	;Which way is the head going
	slli t1, t1, 3
	add t1, t1, t2
	slli t1, t1, 2               ; the array is byte (not word) addressable
	ldw t3, GSA (t1)             ; t3 - > stores in which way is head going
	
	; Checking which way is head going
	addi t4, zero, 1             ; t4 - > iterator
	beq t3, t4, case_left_rigt
	addi t4, zero, 2
	beq t3, t4, case_up_down
	addi t4, zero, 3
	beq t3, t4, case_up_down
	addi t4, zero, 4
	beq t3, t4, case_left_rigt
	ret
	
	; snake can only go up or down if changed
case_left_rigt:
	andi t4, t0, 2               ; upwards
	bne zero, t4, change_up
	andi t4, t0, 4               ; down
	bne zero, t4, change_down
	ret
	
	; snake can only go left or right if changed
case_up_down:
	andi t4, t0, 1               ; left
	bne zero, t4, change_left
	andi t4, t0, 8               ; right
	bne zero, t4, change_right
	ret
	
change_left:
	addi t4, zero, 1
	stw t0, GSA(t1)
	ret
	
change_up:
	addi t4, zero, 2
	stw t0, GSA(t1)
	ret
	
change_down:
	addi t4, zero, 3
	stw t0, GSA(t1)
	ret
	
change_right:
	addi t4, zero, 4
	stw t0, GSA(t1)
	ret
	
	; END:get_input
;BEGIN: draw_array
draw_array:
	addi t4, zero, 0             ; current y
	addi t5, zero, 0             ; current x
	jmpi loop
	
loop:
	; Getting GSA adress, t3 - > auxiliary
	slli t3, t5, 3               ; x << 3
	add t3, t3, t4               ; x << 3 + y
	slli t3, t3, 2
	
	; t0 stores the GSA value
	ldw t0, GSA (t3)
	
	bne t0, zero, non_zero_pixel
	jmpi next_iteration
	
	
next_iteration:
	
	addi t4, t4, 1               ; x + = 1
	addi t1, zero, 8             ; loop constrains y
	blt t4, t1, loop             ; if y valid then continue iteration, else increase x
	
	addi t4, zero, 0             ; x = 0
	addi t5, t5, 1               ; y + = 1
	addi t2, zero, 12            ; loop constrains x
	blt t5, t2, loop             ; if x valid then continue iteration
	
	ret
	
non_zero_pixel:
	
	; remembering values that will be overwritten
	addi sp, sp, - 12
	stw ra, 0(sp)
	stw a0, 4(sp)
	stw a1, 8(sp)
	
	addi a0, t5, 0               ; x pixel coordinate
	addi a1, t4, 0               ; y pixel coordinate
	
	call set_pixel
	
	addi t5, a0, 0               ; restore x coordinate (registers may have been overwritten)
	addi t4, a1, 0               ; restore y coordinate (registers may have been overwritten)
	
	ldw ra, 0(sp)
	ldw a2, 4(sp)
	ldw a1, 8(sp)
	addi sp, sp, 12
	
	jmpi next_iteration
	; END: draw_array
	
	
;BEGIN: move_snake
move_snake:
	ldw t1, HEAD_X (zero)        ; t1 - > loading head x
	ldw t2, HEAD_Y (zero)        ; t2 - > loading head y
	
	;Which way is the head going - > t3
	; t4 - > auxuiliary
	slli t4, t1, 3
	add t4, t4, t2
	slli t4, t4, 2               ; the array is byte (not word) addressable
	ldw t3, GSA (t4)             ; t3 - > stores in which way is head going
	
	; Checking which way is head going
	addi t4, zero, 1             ; t4 - > iterator
	beq t3, t4, head_move_left
	addi t4, zero, 2
	beq t3, t4, head_move_up
	addi t4, zero, 3
	beq t3, t4, head_move_down
	addi t4, zero, 4
	beq t3, t4, head_move_right
	ret
	
head_move_left:
	addi t1, t1, - 1             ; t1 - > head_x, move left
	stw t1, HEAD_X (zero)        ; storing new head x
	jmpi store_new_direction
	
head_move_up:
	addi t2, t2, - 1             ; t2 - > head_y, move up
	stw t2, HEAD_Y (zero)        ; storing new head y
	jmpi store_new_direction
	
head_move_down:
	addi t2, t2, 1               ; t2 - > head_y, move down
	stw t2, HEAD_Y (zero)        ; storing new head y
	jmpi store_new_direction
	
head_move_right:
	addi t1, t1, 1               ; t1 - > head_x, move right
	stw t1, HEAD_X (zero)        ; storing new head x
	jmpi store_new_direction
	
store_new_direction:
	; Storing which way is the head going in new GSA
	; t4 - > auxiliary
	slli t4, t1, 3
	add t4, t4, t2
	slli t4, t4, 2               ; the array is byte (not word) addressable
	stw t3, GSA (t4)             ; t3 - > stores in which way was head going, giving it to GSA
	jmpi check_move_Tail
	
check_move_Tail:
	beq a0, zero, move_Tail
	ret
	
move_Tail:
	ldw t1, TAIL_X (zero)        ; t1 - > loading tail x
	ldw t2, TAIL_Y (zero)        ; t2 - > loading tail y
	
	; Which way is the tail going - > t3
	; t4 - > auxuiliary
	slli t4, t1, 3
	add t4, t4, t2
	slli t4, t4, 2               ; the array is byte (not word) addressable
	ldw t3, GSA (t4)             ; t3 - > stores in which way is tail going
	
	; Clearing the old tail
	stw zero, GSA (t4)
	
	; Checking which way is tail going
	addi t4, zero, 1             ; t4 - > iterator
	beq t3, t4, tail_move_left
	addi t4, zero, 2
	beq t3, t4, tail_move_up
	addi t4, zero, 3
	beq t3, t4, tail_move_down
	addi t4, zero, 4
	beq t3, t4, tail_move_right
	ret
	
tail_move_left:
	addi t1, t1, - 1             ; t1 - > tail_x, move left
	stw t1, TAIL_X (zero)        ; storing new tail x
	ret
	
tail_move_up:
	addi t2, t2, - 1             ; t2 - > tail_y, move up
	stw t2, TAIL_Y (zero)        ; storing new tail y
	ret
	
tail_move_down:
	addi t2, t2, 1               ; t2 - > tail_y, move down
	stw t2, TAIL_Y (zero)        ; storing new tail y
	ret
	
tail_move_right:
	addi t1, t1, 1               ; t1 - > tail_x, move right
	stw t1, TAIL_X (zero)        ; storing new tail x
	ret
	; END: move_snake
	
	; BEGIN: save_checkpoint
save_checkpoint:
	; Init return value to zero
	add v0, zero, zero
	ldw t0, SCORE(zero)
	
	add t1, t0, zero
	addi t2, zero, 0
	
	; One now has to verify that the score is divisible by 10 : \
	
is_zero_modulo10:
	
	addi t1, t1, - 10
	
	blt t1, t2, end_save_checkpoint
	beq t1, t2, make_checkpoint
	jmpi is_zero_modulo10
	
make_checkpoint:
	
	addi v0, v0, 1
	stw v0, CP_VALID(zero)
	
	; We now store the game state in the memory region
	
	ldw t3, HEAD_X(zero)
	stw t3, CP_HEAD_X(zero)
	
	ldw t3, HEAD_Y(zero)
	stw t3, CP_HEAD_Y(zero)
	
	ldw t3, TAIL_X(zero)
	stw t3, CP_TAIL_X(zero)
	
	ldw t3, TAIL_Y(zero)
	stw t3, CP_TAIL_Y(zero)
	
	stw t0, CP_SCORE(zero)
	
	; We need a method for storing the value of the GSA:
	
	add t4, zero, zero           ; iterator
	addi t5, zero, NB_CELLS           ; number of cells
store_gsa:
	bge t4, t5, end_save_checkpoint ; saving is terminated
	slli t6, t4, 2              ; be word aligned
	ldw t3, GSA(t6)              ; load the current state of the GSA
	stw t3, CP_GSA(t6)           ; store the current state of the GSA
	addi t4, t4, 1
	jmpi store_gsa
	
end_save_checkpoint:
	ret
; END: save_checkpoint
	
; BEGIN: restore_checkpoint
restore_checkpoint:

    ldw t0, CP_VALID(zero)
    add v0, t0, zero 

    beq v0, zero, end_restore_checkpoint 

    ldw t1, CP_HEAD_X(zero)
    stw t1, HEAD_X(zero)

    ldw t1, CP_HEAD_Y(zero)
    stw t1, HEAD_Y(zero)

    ldw t1, CP_TAIL_X(zero)
    stw t1, TAIL_X(zero)

    ldw t1, CP_TAIL_Y(zero)
    stw t1, TAIL_Y(zero)

    ldw t1, CP_SCORE(zero)
    stw t1, SCORE(zero)

    add t2, zero, zero
    addi t3, zero, 95 

    load_gsa:
        bge t2, t3, end_restore_checkpoint 
        slli t4, t2, 2
        ldw t1, CP_GSA(t4)
        stw t1, GSA(t4)
        addi t2, t2, 1 
        jmpi load_gsa

    end_restore_checkpoint:
        ret
; END: restore_checkpoint

push_stack:
    addi sp, sp, -32
    stw s0, 28(sp)
    stw s1, 24(sp)
    stw s2, 20(sp)
    stw s3, 16(sp)
    stw s4, 12(sp)
    stw s5, 8(sp)
    stw s6, 4(sp)
    stw s7, 0(sp)
    ret

pop_stack: 
    ldw s0, 28(sp)
    ldw s1, 24(sp)
    ldw s2, 20(sp)
    ldw s3, 16(sp)
    ldw s4, 12(sp)
    ldw s5, 8(sp)
    ldw s6, 4(sp)
    ldw s7, 0(sp)
    
    addi sp, sp, 32
    ret


; BEGIN: blink_score
blink_score:
    addi sp, sp, -4
    stw ra, 0(sp) 

    call push_stack
    addi s0, zero, BLINKS

    blink_loop:
        ldw zero, SEVEN_SEGS(zero)
        ldw zero, SEVEN_SEGS+4(zero)
        ldw zero, SEVEN_SEGS+8(zero)
        ldw zero, SEVEN_SEGS+12(zero)

        call wait
        call display_score
        call wait

        bne s0, zero, blink_loop

    call pop_stack

    ldw ra, 0(sp)
    addi sp, sp,4
    ret
; END: blink_score

; BEGIN : wait
wait: 

	addi t0, zero, CYCLES
	addi t1, zero, 0

	loop_wait:
		addi t1, t1, 1
		bge t1, t0, end_wait
		jmpi loop_wait
	
	end_wait:
		ret
; END : wait


digit_map:
	.word 0xFC                   ; 0
	.word 0x60                   ; 1
	.word 0xDA                   ; 2
	.word 0xF2                   ; 3
	.word 0x66                   ; 4
	.word 0xB6                   ; 5
	.word 0xBE                   ; 6
	.word 0xE0                   ; 7
	.word 0xFE                   ; 8
	.word 0xF6                   ; 9