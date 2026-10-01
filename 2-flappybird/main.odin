package main

import "core:fmt"
import "core:math/rand"
import "core:sys/darwin/CoreFoundation"
import rl "vendor:raylib"

// Enums
State :: enum {
	TITLE,
	GAME,
	GAME_OVER,
}

// Structs
Player :: struct {
	position:        rl.Vector2,
	texture_offset:  rl.Vector2,
	collider_size:   rl.Vector2,
	collider_offset: rl.Vector2,
	velocity:        rl.Vector2,
}

Obstacle :: struct {
	position:               rl.Vector2,
	top_position:           rl.Vector2,
	top_collider_size:      rl.Vector2,
	top_collider_offset:    rl.Vector2,
	bottom_position:        rl.Vector2,
	bottom_collider_size:   rl.Vector2,
	bottom_collider_offset: rl.Vector2,
	score_enabled:          bool,
}


// Constants
SCREEN_SIZE: rl.Vector2 : {720, 1280}
VIEW_PORT_SIZE: rl.Vector2 : {180, 320}
PLAYER_START_POS: rl.Vector2 : {32, VIEW_PORT_SIZE.y / 2}
GRAVITY :: 9.0
MAX_OBSTACLES :: 4
TOP_OBSTACLE_ALIGN_FIX :: 22
TOP_BOTTOM_OBSTACLE_GAP :: 86
OBSTACLE_RESET_X_POS :: VIEW_PORT_SIZE.x
OBSTACLE_HEIGHT_LIMIT :: 86
SPREAD_BETWEEN_OBSTACLES :: VIEW_PORT_SIZE.x / 2
SCORE_FONT_SIZE :: 28
FLOOR_HEIGHT :: 48

// Vars
player: Player
obstacle: Obstacle
obstacles: [MAX_OBSTACLES]Obstacle


cloud1_pos: rl.Vector2
cloud2_pos: rl.Vector2 = {VIEW_PORT_SIZE.x, 0}
clouds_move_speed: f32 = 5

buildings1_pos: rl.Vector2 = {0, 0}
buildings2_pos: rl.Vector2 = {VIEW_PORT_SIZE.x, 0}
buildings_move_speed: f32 = 20

ground1_pos: rl.Vector2 = {0, 0}
ground2_pos: rl.Vector2 = {VIEW_PORT_SIZE.x, 0}
ground_move_speed: f32 = 40


tex_sky: rl.Texture2D
tex_clouds: rl.Texture2D
tex_ground: rl.Texture2D
tex_buildings: rl.Texture2D
tex_pipe: rl.Texture2D
tex_pilot: rl.Texture2D
tex_logo: rl.Texture2D

fnt_game: rl.Font

camera: rl.Camera2D

floor_hazard: rl.Rectangle = {
	x      = 0,
	y      = VIEW_PORT_SIZE.y - FLOOR_HEIGHT,
	width  = VIEW_PORT_SIZE.x,
	height = FLOOR_HEIGHT,
}


debug_on: bool = false
jump_pressed: bool = false

start_game: bool = true
score: i32 = 0
state: State = .TITLE

main :: proc() {
	// Initialization
	rl.SetConfigFlags({.VSYNC_HINT})
	rl.InitWindow(i32(SCREEN_SIZE.x), i32(SCREEN_SIZE.y), "Flappy Bird")
	rl.SetTargetFPS(60)

	create()

	// Core Game Loop
	for !rl.WindowShouldClose() {

		dt := rl.GetFrameTime()

		update(dt)
		collision_check()

		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)
		rl.BeginMode2D(camera)


		draw()

		rl.EndMode2D()
		rl.EndDrawing()
	}

	// Clean Up
	rl.UnloadTexture(tex_sky)
	rl.UnloadTexture(tex_buildings)
	rl.UnloadTexture(tex_clouds)
	rl.UnloadTexture(tex_ground)
	rl.UnloadTexture(tex_pilot)
	rl.UnloadTexture(tex_pipe)
	rl.UnloadTexture(tex_logo)
	rl.UnloadFont(fnt_game)
	rl.CloseWindow()
}

create :: proc() {

	// Load Fonts
	fnt_game = rl.LoadFontEx("ithaca.ttf", SCORE_FONT_SIZE, nil, 0)
	rl.SetTextureFilter(rl.GetFontDefault().texture, .POINT)
	rl.SetTextureFilter(fnt_game.texture, .POINT)

	// Load Textures
	tex_sky = rl.LoadTexture("tex_sky.png")
	tex_clouds = rl.LoadTexture("tex_clouds.png")
	tex_ground = rl.LoadTexture("tex_ground.png")
	tex_buildings = rl.LoadTexture("tex_buildings.png")
	tex_pipe = rl.LoadTexture("tex_pipe.png")
	tex_pilot = rl.LoadTexture("tex_pilot.png")
	tex_logo = rl.LoadTexture("logo.png")

	// Setup Camera
	camera.zoom = SCREEN_SIZE.x / VIEW_PORT_SIZE.x

	reset_game()

}

update :: proc(dt: f32) {
	if state != .GAME_OVER {
		cloud1_pos.x -= clouds_move_speed * dt
		if cloud1_pos.x < -VIEW_PORT_SIZE.x {
			cloud1_pos.x = VIEW_PORT_SIZE.x
		}

		cloud2_pos.x -= clouds_move_speed * dt
		if cloud2_pos.x < -VIEW_PORT_SIZE.x {
			cloud2_pos.x = VIEW_PORT_SIZE.x
		}

		buildings1_pos.x -= buildings_move_speed * dt
		if buildings1_pos.x < -f32(tex_buildings.width) {
			buildings1_pos.x = VIEW_PORT_SIZE.x
		}

		buildings2_pos.x -= buildings_move_speed * dt
		if buildings2_pos.x < -f32(tex_buildings.width) {
			buildings2_pos.x = VIEW_PORT_SIZE.x
		}

		ground1_pos.x -= ground_move_speed * dt
		if ground1_pos.x < -f32(tex_ground.width) {
			ground1_pos.x = VIEW_PORT_SIZE.x
		}

		ground2_pos.x -= ground_move_speed * dt
		if ground2_pos.x < -f32(tex_ground.width) {
			ground2_pos.x = VIEW_PORT_SIZE.x
		}
	}


	if state == .TITLE {
		if rl.IsKeyPressed(.SPACE) {
			state = .GAME
		}
	}
	if state == .GAME_OVER {
		if rl.IsKeyPressed(.R) {
			reset_game()
			state = .GAME
		}
		if rl.IsKeyPressed(.T) {
			reset_game()
			state = .TITLE
		}
	}

	if state == .GAME {
		for i in 0 ..< MAX_OBSTACLES {
			obstacles[i].position.x -= ground_move_speed * dt
			if obstacles[i].position.x < -OBSTACLE_RESET_X_POS {
				obstacles[i].position.x = VIEW_PORT_SIZE.x
				obstacles[i].position.y = rand.float32_range(
					OBSTACLE_HEIGHT_LIMIT,
					VIEW_PORT_SIZE.y - OBSTACLE_HEIGHT_LIMIT,
				)
				obstacles[i].score_enabled = false
			}
		}

		player.velocity.y += GRAVITY * dt
		player.position += player.velocity

		if rl.IsKeyPressed(.SPACE) {
			player.velocity.y += -5
		}
	}


	player.velocity.y = clamp(player.velocity.y, -3, 100)
	player.position.y = clamp(player.position.y, 0, VIEW_PORT_SIZE.y)
}


draw :: proc() {

	rl.DrawTexture(tex_sky, 0, 0, rl.WHITE)

	// Clouds
	rl.DrawTexture(tex_clouds, i32(cloud1_pos.x), i32(cloud1_pos.y), rl.WHITE)
	rl.DrawTexture(tex_clouds, i32(cloud2_pos.x), i32(cloud2_pos.y), rl.WHITE)

	// Building
	rl.DrawTexture(tex_buildings, i32(buildings1_pos.x), i32(buildings1_pos.y), rl.WHITE)
	rl.DrawTexture(tex_buildings, i32(buildings2_pos.x), i32(buildings2_pos.y), rl.WHITE)

	draw_obstacles()

	// Ground
	rl.DrawTexture(tex_ground, i32(ground1_pos.x), i32(ground1_pos.y), rl.WHITE)
	rl.DrawTexture(tex_ground, i32(ground2_pos.x), i32(ground2_pos.y), rl.WHITE)


	// Player
	if state != .GAME_OVER {
		rl.DrawTextureEx(
			tex_pilot,
			{
				player.position.x + player.texture_offset.x,
				player.position.y + player.texture_offset.y,
			},
			player.velocity.y * 5,
			1,
			rl.WHITE,
		)
	}


	if state == .TITLE {
		rl.DrawTexture(tex_logo, i32(VIEW_PORT_SIZE.x / 2) - tex_logo.width / 2, 24, rl.WHITE)

		start_instruction: cstring = "Press 'SPACE' to Start"
		rl.DrawTextEx(
			fnt_game,
			start_instruction,
			{
				VIEW_PORT_SIZE.x / 2 -
				(rl.MeasureTextEx(fnt_game, start_instruction, SCORE_FONT_SIZE / 2, 0)).x / 2,
				VIEW_PORT_SIZE.y / 2 - 31,
			},
			SCORE_FONT_SIZE / 2,
			0,
			rl.BLACK,
		)
		rl.DrawTextEx(
			fnt_game,
			start_instruction,
			{
				VIEW_PORT_SIZE.x / 2 -
				(rl.MeasureTextEx(fnt_game, start_instruction, SCORE_FONT_SIZE / 2, 0)).x / 2,
				VIEW_PORT_SIZE.y / 2 - 32,
			},
			SCORE_FONT_SIZE / 2,
			0,
			rl.WHITE,
		)
	}

	if state == .GAME_OVER {
		game_over_text :: "GAME OVER"
		rl.DrawTextEx(
			fnt_game, 
			game_over_text, 
			{
				VIEW_PORT_SIZE.x / 2 - (rl.MeasureTextEx(fnt_game,game_over_text,28,0)).x/2, 
				49
			}, 
			28, 
			0, 
			rl.BLACK
		)
		rl.DrawTextEx(
			fnt_game, 
			game_over_text, 
			{
				VIEW_PORT_SIZE.x / 2 - (rl.MeasureTextEx(fnt_game,game_over_text,28,0)).x/2, 
				48
			}, 
			28, 
			0, 
			rl.WHITE
		)

		final_score:=rl.TextFormat("Final Score: %i",score)
		rl.DrawTextEx(
			fnt_game, 
			final_score, 
			{
				VIEW_PORT_SIZE.x / 2 - (rl.MeasureTextEx(fnt_game,final_score,14,0)).x/2, 
				76
			}, 
			14, 
			0, 
			{255,128,255,255}
		)
		rl.DrawTextEx(
			fnt_game, 
			final_score, 
			{
				VIEW_PORT_SIZE.x / 2 - (rl.MeasureTextEx(fnt_game,final_score,14,0)).x/2, 
				75
			}, 
			14, 
			0, 
			{128,64,128,255}
		)

		restart_instructions :: "Press 'R' to Try Again"
		rl.DrawTextEx(
			fnt_game, 
			restart_instructions, 
			{
				VIEW_PORT_SIZE.x / 2 - (rl.MeasureTextEx(fnt_game,restart_instructions,14,0)).x/2, 
				129
			}, 
			14, 
			0, 
			rl.BLACK
		)
		rl.DrawTextEx(
			fnt_game, 
			restart_instructions, 
			{
				VIEW_PORT_SIZE.x / 2 - (rl.MeasureTextEx(fnt_game,restart_instructions,14,0)).x/2, 
				128
			}, 
			14, 
			0, 
			rl.WHITE
		)
		title_instructions :: "Press 'T' to Go to Title"
		rl.DrawTextEx(
			fnt_game, 
			title_instructions, 
			{
				VIEW_PORT_SIZE.x / 2 - (rl.MeasureTextEx(fnt_game,title_instructions,14,0)).x/2, 
				149
			}, 
			14, 
			0, 
			rl.BLACK
		)
		rl.DrawTextEx(
			fnt_game, 
			title_instructions, 
			{
				VIEW_PORT_SIZE.x / 2 - (rl.MeasureTextEx(fnt_game,title_instructions,14,0)).x/2, 
				148
			}, 
			14, 
			0, 
			rl.WHITE
		)
	}


	draw_debug()
	draw_player_score()
}

draw_obstacles :: proc() {
	if state != .GAME {
		return
	}
	for i in 0 ..< MAX_OBSTACLES {
		rl.DrawTextureEx(
			tex_pipe,
			{obstacles[i].position.x, obstacles[i].position.y + TOP_BOTTOM_OBSTACLE_GAP / 2},
			0,
			1,
			rl.WHITE,
		)
		rl.DrawTextureEx(
			tex_pipe,
			{
				obstacles[i].position.x + TOP_OBSTACLE_ALIGN_FIX,
				obstacles[i].position.y - TOP_BOTTOM_OBSTACLE_GAP / 2,
			},
			180,
			1,
			rl.WHITE,
		)
	}
}

draw_player_score :: proc() {
	if state != .GAME {
		return
	}
	score_text := rl.TextFormat("%i", score)
	rl.DrawTextEx(
		fnt_game,
		score_text,
		{
			VIEW_PORT_SIZE.x / 2 -
			(rl.MeasureTextEx(fnt_game, score_text, SCORE_FONT_SIZE, 0).x / 2),
			9,
		},
		28,
		0,
		rl.BLACK,
	)
	rl.DrawTextEx(
		fnt_game,
		score_text,
		{
			VIEW_PORT_SIZE.x / 2 -
			(rl.MeasureTextEx(fnt_game, score_text, SCORE_FONT_SIZE, 0).x / 2),
			8,
		},
		28,
		0,
		rl.WHITE,
	)
}

draw_debug :: proc() {
	if !debug_on {
		return
	}
	rl.DrawRectangle(
		i32(floor_hazard.x),
		i32(floor_hazard.y),
		i32(floor_hazard.width),
		i32(floor_hazard.height),
		{255, 0, 0, 64},
	)
	rl.DrawRectangle(
		i32(player.position.x + player.collider_offset.x),
		i32(player.position.y + player.collider_offset.y),
		i32(player.collider_size.x),
		i32(player.collider_size.y),
		{0, 255, 0, 64},
	)
	rl.DrawPixel(i32(player.position.x), i32(player.position.y), rl.GREEN)

	for i in 0 ..< MAX_OBSTACLES {
		rl.DrawRectangle(
			i32(obstacles[i].position.x + obstacles[i].bottom_collider_offset.x),
			i32(
				obstacles[i].position.y +
				TOP_BOTTOM_OBSTACLE_GAP / 2 +
				obstacles[i].bottom_collider_offset.y,
			),
			i32(obstacles[i].bottom_collider_size.x),
			i32(obstacles[i].bottom_collider_size.y),
			{255, 0, 0, 64},
		)
		rl.DrawRectangle(
			i32(obstacles[i].position.x + obstacles[i].top_collider_offset.x),
			i32(
				obstacles[i].position.y -
				TOP_BOTTOM_OBSTACLE_GAP / 2 +
				obstacles[i].top_collider_offset.y,
			),
			i32(obstacles[i].top_collider_size.x),
			i32(obstacles[i].top_collider_size.y),
			{255, 0, 0, 64},
		)
		rl.DrawRectangle(
			i32(obstacles[i].position.x + obstacles[i].top_collider_offset.x) + tex_pipe.width,
			i32(obstacles[i].position.y - TOP_BOTTOM_OBSTACLE_GAP / 2),
			i32(tex_pipe.width),
			i32(TOP_BOTTOM_OBSTACLE_GAP),
			{0, 0, 255, 64},
		)

		rl.DrawPixel(i32(obstacles[i].position.x), i32(obstacles[i].position.y), rl.RED)
	}
}

collision_check :: proc() {
	// Player vs Score Collider
	player_rec: rl.Rectangle = {
		x      = player.position.x + player.collider_offset.x,
		y      = player.position.y + player.collider_offset.y,
		width  = player.collider_size.x,
		height = player.collider_size.y,
	}
	for i in 0 ..< MAX_OBSTACLES {
		score_rec: rl.Rectangle = {
			x      = obstacles[i].position.x + obstacles[i].top_collider_offset.x + f32(tex_pipe.width),
			y      = obstacles[i].position.y - TOP_BOTTOM_OBSTACLE_GAP / 2,
			width  = f32(tex_pipe.width),
			height = TOP_BOTTOM_OBSTACLE_GAP,
		}

		top_pipe_rec: rl.Rectangle = {
			x      = obstacles[i].position.x + obstacles[i].top_collider_offset.x,
			y      = obstacles[i].position.y - TOP_BOTTOM_OBSTACLE_GAP / 2 + obstacles[i].top_collider_offset.y,
			width  = obstacles[i].top_collider_size.x,
			height = obstacles[i].top_collider_size.y,
		}
		if rl.CheckCollisionRecs(player_rec, top_pipe_rec) {
			end_game()
		}
		bottom_pipe_rec: rl.Rectangle = {
			x      = obstacles[i].position.x + obstacles[i].bottom_collider_offset.x,
			y      = obstacles[i].position.y + TOP_BOTTOM_OBSTACLE_GAP / 2 + obstacles[i].bottom_collider_offset.y,
			width  = obstacles[i].bottom_collider_size.x,
			height = obstacles[i].bottom_collider_size.y,
		}
		if rl.CheckCollisionRecs(player_rec, bottom_pipe_rec) {
			end_game()
		}
		floor_hazard: rl.Rectangle = {
			x      = floor_hazard.x,
			y      = floor_hazard.y,
			width  = floor_hazard.width,
			height = floor_hazard.height,
		}
		if rl.CheckCollisionRecs(player_rec, floor_hazard) {
			end_game()
		}

		if rl.CheckCollisionRecs(player_rec, score_rec) {
			if !obstacles[i].score_enabled {
				obstacles[i].score_enabled = true
				score += 1
			}
		}


	}
}

end_game :: proc() {
	state = .GAME_OVER
}

reset_game :: proc() {
	score = 0
	// Setup Player
	player.position = PLAYER_START_POS
	player.collider_size = {42, 13}
	player.texture_offset = {-f32(tex_pilot.width / 2), -f32(tex_pilot.height / 2)}
	player.collider_offset = player.texture_offset + {0, 6}
	player.velocity = {0, 0}

	// Setup Obstacles
	for i in 0 ..< MAX_OBSTACLES {
		obstacles[i].position = {
			VIEW_PORT_SIZE.x + SPREAD_BETWEEN_OBSTACLES * f32(i),
			rand.float32_range(OBSTACLE_HEIGHT_LIMIT, VIEW_PORT_SIZE.y - OBSTACLE_HEIGHT_LIMIT),
		}
		obstacles[i].bottom_collider_size = {f32(tex_pipe.width), f32(tex_pipe.height)}
		obstacles[i].top_collider_size = {f32(tex_pipe.width), f32(tex_pipe.height)}
		obstacles[i].top_collider_offset = {0, f32(-tex_pipe.height)}
		obstacles[i].score_enabled = false
	}
}
