# 20 Games+ Challenge in Odin
This is a collection of game development projects inspired by [The 20 Games Challenge](https://20_games_challenge.gitlab.io/).

As a follow up to my [Learn OpenGL (https://learnopengl.com/) examples in Odin](https://github.com/kidando/learnopengl-odin) project, I am now diving into game development projects using the [Raylib](https://www.raylib.com/) game library.

Shout out to [Karl Zylinski](https://zylinski.se/) for his [Odin + Raylib on the web template](https://github.com/karl-zylinski/odin-raylib-web) that helps you publish your games for the web browser. It compiles your odin code to web assembly using [Emscripten](https://emscripten.org/).

If you want to follow along below are some useful resources and steps you will need to follow.

## Setup
- You will need to install Odin. The [Getting Started](https://odin-lang.org/docs/install/) guide has different options you can follow.
- If you have Odin already, I suggest that you update it. I will be using the most recent build of odin as of the time I uploaded this repo onto github.
You will need a text editor or IDE. This project was a put together in [VS Code](https://code.visualstudio.com/) (and on Win11)
- In the root of project is a folder called ```_project_template``` which is a slimmed down version of [Karl Zylinski's odin-raylib-web project](https://github.com/karl-zylinski/odin-raylib-web). It's ready to go for windows. You may need to replace the ```build_desktop.bat``` and ```build_web.bat``` with ```build_desktop.sh``` and ```build_web.sh``` if you are on a linux environment. Details are on Karl's repo.
  
## How to run the projects
```cd``` into a particular project folder run the ```build_desktop.bat``` or ```build_web.bat``` files to build for desktop and web respectively. On linux that would be ```build_desktop.sh``` and ```build_web.sh``` files.

```shell
$ cd 1-pong
$ build_web.bat
```

Check the ```build``` folder for your builds.

I will publish final playable builds over at my itch.io page.

## Final remarks
I intend to have fun with these projects. Where I can, and without spending too much time, I will try to put my own spin on every game proposed in the challenge. As in make it unique.

If you are following along as well, I encourage you to do the same. 

I do not intend to be super detailed or strict in my approach. Odin, of course, is a low level language. Meaning if you don't watch out, you might cause things like memory leaks. As you can imagine, this sometimes scares devs that are not to familiar with memory management. 

But we are not making games for commercial distribution. I will do what I can to enure we are not crashing programs and causing leaks. But the main goal is to build prototypes for the sake of learning. 
 

## TODO
- [ ] Game #1: Pong