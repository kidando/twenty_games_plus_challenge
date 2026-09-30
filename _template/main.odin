package main

import "core:fmt"
import rl "vendor:raylib"

main::proc(){
    rl.SetConfigFlags({.VSYNC_HINT})
    rl.InitWindow(1280,720,"Template")
    rl.SetTargetFPS(60)

    for !rl.WindowShouldClose(){
        rl.BeginDrawing()
        rl.ClearBackground(rl.BLACK)
        rl.EndDrawing()
    }
    rl.CloseWindow()
}