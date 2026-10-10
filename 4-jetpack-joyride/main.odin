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

	}

	// GAME OVER STATE
	if game_state == .GAME_OVER{

	}
}

// Draw To Scree
draw :: proc() {
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

