package main

import "core:fmt"
import "core:math/rand"
import rl "vendor:raylib"

GameState :: enum {
	TITLE,
	RUN,
	GAME_OVER,
}

PlayerState :: enum {
	IDLE,
	FLY,
	RUN,
	DEAD,
}

DEBUG_OPACITY :: 128
VIEWPORT_SIZE: rl.Vector2 : {640, 360}
SCREEN_SIZE: rl.Vector2 : {1280, 720}
GRAVITY :: 9.8
MAX_BULLETS :: 100
CLOUD_SPEED: f32 : 1
MOUNTAIN_SPEED: f32 : 5
FOREST_SPEED: f32 : 20
GRASS_SPEED: f32 : 65
GROUND_SPEED: f32 : 95
PLAYER_RUN_START_POSITION: rl.Vector2 : {108, 64}
PLAYER_SPRITE_SIZE: f32 : 32
PLAYER_TEXTURE_ORIGIN: rl.Vector2 : {16, 16}
PLAYER_COLLIDER_SIZE: rl.Vector2 : {13, 29}
PLAYER_COLLIDER_OFFSET: rl.Vector2 : {6, 13}
PLAYER_RUN_ANIM_MAX_FRAMES:i32:8
PLAYER_RUN_FRAME_DURATION:f32:0.1
PLAYER_JET_PACK_FORCE:f32:150
FLOOR_POSITION: f32 = 294

camera: rl.Camera2D
debug_on: bool = true

// Textures
tex_coin: rl.Texture2D
tex_prof: rl.Texture2D
tex_sparks: rl.Texture2D
tex_spike: rl.Texture2D
tex_bullet: rl.Texture2D
tex_clouds: rl.Texture2D
tex_forest: rl.Texture2D
tex_grass: rl.Texture2D
tex_ground: rl.Texture2D
tex_mountains: rl.Texture2D

game_state: GameState = .RUN

clouds1_position: rl.Vector2 = {0, 0}
clouds2_position: rl.Vector2 = {VIEWPORT_SIZE.x, 0}
mountains1_position: rl.Vector2 = {0, 0}
mountains2_position: rl.Vector2 = {VIEWPORT_SIZE.x, 0}
forest1_position: rl.Vector2 = {0, 0}
forest2_position: rl.Vector2 = {VIEWPORT_SIZE.x, 0}
grass1_position: rl.Vector2 = {0, 0}
grass2_position: rl.Vector2 = {VIEWPORT_SIZE.x, 0}
ground1_position: rl.Vector2 = {0, 0}
ground2_position: rl.Vector2 = {VIEWPORT_SIZE.x, 0}

run_level: i32

player_state: PlayerState
player_position: rl.Vector2
player_rotation: f32
player_velocity: rl.Vector2
player_is_on_floor: bool = false
player_animation_source_positions: [PlayerState]rl.Vector2
player_animation_source_position: rl.Vector2
player_current_frame:i32
player_anim_run_timer:f32

main :: proc() {
	rl.SetConfigFlags({.VSYNC_HINT})
	rl.InitWindow(i32(SCREEN_SIZE.x), i32(SCREEN_SIZE.y), "Jetpack Joyride")
	rl.SetTargetFPS(60)
	create()

	for !rl.WindowShouldClose() {
		dt := rl.GetFrameTime()
		input()
		update(dt)
		rl.BeginDrawing()
		rl.ClearBackground({0, 149, 233, 255})
		rl.BeginMode2D(camera)
		draw()
		draw_debug()
		rl.EndMode2D()
		rl.EndDrawing()
	}
	clean_up()
	rl.CloseWindow()
}

create :: proc() {
	camera.zoom = SCREEN_SIZE.x / VIEWPORT_SIZE.x
	tex_prof = rl.LoadTexture("./textures/tex_prof.png")
	tex_coin = rl.LoadTexture("./textures/tex_coin.png")
	tex_sparks = rl.LoadTexture("./textures/tex_sparks.png")
	tex_spike = rl.LoadTexture("./textures/tex_spike.png")
	tex_bullet = rl.LoadTexture("./textures/tex_bullet.png")
	tex_clouds = rl.LoadTexture("./textures/tex_clouds.png")
	tex_forest = rl.LoadTexture("./textures/tex_forest.png")
	tex_grass = rl.LoadTexture("./textures/tex_grass.png")
	tex_ground = rl.LoadTexture("./textures/tex_ground.png")
	tex_mountains = rl.LoadTexture("./textures/tex_mountains.png")

	player_animation_source_positions[.IDLE] = {0, PLAYER_SPRITE_SIZE}
	player_animation_source_positions[.RUN] = {PLAYER_SPRITE_SIZE, PLAYER_SPRITE_SIZE}
	player_animation_source_positions[.FLY] = {PLAYER_SPRITE_SIZE * 9, PLAYER_SPRITE_SIZE}
	player_animation_source_positions[.DEAD] = {PLAYER_SPRITE_SIZE * 10, PLAYER_SPRITE_SIZE}


	rest_run()


}

// Input (Every Frame)
input :: proc() {

	// RUN STATE
	if game_state == .TITLE {

	}

	// RUN STATE
	if game_state == .RUN {
		input_player_in_game_state_run()
	}

	// GAME OVER STATE
	if game_state == .GAME_OVER {

	}
}

// Update Every Frame
update :: proc(dt: f32) {
	player_state_management()

	// RUN STATE
	if game_state == .TITLE {

	}

	// RUN STATE
	if game_state == .RUN {
		update_bg_parallax_in_game_state_run(dt)
		update_player_in_game_state_run(dt)
	}

	// GAME OVER STATE
	if game_state == .GAME_OVER {

	}
}

// Draw To Scree
draw :: proc() {
	// Draw Background Objects
	rl.DrawTexture(tex_clouds, i32(clouds1_position.x), i32(clouds1_position.y), rl.WHITE)
	rl.DrawTexture(tex_clouds, i32(clouds2_position.x), i32(clouds2_position.y), rl.WHITE)
	rl.DrawTexture(tex_mountains, i32(mountains1_position.x), i32(mountains1_position.y), rl.WHITE)
	rl.DrawTexture(tex_mountains, i32(mountains2_position.x), i32(mountains2_position.y), rl.WHITE)
	rl.DrawTexture(tex_forest, i32(forest1_position.x), i32(forest1_position.y), rl.WHITE)
	rl.DrawTexture(tex_forest, i32(forest2_position.x), i32(forest2_position.y), rl.WHITE)
	rl.DrawTexture(tex_grass, i32(grass1_position.x), i32(grass1_position.y), rl.WHITE)
	rl.DrawTexture(tex_grass, i32(grass2_position.x), i32(grass2_position.y), rl.WHITE)
	rl.DrawTexture(tex_ground, i32(ground1_position.x), i32(ground1_position.y), rl.WHITE)
	rl.DrawTexture(tex_ground, i32(ground2_position.x), i32(ground2_position.y), rl.WHITE)
	// RUN STATE
	if game_state == .TITLE {
		draw_player()
	}

	// RUN STATE
	if game_state == .RUN {
		draw_player()
	}

	// GAME OVER STATE
	if game_state == .GAME_OVER {

	}
}

// Draw Debug Lines and Shapes
draw_debug :: proc() {
	if !debug_on{
		return
	}

	// RUN STATE
	if game_state == .TITLE {
		draw_debug_player()
	}

	// RUN STATE
	if game_state == .RUN {
		draw_debug_player()
	}

	// GAME OVER STATE
	if game_state == .GAME_OVER {

	}
}


// Clean Up
clean_up :: proc() {
	rl.UnloadTexture(tex_prof)
	rl.UnloadTexture(tex_coin)
	rl.UnloadTexture(tex_sparks)
	rl.UnloadTexture(tex_spike)
	rl.UnloadTexture(tex_bullet)
	rl.UnloadTexture(tex_clouds)
	rl.UnloadTexture(tex_forest)
	rl.UnloadTexture(tex_grass)
	rl.UnloadTexture(tex_ground)
	rl.UnloadTexture(tex_mountains)
}

player_state_management :: proc() {
	switch player_state {
	case .IDLE:
		if player_animation_source_position != player_animation_source_positions[.IDLE] {
			player_animation_source_position = player_animation_source_positions[.IDLE]
			player_current_frame = 0
		}
	case .RUN:
		if player_animation_source_position != player_animation_source_positions[.RUN] {
			player_animation_source_position = player_animation_source_positions[.RUN]
			player_current_frame = 0
		}
	case .FLY:
		if player_animation_source_position != player_animation_source_positions[.FLY] {
			player_animation_source_position = player_animation_source_positions[.FLY]
			player_current_frame = 0
		}
	case .DEAD:
		if player_animation_source_position != player_animation_source_positions[.DEAD] {
			player_animation_source_position = player_animation_source_positions[.DEAD]
			player_current_frame = 0
		}
	}
}

draw_player :: proc() {
	player_tex_source_rec: rl.Rectangle = {
		x      = player_animation_source_position.x+f32(player_current_frame)*PLAYER_SPRITE_SIZE,
		y      = player_animation_source_position.y,
		width  = PLAYER_SPRITE_SIZE,
		height = PLAYER_SPRITE_SIZE,
	}
	player_dest_rec: rl.Rectangle = {
		x      = player_position.x,
		y      = player_position.y,
		width  = PLAYER_SPRITE_SIZE,
		height = PLAYER_SPRITE_SIZE,
	}
	rl.DrawTexturePro(
		tex_prof,
		player_tex_source_rec,
		player_dest_rec,
		PLAYER_TEXTURE_ORIGIN,
		player_rotation,
		rl.WHITE,
	)
}

draw_debug_player :: proc() {
	rl.DrawPixel(i32(player_position.x), i32(player_position.y), rl.GREEN)
	rl.DrawRectangleRec(
		{
			x = player_position.x - PLAYER_COLLIDER_OFFSET.x,
			y = player_position.y - PLAYER_COLLIDER_OFFSET.y,
			width = PLAYER_COLLIDER_SIZE.x,
			height = PLAYER_COLLIDER_SIZE.y,
		},
		{0, 225, 0, DEBUG_OPACITY},
	)
}


rest_run :: proc() {
	run_level = 1
	player_position = PLAYER_RUN_START_POSITION
	player_rotation = 0
	player_velocity = {0, 0}
	player_is_on_floor = false
	player_state = .FLY
	player_animation_source_position = player_animation_source_positions[.FLY]
	player_current_frame = 0
}

input_player_in_game_state_run::proc(){
	if rl.IsKeyDown(.SPACE){
		player_velocity.y = -PLAYER_JET_PACK_FORCE
	}
}

update_player_in_game_state_run :: proc(dt: f32) {
	player_anim_run_timer += dt
	if player_anim_run_timer >= PLAYER_RUN_FRAME_DURATION/f32(run_level){
		player_anim_run_timer = 0
		if player_state == .RUN{
			player_current_frame += 1
			if player_current_frame == PLAYER_RUN_ANIM_MAX_FRAMES{
				player_current_frame = 0
			}
		}
	}
	
	if !player_is_on_floor {
		player_velocity.y += GRAVITY
	}

	

	if !player_is_on_floor && player_position.y >= FLOOR_POSITION {
		player_is_on_floor = true
		player_velocity.y = 0
		player_position.y = FLOOR_POSITION
		player_state = .RUN
	}

	if player_is_on_floor && player_position.y < FLOOR_POSITION {
		player_is_on_floor = false
		player_state = .FLY
	}

	player_position += player_velocity * dt

	player_position.y = clamp(player_position.y,PLAYER_RUN_START_POSITION.y,FLOOR_POSITION)
}

update_bg_parallax_in_game_state_run :: proc(dt: f32) {
	clouds1_position.x -= CLOUD_SPEED * dt * f32(run_level)
	if clouds1_position.x < -VIEWPORT_SIZE.x {
		clouds1_position.x = VIEWPORT_SIZE.x
	}
	clouds2_position.x -= CLOUD_SPEED * dt * f32(run_level)
	if clouds2_position.x < -VIEWPORT_SIZE.x {
		clouds2_position.x = VIEWPORT_SIZE.x
	}

	mountains1_position.x -= MOUNTAIN_SPEED * dt * f32(run_level)
	if mountains1_position.x < -VIEWPORT_SIZE.x {
		mountains1_position.x = VIEWPORT_SIZE.x
	}
	mountains2_position.x -= MOUNTAIN_SPEED * dt * f32(run_level)
	if mountains2_position.x < -VIEWPORT_SIZE.x {
		mountains2_position.x = VIEWPORT_SIZE.x
	}

	forest1_position.x -= FOREST_SPEED * dt * f32(run_level)
	if forest1_position.x < -VIEWPORT_SIZE.x {
		forest1_position.x = VIEWPORT_SIZE.x
	}
	forest2_position.x -= FOREST_SPEED * dt * f32(run_level)
	if forest2_position.x < -VIEWPORT_SIZE.x {
		forest2_position.x = VIEWPORT_SIZE.x
	}

	grass1_position.x -= GRASS_SPEED * dt * f32(run_level)
	if grass1_position.x < -VIEWPORT_SIZE.x {
		grass1_position.x = VIEWPORT_SIZE.x
	}
	grass2_position.x -= GRASS_SPEED * dt * f32(run_level)
	if grass2_position.x < -VIEWPORT_SIZE.x {
		grass2_position.x = VIEWPORT_SIZE.x
	}

	ground1_position.x -= GROUND_SPEED * dt * f32(run_level)
	if ground1_position.x < -VIEWPORT_SIZE.x {
		ground1_position.x = VIEWPORT_SIZE.x
	}
	ground2_position.x -= GROUND_SPEED * dt * f32(run_level)
	if ground2_position.x < -VIEWPORT_SIZE.x {
		ground2_position.x = VIEWPORT_SIZE.x
	}
}
