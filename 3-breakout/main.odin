package main

import "core:fmt"
import "core:math"
import "core:math/linalg"
import "core:math/rand"
import rl "vendor:raylib"

State :: enum {
	TITLE,
	READY,
	GAME,
	GAME_OVER,
}

Brick :: struct {
	position: rl.Vector2,
	color:    rl.Color,
	points:   i32,
	enabled:  bool,
}


// CONSTANTS
MAX_ROWS :: 8
MAX_COLUMNS :: 14
BRICK_WIDTH :: 10
BRICK_HEIGHT :: 4
COLUMN_GAP :: 2
ROW_GAP :: 2
ARENA_BORDER_SIZE :: 7
RED: rl.Color : {163, 30, 10, 255}
GREY: rl.Color : {204, 204, 204, 255}
ORANGE: rl.Color : {194, 133, 10, 255}
GREEN: rl.Color : {10, 133, 51, 255}
YELLOW: rl.Color : {194, 194, 41, 255}
BLUE: rl.Color : {10, 133, 194, 255}
BRICKS_STARTING_POS: rl.Vector2 : {7, 64}
GREY_BAND_HEIGHT_BEFORE_PADDLE_BAND :: 150

SCREEN_SIZE: rl.Vector2 : {720, 1280}
VIEW_PORT_SIZE: rl.Vector2 : {180, 320}
PADDLE_WIDTH_MAX :: 24
PADDLE_HEIGHT :: BRICK_HEIGHT
PADDLE_STARTING_X :: VIEW_PORT_SIZE.x / 2 - PADDLE_WIDTH_MAX / 2
MAX_LIVES :: 3
BALL_START_POSITION: rl.Vector2 = {(VIEW_PORT_SIZE.x / 2) - BRICK_HEIGHT / 2, 261}
PADDLE_POSITION_Y :: 261 + BRICK_HEIGHT
BREAKOUT_SPEED:f32:400


// VARIABLES
camera: rl.Camera2D
bricks: [MAX_COLUMNS][MAX_ROWS]Brick
paddle_width: f32 = PADDLE_WIDTH_MAX
paddle_position: f32 = PADDLE_STARTING_X

state: State = .GAME_OVER
paddle_speed: f32 = 220
lives: i32 = MAX_LIVES
points: i32 = 0
ball_direction: rl.Vector2
ball_position: rl.Vector2 = BALL_START_POSITION
ball_speeds:[3]f32 = {100,200,300}
ball_speed: f32 = 100
has_broken_out:bool = false
ball_hits:i32 = 0
ball_level:i32 = 0

left_wall_collider: rl.Rectangle = {
	x      = 0,
	y      = 0,
	width  = ARENA_BORDER_SIZE,
	height = VIEW_PORT_SIZE.y,
}
right_wall_collider: rl.Rectangle = {
	x      = VIEW_PORT_SIZE.x - ARENA_BORDER_SIZE,
	y      = 0,
	width  = ARENA_BORDER_SIZE,
	height = VIEW_PORT_SIZE.y,
}
top_wall_collider: rl.Rectangle = {
	x      = ARENA_BORDER_SIZE,
	y      = 0,
	width  = VIEW_PORT_SIZE.x - (ARENA_BORDER_SIZE * 2),
	height = ARENA_BORDER_SIZE,
}

paddle_sound: rl.Sound
wall_sound: rl.Sound
brick_sound: rl.Sound


main :: proc() {
	rl.SetConfigFlags({.VSYNC_HINT})
	rl.InitWindow(720, 1280, "Breakout")
	rl.InitAudioDevice()
	rl.SetTargetFPS(60)

	create()

	for !rl.WindowShouldClose() {
		dt := rl.GetFrameTime()
		input(dt)
		update(dt)
		rl.BeginDrawing()
		rl.BeginMode2D(camera)
		rl.ClearBackground(rl.BLACK)
		draw()
		rl.EndMode2D()
		rl.EndDrawing()
	}
	rl.UnloadSound(paddle_sound)
	rl.UnloadSound(wall_sound)
	rl.UnloadSound(brick_sound)
	rl.CloseAudioDevice()
	rl.CloseWindow()
}

reset_session::proc(){
	paddle_width = PADDLE_WIDTH_MAX
	ball_direction = {0,0}
	ball_level = 0
	ball_speed = ball_speeds[ball_level]
	has_broken_out = false
	ball_position = BALL_START_POSITION
	paddle_position = PADDLE_STARTING_X
	ball_hits = 0
}

create :: proc() {
	paddle_sound = rl.LoadSound("paddle.wav")
	brick_sound = rl.LoadSound("brick.wav")
	wall_sound = rl.LoadSound("wall.wav")
	camera.zoom = SCREEN_SIZE.x / VIEW_PORT_SIZE.x

	reset_bricks()
}

reset_bricks::proc(){
	// Bricks setup
	for x in 0 ..< MAX_COLUMNS {
		for y in 0 ..< MAX_ROWS {
			bricks[x][y].position = {
				BRICKS_STARTING_POS.x + f32(x) * (BRICK_WIDTH + COLUMN_GAP),
				BRICKS_STARTING_POS.y + f32(y) * (BRICK_HEIGHT + ROW_GAP),
			}
			if y == 0 || y == 1 {
				bricks[x][y].color = RED
				bricks[x][y].points = 7
			}
			if y == 2 || y == 3 {
				bricks[x][y].color = ORANGE
				bricks[x][y].points = 5
			}
			if y == 4 || y == 5 {
				bricks[x][y].color = GREEN
				bricks[x][y].points = 3
			}
			if y == 6 || y == 7 {
				bricks[x][y].color = YELLOW
				bricks[x][y].points = 1
			}
			bricks[x][y].enabled = true


		}
	}
}

input :: proc(dt: f32) {
	if state == .GAME {
		if rl.IsKeyDown(.A) || rl.IsKeyDown(.LEFT) {
			if paddle_position > ARENA_BORDER_SIZE {
				paddle_position -= paddle_speed * dt

			}
		}
		if rl.IsKeyDown(.D) || rl.IsKeyDown(.RIGHT) {
			if paddle_position < VIEW_PORT_SIZE.x - ARENA_BORDER_SIZE - paddle_width {
				paddle_position += paddle_speed * dt

			}
		}
	}
	if state == .READY {
		if rl.IsKeyPressed(.SPACE) {
			state = .GAME
			ball_direction = {rand.float32_range(-1, 1), -1}
			ball_direction = rl.Vector2Normalize(ball_direction)
		}
	}

	if state == .GAME_OVER{
		if rl.IsKeyPressed(.ENTER){
			points = 0
			lives = 3
			reset_bricks()
			reset_session()
			state = .READY
		}
	}

}

check_ball_hits::proc(){
	ball_hits += 1
	if ball_hits == 4 || ball_hits == 12{
		ball_level += 1
	}

	ball_speed = ball_speeds[ball_level]
}

update :: proc(dt: f32) {
	if state == .GAME {
		previous_ball_position := ball_position
		ball_position += ball_direction * ball_speed * dt

		if ball_position.y > VIEW_PORT_SIZE.y{
			lives -= 1
			if lives > 0{
				reset_session()
				state = .READY
			}else{
				state = .GAME_OVER
			}
		}

		ball_rec: rl.Rectangle = {
			x      = ball_position.x,
			y      = ball_position.y,
			width  = BRICK_HEIGHT,
			height = BRICK_HEIGHT,
		}
		// Collision with Left Wall
		if rl.CheckCollisionRecs(ball_rec, left_wall_collider) {
			collision_normal: rl.Vector2
			check_ball_hits()

			if previous_ball_position.x > 0 {
				collision_normal += {1, 0}
				ball_position.x = ARENA_BORDER_SIZE
			}

			if collision_normal != 0 {
				ball_direction = rl.Vector2Normalize(
					linalg.reflect(ball_direction, rl.Vector2Normalize(collision_normal)),
				)
			}
			if !rl.IsSoundPlaying(wall_sound) {
				rl.PlaySound(wall_sound)
			}


		}
		// Collision with Right Wall
		if rl.CheckCollisionRecs(ball_rec, right_wall_collider) {
			collision_normal: rl.Vector2
			check_ball_hits()

			if previous_ball_position.x < VIEW_PORT_SIZE.x {
				collision_normal += {-1, 0}
				ball_position.x = VIEW_PORT_SIZE.x - ARENA_BORDER_SIZE - BRICK_HEIGHT
			}

			if collision_normal != 0 {
				ball_direction = rl.Vector2Normalize(
					linalg.reflect(ball_direction, rl.Vector2Normalize(collision_normal)),
				)
			}
			if !rl.IsSoundPlaying(wall_sound) {
				rl.PlaySound(wall_sound)
			}


		}
		// Collision with TOP Wall
		if rl.CheckCollisionRecs(ball_rec, top_wall_collider) {
			collision_normal: rl.Vector2
			check_ball_hits()

			if previous_ball_position.y > ARENA_BORDER_SIZE {
				collision_normal += {0, 1}
				ball_position.y = ARENA_BORDER_SIZE
			}

			if collision_normal != 0 {
				ball_direction = rl.Vector2Normalize(
					linalg.reflect(ball_direction, rl.Vector2Normalize(collision_normal)),
				)
			}
			if !has_broken_out{
				has_broken_out = true
				ball_speed = BREAKOUT_SPEED
				paddle_width = paddle_width/2
			}

			if !rl.IsSoundPlaying(wall_sound) {
				rl.PlaySound(wall_sound)
			}

		}

		paddle_rec: rl.Rectangle = {
			x      = paddle_position,
			y      = PADDLE_POSITION_Y,
			width  = paddle_width,
			height = BRICK_HEIGHT,
		}

		if rl.CheckCollisionRecs(ball_rec, paddle_rec) {
			check_ball_hits()
			if ball_direction.y > 0 {
				ball_position.y = PADDLE_POSITION_Y - BRICK_HEIGHT

				paddle_center := paddle_position + paddle_width / 2
				hit_offset := (ball_position.x - paddle_center) / (paddle_width / 2)
				hit_offset = clamp(hit_offset, -1, 1)
				MAX_BOUNCE_ANGLE: f32 : 1.3

				angle := hit_offset * MAX_BOUNCE_ANGLE
				// Rebuild direction from the angle:
				//   angle = 0      -> straight up (0, -1)
				//   angle > 0      -> up and to the right
				//   angle < 0      -> up and to the left

				ball_direction = rl.Vector2{math.sin(angle), -math.cos(angle)}

				ball_direction = rl.Vector2Normalize(ball_direction)

				if !rl.IsSoundPlaying(paddle_sound) {
					rl.PlaySound(paddle_sound)
				}
			}
		}

		for x in 0 ..< MAX_COLUMNS {
			for y in 0 ..< MAX_ROWS {
				if bricks[x][y].enabled {
					brick_rec: rl.Rectangle = {
						x      = bricks[x][y].position.x,
						y      = bricks[x][y].position.y,
						width  = BRICK_WIDTH,
						height = BRICK_HEIGHT,
					}
					if rl.CheckCollisionRecs(ball_rec, brick_rec) {
						check_ball_hits()
						collision_normal: rl.Vector2
						if previous_ball_position.y > bricks[x][y].position.y + BRICK_HEIGHT {
							collision_normal += {0, 1}
							ball_position.y = bricks[x][y].position.y + BRICK_HEIGHT
						}
						if previous_ball_position.y < bricks[x][y].position.y {
							collision_normal += {0, -1}
							ball_position.y = bricks[x][y].position.y - BRICK_HEIGHT
						}
						if previous_ball_position.x < bricks[x][y].position.x {
							collision_normal += {-1, 0}
							ball_position.x = bricks[x][y].position.x - BRICK_HEIGHT
						}
						if previous_ball_position.x > bricks[x][y].position.x + BRICK_WIDTH {
							collision_normal += {1, 0}
							ball_position.x = bricks[x][y].position.x + BRICK_WIDTH
						}

						if collision_normal != 0 {
							ball_direction = rl.Vector2Normalize(
								linalg.reflect(
									ball_direction,
									rl.Vector2Normalize(collision_normal),
								),
							)
						}
						points += bricks[x][y].points
						bricks[x][y].enabled = false
						rl.PlaySound(brick_sound)
					}
				}

			}
		}


	}

}

draw :: proc() {
	rl.DrawRectangle(0, 0, i32(ARENA_BORDER_SIZE), i32(BRICKS_STARTING_POS.y), GREY)

	rl.DrawRectangle(
		i32(VIEW_PORT_SIZE.x - ARENA_BORDER_SIZE),
		0,
		i32(ARENA_BORDER_SIZE),
		i32(BRICKS_STARTING_POS.y),
		GREY,
	)
	rl.DrawRectangle(
		i32(ARENA_BORDER_SIZE),
		0,
		i32(VIEW_PORT_SIZE.x - (ARENA_BORDER_SIZE * 2)),
		i32(ARENA_BORDER_SIZE),
		GREY,
	)


	arena_color_band_start_y: i32 = i32(BRICKS_STARTING_POS.y - ROW_GAP / 2)
	arena_color_band_height: i32 = i32(BRICK_HEIGHT * 2 + ROW_GAP * 2)
	rl.DrawRectangle(
		0,
		arena_color_band_start_y,
		i32(ARENA_BORDER_SIZE),
		arena_color_band_height,
		RED,
	)
	rl.DrawRectangle(
		i32(VIEW_PORT_SIZE.x - ARENA_BORDER_SIZE),
		arena_color_band_start_y,
		i32(ARENA_BORDER_SIZE),
		arena_color_band_height,
		RED,
	)
	rl.DrawRectangle(
		0,
		arena_color_band_start_y + arena_color_band_height,
		i32(ARENA_BORDER_SIZE),
		arena_color_band_height,
		ORANGE,
	)
	rl.DrawRectangle(
		i32(VIEW_PORT_SIZE.x - ARENA_BORDER_SIZE),
		arena_color_band_start_y + arena_color_band_height,
		i32(ARENA_BORDER_SIZE),
		arena_color_band_height,
		ORANGE,
	)
	rl.DrawRectangle(
		0,
		arena_color_band_start_y + arena_color_band_height * 2,
		i32(ARENA_BORDER_SIZE),
		arena_color_band_height,
		GREEN,
	)
	rl.DrawRectangle(
		i32(VIEW_PORT_SIZE.x - ARENA_BORDER_SIZE),
		arena_color_band_start_y + arena_color_band_height * 2,
		i32(ARENA_BORDER_SIZE),
		arena_color_band_height,
		GREEN,
	)
	rl.DrawRectangle(
		0,
		arena_color_band_start_y + arena_color_band_height * 3,
		i32(ARENA_BORDER_SIZE),
		arena_color_band_height,
		YELLOW,
	)
	rl.DrawRectangle(
		i32(VIEW_PORT_SIZE.x - ARENA_BORDER_SIZE),
		arena_color_band_start_y + arena_color_band_height * 3,
		i32(ARENA_BORDER_SIZE),
		arena_color_band_height,
		YELLOW,
	)
	rl.DrawRectangle(
		0,
		arena_color_band_start_y + arena_color_band_height * 4,
		i32(ARENA_BORDER_SIZE),
		GREY_BAND_HEIGHT_BEFORE_PADDLE_BAND,
		GREY,
	)
	rl.DrawRectangle(
		i32(VIEW_PORT_SIZE.x - ARENA_BORDER_SIZE),
		arena_color_band_start_y + arena_color_band_height * 4,
		i32(ARENA_BORDER_SIZE),
		GREY_BAND_HEIGHT_BEFORE_PADDLE_BAND,
		GREY,
	)
	rl.DrawRectangle(
		0,
		arena_color_band_start_y +
		arena_color_band_height * 4 +
		GREY_BAND_HEIGHT_BEFORE_PADDLE_BAND,
		i32(ARENA_BORDER_SIZE),
		arena_color_band_height,
		BLUE,
	)
	rl.DrawRectangle(
		i32(VIEW_PORT_SIZE.x - ARENA_BORDER_SIZE),
		arena_color_band_start_y +
		arena_color_band_height * 4 +
		GREY_BAND_HEIGHT_BEFORE_PADDLE_BAND,
		i32(ARENA_BORDER_SIZE),
		arena_color_band_height,
		BLUE,
	)

	rl.DrawRectangle(
		0,
		arena_color_band_start_y +
		arena_color_band_height * 5 +
		GREY_BAND_HEIGHT_BEFORE_PADDLE_BAND,
		i32(ARENA_BORDER_SIZE),
		50,
		GREY,
	)
	rl.DrawRectangle(
		i32(VIEW_PORT_SIZE.x - ARENA_BORDER_SIZE),
		arena_color_band_start_y +
		arena_color_band_height * 5 +
		GREY_BAND_HEIGHT_BEFORE_PADDLE_BAND,
		i32(ARENA_BORDER_SIZE),
		50,
		GREY,
	)

	if state == .GAME || state == .READY {
		rl.DrawText("POINTS", 16, 16, 12, GREY)
		rl.DrawText("LIVES", i32(VIEW_PORT_SIZE.x / 2) + 8, 16, 12, GREY)
		points_str := rl.TextFormat("%i", points)
		if points < 100 && points >= 10 {
			points_str = rl.TextFormat("0%i", points)
		}
		if points < 10 {
			points_str = rl.TextFormat("00%i", points)
		}
		rl.DrawText(points_str, 16, 26, 24, GREY)
		rl.DrawText(rl.TextFormat("00%i", lives), i32(VIEW_PORT_SIZE.x / 2) + 8, 26, 24, GREY)

		// Blocks
		for x in 0 ..< MAX_COLUMNS {
			for y in 0 ..< MAX_ROWS {
				if bricks[x][y].enabled {
					rl.DrawRectangle(
						i32(bricks[x][y].position.x),
						i32(bricks[x][y].position.y),
						BRICK_WIDTH,
						BRICK_HEIGHT,
						bricks[x][y].color,
					)
				}

			}
		}

		rl.DrawRectangle(
			i32(paddle_position),
			PADDLE_POSITION_Y,
			i32(paddle_width),
			PADDLE_HEIGHT,
			BLUE,
		)

		rl.DrawRectangle(
			i32(ball_position.x),
			i32(ball_position.y),
			BRICK_HEIGHT,
			BRICK_HEIGHT,
			GREY,
		)
	}

	if state == .READY {
		ready_text: cstring = "Hit 'SPACE' When Ready"
		rl.DrawText(
			ready_text,
			i32(VIEW_PORT_SIZE.x / 2) - rl.MeasureText(ready_text, 12) / 2,
			i32(VIEW_PORT_SIZE.y / 2),
			12,
			GREY,
		)
	}

	if state == .GAME_OVER{
		game_over_text: cstring = "GAME OVER"
		rl.DrawText(
			game_over_text,
			i32(VIEW_PORT_SIZE.x / 2) - rl.MeasureText(game_over_text, 24) / 2,
			34,
			24,
			ORANGE,
		)
		rl.DrawText(
			game_over_text,
			i32(VIEW_PORT_SIZE.x / 2) - rl.MeasureText(game_over_text, 24) / 2,
			33,
			24,
			RED,
		)
		rl.DrawText(
			game_over_text,
			i32(VIEW_PORT_SIZE.x / 2) - rl.MeasureText(game_over_text, 24) / 2,
			32,
			24,
			GREY,
		)
	
		final_score_text: cstring = rl.TextFormat("Final Score: %d",points)
		rl.DrawText(
			final_score_text,
			i32(VIEW_PORT_SIZE.x / 2) - rl.MeasureText(final_score_text, 12) / 2,
			64,
			12,
			GREY,
		)
		ready_text: cstring = "Hit 'ENTER' To Replay"
		rl.DrawText(
			ready_text,
			i32(VIEW_PORT_SIZE.x / 2) - rl.MeasureText(ready_text, 12) / 2,
			i32(VIEW_PORT_SIZE.y / 2),
			12,
			GREY,
		)
	}

}