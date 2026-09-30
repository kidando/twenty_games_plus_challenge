package main

import "core:math/linalg"
import "core:math/rand"
import "core:fmt"
import rl "vendor:raylib"

State :: enum {
	READY,
	GAME,
}

Paddle :: struct {
	x:      i32,
	y:      i32,
	width:  i32,
	height: i32,
}

SCREEN_WIDTH :: 1280
SCREEN_HEIGHT :: 720
PADDLE_WIDTH :: 16
PADDLE_HEIGHT :: 100
PADDLE_SPEED :: 10
WINDOW_PADDING :: 32
SCORE_UI_PADDING_INLINE :: 16
SCORE_UI_PADDING_BLOCK :: 8
SCORE_FONT_SIZE :: 48
BALL_RADIUS :: 16
STAT_GAME_TEXT :: "PRESS 'SPACE' TO START"
STAT_GAME_FONT_SIZE :: 48
BALL_START_POS:rl.Vector2:{SCREEN_WIDTH/2, SCREEN_HEIGHT/2}
INIT_BALL_SPEED::200
BALL_SPEED_ADDER::30

BOUNDARY_TOP:rl.Rectangle:{
	x=0,
	y=0,
	width = SCREEN_WIDTH,
	height = 32
}
BOUNDARY_BOTTOM:rl.Rectangle:{
	x=0,
	y=SCREEN_HEIGHT-32,
	width = SCREEN_WIDTH,
	height = 32
}

GOAL_LEFT:rl.Rectangle:{
	x=-16,
	y=32,
	width = 32,
	height = SCREEN_HEIGHT-64
}
GOAL_RIGHT:rl.Rectangle:{
	x=SCREEN_WIDTH-16,
	y=32,
	width = 32,
	height = SCREEN_HEIGHT-64
}

paddle_left_pos_x: i32 = WINDOW_PADDING
paddle_left_pos_y: i32 = WINDOW_PADDING

paddle_right_pos_x: i32 = SCREEN_WIDTH - WINDOW_PADDING - PADDLE_WIDTH
paddle_right_pos_y: i32 = WINDOW_PADDING

left_score: i32 = 0
right_score: i32 = 0

ball_pos:rl.Vector2 = BALL_START_POS
ball_dir:rl.Vector2
ball_speed:f32 = INIT_BALL_SPEED

state: State = .READY

main :: proc() {
	rl.SetConfigFlags({.VSYNC_HINT})
	rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Pong")
	rl.SetTargetFPS(60)


	for !rl.WindowShouldClose() {

        if state == .READY{
            if rl.IsKeyDown(.SPACE){
                state = .GAME
				ball_dir = {rand.float32_range(-1,1),rand.float32_range(-1,1)}
				// ball_dir ={0,1}
            }
        }
		paddle_controls()

		prev_ball_pos:rl.Vector2 = ball_pos
		ball_pos += rl.Vector2Normalize(ball_dir) * ball_speed * rl.GetFrameTime()
		

		// Left Paddle Collisions
		if rl.CheckCollisionCircleRec(ball_pos,BALL_RADIUS,{x=f32(paddle_left_pos_x),y=f32(paddle_left_pos_y),width=PADDLE_WIDTH,height=PADDLE_HEIGHT}){
			ball_speed += BALL_SPEED_ADDER
			collision_normal:rl.Vector2

			if prev_ball_pos.x > f32(paddle_left_pos_x) + PADDLE_WIDTH{
				collision_normal += {1,0}
				ball_pos.x = f32(paddle_left_pos_x) + PADDLE_WIDTH + BALL_RADIUS
			}

			if prev_ball_pos.y < f32(paddle_left_pos_y){
				collision_normal += {0,-1}
			}
			if prev_ball_pos.y > f32(paddle_left_pos_y)+PADDLE_HEIGHT{
				collision_normal += {0,1}
			}

			ball_dir = rl.Vector2Normalize(linalg.reflect(ball_dir, rl.Vector2Normalize(collision_normal)))
		}

		// Right Paddle Collisions
		if rl.CheckCollisionCircleRec(ball_pos,BALL_RADIUS,{x=f32(paddle_right_pos_x),y=f32(paddle_right_pos_y),width=PADDLE_WIDTH,height=PADDLE_HEIGHT}){
			ball_speed += BALL_SPEED_ADDER
			collision_normal:rl.Vector2

			if prev_ball_pos.x < f32(paddle_right_pos_x){
				collision_normal += {-1,0}
				ball_pos.x = f32(paddle_right_pos_x) - BALL_RADIUS
			}

			if prev_ball_pos.y < f32(paddle_right_pos_y){
				collision_normal += {0,-1}
			}
			if prev_ball_pos.y > f32(paddle_right_pos_y)+PADDLE_HEIGHT{
				collision_normal += {0,1}
			}

			ball_dir = rl.Vector2Normalize(linalg.reflect(ball_dir, rl.Vector2Normalize(collision_normal)))
		}

		// Top Boundary Collisions
		if rl.CheckCollisionCircleRec(ball_pos,BALL_RADIUS,{x=BOUNDARY_TOP.x,y=BOUNDARY_TOP.y,width=BOUNDARY_TOP.width,height=BOUNDARY_TOP.height}){
			collision_normal:rl.Vector2

			if prev_ball_pos.y > BOUNDARY_TOP.y + BOUNDARY_TOP.height{
				collision_normal += {0,1}
				ball_pos.y = BOUNDARY_TOP.y +  BOUNDARY_TOP.height + BALL_RADIUS
			}

			ball_dir = rl.Vector2Normalize(linalg.reflect(ball_dir, rl.Vector2Normalize(collision_normal)))
		}
		// BOTTOM Boundary Collisions
		if rl.CheckCollisionCircleRec(ball_pos,BALL_RADIUS,{x=BOUNDARY_BOTTOM.x,y=BOUNDARY_BOTTOM.y,width=BOUNDARY_BOTTOM.width,height=BOUNDARY_BOTTOM.height}){
			collision_normal:rl.Vector2

			if prev_ball_pos.y < BOUNDARY_BOTTOM.y{
				collision_normal += {0,-1}
				ball_pos.y = BOUNDARY_BOTTOM.y - BALL_RADIUS
			}

			ball_dir = rl.Vector2Normalize(linalg.reflect(ball_dir, rl.Vector2Normalize(collision_normal)))
		}

		if rl.CheckCollisionCircleRec(ball_pos,BALL_RADIUS,{x=GOAL_LEFT.x,y=GOAL_LEFT.y,width=GOAL_LEFT.width,height=GOAL_LEFT.height}){
			left_score += 1
			reset_game()

		}
		if rl.CheckCollisionCircleRec(ball_pos,BALL_RADIUS,{x=GOAL_RIGHT.x,y=GOAL_RIGHT.y,width=GOAL_RIGHT.width,height=GOAL_RIGHT.height}){
			right_score += 1
			reset_game()
		}
		


		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)
		draw_game_state()
		rl.EndDrawing()
	}
	rl.CloseWindow()
}

reset_game::proc(){
	state = .READY
	ball_pos = BALL_START_POS
	paddle_left_pos_x = WINDOW_PADDING
	paddle_left_pos_y = WINDOW_PADDING
	paddle_right_pos_x = SCREEN_WIDTH - WINDOW_PADDING - PADDLE_WIDTH
	paddle_right_pos_y = WINDOW_PADDING
	ball_speed = INIT_BALL_SPEED
	ball_dir = {0,0}
}

draw_game_state :: proc() {
	rl.DrawRectangle((i32(SCREEN_WIDTH) / 2) - 1, 0, 2, i32(SCREEN_HEIGHT), rl.WHITE)
	rl.DrawRectangle(
		i32(BOUNDARY_TOP.x),
		i32(BOUNDARY_TOP.y),
		i32(BOUNDARY_TOP.width),
		i32(BOUNDARY_TOP.height),
		rl.GRAY
	)
	rl.DrawRectangle(
		i32(BOUNDARY_BOTTOM.x),
		i32(BOUNDARY_BOTTOM.y),
		i32(BOUNDARY_BOTTOM.width),
		i32(BOUNDARY_BOTTOM.height),
		rl.GRAY
	)

	rl.DrawRectangle(
		i32(GOAL_LEFT.x),
		i32(GOAL_LEFT.y),
		i32(GOAL_LEFT.width),
		i32(GOAL_LEFT.height),
		{0,255,255,255}
	)
	rl.DrawRectangle(
		i32(GOAL_RIGHT.x),
		i32(GOAL_RIGHT.y),
		i32(GOAL_RIGHT.width),
		i32(GOAL_RIGHT.height),
		{255,0,255,255}
	)

	left_score_string := rl.TextFormat("%v", left_score)
	rl.DrawText(
		left_score_string,
		(i32(SCREEN_WIDTH / 2)) -
		rl.MeasureText(left_score_string, SCORE_FONT_SIZE) -
		SCORE_UI_PADDING_INLINE,
		SCORE_UI_PADDING_BLOCK,
		SCORE_FONT_SIZE,
		rl.WHITE,
	)
	rl.DrawText(
		rl.TextFormat("%v", right_score),
		i32(SCREEN_WIDTH / 2) + SCORE_UI_PADDING_INLINE,
		SCORE_UI_PADDING_BLOCK,
		SCORE_FONT_SIZE,
		rl.WHITE,
	)

	if state == .READY {
		rl.DrawText(
			STAT_GAME_TEXT,
			i32(SCREEN_WIDTH / 2) - (rl.MeasureText(STAT_GAME_TEXT, STAT_GAME_FONT_SIZE) / 2),
			i32(SCREEN_HEIGHT / 2) - 100,
			STAT_GAME_FONT_SIZE,
			rl.WHITE,
		)
	}

	rl.DrawText(
		rl.TextFormat("BALL SPEED: %v", ball_speed),
		i32(SCREEN_WIDTH / 2) + SCORE_UI_PADDING_INLINE - (rl.MeasureText(rl.TextFormat("BALL SPEED: %v", ball_speed), 32) / 2),
		SCREEN_HEIGHT - 64,
		32,
		rl.WHITE,
	)


	rl.DrawRectangle(paddle_left_pos_x, paddle_left_pos_y, PADDLE_WIDTH, PADDLE_HEIGHT, rl.WHITE)
	rl.DrawRectangle(paddle_right_pos_x, paddle_right_pos_y, PADDLE_WIDTH, PADDLE_HEIGHT, rl.WHITE)
	rl.DrawCircle(i32(ball_pos.x), i32(ball_pos.y), BALL_RADIUS, rl.GREEN)
}

paddle_controls :: proc() {
	if state != .GAME {
		return
	}

	if rl.IsKeyDown(.S) && paddle_left_pos_y < SCREEN_HEIGHT - PADDLE_HEIGHT - WINDOW_PADDING {
		paddle_left_pos_y += PADDLE_SPEED
	}
	if rl.IsKeyDown(.W) && paddle_left_pos_y > WINDOW_PADDING {
		paddle_left_pos_y -= PADDLE_SPEED
	}
	if rl.IsKeyDown(.DOWN) && paddle_right_pos_y < SCREEN_HEIGHT - PADDLE_HEIGHT - WINDOW_PADDING {
		paddle_right_pos_y += PADDLE_SPEED
	}
	if rl.IsKeyDown(.UP) && paddle_right_pos_y > WINDOW_PADDING {
		paddle_right_pos_y -= PADDLE_SPEED
	}
}

