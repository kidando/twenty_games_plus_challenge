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

Spike :: struct {
	spawned:  bool,
	position: rl.Vector2,
}

Coin :: struct {
	spawned:         bool,
	position:        rl.Vector2,
	current_frame:   i32,
	animation_timer: f32,
}

Bullet :: struct {
	spawned:  bool,
	position: rl.Vector2,
}

Spark :: struct {
	spawned:         bool,
	position:        rl.Vector2,
	current_frame:   i32,
	animation_timer: f32,
}

GAME_TITLE: cstring : "Jetpack Tester"

DEBUG_OPACITY :: 128

VIEWPORT_SIZE: rl.Vector2 : {640, 360}
SCREEN_SIZE: rl.Vector2 : {1280, 720}

GRAVITY :: 9.8

MAX_BULLETS :: 250
MAX_SPIKES :: 50
MAX_COINS :: 50

CLOUD_SPEED: f32 : 1
MOUNTAIN_SPEED: f32 : 5
FOREST_SPEED: f32 : 20
GRASS_SPEED: f32 : 65
GROUND_SPEED: f32 : 95

DEFAULT_FONT_SIZE :: 56
GAME_OVER_FONT_SIZE :: 28
GUI_FONT_SIZE :: 14

PLAYER_RUN_START_POSITION: rl.Vector2 : {108, 64}
PLAYER_SPRITE_SIZE: f32 : 32
PLAYER_TEXTURE_ORIGIN: rl.Vector2 : {16, 16}
PLAYER_COLLIDER_SIZE: rl.Vector2 : {13, 29}
PLAYER_COLLIDER_OFFSET: rl.Vector2 : {6, 13}
PLAYER_RUN_ANIM_MAX_FRAMES: i32 : 8
PLAYER_RUN_FRAME_DURATION: f32 : 0.1
PLAYER_JET_PACK_FORCE: f32 : 150
PLAYER_ROTATION_SPEED: f32 : 300

BULLET_SPAWN_POSITION: rl.Vector2 : {-6, 8}
BULLET_VELOCITY: rl.Vector2 : {-0.2, 1}
BULLET_RESET_POSITION: rl.Vector2 : {-64, -64}
BULLET_SPEED: f32 : 250
BULLET_SPRITE_SIZE: f32 : 16
BULLET_TEXTURE_ORIGIN: rl.Vector2 : {8, 8}
BULLET_ROTATION: f32 : 90
BULLET_COLLISION_SIZE: rl.Vector2 : {8, 16}
BULLET_COLLISION_OFFSET: rl.Vector2 : {-4, -8}

SPARKS_ANIM_SPEED: f32 : 0.1
SPARKS_SPRITE_SIZE: f32 : 32
SPARKS_TEXTURE_ORIGIN: rl.Vector2 : {16, 16}
MAX_SPARKS_FRAMES: i32 : 5

ITEM_SPRITE_SIZE: f32 : 32
ITEM_TEXTURE_ORIGIN: rl.Vector2 = {16, 16}
ITEM_VELOCITY: rl.Vector2 : {-1, 0}
ITEM_SPEED: f32 : 90
ITEM_DE_SPAWN_POINT: f32 : -64
ITEM_RESET_POSITION: rl.Vector2 : {VIEWPORT_SIZE.x, 0}

SPIKE_COLLIDER_SIZE: rl.Vector2 : {24, 24}
SPIKE_COLLIDER_OFFSET: rl.Vector2 : {12, 12}

COIN_COLLIDER_SIZE: rl.Vector2 : {32, 32}
COIN_COLLIDER_OFFSET: rl.Vector2 : {16, 16}
MAX_COIN_FRAMES :: 8
COINS_ANIM_SPEED: f32 : 0.1

FLOOR_POSITION: f32 = 294

PIXELS_PER_METER: f32 : 0.5

camera: rl.Camera2D
debug_on: bool = false

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
fnt_main: rl.Font
snd_jetpack: rl.Sound
snd_coin: rl.Sound
snd_game_over: rl.Sound
snd_bullet_hit: rl.Sound

game_state: GameState = .TITLE

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
player_current_frame: i32
player_anim_run_timer: f32

// Spikes
spikes: [MAX_SPIKES]Spike
spike_spawn_rate: f32
spike_spawn_timer: f32

// Coins
coins: [MAX_COINS]Coin
coin_spawn_rate: f32
coin_spawn_timer: f32


distance_covered: i32
coins_collected: i32
hi_score: i32
final_score: i32
pixels_covered: f32
divisible_by: i32

bullets: [MAX_BULLETS]Bullet
sparks: [MAX_BULLETS]Spark


main :: proc() {
	rl.SetConfigFlags({.VSYNC_HINT})
	rl.InitWindow(i32(SCREEN_SIZE.x), i32(SCREEN_SIZE.y), GAME_TITLE)
	rl.InitAudioDevice()
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
	rl.CloseAudioDevice()
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
	fnt_main = rl.LoadFontEx("./fonts/upheavtt.ttf", DEFAULT_FONT_SIZE, nil, 0)
	snd_jetpack = rl.LoadSound("./sounds/snd_jetpack.wav")
	snd_coin = rl.LoadSound("./sounds/snd_pick_coin.wav")
	snd_game_over = rl.LoadSound("./sounds/snd_game_over.wav")
	snd_bullet_hit = rl.LoadSound("./sounds/snd_bullet_hit.wav")

	rl.SetTextureFilter(fnt_main.texture, .POINT)

	player_animation_source_positions[.IDLE] = {0, PLAYER_SPRITE_SIZE}
	player_animation_source_positions[.RUN] = {PLAYER_SPRITE_SIZE, PLAYER_SPRITE_SIZE}
	player_animation_source_positions[.FLY] = {PLAYER_SPRITE_SIZE * 9, PLAYER_SPRITE_SIZE}
	player_animation_source_positions[.DEAD] = {PLAYER_SPRITE_SIZE * 10, PLAYER_SPRITE_SIZE}


	reset_run()


}

// Input (Every Frame)
input :: proc() {

	// RUN STATE
	if game_state == .TITLE {
		if rl.IsKeyPressed(.SPACE){
			game_state = .RUN
		}
	}

	// RUN STATE
	if game_state == .RUN {
		input_player_in_game_state_run()
	}

	// GAME OVER STATE
	if game_state == .GAME_OVER {
		input_player_in_game_state_game_over()
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
		update_spikes_in_game_state_run(dt)
		update_coins_in_game_state_run(dt)
		update_bullets_in_game_state_run(dt)
		update_sparks_in_game_state_run(dt)
	}

	// GAME OVER STATE
	if game_state == .GAME_OVER {
		update_player_in_game_state_game_over(dt)
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

	if game_state == .TITLE {
		draw_title()
	}

	// RUN STATE
	if game_state == .RUN {
		draw_bullets()
		draw_player()
		draw_spikes()
		draw_coins()
		draw_sparks()
		draw_game_hud()
	}

	// GAME OVER STATE
	if game_state == .GAME_OVER {
		display_game_over()
	}
}

// Draw Debug Lines and Shapes
draw_debug :: proc() {
	if !debug_on {
		return
	}

	// RUN STATE
	if game_state == .TITLE {
		draw_debug_player()
	}

	// RUN STATE
	if game_state == .RUN {
		draw_debug_player()
		draw_debug_spikes()
		draw_debug_coins()
		draw_debug_bullets()
		draw_debug_sparks()
	}

	// GAME OVER STATE
	if game_state == .GAME_OVER {
		draw_player()
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
	rl.UnloadFont(fnt_main)
	rl.UnloadSound(snd_bullet_hit)
	rl.UnloadSound(snd_coin)
	rl.UnloadSound(snd_game_over)
	rl.UnloadSound(snd_jetpack)
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
		x      = player_animation_source_position.x + f32(player_current_frame) * PLAYER_SPRITE_SIZE,
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


reset_run :: proc() {
	run_level = 1
	player_position = PLAYER_RUN_START_POSITION
	player_rotation = 0
	player_velocity = {0, 0}
	player_is_on_floor = false
	player_state = .FLY
	player_animation_source_position = player_animation_source_positions[.FLY]
	player_current_frame = 0
	spike_spawn_rate = 2
	coin_spawn_rate = 5.73
	spike_spawn_timer = 0
	coin_spawn_timer = 0
	distance_covered = 0
	coins_collected = 0
	pixels_covered = 0
	divisible_by = 100

	// Initialize Spikes
	for i in 0 ..< MAX_SPIKES {
		spikes[i].spawned = false
		spikes[i].position = ITEM_RESET_POSITION
	}

	// Initialize Coins
	for i in 0 ..< MAX_COINS {
		coins[i].spawned = false
		coins[i].position = ITEM_RESET_POSITION
		coins[i].current_frame = rand.int32_range(0, 7)
	}

	// Initialize bullet pool
	for i in 0 ..< MAX_BULLETS {
		bullets[i].spawned = false
		bullets[i].position = BULLET_RESET_POSITION

		sparks[i].spawned = false
		sparks[i].position = BULLET_RESET_POSITION
		sparks[i].current_frame = 0
		sparks[i].animation_timer = 0
	}
}

input_player_in_game_state_run :: proc() {
	if rl.IsKeyDown(.SPACE) {
		player_velocity.y = -PLAYER_JET_PACK_FORCE
		if !rl.IsSoundPlaying(snd_jetpack) {
			rl.PlaySound(snd_jetpack)
			for i in 0 ..< MAX_BULLETS {
				if !bullets[i].spawned {
					bullets[i].spawned = true
					bullets[i].position = {
						player_position.x + BULLET_SPAWN_POSITION.x,
						player_position.y + BULLET_SPAWN_POSITION.y,
					}
					break
				}
			}
		}
	}
}

update_player_in_game_state_run :: proc(dt: f32) {


	pixels_covered += dt
	if pixels_covered >= PIXELS_PER_METER {
		pixels_covered = 0
		distance_covered += 1
		if distance_covered % divisible_by == 0 {
			run_level += 1
			divisible_by *= 2
		}
	}

	player_anim_run_timer += dt
	if player_anim_run_timer >= PLAYER_RUN_FRAME_DURATION / f32(run_level) {
		player_anim_run_timer = 0
		if player_state == .RUN {
			player_current_frame += 1
			if player_current_frame == PLAYER_RUN_ANIM_MAX_FRAMES {
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
		if player_state != .RUN {
			player_state = .RUN
		}
	}

	if player_is_on_floor && player_position.y < FLOOR_POSITION {
		player_is_on_floor = false
		player_state = .FLY
	}

	player_position += player_velocity * dt

	player_position.y = clamp(player_position.y, PLAYER_RUN_START_POSITION.y, FLOOR_POSITION)
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

update_player_in_game_state_game_over :: proc(dt: f32) {
	if player_state != .DEAD {
		player_state = .DEAD
	}
	player_rotation += PLAYER_ROTATION_SPEED * dt
}

update_spikes_in_game_state_run :: proc(dt: f32) {
	spike_spawn_timer += dt
	if spike_spawn_timer >= spike_spawn_rate / f32(run_level) {
		spike_spawn_timer = 0
		for i in 0 ..< MAX_SPIKES {
			if !spikes[i].spawned {
				spikes[i].spawned = true
				spikes[i].position = {
					VIEWPORT_SIZE.x,
					rand.float32_range(PLAYER_RUN_START_POSITION.y, FLOOR_POSITION),
				}
				break
			}
		}
	}

	for i in 0 ..< MAX_SPIKES {
		if spikes[i].spawned {
			spikes[i].position += ITEM_VELOCITY * ITEM_SPEED * f32(run_level) * dt
		}
	}

	// De-spawn Spikes
	for i in 0 ..< MAX_SPIKES {
		if spikes[i].spawned && spikes[i].position.x < ITEM_DE_SPAWN_POINT {
			spikes[i].spawned = false
			spikes[i].position = ITEM_RESET_POSITION
		}
	}

	// Player Collision With Spikes
	player_rec: rl.Rectangle = {
		x      = player_position.x - PLAYER_COLLIDER_OFFSET.x,
		y      = player_position.y - PLAYER_COLLIDER_OFFSET.y,
		width  = PLAYER_COLLIDER_SIZE.x,
		height = PLAYER_COLLIDER_SIZE.y,
	}
	for i in 0 ..< MAX_SPIKES {
		if spikes[i].spawned {
			spike_collision_rec: rl.Rectangle = {
				x      = spikes[i].position.x - SPIKE_COLLIDER_OFFSET.x,
				y      = spikes[i].position.y - SPIKE_COLLIDER_OFFSET.y,
				width  = SPIKE_COLLIDER_SIZE.x,
				height = SPIKE_COLLIDER_SIZE.y,
			}

			if rl.CheckCollisionRecs(player_rec, spike_collision_rec) {
				game_state = .GAME_OVER
				rl.PlaySound(snd_game_over)
				final_score = (coins_collected * 10) + distance_covered
				if hi_score < final_score {
					hi_score = final_score
				}
			}
		}
	}
}
update_coins_in_game_state_run :: proc(dt: f32) {
	coin_spawn_timer += dt
	if coin_spawn_timer >= coin_spawn_rate / f32(run_level) {
		coin_spawn_timer = 0
		for i in 0 ..< MAX_COINS {
			if !coins[i].spawned {
				coins[i].spawned = true
				coins[i].position = {
					VIEWPORT_SIZE.x,
					rand.float32_range(PLAYER_RUN_START_POSITION.y, FLOOR_POSITION),
				}
				break
			}
		}
	}

	for i in 0 ..< MAX_COINS {
		if coins[i].spawned {
			coins[i].position += ITEM_VELOCITY * ITEM_SPEED * f32(run_level) * dt
			coins[i].animation_timer += dt
			if coins[i].animation_timer >= COINS_ANIM_SPEED {
				coins[i].animation_timer = 0
				coins[i].current_frame += 1
				if coins[i].current_frame == MAX_COIN_FRAMES {
					coins[i].current_frame = 0
				}
			}
		}
	}

	// De-spawn Spikes
	for i in 0 ..< MAX_COINS {
		if coins[i].spawned && coins[i].position.x < ITEM_DE_SPAWN_POINT {
			coins[i].spawned = false
			coins[i].position = ITEM_RESET_POSITION
		}
	}

	// Player Collision With Spikes
	player_rec: rl.Rectangle = {
		x      = player_position.x - PLAYER_COLLIDER_OFFSET.x,
		y      = player_position.y - PLAYER_COLLIDER_OFFSET.y,
		width  = PLAYER_COLLIDER_SIZE.x,
		height = PLAYER_COLLIDER_SIZE.y,
	}
	for i in 0 ..< MAX_COINS {
		if coins[i].spawned {
			coin_collision_rec: rl.Rectangle = {
				x      = coins[i].position.x - SPIKE_COLLIDER_OFFSET.x,
				y      = coins[i].position.y - SPIKE_COLLIDER_OFFSET.y,
				width  = SPIKE_COLLIDER_SIZE.x,
				height = SPIKE_COLLIDER_SIZE.y,
			}

			if rl.CheckCollisionRecs(player_rec, coin_collision_rec) {
				coins_collected += 1
				rl.PlaySound(snd_coin)
				coins[i].position = ITEM_RESET_POSITION
				coins[i].spawned = false
			}
		}
	}
}

update_bullets_in_game_state_run :: proc(dt: f32) {
	for i in 0 ..< MAX_BULLETS {
		if bullets[i].spawned {
			bullets[i].position += BULLET_SPEED * rl.Vector2Normalize(BULLET_VELOCITY) * dt

			if bullets[i].position.y > FLOOR_POSITION {

				// Spawn Sparks
				for i in 0 ..< MAX_BULLETS {
					if !sparks[i].spawned {
						sparks[i].position = bullets[i].position
						sparks[i].spawned = true
						break
					}
				}
				rl.PlaySound(snd_bullet_hit)
				bullets[i].spawned = false
				bullets[i].position = BULLET_RESET_POSITION
			}
		}
	}
}
update_sparks_in_game_state_run :: proc(dt: f32) {
	for i in 0 ..< MAX_BULLETS {
		if sparks[i].spawned {
			sparks[i].animation_timer += dt
			if sparks[i].animation_timer > SPARKS_ANIM_SPEED {
				sparks[i].current_frame += 1
				if sparks[i].current_frame == MAX_SPARKS_FRAMES {
					sparks[i].spawned = false
					sparks[i].position = BULLET_RESET_POSITION
					sparks[i].current_frame = 0
					sparks[i].animation_timer = 0
				}
			}
		}
	}
}


draw_spikes :: proc() {
	for i in 0 ..< MAX_SPIKES {
		if spikes[i].spawned {
			spike_tex_source_rec: rl.Rectangle = {
				x      = 0,
				y      = 0,
				width  = ITEM_SPRITE_SIZE,
				height = ITEM_SPRITE_SIZE,
			}

			spike_dest_rec: rl.Rectangle = {
				x      = spikes[i].position.x,
				y      = spikes[i].position.y,
				width  = ITEM_SPRITE_SIZE,
				height = ITEM_SPRITE_SIZE,
			}
			rl.DrawTexturePro(
				tex_spike,
				spike_tex_source_rec,
				spike_dest_rec,
				ITEM_TEXTURE_ORIGIN,
				0,
				rl.WHITE,
			)
		}
	}
}
draw_coins :: proc() {
	for i in 0 ..< MAX_COINS {
		if coins[i].spawned {
			coin_tex_source_rec: rl.Rectangle = {
				x      = f32(coins[i].current_frame) * ITEM_SPRITE_SIZE,
				y      = 0,
				width  = ITEM_SPRITE_SIZE,
				height = ITEM_SPRITE_SIZE,
			}

			coin_dest_rec: rl.Rectangle = {
				x      = coins[i].position.x,
				y      = coins[i].position.y,
				width  = ITEM_SPRITE_SIZE,
				height = ITEM_SPRITE_SIZE,
			}
			rl.DrawTexturePro(
				tex_coin,
				coin_tex_source_rec,
				coin_dest_rec,
				ITEM_TEXTURE_ORIGIN,
				0,
				rl.WHITE,
			)
		}
	}
}

draw_bullets :: proc() {
	for i in 0 ..< MAX_BULLETS {
		if bullets[i].spawned {
			bullet_source_rec: rl.Rectangle = {
				x      = 0,
				y      = 0,
				width  = BULLET_SPRITE_SIZE,
				height = BULLET_SPRITE_SIZE,
			}
			bullet_destination_rec: rl.Rectangle = {
				x      = bullets[i].position.x,
				y      = bullets[i].position.y,
				width  = BULLET_SPRITE_SIZE,
				height = BULLET_SPRITE_SIZE,
			}
			rl.DrawTexturePro(
				tex_bullet,
				bullet_source_rec,
				bullet_destination_rec,
				BULLET_TEXTURE_ORIGIN,
				BULLET_ROTATION,
				rl.WHITE,
			)
		}
	}

}

draw_sparks :: proc() {
	for i in 0 ..< MAX_BULLETS {
		if sparks[i].spawned {
			sparks_source_rec: rl.Rectangle = {
				x      = f32(sparks[i].current_frame) * SPARKS_SPRITE_SIZE,
				y      = 0,
				width  = SPARKS_SPRITE_SIZE,
				height = SPARKS_SPRITE_SIZE,
			}
			sparks_dest_rec: rl.Rectangle = {
				x      = sparks[i].position.x,
				y      = sparks[i].position.y,
				width  = SPARKS_SPRITE_SIZE,
				height = SPARKS_SPRITE_SIZE,
			}
			rl.DrawTexturePro(
				tex_sparks,
				sparks_source_rec,
				sparks_dest_rec,
				SPARKS_TEXTURE_ORIGIN,
				0,
				rl.WHITE,
			)
		}
	}


}

draw_debug_spikes :: proc() {

	for i in 0 ..< MAX_SPIKES {
		if spikes[i].spawned {


			rl.DrawPixel(
				i32(spikes[i].position.x),
				i32(spikes[i].position.y),
				{255, 0, 0, DEBUG_OPACITY},
			)
			rl.DrawRectangle(
				i32(spikes[i].position.x - SPIKE_COLLIDER_OFFSET.x),
				i32(spikes[i].position.y - SPIKE_COLLIDER_OFFSET.x),
				i32(SPIKE_COLLIDER_SIZE.x),
				i32(SPIKE_COLLIDER_SIZE.y),
				{255, 0, 0, DEBUG_OPACITY},
			)
		}
	}
}
draw_debug_coins :: proc() {
	for i in 0 ..< MAX_COINS {
		if coins[i].spawned {

			rl.DrawPixel(
				i32(coins[i].position.x),
				i32(coins[i].position.y),
				{255, 0, 0, DEBUG_OPACITY},
			)
			rl.DrawRectangle(
				i32(coins[i].position.x - COIN_COLLIDER_OFFSET.x),
				i32(coins[i].position.y - COIN_COLLIDER_OFFSET.x),
				i32(COIN_COLLIDER_SIZE.x),
				i32(COIN_COLLIDER_SIZE.y),
				{0, 0, 255, DEBUG_OPACITY},
			)
		}
	}
}

draw_debug_bullets :: proc() {
	for i in 0 ..< MAX_BULLETS {
		if bullets[i].spawned {
			rl.DrawRectangle(
				i32(bullets[i].position.x + BULLET_COLLISION_OFFSET.x),
				i32(bullets[i].position.y + BULLET_COLLISION_OFFSET.y),
				i32(BULLET_COLLISION_SIZE.x),
				i32(BULLET_COLLISION_SIZE.y),
				{255, 0, 255, DEBUG_OPACITY},
			)
		}
	}

	rl.DrawPixel(
		i32(player_position.x + BULLET_SPAWN_POSITION.x),
		i32(player_position.y + BULLET_SPAWN_POSITION.y),
		{225, 0, 255, 255},
	)
}

draw_debug_sparks :: proc() {
	for i in 0 ..< MAX_BULLETS {
		if sparks[i].spawned {
			rl.DrawPixel(i32(sparks[i].position.x), i32(sparks[i].position.y), rl.BLACK)
		}
	}
}

display_game_over :: proc() {
	game_over_text: cstring = "Game Over"
	rl.DrawTextEx(
		fnt_main,
		game_over_text,
		{
			VIEWPORT_SIZE.x / 2 -
			rl.MeasureTextEx(fnt_main, game_over_text, GAME_OVER_FONT_SIZE, 0).x / 2,
			66,
		},
		GAME_OVER_FONT_SIZE,
		0,
		rl.BLACK,
	)
	rl.DrawTextEx(
		fnt_main,
		game_over_text,
		{
			VIEWPORT_SIZE.x / 2 -
			rl.MeasureTextEx(fnt_main, game_over_text, GAME_OVER_FONT_SIZE, 0).x / 2,
			63,
		},
		GAME_OVER_FONT_SIZE,
		0,
		rl.WHITE,
	)


	distance_covered_str := rl.TextFormat("Distance Traveled: %i m", distance_covered)
	rl.DrawTextEx(
		fnt_main,
		distance_covered_str,
		{
			VIEWPORT_SIZE.x / 2 -
			rl.MeasureTextEx(fnt_main, distance_covered_str, GUI_FONT_SIZE, 0).x / 2,
			102,
		},
		GUI_FONT_SIZE,
		0,
		rl.BLACK,
	)
	rl.DrawTextEx(
		fnt_main,
		distance_covered_str,
		{
			VIEWPORT_SIZE.x / 2 -
			rl.MeasureTextEx(fnt_main, distance_covered_str, GUI_FONT_SIZE, 0).x / 2,
			100,
		},
		GUI_FONT_SIZE,
		0,
		rl.WHITE,
	)


	coins_str := rl.TextFormat("Coins Collected: %i", coins_collected)
	rl.DrawTextEx(
		fnt_main,
		coins_str,
		{VIEWPORT_SIZE.x / 2 - rl.MeasureTextEx(fnt_main, coins_str, GUI_FONT_SIZE, 0).x / 2, 122},
		GUI_FONT_SIZE,
		0,
		rl.BLACK,
	)
	rl.DrawTextEx(
		fnt_main,
		coins_str,
		{VIEWPORT_SIZE.x / 2 - rl.MeasureTextEx(fnt_main, coins_str, GUI_FONT_SIZE, 0).x / 2, 120},
		GUI_FONT_SIZE,
		0,
		{254, 174, 52, 255},
	)

	final_score_str := rl.TextFormat("Final Score: %i", final_score)
	rl.DrawTextEx(
		fnt_main,
		final_score_str,
		{
			VIEWPORT_SIZE.x / 2 -
			rl.MeasureTextEx(fnt_main, final_score_str, GUI_FONT_SIZE, 0).x / 2,
			142,
		},
		GUI_FONT_SIZE,
		0,
		rl.BLACK,
	)
	rl.DrawTextEx(
		fnt_main,
		final_score_str,
		{
			VIEWPORT_SIZE.x / 2 -
			rl.MeasureTextEx(fnt_main, final_score_str, GUI_FONT_SIZE, 0).x / 2,
			140,
		},
		GUI_FONT_SIZE,
		0,
		rl.WHITE,
	)

	rl.DrawTextEx(
		fnt_main,
		final_score_str,
		{
			VIEWPORT_SIZE.x / 2 -
			rl.MeasureTextEx(fnt_main, final_score_str, GUI_FONT_SIZE, 0).x / 2,
			140,
		},
		GUI_FONT_SIZE,
		0,
		rl.WHITE,
	)


	hi_score := rl.TextFormat("Hi-Score: %i", hi_score)
	rl.DrawTextEx(
		fnt_main,
		hi_score,
		{VIEWPORT_SIZE.x / 2 - rl.MeasureTextEx(fnt_main, hi_score, GUI_FONT_SIZE, 0).x / 2, 162},
		GUI_FONT_SIZE,
		0,
		rl.BLACK,
	)
	rl.DrawTextEx(
		fnt_main,
		hi_score,
		{VIEWPORT_SIZE.x / 2 - rl.MeasureTextEx(fnt_main, hi_score, GUI_FONT_SIZE, 0).x / 2, 160},
		GUI_FONT_SIZE,
		0,
		{99, 199, 77, 255},
	)


	restart_game_str: cstring = "Press 'SPACE' to restart"
	rl.DrawTextEx(
		fnt_main,
		restart_game_str,
		{
			VIEWPORT_SIZE.x / 2 -
			rl.MeasureTextEx(fnt_main, restart_game_str, GUI_FONT_SIZE, 0).x / 2,
			202,
		},
		GUI_FONT_SIZE,
		0,
		rl.BLACK,
	)
	rl.DrawTextEx(
		fnt_main,
		restart_game_str,
		{
			VIEWPORT_SIZE.x / 2 -
			rl.MeasureTextEx(fnt_main, restart_game_str, GUI_FONT_SIZE, 0).x / 2,
			200,
		},
		GUI_FONT_SIZE,
		0,
		rl.WHITE,
	)
}


input_player_in_game_state_game_over :: proc() {
	if rl.IsKeyPressed(.SPACE) {
		reset_run()
		game_state = .RUN
	}
}

draw_game_hud :: proc() {

	distance_covered_str := rl.TextFormat("%i m", distance_covered)
	distance_covered_len_vec := rl.MeasureTextEx(fnt_main, distance_covered_str, GUI_FONT_SIZE, 0)
	rl.DrawRectangleRec(
		{
			x = VIEWPORT_SIZE.x - distance_covered_len_vec.x - 39,
			y = 8,
			width = distance_covered_len_vec.x + 13,
			height = distance_covered_len_vec.y + 1,
		},
		rl.BLACK,
	)
	rl.DrawTextEx(
		fnt_main,
		distance_covered_str,
		{(VIEWPORT_SIZE.x - 32) - distance_covered_len_vec.x, 8},
		GUI_FONT_SIZE,
		0,
		rl.WHITE,
	)
}


draw_title :: proc() {
	rl.DrawTextEx(
		fnt_main, 
		GAME_TITLE, 
		{
			(VIEWPORT_SIZE.x / 2)-(rl.MeasureTextEx(fnt_main,GAME_TITLE,28,0).x/2), 
			52
		}, 
		28, 
		0, 
		rl.WHITE
	)
	rl.DrawTextEx(
		fnt_main, 
		GAME_TITLE, 
		{
			(VIEWPORT_SIZE.x / 2)-(rl.MeasureTextEx(fnt_main,GAME_TITLE,28,0).x/2), 
			50
		}, 
		28, 
		0, 
		{254,174,52,255}
	)
	rl.DrawTextEx(
		fnt_main, 
		GAME_TITLE, 
		{
			(VIEWPORT_SIZE.x / 2)-(rl.MeasureTextEx(fnt_main,GAME_TITLE,28,0).x/2), 
			48
		}, 
		28, 
		0, 
		rl.BLACK
	)

	start_text:cstring:"Press 'SPACE' to Start"

	rl.DrawTextEx(
		fnt_main, 
		start_text, 
		{
			(VIEWPORT_SIZE.x / 2)-(rl.MeasureTextEx(fnt_main,start_text,14,0).x/2), 
			(VIEWPORT_SIZE.y/2)+2
		}, 
		14, 
		0, 
		rl.BLACK
	)
	rl.DrawTextEx(
		fnt_main, 
		start_text, 
		{
			(VIEWPORT_SIZE.x / 2)-(rl.MeasureTextEx(fnt_main,start_text,14,0).x/2), 
			VIEWPORT_SIZE.y/2
		}, 
		14, 
		0, 
		rl.WHITE
	)
}
