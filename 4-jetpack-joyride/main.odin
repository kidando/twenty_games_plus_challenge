package main

import "core:fmt"
import "core:math/rand"
import rl "vendor:raylib"

GameState::enum{
	TITLE,
	RUN,
	GAME_OVER
}


VIEWPORT_SIZE: rl.Vector2 : {640, 360}
SCREEN_SIZE: rl.Vector2 : {1280, 720}
GRAVITY :: 9.8
MAX_BULLETS :: 100
CLOUD_SPEED:f32:1
MOUNTAIN_SPEED:f32:5
FOREST_SPEED:f32:20
GRASS_SPEED:f32:65
GROUND_SPEED:f32:95

camera: rl.Camera2D

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

game_state:GameState = .RUN

clouds1_position:rl.Vector2 = {0,0}
clouds2_position:rl.Vector2 = {VIEWPORT_SIZE.x,0}
mountains1_position:rl.Vector2 = {0,0}
mountains2_position:rl.Vector2 = {VIEWPORT_SIZE.x,0}
forest1_position:rl.Vector2 = {0,0}
forest2_position:rl.Vector2 = {VIEWPORT_SIZE.x,0}
grass1_position:rl.Vector2 = {0,0}
grass2_position:rl.Vector2 = {VIEWPORT_SIZE.x,0}
ground1_position:rl.Vector2 = {0,0}
ground2_position:rl.Vector2 = {VIEWPORT_SIZE.x,0}

run_level:i32

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

	rest_run()

	
}

// Input (Every Frame)
input :: proc() {

	// RUN STATE
	if game_state == .TITLE{

	}

	// RUN STATE
	if game_state == .RUN{

	}

	// GAME OVER STATE
	if game_state == .GAME_OVER{

	}
}

// Update Every Frame
update :: proc(dt: f32) {
	// RUN STATE
	if game_state == .TITLE{

	}

	// RUN STATE
	if game_state == .RUN{
		// Parallax Scrolling
		clouds1_position.x -= CLOUD_SPEED * dt * f32(run_level)
		if clouds1_position.x < - VIEWPORT_SIZE.x{
			clouds1_position.x = VIEWPORT_SIZE.x
		}
		clouds2_position.x -= CLOUD_SPEED * dt * f32(run_level)
		if clouds2_position.x < - VIEWPORT_SIZE.x{
			clouds2_position.x = VIEWPORT_SIZE.x
		}

		mountains1_position.x -= MOUNTAIN_SPEED * dt * f32(run_level)
		if mountains1_position.x < - VIEWPORT_SIZE.x{
			mountains1_position.x = VIEWPORT_SIZE.x
		}
		mountains2_position.x -= MOUNTAIN_SPEED * dt * f32(run_level)
		if mountains2_position.x < - VIEWPORT_SIZE.x{
			mountains2_position.x = VIEWPORT_SIZE.x
		}

		forest1_position.x -= FOREST_SPEED * dt * f32(run_level)
		if forest1_position.x < - VIEWPORT_SIZE.x{
			forest1_position.x = VIEWPORT_SIZE.x
		}
		forest2_position.x -= FOREST_SPEED * dt * f32(run_level)
		if forest2_position.x < - VIEWPORT_SIZE.x{
			forest2_position.x = VIEWPORT_SIZE.x
		}

		grass1_position.x -= GRASS_SPEED * dt * f32(run_level)
		if grass1_position.x < - VIEWPORT_SIZE.x{
			grass1_position.x = VIEWPORT_SIZE.x
		}
		grass2_position.x -= GRASS_SPEED * dt * f32(run_level)
		if grass2_position.x < - VIEWPORT_SIZE.x{
			grass2_position.x = VIEWPORT_SIZE.x
		}

		ground1_position.x -= GROUND_SPEED * dt * f32(run_level)
		if ground1_position.x < - VIEWPORT_SIZE.x{
			ground1_position.x = VIEWPORT_SIZE.x
		}
		ground2_position.x -= GROUND_SPEED * dt * f32(run_level)
		if ground2_position.x < - VIEWPORT_SIZE.x{
			ground2_position.x = VIEWPORT_SIZE.x
		}
	}

	// GAME OVER STATE
	if game_state == .GAME_OVER{

	}
}

// Draw To Scree
draw :: proc() {
	// Draw Background Objects
	rl.DrawTexture(tex_clouds,i32(clouds1_position.x),i32(clouds1_position.y),rl.WHITE)
	rl.DrawTexture(tex_clouds,i32(clouds2_position.x),i32(clouds2_position.y),rl.WHITE)
	rl.DrawTexture(tex_mountains,i32(mountains1_position.x),i32(mountains1_position.y),rl.WHITE)
	rl.DrawTexture(tex_mountains,i32(mountains2_position.x),i32(mountains2_position.y),rl.WHITE)
	rl.DrawTexture(tex_forest,i32(forest1_position.x),i32(forest1_position.y),rl.WHITE)
	rl.DrawTexture(tex_forest,i32(forest2_position.x),i32(forest2_position.y),rl.WHITE)
	rl.DrawTexture(tex_grass,i32(grass1_position.x),i32(grass1_position.y),rl.WHITE)
	rl.DrawTexture(tex_grass,i32(grass2_position.x),i32(grass2_position.y),rl.WHITE)
	rl.DrawTexture(tex_ground,i32(ground1_position.x),i32(ground1_position.y),rl.WHITE)
	rl.DrawTexture(tex_ground,i32(ground2_position.x),i32(ground2_position.y),rl.WHITE)
	// RUN STATE
	if game_state == .TITLE{

	}

	// RUN STATE
	if game_state == .RUN{

	}

	// GAME OVER STATE
	if game_state == .GAME_OVER{

	}
}

// Draw Debug Lines and Shapes
draw_debug :: proc() {
	// RUN STATE
	if game_state == .TITLE{

	}

	// RUN STATE
	if game_state == .RUN{

	}

	// GAME OVER STATE
	if game_state == .GAME_OVER{

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


rest_run::proc(){
	run_level = 1
}
