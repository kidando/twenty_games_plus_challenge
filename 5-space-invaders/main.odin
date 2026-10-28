package main

import "core:fmt"
import "core:math/rand"
import rl "vendor:raylib"

EnemyMoveDirection :: enum {
	LEFT,
	RIGHT,
}

Scene :: enum {
	TITLE,
	READY,
	GAME,
	LEVEL_COMPLETED,
	DIED,
	GAME_OVER,
}

Enemy :: struct {
	alive:                bool,
	visible:              bool,
	position:             rl.Vector2,
	texture_atlas_pos:    f32,
	anim_index:           f32,
	death_duration_timer: f32,
	points:               i32,
}

PlayerBullet :: struct {
	visible:  bool,
	position: rl.Vector2,
}

EnemyBullet :: struct {
	visible:    bool,
	position:   rl.Vector2,
	anim_index: f32,
	anim_timer: f32,
}

GAME_TITLE: cstring : "Space Intruders"
SCREEN_SIZE: rl.Vector2 : {720, 1280}
VIEWPORT_SIZE: rl.Vector2 : {180, 320}

MAX_LIVES: i32 : 3

MAX_PLAYER_BULLETS: i32 : 100
MAX_ENEMY_BULLETS: i32 : 100

ENEMY_ROWS: i32 : 5
ENEMY_COLUMNS: i32 : 6
ENEMIES_GAP: rl.Vector2 : {8, 8}
ENEMIES_RESET_POSITION: rl.Vector2 : {16, 48}
ENEMY_SPRITE_SIZE: f32 : 16
ENEMY_TEXTURE_ORIGIN: rl.Vector2 : {-8, -8}
ENEMIES_MOVE_STEP: rl.Vector2 : {4, 12}
ENEMY_MOVE_DELAY: f32 : 0.6
ENEMY_FIRE_RATE_RANGE: rl.Vector2 : {3, 5}
ENEMY_SEARCH_ATTEMPTS: i32 : 30
ENEMY_DEATH_DURATION: f32 : 0.5


ENEMY_BULLET_SPEED :: 65
ENEMY_BULLET_RESET_POSITION: rl.Vector2 : {-64, -64}
ENEMY_BULLET_ANIM_SPEED: f32 : 0.1
ENEMY_BULLET_MAX_FRAMES: i32 : 4
ENEMY_BULLET_TEXTURE_SIZE: rl.Vector2 : {7, 8}
ENEMY_BULLET_TEXTURE_ORIGIN: rl.Vector2 : {-3, -4}
ENEMY_BULLET_COLLISION_SIZE: rl.Vector2 : {5, 6}
ENEMY_BULLET_COLLISION_OFFSET: rl.Vector2 : {-2, -3}

MOTHER_SHIP_TEXTURE_ORIGIN: rl.Vector2 : {8, 8}
MOTHER_SHIP_COLLIDER_SIZE: rl.Vector2 : {16, 8}
MOTHER_SHIP_COLLIDER_OFFSET: rl.Vector2 : {-8, -3}
MOTHER_SHIP_RESET_POSITION: rl.Vector2 : {-16, 32}
MOTHER_SHIP_VELOCITY: rl.Vector2 : {1, 0}
MOTHER_SHIP_SPAWN_RANGE: rl.Vector2 : {20, 25}
MOTHER_SHIP_SPEED: f32 : 30
MOTHER_SHIP_POINTS: i32 : 500
MOTHER_SHIP_DEATH_DURATION: f32 : 0.5

PLAYER_SPRITE_SIZE: rl.Vector2 : {15, 16}
PLAYER_RESET_POSITION: rl.Vector2 : {VIEWPORT_SIZE.x / 2, VIEWPORT_SIZE.y - 32}
PLAYER_TEXTURE_ORIGIN: rl.Vector2 : {7, 8}
PLAYER_COLLISION_SIZE: rl.Vector2 : {15, 14}
PLAYER_COLLISION_OFFSET: rl.Vector2 : {-7, -4}
PLAYER_MOVEMENT_SPEED :: 90
PLAYER_AFTER_DEATH_DURATION: f32 : 1
PLAYER_LEVEL_UP_DURATION: f32 : 1.5

PLAYER_BULLET_SPEED :: 100
PLAYER_BULLET_RESET_POSITION: rl.Vector2 : {-64, VIEWPORT_SIZE.y + 64}
PLAYER_BULLET_SIZE: rl.Vector2 : {1, 5}
PLAYER_BULLET_SPRITE_ORIGIN: rl.Vector2 : {0, -2}
PLAYER_BULLET_RATE_OF_FIRE: f32 : 0.5

BORDER_REC: rl.Rectangle = {
	x      = 0,
	y      = VIEWPORT_SIZE.y - 40,
	width  = VIEWPORT_SIZE.x,
	height = 2,
}

UI_PADDING: f32 : 8
UI_FONT_SIZE: f32 : 6
UI_LINE_HEIGHT: f32 : 12

DEBUG_OPACITY :: 128

GAME_OVER_DURATION: f32 : 3


scene: Scene = .READY

score: i32
hi_score: i32
lives: i32
level: i32

enemies: [ENEMY_ROWS][ENEMY_COLUMNS]Enemy
enemy_group_position: rl.Vector2
enemy_move_timer: f32
enemy_move_direction: EnemyMoveDirection
enemy_can_fire: bool
enemy_fire_rate: f32
enemy_fire_timer: f32

enemy_bullets: [MAX_ENEMY_BULLETS]EnemyBullet
enemy_bullet_velocity: rl.Vector2

player_position: rl.Vector2
player_velocity: rl.Vector2
player_anim_index: i32
player_level_up_timer: f32

player_bullets: [MAX_PLAYER_BULLETS]PlayerBullet
player_bullet_velocity: rl.Vector2
can_fire_player_bullet: bool
player_bullet_fire_timer: f32
player_after_death_timer: f32

tex_enemies: rl.Texture2D
tex_player: rl.Texture2D
tex_enemy_projectile: rl.Texture2D

snd_move_left_right: rl.Sound
snd_move_down: rl.Sound
snd_player_fire: rl.Sound
snd_enemy_dead: rl.Sound
snd_player_dead: rl.Sound
snd_player_levelled_up: rl.Sound
snd_game_over: rl.Sound
snd_projectiles_collide: rl.Sound
snd_mother_ship_appears: rl.Sound
snd_mother_ship_points: rl.Sound

fnt_main: rl.Font

camera: rl.Camera2D

debug_on: bool = false

game_over_duration_timer: f32

mother_ship_position: rl.Vector2
mother_ship_visible: bool
mother_ship_spawn_duration: f32
mother_ship_spawn_timer: f32
mother_ship_anim_index: i32 = 6
mother_ship_death_timer: f32
mother_ship_destroyed: bool


main :: proc() {
	rl.SetConfigFlags({.VSYNC_HINT})
	rl.InitWindow(i32(SCREEN_SIZE.x), i32(SCREEN_SIZE.y), GAME_TITLE)
	rl.InitAudioDevice()
	rl.SetTargetFPS(60)

	init()
	for !rl.WindowShouldClose() {
		input()
		update(rl.GetFrameTime())
		rl.BeginDrawing()
		rl.BeginMode2D(camera)
		rl.ClearBackground(rl.BLACK)
		draw()
		draw_hud()
		draw_debug()
		rl.EndMode2D()
		rl.EndDrawing()
	}
	clean_up()
	rl.CloseAudioDevice()
	rl.CloseWindow()
}

// Start of game
init :: proc() {
	tex_enemies = rl.LoadTexture("./textures/tex_enemies.png")
	tex_player = rl.LoadTexture("./textures/tex_player.png")
	tex_enemy_projectile = rl.LoadTexture("./textures/tex_enemy_projectile.png")

	snd_move_left_right = rl.LoadSound("./sounds/snd_move_left_right.wav")
	snd_move_down = rl.LoadSound("./sounds/snd_move_down.wav")
	snd_player_fire = rl.LoadSound("./sounds/snd_player_fire.wav")
	snd_enemy_dead = rl.LoadSound("./sounds/snd_enemy_dead.wav")
	snd_player_dead = rl.LoadSound("./sounds/snd_player_dead.wav")
	snd_player_levelled_up = rl.LoadSound("./sounds/snd_player_levelled_up.wav")
	snd_game_over = rl.LoadSound("./sounds/snd_game_over.wav")
	snd_projectiles_collide = rl.LoadSound("./sounds/snd_projectiles_collide.wav")
	snd_mother_ship_appears = rl.LoadSound("./sounds/snd_mother_ship_appears.wav")
	snd_mother_ship_points = rl.LoadSound("./sounds/snd_mother_ship_points.wav")

	fnt_main = rl.LoadFontEx("./fonts/press_start.ttf", 64, nil, 0)
	rl.SetTextureFilter(fnt_main.texture, .POINT)

	camera.zoom = SCREEN_SIZE.x / VIEWPORT_SIZE.x

	reset_run()
}

// Input check every frame
input :: proc() {
	switch scene {

	case .TITLE:
	case .READY:
		if rl.IsKeyPressed(.SPACE) {
			scene = .GAME
		}
	case .GAME:
		input_player_in_game_state_game()
	case .LEVEL_COMPLETED:
	case .DIED:
	case .GAME_OVER:

	}
}

// Update data every frame
update :: proc(dt: f32) {
	switch scene {

	case .TITLE:
	case .READY:
	case .GAME:
		update_player_in_game_state_game(dt)
		update_enemies_in_game_state_game(dt)
		update_player_bullets_in_game_state_game(dt)
		update_enemy_bullets_in_game_state_game(dt)
		update_mother_ship_in_game_state_game(dt)
	case .LEVEL_COMPLETED:
		update_player_in_game_state_level_complete(dt)
	case .DIED:
		player_after_death_timer += dt
		if player_after_death_timer >= PLAYER_AFTER_DEATH_DURATION {
			player_after_death_timer = 0
			if lives > 0 {
				enemy_group_position = ENEMIES_RESET_POSITION
				reset_enemies()
				player_anim_index = 0
				player_position = PLAYER_RESET_POSITION
				scene = .READY
			} else {
				if score > hi_score {
					hi_score = score
				}
				game_over_duration_timer = 0
				scene = .GAME_OVER
				rl.PlaySound(snd_game_over)
			}

		}
	case .GAME_OVER:
		update_game_over(dt)

	}
}

// Draw objects to screen (every frame)
draw :: proc() {
	switch scene {

	case .TITLE:
	case .READY:
		draw_player()
		draw_enemies()
		draw_mother_ship()
		draw_border()
	case .GAME:
		draw_player()
		draw_enemies()
		draw_player_bullets()
		draw_enemy_bullets()
		draw_mother_ship()
		draw_border()
	case .LEVEL_COMPLETED:
		draw_player()
	case .DIED:
		draw_player()
		draw_enemies()
		draw_border()
	case .GAME_OVER:

	}


}

draw_debug :: proc() {
	if !debug_on {
		return
	}
	switch scene {

	case .TITLE:
	case .READY:
		draw_debug_mother_ship()
	case .GAME:
		draw_debug_player()
		draw_debug_enemies()
		draw_debug_player_bullets()
		draw_debug_enemy_bullets()
		draw_debug_mother_ship()
	case .LEVEL_COMPLETED:
	case .DIED:
	case .GAME_OVER:

	}
}

// Clean up before close
clean_up :: proc() {
	rl.UnloadTexture(tex_enemies)
	rl.UnloadTexture(tex_player)
	rl.UnloadTexture(tex_enemy_projectile)
	rl.UnloadSound(snd_move_left_right)
	rl.UnloadSound(snd_move_down)
	rl.UnloadSound(snd_player_fire)
	rl.UnloadSound(snd_enemy_dead)
	rl.UnloadSound(snd_player_dead)
	rl.UnloadSound(snd_player_levelled_up)
	rl.UnloadSound(snd_game_over)
	rl.UnloadSound(snd_projectiles_collide)
	rl.UnloadSound(snd_mother_ship_appears)
	rl.UnloadFont(fnt_main)
}

reset_run :: proc() {
	score = 0
	lives = MAX_LIVES
	level = 1
	player_position = PLAYER_RESET_POSITION
	enemy_move_direction = .RIGHT
	player_anim_index = 0
	enemy_group_position = ENEMIES_RESET_POSITION
	enemy_can_fire = false
	enemy_fire_rate = rand.float32_range(ENEMY_FIRE_RATE_RANGE.x, ENEMY_FIRE_RATE_RANGE.y)
	enemy_fire_timer = 0
	player_after_death_timer = 0
	mother_ship_position = MOTHER_SHIP_RESET_POSITION
	mother_ship_spawn_timer = 0
	mother_ship_spawn_duration = rand.float32_range(
		MOTHER_SHIP_SPAWN_RANGE.x,
		MOTHER_SHIP_SPAWN_RANGE.y,
	)
	if rl.IsSoundPlaying(snd_mother_ship_appears) {
		rl.StopSound(snd_mother_ship_appears)
	}
	mother_ship_death_timer = 0
	mother_ship_destroyed = false

	for x in 0 ..< ENEMY_ROWS {
		for y in 0 ..< ENEMY_COLUMNS {
			if x == 0 {
				enemies[x][y].points = 30
			}
			if x == 1 || x == 2 {
				enemies[x][y].points = 20
			}
			if x == 3 || x == 4 {
				enemies[x][y].points = 10
			}
			enemies[x][y].death_duration_timer = 0
			enemies[x][y].alive = true
			enemies[x][y].visible = true
			enemies[x][y].position = enemy_group_position + {f32(y) * (16 + 4), f32(x) * (16 + 4)}
			enemies[x][y].anim_index = 0
		}
	}

	reset_all_projectiles()

	can_fire_player_bullet = true
	player_bullet_fire_timer = 0
}

reset_enemies :: proc(_reset_the_dead: bool = false) {
	mother_ship_position = MOTHER_SHIP_RESET_POSITION
	mother_ship_spawn_timer = 0
	mother_ship_spawn_duration = rand.float32_range(
		MOTHER_SHIP_SPAWN_RANGE.x,
		MOTHER_SHIP_SPAWN_RANGE.y,
	)
	mother_ship_death_timer = 0
	mother_ship_destroyed = false
	if rl.IsSoundPlaying(snd_mother_ship_appears) {
		rl.StopSound(snd_mother_ship_appears)
	}
	enemy_move_direction = .RIGHT
	enemy_can_fire = false
	enemy_fire_rate = rand.float32_range(ENEMY_FIRE_RATE_RANGE.x, ENEMY_FIRE_RATE_RANGE.y)
	enemy_group_position = ENEMIES_RESET_POSITION
	enemy_fire_timer = 0
	for x in 0 ..< ENEMY_ROWS {
		for y in 0 ..< ENEMY_COLUMNS {
			if _reset_the_dead {
				enemies[x][y].alive = true
				enemies[x][y].visible = true
			}
			enemies[x][y].position = enemy_group_position + {f32(y) * (16 + 4), f32(x) * (16 + 4)}
			enemies[x][y].anim_index = 0
		}
	}
}

get_farthest_position_x :: proc(dir: EnemyMoveDirection) -> f32 {

	amt: f32
	if dir == .RIGHT {
		amt = 0
		for x in 0 ..< ENEMY_ROWS {
			for y in 0 ..< ENEMY_COLUMNS {
				if enemies[x][y].visible {
					if enemies[x][y].position.x > amt {
						amt = enemies[x][y].position.x
					}
				}
			}
		}
	}

	if dir == .LEFT {
		amt = VIEWPORT_SIZE.x
		for x in 0 ..< ENEMY_ROWS {
			for y in 0 ..< ENEMY_COLUMNS {
				if enemies[x][y].visible {
					if enemies[x][y].position.x < amt {
						amt = enemies[x][y].position.x
					}
				}
			}
		}
	}
	return amt
}

input_player_in_game_state_game :: proc() {
	player_velocity = {0, 0}
	if rl.IsKeyDown(.A) || rl.IsKeyDown(.LEFT) {
		player_velocity.x = -1
	}
	if rl.IsKeyDown(.D) || rl.IsKeyDown(.RIGHT) {
		player_velocity.x = 1
	}

	if rl.IsKeyDown(.J) || rl.IsKeyDown(.Z) {
		if can_fire_player_bullet {
			rl.PlaySound(snd_player_fire)
			can_fire_player_bullet = false
			for i in 0 ..< MAX_PLAYER_BULLETS {
				if !player_bullets[i].visible {
					player_bullets[i].visible = true
					player_bullets[i].position = player_position
					break
				}
			}
		}
	}
}

update_player_in_game_state_game :: proc(dt: f32) {
	player_position += player_velocity * dt * PLAYER_MOVEMENT_SPEED
	player_position.x = clamp(
		player_position.x,
		PLAYER_SPRITE_SIZE.x / 2,
		VIEWPORT_SIZE.x - PLAYER_SPRITE_SIZE.x / 2,
	)
}

update_enemies_in_game_state_game :: proc(dt: f32) {
	enemy_move_timer += dt
	if enemy_move_timer >= ENEMY_MOVE_DELAY / f32(level)*2 {
		for x in 0 ..< ENEMY_ROWS {
			for y in 0 ..< ENEMY_COLUMNS {
				if enemies[x][y].visible && enemies[x][y].alive {
					if enemies[x][y].anim_index == 0 {
						enemies[x][y].anim_index = 1
					} else {
						enemies[x][y].anim_index = 0
					}
				}

			}
		}
		// 1. Check if enemies are moving left or right
		if enemy_move_direction == .RIGHT {
			// 2. Check for the enemy position.x that is farthest to the right (in the group)
			farthest_right := get_farthest_position_x(enemy_move_direction)
			if farthest_right + ENEMIES_MOVE_STEP.x < VIEWPORT_SIZE.x - ENEMY_SPRITE_SIZE / 2 {
				enemy_group_position.x += ENEMIES_MOVE_STEP.x
				rl.PlaySound(snd_move_left_right)
			} else {
				enemy_group_position.y += ENEMIES_MOVE_STEP.y
				enemy_move_direction = .LEFT
				rl.PlaySound(snd_move_down)
			}
		} else {
			farthest_left := get_farthest_position_x(enemy_move_direction)
			if farthest_left - ENEMIES_MOVE_STEP.x > ENEMY_SPRITE_SIZE / 2 {
				enemy_group_position.x -= ENEMIES_MOVE_STEP.x
				rl.PlaySound(snd_move_left_right)
			} else {
				enemy_group_position.y += ENEMIES_MOVE_STEP.y
				enemy_move_direction = .RIGHT
				rl.PlaySound(snd_move_down)
			}
		}
		enemy_move_timer = 0
	}

	for x in 0 ..< ENEMY_ROWS {
		for y in 0 ..< ENEMY_COLUMNS {
			if enemies[x][y].visible {
				if enemies[x][y].alive {
					enemies[x][y].position =
						enemy_group_position + {f32(y) * (16 + 4), f32(x) * (16 + 4)}

					// Check for collision with border
					enemy_rec: rl.Rectangle = {
						x      = enemies[x][y].position.x + ENEMY_TEXTURE_ORIGIN.y,
						y      = enemies[x][y].position.y + ENEMY_TEXTURE_ORIGIN.y,
						width  = ENEMY_SPRITE_SIZE,
						height = ENEMY_SPRITE_SIZE,
					}
					if rl.CheckCollisionRecs(enemy_rec, BORDER_REC) {
						kill_player()
						break
					}

				} else {
					// Enemy is not alive
					enemies[x][y].death_duration_timer += dt
					if enemies[x][y].death_duration_timer >= ENEMY_DEATH_DURATION {
						enemies[x][y].visible = false
						enemies[x][y].position = {-64, -64}
						check_enemies_remaining()
					}
				}
			}

		}
	}

	if enemy_can_fire {
		enemy_can_fire = false
		enemy_fire_rate = rand.float32_range(ENEMY_FIRE_RATE_RANGE.x, ENEMY_FIRE_RATE_RANGE.y)
		ran_x: i32 = rand.int32_range(0, ENEMY_ROWS)
		ran_y: i32 = rand.int32_range(0, ENEMY_COLUMNS)
		search_for_enemy: bool = true
		attempts: i32 = 0
		for search_for_enemy {
			if enemies[ran_x][ran_y].visible {
				search_for_enemy = false
				// Spawn Bullet
				for i in 0 ..< MAX_ENEMY_BULLETS {
					if !enemy_bullets[i].visible {
						enemy_bullets[i].visible = true
						enemy_bullets[i].position = enemies[ran_x][ran_y].position
						break
					}
				}
			} else {
				ran_x = rand.int32_range(0, ENEMY_ROWS)
				ran_y = rand.int32_range(0, ENEMY_COLUMNS)
				attempts += 1
				if attempts >= ENEMY_SEARCH_ATTEMPTS {
					search_for_enemy = false
				}
			}
		}
	} else {
		enemy_fire_timer += dt
		if enemy_fire_timer >= enemy_fire_rate {
			enemy_fire_timer = 0
			enemy_can_fire = true
		}
	}

}


update_player_bullets_in_game_state_game :: proc(dt: f32) {
	if !can_fire_player_bullet {
		player_bullet_fire_timer += dt
		if player_bullet_fire_timer >= PLAYER_BULLET_RATE_OF_FIRE {
			player_bullet_fire_timer = 0
			can_fire_player_bullet = true
		}
	}
	player_velocity = {0, -1}
	for i in 0 ..< MAX_PLAYER_BULLETS {
		if player_bullets[i].visible {
			player_bullets[i].position += player_velocity * dt * PLAYER_BULLET_SPEED

			bullet_rec: rl.Rectangle = {
				x      = player_bullets[i].position.x + PLAYER_BULLET_SPRITE_ORIGIN.x,
				y      = player_bullets[i].position.y + PLAYER_BULLET_SPRITE_ORIGIN.y,
				width  = PLAYER_BULLET_SIZE.x,
				height = PLAYER_BULLET_SIZE.y,
			}

			// Collision Check With Enemies
			for x in 0 ..< ENEMY_ROWS {
				for y in 0 ..< ENEMY_COLUMNS {
					if enemies[x][y].visible && enemies[x][y].alive {

						enemy_rec: rl.Rectangle = {
							x      = enemies[x][y].position.x + ENEMY_TEXTURE_ORIGIN.y,
							y      = enemies[x][y].position.y + ENEMY_TEXTURE_ORIGIN.y,
							width  = ENEMY_SPRITE_SIZE,
							height = ENEMY_SPRITE_SIZE,
						}

						if rl.CheckCollisionRecs(bullet_rec, enemy_rec) {
							enemies[x][y].alive = false
							player_bullets[i].visible = false
							player_bullets[i].position = PLAYER_BULLET_RESET_POSITION
							rl.PlaySound(snd_enemy_dead)
							score += enemies[x][y].points
							break
						}

					}
				}
			}

			// Collision Check With Enemy Bullets
			for i in 0 ..< MAX_ENEMY_BULLETS {
				if enemy_bullets[i].visible {
					enemy_bullet_rec: rl.Rectangle = {
						x      = enemy_bullets[i].position.x + ENEMY_BULLET_COLLISION_OFFSET.x,
						y      = enemy_bullets[i].position.y + ENEMY_BULLET_COLLISION_OFFSET.y,
						width  = ENEMY_BULLET_COLLISION_SIZE.x,
						height = ENEMY_BULLET_COLLISION_SIZE.y,
					}

					if rl.CheckCollisionRecs(enemy_bullet_rec, bullet_rec) {
						player_bullets[i].visible = false
						player_bullets[i].position = PLAYER_BULLET_RESET_POSITION
						rl.PlaySound(snd_projectiles_collide)
						enemy_bullets[i].visible = false
						enemy_bullets[i].position = ENEMY_BULLET_RESET_POSITION
						enemy_bullets[i].anim_index = 0
						enemy_bullets[i].anim_timer = 0
						score += 5
					}
				}

			}

			if player_bullets[i].position.y == -16 {
				player_bullets[i].visible = false
				player_bullets[i].position = PLAYER_BULLET_RESET_POSITION
			}
		}
	}
}

update_enemy_bullets_in_game_state_game :: proc(dt: f32) {
	for i in 0 ..< MAX_ENEMY_BULLETS {
		if enemy_bullets[i].visible {
			enemy_bullets[i].anim_timer += dt
			if enemy_bullets[i].anim_timer >= ENEMY_BULLET_ANIM_SPEED {
				enemy_bullets[i].anim_timer = 0
				enemy_bullets[i].anim_index += 1
				if enemy_bullets[i].anim_index == f32(ENEMY_BULLET_MAX_FRAMES) {
					enemy_bullets[i].anim_index = 0
				}
			}

			enemy_bullets[i].position += enemy_bullet_velocity * dt * ENEMY_BULLET_SPEED

			player_rec: rl.Rectangle = {
				x      = player_position.x + PLAYER_COLLISION_OFFSET.x,
				y      = player_position.y + PLAYER_COLLISION_OFFSET.y,
				width  = PLAYER_COLLISION_SIZE.x,
				height = PLAYER_COLLISION_SIZE.y,
			}

			bullet_rec: rl.Rectangle = {
				x      = enemy_bullets[i].position.x + ENEMY_BULLET_COLLISION_OFFSET.x,
				y      = enemy_bullets[i].position.y + ENEMY_BULLET_COLLISION_OFFSET.y,
				width  = ENEMY_BULLET_COLLISION_SIZE.x,
				height = ENEMY_BULLET_COLLISION_SIZE.y,
			}

			// Check Collision With Player
			if rl.CheckCollisionRecs(player_rec, bullet_rec) {
				kill_player()
				enemy_bullets[i].visible = false
				enemy_bullets[i].position = ENEMY_BULLET_RESET_POSITION
			}

			if enemy_bullets[i].position.y > VIEWPORT_SIZE.y {
				enemy_bullets[i].visible = false
				enemy_bullets[i].position = ENEMY_BULLET_RESET_POSITION
			}
		}
	}

}

kill_player :: proc() {
	scene = .DIED
	player_anim_index = 1
	rl.PlaySound(snd_player_dead)
	lives -= 1
}

update_mother_ship_in_game_state_game :: proc(dt: f32) {
	mother_ship_spawn_timer += dt
	if mother_ship_spawn_timer >= mother_ship_spawn_duration {
		mother_ship_spawn_duration = rand.float32_range(
			MOTHER_SHIP_SPAWN_RANGE.x,
			MOTHER_SHIP_SPAWN_RANGE.y,
		)
		mother_ship_spawn_timer = 0
		mother_ship_visible = true
	}

	if mother_ship_visible {
		if !rl.IsSoundPlaying(snd_mother_ship_appears) {
			rl.PlaySound(snd_mother_ship_appears)
		}
		mother_ship_position += MOTHER_SHIP_VELOCITY * dt * MOTHER_SHIP_SPEED
		if mother_ship_position.x > VIEWPORT_SIZE.x + 16 {
			mother_ship_visible = false
			mother_ship_position = MOTHER_SHIP_RESET_POSITION
		}

		mother_ship_rec: rl.Rectangle = {
			x      = mother_ship_position.x + MOTHER_SHIP_COLLIDER_OFFSET.x,
			y      = mother_ship_position.y + MOTHER_SHIP_COLLIDER_OFFSET.y,
			width  = MOTHER_SHIP_COLLIDER_SIZE.x,
			height = MOTHER_SHIP_COLLIDER_SIZE.y,
		}

		// Collision With Player Bullet
		for i in 0 ..< MAX_PLAYER_BULLETS {
			if player_bullets[i].visible {
				bullet_rec: rl.Rectangle = {
					x      = player_bullets[i].position.x + PLAYER_BULLET_SPRITE_ORIGIN.x,
					y      = player_bullets[i].position.y + PLAYER_BULLET_SPRITE_ORIGIN.y,
					width  = PLAYER_BULLET_SIZE.x,
					height = PLAYER_BULLET_SIZE.y,
				}

				if rl.CheckCollisionRecs(bullet_rec, mother_ship_rec) {
					player_bullets[i].visible = false
					player_bullets[i].position = PLAYER_BULLET_RESET_POSITION
					mother_ship_anim_index = 7
					rl.PlaySound(snd_enemy_dead)
					rl.PlaySound(snd_mother_ship_points)
					score += MOTHER_SHIP_POINTS
					mother_ship_death_timer = 0
					mother_ship_destroyed = true
				}
			}
		}
	}

	if mother_ship_destroyed {
		mother_ship_death_timer += dt
		if mother_ship_death_timer >= MOTHER_SHIP_DEATH_DURATION {
			mother_ship_death_timer = 0
			mother_ship_visible = false
			mother_ship_destroyed = false
			mother_ship_position = MOTHER_SHIP_RESET_POSITION
			mother_ship_anim_index = 6
		}
	}
}

update_player_in_game_state_level_complete :: proc(dt: f32) {
	player_level_up_timer += dt
	if player_level_up_timer >= PLAYER_LEVEL_UP_DURATION {
		scene = .READY
	}
}

update_game_over :: proc(dt: f32) {
	game_over_duration_timer += dt
	if game_over_duration_timer >= GAME_OVER_DURATION {
		reset_run()
		scene = .READY
	}
}

draw_player :: proc() {
	player_source_rec: rl.Rectangle = {
		x      = f32(player_anim_index) * PLAYER_SPRITE_SIZE.x,
		y      = 0,
		width  = PLAYER_SPRITE_SIZE.x,
		height = PLAYER_SPRITE_SIZE.y,
	}
	player_dest_rec: rl.Rectangle = {
		x      = player_position.x,
		y      = player_position.y,
		width  = PLAYER_SPRITE_SIZE.x,
		height = PLAYER_SPRITE_SIZE.y,
	}
	rl.DrawTexturePro(
		tex_player,
		player_source_rec,
		player_dest_rec,
		PLAYER_TEXTURE_ORIGIN,
		0,
		rl.WHITE,
	)
}

draw_enemies :: proc() {
	for x in 0 ..< ENEMY_ROWS {
		for y in 0 ..< ENEMY_COLUMNS {
			if enemies[x][y].visible {
				enemy_color: rl.Color = rl.WHITE
				enemies[x][y].texture_atlas_pos = 0
				if x == 0 {
					enemy_color = rl.RED
					enemies[x][y].texture_atlas_pos = ENEMY_SPRITE_SIZE * 2
				}
				if x == 1 || x == 2 {
					enemy_color = rl.GREEN
					enemies[x][y].texture_atlas_pos = ENEMY_SPRITE_SIZE * 4
				}


				source_rec: rl.Rectangle = {
					x      = enemies[x][y].texture_atlas_pos + (enemies[x][y].anim_index * ENEMY_SPRITE_SIZE),
					y      = 0,
					width  = ENEMY_SPRITE_SIZE,
					height = ENEMY_SPRITE_SIZE,
				}
				if !enemies[x][y].alive {
					enemy_color = rl.WHITE
					source_rec = {
						x      = 7 * ENEMY_SPRITE_SIZE,
						y      = 0,
						width  = ENEMY_SPRITE_SIZE,
						height = ENEMY_SPRITE_SIZE,
					}
				}
				dest_rec: rl.Rectangle = {
					x      = enemies[x][y].position.x,
					y      = enemies[x][y].position.y,
					width  = ENEMY_SPRITE_SIZE,
					height = ENEMY_SPRITE_SIZE,
				}


				rl.DrawTexturePro(tex_enemies, source_rec, dest_rec, {8, 8}, 0, enemy_color)
			}
		}
	}
}

draw_mother_ship :: proc() {
	source_rec: rl.Rectangle = {
		x      = f32(mother_ship_anim_index) * ENEMY_SPRITE_SIZE,
		y      = 0,
		width  = ENEMY_SPRITE_SIZE,
		height = ENEMY_SPRITE_SIZE,
	}
	dest_rec: rl.Rectangle = {
		x      = mother_ship_position.x,
		y      = mother_ship_position.y,
		width  = ENEMY_SPRITE_SIZE,
		height = ENEMY_SPRITE_SIZE,
	}
	rl.DrawTexturePro(tex_enemies, source_rec, dest_rec, MOTHER_SHIP_TEXTURE_ORIGIN, 0, rl.WHITE)
}

draw_border :: proc() {
	rl.DrawRectangleRec(BORDER_REC, rl.WHITE)
}

draw_player_bullets :: proc() {
	for i in 0 ..< MAX_PLAYER_BULLETS {
		if player_bullets[i].visible {
			rl.DrawRectangle(
				i32(player_bullets[i].position.x + PLAYER_BULLET_SPRITE_ORIGIN.x),
				i32(player_bullets[i].position.y + PLAYER_BULLET_SPRITE_ORIGIN.y),
				i32(PLAYER_BULLET_SIZE.x),
				i32(PLAYER_BULLET_SIZE.y),
				rl.WHITE,
			)
		}
	}

}

draw_enemy_bullets :: proc() {
	for i in 0 ..< MAX_ENEMY_BULLETS {
		if enemy_bullets[i].visible {
			source_rect: rl.Rectangle = {
				x      = enemy_bullets[i].anim_index * ENEMY_BULLET_TEXTURE_SIZE.x,
				y      = 0,
				width  = 7,
				height = 8,
			}
			dest_rect: rl.Rectangle = {
				x      = enemy_bullets[i].position.x + ENEMY_BULLET_TEXTURE_ORIGIN.x,
				y      = enemy_bullets[i].position.y + ENEMY_BULLET_TEXTURE_ORIGIN.y,
				width  = 7,
				height = 8,
			}
			rl.DrawTexturePro(tex_enemy_projectile, source_rect, dest_rect, {0, 0}, 0, rl.WHITE)
		}
	}
}


draw_hud :: proc() {
	draw_hud_score()
	draw_hud_level()
	draw_hud_hi_score()
	draw_hud_lives()

	switch scene {
	case .TITLE:
	case .READY:
		draw_hud_ready()
	case .GAME:
	case .LEVEL_COMPLETED:
	case .DIED:
	case .GAME_OVER:
		draw_hud_game_over()
	}


}

draw_hud_score :: proc() {
	rl.DrawTextEx(fnt_main, "SCORE", {UI_PADDING, UI_PADDING}, UI_FONT_SIZE, 0, rl.WHITE)
	rl.DrawTextEx(
		fnt_main,
		rl.TextFormat("%i", score),
		{UI_PADDING, UI_PADDING + UI_LINE_HEIGHT},
		UI_FONT_SIZE,
		0,
		rl.WHITE,
	)
}

draw_hud_level :: proc() {
	level_str: cstring = "LEVEL"
	rl.DrawTextEx(
		fnt_main,
		level_str,
		{
			VIEWPORT_SIZE.x / 2 - rl.MeasureTextEx(fnt_main, level_str, UI_FONT_SIZE, 0).x / 2,
			UI_PADDING,
		},
		UI_FONT_SIZE,
		0,
		rl.WHITE,
	)
	level_val_str := rl.TextFormat("%i", level)
	rl.DrawTextEx(
		fnt_main,
		level_val_str,
		{
			VIEWPORT_SIZE.x / 2 - rl.MeasureTextEx(fnt_main, level_val_str, UI_FONT_SIZE, 0).x / 2,
			UI_PADDING + UI_LINE_HEIGHT,
		},
		UI_FONT_SIZE,
		0,
		rl.WHITE,
	)
}

draw_hud_hi_score :: proc() {
	hi_score_str: cstring = "HI-SCORE"
	rl.DrawTextEx(
		fnt_main,
		hi_score_str,
		{
			VIEWPORT_SIZE.x -
			UI_PADDING -
			rl.MeasureTextEx(fnt_main, hi_score_str, UI_FONT_SIZE, 0).x,
			UI_PADDING,
		},
		UI_FONT_SIZE,
		0,
		rl.WHITE,
	)
	hi_score_val_str := rl.TextFormat("%i", hi_score)
	rl.DrawTextEx(
		fnt_main,
		hi_score_val_str,
		{
			VIEWPORT_SIZE.x -
			UI_PADDING -
			rl.MeasureTextEx(fnt_main, hi_score_val_str, UI_FONT_SIZE, 0).x,
			UI_PADDING + UI_LINE_HEIGHT,
		},
		UI_FONT_SIZE,
		0,
		rl.WHITE,
	)
}

draw_hud_lives :: proc() {
	source_rec: rl.Rectangle = {
		x      = 0,
		y      = 0,
		width  = PLAYER_SPRITE_SIZE.x,
		height = PLAYER_SPRITE_SIZE.y,
	}

	for i in 0 ..< lives {
		dest_rec: rl.Rectangle = {
			x      = 8 + f32(i) * (PLAYER_SPRITE_SIZE.x / 1.5),
			y      = VIEWPORT_SIZE.y - 16,
			width  = PLAYER_SPRITE_SIZE.x / 2,
			height = PLAYER_SPRITE_SIZE.y / 2,
		}
		rl.DrawTexturePro(tex_player, source_rec, dest_rec, 0, 0, rl.WHITE)
	}
}

draw_hud_ready :: proc() {
	rl.DrawRectangle(0, i32(VIEWPORT_SIZE.y / 2) - 16, i32(VIEWPORT_SIZE.x), 32, rl.YELLOW)
	ready_str: cstring = "Press 'Space' When Ready"
	rl.DrawTextEx(
		fnt_main,
		ready_str,
		{
			VIEWPORT_SIZE.x / 2 - (rl.MeasureTextEx(fnt_main, ready_str, 6, 0).x / 2),
			VIEWPORT_SIZE.y / 2,
		},
		6,
		0,
		rl.BLACK,
	)
}
draw_hud_game_over :: proc() {
	game_over_str: cstring = "Game Over"
	fnt_size: f32 = 14

	rl.DrawTextEx(
		fnt_main,
		game_over_str,
		{
			VIEWPORT_SIZE.x / 2 - (rl.MeasureTextEx(fnt_main, game_over_str, fnt_size, 0).x / 2),
			(VIEWPORT_SIZE.y / 2) - 32,
		},
		fnt_size,
		0,
		rl.WHITE,
	)
}

draw_debug_player :: proc() {
	rl.DrawRectangle(
		i32(player_position.x + PLAYER_COLLISION_OFFSET.x),
		i32(player_position.y + PLAYER_COLLISION_OFFSET.y),
		i32(PLAYER_COLLISION_SIZE.x),
		i32(PLAYER_COLLISION_SIZE.y),
		{0, 255, 0, DEBUG_OPACITY},
	)
	rl.DrawPixel(i32(player_position.x), i32(player_position.y), {0, 255, 0, DEBUG_OPACITY})
}

draw_debug_enemies :: proc() {
	for x in 0 ..< ENEMY_ROWS {
		for y in 0 ..< ENEMY_COLUMNS {
			if enemies[x][y].visible {
				rl.DrawRectangle(
					i32(enemies[x][y].position.x + ENEMY_TEXTURE_ORIGIN.y),
					i32(enemies[x][y].position.y + ENEMY_TEXTURE_ORIGIN.y),
					i32(ENEMY_SPRITE_SIZE),
					i32(ENEMY_SPRITE_SIZE),
					{255, 0, 0, DEBUG_OPACITY},
				)
			}
		}
	}
}

draw_debug_player_bullets :: proc() {
	for i in 0 ..< MAX_PLAYER_BULLETS {
		if player_bullets[i].visible {
			rl.DrawRectangle(
				i32(player_bullets[i].position.x + PLAYER_BULLET_SPRITE_ORIGIN.x),
				i32(player_bullets[i].position.y + PLAYER_BULLET_SPRITE_ORIGIN.y),
				i32(PLAYER_BULLET_SIZE.x),
				i32(PLAYER_BULLET_SIZE.y),
				{0, 0, 255, DEBUG_OPACITY},
			)

			rl.DrawPixel(
				i32(player_bullets[i].position.x),
				i32(player_bullets[i].position.y),
				rl.BLUE,
			)
		}
	}

}

draw_debug_enemy_bullets :: proc() {
	for i in 0 ..< MAX_ENEMY_BULLETS {
		if enemy_bullets[i].visible {
			rl.DrawRectangle(
				i32(enemy_bullets[i].position.x + ENEMY_BULLET_COLLISION_OFFSET.x),
				i32(enemy_bullets[i].position.y + ENEMY_BULLET_COLLISION_OFFSET.y),
				i32(ENEMY_BULLET_COLLISION_SIZE.x),
				i32(ENEMY_BULLET_COLLISION_SIZE.y),
				{255, 0, 0, DEBUG_OPACITY},
			)
			rl.DrawPixel(
				i32(enemy_bullets[i].position.x),
				i32(enemy_bullets[i].position.y),
				rl.RED,
			)
		}
	}
}

draw_debug_mother_ship :: proc() {
	rl.DrawRectangle(
		i32(mother_ship_position.x + MOTHER_SHIP_COLLIDER_OFFSET.x),
		i32(mother_ship_position.y + MOTHER_SHIP_COLLIDER_OFFSET.y),
		i32(MOTHER_SHIP_COLLIDER_SIZE.x),
		i32(MOTHER_SHIP_COLLIDER_SIZE.y),
		{255, 0, 0, DEBUG_OPACITY},
	)
	rl.DrawPixel(i32(mother_ship_position.x), i32(mother_ship_position.y), rl.RED)
}

check_enemies_remaining :: proc() {
	total_enemies: i32 = ENEMY_ROWS * ENEMY_COLUMNS
	dead_enemies: i32 = 0

	for x in 0 ..< ENEMY_ROWS {
		for y in 0 ..< ENEMY_COLUMNS {
			if !enemies[x][y].alive {
				dead_enemies += 1
			}
		}
	}

	if dead_enemies == total_enemies {
		player_level_up_timer = 0
		rl.PlaySound(snd_player_levelled_up)
		player_position = PLAYER_RESET_POSITION
		level += 1
		reset_enemies(true)
		reset_all_projectiles()
		scene = .LEVEL_COMPLETED
	}
}

reset_all_projectiles :: proc() {
	for i in 0 ..< MAX_PLAYER_BULLETS {
		player_bullets[i].visible = false
		player_bullets[i].position = PLAYER_BULLET_RESET_POSITION
	}

	for i in 0 ..< MAX_ENEMY_BULLETS {
		enemy_bullets[i].visible = false
		enemy_bullets[i].position = ENEMY_BULLET_RESET_POSITION
		enemy_bullets[i].anim_index = 0
		enemy_bullets[i].anim_timer = 0
	}
	enemy_bullet_velocity = {0, 1}
}
